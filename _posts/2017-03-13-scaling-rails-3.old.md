---
layout: post
title:  "Scaling Rails 3.old"
authors:
  - "Michael Groble"
excerpt: >
  We're not particularly proud that we are still using Rails 3.2, but we _are_ extremely
  proud of scaling our traffic over the last few years. Our new services are built in Rails 5,
  but we still have a hefty chunk of functionality in our original Rails 3.x monolith. A rueful
  "rails 3.old" hits our slack channels as someone stumbles across an issue as they switch back
  to the monolith. Growing our business, features and team over the last few years has left
  little time to do a wholesale upgrade of the monolith platform.  Here are some tactical things
  we've done to help it keep pace with our growth.

---

## Migrations
If you are coming from Rails 5, you can add lines like this to your migration and expect helpful things to result.

```ruby
add_index :redeliveries, :parent_order_id, algorithm: :concurrently
t.references :order, index: true
t.references :admin, null: false, foreign_key: :user
```

These in fact are all examples from our monolith code base and none of them do what they intend to.  Rails 3 doesn't
support the `algorithm`, `index` and `foreign_key` options and silently ignores them.  At our current scale, locking
a table to add an index, or forgetting to add a foreign key constraint or index in the first place can cause outages
so we've added some safety nets.

Gems like [zero_downtime_migrations](https://github.com/LendingHome/zero_downtime_migrations) and
[strong_migrations](https://github.com/ankane/strong_migrations) look to help catch certain problems, but don't ultimately
do the job.  They will accept an `algorithm: :concurrently` annotation, for example, even though the generated SQL command does
not create the index concurrently.

We use both [immigrant](https://github.com/jenseng/immigrant) and [lol_dba](https://github.com/plentz/lol_dba) to keep
on top of our migrations.  Immigrant is robust enough to integrate into our Continuous Integration system and fail the
build when foreign keys are missing.  But lol_dba generates too many false positives so we check foreign keys like
immigrant does and fail the build when our foreign keys aren't indexed.

## Database
Our database design has been performant for core use cases from the very beginning, but we've had to introduce three
particular technologies to maintain performance as we've scaled.

We've introduced pgbouncer to reduce connections to our database as we've horizontally scaled our application servers.
We use activerecord_autoreplica to distribute read queries to replicas.  And finally we use monitoring, rack timeouts
and aggressive statement timeouts to catch and kill long-running queries.

For pgbouncer, our [fork of the buildpack](https://github.com/deliveroo/heroku-buildpack-pgbouncer/tree/resolve-stunnel-dns-at-connection-time-idle-settings)
introduces a number of small improvements

* robustly parses the database URL, unescaping it correctly and ignoring extraneous parameters (such as `?pool=5` which
  is really a parameter for the ActiveRecord adapter, not pgbouncer)
* reports pgbouncer stats to DataDog
* forces stunnel to resolve DNS at connection time so it gracefully handles database failover scenarios

In the beginning, our operational database also drove our reporting and invoicing functionality which led to some lengthy
web requests and database statements. Adding both statement and request timeouts have helped us identify and fix those
problem areas.  Our [fork of activerecord_autoreplica](https://github.com/deliveroo/activerecord_autoreplica) mainly
improves robustness in connection cleanup to handle both these timeouts and database failover scenarios.

Finally, we've also had to patch Rails itself to get the most out of the autoreplica gem.  The short summary is
that `pluck` statements were never going to replicas, only to the master because ActiveRecord in Rails 3 generates
an `exec_query` statement for a `pluck`.  The autoreplica gem will only send a command to a replica if it starts
with `select_` so this patch does that.

```ruby
if defined?(::ActiveRecord::VERSION::MAJOR) && ::ActiveRecord::VERSION::MAJOR.to_i == 3
  module ActiveRecord
    class Relation
      def pluck(column_name)
        if column_name.is_a?(Symbol) && column_names.include?(column_name.to_s)
          column_name = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(column_name)}"
        end

        result = klass.connection.select_all(select(column_name).to_sql)

        result.map do |kv|
          name = kv.keys.first
          klass.type_cast_attribute(name, klass.initialize_attributes(kv))
        end
      end
    end
  end
end
```

## Redis
We could not function at scale without Redis, but have had to come up with a number of forks to get the most out of it as well.

We are a very data-driven organization and to date we've used the Split gem to help drive our A/B testing approach.  It wasn't
until  it was widely used in the code base that we realized how very inefficiently it uses Redis.  Our
[fork of split](https://github.com/deliveroo/split/tree/ab-tests) allows us to query multiple experiments at once and defer
cleanup until later which has greatly improved our Redis load.

Even with that optimization, we need to shard across multiple Redis instances.  Our forks of
[redis-rb](https://github.com/deliveroo/redis-rb/tree/distributed_mget) and
[redis-rack-cache](https://github.com/deliveroo/redis-rack-cache/tree/sharding) allow us to use multiple shards
for both Rails and Rack caching (among other uses).

We've recently been migrating from Unicorn to Puma and have stumbled upon yet another deadly case of silently ignored options.
Releases of [redis-activesupport](https://github.com/redis-store/redis-activesupport) since v4.1.0 have supported both
connection pool parameters and distributed shards via a configuration similar to the following.

```ruby
RedisStore.new "localhost:6379/0", "localhost:6380/0", pool_size: 5, pool_timeout: 10
```

That is an important scenario for us and we've been running a configuration like that for months now. After flipping
from Unicorn to Puma, we saw both CPU usage and MGET command counts go way down on our Redis cache instances.  Sure enough,
the support for those pool parameters aren't in the version that works with Rails 3.  The dependency nightmare that exists in
all the little redis-store gems means that we will likely need to fork and backport this pool support to move forward with Puma
or add `Redis::Distributed` support to [readthis](https://github.com/sorentwo/readthis).

## Path Forward
The good news is that we are on the latest versions of both Postgres and Redis in production so the Rails stack itself is
our last sticking point.

We're hiring aggressively and our general preference is to use our expanding engineering team to chip away at the
monolith, reduce its footprint and replace existing functionality with new services using the latest frameworks.  That is the path
we have been on for months now and it is accelerating as we get those first services running in production.

Tracking down the last Redis cache pool gotcha is what finally prompted me to write a blog post about our experiences.  If
Rails 3.old is popping up in your slack channels as well, hopefully you find some value in our forks or let us know of
alternatives you use to keep things running.  Maintaining an old code base is always an adventure.

And if you're interested in working with us and have actually migrated a monolith off of Rails 3, don't think you need to
hide that on your resume.  We promise we won't lock you away to work on that for your first weeks.  We spread infrastructure
and platform work across all teams and have way too many interesting things going on to monopolize your time like that (although you
_may_ get bonus points if your code flags invalid option usage)!
