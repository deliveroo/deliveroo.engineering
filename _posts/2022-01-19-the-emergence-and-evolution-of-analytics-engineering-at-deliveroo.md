---
layout: post
title:  "The Emergence and Evolution of Analytics Engineering at Deliveroo"
authors:
  - "Andrew Ferrier"
excerpt: >
  In the first of what we hope will be a series of blog posts about our analytics engineering discipline and some of the work we do, we first introduce the team, where it has come from, and how we’re evolving our organisational model in step with our growth. We’ll also touch on some of the tools we use, challenges we face, and the future we’re working towards.

---

## What is Analytics Engineering at Deliveroo?

[Analytics Engineering](https://locallyoptimistic.com/post/analytics-engineer/), for those less familiar with the term, is a relative newcomer to the many technical disciplines that deal with data and/or engineering. The need for a role that intersected data engineering, analytics and data science materialised in the last 5 years or so, on the back of the emergence of cloud data warehousing, self-service BI tools and data pipeline services.

Leveraging this new and powerful “modern data stack”, analytics engineers are tasked with transforming raw data from multiple sources into well-modelled and reliable datasets that can be used to make better, faster analytically-driven business decisions. As a result, it also requires a deep understanding of downstream data use-cases and requirements, as well an ability to work alongside software engineers where the provenance of data is of concern.

What additional, peripheral responsibilities that belong to the role depend on how exactly the analytics engineering discipline is deployed within the organisation, and we’ll talk about some of those that apply at Deliveroo.

## Early Challenges

Countless tech-focused companies have had to reckon with the dramatic advancement in data tooling and services over the past few years, whether building from scratch or migrating from legacy stacks. Although there are numerous common themes to all of those journeys, each still has its own story to tell, with its own unique challenges.

Deliveroo’s journey and path to modern analytics engineering has been particularly interesting to me, for a couple of reasons.

Firstly, Deliveroo’s genesis, and its emergence as a definitive food delivery company, almost perfectly coincided with the emergence and maturing of the modern data stack. In 2013, when Deliveroo delivered its first order, on-premise data stacks were well and truly on their way out, but the “platforms” replacing them were still in relative infancy. In 2016, when Deliveroo’s growth (and subsequently our hunger for data) were sky-rocketing, we took an early bet on two emergent tools that remain in our stack to this day - Snowflake & Looker. Despite this early adoption, there was no established playbook for realising the full potential of what these tools unlocked. We dove head first into areas like modern data modelling strategies, self-serve analytics, streaming ingestion and virtual warehouse management at a time when understanding and experience were scarce. What’s more, our scale meant we were pushing these tools to their limit in those early days (we definitely still do, though less often), which made the challenge even more compelling.

Ever-present alongside these technical obstacles though have been organisational and process challenges. From staying aligned with stakeholder and partner organisations that are constantly changing around us, to trying to define data domains in a three sided marketplace that is highly intertwined, to preparing for an IPO, to perpetually trying to balance velocity and scalability, we’ve needed to remain flexible, whilst constantly striving for more maturity and refinement.

Hiring the right people for this type of environment, and empowering them to have impact in the right organisational setting was therefore critical. This has been a problem of a perpetually unfolding scale.

## Scale Breeds Specialisation

The first hires in any start-up are almost always generalists, and this is no different for the first data hires.

As Deliveroo’s first analyst, I would be the seed for what would become BI, a team then responsible for analysis and reporting, and by extension data transformations. Our first couple of data scientists, long before they did any actual data science, built our first analytics database and ELT pipeline. We had everything we needed for a little while, without the need for data-focused engineers.

It wasn’t long though before we made our first data engineering hires. They took on the responsibilities of data ingestion, warehouse management and transformation pipelines, whilst the growing BI remained as effective owners of the data itself, and the insights we yielded from it.

Around the time we passed around 1000 scripts in our twice daily SQL transformations pipeline, we spun up an “infrastructure” team within BI to specialise in said pipeline.

There were two final and important factors that elevated the need for what we now know as our Analytics Engineering team beyond doubt.
- BI was merged into a rapidly growing data science org, and it was becoming quickly evident that our commitment to put data science and analytics at the centre of everything we did was increasingly out-pacing our ability to maintain and build adequate, reliable data sets.
- The evolution of what was data engineering into a data services team that owned and maintained our Kafka deployment created a vacuum around our analytics platform tools.

Thus Analytics Engineering at Deliveroo was born.

After an initial period of operating as a small, nimble team focused on both analytics and data engineering concepts, the team started to forge an identity towards the back end of 2021.

## Analytics Engineering in Full Bloom

The last six months or so for the team have been transformative (pun intended), and 2022 is shaping up to be a landmark year for the discipline within Deliveroo.

We’ll be tackling projects related to every corner of the data space, and hope to write about them all throughout the year.

To achieve all of these goals, we’ll need more highly skilled engineers, and we’ve made a great start by growing from a couple of full-time analytics engineers in the summer of 2021 to now more than twenty (and we’re not stopping there). This newfound scale has enabled us to implement some key organisational and strategic changes that empower us to reach the next level of impact, by introducing another layer of specialisation within the team.

The first and most important of these is a move towards domain-focused pods of analytics engineers. Deliveroo’s data estate is vast and complex, and it has been many years since anyone has been able to have even a reasonable grasp on all of our data, across restaurants, rider, consumer, finance and more. These pods will start by embedding within the corresponding data science teams, which is where a lot of the domain knowledge and relationships that we wish to inherit reside. We’ll gradually break free of this dependency as the team grows in size and influence, becoming an independent entity that partners directly with engineers, product managers and business stakeholders from their area of focus. 

The deployment of specialised analytics engineers will result in higher quality data being available for data scientists, machine learning engineers and business users, and will unburden data scientists from this kind of work. The impact, particularly for data science, is thus two-fold: more _time_ to deliver higher _quality_ insights.

To ensure the highest chance of success for this model, we’ve split the team in two, and spun up an Analytics Platform team. This team will focus on all of the “platforms” that host and process and surface the data that domain-focused analytics engineers are responsible for. Snowflake, Looker and Prefect (our orchestration layer) are at the heart of this analytics platform stack, and alongside data integrations, and strong working knowledge of our Kafka streaming platform, the skillset is more akin to a classic data engineer.

What’s more, Analytics Platform are also now part of a newly-formed data platform group, consisting of a well-established experimentation platform team, and a newly forged machine learning platform team.

## A Constantly Evolving Challenge

As has been the case since day one at Deliveroo, we’ll no doubt have to continue to evolve our technical and strategic thinking in step with the internal needs of the business. The organisational model and processes that fit now may not fit us in 12 months time, and that is a reality we've learnt to live with.

What's more, the analytics engineering discipline itself is changing at a rapid pace. The playbook for organisational models and the underlying tech stack is constantly under revision, driven forward by competing vendors, and an ever-expanding community of analytics engineers (many of which we take constant inspiration from!).

Whilst we attempt to scale up to one of the largest Analytics Engineering teams in existence though, we'll yet again come across new challenges seldom tackled elsewhere, and we wouldn't have it any other way.

