---
layout: post
title:  "Testing Kafka Consumption"
authors:
  - "Tim Baker"
excerpt: >
    A strategy to test consuming from a fully functional kafka instance without going too deep.
---

This post outlines a strategy for testing an application's dependency on consuming from kafka by creating a dockerized instance of kafka and zookeeper to use exclusively within your tests. Primarily it's suitable in situations where mocks/stubs don't provide the level of test coverage you desire, for example when using an unsable API where the method signatures or expected responses are subject to change.

Kafka is an external dependency of the application under test, and when testing behaviour it's common to stub it out, or assert against mocks. For example you might do this:

```ruby
# Stub the poll method on the consumer to return the message that we want.

allow(consumer).to receive(:poll).and_return(message)
```

This is fine most of the time, and a lot of languages have a verified double that ensures compatibility as far as the method call is concerned. However even instance doubles don't guarantee that the responses are compatible with the underlying object.

I recently found myself writing code that made use of a few public but not particularly well trodden APIs in a pre 1.0 kafka library, where breaking changes are to be expected in both the method definition and the structure of the responses. I was concerned that my stubbed tests would continue to pass even if an API changed, so I introduced a running kafka and zookeeper instance to my tests and it was easier than I expected.

To get the instances running firstly define your kafka and zookeeper instances in a docker compose file:

```
zookeeper:
  image: confluentinc/cp-zookeeper:latest
  environment:
    ZOOKEEPER_CLIENT_PORT: 2181
    ZOOKEEPER_TICK_TIME: 2000

kafka:
  image: confluentinc/cp-kafka:latest
  depends_on:
    - zookeeper
  ports:
    - 9092:9092
  environment:
    KAFKA_BROKER_ID: 1
    KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
    KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'false'
    KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
    KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
    KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
```

Then start your kafka/zookeeper:

```
docker-compose -f docker-compose.kafka.yml up -d
```

Lastly create a topic:

```
docker-compose -f docker-compose.kafka.yml exec kafka kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 8 --topic foobars
```

You now have an instance of kafka running and can interact with it from your application. For example take the following ruby code. The Kafka class holds a producer and a consumer pointing at localhost:9092 (where we configured our local docker kafka instance to live).

```ruby
require "securerandom"
gem "rdkafka", '=0.7.0'
require "rdkafka"

class Kafka
  CONFIG = {
    :"api.version.request" => false,
    :"broker.version.fallback" => "1.0",
    :"bootstrap.servers" => "localhost:9092",
    :"enable.auto.commit" => false,
    :"enable.auto.offset.store" => false,
    :"group.id" => "foobar#{SecureRandom.uuid}",
    :"auto.offset.reset" => "earliest",
    :"enable.partition.eof" => false,
  }

  def initialize(options: {})
    config = Rdkafka::Config.new(CONFIG)
    @consumer = config.consumer
    @producer = config.producer
  end

  def consume!
    begin
      @consumer.subscribe("foobars")

      until @stopped
        message = @consumer.poll(500)
        foobar_consumer.process(message) unless message.nil?
      end
    ensure
      @consumer.close
    end
  end

  def produce(message)
    @producer.produce(
      topic:     "foobars",
      payload:   message,
      key:       "key 1",
      partition: 0,
    ).wait
  end

  def foobar_consumer
    @foobar_consumer ||= FoobarConsumer.new
  end
end

class FoobarConsumer
  attr_reader :messages_received

  def initialize
    @messages_received = []
  end

  def process(message)
    puts message
    @messages_received << message.payload
  end
end
```

You can then initalize the object, kick off kafka consumption inside a separate thread and publish to the topic you created:

```ruby
k = Kafka.new
t = Thread.new { k.consume! }
k.produce "foobars"
```

After a few seconds you'll see `puts message` output "foobar" and will be able to interrogate the FoobarConsumer `@messages_received` ivar.

```ruby
expect(k.foobar_consumer.messages_received).to eq(["foobars"])
```

There you have it, in 100 lines we have a fully functioning kafka instance and code to interact with it, and by using this pattern you can be more sure of tests that cover features with kafka as a dependency.
