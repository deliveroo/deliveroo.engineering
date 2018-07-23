---
layout: post
title:  "Building a Payments Lambda with Terraform"
authors:
  - "Phil Hack"
excerpt: >
    While integrating with a new payment provider, we needed to sync merchant ids via SFTP. We built an AWS Lambda function with Terraform to do this. I'll walk through our Terraform configuration and the hurdles we overcame around accessing the S3 bucket and retrieving sensitive credentials. 
---

## Why Build a Lambda
On the Deliveroo Payments team we encountered an interesting problem while attempting to add a new payment service provider (PSP). In order to make this new PSP work, we needed to synchronize merchant ids. Unfortunately, this was only supported through SFTP using two folders: IN and OUT. We needed to generate an XML file, upload it to the PSP, then download and parse an XML file that the PSP created. Due to the way the encryption was configured on the SFTP server, there was not a suitable Ruby SFTP client that would work out of the box. 

We looked at our options. One option was to fork a Ruby SFTP client, code some low level cryptography, hope that our open source PR was accepted, and then wait for a new gem to be released. Another option was to test out a well supported SFTP client in a different language.
[Paramiko](http://docs.paramiko.org/en/2.4/api/sftp.html), a well supported Python SFTP client, connected on the first try. We chose to build a micro service, utilizing Paramiko, that runs on an AWS [Lambda](https://aws.amazon.com/lambda/). The responsibility of this micro service is to periodically sync between an S3 Bucket and the PSP's SFTP. The Deliveroo SETI team made life easier by creating a template foundation for building lambdas using [Terraform](https://www.terraform.io/). By keeping infrastructure as code, we're able to deploy the same cookie cutter configuration to multiple environments.

The hurdles that we overcame were:
1. Storing and using SFTP Credentials
1. Configuring the S3 bucket
1. Invoking the lambda on a schedule
1. Building the lambda
1. Configuring Circle CI

## Storing and Using SFTP Credentials
One of the issues that we came up against was how to persist and access the sensitive credentials for the SFTP server in the lambda. We opted for using [AWS Systems Manager Parameter Store with KMS](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html). We saved the credentials as [secure string parameters](https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-paramstore-about.html#sysman-paramstore-securestring), which are a key/value pair, where the value is encrypted.  We easily configured [Boto3](http://boto3.readthedocs.io/en/latest/reference/services/ssm.html) to fetch and decrypt the credentials in our app.

### Getting Credentials using Boto3
Below is a python snippet on how we used Boto3 and SSM to securely get the SFTP credentials.

```python
    def __init__(self, aws_session):
        self.__ssm_client = aws_session.get_session().client('ssm')
        self.__load_sftp_settings_from_ssm()

    def __load_sftp_settings_from_ssm(self):
        params = self.__ssm_client.get_parameters(
            Names=[
                self.__SSM_SFTP_USERNAME_KEY,
                self.__SSM_SFTP_PASSWORD_KEY,
            ],
            WithDecryption=True
        )
        for param in params['Parameters']:
            self.__ssm_store[param['Name']] = param['Value']
```

### Configure Terraform Permissions
To grant the lambda access to the SSM, we needed to add the `ssm:GetParameters` action in a new `statement` to our access-policy. We specify the exact name of our app `sftpsync` in the `resources` to adhere to least privilege.

```bash
data "aws_iam_policy_document" "sftpsync-s3-read-write-secrets-access-policy-document" {
  statement {
    actions = [
      "ssm:GetParameters",
    ]

    resources = [
      "arn:aws:ssm:${var.region}:${var.aws_account_id}:parameter/secretconfig/sftpsync/*",
    ]
  }
}
```

## Configuring the S3 Bucket
Both the lambda that performs the SFTP sync and our ruby [sidekiq](https://sidekiq.org/) jobs need to access the S3 bucket.

### Accessing S3 from the Lambda
To allow the Lambda to access the bucket using put, get, list, and delete on the objects in the bucket, we need the permissions below. These were a little time consuming to sort out. Some of the key takeaways here are: 
1. `s3:HeadBucket` needs to access all resources.
1. For the other actions, we need the `specific resource` and the `specific resource` with a trailing `/*`. 

```bash
data "aws_iam_policy_document" "sftpsync-s3-read-write-secrets-access-policy-document" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]

    resources = [
      "${aws_s3_bucket.sftpsync-bucket.arn}",
      "${aws_s3_bucket.sftpsync-bucket.arn}/*",
    ]
  }

  statement {
    actions = [
      "s3:HeadBucket",
    ]

    resources = [
      "*",
    ]
  }
}
```

### Accessing S3 from the Ruby Sidekiq Worker
To grant the sidekiq worker access to the S3 bucket, we create a policy document with the exact same permissions as above, but we need to create a policy and a policy attachment. The only allows the specific ec2 instance(s) access to the S3 bucket.

```bash
resource "aws_iam_policy" "sidekiq-to-sftpsync-s3-policy" {
  name   = "${module.sidekiq.app_name}-${var.env_name}-to-sidekiq-to-sftpsync-s3-policy"
  policy = "${data.aws_iam_policy_document.sidekiq-to-sftpsync-s3-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "sidekiq-to-sftpsync-s3-policy-attachment" {
  role       = "${module.sidekiq.iam_role_name}"
  policy_arn = "${aws_iam_policy.sidekiq-to-sftpsync-s3-policy.arn}"
}
```

### Programmatically Creating 'Folders'
Our sftp sync S3 bucket needed the following objects created: `in` and `out` to basically act as folders. Since we want to do this programatically accross all environments, we can do this in terraform with:
```bash
resource "aws_s3_bucket_object" "sftpsync-bucket-in-object" {
  bucket = "sftpsync-${var.env_name}"
  acl    = "private"
  key    = "in/"
  source = "/dev/null"
}
```

## Invoking the lambda
To sync our lambda every 30 miunutes, we used cloud watch to emulate what would historically would have been done with a cron job. We can easily do this in terraform using the code below.

```bash
resource "aws_cloudwatch_event_rule" "sftpsync" {
  name                = "sftpsync-${var.region}"
  description         = "Sync payment provider xyz sftp to s3 bucket at specific interval"
  schedule_expression = "rate(30 minutes)"
}

resource "aws_cloudwatch_event_target" "sftpsync" {
  rule = "${aws_cloudwatch_event_rule.sftpsync.name}"
  arn  = "${lookup(module.sftpsync-lambda.config, "function_arn")}"
}
```

## Building the Lambda
The Deliveroo SETI team already did the heavy lifting and created some base terraform lambda templates. This template allows for properties and environment variables to be overridden. We created a module `sftpsync-lambda` that hooked into this template to build the lambda. 

```bash
module "sftpsync-lambda" {
  runtime               = "python2.7"
  variables = {
    SFTPSYNC_S3_BUCKET = "${aws_s3_bucket.sftpsync-bucket.bucket}"
  }
}

module "sftpsync-logs" {
  env_name        = "${var.env_name}"
  producer_config = "${module.sftpsync-lambda.config}"
  receiver_config = "${module.lambdalogs.config}"
}

resource "aws_lambda_permission" "sftpsync" {
  statement_id  = "sftpsync-${var.env_name}-${var.region}"
  action        = "lambda:InvokeFunction"
  function_name = "${lookup(module.sftpsync-lambda.config, "function_name")}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.sftpsync.arn}"
}

resource "aws_iam_role_policy_attachment" "sftpsync-policy-attachment" {
  role       = "${lookup(module.payments-sftpsync.config, "role_name")}"
  policy_arn = "${aws_iam_policy.sftpsync-s3-read-write-secrets-access-policy.arn}"
}

```

## Configuring Circle CI
Our SETI team created some amazing helpers for making lambda CI/CD pipeline as simple as possible. This automagically wires up the deploy pipeline to push our image to a separate deployment S3 bucket and then deploys the image to our target environment. These are open source and you can find them [here](https://github.com/deliveroo/circleci). The corresponding docker image, while publicly available, is a little bit Deliveroo specific. However, there are some useful scripts that others can remix and adapt to their own needs.

## Conclusion
When building a lambda microservice, there are aways additional items that should be taken into account besides just coding the new service, such as:
1. Logging
1. Monitoring
1. Alerting
1. CI/CD pipeline
1. Provisioning infrastructure
1. Security

All of these take additional time to implement, but having standardized templated solutions to these problems significantly decreases the time taken to get a new service into production. While we had the majority of these items covered, there were still a few time consuming gotchas, for example:

1. Sorting out the S3 permissions and allowing access 
1. Reconfiguring  security in our Ruby S3 adapter
1. Configuring SSM with the lambda 

Although tackling these problems took additional time, we won't need to solve them again, which helps the wider team to easily create more lambdas in the future. 

If you enjoy solving problems like this, and want to use the latest tech, join us on the Deliveroo Payments Team. [We're hiring!](https://careers.deliveroo.co.uk)
