---
layout: post
title:  "Improving Stream Data Quality With Protobuf Schema Validation"
authors:
  - "Tom Seddon"
excerpt: >
  The requirements for fast, reliable and scalable data pipelines are growing quickly at Deliveroo as the business continues to scale and innovate. Just some of the ways in which we make use of data at Deliveroo include, computing optimal rider assignments to in-flight orders, making live operational decisions, personalising restaurant recommendations to users and prioritising platform fixes. Our quickly expanding business also means our platform needs to operate reliably at scale. In addition to this the Engineering organization is in the process of decomposing a monolith application into separate services. Both of these aspects mean we require a pipeline to reliably transport data between new services, and an externally defined data model that applications can depend on. 

---

Over the last several months, the Data Engineering Team have scoped out and delivered a new inter-service communication framework that meets the needs of the company’s extreme thirst for analytical data, as well as a providing a new asynchronous messaging mechanism utilised by all internal services.  The system, known internally as Franz (due to its use of Apache Kafka) was conceived as a strongly typed, interoperable data stream backbone for inter-service communication. Baked into our system design are guarantees for reliable and consistent data on each topic and a way schemas to evolve without breaking downstream systems. Use of Kafka and our strict enforcement of Protobuf messages on all topics has been instrumental in providing the persistence and reliability guarantees we required.

This article describes in some detail how we came implement a flexible, managed repository for the Protobuf schemas flowing on Franz, and how we have designed a way to provide a reliable schema contract between producer and consumer applications.


## The Need for a Structured Message Format


A key requirement of our centralised message service is resilience and one step towards achieving this is providing guarantees about the structure and data types of messages. These guarantees means consumer applications can have expectations of the format of the data and be less vulnerable to breaking due to corrupt messages. Another important aspect for resilience is being able to update the data model without breaking consumers that are depending on the previous version, which means enforcing backwards and forwards compatible schema evolution guarantees. 

Both of these requirements meant that a flexible data format such as JSON would not be ideal and the team invested in researching transport encoding formats the would provide stronger assurances about the data being transmitted. While there are some ways to give greater guarantees for JSON, using for example JSON Schema, this still leaves a lot to be desired, including a lack of well defined mechanisms for schema evolution, and still leaves us with sub-par encoding and decoding performance of JSON itself.

## Deciding on an Encoding Format
The team began investigating the range of technologies available for inter-operable schema formats. We were looking for a system that supports defining a schema in a programming language agnostic Interface Definition Language (IDL) which could then propagate the schema across to all the applications that need to work on that data. In addition to this, benefits such as binary serialization (reduced payload size) and schema evolution mechanisms were aspects the team had worked with before on previous projects, and were keen to make use of again.

The options available for these types of serialization formats supporting cross language support were narrowed down to three that broadly met our requirements. These were Thrift, Protocol Buffers (Protobuf), and Avro. We then proceeded to conduct an evaluation of these formats to determine what would work best for transmission of data over Kafka.

Thrift and Protobuf have very similar semantics, with IDLs that support the broad types and data structures utilised in mainstream programming languages. When conducting our evaluation, we initially chose Thrift due to familiarity, but in the end discounted this due to lack of community support. Avro was an intriguing option, particularly because of Confluent’s support for this on Kafka. Avro semantics are quite different to that of Protobuf, as it is typically used with a schema definition provided in a header to a file. Confluent’s schema registry removes this requirement by keeping the schema definition in an API and tagging each message with a lookup to find that schema. One of the other appealing aspects of Avro is that it manages schema evolution and backwards and forwards compatibility for you, by keeping track of a writers and a readers schema. 

In the end Avro was discounted as not ideal for Deliveroo’s setup due to lack of cross language support. The thinking behind this was based on a desire for support of generated schema classes in each of Deliveroo’s main supported languages (JVM, Go and Ruby). Avro only supported JVM in this regard.

## Providing Guarantees on Graceful Schema Evolution
In deciding to make use of Protobuf, there was some work to be done to enforce the graceful schema evolution rules that are provided with correct use of the format. The Protobuf documentation outlines the rules for ensuring graceful schema evolution.

### Forwards Compatibility
Forwards compatibility means that consumers can read data produced from a client which is using a later version of the schema than that consumer. Fields that have been added in the new schema will not be picked up by the consumer until it moves to a later version. Fields that have been deleted in the new schema will be deserialized as default values for the relevant types in the consumer programming language. In both cases no deserialization errors occur as a result of the schema mismatch.

### Backwards Compatibility
Backwards compatibility means that consumers using a newer version of the schema can read the data produced by a client with an earlier version of the schema. Fields that have been added in the newer version will again be deserialized with default values. Fields that have been deleted in the new schema will not be deserialized, but naturally any subsequent code that was in place to handle that data will need to be refactored to cope.

The remaining Protobuf requirements that are mandated to ensure data consistency are met by ensuring that the ordinal placeholders for each attribute are held immutable throughout a message’s lifespan. In Protobuf the integer field number that represents a field is sacred, as this is what is actually transmitted in a serialized message (as opposed to the field name). All producers and consumers rely on this integer having a consistent meaning, and altering it can cause havoc if a consumer processes old data with a new understanding of what data belongs to a field number. 

The tests we’ve implemented to cover all of these aspects are as follows:
- Fields numbers must not be amended.
- Fields must not have their type amended.
- Fields that have been removed from a message must have an entry added to a reserved statement within the message, both for the deleted field and the deleted field number (tag). This ensures that the protoc compiler will complain if someone attempts to add either of these back in to a subsequent version. 
- Fields must not have their name amended (this would not break Protobuf compatibility, but we have the test in place to help maintain the evolvable schemas for JSON derived from Protobuf models).

These rules are enforced within our Protobuf repo, using the Protobuf FileDescriptor API, which allows for a single object representation of the entire message space, and can be used to track differences that arise between message versions within the scope of an individual pull request. While this doesn’t provide explicit guarantees that version 1 and version n of a schema will be compatible, it does facilitate this implicitly by setting constraints on the changes that an individual pull request would apply.

## Providing Guarantees on Topic Schemas 
The Confluent Schema Registry makes use of a centralised service so that both producers and consumers can access schemas and achieve a common understanding. The service keeps track of schema subjects and versions, as well as the actual schema details. This means that when a producer publishes data to a topic on Kafka, it registers the schema, and when that message is picked up by a consumer, it can use the attached identifier to fetch the deserialization details from the registry. 

What we were after though was a way to provide even tighter guarantees around topics and schemas. Where Confluent’s schema registry provides a mechanism for knowing what this message means, we wanted a way to be sure that a consumer can trust a contract of the nature:

<center><span style="font-size:larger;"><span style="color:darkblue">Producer X owns Topic Y with Message Format Z</span></span></center>

 
The first component employed to enforce these constraints is implemented in another Data Engineering product; our Stream Producer API performs schema/topic validation before forwarding messages to Kafka. The second component is some mandatory metadata which is enforced within the API, but is defined in the Protobuf IDL. The metadata consists of Protobuf custom options. The custom option is defined once within a shared Protobuf file:

```proto
extend google.protobuf.MessageOptions {
    string topic_name = 50000;
}
```

We then make use of this in all canonical topic schema definitions by including the topic_name attribute.

```proto
message Order {

    option (common.topic_name) = "orders";

    int64 id = 1;
    …
}
```

Messages that have a missing topic definition or mismatched definition in relation to the topic being published to are rejected by the Producer API. The full contract is achieved through a combination of the topic metadata tying a topic to a schema and a separate mapping between an authentication key used by publishers which maps to one and only one topic. By ensuring all publishing to Kafka is done via our Stream Producer API (topic ACLs prevent any other applications from publishing), we have implemented a method to enforce the relationship between producers, topics and schemas.

## Managing schema artefacts and the path towards a dynamic registry
A key requirement for implementing central management of schemas is to minimise the burden for developers. One of the advantages of the Confluent Schema registry is that schema management is handled without the need to include generated code within client applications. While generated code can be useful in some instances (where one wishes to manage the use of a particular version of the schema within an application in a highly controlled manner), in other cases a client may be better off treating schema definitions more like configuration, available within the run-time environment. In the case of Deliveroo’s Kafka Producer API, requiring a library version update and re-release of the application every time the schema changed was deemed too heavyweight to suit the pace of development. To get around this, we’ve implemented a two pronged approach for the distribution of schema information for clients. The first method is in the form of generated code artefacts in relevant Deliveroo languages, held in code repositories. The schema dependencies are then included in client projects through relevant package managers. The second method, which was first implemented so that the Producer API would quickly adapt to the latest schemas, makes use of the Protobuf FileDescriptor API. This generates a master binary schema file which can be loaded dynamically from Amazon S3. The Producer API then loads this file and uses it to validate all incoming messages.

<figure>
![Data flow](/images/posts/proto-schema-registry/proto-layout.png)
</figure>

## Limitations
The setup outlined in this article does limit the enforcement of our contract only to publishers over HTTP for the moment. In order to make Franz a more versatile system and to give better semantics when consumers demand a physical ordering according to source database activity, making use of Change Data Capture (CDC) tools like Debezium will be worth considering. These also have the advantage of ensuring that every state change is captured (something that is not guaranteed with our current producer clients). While these considerations are outside the scope of this article, CDC tools are worthy of evaluation as another class of producer client. In order to accommodate these, we will need a new implementation of the concepts outlined here in order to enforce the contract. 







