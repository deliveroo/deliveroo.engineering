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
- Use `ActiveModel::Validations`
- Implement `find(id)`, `find_by_foobar`, `save`, `save!`

Do _not_ just "use redis" in random classes, just like you wouldn't write SQL
queries in, say, a controller. Instead, wrap your Redis usage in a model class.


## Key naming

Key separator is `:`.

The first component should be the underscored name of the model class.

High-cardinality key components should be at then end (so we can look at the
"tree of keys” meaningfully)

## Data modeling

It is acceptable, but not required to have exactly one hash key per record.

The one-hash-per-record approach mimic ActiveRecord more closely, but can defeat
the purpose of using Redis—it has faster, more advanced data structures. Like
other "NoSQL" stores it's often best to store data in a format that's friendly
to the heaviest queries: the example below illustrates a case where each record
has only an ID an an enumerated field, and uses sets instead.  Another typical
approach is to store one hash per record, but also have "index" keys; for
instance, one could speed up geographical lookup of restaurants by
- storing each restaurant's data in a HASH key;
- using a ZSET of IDs scored by geohashes fore extremely fast bounding-box
  searches.

It is _not_ fine to hold data for all records in a single key, as this breaks
shardability of Redis.

Sharding is the practice of scaling Redis horizontally by deterministically
reading and writing certain keys from a given server, based on a hash of the
key. This is built into Redis clients and has even [better
support](http://redis.io/topics/cluster-tutorial) in Redis 3.  Splitting large
datasets into multiple keys means they can easily be sharded across a cluster,
when we need to, without major refactoring. This should be done as soon as the
size of a given key is known exceed a few thousand entries (lists, sets, etc).

## Example

I have a set of payment method fingerprints.  I want to be able to rapidly
determine whether a fingerprint is marked as fraudulent.

The backing store for this is 2x256 Redis sets; 256 for each "good" and "bad"
fingerprint status. Having 256 buckets per status lets us easily shard the data
when we need to.

The class exposes `.find_by_id`, `#save`, and `#save!` as any Rails user would
expect.

```ruby
class PaymentFingerprint
  include ActiveModel::Validations
  include Roo::ModelSupport::RedisSupport
  
  Invalid = Class.new(Exception)
  
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
    redis.multi do
      other_status = status == :good ? :bad : :good
      redis.sadd _key(id, status), id
      redis.srem _key(id, other_status), id
    end
    true
  end
  
  def save!
    return if save
    raise Invalid, errors.full_messages.join(' ')
  end
  
  module ClassMethods
    include Roo::ModelSupport::RedisSupport
    
    def find_by_id(id)
      if redis.smember _key(id, :good), id
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
```
