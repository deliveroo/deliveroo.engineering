---
layout:     guidelines
title:      "API design"
collection: guidelines
---

# Designing APIs in a resource-oriented architecture

This set of guidelines and conventions outline how to design APIs that are
reusable and match with our [Service
design](http://deliveroo.engineering/guide/services) guidelines.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

  - [1. General principles](#1-general-principles)
    - [1.1. RESTful](#11-restful)
    - [1.2. Hypermedia / HATEOAS](#12-hypermedia--hateoas)
    - [1.3. Fine-grained](#13-fine-grained)
  - [2. API and domain modelling](#2-api-and-domain-modelling)
    - [2.1. Listing intrinsic properties](#21-listing-intrinsic-properties)
    - [2.2. Listing relations](#22-listing-relations)
    - [2.3. Normalising concepts](#23-normalising-concepts)
  - [3. Documenting APIs](#3-documenting-apis)
  - [4. Conventions on requests](#4-conventions-on-requests)
    - [4.1. Content type negotiation](#41-content-type-negotiation)
    - [4.2. Path segments](#42-path-segments)
    - [4.3. Naming](#43-naming)
    - [4.4. Parameters](#44-parameters)
    - [4.5. Multi-tenancy](#45-multi-tenancy)
    - [4.6. Security](#46-security)
    - [4.7. Versioning](#47-versioning)
    - [4.8. Internationalisation (i18n)](#48-internationalisation-i18n)
  - [5. Conventions on responses](#5-conventions-on-responses)
    - [5.1. Single-resource representation](#51-single-resource-representation)
    - [5.2. Single-entity GET endpoints](#52-single-entity-get-endpoints)
    - [5.3. Collection GET endpoints](#53-collection-get-endpoints)
    - [5.4 POST, creating entities](#54-post-creating-entities)
    - [5.5 PUT and PATCH, mutating entities](#55-put-and-patch-mutating-entities)
    - [5.6. Return codes and errors](#56-return-codes-and-errors)
    - [5.7. Query parameters](#57-query-parameters)
    - [5.8. Caching](#58-caching)
    - [5.9. Compression](#59-compression)
  - [6. Tools of the trade](#6-tools-of-the-trade)
    - [Clients](#clients)
    - [Servers](#servers)
  - [7. Further reading](#7-further-reading)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

**Note to readers**: Many responses in this document will be represented as
equivalent Yaml instead of JSON for conciseness; actual responses should still
be JSON.


## 1. General principles

We choose to adopt three general principles. Here's a shortcut to remember:

> **RESTful, Hypermedia, Fine-grained**


### 1.1. RESTful

We decide that our APIs will let consumers perform [Representational State
Transfer](http://en.wikipedia.org/wiki/Representational_state_transfer), as
opposed to Remote Procedure Call.  In particular, this means that:

1. The top-level concepts of the APIs are always **nouns**, i.e. paths
   contain nouns which refer to the domain concepts.

2. The only verbs are HTTP verbs: `GET` to read, `POST` to create, `PUT` and
   `PATCH` to modify, `DELETE` to destroy, and `HEAD` to obtain metadata.
   
3. Read methods (`GET`, `HEAD`) have no side effects, and write methods (`PUT`,
   `PATCH`) are idempotent.


Example of verb v noun usage:

- Good: `POST /bookings { property: { id: 1234 } }`
- Bad: `POST /property/1234/book`

Example of proper method usage:

- Good: `PATCH /bookings/432 { state: "requested", payment_id: 111 }`
- Bad:  `POST  /bookings/432 { state: "requested", payment_id: 111 }`


### 1.2. Hypermedia / HATEOAS

The principle of [HATEOAS](http://en.wikipedia.org/wiki/HATEOAS) is that "a
client interacts with a network application entirely through hypermedia provided
dynamically by application servers. (...) The HATEOAS constraint decouples
client and server in a way that allows the server functionality to evolve
independently."

In practice, this means that interacting with the API should generally rely on
URLs, not IDs (like our internal, numeric identifiers for resources).  In
responses, associations are specified using their URL.

More importantly, **consumers should not need to construct URLs**, instead using
only URLs dynamically discovered in responses.

Ideally the domain can be discovered by calling `GET` on the root:

```
GET /api
Accept: application/hal+json

HTTP/1.0 200 OK
Content-Type: application/hal+json;v=2
Vary: Accept
{ 
  "_links": {
    "properties": "/api/properties",
    "bookings":   "/api/bookings"
  },
  "versions": ["v1", "v2"]
}
```

This lowers coupling as consumers no longer need to maintain a copy of the
routing table of the services they consumer.

HATEOAS is difficult to achieve in practice on large APIs, but is a very
valuable target to aim for.


### 1.3. Fine-grained


A fine-grained API should provide

- only one way to obtain an entity representation, or to make changes; and
- represent entities with as little information as possible.

The purpose is to honour the "principle of least surprise" and minimise
confusion with developers consuming the API; we aim to make the answers to
"how do I get information about a _{thing}_" or "what's this field for
again" as obvious as possible.

In practice, this means that:

**A given entity has a single, canonical route.**

... although there may be more than one route for its concept.

Good:

    
    GET   /users/{id}              # single user
    GET   /users                   # user index
    GET   /properties/{id}/guests  # property's user index

Bad:

    GET   /users/{id}                  # single user
    GET   /properties/{id}/guest/{id}  # duplicate!


**Embedding entities should be avoided**

If an entity's representation contains a representations of its relations, 

- there is no longer a simple way to get the relations' representation; and
- the parent entity can often no longer be efficiently cached (as the cache
  would need to be invalidated whenever the related entity changes).

In practice, embedded documents should be avoided.

Good:

```yml
#> GET /properties/123
#< HTTP/1.0 200 OK
id: 123
_links:
  host: /users/111
```

Bad:

```yml
#> GET /properties/123
#< HTTP/1.0 200 OK
id: 123
_embedded:
  host:
    id:   111
    name: "John O'Foobar"
```

Exceptions can be made on a case-by-case basis, see the "Domain modelling" section below.

**Few fields should be returned**

Few fields mean the response payloads will be small and be more cacheable, both
good characteristics of an API.

If a representation has many fields, it's usually a symptom of poor domain
modelling; a classic cause being that the representation is just a dump of the
underlying storage columns.

Look out for implicitly embedded relations as a possible API design issue, and
normalise/decouple the API.


**Many calls may be required**

A consequence of a well-normalised API is that many calls may be required to
render anything significant.

For instance, take a listing page for a product catalog: you'll probably need to make 

- one "index" API call to obtain the list or page of products;
- one call per listed product to get its name and price;
- another call per product to get its review score.

For those coming from coupled applications, you'll typically make one call per
_database row_ you'd ordinarily fetch.  This may sound dire, but isn't normally
a problem with a good use of caches:

- client cost is low (HTTP connections are reusable, and can be done in parallel);
- scalability is very high (each request is small; a group of requests can be
  dispatched to many servers; most requests can be cached; and the resulting
  database queries are typically key-value fetches).

An important corner case is when building **mobile-friendly APIs** as opposed to
inter-service APIs.  Here, it's often important to limit the number of requests,
mainly because the client cost is very high (HTTP connections are not reusable,
slow to establish, and cannot be parallelised) and scalability is poor (caching
space is limited, bandwidth is limited).

The recommended pattern is not to disregard these guidelines, but instead to
build a **facade service** which:

- receives requests for "batches" of aggregate information;
- allow the consumer to make just one call in the example above;
- aggregate resource payloads, possibly from multiple services, probably in
  parallel;
- itself has aggressive caching built in.

Such a facade service can be considered a "view service" which pre-renders to
JSON.


----------

## 2. API and domain modelling

----------

## 3. Documenting APIs

----------

## 4. Conventions on requests

----------

## 5. Conventions on responses

----------

## 6. Tools of the trade

----------

## 7. Further reading

