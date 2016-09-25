---
layout: post
title:  "Optimising session key storage in Redis"
author: "Greg Beech"
exerpt: >
  Tracking authenticated sessions can be implemented in Redis using `setex` with some serialized JSON. It works pretty well until you have to cope with millions, or even tens of millions of sessions where the memory usage and performance can suffer.


  By using Redis data structures more effectively we can achieve a **70% reduction** in memory usage, at the cost of both code and conceptual complexity. Is it worth it?

---

## A starting point

First let's create a session class as our starting point which will use a key per session in Redis. The attributes we care about are:

- **ID**, a long random token identifying the session
- **Identity ID**, the identity of the user who owns the session, and
- **Expires At**, the time at which the session expires


```ruby
class Session
  attr_accessor :id, :identity_id, :expires_at

  def initialize(attributes)
    self.id = attributes[:id] || SecureRandom.hex(20)
    self.identity_id = attributes[:identity_id]
    self.expires_at = attributes[:expires_at] || 30.days.from_now
  end
end
```

We'll need to add a save method which uses [`setex`](http://redis.io/commands/SETEX) to save the key with an expiry time:

```ruby
def save!
  ttl = Time.current - expires_at
  data = { identity_id: identity_id, expires_at: expires_at.to_i }.to_json
  redis.setex(self.class.key(id), ttl.to_i, data)
end

def self.key(id)
  "session:#{id}"
end
```

We also need the opposite method to find a session we've previously stored using the [`get`](http://redis.io/commands/GET) method to grab all the key data.

```ruby
def self.find(id)
  data = redis.get(key(id)) or raise 'Not Found'
  attributes = JSON.parse(data).merge(id: id).with_indifferent_access
  attributes[:expires_at] = Time.at(attributes[:expires_at]).utc
  new(attributes)
end
```

This key-per-session approach could also be implemented using a Redis hash with [`hmset`](http://redis.io/commands/HMSET)/[`expire`](http://redis.io/commands/EXPIRE) and [`hgetall`](http://redis.io/commands/HGETALL) but it doesn't really make a huge difference to memory or performance.

## Benchmarking

To make sure there's nothing else in Redis flush the databases and check that only the baseline amount of memory is being used.

```
$ redis-cli flushall
OK
$ redis-cli info | grep used_memory_human
used_memory_human:984.64K
```

Then in `irb` we can start populating sessions by repeatedly inserting 100k sessions:

```
irb> 100_000.times { |n| Session.new(identity_id: n).save! }
 => 100000
```

For every iteration we query the Redis memory used:

```
$ redis-cli info | grep used_memory_human
used_memory_human:24.95M
```

Repeating this process until we've got a million sessions stored which gives us more than enough data to plot. This gives us our baseline memory usage for the quickest and easiest implementation:

<figure>
![Baseline memory usage](/images/posts/optimising-session-key-storage/baseline.png)
</figure>

The memory usage is linear, as you'd expect, and we're using around 230MB to store every 1M sessions. Given you can scale RedisGreen to 30GB and we use a dedicated store for sessions, it seems we could support 100M sessions without any real problems so perhaps there's no point in trying to optimise this. But let's do it anyway.

## Modification 1: Efficient binary packing

The first change we can make is to turn the hex session ID back into binary, which almost halves the size of the Redis key:

```ruby
def self.key(id)
  "session:#{[id].pack('H*')}"
end
```

We can also make the data much smaller by switching to the [MessagePack](http://msgpack.org/index.html) format and using single byte keys rather than the full attribute name:

```ruby
def save!
  ttl = Time.current - expires_at
  data = { i: identity_id, x: expires_at.to_i }.to_msgpack
  redis.setex(self.class.key(id), ttl.to_i, data)
end
```

This of course needs some corresponding changes to the find method:

```ruby
def self.find(id)
  data = redis.get(key(id)) or raise 'Not Found'
  attributes = MessagePack.unpack(data).merge(id: id).with_indifferent_access
  attributes[:identity_id] = attributes.delete(:i)
  attributes[:expires_at] = Time.at(attributes.delete(:x)).utc
  new(attributes)
end
```

These changes give us a 25% reduction in memory usage, which isn't as much as you might expect given we've almost halved the size of the key, and reduced the size of the data to about a third!

<figure>
![Binary packing memory usage](/images/posts/optimising-session-key-storage/binary-packing.png)
</figure>

This is because each key in Redis has (TODO: Write about memory overhead per key)

## Modification 2: Sharded HASH + ZSET

The [Redis memory optimisation page](http://redis.io/topics/memory-optimization) suggests that by splitting the data into a set of sharded HASH structures we can avoid the per-key memory overhead. We still need to be able to expire the keys though, so we need to store the session ID in a ZSET scored by expiry date. (TODO: Write this section better)

We have a number of new keys:

```ruby
PREFIX_SIZE = 2

def self.data_key(id)
  "session:data:#{id[0..(PREFIX_SIZE - 1)]}"
end

def self.expiry_key(id)
  "session:expiry:#{id[0..(PREFIX_SIZE - 1)]}"
end

def self.sub_key(id)
  [id[PREFIX_SIZE..-1]].pack('H*')
end
```

And then the save method changes:

```ruby
def save!
  data = { i: identity_id, x: expires_at.to_i }.to_msgpack
  redis.multi do |redis|
    redis.hset(self.class.data_key(id), sub_key, data)
    redis.zadd(self.class.expiry_key(id), expires_at.to_i, sub_key)
  end
end
```

As does find:

```ruby
def self.find(id)
  data = redis.hget(data_key(id), sub_key(id)) or raise 'Not Found'
  attributes = MessagePack.unpack(data).merge(id: id).with_indifferent_access
  attributes[:identity_id] = attributes.delete(:i)
  attributes[:expires_at] = Time.at(attributes.delete(:x)).utc
  new(attributes)
end
```

Oh :-(

<figure>
![256 shards memory usage](/images/posts/optimising-session-key-storage/256-shards.png)
</figure>

## Modification 3: Sharded HASH + ZSET ziplists

So it turns out using multiple hashes was really bad as we didn't read the docs closely enough. It started off well enough as some of the hashes were still ziplists, but by 200k sessions the memory usage is around 20% higher than the baseline.

Just change how much of the key we put in the prefix so we have 65k shards:

```ruby
PREFIX_SIZE = 4
```

This is 68% better than our baseline:

<figure>
![65k shards memory usage](/images/posts/optimising-session-key-storage/65k-shards.png)
</figure>

 (~15 entries per hash/zset, etc.)

## Modification 4: Even more shards

Use 16M shards, avg. one key per ziplist

Worse by 12% but not as bad as 256 shards.!

<figure>
![16M shards memory usage](/images/posts/optimising-session-key-storage/16m-shards.png)
</figure>

## Continuing the lines

However, this isn't the whole story. We're only looking at a small number of sessions here and as we start to insert more of them things will change.

With 65k shards and the standard settings of 128 entries in a ZSET and 512 in a HASH before the efficient storage ziplist format is converted to 'regular' storage we'd expect to see the ZSETs being converted once we have ~8M sessions and the HASHes being converted at around ~33M sessions.

Conversely with 16M shards we're wasting a lot of space with virtually empty ziplists with lower numbers of entries, using essentially the key per session model except the value is a ziplist instead of blob. However, as more sessions are added these ziplists will start to fill up more efficiently.

Extending the lines out to around 60M sessions we can see the trend, and at around 18M sessions using the higher number of shards starts to become more efficient. This tallies with the earlier observations that using too small a shard size is less memory efficient than the key-per-session approach.

<figure>
![Extended memory usage](/images/posts/optimising-session-key-storage/extended.png)
</figure>

## Conclusions

The basic approach of serializing a JSON blob (or, better, a msgpack blob) into an expiring key is sufficient for managing sessions for all but the very largest of sites. Unless you're dealing with tens of millions of sessions then there's very little point in doing anything more complex than this.

Choosing too small a shard size is worse than not sharding at all; you use significantly more memory than the basic approach and also increase the complexity of your code.

Getting the shard size right means you can make significant savings in memory usage -- almost 70% reduction from the basic approach and 55% over the approach with binary packing. However, given you could store ~40M sessions in a RedisGreen X-Large instance at $779/month using the basic approach, it's debatable whether the additional complexity is worth it.


