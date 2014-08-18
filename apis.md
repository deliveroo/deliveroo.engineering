# Designing APIs

This set of guidelines outline how to design APIs that are reusable and match
with out [Service
design](https://github.com/HouseTrip/guidelines/blob/master/active-record.m://github.com/HouseTrip/guidelines/blob/master/services.md)
guidelines.


General principles

- Representational State Transfer
  - only verbs are HTTP verbs
  - idempotency

- HATEOAS
  - dynamic discovery or URLs 
  - no URL construction in clients (which would be tight coupling)

- make many calls
  - client cost is low (reusable connections, parallelism)
  - better scalability (small requests, dispatched to many servers; caching; small DB queries)

## Domain modeling

- concepts v database
- mutation of entities can need to be materialised
- intrinsic v extrinsic
  gray area: localised property descriptions
    modifying the domain for performance reasons


## Documentation

- APIs documented (apiary) & discussed before being implemented (design)


## Authentication

- HTTP Basic
- Digest + persistent connections (otherwise 2x request overhead of the digest
  challenge-response)


## Naming & paremeters

- URLs nesting follows the domain (/properites/:id:/photos)
- parameters v segment: ownership? makes sense without the parameter? index
  needed?


## Responses

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


### POST and PUT endpoints


### PATCH endpoints


- explain PATCH v PUT



### Versioning entities

"Update hole" within a GET - PUT/PATCH cycle.
Optimistic Locking
lock_version field

## Errors

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

### "Extra" parameters

are an error
payload in POST/PUT, parameters in GET


## Caching

- GET endpoints heavily cached for immutable entities (photos, translations)
     faraday cache middleware


- architecture / domain / authority on concepts and on functions


## Localisation


jesper [12:20] 
:question: Any reasons why we translate the api endpoints?  example: `/en/api/internal/v1/properties/{property_id}` http://docs.internalapiv10.apiary.io/

mezis [12:21] 
i18n is a representation. "translating" the endpoints would infer distinct resources.
so `/api/internal/v1/properties/{id}.json{?locale}` would make more sense. (edited)
(hopefully that just made sense!)
I'll add a paragraph in the upcoming "APIs guideline" document

Event better (more standard): use the `Accept-Language` header (it's part of
HTTP)


## Tools

### Clients

Faraday (for simple APIs / use cases)
Hyperclient / Hyperresource (uses Faraday)

### Servers

Grape + Roar
Rails + Roar

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

