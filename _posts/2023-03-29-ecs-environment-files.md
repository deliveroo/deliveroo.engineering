---
layout: post
title:  "Environment files and finding a bug in the Amazon Elastic Container Service Agent"
authors:
  - "Simon Apen-Sadler"
excerpt: >
  How Deliveroo passes environment variables to containers in production
date: 2023-03-29T15:07:01+0100
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Background

We use the [Amazon Web Services][aws] (AWS) cloud provider to host our containers, primarily with the [Amazon Elastic Container Service][ecs] (ECS). As part of Deliveroo's [release process][app-dev], we use Hopper (Deliveroo's internal Continuous Deployment tool) to deploy changes into production. We use environment variables to configure some of our applications. Hopper stores environment variables in its database (and links to [AWS Secrets Manager][secrets-manager] for sensitive values). During a deployment to ECS, Hopper generates a new [ECS Task definition][task-def] and registers it with ECS, inserting environment variables as necessary. Hopper then uses this new task definition to update the service in ECS.

Task definition snippet:

```json
{
    "containerDefinitions": [
        {
            "name": "web",
            "image": "nginx",
            "cpu": 128,
            "memory": 128,
            "essential": true,
            "environment": [
              {
                "name": "NAME",
                "value": "value"
              }
            ]
          
        }
    ]
}
```

## The problem

Some of Deliveroo's services have a lot of environment variables, some with large values. This is particularly true for some older services that have grown organically over time. ECS has a hard [limit][ecs-limit] on the size of the task definition - it cannot exceed 64KiB. These task definitions started going over the limit, which meant Deliveroo were unable to deploy some key services and unable to add new environment variables.

## The temporary fix

We removed newly added variables to reduce the size below the limit and put in checks to pull requests to avoid adding new ones. This fixed the immediate problem but blocked us from releasing any new releases that required environment file configuration. 

Additionally, we reviewed existing environment variables to find those that could be safely removed, which might temporarily give us some wiggle room but not in the long term.

## Compression 
We thought we might be able to use compression to reduce the overall size of the environment variable/value pairs. After some initial digging into this, it turned out we had already compressed the variables into a bundle which our init process would decode for our main application. We needed to try something else.

## Environment files

ECS provides an alternative way to pass environment variables to containers - [environment files][env-files]. This changes the task definition:

```json
{
    "containerDefinitions": [
        {
            "name": "web",
            "image": "nginx",
            "cpu": 128,
            "memory": 128,
            "essential": true,
            "environmentFiles": [
              {
                "value": "arn:aws:s3:::example-bucket/example.env",
                "type": "s3"
              }
            ]
          
        }
    ]
}
```

Each environment file contains one key value pair per line of the form:

```text
NAME=value
```

Using environment files allowed us to store them separately from the task definition and reduce its size to below the limit.

## Intermittent failures

After implementing the change to *optionally* use environment files instead of an environment array in the task definition, and successfully testing in staging, we rolled it out to production. The sizes were reduced, and we were able to deploy. Success was short-lived - releases began to fail intermittently. We had to roll back.

### Crashing Containers and Automated Rollbacks
Releases using the new environment file feature would intermittently fail and auto-rollback - we had to revert the change. Hopper was automatically rolling back the release because new containers were crashing. The error message:

```text
Task failed to start. ResourceInitializationError: resource cannot be initialized for task arn:aws:ecs:eu-west-1:000000000000:task/production/4d48d7b08b8a467f89d6161a73f0ea29: open /data/envfiles/<snip>
```

The logs were truncated which made tracking down the issue harder. Initially we thought it could be a concurrency bug where the task would start before we uploaded the environment file. We ruled this out quickly as we also saw in our logs this was occurring overnight as the service would auto-scale. As other tasks were successfully running (and had been for many hours), the environment file must have been present with the correct permissions and configuration. Due to the intermittent nature of the issue and the error log suggesting that the environment file was not being downloaded locally, I believed it was a concurrency bug in the ECS agent. However, I had no evidence to support that theory.

### Asking for help

At this point, we raised a ticket with AWS to try to get to the bottom of the issue. It turned out to be a complex issue to debug due to the intermittent nature, and we needed a fix faster.

### Temporary Mitigation

Hopper auto-detects container crashes and will roll back if the configurable threshold is met. However, we do experience temporary failures such as a full disk, which we ignore as these are temporary. We used similar logic to ignore this specific type of error too, which fixed the problem quickly, and we were able to continue using environment files successfully.

## Continued Investigation

Not satisfied, as containers crashing on startup should not be a normal event, we continued with the investigation with AWS Support. We discovered we are not using the recommended ami for our ecs instances and the configuration differed significantly from the recommended approach. At this point we wondered if this was linked to our ec2 ami configuration and whether this really was an issue in the ecs-agent.

### ECS Agent Bug

Being unable to determine when and where the issue would next occur, we'd have to enable debug logs for the ECS agent for the entire cluster - logging has a cost and this would not be insignificant. With no other choice, we did this for a short period of time, until we saw the error, to minimise cost.

Going through the debug logs for specific containers that failed we found the following log entries:

```text
level=debug time=2022-12-07T16:55:34Z msg="Downloading envfile with bucket name <bucket> and key name <snip>/envfile.env" module=envfile.go
level=error time=2022-12-07T16:55:34Z msg="Unable to open environment file at /data/envfiles/<snip>/envfile.env to read the variables" module=envfile.go
level=debug time=2022-12-07T16:55:34Z msg="Downloaded envfile from s3 and saved to /data/envfiles/<snip>/envfile.env" module=envfile.go
```

Which showed the file being accessed **before** the download completed. This confirmed a concurrency bug in the ECS agent. The issue was [fixed][fix-pr] by AWS. 

The underlying issue was that in the dependency graph in the ecs-agent each environment file was referenced by the same id. In our case we had multiple environment files (one per container) - one file would download successfully but all files were marked as downloaded as they had the same name.

Deploying the new agent has since fixed the issue, and we're now using environment files in production without issue.

[aws]:https://aws.amazon.com/
[deliveroo-ecs]:https://deliveroo.engineering/2020/06/16/using-aws-ec2-and-ecs-to-host-hundreds-of-services.html
[ecs]:https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html
[task-def]:https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html
[fix-pr]:https://github.com/aws/amazon-ecs-agent/pull/3554
[ecs-limit]:https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-quotas.html
[app-dev]:https://deliveroo.engineering/2018/02/21/application-deployment.html
[env-files]:https://docs.aws.amazon.com/AmazonECS/latest/developerguide/taskdef-envfiles.html
[secrets-manager]:https://aws.amazon.com/secrets-manager/
