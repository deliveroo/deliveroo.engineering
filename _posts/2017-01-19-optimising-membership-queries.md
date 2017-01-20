---
layout: post
title:  "Optimising Redis storage, part two"
author: "Julien Letessier"
excerpt: >
  Counting unique users, checking if a credit card has already been used, or
  checking if this is a mobile user's first visit ever — all of these require
  maintaining a large set of fingerprints (unique visitor ID, card fingerprint,
  IDFVs depending on the use case).


  Because this usually needs to be queried very rapidly, Redis is naturally our
  store of choice.
  While using its `SET` feels obvious, what data structure to select? Are there
  memory/performance compromises?


  This shows that while plain key/value is a safe bet, there are possible
  optimisations with hashes and traps to avoid with sets and sorted sets.

---

In a [previous article](/2016/10/07/optimising-session-key-storage.html) we
investigated how best to store a large key-value dataset (user sessions). We
showed that number of partitions can have a huge effect on memory usage, but
didn't look at the other structures or how it affected performance.

The size of this set is driven by the fact session key and data are roughly 43
bytes, and that it grows with the number of monthly active users.

For this new use cases, we're looking at identifiers that are typically smaller
(128-bit UUIDs, or 16 bytes) with no payload (associated data); it's also a
dataset that grows with _time_, not just with _current usage_ — so storage
constraints are slightly different: smaller unit data, but kept essentially
forever.


## Why do this

One of Redis's most awesome features, besides it's speed and well-designed data
structures, is that it documents algorithmic complexity for every single call.
For instance: we know that adding to a hash is _O(1)_ and adding to a sorted set
is _O(log n)_.

What Redis does not document, however, includes

- memory storage costs for each data structure, and
- relative cost of different calls (because not all _O(1)_'s are equal).

Aside from the stated use case, this exploration is about lifting this mystery
for a few of the most commonly-used Redis data structures.


## Data structures: options

We assume the identifiers we want to store are 128-bit random numbers. The key
use cases we consider is:

<em>
Check if a given identifier is in the set of known identifiers, and add it if it isn't.
</em>

Because this is an operation that will happen often, and the set will be large
very rapidly, we want this to be a single Redis operation, commonly called a CAS
(check-and-set).

The options we're considering are:

1) Store flat keys.

For a given ID `0001aaaa0002bbbb0003cccc0004dddd`, we store the value 1 at key
`bench:flat:xx:{id}`.

The `xx` is to mimic partitioning in other data structures, so that the keys in the
"flat" option are comparable in length (more below).

Our CAS query is implemented with `SETNX`.

2) Use Redis hashes

A stored ID is persisted by setting a field to 1 in a hash. The data is
partitioned into _2^n_ hashes, by taking the low _n_ bits of the ID and using it
as part of the hash's key. For example, with _n = 12_ (4,096 partitions), our
example ID is persisted by setting field `0001aaaa0002bbbb0003cccc0004d` of hash
key `bench:flat:12:ddd` to the value 1.

CAS is implemented with a single `HSETNX`.

3) Use Redis sets

Similar to hashes, except to associated value is needed.

For 4,096 partitions, the example ID is persisted by adding the value
`0001aaaa0002bbbb0003cccc0004d` to the set named `bench:set_:12:ddd`.

CAS is implemented with `SADD` (which does return the number of items added).

4) Use Redis sorted sets

Similar to hashes again.

For 4,096 partitions, the example ID is persisted by adding the value
`0001aaaa0002bbbb0003cccc0004d` to the sorted set named `bench:zset:12:ddd`,
with the associated score of 1.

CAS is similarly implemented with `ZADD`.


## Benchmarking

We prepared a benchmark driver that explores the possible data structures and
number of partitions — storing all IDs in a single structure at one extreme, and
storing each ID in its own structure at the other.

The code for the benchmark driver is
[here](/images/posts/optimising-membership-queries/bench.rb); the graphs
presented are from [this
spreadsheet](/images/posts/optimising-membership-queries/bench.xlsx).

We found that the behaviours described below were completely similar with 1, 5,
10, or 20 million million IDs, so for simplicity (and to avoid unseemly 3D
graphs) we're only plotting results for 10 million IDs here.


### Memory usage

The "flat" storage scheme uses consistent memory, which is expected: the number
of keys and key size are identical, and "partitioning" here is really just
rearranging characters in keys.

At low partition counts (ie. more IDs stored in a single structure), hashes, sets,
and flat keys use up roughly the same amount of memory (within 10% difference),
while sorted sets use 75% extra memory.

The right-hand side (many partitions, few IDs per partition) exhibits 2
interesting behaviours: first the memory usage for hashes and zsets massively
improves, then degrades as we converge towards a single ID per structure.

Even more interestingly, for 128k partitions, the total memory usage is within a
hair of the theoretical minimum (320MB to store 10 million 32 byte IDs).

<figure>
![Total memory usage](/images/posts/optimising-membership-queries/i-memory-usage.svg)
</figure>

Let's revisit this chart's axes to detail these behaviours. The next chart
presents the same data, but focusing on overhead per ID, rather that total
memory usage. Overhead is simply the memory used per ID, minus the minimum size
to store an item (32 bytes).

On the leftmost side, the difference between the curves gives us a measure of
the memory cost per data structure entry. Two interesting conclusions:

- Each key uses up 63 bytes of memory (the graphs reports 78 bytes, from which
  15 is part our key name: `bench:flat:xx::` + 32 bytes of ID).
- `HASH` and `SET` consume 70 bytes per element.
- `ZSET` consume an extra 122 bytes per element (including 8 bytes for the
  per-element score)

At the right, the difference measure the memory cost of a single data structure
(because each now hold a single ID). From which we deduce:

- Each `HASH` and `ZSET` consumes roughly 37 bytes (when ziplist'd), on top of
  the base key usage.
- Each `SET` consumes a whopping 194 bytes.

This leaves the improvement in memory usage that starts at 512 IDs per hash and
128 IDs per sorted set.

This phenomenon is due to Redis [reverting to simpler
structures](http://redis.io/topics/memory-optimization) (called "ziplists" or
"zipmaps") when a data structure contains fewer than a (configurable) number of
items.

In practice, and with the default settings, a hash containing fewer than 512
elements will be stored as a flat list. This does mean that queries (in
particular, our CAS query) will revert from _O(1)_ to _O(n)_... but with a _n_
that is constrained to be small.

Unfortunately, this effect gets negated if the partition counts becomes too
high, as the memory cost of having more keys makes up for the efficient ziplist
encoding.


<figure>
![Memory overhead](/images/posts/optimising-membership-queries/i-overhead.svg)
</figure>


### Querying performance

Different data structures, even if quoted at _O(1)_, might have different
performance when queried: constant operation time might mean a constant 1ms or a
constant 100ms, after all.

Using the same dataset, we benchmark throughput for two scenarios: CAS hits
(trying to add an ID that's already in the set), and misses (the converse).

Caveats:
- the measurements below typically have a ±6% margin of error.
- we used a single-threaded Ruby driver for these, which means the driver
  overhead is factored in and probably masks a significant portion of Redis
  performance.

We did make sure that the time spent in the driver is identical for each
scenario and for each type of data structure, so that any difference can still
be compared.

- Flat keys, as expected, provide consistent hit throughput.
- `SET` throughput provides consistent performance, and is 5% slower than flat
  keys.
- `HASH` is also consistent, and 10% slower than flat keys.
- `ZSET` is more noisy and less consistent; from 10% slower when ziplist
  encoding gets used to 20% slower otherwise.


<figure>
![Hit performance](/images/posts/optimising-membership-queries/i-cas-hit.svg)
</figure>

For CAS misses (ie. writes), performance is generally 15% lower.

- Flat keys still behave consistently.
- `SET` is 1 to 3% slower than flat keys on average.
- `HASH` is exactly as fast as flat keys to large hashes, but plummets to 15%
  slower when using ziplists close to the limit (i.e. with 128 to 512 items per
  partition).
- `ZSET`'s theorectical _O(log n)_ behaviour finally rears its head, with 25%
  lower throughput on larger sets.

<figure>
![Miss performance](/images/posts/optimising-membership-queries/i-cas-miss.svg)
</figure>


## Closing thoughts

Our conclusion on storing large sets in Redis is twofold:

1. Flat keys, sets, and hashes have very comparable performance and memory usage
   when low partitioning is used.

   If the purpose is to enabled partitioning/clustering without much concern for
   overall memory usage, we recommend using `SET` with few partitions (256 would
   typically be convenient): `SET` is conceptually a better match, and a lower
   number of keys is more practical for monitoring, and
   faster when restoring backups.

2. Ziplists create a sweet spot for `HASH` ("intlists" create another for `SET`,
   which we have not explored here). It can be a technique worth exploring when
   memory usage is critical, for huge datasets when the unit datum is of a
   similar order of magnitude as the key size — and importantly, where the size
   of the set is known to stay within 1 order of magnitude.
   
   In our case, this approach would be possible to reduce storage size by 65%;
   this comes at a moderate performance cost.

Of course, work here is incomplete. Instead of storing our IDs as hexadecimal
strings, we could have halved storage by using binary packing — but that'd have
made our examples unreadable.

Another avenue that might be worth exploring is using Redis as the storage for a
Bloom filter, for use cases where a probabilistic data structure is sufficient.
In theory, such a filter would only consume 80MB of memory for a set with
1-millionth false positive rates (a 90% reduction over our "exact" approach).

While reasonably realistic, this benchmark is still a benchmark and not
behaviour in a production system, but hopefully will help you understand Redis
behaviour a little better, as it did for us!




