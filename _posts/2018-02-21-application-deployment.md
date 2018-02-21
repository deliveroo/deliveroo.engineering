---
layout: post
title: Application Deployment at Deliveroo
authors:
- Ben Cordero
excerpt: >
  Our services are rapidly growing in number and we need a scalable way of managing the mayhem.
  Over the course of a year, our site was served as a single monolith and is now composed of over
  50 services.

---

<aside>
"When a monolith is split into microservices, the responsibilities of the infrastructure
organization for providing a stable platform for microservices to be developed and run on grows
drastically in importance. The infrastructure teams must provide microservice teams with stable
infrastructure that abstracts away the majority of the complexity of the interactions between
microservices."

_Production-Ready Microservices by Susan J. Fowler_
</aside>

Breaking up the monolith and new feature initiatives means that we are adding (or maybe I'm just
discovering) two new services a week. Over the past nine months, we have been making strides to
take ownership of our application infrastructure.

Making it easy to deploy new apps, with consistency, is key to preventing this devolving into mayhem.
With an *infrastructure description language*, like Hashicorp's [Terraform](https://www.terraform.io/),
we can describe applications programatically. With [Infrastructure as Code](https://martinfowler.com/bliki/InfrastructureAsCode.html),
maintaining the service platform itself can be done with GitHub PRs.

## Deploying new applications

```
module "avocado" {
  source = "../templates/roo_app"
  ...

  # Somewhere in GitHub, assume github.com/deliveroo/%repo_name%
  repo_name = "avocados-service"
}

module "avocado-web-service" {
  source = "../templates/roo_service_public_web"
  ...

  process_name   = "web"
  container_port = 3000
}
```

With a few lines, we can define and instantiate new applications with very little effort.

These templates are quite powerful and hides a lot of our infrastructure decisions.

  - Set up the Elastic Container Repository, [ECR](https://aws.amazon.com/ecr/), to store deployable Docker Images.
  - Set up the [CircleCI](https://circleci.com/) environment for building (and pushing) Docker Images to ECR.
  - Create AWS resources, such as S3, IAM and Cloudwatch as needed to configure this application.
  - Register the application in Hopper, our release manager.
  - Add an ALB to Load Balance HTTP requests for the web service.
  - Set up (optional) Autoscaling for the workers.
  - Add a basic [newrelic](https://newrelic.com/) dashboard for the service.
  - Create an initial ECS placeholder task.
  - Create DNS records in [route53](https://aws.amazon.com/route53/) and [Cloudflare](https://www.cloudflare.com/).

The end result is that all of our services can now be developed and deployed with consistency.
There is no playbook for "adding new apps". Teams can create a PR and we all wait for Terraform to
do its thing.

## Adding more resources

My team maintains a bunch of extra templates for common resources that applications can use.
For example, adding a [postgresql](https://www.postgresql.org/) database.

```
module "avocado-db" {
  source = "../templates/postgresql"

  application_name        = "${module.avocado.app_name}"
  backup_retention_period = "30"
  storage_encrypted       = true

  ebs_size = 100

  master_instance_class = {
    production = "db.m4.large"
    staging    = "db.t2.small"
  }

  replica_instance_class = {
    production = "db.m4.large"
    staging    = "db.t2.small"
  }

  replica_count = 2
  ...
}

# This is injected into the application environment at runtime
resource "hopper_variable" "avocado-env-database-url" {
  app_name   = "${module.avocado.app_name}"
  name       = "DATABASE_URL"
  value      = "${module.avocado-db.url}"
  write_only = true
}
```

This can be extended to any Terraformable resource, not just AWS. The template modules can abstract
common details and let us pick which parameters we can allow diverge across our organisation.

## Beyond Infrastructure as Code

<aside>
"In cloud native infrastructure, you must hide underlying systems to improve reliablilty. Cloud
infrastructure, like applications, expects failures of underlying components to occur and is
designed to handle such failures gracefully. This is needed because the infrastructure engineers
no longer have control of everything in the stack.

Infrastructure is ready to become cloud native when it is no longer a challenge. Once
infrastructure becomes easy, automated, self-serviceable, and dynamic, it has the potential to be
ignored. When systems can be ignored and the technology becomes mundane, it's time to move up the
stack"

_Cloud Native Infrastructure - Justin Garrison & Kris Nova_
</aside>

We don't control everything about our applications in Terraform. While keeping a git log of all
changes can be useful, not all changes need to be serialised through my team.

Higher frequency changes such as deploying a commit or updating variables are tasks that are controlled
by dashboards and control panels. With an CI/CD workflow, a team may choose to have the system
autodeploy whenever the GitHub Merge button is clicked.

We think we have this abstraction at the right level. The particular details about the platform
can be concealed in the templates, while application choices are established for each instance.

