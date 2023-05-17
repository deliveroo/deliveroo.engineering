---
layout: post
title:  "3DS rule experimentation and optimization"
authors:
  - "Jack Dai"
excerpt: >
  How we’ve balanced fraud risk and friction: Deliveroo's Journey with 3DS rule experimentation
date: 2023-05-16T16:31:03+0100

---
## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Introduction
Hello there! I’m Jack, a Data Scientist working in Deliveroo's Trust team. The Trust team works on safeguarding Deliveroo and its customers against fraudulent activities and abuse. We tackle various challenges, including payment fraud, compensation abuse, and promotions abuse, among others. Lately, my focus has been on optimising our payment fraud rules. In this blog post, I will share my insights and offer some actionable advice for teams trying to do the same.

## What is 3DS and why is this important?
Any merchant receiving online transactions is at risk of payment fraud - this is where fraudsters use stolen credit cards to transact on their platform. The main way merchants protect themselves and their customers from payment fraud is through the use of 3D Secure (3DS). 3DS is an authentication protocol designed to provide an additional layer of security for online transactions, for example by requiring the cardholder to provide a one-time passcode to help verify their identity.

Payment fraud can impose significant financial burdens to a company’s profitability through various means, such as chargeback expenses and severe financial penalties imposed by card networks like VISA and Mastercard in cases of excessively high fraud rates. While preventing fraud is of paramount concern for companies, employing excessive and inefficient fraud prevention measures can have equally adverse consequences. These measures can detrimentally impact the experience of legitimate customers, leading to a decrease in order volume, profitability, and customer retention.

## How does Deliveroo use 3DS?
Deliveroo decides which transactions to send to 3DS through two main methods:
Machine learning Models (such as Ravelin’s Machine learning model)
Custom 3DS rules. These are rules manually created by our operations team, using Ravelin, to help quash emerging fraud trends they’ve identified, or that we think we need extra protection against.

Ravelin is a fraud detection and prevention company that offers machine learning-based solutions to help businesses combat online fraud. In the payments fraud space, we use their models to prevent fraud, and also use their platform to create 3DS rules.

It is worth noting that other parties involved in the payment processing flow (PSPs and Card Issuers) can also trigger 3DS based on their own fraud engines or fraud rules, so the overall 3DS customer experience is not only dependent on Deliveroo.

So, why not just 3DS everyone?

<figure>
![Hmmm](/images/posts/3ds-optimisation/scooby-doo-meme.png)
</figure>

Whilst 3DS is highly effective in preventing fraud, it comes with its trade offs. Whenever you authenticate a customer, you introduce friction into their purchase journey, and inevitably cause a percentage of transactions to be lost. So, whilst we could send all orders to 3DS and eliminate almost all fraud, we’d see sizable drops in both order volume, profit, customer retention/experience, and negatively impact what is mostly genuine customers. Indeed, extremely high 3DS rates sometimes result in lower authorisation rates as Issuers rate the merchants as riskier.

## Deliveroo's 3DS best practices
The below outlines how we at Deliveroo are thinking about 3DS:
* **We should measure the effectiveness of our 3DS rules.** We should be measuring the impact of our rules to make sure they are not doing more harm than good, and see whether the fraud they prevent outweighs the loss of order volume and profit caused by the increased friction. To do this we use experimentation (A/B tests).
* **We should use a cost benefit lens to determine what’s best for the business overall.** This lens should take into account all financial repercussions of the rule. Of course we want to reduce fraud as much as possible, but by doing so we may not be making the right decision for Deliveroo overall.
* **We should leave the bulk of the protection to models.** Models should be more efficient at identifying fraud than manual rules (lower false positive rate).
* **We should use rules as ‘spike' protection.** Manual rules are still useful, for example in situations where we need to swiftly respond to an emerging fraud vector and do not have enough time to change a model. They are also good for implementing policy decisions we might want to keep separate from models.
* **We should be constantly reviewing and monitoring rules.** Long-lived rules become increasingly ineffective over time as fraudsters move to different fraud vectors. We should constantly monitor to determine if the benefits of a rule outweigh the costs (and therefore it should be switched on), or vice versa.

## Running Experiments on 3DS Rules
The question we first and foremost needed to answer was: how good are our 3DS rules? To do this, we conducted A/B tests (or experiments). We conducted large scale A/B tests over Q4 2022. For each rule that we experimented on, we divided our users into two groups – the control group and the experimental group. The control group was subject to the existing 3DS rule as usual, while the experimental group was exempted from 3DS for that particular rule. We then monitored the performance of both groups. We chose to experiment on the highest volume rules first for speed and practicality. There are a lot of interesting quirks around 3DS experimentation such as the randomization unit, and challenges with overlapping rules which are out of scope for this blog post.

In practice, we ran all of the experiments through Ravelin. Ravelin’s rule platform and UI makes it extremely easy to run A/B tests, without the need for engineering work traditionally required for experiments such as adding feature flags and relevant data logging. We used the Ravelin tags feature to split our population into groups, and made use of Ravelin’s rule hierarchy to exempt the correct orders from 3DS.

## Thinking in terms of cost benefit
To evaluate the rules, we devised an equation that accounted for various financial factors beyond fraud prevention alone that the rule could have. Instead of just thinking about the fraud it prevented, we added in information about the operational profit, 3DS fees, and any additional compensation costs. Below shows the equation we used.

Cost benefit = Additional Operational profit + 3DS fees saved - Additional Chargeback costs (inc. fees) - Additional Compensation costs

Another thing we consider when removing rules is fraud rates - Card schemes (such as VISA and Mastercard) impose strict penalties if you breach certain fraud levels. We always make sure to keep well within card scheme rules by keeping our fraud rates very low.


## Our results
Based on our analysis of the data, we identified a large number of rules that were overly restrictive and were on balance net negative to the business. By optimising those rules we have been able to and reduce our 3DS rate by nearly 40% without exposing Deliveroo, our customers or partners to additional fraud risks. As a result, we’ve been able to reduce friction for genuine customers, improving conversion for Deliveroo and increasing orders for our partners and riders. A win-win-win-win.
