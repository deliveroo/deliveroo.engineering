---
layout: post
title:  "Using AWS EC2 and ECS to host hundreds of services"
authors:
  - "Steve Rabino"
excerpt: >
  The Production Engineering team at Deliveroo look after hosting hundreds of
  services on AWS EC2 and ECS. Here, we take a high level look at how that's
  done, and how we manage the process of updates and improvements to this
  system.

---

One of my goals of moving internally to the Production Engineering team was to
help demystify the concepts that are commonplace within our Platform teams. My
first internal blog post to do this was to share how we use EC2 (AWS Elastic
Compute Cloud) and ECS (AWS Elastic Container Service) to host the hundreds of
services that our Software Engineers build and improve every day.

## What is an EC2 host?

<aside>
"Amazon Elastic Compute Cloud (Amazon EC2) is a web service that provides
secure, resizable compute capacity in the cloud. It is designed to make
web-scale cloud computing easier for developers. Amazon EC2’s simple web service
interface allows you to obtain and configure capacity with minimal friction. It
provides you with complete control of your computing resources and lets you run
on Amazon’s proven computing environment."

_Amazon's description of EC2_
</aside>

I would say this; an EC2 host is a server. More simply, it is a computer. It is
(in most cases) not an actual physical server in a rack, and Amazon abstracts
that detail away from us, but I find I get my head around the concept easier by
thinking of them as physical machines anyway. The machines we generally use have
16 vCPUs and 64 GiB of Memory (RAM).

It comes preinstalled with the software required to make it a usable computer;
like an operating system (you can just assume Linux for now - others are
available though), so it can be booted up and can run processes - more on that
later…

## What do we use EC2 hosts for?

A few different uses, but the most common use is in an
[ECS Cluster](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html),
a grouping of EC2 machines used as a home for ECS Tasks - these are the
Dockerized containers of our applications that are running with a command
specified by the engineer in a config file.

## ECS? What’s that, and how is it related to EC2?

ECS is AWS’s Elastic Container Service. It is an orchestration service that
makes sure the correct number of each service is running in the environment.
What it is actually running are the Docker containers that our continuous
deployment provider built when a PR was last merged to master.

When an engineer tells Hopper, our application release manager, to first scale
one of their app’s services up from 0 to 1 task, Hopper makes a call to ECS to
ask it to make sure that at all times there is one healthy instance of their
Docker container running on any one of the EC2 hosts. This is the desired number
of tasks - if the number of running tasks is less than this, ECS will start more
containers to reach the desired number, if there are more than desired, ECS will
safely terminate running containers to reach the desired number.

## Where does ECS start running this one container I’ve asked for?

This takes us back to our cluster of EC2 machines. ECS will find an EC2 machine
in the cluster that has enough spare capacity on it to hold and run your task
(i.e. it has enough spare reserved CPU and memory - which is specified in the
config file). There are some other rules in place regarding which Availability
Zone your task is running in (we don’t want all your eggs in one basket), but
for the most part, we leave it to ECS to decide.

## What happens if the cluster is full?

We are constantly monitoring the ECS cluster, and autoscale EC2 instances based
on how much spare capacity there is. If there’s not enough spare capacity to
immediately run another 40 large docker containers, we bump up the desired count
of EC2 instances in the cluster, and EC2 spins up new machines (the number of
machines we start up depends on how much below approximately 40 large container
capacity we are). New EC2 instances can take a few minutes before they’re ready
to be used by ECS, so we need to have a buffer to deal with unexpected spikes in
demand.

## How do we change or upgrade the machine image used?

Circling back to the software that is preinstalled on these EC2 servers. When
booted up, an Amazon Machine Image (AMI) is used, which has some basic tools
installed on it to make the machine usable. Amazon provides a base AMI which we
have built upon, using [Packer](https://github.com/hashicorp/packer) and
[Ansible](https://github.com/ansible/ansible), to create our own Amazon
Linux-derived machine image. This, and some initialization scripts, give all our
running ECS tasks access to things that all Deliveroo’s services will need, such
as software (like the [Datadog agent](https://docs.datadoghq.com/agent/) which
sends metrics to Datadog, and
[AWS Inspector](https://aws.amazon.com/inspector/), AWS's automated security
assessment service), roles, security policies, and environment variables that
we need to apply to the containers.

The process of rolling out a new machine image when an update is available, or
when we make changes to our custom machine image, is not as straightforward as
I’m used to as an application developer (I have a new-found appreciation for
release management software). Only newly created EC2 machines will be built
using this new image, and so the process of rolling out is one of the following
on each of our AWS environments (sandbox, staging, production):

* Disabling some of the cluster autoscaling rules, as we only want EC2 instances
using the old image being terminated when the cluster gets too big.
* Slowly scaling up the number of desired EC2 instances using the new AMI and
observing whether the change looks to be applied correctly, or if there are
issues occurring, or alerts triggering.
* Slowly reducing the desired number of old EC2 instances - terminated instances
will send a message to ECS to safely end all the tasks being run on the
instance. Without doing this, very few new services will actually be placed on
the new EC2 instances to test the changes in an incremental fashion.
* Once the cluster is fully on the new EC2 instances, adjust and re-enable the
autoscaling rules so that the old AMI is no longer used, and we continue to
autoscale instances using only the new AMI.
* Repeat until fully rolled out, on all environments.

We use an A/B system to deploy - the old AMI and configurations remained as the
`B` option, while any changes are only applied to the `A` track. On the first
attempt we noticed some issues with the new machine image after starting a
relatively small number of EC2 machines; it was as simple as scaling `B` back up
to an appropriate level, and `A` down to 0. As disappointing as it was to fail
the first time, I learnt so much more about the process by having to undo it
halfway through than I would have done if it had gone perfectly.
