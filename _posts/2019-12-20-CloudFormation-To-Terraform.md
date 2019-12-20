---
layout: post
title:  "CloudFormation To Terraform"
authors:
  - "Melmols"
excerpt: >
  As engineers we love solving logical problems, building and fixing. But we also like to keep things simple, we often find there is already a solution built, but
  not in the language/format that we'd need. 


  Sometimes the way we approach a problem can influence greatly in the outcome. This guide will show you a quick workaround that will help in managing a CloudFormation stack with Terraform.

---

For those starting with either Terraform or CloudFormation this guide is a good way to understand the differences between the two.
I found myself a little bit stuck because I needed to find/create code (in this case) that would help me in Benchmarking our
compliance status in AWS. I found a solution in CloudFormation, so I wondered if there was some sort of translator tool (there wasn't),
and if not, how and where would I start translating this code? Would it be worth me building it from scratch in Terraform?

# How to convert CloudFormation (CF) to Terraform (TF): CIS Foundations Quickstart


#### First lets state the differences and how each syntax is built:

### Terraform

Terraform language uses HCL (Hashicorp Configuration Language). Terraform code is built around 2 key syntax constructs:

-   Arguments:
    -   Arguments assigns a value to a particular name:

```json
image_id = "blabla"
```

-   Blocks:
    -   A block is a container for other content

```json
resource "aws_instance" "example" {
  ami = "abc123"

  network_interface {
    # ...
  }
}
```

Terraform consists of modules, which is really up to the builder on what it does. Each module has *blocks* and along with the configuration,
it tells terraform how/when to use/build that module. Configuration files in Terraform are written in JSON.

## CloudFormation

CloudFormation is all about templates. If you want to build a configuration for an application or service in AWS, in CF,
you would create a template, these templates will quickly provision the services or applications (called stacks) needed.
The most important top-level properties of a CloudFormation template are:

- Resources:
    - This would be where we define the services used in the stack.
For example, we could define an EC2 instance, its type, security group etc.

```YAML
EC2Instance:
Type: AWS::EC2::Instance
Properties:
  InstanceType:
    Ref: InstanceType
  SecurityGroups:
  - Ref: InstanceSecurityGroup
```

- Parameters:
    - If we define an instance, with its type, this is where that "parameter type" would be passed in:

```YAML
Parameters:
InstanceType:
Description: WebServer EC2 instance type
Type: String
Default: t2.small
```
Configuration files for CF are written either in YAML or JSON.

## Converting CF to TF

In this document, I'll take you through the steps I went through on how to convert CF to TF. In particular, a recent project I worked on.
In case you haven't heard about it, CIS is the Center for Internet Security, and they provide cyber security standards and best practices.
Recently, AWS launched a new service called AWS Security Hub, which analyses security findings from various supported AWS and third-party products. Security hub supports
the CIS AWS Foundations Benchmark, (read more [here](https://www.cisecurity.org/benchmark/amazon_web_services/])) which, quoting
CIS is "An objective, consensus-driven security guideline for the AWS Cloud Providers". To jump straight into it, AWS Security
Architects partnered up with Accenture and created a [CIS-Foundations Quickstart](https://github.com/aws-quickstart/quickstart-compliance-cis-benchmark) written in CloudFormation
but it is built using CloudFormation, not Terraform. So, after looking around, realised there wasn't any versions written in Terraform, and also
no guides on how to translate it. Or automated translation tools for the matter (future work? hit me up for a collab) I decided to
do it manually, as I felt this was a bit of a sensitive project to be testing automated tools on. But fear not, I did not do it as manually as you think. Simplicity above everything!

### Part 1: Understand the structure, state the stack

Lets take a look at how the CloudFormation [CIS Benchmark Quickstart](https://github.com/aws-quickstart/quickstart-compliance-cis-benchmark) works.

![](https://camo.githubusercontent.com/f600ecf22ac9fbac422f02251f3910f9636e5376/68747470733a2f2f64302e6177737374617469632e636f6d2f706172746e65722d6e6574776f726b2f517569636b53746172742f646174617368656574732f717569636b73746172742d6172636869746563747572652d666f722d6369732d62656e63686d61726b2d6f6e2d6177732e706e67)

The stack can be described as follows:

- Cloudtrail
- AWS Config
- S3

Templates are the following:

- Pre-requisites template: makes sure CloudTrail, config and S3 are created or exist and meet the preconditions for CIS Benchmarking:
    - Config must have an active recorder running.
    - CloudTrail must be delivering logs to CloudWatch Logs
- Config Setup template: sets the configurations needed for AWS config
- CloudTrail-setup template: sets the configurations needed for CloudTrail
- CIS-benchmark template: this is the tricky one, it contains all 42 objectives the account should meet to be CIS foundations compliant.
- Main template: this is the main template, and it nests the stacks created from the previous templates so it can deploy the CIS AWS Foundations benchmark.

### Part 2: design TF

Now that we stated how this CF project works, lets see how we can transform them into the likes of Terraform.

- The templates can be transformed into modules.
- Pre-requisites can be part of the config and Circle CI checks (we will take a look at that in the end)
- Main template will be the main.tf, contains all the callable modules.

Lets see how a CF template would look like:

- AWSTemplateFormatVersion: 2010-09-09
Description: (stuff)
- Metadata
Labels: (Stuff)
- Parameters:
(Stuff)
- Conditions: (more Stuff)
- Resource: (This is where all the cheesy stuff happens)

Now, lets see how we can use that to "translate" into Terraform.

### Part 3: translation

Now, apart from tedious, translating line by line, especially in a big project, is a bit of science fiction (for me). So I dug around:

1)   Terraform accepts CF stack templates:

By Stating Resource: aws_cloudformation_stack_set, you can manage a CloudFormation stack set, so this functionality allows you to deploy
CloudFormation templates. It only accepts JSON templates.

> Possible challenge: templates built in YAML instead of JSON

No problem! I had this myself, after a bit of googling, there is actually a tool called [cfn-flip](https://github.com/awslabs/aws-cfn-template-flip) explicitly for the translation of YAML to JSON in CF:


So for example, if you want to create the template in json:

```bash

$ cfn-flip main.template > main.json

or, just copy the output:

$ cfn-flip main.template | pbcopy

```
2)  But, what if it's a giant template?

This is my case too, the cis-benchmark template is quite big. Luckily for us again, you can reference the json template, by uploading it to a S3
bucket. It would look like this:

```go
resource "aws_cloudformation_stack" "cis-benchmark" {
  name = "cis-benchmark-stack"

  template_url = "https://cis-compliance-json.s3-eu-west-1.amazonaws.com/cis-benchmark.json"

}
```
> Note: never reference config files and templates that have hardcoded variables (also never hard code sensitive data ) that are hosted publicly. In my case
think of that template as skeletal, it doesn't have any sort of compromising info.

 And done, we just created a part of the module in just 3 lines of code!

#### Challenges

3)  Nested Stacks

In our case, the Quickstart uses nested stacks. Now aws_cloudformation_stack terraform functionality doesn't have a
"nested stacks" option. But creating the resources in the same module works fine.

-   Parameters

    If you need to pass Parameters, you can do it as you would normally do, state the vars in the resource where you create
    the stack and should be good to go too!


Example code: (This is an extract of the module)

```go
#root module

resource "aws_cloudformation_stack" "pre-requisites" {
  name = "CIS-Compliance-Benchmark-PreRequisitesForCISBenchmark"

  template_url = "https://{bucket-name}.s3-(region-here).amazonaws.com/cis-pre-requisites.json"

  parameters = {

    QSS3BucketName = "${var.QSS3BucketName}"
    QSS3KeyPrefix = "${var.QSS3KeyPrefix}"
    ConfigureConfig = "${var.ConfigureConfig}"
    ConfigureCloudtrail = "${var.ConfigureCloudtrail}"


   }
}


resource "aws_cloudformation_stack" "cloudtrail-setup" {
  name = "CIS-Compliance-Benchmark-cloudtrail-stack"

  template_url = "https://{bucket-name-here}.s3-(region-here).amazonaws.com/cis-cloudtrail-setup.json"

  capabilities = ["CAPABILITY_IAM"]

}

[...]
```
4) Done!

Now you can simply run and manage your stacks using Terraform. I suggest to
always be careful with sensitive data and parameters and follow best practices.
You can read more about it [here](https://www.terraform.io/docs/providers/aws/r/cloudformation_stack_set.html#template_url)

### Conclusion

When it comes to features, CF and TF are not equivalent. It is not possible to express what CF is able to deploy in TF.
Which is why I aimed at this solution, translating line by line would be very tedious, so if that is your case i'd suggest
rewriting the entire module in TF. However writing a translator would be complex but very useful, still would have to figure
out how it would work when CF uses intrinsic functions (please contact me for ideas!) but i'd guess that'll be for future work.
I hope this quick workaround helped you out!