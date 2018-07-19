---
layout: post
title:  "Building a Payments Lambda with Terraform"
authors:
  - "Phil Hack"
excerpt: >
    While integrating with a new payment provider, we needed to sync merchant ids via SFTP. We built an AWS Lambda function with Terraform to do this. I'll walk through our Terraform configuration and the hurdles we overcame around accessing the S3 bucket and accessing sensitive credentials. 
---

## Why Build a Lambda
On the Deliveroo Payments team we encountered an interesting problem while attempting to add a new payment service provider (PSP). In order to make this new PSP work, we needed to synchronize merchant ids. Unfortunately, this was only supported through SFTP using two folders: IN and OUT. We needed to generate an XML file, upload it to the PSP, then download and parse an XML file that the PSP created. Due to the way the encryption was configured on the SFTP server, there was not a suitable Ruby SFTP client that would work out of the box. 

Our options were either to fork a client, code some low level cryptography, hope that our open source PR was accepted, and then wait for a new gem to be released.
Luckily [Paramiko](http://docs.paramiko.org/en/2.4/api/sftp.html) connected on the first try. So, we built a micro service using this tech that runs on AWS [Lambda](https://aws.amazon.com/lambda/) and periodically syncs between an S3 Bucket and the PSP's SFTP. The Deliveroo ProdEng team made life easier by creating a template foundation for building lambdas using [Terraform](https://www.terraform.io/). By keeping infrastructure as code, we're able to deploy the same cookie cutter configuration to multiple environments.

The hurdles that we overcame were:
1. Storing and Using SFTP Credentials
1. Configuring the S3 Bucket
1. Invoking the lambda on a schedule
1. Building the lambda
1. Configuring Circle CI

## Storing and Using SFTP Credentials
One of the issues that we can up against was how to store the credentials for the SFTP server in the lambda. The solution was to use the [AWS SSM Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-paramstore.html). This was easy to configure since [Boto3](http://boto3.readthedocs.io/en/latest/reference/services/ssm.html) supports SSM out of the box.

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

```python
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

```python
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

```python
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
```python
resource "aws_s3_bucket_object" "sftpsync-bucket-in-object" {
  bucket = "sftpsync-${var.env_name}"
  acl    = "private"
  key    = "in/"
  source = "/dev/null"
}
```

## Invoking the lambda
To sync our lambda every 30 miunutes, we use cloud watch to emulate what would historically would have been done with a cron job. We can easily do this in terraform using the code below.

```python
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
Thanks to our ProdEng and ReleaseEng teams for already doing all the heavy lifting and creating some base terraform lambda templates that we can hook into, we can use the code snippet below to create the lambda. We created a module `sftpsync-lambda` that uses the template. We can override properties and set any environment variables that on the lambda itself using the `variables` property. 

```python
module "sftpsync-lambda" {
  source                = "../templates/lambda_function"
  circleci_project_name = "project/sftpsync"
  env_name              = "${var.env_name}"
  name                  = "sftpsync"
  region                = "${var.region}"
  handler               = "lambda_function.lambda_handler"
  runtime               = "python2.7"
  timeout               = 59
  variables = {
    SFTPSYNC_S3_BUCKET = "${aws_s3_bucket.sftpsync-bucket.bucket}"
  }
}

module "sftpsync-logs" {
  source = "../templates/lambda_stream"

  aws_account_id  = "${var.aws_account_id}"
  env_name        = "${var.env_name}"
  producer_config = "${module.sftpsync-lambda.config}"
  receiver_config = "${module.lambdalogs.config}"
  region          = "${var.region}"
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
Our ProdEng and ReleaseEng teams created some amazing helpers for making lambda CI/CD pipeline as simple as possible. These are open source and you can find them [here](https://github.com/deliveroo/circleci). This automagically wires up the deploy pipeline to push our image to a separate deployment S3 bucket and then deploys the image to our target environment.
