---
layout:     guidelines
title:      "Redis (in Ruby)"
subtitle:   "Guidelines on using Redis in Ruby apps"
collection: guidelines
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Model classes

Make classes as Rails-y as possible:

- Use `ActiveModel::Validations` (in Rails 3) or `ActiveModel::Model` (in Rails
  4+)
- Implement `find_by(id:)`, `find_by(foobar:)`, `save`, `save!`

Do _not_ just "use redis" in random classes, just like you wouldn’t write SQL
queries in, say, a controller. Instead, wrap your Redis usage in a model class.


## Key naming

- Separate keys with `:`
- The first component should be the underscored name of the model class
 
For example:

```
# DriverStatus
driver_status:{driver_id}
```

High-cardinality key components should be at then end (so we can look at the
"tree of keys” meaningfully). So, for a set of order IDs…
 
Good:
 
```
users:order_ids:{user_id}
```

Bad:

```
users:{user_id}:order_ids
```

## Data modeling

It is acceptable, but not required to have exactly one hash key per record.
The one-hash-per-record approach mimics ActiveRecord more closely, but can 
defeat the purpose of using Redis—it has faster, more advanced data structures.
 
Like other non-relational stores it’s often best to store data in a format 
that’s friendly to the heaviest queries: the example below illustrates a case 
where each record has only an ID an an enumerated field, and uses sets instead. 
Another typical approach is to store one hash per record, but also have "index" 
keys; for instance, one could speed up geographical lookup of restaurants by…

- storing each restaurant’s data in a hash key;
- using a sorted set of IDs scored by geohashes for extremely fast bounding-box
  searches


## Memory usage

When designing storage for a Redis-backed models, it is advisable to be aware if
how efficient Redis data structures are if you’re going to store a lot of data.

Key tidbits:

- One-hash-per-record can be very inefficient, as the hash _keys_ are repeated
  for each record. Columnar storage might be preferred, or (if the whole hash
  will always be needed) packing record data with MessagePack and replacing long
  keys with shorter ones.
- While querying large sets, sorted sets, of hashes is normally faster than
  querying the root keyspace (e.g. for membership checks), be aware that those
  data structures have a memory overhead.

Because small data structures get [stored
differently](http://redis.io/topics/memory-optimization), this overhead can be
lower when the individual data structures are small (~100 items). We’ve
written an [article on storing session data](http://deliveroo.engineering/2016/10/07/optimising-session-key-storage.html) which outlines an extreme case
of this.


## Scalability and sharding

It is _not_ fine to hold data for all records of a given model in a single key,
as this breaks shardability of Redis.

Sharding is the practice of scaling Redis horizontally by deterministically
reading and writing certain keys from a given server, based on a hash of the
key. This is built into Redis clients and has even [better
support](http://redis.io/topics/cluster-tutorial) in Redis 3.  Splitting large
datasets into multiple keys (partitions) means they can easily be sharded across a cluster,
when we need to, without major refactoring.

Partitioning should be considered for any data structure that exceeds a few
thousand entries (lists, sets, etc), and is likely to grow as time passes or the
business grows.

## Example

I have a set of payment method fingerprints.  I want to be able to rapidly
determine whether a fingerprint is marked as fraudulent.

The backing store for this is 2x256 Redis sets; 256 for each "good" and "bad"
fingerprint status. Having 256 buckets per status lets us easily shard the data 
when we need to. 

Note that the number of partitions you need can be optimised. In this particular
case, the primary purpose is to allow for clustering.

The class exposes `.find_by(id:)`, `#save`, and `#save!` as any Rails user would
expect.

```ruby
class PaymentFingerprint
  include ActiveModel::Validations
  
  attr_accessor :id # the actual fingerprint
  attr_accessor :status # :good or :bad
  
  validates_presence_of :id
  validates_inclusion_of :status, in: %i[good bad]
  
  def intialize(id:nil, status:nil)
    @id = id
    @status = status
  end
  
  def save
    return false unless valid?
    App.redis.multi do |r|
      other_status = status == :good ? :bad : :good
      r.sadd _key(id, status), id
      r.srem _key(id, other_status), id
    end
    true
  end
  
  def save!
    return if save
    raise Redis::InvalidRecord.new(self)
  end
  
  module ClassMethods
    def find_by(id:)
      if App.redis.smember _key(id, :good), id
        new(id: id, status: :good)
      elsif redis.smember _key(id, :bad), id
        new(id: id, status: :bad)
      else
        nil
      end
    end
  end
  extend ClassMethods
  
  private

  module SharedMethods
    def _key(id, status)
      "payment_fingerprint:%s:%s" % [
        status
        Digest::MD5.hexdigest(id.to_s)[-2,2]
      ]
    end
  end
  include SharedMethods
  extend SharedMethods
end

class Redis::InvalidRecord < StandardError
  attr_reader :record
  def initialize(record)
    @record = record
  end
end  
```
