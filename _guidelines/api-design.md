---
layout:     guidelines
title:      "API design"
collection: guidelines
---



> These guidelines mostly apply to _internal_ APIs, meant to be consumed by
> software we build and maintain.
>
> APIs that face the public, or 3rd-party integrators, or simply our own apps
> outside the datacenter, have very different constraints.
> The section [external-facing APIs](#external-facing) has details on how to
> handle those cases.
{: .dg-sidebar.dg-warning }

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
- [3. Documenting APIs](#3-documenting-apis)
- [4. Conventions on requests](#4-conventions-on-requests)
- [5. Conventions on responses](#5-conventions-on-responses)
- [6. External-facing APIs](#6-external-facing-apis)
  - [6.1. Mobile-friendly APIs](#61-mobile-friendly-apis)
  - [6.2. Public-friendly APIs](#62-public-friendly-apis)
- [7. Tools of the trade](#7-tools-of-the-trade)
- [8. Further reading](#8-further-reading)

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

2. The only verbs are HTTP verbs: `GET` to read, `POST` to create, `PATCH` to
   modify, `DELETE` to destroy, and `HEAD` to obtain metadata.
   
3. Read methods (`GET`, `HEAD`) have no side effects, and write methods
   (`PATCH`) are idempotent.

4. `DELETE` is _not_ idempotent and should return 404 or 410 when the resource
   does not exist (or not any longer).


Example of verb v noun usage:

- Good: `POST /bookings { property: { id: 1234 } }`
- Bad: `POST /property/1234/book`

Example of proper method usage:

- Good: `PATCH /bookings/432 { state: "requested", payment_id: 111 }`
- Bad:  `POST  /bookings/432 { state: "requested", payment_id: 111 }`

Note that the `PUT` verb, which is fairly ambiguous (can both create or update a
resource) should generally not be used.


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
Accept: application/json

HTTP/1.0 200 OK
Content-Type: application/json
Vary: Accept

_links:
  properties:
    href: /api/properties
  property:
    href: /api/properties/{id}
    templated: true
  bookings:
    href: /api/bookings
  booking:
    href: /api/bookings/{id}
    templated: true
```

This lowers coupling as consumers no longer need to maintain a copy of the
routing table of the services they consume.

HATEOAS is difficult to achieve in practice on large APIs, but is a very
valuable target to aim for - it significantly improves maintainability and
allows for high-level clients that can "walk" relationships transparently.


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

In practice, embedded documents should be avoided as they make caching horribly
difficult.

Good:

```yml
#> GET /properties
#< HTTP/1.0 200 OK
_links:
  property: 
    - href: /properties/123
    - href: /properties/124
```

```yml
#> GET /properties/123
#< HTTP/1.0 200 OK
id: 123
name: "Beautiful duplex flat in Marylebone"
_links:
  host:
    href: /users/111
```

Bad:

Embedding on index requests.

```yml
#> GET /properties
#< HTTP/1.0 200 OK
property:
  - id: 123
    _links:
      host:
        href: /users/111
  - id: 124
    _links:
      host:
        href: /users/112
```

Embedding on resource requests.

```yml
#> GET /properties/123
#< HTTP/1.0 200 OK
id: 123
_embedded:
  host:
    id:   111
    name: "John O'Foobar"
```

Exceptions on embedding can be made on a case-by-case basis, see the "Domain
modelling" section below.

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

See also the [External-facing APIs](#external-facing) for generics on
non-internal APIs; [this article](http://dec0de.me/2014/09/resn-routemaster/)
also has a more elaborate explanation and example.


----------

## 2. API and domain modelling

----------

## 3. Documenting APIs

----------

## 4. Conventions on requests

----------

## 5. Conventions on responses

----------

{: #external-facing}

## 6. External-facing APIs


We want to do our best to make out internal services use HATEOAS and we can try
and catch any URL construction in PRs, but for anything exposed to third-party
API consumers (integrators, developers in the general public) — it's unlikely
that everyone will stick to these ideals.

Performance constraints can also be quite different.

### 6.1. Mobile-friendly APIs

To build APIs that are friendly to mobile consumers, special attention is needed
to limit the number of requests. This is because mobile connections are
(relatively) high latency, and the cost of the roundtrip can result in bad user
experience.

Our recommendation is to

1. Still expose "pure", RESTful, hypermedia APIs, but not to the app directly;
2. Provide a "mobile adapter" service that uses the pure APIs to provide a less
   "chatty" interface.

The benefit of this approach is that the caching capabilities of the RESTful
approach are preserved. The adapter service can aggressively cache
representations, but has little logic beyond that — in particular, it owns no
domain concept and should normally have no persistent storage.

In particular, the mobile adapter can take care of user-facing request
authentication; whereas the internal services only need to care about
service-to-service authentication.


### 6.2. Public-friendly APIs

For external services we should to stick to a somewhat different set of
principles, because of the low incentive for 3rd-party consumers to support
maintainability of _our_ software.

1. As above, public APIs should be implemented in terms or our private, "pure"
   APIs, in separate adapter services.
2. API URLs should never change (because consumers risk constructing their own).
3. While it is still recommended to include hypermedia links to encourage good
   practices, is it not mandated like for internal services.
4. The recommended practice for versioning is DNS-based: a new (breaking/major)
   version of a set of public-facing APIS should be an entirely new domain (e.g.
   `v2.my-api.example.com`), with entirely segregated infrastructure.

----------

## 7. Tools of the trade

----------

## 8. Further reading

