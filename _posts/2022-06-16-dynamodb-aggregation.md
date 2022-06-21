---
layout: post
title:  "Real-Time Data Aggregation Using DynamoDB Streams"
authors:
  - "Michael Seymour"
excerpt: >
  DynamoDB is great for quick data access, low-latency and scalability. However,
  one downside is that it does not support aggregation functionality like 
  relational DB's do. This is how we tackled this problem using DynamoDB Streams...

---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

In this post I break down how we aggregate our 'favourites' data at Deliveroo. Our 'favourites' data is stored in DynamoDB and what makes the aggregation interesting is that DynamoDB does not support aggregate functions. The TL;DR is that we decided to use a DynamoDB Stream which invoked a Lambda function that updates an aggregate table. Keep reading for more details.

## What Are 'Favourites'?

In December 2021, we added the ability for our users to favourite restaurants. This is what that looks like:

<figure class="small">
<img src="/images/posts/dynamodb-aggregation/fav_restaurant.gif" alt="Favouriting a Restaurant" style="max-width:461px">
</figure>

Clicking the heart favourites the restaurant, and clicking it again un-favourites the restaurant.

## How is Favourites Data Stored?

A user's favourite restaurants are stored in DynamoDB. Here is a simplified schema of our table:

<figure>
<img src="/images/posts/dynamodb-aggregation/fav_table.png" alt="Favourites Table" style="max-width:600px">
</figure>

When a customer favourites a restaurant, a new item is inserted into `Favourites`. When the customer un-favourites a restaurant, the item in `Favourites` is removed.

## Our Goal

We want to aggregate the favourites data (over all time) so that we can get the total favourite count per restaurant.

At the moment, this data is only required for this “most favourited places” list that appears on our customers' feed:

<figure>
<img src="/images/posts/dynamodb-aggregation/fav_carousel.png" alt="Most Favourited Places List" style="padding:10px;border:1px solid #CCC;background-color:#FFF;border-radius:5px;">
<figcaption>
A list of restaurants ordered from most to least favourited
</figcaption>
</figure>

In the future, we’ll be using this aggregated data for many other features, such as displaying the total favourite count per restaurant:

<figure>
<img src="/images/posts/dynamodb-aggregation/fav_metadata.png" alt="Most Favourited Count" style="max-width:375px;padding:0;border:1px solid #CCC;background-color:#FFF;border-radius:5px;">
</figure>

## Aggregating the DynamoDB Data

### High-Level Design

As mentioned earlier, DynamoDB does not support aggregate functions. Therefore, there’s no magic `SELECT SUM` or `GROUP BY` clauses like in relational databases. 

Instead, to aggregate favourites we implemented the following design (more details below):

<figure>
![System Design Diagram](/images/posts/dynamodb-aggregation/sys_design.png)
</figure>

1. We created a new DynamoDB table to store aggregated favourites data with this schema (simplified for the sake of this blog post)

    <figure>
    <img src="/images/posts/dynamodb-aggregation/agg_fav_table.png" alt="AggregatedFavourites Table" style="max-width:700px">
    </figure>

1. We enabled a [DynamoDB Stream](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html) on the `Favourites` table which sends DB events (`INSERT`, `MODIFY`, `REMOVE`) to a Lambda function.

1. We implemented the Lambda function to do the following:
    1. Receive a batch of events
    1. Filter the relevant events (we only need `INSERT` and `REMOVE` events)
    1. Calculates how many favourites each restaurant has increased/decreased by
    1. Atomically increases/decreases the `favourite_count` for the restaurant by updating the `AggregatedFavourites` table in an isolated transaction


### Implementation Details

#### Atomic Updates
Multiple Lambda functions could be running at the same time so it's important that `favourite_count` is updated atomically to prevent a race condition. This is done using an an update expression, but instead of using the `SET` action, we use the [`ADD`](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Expressions.UpdateExpressions.html#Expressions.UpdateExpressions.ADD) action. 

#### Lambda Retry Strategy
An ['event source mapping'](https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html) is configured to read from our DynamoDB stream and invoke the Lambda function. We have it set so that it only sends up to 100 events to the Lambda function per invocation, and if the Lambda function fails, we'll retry up to 20 times before the events are sent to a dead-letter queue. In addition, the batch of events gets [bisected on every retry](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-lambda-eventsourcemapping.html#cfn-lambda-eventsourcemapping-bisectbatchonfunctionerror).

#### Transactional Updates
The Lambda function receives a batch of events and may have to update the `favourite_count` for multiple restaurants on each Lambda invocation. However, DynamoDB does not support a batch update function. Hence, we are making use of [DynamoDB Transactions](https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_TransactWriteItems.html) to ensure that the batch of events is never partially processed (if the Lambda has an error halfway).

### Pros & Cons of This Design

<table>
    <thead>
        <tr>
            <th>Pros 🙌</th>
            <th>Cons 🤷</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>
              <ul style="margin: 1em auto;">
                <li>Aggregation is done in real-time</li>
                <li>Aggregation is done asynchronously (doesn't slow down the API)</li>
                <li>Design is scalable (greater favouriting throughput will simply invoke more Lambdas)</li>
              </ul>
            </td>
            <td>
              <ul style="margin: 1em auto;">
                <li>Data integrity: If the Lambda fails to run the aggregate table could get out-of-sync</li>
                <li>Complexity: Adding a Lambda adds complexity to the system</li>
              </ul>
            </td>
        </tr>
    </tbody>
</table>

### Results

Our Lambda is invoked approximately 7k times per day. The average Lambda duration is 25ms and the average memory usage is 64MB. This means that this aggregator has a very minimal cost of < $1 per month.

There was also no significant amount of load added to DynamoDB.

So far, this system has been working very reliably and it's been great to have aggregated data which is aggregated in real-time which has opened the door for a few interesting projects.

### Alternative Designs Considered

#### Daily Full-Table Scan

We could have done a daily (or even weekly) full-table scan of the `Favourites` table. In this case, the aggregate data would no longer be realtime, which was fine for our use cases. However, we have millions of items in the `Favourites` table and doing so would have been expensive, so we didn't pursue this option.

#### Synchronous Instead of Asynchronous Aggregation

Instead of using a DynamoDB Stream + Lambda to aggregate the data, we could have done all the logic from the Lambda in the Golang service (in the `SaveFavourite`/`UnsaveFavourite` API handler).

 - Pros: Less complex (as we wouldn't need a Lambda)
 - Cons: Increased API latency, increased risk of API bugs & downtime

For us, decoupling the aggregation from the API handler was important so that's why we didn't pursue this option.

## Seeding the Aggregated Data Table & Keeping It In-Sync

The aggregate table was seeded using a once-off script that did a full-table scan on `Favourites`.

We first considered this approach:

1. Do a full-table scan on `Favourites`
1. Maintain a map of restaurant id -> favourite count
1. Update the `AggregatedFavourites` table

Running this script could potentially take a few hours. If our users are busy favouriting/un-favouriting restaurants during this process, this could result in the seed data being very stale by the time the once-off script updates the DB.

Although we can, we did not want to disable the ability to favourite restaurants while seeding the `AggregatedFavourites` table.

Instead, what we did is iterate over each of our restaurant ids, and then for each restaurant we:
1. Used a scan to sum up just that restaurant's favourite count
1. Update the aggregate table

Scanning the table for just 1 restaurant is much faster (a few minutes) which means that the seed data is very unlikely to be stale.

The seed script processed restaurants concurrently and took just under 1 hour to run, aggregating 6M `Favourite` items in total.

We are still considering running this script on a schedule (every week or so), just in case the data in `AggregateFavourites` ever gets out of sync.

## Conclusion

I had a lot of fun working on this aggregator - I hope you found this post helpful. If you're interested in working at Deliveroo, please visit our [careers page](https://careers.deliveroo.co.uk/), and also check out [@DeliverooEng](https://twitter.com/deliverooeng) on Twitter.
