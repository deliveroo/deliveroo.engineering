require 'hiredis'
require 'redis'
require 'redis/connection/hiredis'
require 'securerandom'
require 'benchmark/ips'
require 'csv'
require 'pry'

ENTRIES = 10_000_000
BATCH_SIZE = 1_000
RUNS = 5
MAX_SHARD_BITS = 23

$redis = Redis.new(timeout: 10)
$redis.flushall

def current_memory_usage
  $redis.info['used_memory'].to_i
end

class SetAdapter
  def name
    'set'
  end

  def key(sharding_bits, value)
    prefix = (value % (1<< sharding_bits)).to_s(16)
    member = (value >> sharding_bits).to_s(16)
    key = "bench:set_:%02d:%s" % [sharding_bits, prefix]
    [key, member]
  end

  def write(r, sharding_bits, value)
    key, member = key(sharding_bits, value)
    r.sadd(key, member)
  end

  def read(r, sharding_bits, value)
    key, member = key(sharding_bits, value)
    !! r.sismember(key, member)
  end

  def cas(*args)
    !! write(*args)
  end
end

class HashAdapter
  def name
    'hash'
  end

  def key(sharding_bits, value)
    prefix = (value % (1<< sharding_bits)).to_s(16)
    member = (value >> sharding_bits).to_s(16)
    key = "bench:hash:%02d:%s" % [sharding_bits, prefix]
    [key, member]
  end

  def write(r, sharding_bits, value)
    key, member = key(sharding_bits, value)
    r.hset(key, member, 1)
  end

  def read(r, sharding_bits, value)
    key, member = key(sharding_bits, value)
    !! r.hexists(key, member)
  end

  def cas(*args)
    !! write(*args)
  end
end


class ZsetAdapter
  def name
    'zset'
  end

  def key(sharding_bits, value)
    prefix = (value % (1<< sharding_bits)).to_s(16)
    member = (value >> sharding_bits).to_s(16)
    key = "bench:zset:%02d:%s" % [sharding_bits, prefix]
    [key, member]
  end

  def write(r, sharding_bits, value)
    key, member = key(sharding_bits, value)
    r.zadd(key, 1, member)
  end

  def read(r, sharding_bits, value)
    key, member = key(sharding_bits, value)
    !! r.zscore(key, member)
  end

  def cas(*args)
    !! write(*args)
  end
end

class FlatAdapter
  def name
    'flat'
  end

  def key(sharding_bits, value)
    prefix = (value % (1<< sharding_bits)).to_s(16)
    member = (value >> sharding_bits).to_s(16)
    "bench:flat:%02d:%s:%s" % [sharding_bits, prefix, member]
  end

  def write(r, sharding_bits, value)
    key = key(sharding_bits, value)
    r.setnx(key, 1)
  end

  def read(r, sharding_bits, value)
    key = key(sharding_bits, value)
    !! r.exists(key)
  end

  def cas(*args)
    !! write(*args)
  end
end

# binding.pry

# generate entries
DATA = (0...(ENTRIES/BATCH_SIZE)).map do
  (0...BATCH_SIZE).map do
    SecureRandom.hex(16).to_i(16)
  end
end

csv = CSV.open('bench.csv', 'w')
csv << %w[type shards memory ips]

# 0.upto(MAX_SHARD_BITS) do |sharding_bits|
24.upto(26) do |sharding_bits|
  [
    ZsetAdapter.new,
    SetAdapter.new,
    HashAdapter.new,
    FlatAdapter.new,
  ].each do |adapter|
    $redis.flushall

    # fill sets with data
    $stderr.puts("Loading data...")
    begin
      start_at = Time.now
      DATA.each do |batch|
        $redis.pipelined do |r|
          batch.each do |value|
            adapter.write(r, sharding_bits, value)
          end
        end
      end
    rescue Redis::CommandError => e
      $stderr.puts("Failed: #{e.message}")
      next
    end
    $stderr.puts("Loaded in %s ms" % ((Time.now.to_f - start_at.to_f) * 1e3))

    used_memory = current_memory_usage

    # measure hit performance - median of 5 runs.
    report = Benchmark.ips do |x|
      x.config(warmup: 1)

      RUNS.times do |k|
        x.report(k) do |count|
          count.times do
            adapter.cas $redis, sharding_bits, DATA.sample.sample
          end
        end
      end
    end

    read_ips = report.data.map { |d| d[:ips] }.sort[RUNS/2]
    
    # measure miss performance
    report = Benchmark.ips do |x|
      x.config(warmup: 1)

      RUNS.times do |k|
        x.report(k) do |count|
          count.times do
            adapter.cas $redis, sharding_bits, SecureRandom.hex(16).to_i(16)
          end
        end
      end
    end

    write_ips = report.data.map { |d| d[:ips] }.sort[RUNS/2]
    
    results = [
      adapter.name,
      1 << sharding_bits,
      used_memory, 
      read_ips,
      write_ips,
    ]
    $stderr.puts results.join(',')
    csv << results
  end
end

