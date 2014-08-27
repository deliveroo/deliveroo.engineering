# Designing APIs in a microservices architecture

This set of guidelines and conventions outline how to design APIs that are
reusable and match with out [Service
design](https://github.com/HouseTrip/guidelines/blob/master/active-record.m://github.com/HouseTrip/guidelines/blob/master/services.md)
guidelines.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

  - [General principles](#general-principles)
    - [RESTful](#restful)
    - [Hypermedia / HatEoAS](#hypermedia--hateoas)
    - [Many-calls](#many-calls)
  - [API and domain modeling](#api-and-domain-modeling)
    - [Naming & paremeters](#naming-&-paremeters)
  - [Documentation](#documentation)
  - [General API conventions](#general-api-conventions)
    - [Authentication](#authentication)
    - [Versioning](#versioning)
    - [i18n](#i18n)
    - [Multi-tenancy](#multi-tenancy)
  - [Conventions on responses](#conventions-on-responses)
    - [GET endpoints (for single resources)](#get-endpoints-for-single-resources)
    - ["Index" GET endpoints (for collections)](#index-get-endpoints-for-collections)
    - [POST and PUT endpoints](#post-and-put-endpoints)
    - [PATCH endpoints](#patch-endpoints)
    - [Versioning entities](#versioning-entities)
    - [Return codes and errors](#return-codes-and-errors)
    - ["Extra" parameters](#extra-parameters)
    - [Caching](#caching)
    - [Compression](#compression)
  - [Tools and Examples](#tools-and-examples)
    - [Clients](#clients)
    - [Servers](#servers)
  - [Further reading](#further-reading)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

----------

## General principles

We choose to adopt three general principles. Here's a shortcut to remember:

> **RESTful, Hypermedia, Many-calls, Concise**


### RESTful

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

### Hypermedia / HATEOAS

The principle of [HATEOAS](http://en.wikipedia.org/wiki/HATEOAS) is that "a
client interacts with a network application entirely through hypermedia provided
dynamically by application servers. (...) The HATEOAS constraint decouples
client and server in a way that allows the server functionality to evolve
independently."

In practice, this means that interacting with the API should rely on **URLs, not
IDs** (like our internal, numeric identifiers for resources):

- In responses, associations are specified using their URL.
- Consumers should not need to construct URLs, instead using only URLs
  dynamically discovered in responses.

Ideally the domain can be discovered by calling `GET` on the root:

    > GET /api
    > Accept: application/hal+json
    < { 
    <   _links: {
    <     properties: "/api/{version}/properties",
    <     bookings:   "/api/{version}/bookings"
    <   },
    <   versions: ["v1", "v2"]
    < }

This lowers coupling as consumers no longer need to maintain a copy of the
routing table of the services they consumer.

HATEOS is difficult to achieve in practice on large APIs, but is a very valuable
target to aim for.


### Many-calls

- make many calls
  - client cost is low (reusable connections, parallelism)
  - better scalability (small requests, dispatched to many servers; caching; small DB queries)


### Concise

- one way to query for data or make changes
  - no multiple routes for the same resource (/users/1234 v /properties/11/host)
  - avoid embedded documents
  - avoid multiple naming (host, guest, author -> user)
  - IDs v URLs: favour URLs


## API and domain modeling

- concepts v database
- mutation of entities can need to be materialised
- intrinsic v extrinsic
  gray area: localised property descriptions
    modifying the domain for performance reasons

- surfacing concepts for technical reasons

Can the user's avatar change without the user becoming a "different" user? Does it change on a different schedule? Can a user _not_ have an avatar?
Yes -> hint it's not intrinsic.
Is an avatar used similarly to another concept (property photo)
Yes -> hint it's probably the same top-level domain model.

KArlo:
it is a difficult question, but one question could be: "is this value or entity be the same for someone else - if no, it is intrinsic"
for example, my avatar should never be user by someone else -> intrinsic

### Naming & paremeters

- URLs nesting follows the domain (/properites/:id:/photos)
- parameters v segment: ownership? makes sense without the parameter? index
  needed?

no params for GET in general

exception: supporting "legacy", non-compliant apps in a transition process


## Documentation

- APIs documented (apiary) & discussed before being implemented (design)


## General API conventions

### Authentication

- HTTP Basic
- Digest + persistent connections (otherwise 2x request overhead of the digest
  challenge-response)


### Versioning

version using the path
authoritative URLs replaced with URL templates:

`/api/{version}/properties/1234`

### i18n

not decided. options:
- use headers (Accept-Language), not testable by PMs easily
- user param (locale)

in either option, how can we auto-cache for multiple locales?

jesper [12:20] 
:question: Any reasons why we translate the api endpoints?  example: `/en/api/internal/v1/properties/{property_id}` http://docs.internalapiv10.apiary.io/

mezis [12:21] 
i18n is a representation. "translating" the endpoints would infer distinct resources.
so `/api/internal/v1/properties/{id}.json{?locale}` would make more sense. (edited)
(hopefully that just made sense!)
I'll add a paragraph in the upcoming "APIs guideline" document

Event better (more standard): use the `Accept-Language` header (it's part of
HTTP)

### Multi-tenancy

- "tenant" is the first component of the path after `/api/{version}`
- mandatory for all services but the monorail


## Conventions on responses

- hypermedia links
- no document nesting in responses
  - avoids endless debate on where to limit, what fields to limit to

### GET endpoints (for single resources)

- intrinsic properties only (eg nested photos)
  - think hard when exposing a field, case by case
  - e.g. photos - image_file_name
- intrinsic-ness might be gray (e.g. modeling descriptions as a separate concept)
- plus counts (which cannot be expressed otherwise), in hypermedia links section

### "Index" GET endpoints (for collections)

- make no assumptions on consumers (example of listable properties and /properties)
- metadata in headers
- index actions always have paging (total, page_limit)
  pagination in Link headers
  other metadata in headers: X-Pagination-Total, X-Pagination-Page-Size,
  X-Pagination-Current-Page
- collections as arrays, collection metadata in headers (X-PageSize)
- provides for "counting" endpoints (using HEAD and looking at
  X-Pagination-Total)
- per_page, page query parameters

Rationale: 

In domain terms, an index endpoint actually returns a _view_ on the _collection_
of resources; ie. the resource returned is the view.
The current page, links, and page size are _data_ of that view. The number of
pages and the total number of resources depend (if your view can filter it's
data; if it can only order it's metadata). (edited)

For the sake of consistency, I'd argue that the 2 latter should be both in the
payload (because it's usually data) and the headers (because you want to count).
(edited)

### POST and PUT endpoints


### PATCH endpoints


- explain PATCH v PUT



### Versioning entities

"Update hole" within a GET - PUT/PATCH cycle.
Optimistic Locking
lock_version field

### Return codes and errors

text/plain
only valuable for users
should _not_ be parsed (errors, like exceptions, are not to be used for flow
control)

use codes as close as possible to being semantic

don't confuse syntax & semantic failures

- 400 Bad Request -> bad _syntax_ (unknown route, missing required parameters, unknown extra parameters)
- 404 Not Found
- 409 Conflict -> POST with unique fields
- 422 Unprocessable entity -> inconsistency in GET/POST parameters
- 428 Precondition failed -> GET/PUT cycles (see versioning entities)

success codes

- 200 v 204
- 200 v 201 v 202

### "Extra" parameters

are an error
payload in POST/PUT, parameters in GET


### Caching

- GET endpoints heavily cached for immutable entities (photos, translations)
     faraday cache middleware


- architecture / domain / authority on concepts and on functions

- optimistic caching first: Cache-Control + client cache
- pessimistic caching second: ETag/If-None-Match

may be ignored for GETs when using routemaster


### Compression

optional


## Tools and Examples

### Clients

Faraday (for simple APIs / use cases)
Hyperclient / Hyperresource (uses Faraday)

routemaster-receiver (to come)

### Servers

Rails + Roar

no Grape, Rails-API (because of no router)

## Further reading

principles
http://restful-api-design.readthedocs.org/
http://en.wikipedia.org/wiki/Representational_state_transfer
http://en.wikipedia.org/wiki/HATEOAS

example decently well-though API
https://developer.github.com

context and debate
http://devblog.reverb.com/post/47197560134/hal-siren-rabl-roar-garner-building-hypermedia
http://www.foxycart.com/blog/the-hypermedia-debate
http://stackoverflow.com/questions/9055197/splitting-hairs-with-rest-does-a-standard-json-rest-api-violate-hateoas

specs for `application/hal+json`
http://stateless.co/hal_specification.html
http://tools.ietf.org/html/draft-kelly-json-hal-06

presentation of JSON HAL
http://alphahydrae.com/2013/06/rest-and-hypermedia-apis/

emitting JSON HAL
Grape + Roar
https://github.com/apotonick/roar

reading JSON HAL
both based on Faraday
http://codegram.github.io/hyperclient/
https://github.com/gamache/hyperresource/

