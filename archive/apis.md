# Designing APIs in a resource-oriented architecture

This set of guidelines and conventions outline how to design APIs that are
reusable and match with our [Service
design](https://github.com/HouseTrip/guidelines/blob/master/services.md)
guidelines.

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

**Note to readers**: Many responses in this document will be represented as equivalent Yaml instead of JSON for conciseness; actual responses should still be JSON.


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

In practice, this means that interacting with the API should generally rely on URLs, not
IDs (like our internal, numeric identifiers for resources).
In responses, associations are specified using their URL.

More importantly, **consumers should not need to construct URLs**, instead using only URLs dynamically discovered in responses.

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

HATEOAS is difficult to achieve in practice on large APIs, but is a very valuable
target to aim for.


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
- the parent entity can often no longer be efficiently cached (as the cache would need to be invalidated whenever the related entity changes).

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

Few fields mean the response payloads will be small and be more cacheable, both good characteristics of an API.

If a representation has many fields, it's usually a symptom of poor domain modelling; a classic cause being that the representation is just a dump of the underlying storage columns.

Look out for implicitly embedded relations as a possible API design issue, and normalise/decouple the API.


**Many calls may be required**

A consequence of a well-normalised API is that many calls may be required to render anything significant.

For instance, take a listing page for a product catalog: you'll probably need to make 

- one "index" API call to obtain the list or page of products;
- one call per listed product to get its name and price;
- another call per product to get its review score.

For those coming from coupled applications, you'll typically make one call per _database row_ you'd ordinarily fetch.
This may sound dire, but isn't normally a problem with a good use of caches:

- client cost is low (HTTP connections are reusable, and can be done in parallel);
- scalability is very high (each request is small; a group of requests can be dispatched to many servers; most requests can be cached; and the resulting database queries are typically key-value fetches).

An important corner case is when building **mobile-friendly APIs** as opposed to inter-service APIs.
Here, it's often important to limit the number of requests, mainly because the client cost is very high (HTTP connections are not reusable, slow to establish, and cannot be parallelised) and scalability is poor (caching space is limited, bandwidth is limited).

The recommended pattern is not to disregard these guidelines, but instead to build a **facade service** which:

- receives requests for "batches" of aggregate information;
- allow the consumer to make just one call in the example above;
- aggregate resource payloads, possibly from multiple services, probably in parallel;
- itself has aggressive caching built in.

Such a facade service can be considered a "view service" which pre-renders to JSON.



## 2. API and domain modelling

Defining good APIs (with respect to the principles outlined above) relies on domain-driven design.

This, in turn, requires one to abstract out any implementation details (particularly, how "things" will be stored in a database), and instead reflect on what the domain is, how it can be split down into concepts and operations on those.
Clarity on naming is crucial.

We recommend reading about [Domain driven design](http://en.wikipedia.org/wiki/Domain-driven_design), although in many cases common sense can be enough.

An **entity** of the domain is _an object that is not defined by its attributes, but rather by a thread of continuity and its identity_. A given user, a given property are entities; their name may change without breaking the "thread of identity". We refer to a given identity by a (unique) identifier, its URL. For instance, _User 1234_ can solely referred to by the URL `/users/1234`.

A **concept** of a domain is the set of entities that have a similar representation and lifecycle; _users_ or _properties_ are concepts.

An entity can have any number of _representations_. The canonical one is obtained by requesting its URL, and is composed of

- a set of intrinsic properties, and
- links to related entities (using their URL);

Note that **intrinsic properties** are not "database fields"; the worst possible way to represent an entity is by dumping the way it's been stored in a legacy system.

### 2.1. Listing intrinsic properties

Listing intrinsic properties is a difficult task, as it's usually a grey area with no hard answers. We can, however, provide a number of _hints_ that a property is intrinsic (and therefore should be part of the representation) or extrinsic (and should probably be part of a linked entity's representation, instead).

No single hint can lead to the conclusion that a given property is intrinsic or extrinsic; it's generally the addition that matters.

Hint towards extrinsic:

- *Separate change*: The URL of a user's avatar image can change without the identity of the user changing.
- *Optional property*: A user can not have an avatar, and it's commonplace.
- *Structured properties*: A property bedroom has a number of beds, bed types, surface.
- *Shared concept*: an avatar is an image, and other concepts (e.g. properties) relate to images.

Hints towards intrinsic:

- *Value object*: 
    - A property's name is a simple string. The string itself is immutable.
    - A user's avatar an image, which itself is a file with a storage location, a size, dimensions, and a MIME type, but is immutable.

A classic trap is the "physical inclusion" trap. For instance, _bedrooms are inside properties_ does not imply that the representation of bedrooms must be properties of the representation of properties. They _can_, but that's a modelling decision; one can, for instance

- Decide that bedrooms should not exist as a standalone concept, because they're  immutable;
- Decide they exist as a standalone concept, but embed their representation inside that of their parent property, because they're _almost_ immutable (and deal with possible caching issues);
- Decide they're simply a relation of properties, because they're mutable or the payload size would be too large.


### 2.2. Listing relations

Typically, when exposing a concept with an API, the database will contain a number of `thing_id` columns.

These are *relations*, not properties; the payload should contain a number of links to the corresponding resources, but should not (ever) contain `thing_id` properties.


### 2.3. Normalising concepts

Elaborating on the example above, it's not uncommon for an entity to refer to multiple, similar others. A property's record can for instance contain a `city_id`, `region_id`, and `country_id`.

The naive transformation into an API would be to entities of the `city`, `region`, and `country` concepts;

One could argue this is a lack of normalisation; and that cities, regions, and countries are actually entities of a broader `places` concept; properties then relate to a number of places with varied `kind` properties, and which relate to each other as a tree (or digraph).



## 3. Documenting APIs

API users are both developers and machines; therefore, you should:

- Discuss APIs _before_ starting any implementation: you're wearing your designer hat here.
- Documented in a human-readable format. We recommend [Apiary](http://apiary.io/) and the [API Blueprint](http://apiblueprint.org/) standard `.apib` files.



## 4. Conventions on requests

### 4.1. Content type negotiation

All requests _should_ include the `Accept: application/hal+json` headers.

Requests _may_ use the `application/json` MIME type instead for backwards compatibility reasons.

The `Accept` header _may_ include the `v` parameter to specify the API version requested; see "Versioning" below.

Server _may_ react to the `Accept-Language` header, see "i18n" below.


### 4.2. Path segments

There _should not_ be more than 3 path segments, API root (typically `/`, `/api`, or `/api/{tenant}`) excluded.

In practice:

- each concept _must_ be exposed as a top level segment, e.g. `/photos{/id}`, `/properties{/id}`, etc)
- resources _should not_ be nested, e.g. `/properties/{id}/photos/{pid}` is bad)
- there _may_ be a nested index for related entities, e.g. `/properties/{id}/photos`.

As a rule of thumb, there _should not_ be more than one (numeric) identifier per URL.

### 4.3. Naming

All path segments which refer to a domain concept _should_ be plurals, except if there is only zero or one entity in the concept, or it is a index endpoint for a relation.

Note that relation endpoints _must_ link to a toplevel endpoint.

Example: 

```
/host_profiles/{id}
/users/{id}/host_profile

/photos/{id}
/properties/{id}/photos
```

### 4.4. Parameters

Endpoints returning single entities _should not_ accept any parameters. They _may_ return an error if parameters are passed.

- Good: `/properties/{id}`
- Bad: `/properties/{id}{?fields}`

An exception _may_ be made for backwards compatibility reasons (supporting "legacy", non-compliant apps in a transition process). In such cases, only one parameter is allowed; its name _must_ be `legacy` and its value _should_ be ignored (only its presence is relevant).

Collection endpoints _may_ accept parameters. If they do, those _must_ be specified in the root document's link relations.

Example:

```yml
#> GET /api
#< HTTP/1.0 200 OK
_links:
  property:
    href:      "/properties/{id}"
    templated: true
  properties:
    href:      "/properties{?published}"
    templated: true
  property_photos:
    href:      "/properties/{id}/photos{?default}"
    templated: true
```

_Note_: in a root document, the `href` fields will typically be URI templates as per RFC 6570.

### 4.5. Multi-tenancy

A service _should_ include a tenant name as a path segment; in this case the API prefix is typically `/api/{tenant}`.

Entity URLs then can be for instance:

```
/api/staging12/properties/1234
/api/staging9/properties/1234
```


The rationale is that:
- multi-tenancy may be needed needed to reduce the number of running instances of a service, when multiple testing environments (or client environments) are required;
- different entities belonging to different tenants may have the same numeric ID, but need to have distinct URLs.

Conversely, the tenant name _must not_ be passed as a query parameter or as a header.

Mono-tenant services (e.g. a central monolith in our case) _may_ exclude this, as the tenant name is implicit (it is part of the FQDN); e.g.:

```
https://staging12.acme.com/api/properties/1234
https://staging9.acme.com/api/properties/1234
```

### 4.6. Security

A service _must_ accept connections over HTTPS. It _should not_ respond over plain HTTP, and in particular, it _should not_ redirect from HTTP to HTTPS. It _should_ respond to plain HTTP requests with status 426, Upgrade Required.

A service _should_ require HTTP Basic authentication. It _should_ ignore the username and use the password as a token. It _may_ accept unauthenticated requests for some endpoints.

Rationale: why not HTTP Digest?

- Digest has 2x request overhead of the Basic for the first request (challenge-response);
- It is not needed with SSL, as (a) the enclosing protocol is encrypted and has its own challenge-response mechanism, and (b) refusing connections over HTTP reduces the risk of cleartext passwords.



### 4.7. Versioning

A service _may_ provide different APIs (endpoints and representations) in the form of API versions.

Clients _may_ specify a desired version as the `v` parameter of the `Accept` header, for instance:

    Accept: application/hal+json;v=2

The service _should_ respond with status 406, Not Acceptable if the version is unavailable.

If a version was specified by the client, and is available, the service _must_ respond with the same version:

    # Request:
    Accept: application/hal+json;v=2

    # Response:
    Content-Type: application/hal+json;v=2

If the version was unspecified, the server _should_ use the latest available version, and specify the `Vary` header, as future request may yield a different response:

    # Request:
    Accept: application/hal+json

    # Response:
    Content-Type: application/hal+json;v=2
    Vary: Accept

Finally, a service's root endpoint _should_ list the available versions:

```yml
#> GET /api
#< HTTP/1.0 200 OK
_links:
  ... 
versions:
  - 1
  - 2
```


_Note_: Another Approach is to version APIs through path segments (e.g. `/api/v1/things/123`). We choose not to follow it:the major issue is that entities may have multiple URLs which risk being misinterpreted as referencing different entities.



### 4.8. Internationalisation (i18n)

A service _may_ provide internationalised representations of entities.

A client _may_ specify their desired locale using the `Accept-Language` header as per [RFC 2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4).

If representation is localised, the service _should_ include the `Content-Language` header in the response.

If the locale requested is not available, the service _should_ respond with status 406, Not Acceptable.

If the response does not match the requested locale exactly (either more than one locale options were requested, or none), the service _should_ include the `Vary: Accept-Language` header in the response.

Rationale:

- Including the locale in the path (e.g. `/api/en/things/123`) suffers from the same lack-of-uniqueness issue mentioned in "versioning" above.
- Including the locale in a parameter violates conventions on parameters.
- Localisation is inherently a representation concern, and HTTP mandates such concerns to be addressed using protocol headers.


## 5. Conventions on responses

Responses _should_ be valid [JSON-HAL](https://tools.ietf.org/html/draft-kelly-json-hal) documents, with the following extension:

>  Instead of a link object, a link relation can map directly to the link URL when the name of the relation, and the URL is not templated.

In addition, embedded entities (using `_embedded`) should be avoided when possible, and only introduced:

- for collections; or
- for excruciating performance reasons; or
- when the (partial) representation of the embedded entity is immutable with respect to the parent.


### 5.1. Single-resource representation

A single resource representation _should_ have a numeric `id` field.
It _must_ have a link to `self`.
It _may_ contain a number of intrinsic properties of the entity (see the "domain modelling" discussion above.

Example:

```yml
#> GET /properties/1234
#< HTTP/1.0 200 OK
id:   1337
name: "Beautiful apartment"
lat:  1.2345
lng:  45.678
_links:
  self:     "/properties/1337"
  reviews:  "/properties/1337/reviews"
  host:     
    href:   "/users/8008"
    type:   "user"
  places:   "/properties/1337/places"
  photos:   "/properties/1337/photos"
```

Note that intrinsic-ness of a given property is a gray area: think hard and have a debate whenever considering adding another property to a representation.
There may occasionally be arguments outside the domain, e.g. performance considerations.
For instance, one may decide to model property descriptions (which are lengthy text blobs) as a relation to properties, instead of as an intrinsic field, because (a) the payload would become very large, and (b) it is seldom needed by consumers.

As a particular case, note that fields that count relations (eg. `photos_count` in the example above) are _not_ intrinsic and _should not_ be made part of the representation.

In exceptional cases, counts (which are a property of the relation) _may_ be mentioned as a link attribute. Consumers should not expect the value to be authoritative, and should refer to the relation URL if consistency is required.

Example:

```yml
#> GET /properties/1234
#< HTTP/1.0 200 OK
id:   1337
_links:
  self:     "/properties/1337"
  photos:
    href:   "/properties/1337/photos"
    count:  27
```


### 5.2. Single-entity GET endpoints

A single-entity GET endpoint _should_ always be of one of the forms

- `/{concept-plural}/{id}` for typical concepts (e.g. `/properties/1234`);
- `/{concept-singular}` for singletons (e.g. `/exchange_rate`)
- `/{parent}/{id}/{concept-singular}` for singleton relations (e.g. `/users/1234/host_profile`).

Such endpoints _must_ return the representation of a single entity, and any links, as described in the previous section.

Partial responses (e.g. with `field` query param) _should not_ be returned.


### 5.3. Collection GET endpoints

A collection GET endpoint _should_ be of one of the forms:

- `/{concept-plural}`, e.g. `/properties`
- `/{parent}/{id}/{concept-plural}`, e.g. `/properties/1234/photos`

Such endpoints _must_ return a representation of the collection, and embed a list of (possibly partial) representations of some of the entities.

_Rationale_:
In domain terms, an index endpoint actually returns a _view_ on the _collection_
of resources; ie. the resource returned is the view.
The current page, links, and page size are _data_ of that view. The number of
pages and the total number of resources depend (if your view can filter it's
data; if it can only order it's metadata). (edited)

A collection representation

- _should_ link to relations `next` and `prev` for pagination purposes;
- _must_ include the properties `page`, `per_page`, `total`

In a collection representation, embedded representations _may_ be incomplete, but _should_ include at least a numeric `id` and the mandatory link to `self`.

Example:

```yml
#> GET /properties?listable=1
#< HTTP/1.0 200 OK
page:     1
per_page: 10
total:    153277
_links:
  self:   "/properties?listable=1"
  prev:   null
  next:   "/properties?listable=1&page=2"
_embedded:
  properties:
    - id: 1
      _links:
        self: "/properties/1"
    ...
    - id: 10
      _links:
        self: "/properties/2"
```


### 5.4 POST, creating entities

A collection GET endpoint _may_ respond to the POST method to create new entities.

If it exists, it _shoud_ return status

- 201 Created if the entity was successfully created, or
- 400 Bad Request if the entity cannot be created with the information in the request body.

The response _must_ be a valid single resource representation, although it _may_ be partial, including at least the numeric `id` and the mandatory link to self.

Example:

```yml
#> POST /properties
name: "Castle by the lake"
lat:  1.2345
lng:  45.678
#< HTTP/1.0 201 Created
id: 1337
_links:
  self: "/properties/1337"
```

### 5.5 PUT and PATCH, mutating entities

A single-resource GET endpoint _may_ respond to the PUT and PATCH methods to modify existing entities.

If such an endpoint exists (i.e. the API permits entity mutation), the single-resource GET endpoint _must_ include a property named `version`. This value can for instance be a timestamp, a hashsum, or a UUID, and _should_ change every time the entity is modified.

The response status _should_ be

- 200 OK, if the modification succeeded.
- 400 Bad Request, if the modification failed.
- 409 Conflict, if the `version` field is missing from the request payload, or if its value is different from the current value.

The response _must_ be a valid single resource representation, although it _may_ be partial, including at least the numeric `id` and the mandatory link to self.

Example:

```yml
#> GET /properties/1337
#< HTTP/1.0 200 OK
id:       1337
name:     "Castle by the lake"
version:  "ed6edecf-0f7c-44c1-b575-ed3a279a35bc"
_links:
  self:   "/properties/1337"

#> PATCH /properties/1337
name:     "Manor by the lake"
version:  "ed6edecf-0f7c-44c1-b575-ed3a279a35bc"
#< HTTP/1.0 200 OK
id:       1337
name:     "Manor by the lake"
version:  "daaa8952-612d-4080-b818-634dcd573a69"
_links:
  self:   "/properties/1337"
```


### 5.6. Return codes and errors

In the case of client or server errors (i.e. when the return code is 400+), the content-type _should_ be `application/hal+json`.

The results are not intended to be acted on by machines, but rather presented to users.

The response _should_ be an `errors` object whose keys are either keys present in the original request, parameter names, or the `general` key for failures not attributable to a request key.

Each value _should_ be a human readable message.

Example: index with out-of-bounds page:

```yml
#> GET /properties?page=52196
#< HTTP/1.0 404 Not Found
errors:
  page: "Page is out of bounds"
```

Example of a PATCH version fail:

```yml
#> PATCH /properties/1337
name:       "Manor by the Lake"
version:    "283753b7-d80e-411b-87d3-d2df5df2c461"
#< HTTP/1.0 409 Conflict
errors:
  version:  "Resource was updated since you read it."
```

Example of a missing value in POST:

```yml
#> POST /properties/1337
lat: "foobar"
#< HTTP/1.0 400 Bad Request
errors:
  name:  "Name is required."
  lat:   "Latitude must be a floating-point number."
  lng:   "Latitude is required."
```

HTTP status codes should be used as possible to being semantic where these guidelines are unclear. In particular, syntactic and semantic failures should not be confused:

- 400 Bad Request: bad _syntax_ (unknown route, missing required fields or parameters, unknown extra parameters, bad field or parameter values).
- 404 Not Found: the specified entity does not exist (unknown routes should not 404).
- 409 Conflict: PATCH and PUT failures with unique fields

Likewise, for success codes:

- POST, PUT and PATCH should never result in a 200 (generally 201, occasionally 202).
- 204 should not be returned.


### 5.7. Query parameters

Single-entity endpoints _should not_ accept query parameters (for any HTTP method). The only exception is the `legacy` parameter, mentioned above, which may be used during transitions.

Those endpoints _may_ return 400 Bad Request if parameters are specified.

Collection GET endpoints are the only endpoints that usually accept query parameters. Those _should_ accept the `page` and `per_page` parameters. They _may_ accept parameters that match property names of the corresponding concept; if they do, they _should_ 

- use the parameter value for filtering purposes (i.e. return entities whose corresponding property has the specified value), and
- mention those parameters in the link relation of the root document.

They _may_ accept the _order_ parameter; if they do,

- the accepted values _should_ be comma-separated lists of property names, possibly prefixed; and
- they _should_ return entities ordered accordingly.

Example:

```
GET /properties?page=1&order=-updated_at,name
```

The _may_ also respond to other parameters, although it is not recommended. If they do those _should_ be mentioned in the root document and the behaviour is unspecified.


### 5.8. Caching

Caching efficiency is a critical aim of well-designed APIs, as it is influential on service performance; cache consistency is as important.

Responses to single-resource GET endpoints _should_ specify a `Cache-Control` header.

- If the entity is mutable, the value _should_ be `no-cache`.
- If the entity is immutable (even if it can be deleted), the value _should_ be `public; max-age=31536000` (one year).

Responses to collection GET endpoints _should not_ specify a `Cache-Control` header.

All requests _may_ use the `If-None-Match` header, and all responses _should_ include an `Etag` header. This should always be based on a hash of the response, not on timestamp information.


### 5.9. Compression

Servers _may_ support the `Accept-Encoding` header for compression purposes.

*Rationale*: latency is more important than bandwidth savings for most APIs; therefore the overhead of compression is seldom justified.


## 6. Tools of the trade

### Clients

[Faraday](https://github.com/lostisland/faraday) using the [net-http-persistent](https://github.com/drbrain/net-http-persistent) adapter is recommended for simple consumer cases, where performance is not particularly required (e.g. when not reacting to browser requests, or making very few calls).

When better performance is needed:

- Using Faraday with [futures](https://github.com/meh/ruby-thread#future) is recommended to achieve concurrency. This can usually mimic 10x-100x parallelism, and is useful when a browser request requires fetching many similar resources. Clients _should not_ use Typhoeus, which requires many extra dependencies, requires C extensions, and does not achieve better performance.

- Using [routemaster-drain](https://github.com/HouseTrip/routemaster-drain#routemaster-drain) permits preemptive caching of entity representation for read-intensive consumers.

- Using [Hyperclient](https://github.com/codegram/hyperclient) allows easier walking of links between resources. It relies on Faraday.


### Servers

We strongly recommend using

- Ruby on Rails as the framework,
- [Rails-API](https://github.com/rails-api/rails-api#railsapi) if possible to lean up Rails, and
- [Roar](https://github.com/apotonick/roar) as a presenter framework for models.

Using Sinatra is _not_ recommended as there is no performance benefit over Rails, and Sinatra lacks a router (which means all link URLs must be manually built).

Using Grape is _not_ recommended as it lacks a router as well.


## 7. Further reading

- principles:
    - http://restful-api-design.readthedocs.org/
    - http://en.wikipedia.org/wiki/Representational_state_transfer
    - http://en.wikipedia.org/wiki/HATEOAS

- example of decently well-thought-out APIs and guidelines
    - https://github.com/gocardless/http-api-design
    - https://developer.github.com

- context and debate
    - http://www.troyhunt.com/2014/02/your-api-versioning-is-wrong-which-is.html
    - http://devblog.reverb.com/post/47197560134/hal-siren-rabl-roar-garner-building-hypermedia
    - http://www.foxycart.com/blog/the-hypermedia-debate
    - http://stackoverflow.com/questions/9055197/splitting-hairs-with-rest-does-a-standard-json-rest-api-violate-hateoas

- more on `application/hal+json`
    - http://tools.ietf.org/html/draft-kelly-json-hal
    - http://stateless.co/hal_specification.html
    - http://alphahydrae.com/2013/06/rest-and-hypermedia-apis/

- spec for json-api
    - http://jsonapi.org
