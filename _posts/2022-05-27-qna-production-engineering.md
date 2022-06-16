---
layout: post
title:  "Q&A with a Production Engineer @ Deliveroo"
authors:
  - "Sanyia Saidova"
excerpt: >
  There's a lot to being a production engineer at Deliveroo, and there's no better way to answer this than in a Q&A fashion. So here are some of the questions I get asked and my answers to them. :)

---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## What do I do?

I am a senior software engineer working at Deliveroo for nearly 1.5 years, focusing in the production engineering space, where we create abstractions for our platform and improve developer effectiveness. Prior to joining Deliveroo, I worked in a mixture of infrastructure and software development roles. My previous experience ranged from working in a telecoms based company, which was largely on premises, to a consultancy that allowed me to experience multiple cloud environments.

## Why Deliveroo?

I joined Deliveroo during one of the pandemic waves - around January 2021. Although my interviews were mostly remote, I felt instant chemistry with the engineeers who interviewed me - a majority of the time spent in the interviews didn't feel like interviewing. Looking into the engineering team before joining, I also learned that a lot of the engineers are active contributors to open source projects and have been involved in conferences [like AWS re:Invent](https://www.youtube.com/watch?v=EFIMpgSgSaQ). I used to work in engineering environments where contributions to open source and involvement in public spaces were held back with a lot of red tape. I was looking for a team where I can be encouraged to help others and think about how I can help contribute to a larger tech community, and Deliveroo provided that.

## What have I done since joining?

Although I only joined in January 2021, I have since been promoted to a senior software engineer which wouldn’t have been possible without the support of our great managers who were able to provide actionable advice. We also have an internal framework for expecations which allows engineers to see what they can target at each level - this has helped to create an open conversation about what to target and what needs to be done to meet those targets.

Since I've joined, I've been actively involved in refactoring our database monitoring (which is still a work in progress - harder than I thought), refreshing our onboarding training and documenting our overall architecture, which will feed into improvement work to address a future of more customers.

## What are the main problems production engineering aim to solve?

Production engineering exists to standardise our approach to building infrastructure and to deploying code. We build internal tooling to offer teams a way to perform deployments and plan infrastructure builds without having to worry about security and reliability configuration which we want to set as defaults.

Although we have a set of internal tools we maintain, Deliveroo is growing in engineering capacity and customer base, so the next challenge is looking at whether our existing workflows and architecture will suit the growth in engineers and customer we expect. One of our main focuses is rethinking our load and integration testing strategies since we plan to split our infrastructure to be isolated on a per market basis. With this change, we have to look at how we can ensure changes are homogenous across all markets and that our tests can reliably highlight capacity limitations. Ideally the solution shouldn't change our developers' workflows too much but add additional visibility into performance bottlenecks, which will help us confirm if we've made the right architectural choices.

## What's on the horizon for production engineering?

We’ve recently hired a new VP, [Megan Bigelow](https://www.linkedin.com/in/megan-bigelow-0a470a2/), that will be heading up the production engineering space. There are big plans in this space, including the potential for a specialised SRE team. Because we’re focused on growth and expanding into new markets, building out the SRE team means we'll have a dedicated team that will look at enhanced monitoring (i.e. what we can do to improve our network architecture to capture more data on latency and inter-service connectivity patterns) and create action plans to address pinch points that come up with added load. 

## Why would you recommend working as a production engineer at Deliveroo?

Production engineering at its core is about improving developer effectiveness, thinking about overall infrastructure stability and making changes to our infrastructure without disruption to existing services. A team like this exists at the phase of a company where it's stable and can predictably expand into additional markets. I would recommend working in this space for the stability and because of the ease of working with our customers, who are other engineers. You're also required to know more about low level network, operating system and database concepts, so if you're interested in becoming more specialised in these areas, we're hiring! :)
