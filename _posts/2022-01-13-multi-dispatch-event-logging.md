---
layout: post
title:  "Multi-dispatch event logging"
authors:
  - "Charlie Sabine"
excerpt: >
  How and why we use multi-dispatch event logging at Deliveroo - writing events data out to Datadog, Kafka and Snowflake.
---
## Background

### Our traditional monitoring and alerting setup

At Deliveroo, we use Datadog for all things monitoring and alerting - most commonly we use StatsD counters to calculate metrics, and then create monitors over these.

By way of example, each time a user attempts a payment we will fire a simple counter saying something like “payment attempted”, then when we get a response back from our payment service provider we will fire another counter - e.g. “payment successful” or “payment failed”. We can divide these counters by each other to create a payment success rate metric, and fire an alert if this metric goes below an acceptable threshold. 

Whilst we can add additional tags onto a metric to help with debugging, we are limited here by the cardinality of the tags added. Adding the market (e.g. UK, France) or platform (e.g. android, ios) to a metric is fine, but adding the unique user ID likely is not, given the millions of users we have. 

We use logs and APM traces for higher cardinality debugging - however typically these are sampled and have limited retention. They’re good for pinpointing where in code a problem lies, but impractical to assess the total impact of a problem. 

### Use of Kafka and Snowflake at Deliveroo

Kafka is our primary method of communication at Deliveroo - powering our interservice communication, machine learning models, and much more. Snowflake is our primary offline data warehouse, powering our Looker reporting and all ad hoc analyses by the data science org. 

We invest heavily in platform engineering at Deliveroo, meaning that it is relatively simple for product focused engineering teams to spin up a new Kafka topic, start publishing to it, and then writing the data through to Snowflake via a custom consumer. At the same time, we also replicate most of our databases in Snowflake too (e.g. our users database), meaning more complex analyses can be done in Snowflake by joining topic data with database data. 

## The problem and our solution

### The problem

The standard problems we faced with our traditional monitoring/alerting setup can be summarised as:

- Simple counts are great to tell you how often something is happening and whether an engineer needs to be paged; but not more useful business metrics e.g. how many unique users a bug is affecting; how much revenue a bug impacts 
- Metrics existed in isolation of each other - whilst we may be able to correlate failures on X service with those on Y service, these were often limited by retention or sampling
- Having no real bridge between Datadog and Snowflake meant that the engineering world and the business analytics world were not as close as we would like

As an example, imagine a bug that causes a number of failures, spiking one of our metrics. To ascertain how serious this bug is, we need to consider a few things:

- How evenly distributed are these errors? Do a small number of users have a lot of errors each, or do a lot of users have one single error each? 
- What is the immediate business impact of these errors? Can they retry later and successfully complete an action, or are they blocked entirely? 
- What are the downstream business implications of these errors? For example if new users experience a serious bug on their first ever payment attempt, they may be more inclined to forever churn from the platform

### Our solution

Enter the multi-dispatch approach: instead of calling separate publishers in our application code (one for Kafka, one for StatsD), we can call a generic publisher that multi-dispatches to both.

Full event payloads are published to Kafka - these contain not just the event name (e.g. “payment attempted”), but also any other relevant metadata regardless of cardinality such as user IDs, device metadata, and any other relevant correlation IDs that we may have. These have to be modelled upfront - see [here](https://deliveroo.engineering/2019/02/05/improving-stream-data-quality-with-protobuf-schema-validation.html) for how we handle Kafka schema.

At the same time, a lightweight event payload is also published via StatsD - usually just containing the event name and lower cardinality tags such as market and platform. 

The result is that we have two ways to analyse events data - we can use our standard Datadog telemetry to create metrics and alerts, but also given that our Kafka payloads are available in Snowflake, we can perform ad hoc analyses to more deeply quantify the impact during incident analysis:

- We can group by user ID to see if errors are transient or fully blocking - did they complete an action later on in the same session or not? 
- We can calculate the downstream impact of errors on user behaviour - what are the longer term impacts on retention, frequency, any other business metrics? 
- We can compare the binary count data with more complex business metrics and therefore create more meaningful thresholds for alerting - answering questions such as “should we alert if a metric goes below 80%? What about 90%?” 

A more subtle benefit of this approach is that it brings our engineering and data orgs closer together. By opting to multi-dispatch, we can avoid cases where data solely exists in just Datadog or Snowflake, but not both. Furthermore, given both streams of data are created at the same time, any changes made at publish time should be reflected in both outputs. Data scientists can suggest new logging events that we should add and alert on based on their business understanding, whilst engineers can self-serve their own impact analysis by querying Snowflake data and creating their own business metrics.

By choosing Kafka to publish our event payloads, we also can unlock one more significant benefit - using tools such as Apache Flink, we can combine multiple Kafka topics together to create streaming derived business metrics, and then alert on these in real time. More on that approach another time, however…

### An example in practice

Consider the ordering process on Deliveroo - as a simplistic overview:

- User places an order on their device
- Deliveroo contacts payment service providers to handle payment
- Deliveroo sends the order to the restaurant to be prepared
- Rider collects the food, and delivers to the customer

In the above, we create a unique identifier at the time of an order being placed, publishing the event to a Kafka topic containing information such as the user ID, restaurant ID, market etc. As the order moves through each part of the above flow, we publish additional events to the same Kafka topic with the same unique identifier (e.g. “order sent to restaurant”). Using the resulting data, we can create real time dashboards in Datadog, and Looker dashboards based on the Snowflake output of the Kafka topic. If any errors occur at any point in the flow, we can use Datadog metrics to be alerted in real time, and then later perform impact analysis in Snowflake (e.g. count of distinct users affected, retention impact). 

## Closing remarks

The multi-dispatch approach exists because creating a one-size-fits-all database for such different read/write patterns is [notoriously difficult](https://dataintensive.net/) - metrics optimised for quick aggregations will suffer if you add high cardinality fields to them (and not allow joins); running large join queries on your production relational databases will probably cause an outage. By multi-dispatching the same underlying data but storing it in very different ways, we can serve the needs of both engineers and data scientists without having to make compromises.

The multi-dispatch approach described above is nothing new - for example Facebook’s infrastructure is referenced [here](https://research.facebook.com/blog/2014/10/facebook-s-top-open-data-problems/) - they multi-dispatch to their in-house tools called ODS, Scuba and Hive. In a very simplistic way, we can roughly align our approach as follows:

- We use Datadog for time series counters, akin to ODS
- Whilst only tangentially comparable, by joining multiple Kafka streams with Apache Flink, we can create real time enriched datasets akin to the data that powers Scuba
- Hive is akin to Snowflake

Finally, the importance of different areas of the business having a consensus around data cannot be understated. If an exec sees a spike in a metric based on Snowflake data, but the engineering org uses a different set of metrics (published at different times) to measure the same thing, then wires can easily get crossed. The multi-dispatch approach aims to bridge some of this gap, ensuring that equivalent datasets can always be analysed regardless of the tool used.
