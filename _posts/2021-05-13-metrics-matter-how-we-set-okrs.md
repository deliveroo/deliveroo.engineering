---
layout: post
title:  "Metrics matter - how we set OKRs at Deliveroo"
authors:
  - "Charlie Sabine"
excerpt: >
  Learn more about how we set OKRs at Deliveroo.
---

OKRs stand for Objectives and Key Results - objectives are relatively high level things that we wish to focus on as a company - for example “reducing fraud and abuse”, whilst key results are the way that we measure success against these objectives. 

OKRs are fairly well established in the literature - see for example [this post](https://www.whatmatters.com/faqs/okr-meaning-definition-example/) about some of the history behind them. This blog post details Deliveroo’s specific experience and guidance to how we set OKRs internally - namely the “key results” part, as these are typically the most difficult to get right. 

At Deliveroo we use two main types of key results - ship goals, and metric goals. An example of a ship goal might be “launch Deliveroo Plus in France”, whilst a metric goal might be “increase Plus profitability by 10%”.



# Metric goals

In setting metric goals, we consider three main factors:

1. Choosing the right metric
2. Ensuring the metric can be measured 
3. Setting the right movement of that metric

## Choosing the right metric

This is often the most difficult part. Below I explore some things to consider when trying to choose a metric in the first place:

### Ability to influence within the team

If a metric is set for a team, the team should have the full ability to influence all parts of that metric - otherwise movements in the metric (and therefore hitting their goals) are outside of their control. 

An example here is around negative order experiences (e.g. when a customer orders food but it never turns up) - at Deliveroo we have a broadly defined metric for these which we use to measure improvements to customer service levels. These negative experiences can be caused by multiple issues - for example due to our delivery network algorithms, or due to customer fraud. If the delivery network algorithm team is goaled on reducing these experiences but it turns out that an increase in consumer fraud causes the metric to rise, then the team should either have their scope widened, or the goal should be spread across multiple teams - one responsible for the delivery network element, one responsible for the consumer fraud element, etc.

### Ability to influence within the timeframe set

Some metrics might measure exactly what we want, however take a long time to influence. An example here could be something that relates to the signing of legal contracts (e.g. partnerships). If an engineering team is goaled on increasing our product offering to improve likelihood of signing these partnerships, but contracts are typically only revisited on a yearly basis, then a Q3 goal to increase this number may not make sense, as contract negotiations will likely take too long. In this example, setting a longer term goal might make more sense, or alternatively using other proxy metrics for Q3 goals, with the overall metric measured but not goaled against in the short term.

### Ability to influence - and realistically take credit for

If OKRs are set for a specific team, but the overall metric is ultimately influenced by factors outside of that team (e.g. commercial or legal) - should this metric be used? The above example again works here - signing legal contracts obviously has a large reliance on teams other than engineering, meaning that meeting the goal may be entirely down to another team, or alternatively not meeting the goal also may be no fault of the team in question.

Another example here is around overall profitability. One metric may be “increase profitability from X to Y” - whilst this makes sense for the whole company to be goaled on, it is not the responsibility of one single team. Instead, this metric could be changed to be e.g. “increase Plus profitability from X to Y” - if measured experimentally, we can calculate the cumulative impact of one team on this metric, and therefore realistically the team can take credit. Cannibalisation is important to take into account here - see later section.

### Gameability - don’t move the goalposts

Don’t make goals that are easily gameable by the team that is responsible for them - if you set a goal of “increase metric X by 10%” and then simply change the metric definition at the end of the timeframe, any team can easily achieve the goal.

Instead, doing some work upfront to set metric definitions will help to keep teams accountable. Metrics can change definition if new information arises and is relevant, so long as this is recorded and goals are updated accordingly if needed. 

### Give metrics meaning

Related to gameability, metrics should be defined in such a way that we actually care about their outcome. An example is the difference between “number of users” and “number of active users'' - the former could be gamed by promoting low-intent users to sign up with no concern for whether or not they actually place any orders. “Number of active users” however includes the “...and placing orders” assumption on the metric, so in this case better measures the actual business outcomes that we want (new users lead to more orders), whilst still being relevant to e.g. the growth team. 

### Decomposability

If we see a movement in a metric, we ideally want to be able to tell why the move happened - which means we will likely need to decompose it into its constituent parts. An example is order growth - if we see order growth changing, we can break this down into geographic regions, types of users, new vs old customers, order types. This of course all relies on the relevant data being logged - the metadata used to decompose the metric needs to be readily available, such as the geographic region that an order was placed in.

### Consider cannibalisation 

In the above example of increasing profitability of one part of the business, the downside here is that if one team pursues this goal, it could have negative consequences elsewhere in the business - i.e. one product cannibalising another. 

To counter this at Deliveroo, our experimentation platform has a suite of “do no harm” metrics which measure the impact of any experiments on one product across other products or areas of the business. This way, we can catch any possible degradations early, and make decisions on whether prioritising hitting one goal over another makes sense for the wider business.

### Internal-facing products and proxy metrics

At Deliveroo we have a number of internal facing teams - for example our production engineering team, and our experimentation platform team who work on facilitating data scientists’ ability to run experiments. The ultimate goal of these teams is to level up the ability of the rest of the organisation, ensuring stability and consistency. As a result, their impact on any outward facing metrics such as profitability or growth is likely to happen only via second order effects.

Typically for these teams we will use a number of proxy metrics instead for goaling purposes. Using the experimentation platform team as an example, we have historically goaled this team on the number of active users of the platform. The logic here is that by increasing the number of active users of the platform, we will free up more time for data scientists to work on more impactful projects or allow them to increase their scope, ultimately saving the company money and ensuring we make more consistent and accurate business decisions. 

## Ensuring the metric can be measured

To measure success against metrics, we need to be able to calculate the metric.

### Does the data exist to calculate the metric

Firstly - you cannot measure a metric if the data doesn’t exist. It is likely you already record all the relevant data for e.g. orders, or users, however more complex metrics there may be upfront work to be done to either add new data logging, or data pipelining work. An example here is the “negative order experience” metric - at Deliveroo we use a version of this which aggregates a number of possible factors, combining it into one headline metric that we can use as an OKR. Before we were able to goal on this metric, the metric had first be well defined, and pipelines had to be created so that we could report on our progress against it.

### Consider the tradeoff of effort required to measure a metric

For some metrics, we cannot get the data for them even if we tried with reasonable effort. In these scenarios, we either need to calculate some sort of proxy metric, or change the metric entirely. An example here could be reducing false positives due to an unsupervised algorithm - if we cannot measure false positives without manually labelling data, which would require a labour-intensive effort, then perhaps this is not the right metric. 

## Setting the right movement of a metric

Once you’ve defined a metric, you need to define what the goal of the metric is - e.g. increasing adoption of a product from X% to Y% of our active user base.

Goals have to be within the realms of possibility, but also stretch the team to achieve them. At Deliveroo we typically do not expect the company to hit all of its internal product team goals, as this would likely imply that targets were too easy to hit. To combat this, our leadership team reviews past OKRs each quarter to assess whether our goal-setting process was too aggressive or not, and uses this to feed back into the next round. Note that externally-facing goals or commitments to the Board and investors are very different - this blog post solely focusses on internal goals. 

Factors to consider when aiming to choose the “X” that a metric needs to hit are:

### Do we have other comparisons that we can look at?

An example here is that if we saw a previous year’s work achieving a 10% reduction in some metric, do we think that another 10% reduction is achievable (given likely diminished marginal returns)? What about if past analyses or experiments have given us a figure that we believe is achievable? 

### Is the movement realisable?

We shouldn’t set movements that are out of the realms of possibility. For example, increasing the share of wallet of payment method X to 50%, even though less than 50% of our users are capable of using this payment method. At Deliveroo we usually perform this sort of due diligence by getting all OKRs reviewed by multiple other people, who can additionally sense-check whether the metrics are realistic or not.

### Can market research or external data help?

An example here is where third parties might publish market data on fraud solution false positive rates - if this data is available, we can use it to benchmark our own goal setting in this area. 

### Does the goal tie in to some other wider company objective?

An example here might be related to order growth - if we have a company-level goal to achieve growth of X%, then our bottoms-up aggregation of all goals should equal that X%. Of course the “realms of possibility” argument is relevant here, but it is useless setting a company-wide goal of growth of X when the sum of each individual team’s goals is less than that X.



# Ship goals

Broadly speaking, ship goals are less preferable to metric goals - before deciding to choose a ship goal, ideally the above “how to choose a good metric” approach should have been exhausted. Ship goals reduce the autonomy of teams - as the goal is essentially “do this thing”. But sometimes you really do just need to do this thing.

Below are some examples of when ship goals may be necessary. 

### 0 to 1 products

For some features or products, we simply cannot know the impact before we launch them, as they are in entirely unknown territory. Here, if we have solid business reasons for the product, then a ship goal can be relevant. An example here could be a new feature where we might have market research and competitor intelligence that tells us that this is the correct feature to launch, however we do not know in advance whether we can really expect 5%, 10%, 20% of users to use the feature - so setting a “usage” goal would be a complete stab in the dark anyway. 

### External factors - contractual agreements, or legal obligations 

Sometimes we simply have to do something - for example be GDPR compliant. Other times, there is a big contractual reason why we should do something - for example if we believe that launching a large new partner in the UK requires a certain product feature, then we could argue that implementation of that product feature should be a ship goal.

### When a metric just doesn’t make sense or work for the timeframe

Sometimes setting up proper metrics might take a considerable amount of time, which doesn’t help if it’s already March and you’re setting Q2 goals. In this case, ship goals may suffice for the time being. Similarly, some goals may not really make sense to have proper metrics for, or they may be impossible to measure via a metric.

An example here is Deliveroo’s recent IPO - for this, we had a set list of things to achieve to be “IPO ready”, and therefore set ship goals against milestones we needed to achieve to get there. 



# Tracking goals once they’ve been set

Once goals have been set, we want to track our progress against them. 

### Dashboards vs static analyses 

For some goals, setting up pipelines and continually monitoring progress against goals makes sense - for example if our goal is to get take-up rates of some product to 50% of our active user base, then setting up a dashboard that tracks this usage can be a helpful motivational tool for the whole team to see how their work is influencing the metric.

However, for others, offline static analyses will suffice. Some metrics may rely on survey data rather than some constant data feed, in which case given that surveys can only be ran at distinct time intervals, a fixed cadence of reporting results makes more sense. 

### Measuring cumulative experimental impact

If your goal is something like “increase profitability from a certain product from X to Y”, likely individual product feature launches will be run as an experiment, to see their impact on profitability. However, at the end of the time period, we will need to calculate what the cumulative impact is of all the product changes. 

There are two common approaches to this. The first approach is to have a fixed holdout group which remains in place for the entire time period (e.g. a quarter, half, or year). All changes to the product can be calculated relative to this holdout group, to see the cumulative impact of product launches. The pro of this approach is that interaction effects are taken into account - if two separate product feature launches are not independent, the combined impact of them launched together is likely not equal to the sum of their individual experiment results. An overall holdout takes this into account. The downside, however, is that a set of users will have a different app experience for a long period of time. If our population is small, this holdout might need to be high in order to get statistical significance - e.g. 10% of all users. 

Alternatively, a “sum of experiments” approach can be taken. This is where each individual product feature launch is measured in isolation, and the sum of their impact is assumed to be the cumulative impact had. The main downside here is the interaction effects problem explained above - likely the total impact will be less (or possibly even higher) than the individual sums. However, the benefit is that holdouts only exist during experimentation, and features can be launched more widely. Accuracy of results is traded for a better, more consistent user experience.

### Don’t go overboard

Setting goals takes time - particularly data scientists’ time. There is always more work that can be done on a set of goals - could we improve our forecast model? Could we define our metric better? Could we build some beautiful dashboards to track our progress? The answer is always yes, but we don’t have infinite data scientists. OKRs, at a high level, are intended to ensure that we are on the right course and making progress. We will likely continue to iterate on our OKR setting process as we mature as an org, so no doubt our earlier attempts at OKRs will not be perfect - however the above guide should hopefully ensure that they are at least “directionally correct”. 



# A motivating example of OKRs in action at Deliveroo

Greg Beech (former principal engineer at Deliveroo) tweeted about his previous positive experience with OKRs whilst working on the Care team:

[https://twitter.com/gregbeech/status/1236707894588039170](https://twitter.com/gregbeech/status/1236707894588039170)
