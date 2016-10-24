---
layout:     guidelines
title:      "API design"
subtitle:   "Designing APIs in a resource-oriented architecture"
collection: guidelines
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Introduction

This set of guidelines and conventions outline how to design APIs that are
reusable and match with our [Service design](/guidelines/services) guidelines.

These guidelines mostly apply to _internal_ APIs, meant to be consumed by
software we build and maintain.

APIs that face the public, or 3rd-party integrators, or simply our own apps
outside the datacenter, have very different constraints.

The section [external-facing APIs](#external-facing) has details on how to
handle those cases.

**Note to readers**: Many responses in this document will be represented as
equivalent Yaml instead of JSON for conciseness; actual responses should still
be JSON.

In our examples, as a use case we'll generally assume we're building APIs for a
hotel booking website - concepts will include hotels, rooms, bookings for
instance.

## General principles

We choose to adopt three general principles. Here's a shortcut to remember:

**RESTful, Hypermedia, Fine-grained**

### RESTful

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

Example of verb vs. noun usage:

```
# Good
POST /bookings { hotel: { id: 1234 } }

# Bad
POST /hotel/1234/book
````

Example of proper method usage:

```
# Good
PATCH /bookings/432 { state: "requested", payment_id: 111 }

# Bad
POST  /bookings/432 { state: "requested", payment_id: 111 }
```

Note that the `PUT` verb, which is fairly ambiguous (can both create or update a
resource) should generally not be used.

### Hypermedia / HATEOAS

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
#> GET /api
#> Accept: application/json

#< HTTP/1.0 200 OK
#< Content-Type: application/json

_links:
  hotels:
    href: /api/hotels
  hotel:
    href: /api/hotels/{id}
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

### Fine-grained

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

```
GET   /users/{id}              # single user
GET   /users                   # user index
GET   /hotels/{id}/guests      # hotel's user index
```

Bad:

```
GET   /users/{id}              # single user
GET   /hotels/{id}/guest/{id}  # duplicate!
```

**Embedding entities should be avoided**

If an entity's representation contains a representations of its relations,

- there is no longer a simple way to get the relations' representation; and
- the parent entity can often no longer be efficiently cached (as the cache
  would need to be invalidated whenever the related entity changes).

In practice, embedded documents should be avoided as they make caching horribly
difficult.

Good:

```yml
#> GET /hotels
#< HTTP/1.0 200 OK
_links:
  hotel:
    - href: /hotels/123
    - href: /hotels/124
```

```yml
#> GET /hotels/123
#< HTTP/1.0 200 OK
id: 123
name: "Luxury resort in Marylebone"
_links:
  manager:
    href: /users/111
```

Bad:

Embedding on index requests.

```yml
#> GET /hotels
#< HTTP/1.0 200 OK
hotel:
  - id: 123
    _links:
      manager:
        href: /users/111
  - id: 124
    _links:
      manager:
        href: /users/112
```

Embedding on resource requests.

```yml
#> GET /hotels/123
#< HTTP/1.0 200 OK
id: 123
_embedded:
  manager:
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
Also note that a service does not necessarily need
to expose _all_ it knows about a resource; and definitely should not expose
anything only relevant to _how_ it persists it.

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


## API and domain modelling

Defining good APIs (with respect to the principles outlined above) relies on
domain-driven design.

This, in turn, requires one to abstract out any implementation details
(particularly, how "things" will be stored in a database), and instead reflect
on what the domain is, how it can be split down into concepts and operations on
those.  Clarity on naming is crucial.

We recommend reading about [Domain driven
design](http://en.wikipedia.org/wiki/Domain-driven_design), although in many
cases common sense can be enough.

An **entity** of the domain is _an object that is not defined by its attributes,
but rather by a thread of continuity and its identity_. A given user, a given
hotel are entities; their name may change without breaking the "thread of
identity". We refer to a given identity by a (unique) identifier, its URL. For
instance, _User 1234_ can solely referred to by the URL `/users/1234`.

A **concept** of a domain is the set of entities that have a similar
representation and lifecycle; _users_ or _hotels_ are concepts.

An entity can have any number of _representations_. The canonical one is
obtained by requesting its URL, and is composed of

- a set of intrinsic properties, and
- links to related entities (using their URL);

Note that **intrinsic properties** are not "database fields"; the worst possible
way to represent an entity is by dumping the way it's been stored in a legacy
system.

### Listing intrinsic properties

Listing intrinsic properties is a difficult task, as it's usually a grey area
with no hard answers. We can, however, provide a number of _hints_ that a
property is intrinsic (and therefore should be part of the representation) or
extrinsic (and should probably be part of a linked entity's representation,
instead).

No single hint can lead to the conclusion that a given property is intrinsic or
extrinsic; it's generally the addition that matters.

Hint towards extrinsic: is a user's avatar a property, or a separate entity?

- *Separate change*: The URL of a user's avatar image can change without the
  identity of the user changing.
- *Optional property*: A user can not have an avatar, and it's commonplace.
- *Structured properties*: An avatar has width, height, colour depth.
- *Shared concept*: an avatar is an image, and other concepts (e.g. properties)
  relate to images.

Hints towards intrinsic:

- *Value object*:
    - A hotel's name is a simple string. The string itself is immutable.
    - A user's avatar is an image, which itself is a file with a storage
      location, a size, dimensions, and a MIME type, but is immutable.

A classic trap is the "physical inclusion" trap. For instance, _rooms are
inside hotels_ does not imply that the representation of rooms must be
properties of the representation of hotels. They _can_, but that's a
modelling decision; one can, for instance

- Decide that rooms should not exist as a standalone concept, because they're
  immutable;
- Decide they exist as a standalone concept, but embed their representation
  inside that of their parent hotel, because they're _almost_ immutable (and
  deal with possible caching issues);
- Decide they're simply a relation of hotels, because they're mutable or the
  payload size would be too large.


### Listing relations

Typically, when exposing a concept with an API, the database will contain a
number of `thing_id` columns.

These are *relations*, not properties; the payload can contain a number of links
to the corresponding resources, but should not (ever) contain `thing_id`
properties.

Good:

```yml
#> GET /hotels/123
#< HTTP/1.0 200 OK
id: 123
_links:
  self:
    href: /hotels/123
  city:
    href: /cities/456
```


Bad:

```yml
#> GET /hotels/123
#< HTTP/1.0 200 OK
id: 123
city_id: 456
```

### Normalising concepts

Elaborating on the example above, it's not uncommon for an entity to refer to
multiple, similar others. A hotel's record can for instance contain a
`city_id`, `region_id`, and `country_id`.

The naive transformation into an API would be to entities of the `city`,
`region`, and `country` concepts;

One could argue this is a lack of normalisation; and that cities, regions, and
countries are actually entities of a broader `places` concept; hotels would then
relate to a number of places with varied `kind` properties, and which relate to
each other as a tree (or digraph) — but depending on the use case, this might be
cumbersome over-normalisation.


## Documenting APIs

API users are both developers and machines; therefore, you should:

- Discuss APIs _before_ starting any implementation: you're wearing your
  designer hat here.
- Documented in a human-readable format. We recommend
  [Apiary](http://apiary.io/) and the [API Blueprint](http://apiblueprint.org/)
  standard `.apib` files.
  

## Conventions on requests

### Content type negotiation

All requests _should_ include the `Accept: application/json` headers.

Requests _may_ use the `application/json` MIME type instead for backwards
compatibility reasons.

The `Accept` header _may_ include the `v` parameter to specify the API version
requested; see "Versioning" below.

Server _may_ react to the `Accept-Language` header, see "i18n" below.


### Resource lifecycle

All GET requests for a single resource _may_ specify `If-*` headers to avoid
fetching payloads when revelant (thus expecting a possible 304 response).

All PATCH requests _must_ include at least one `If-*` header (either
`If-Unmodified-Since` or `If-Match`) to avoid editing conflicts.


### Path segments

There _should not_ be more than 3 path segments, API root (typically `/`,
`/api`, or `/api/{tenant}`) excluded.

In practice:

- each concept _must_ be exposed as a top level segment, e.g. `/photos{/id}`,
  `/hotels{/id}`, etc)
- resources _should not_ be nested, e.g. `/hotels/{id}/photos/{pid}` is bad)
- there _may_ be a nested index for related entities, e.g.
  `/hotels/{id}/photos`.

As a rule of thumb, there _should not_ be more than one (numeric) identifier per
URL.

### Naming

All path segments which refer to a domain concept _should_ be plurals, except if
there is only zero or one entity in the concept (singleton relations).

Note that relation endpoints _must_ link to a toplevel endpoint.

Example:

```
# Singleton
/manager_profiles/{id}
/users/{id}/manager_profile

# Normal case
/photos/{id}
/hotels/{id}/photos
```

### Parameters

Endpoints returning single entities _should not_ accept any parameters. They
_may_ return an error if parameters are passed.

- Good: `/hotels/{id}`
- Bad: `/hotels/{id}{?fields}`

Collection endpoints _may_ accept parameters (e.g. for filtering). If they do,
those _must_ be specified in the root document's link relations.

Example:

```yml
#> GET /api
#< HTTP/1.0 200 OK
_links:
  hotel:
    href:      "/hotels/{id}"
    templated: true
  hotels:
    href:      "/hotels{?published}"
    templated: true
  hotel_photos:
    href:      "/hotels/{id}/photos{?default}"
    templated: true
```

_Note_: in a root document, the `href` fields will typically be URI templates as
per RFC 6570.


### Security

A service _must_ accept connections over HTTPS. It _should not_ respond over
plain HTTP, and in particular, it _should not_ redirect from HTTP to HTTPS. It
_should_ respond to plain HTTP requests with status 426, Upgrade Required.

A service _should_ require HTTP Basic authentication. It _should_ ignore the
username and use the password as a token. It _may_ accept unauthenticated
requests for some endpoints.

Rationale: why not HTTP Digest?

- Digest has 2x request overhead of the Basic for the first request
  (challenge-response);
- It is not needed with SSL, as (a) the enclosing protocol is encrypted and has
  its own challenge-response mechanism, and (b) refusing connections over HTTP
  reduces the risk of cleartext passwords.

Rationale: why not an `X-Token` header?

- Because that's functionally equivalent to HTTP Basic, which has universal
  support in clients libraries and browser-based testing tools.

Rationale: why not `?token=abcd` in the query string?

- Because that violates REST (the query string is part of the URL)
- Because URLs can leak (at least, to logs)
- Because it's unnecessary (see above)

### Versioning

A service _may_ provide different APIs (endpoints and representations) in the
form of API versions.

Clients _may_ specify a desired version as the `v` parameter of the `Accept`
header, for instance:

```
Accept: application/json;v=2
```

The service _should_ respond with status 406, Not Acceptable if the version is
unavailable.

If a version was specified by the client, and is available, the service _must_
respond with the same version:

```
# Request:
Accept: application/json;v=2

# Response:
Content-Type: application/json;v=2
```

If the version was unspecified, the server _should_ use the latest available
version, and specify the `Vary` header, as future request may yield a different
response:

```
# Request:
Accept: application/json

# Response:
Content-Type: application/json;v=2
Vary: Accept
```

Finally, a service's root endpoint _should_ list the available versions:

```yml
#> GET /api
#< HTTP/1.0 200 OK
_links:
  ...
_versions:
  - 1
  - 2
```

_Note_: Another Approach is to version APIs through path segments (e.g.
`/api/v1/things/123`). We choose not to follow it. The major issue is that
entities may have multiple URLs which risk being misinterpreted as referencing
different entities.

### Internationalisation (i18n)

A service _may_ provide internationalised representations of entities.

A client _may_ specify their desired locale using the `Accept-Language` header
as per [RFC
2616](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4).

If representation is localised, the service _should_ include the
`Content-Language` header in the response.

If the locale requested is not available, the service _should_ respond with
status 406, Not Acceptable.

If the response does not match the requested locale exactly (either more than
one locale options were requested, or none), the service _should_ include the
`Vary: Accept-Language` header in the response.

Rationale:

- Including the locale in the path (e.g. `/api/en/things/123`) suffers from the
  same lack-of-uniqueness issue mentioned in "versioning" above.
- Including the locale in a parameter violates conventions on parameters.
- Localisation is inherently a representation concern, and HTTP mandates such
  concerns to be addressed using protocol headers.


## Conventions on responses

Responses _should_ be valid
[JSON-HAL](https://tools.ietf.org/html/draft-kelly-json-hal) documents.

In addition, embedded entities (using `_embedded`) should be avoided when
possible, and only introduced:

- for collections; or
- for excruciating performance reasons; or
- when the (partial) representation of the embedded entity is immutable with
  respect to the parent.

### Single-resource representation

A single resource representation _should_ have a numeric `id` field.  It _must_
have a link to `self`.  It _may_ contain a number of intrinsic properties of the
entity (see the "domain modelling" discussion above.

Example:

```yml
#> GET /hotels/1234
#< HTTP/1.0 200 OK
id:   1337
name: "The Four Seasons*****"
lat:  1.2345
lng:  45.678
_links:
  self:
    href:   "/hotels/1337"
  reviews:
    href:   "/hotels/1337/reviews"
  manager:
    href:   "/users/8008"
    type:   "user"
  photos:
    href:   "/hotels/1337/photos"
```

Note that intrinsic-ness of a given property is a gray area: think hard and have
a debate whenever considering adding another property to a representation.

There may occasionally be arguments outside the domain, e.g. performance
considerations.  For instance, one may decide to model hotel descriptions
(which are lengthy text blobs) as a relation to hotels, instead of as an
intrinsic field, because (a) the payload would become very large, and (b) it is
seldom needed by consumers.

As a particular case, note that fields that count relations (eg. `photos_count`
in the example above) are _not_ intrinsic and _should not_ be made part of the
representation.

In exceptional cases, counts (which are a property of the relation) _may_ be
mentioned as a part of the link metadata. Consumers should not expect the value
to be authoritative, and should refer to the relation URL if consistency is
required.

Example:

```yml
#> GET /hotels/1234
#< HTTP/1.0 200 OK
id:   1337
_links:
  self:     "/hotels/1337"
  photos:
    href:   "/hotels/1337/photos"
    count:  27
```


### Single-entity GET endpoints

A single-entity GET endpoint _should_ always be of one of the forms

- `/{concept-plural}/{id}` for typical concepts (e.g. `/hotels/1234`);
- `/{concept-singular}` for singletons (e.g. `/exchange_rate`)
- `/{parent}/{id}/{concept-singular}` for singleton relations (e.g.
  `/users/1234/manager_profile`).

Such endpoints _must_ return the representation of a single entity, and any
links, as described in the previous section.

Partial responses (e.g. with `field` query param) _should not_ be returned.

Responses _should_ include a `Last-Modified` or `ETag` header, and _may_ include
both. The ETag should be based on a hash of the response payload, not on
timestamps.


### Collection GET endpoints

A collection GET endpoint _should_ be of one of the forms:

- `/{concept-plural}`, e.g. `/hotels`
- `/{parent}/{id}/{concept-plural}`, e.g. `/hotels/1234/photos`

Such endpoints _must_ return a representation of the collection. They _must_
link to a (possibly empty) list of entities.

_Rationale_:
In domain terms, an index endpoint actually returns a _view_ on the _collection_
of resources; ie. the resource returned is the view.  The current page, links,
and page size are _data_ (intrinsics) of that view. The number of pages and the
total number of resources depend (if your view can filter it's data; if it can
only order it's metadata).

A collection representation

- _should_ link to relations `next` and `prev` for pagination purposes;
- _must_ include the properties `page`, `per_page`, `total`

Example:

```yml
#> GET /hotels?checkin=2016-01-02&checkout=2016-01-09
#< HTTP/1.0 200 OK
page:     1
per_page: 10
total:    153277
_links:
  self:   
    href:   "/hotels?checkin=2016-01-02&checkout=2016-01-09&page=1"
  prev:     null
  next:   
    href:   "/hotels?checkin=2016-01-02&checkout=2016-01-09&page=2"
  hotels:
    - href: "/hotels/1"
    - href: "/hotels/2"
```


Exceptionally, a collection representation, _may_ embedded representations of
the linked resources, which _may_ be incomplete, but _must_ include at least a
the mandatory link to `self`.

Note that as for other use cases of `_embedded`, there should be a very robust
reason to do so as it makes using the API more complex (partial representations,
caching issues, etc).

Example:

```yml
#> GET /hotels?checkin=2016-01-02&checkout=2016-01-09
#< HTTP/1.0 200 OK
page:     1
per_page: 10
total:    153277
_links:
  self:   
    href:   "/hotels?checkin=2016-01-02&checkout=2016-01-09&page=1"
  prev:     null
  next:   
    href:   "/hotels?checkin=2016-01-02&checkout=2016-01-09&page=2"
  hotels:
    - href: "/hotels/1"
    - href: "/hotels/2"
_embedded:
  hotels:
    - id: 1
      _links:
        self: 
          href:   "/hotels/1"
    ...
    - id: 10
      _links:
        self: 
          href:   "/hotels/2"
```


### POST, creating entities

A collection GET endpoint _may_ respond to the POST method to create new entities.

If it exists, it _should_ return status:

- 201 Created if the entity was successfully created, or
- 400 Bad Request if the entity cannot be created with the information in the
  request body.

Additional 4xx response codes _may_ be used:

- 412 Precondition Failed if e.g. the resource wouldn't statisfy some uniqueness
  criterion;
- 415 Unsupported if using versioning and the server doesn't support the
  specified version.
- 429 Too Many Requests if the service throttles requests from an aggressive
  client.

The response _must_ be a valid single resource representation, although it _may_
be partial, including at least the numeric `id` and the mandatory link to self.

Example:

```yml
#> POST /hotels
name: "Castle by the lake"
lat:  1.2345
lng:  45.678
#< HTTP/1.0 201 Created
id: 1337
_links:
  self: "/hotels/1337"
```

### PATCH, mutating entities

A single-resource GET endpoint _may_ respond to the PATCH method to modify
existing entities.

The response status _should_ be

- 200 OK, if the modification succeeded.
- 400 Bad Request, if the modification failed.
- 412 Precondition failed, when failing to honour `If-Match` or
  `If-Unmodified-Since` headers.
- 428 Precondition Required, when the request lack a `If-*` header.
- 415 Unsupported if using versioning and the server doesn't support the
  specified version.

The response _must_ be a valid single resource representation, although it _may_
be partial, including at least the numeric `id` and the mandatory link to self.

Example:

```yml
#> GET /hotels/1337
#< HTTP/1.0 200 OK
#< Last-Modified: Tue, 15 Nov 1994 12:45:26 GMT
#< Etag: "e04c6ca4-6ac9-11e6-ab5a-cf7dd1791cc9"
id:       1337
name:     "Castle by the lake"
_links:
  self:   "/hotels/1337"

#> PATCH /hotels/1337
#> If-Match: "e04c6ca4-6ac9-11e6-ab5a-cf7dd1791cc9
name:     "Manor by the lake"
#< HTTP/1.0 200 OK
id:       1337
name:     "Manor by the lake"
_links:
  self:   "/hotels/1337"
```

### DELETE, destroying entities

A resource GET endpoint _may_ respond to the DELETE method to permanently
destroy an existing entity.

If it exists, it _should_ return status:

- 204 No Content if the entity was successfully destroyed,
- 404 Not Found if the entity does not exist
- 410 Gone if the entity is known to have existed but no longer does.

Additional 4xx response codes _may_ be used:

- 412 Precondition Failed
- 415 Unsupported if using versioning and the server doesn't support the
  specified version.

The response _should_ be empty on success.

Example:

```yml
#> DELETE /hotels/1234
#< HTTP/1.0 204 No Content
```


### Return codes and errors

In the case of client or server errors (i.e. when the return code is 400+), the
content-type _should_ be `application/json`.

The results are not just intended to be acted on by machines, but rather
presented to users.

The response _should_ be an `errors` object whose keys are either keys present
in the original request, parameter names, or the `general` key for failures not
attributable to a request key.

Each value _should_ be a human readable message, localised according to the
`Accept-Language` header.

Example: index with out-of-bounds page:

```yml
#> GET /hotels?page=52196
#< HTTP/1.0 404 Not Found
errors:
  page: "Page is out of bounds"
```

Example of a PATCH version fail:

```yml
#> PATCH /hotels/1337
#> If-Match: "e04c6ca4-6ac9-11e6-ab5a-cf7dd1791cc9"
name:       "Manor by the Lake"
#< HTTP/1.0 412 Precondition failed
errors:
  version:  "Resource was updated since you read it."
```

Example of bad/missing values in POST:

```yml
#> POST /hotels/1337
lat: "foobar"
#< HTTP/1.0 400 Bad Request
errors:
  name:  "Name is required."
  lat:   "Latitude must be a floating-point number."
  lng:   "Latitude is required."
```

Example of bad/missing values in POST:

```yml
#> POST /hotels/1337
name: "Luxury resort"
#< HTTP/1.0 409 Conflict
errors:
  name:  "Name must be unique."
```

HTTP status codes should be used as possible to being semantic where these
guidelines are unclear. In particular, syntactic and semantic failures should
not be confused:

- 400 Bad Request: bad _syntax_ (unknown route, missing required fields or
  parameters, unknown extra parameters, bad field or parameter values).
- 404 Not Found: the specified entity does not exist (unknown routes should not
  404).
- 409 Conflict: PATCH and PUT failures with unique fields.
- 412 Precondition failed: resource versioning issues.

Likewise, for success codes:

- POST and PATCH should never result in a 200 (generally 201, occasionally 202).
- 204 should not be returned.

### Query parameters

Single-entity endpoints _should not_ accept query parameters (for any HTTP
method).

Those endpoints _may_ return 400 Bad Request if parameters are specified.

Collection GET endpoints are the only endpoints that usually accept query
parameters. Those _should_ accept the `page` and `per_page` parameters. They
_may_ accept parameters that match property names of the corresponding concept;
if they do, they _should_

- use the parameter value for filtering purposes (i.e. return entities whose
  corresponding property has the specified value), and
- mention those parameters in the link relation of the root document.

They _may_ accept the _order_ parameter; if they do,

- the accepted values _should_ be comma-separated lists of property names,
  possibly prefixed; and
- they _should_ return entities ordered accordingly.

Example:

```
GET /hotels?page=1&order=-updated_at,name
```

They _may_ also respond to other parameters, although it is not recommended. If
they do those _should_ be mentioned in the root document and the behaviour is
unspecified.


### Caching

Caching efficiency is a critical aim of well-designed APIs, as it is influential on service performance; cache consistency is as important.

These guidelines only consider HTTP/1.1 and later. If the API is internal then you can make this a requirement. External APIs must always use TLS so only direct clients or trusted intermediaries who have our certificates (CDNs, typically) will be able to view the content; all CDNs support 1.1 or later and it's not too much of a stretch to make this assumption for direct clients.

Responses with the following status codes _should_ specify a `Cache-Control` header because without one the HTTP specification allows clients to cache them according to their own cache policy which is typically more lax than desirable:

- `200 OK`
- `203 Non-Authoritative Information`
- `206 Partial Content`
- `300 Multiple Choices`
- `301 Moved Permanently`
- `308 Permanent Redirect`
- `410 Gone`

The following status codes _should_ also specify this header because many CDNs or intermediaries will choose to cache them even though they are not permitted to do so by the HTTP specification:

- `302 Moved Temporarily`
- `307 Temporary Redirect`
- `404 Not Found`

Other status codes _should not_ specify a `Cache-Control` header

The HTTP `Cache-Control` header is somewhat confusing and some of the directives do not mean what you think they do. A basic summary of the confusing ones is:

- `no-store` means that the response is very sensitive data which absolutely _must not_ be written to any kind of storage or to any type of cache either private or public.
- `no-cache` means that the response may be cached (!) but _must not_ be used to satisfy any kind of request without revalidating it. Before using the cached data you _must_ check the endpoint with either the `If-None-Match` or `If-Modified-Since` and can only use it if you get `304 Not Modified`.
- `must-revalidate` means that the response may be cached and may be used without revalidation (!) but may not be used beyond when it expires. If the cached data has passed the expiry, e.g. `max-age` was `3600` and you got the data over an hour ago, then you must check the endpoint with either the `If-None-Match` or `If-Modified-Since` and can only use it if you get `304 Not Modified`.
- If none of the above directives are present then clients may cache the response and continue to use the data past the expiration time at their own discretion.

For full details, and information about the other directives such as `public`, `private` and `max-age`, refer to [RFC 7234 § 5.2](https://tools.ietf.org/html/rfc7234#section-5.2).

Most of the time it is fine for clients to cache data and it's often acceptable for the data to be at least somewhat stale (even if it's just a minute or two) but rarely fine to use them after the expiration time, so in general your `Cache-Control` header should be:

```
Cache-Control: private, max-age={seconds}, must-revalidate
```

If the resource is immutable then `{seconds}` should be `31536000` which is one year, the maximum allowed. Statuses `301`, `308` and `410` should be considered immutable as they are permanent conditions.

For resources that absolutely must be up-to-date when used you still normally want to allow the efficient return of `304 Not Modified` so choose `no-cache` (note that this is typically the best choice for the `302`, `307` and `404` status codes mentione above):

```
Cache-Control: private, no-cache
```

In the rare cases where data is extremely sensitive and must never be cached anywhere (for example, a password reset token) then use:

```
Cache-Control: no-store
```

Remember that because `no-store` prevents any kind of caching that clients cannot use conditional directives to get `304 Not Modified` because they are not permitted to store the data between requests, so have no reference for the unmodified resource.

Responses _should_ include an `ETag` header with a strong ETag; if this is not practical then they _should_ include a `Last-Modified` header (ideally, include both). Strong ETags _must_ be based on a hash of the response, not on timestamp information. Do not use [weak ETags](https://tools.ietf.org/html/rfc7232#section-2.1) because they have confusing semantics, for example they cannot legally be used in preconditions on `PUT`, `PATCH` or `DELETE` requests.

Any `GET` requests _may_ use either `If-None-Match` or `If-Modified-Since`, and all `PUT`/`PATCH`/`DELETE` requests _should_ use either `If-Match` or `If-Unmodified-Since`. If the request provided a strong ETag then the "match" headers are better, otherwise use the "modified" headers.

### Mutable resources

Single-entity endpoints _should_ return an `Etag` header and a `Last-Modified`
header.

They _should_ accept `If-None-Match` and `If-Modified-Since` and return status
304 (and no payload) as appropriate.

Mutation endpoints _should_ honour the `If-Match` and `If-Unmodified-Since`
headers as appropriate.


### Compression

Servers _may_ support the `Accept-Encoding` header for compression purposes, but
this is not mandatory.

*Rationale*: latency is more important than bandwidth savings for most internal
APIs; therefore the overhead of compression is seldom justified.


{: #external-facing}
## External-facing APIs


We want to do our best to make out internal services use HATEOAS and we can try
and catch any URL construction in PRs, but for anything exposed to third-party
API consumers (integrators, developers in the general public) — it's unlikely
that everyone will stick to these ideals.

Performance constraints can also be quite different.

### Mobile-friendly APIs

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


### Public-friendly APIs

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


## Tools of the trade

We strongly recommend using Rails 5 to build API services, as per the [service guidelines](http://deliveroo.engineering/guidelines/services/).
Rails's [API-only mode](http://edgeguides.rubyonrails.org/api_app.html) has
solid support for API building.

If the API service also has a user interface, it is suggested to make the API
part a mounted [Rails engine](http://guides.rubyonrails.org/engines.html) using
API mode.

Using Sinatra is _not_ recommended as there is no significante performance
benefit over Rails, it lacks a router (which means all link URLs must be
manually built), and most non-trivial Sinatra apps end up reinventing MVC.

Using Grape is _not_ recommended as it lacks a router as well.

## Further reading

### Principles

  - [RESTful API design](http://restful-api-design.readthedocs.org/)
  - [Representation state transfer on Wikipedia](http://en.wikipedia.org/wiki/Representational_state_transfer)
  - [HATEOAS on Wikipedia](http://en.wikipedia.org/wiki/HATEOAS)

### Examples of decently well-thought-out APIs and guidelines

  - [GoCardless API design](https://github.com/gocardless/http-api-design)
  - [GitHub API design](https://developer.github.com)

### Context and debate

  - [Your API Versioning is Wrong](http://www.troyhunt.com/2014/02/your-api-versioning-is-wrong-which-is.html)
  - [The Hypermedia Debate](http://www.foxycart.com/blog/the-hypermedia-debate)
  - [Does a standard JSON REST API violate HATEOAS?](http://stackoverflow.com/questions/9055197/splitting-hairs-with-rest-does-a-standard-json-rest-api-violate-hateoas)
  - [Building Hypermedia APIs in Ruby/Rails](https://product.reverb.com/hal-siren-rabl-roar-garner-building-hypermedia-apis-in-ruby-rails-ad73f36fbd84)

### More on JSON APIs

  - [JSON-HAL Draft Spec](http://tools.ietf.org/html/draft-kelly-json-hal)
  - [Rest and Hypermedia APIs](http://alphahydrae.com/2013/06/rest-and-hypermedia-apis/)
  - [The JSON-API spec](http://jsonapi.org)
