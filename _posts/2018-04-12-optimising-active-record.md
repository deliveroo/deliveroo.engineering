---
layout: post
title:  "Optimising a simple ActiveRecord query"
authors:
  - "Joost van Oorschot"
excerpt: >
    Last week a seemingly simple ActiveRecord query was causing problems on production, by being incredibly slow. Together with my colleague Marty I debugged the issue and as a result we decreased the query time from about 80 seconds to about 100 milliseconds.
---

## The problem

The problem occurred in the query in this innocuous looking method, which returns the date of the first order of a restaurant on Deliveroo. The query simply finds the first order that a restaurant has received, and takes its date of creation.

```ruby
def self.date_of_first_order(restaurant)
  Order
    .where(restaurant: restaurant)
    .first
    &.created_at
end
```

This looked pretty efficient and straight forward to me. However, on production this method can take up to 80 seconds to complete!
 
## Diagnosing the issue 
 
Often, a good starting point when debugging ActiveRecord queries is using `to_sql`, to show the SQL that ActiveRecord generates in order to execute the query. Another great method to use when debugging ActiveRecord queries is `explain`, which will show the generated SQL, as well as the query plan used by the database management system to execute the query. This is often useful to debug queries where missing indexes are slowing your queries down. However, for the problem at hand using `to_sql` was enough.

Calling `to_sql` on the ActiveRecord query showed me the following SQL statement. 

```sql
SELECT "orders".*
FROM "orders"
WHERE "orders"."restaurant_id" = $1
ORDER BY "orders"."id" ASC
LIMIT 1;
```

As we can see in the generated SQL, to get the first row of a table, ActiveRecord sorts the table by ascending `id` and limits the query by 1. The culprit here is the `ORDER BY` statement. `ORDER BY` can be very slow, especially on a large table like `orders`, which contains millions of rows. 

## The fix

We can increase the performance of the query if we can find a way to remove the `ORDER_BY` statement. After we have found a better performing SQL query we can create an ActiveRecord query that will generate our desired SQL query. The query that we settled on uses a subquery to retrieve the minimum order `id` for the specified restaurant, which is much faster than doing an `ORDER_BY`. After we have found the minimum order `id` we can simply retrieve the order from the database. 

```sql
SELECT "orders".*
FROM "orders"
WHERE "orders".id = (
  SELECT MIN("orders".id)
  FROM "orders"
  WHERE "orders"."restaurant_id" = $1
);
```

This new query runs in about 100 milliseconds. The only thing that remains is to convert the SQL query back into an ActiveRecord query.

```ruby
def self.date_of_first_order(restaurant)
  minimum_order_id = minimum_order_id(restaurant)
  return if minimum_order_id.nil?

  Order.find(minimum_order_id)&.created_at
end

def self.minimum_order_id(restaurant)
  Order
    .select(:id)
    .where(restaurant: restaurant)
    .minimum(:id)
end
```

Done! The trade off is that the resulting Ruby is more verbose and non-standard, which is why an optimisation like this shouldn’t be made prematurely. However, in this case the performance increase is worth it.

Although the ActiveRecord query that we optimised is very simple, the debugging method of looking at the generated SQL query to figure out what is going on, fixing the SQL query and turning it back into an ActiveRecord query is something that can be applied to any query you want to investigate. Using this method for solving slow queries will also give you an understanding of how ActiveRecord works under the hood, which cool to know and it can help make debugging easier in the future.

### P.S.

An important note on optimising `first` specifically is that the database row with the minimum `id` is not always the one that has been created first. In the specific case of  the code in this post it is okay to use the minimum `id` because the value returned by `date_of_first_order` does not have to be 100% accurate. However, in a different scenario where you need to be sure you get the actual earliest date, you will have to take the minimum of `created_at`.
