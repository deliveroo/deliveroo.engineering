---
layout: post
title:  "Hitting the Scale Button"
authors:
  - "Amy Harms"
excerpt: >
  It’s been a year since I arrived at Deliveroo to help build out the site reliability engineering team.

  We spent a lot of time in the first month just brainstorming what this means for Engineering at Deliveroo and then what was in scope for the backlog and then how to still deliver “all the things.”  It was a heady time (although to be fair, all the times are heady here!) as Deliveroo prepared to move from a major industry 3rd party PaaS platform and a communal Jira project called IP (for Infrastructure Projects) that was democratically worked on by any of all teams as needed and to a full time Tools and Infrastructure team that would undertake the biggest of all efforts: a completely new cloud platform owned and managed by an internal team to give the business the maximum flexibility around technology choices and delivering our growth strategy.

---

When we started:
1. We had a monolith Rails application that we would start to  aggressively and actively decompose.
2. That application monolith had a monolithic db, a bottleneck to our planned growth.
3. We wanted to give all of Engineering teams control of their own infra
4. After serious reliability issues in late 2016 and early 2017; we needed to find ways to improve our reliability and our ability to manage incidents of any size.
5. After a few years of intense growth, we had some serious tech debt that we needed to pay back.

So we embarked on a major programme to improve the live service reliability, the health of the database and to build a new platform.

Fundamentally we had two problems: technical limitations in our architecture and reliability issues hampered by process and/or culture. There are loads of things that were happening around us and supporting us so the rest of this post will lay out what we tackled from the perspective of platform engineering. But just a quick word of thanks to our Recruitment team, our commercial Legal, and Procurement teams who collaborated brilliantly every step of the way with us and made sure that those things went smoothly.

From a technical perspective, we realised that we needed a new way to deploy infrastructure, manage releases and improve reliability. So we first did a lot of work on the current platform to ensure several quarters of growth by:
We implemented a “reliability monitor” for each team and service to shine a light on reliability issues in real time. This in turn drives a culture where engineering prioritisation can make clear choices between the live service and new features. Think bug or error “budgets” via internal dashboards
We also did a deep dive in database health and pursued a 2-part effort to shape up two of the most heavily used tables and prevent the db from bottleneck growth for a few quarters.
We created a weekly review for all of Tech (and in future all of Deliveroo e.g. our global Customer Support team etc) to look at and understand the health of the live service for the past seven days.
We undertook the implementation and days to day operation of a hugely successful bug bounty programme.

After we “bought some runway” for the current platform, we then had the breathing room to focus on building the new one. (It’s worth noting that Deliveroo is an Agile, cloud-native tech company which comes with a lot of inherent advantage or privilege. We never had to debate or persuade anyone about why we would use containers or re-design CI/CD or use AWS.) We then spent 6 months doing 3 things:
Our tools and infra team researched, designed, and built the new platform for the scale and reliability that the business growth will demand for the future.
We then migrated every app and service to the new platform whilst running the original platform over the course of two quarters.
We focused relentlessly on “engineering customer support” to assist our coworkers grapple with the new Platform and evangelise it! Clinics, presentations, a dedicated Slack channel, Tech Talks, Huddle talks, internal blog posts etc.

From a cultural and process point of view, we really needed to set the bar that our reliability of the live service was a product feature. My mantra is “customer first; live site first,” no would ever disagree with. So much of moving fast and scaling a startup pulls you away from focusing on reliability. But to get to the next level, you need reliability as a fundamental building block.

First we focused on a pain point which for us was the on-call experience, and then we solved by:
Launching Readiness Exercises for everything already in production to ensure everything was supportable for failure cases. We also made these mandatory for the launch of new services.
We implemented an Incident Management Framework and to make sure that we matched our response to the impact of an incident and that we could learn and improve regularly.
We moved from a single, small, voluntary on-call rota to broad team-based rotas where all engineers are on-call for the services that they own. This has been a huge driver of accountability and inherent quality choices. It has also reduced the stress of being on-call as the subject matter requirements are more relevant.
We hired for Platform Engineering roles to help with the scope and reach.
We implemented weekly live service health reviews to focus as a tech org on everything that impacted the live service in the previous 7 days. These were blameless and learning opportunities for improving incrementally week by week and team by team.
We worked diligently with all aspects of the business, including Legal and other teams to prepare for and be ready for the arrival of GDPR in May.

I was at the LeadDev conference yesterday where the fabulous Alice Goldfuss at GitHub outlined almost exactly what we have done technically in her talk “The Container Operator’s Manual.” She also prepped folks that they should probably budget a year. I was high-fiving my team for our “6mos!”

It’s been an amazing year. To quote our own Ben Cordero, we have now implemented the “scale button” for our global and future growth and reliability.
