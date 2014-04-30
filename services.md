
# Building services

[What's a service?](#whats-a-service) |
[Principles / philosophy](#principles--philosophy) |
[Defining a service](#defining-a-service) | 
[Preferred technology stack](#preferred-technology-stack) |
[Configuration](#service-configuration)

We strive towards a service-oriented, event-driven architecture.

This guide intends to pave the road and help readers make good architecture and
design decisions when building services.

--------------------------------------------------------------------------------

### What's a service?


A service is a software entity that can be defined as a function of what third
parties it interacts with, which domain concepts it operates on, and how it
transforms them.

Domain concepts typically map to classes (bookings, users), and domain entities
to instances (a given booking, a given user).

A service may have authority on some or all of the state of a set of entities of
the domain, and then usually exposes a representation of said entities to third
parties.

A service may be responsible for transformations of entity representations or
manipulation of their state.

A service communicates with others by exchanging state information about
entities.


--------------------------------------------------------------------------------

### Principles / philosophy

The overarching principles in service design are:

- **Cohesion**: a service is sole responsible for clearly defined functions on
  the domain, and for clearly defined sets of entities in the domain (a.k.a
  compactness, autonomy).
- **Abstraction**: a service's implementation details are entirely hidden behind its
  interface, including non-functionals (ie. scalability of a service, or lack
  thereof, is not the consumer's concern).

#### Twelve Factor App

We adopt the principles outlined in the [12 Factor App](http://12factor.net/) to
build good services. As a summary:

1. Codebase: One codebase tracked in revision control, many deploys
2. Dependencies: Explicitly declare and isolate dependencies
3. Config: Store config in the environment
4. Backing Services: Treat backing services as attached resources
5. Build, release, run: Strictly separate build and run stages
6. Processes: Execute the app as one or more stateless processes
7. Port binding: Export services via port binding
8. Concurrency: Scale out via the process model
9. Disposability: Maximize robustness with fast startup and graceful shutdown
10. Dev/prod parity: Keep development, staging, and production as similar as possible
11. Logs: Treat logs as event streams
12. Admin processes: Run admin/management tasks as one-off processes


#### REST over HTTP

Services must only ever communicate with the rest of the world (other services
or end users) over an HTTP interface, respecting REST principles.

In particular (but not limited to):

- HTTP verbs should be used.
- GET requests should be idempotent and cacheable.
- URL terms in any API should reflect domain concepts.
- Hypermedia links should be provided in responses.


#### Representational State Notification

Or in other words, **ask, don't tell**.

When services need to coordinate or synchronize state information about domain
entities (normally flowing out of the service that has authority on that part
of the domain), this should be achieved in an event-driven manner.

An event can simply be defined as:

- The identity of the entity whose state changed (ie. its authoritative URL)
- The type of state change, one of *created*, *updated*, *deleted*.

An event should *not* have a "payload", ie. a representation of the entity.

Note that an event itself is an entity, one that is typically only ever created
over HTTP.

Consumer services should register with the authoritative service to receive
those events. Ideally, this should be achieved through an event bus.

Local knowledge should be limited: authoritative services should not know about
their consumers (they never reference to consumer DNS names).
Generally, services shouldn't know most other services unless necessary.

Consumer services know about source services through configuration (i.e. through the environment): no server names or URLs in a service's codebase


#### API design basics

Again because of the local knowledge criterion, services should have minimal
knowledge of any service's API they consume.  This can be achieved through good
use of hypermedia links.

For instance, imagining a resource (API term for domain concept) named
`bookings` that references a resource named `property`, you'd want this type of
API:

    >> GET /api/bookings/123
    << {
    <<   url: 'https://bookings.example.com/api/bookings/123', 
    <<   property_url: 'https://monolith.example.com/api/properties/456'
    << }

which lets you

- not rely on IDs (which are an internal implementation detail of our service);
- not need to know how the URL for a property entity is constructed.

_Sidebar: why is this important?_
Imagine a service that consumes bookings to aggregate statistics. Ideally, it
does so by listening to the event bus for booking lifecycle events. If using
hypermedia links as in the above, it only ever needs to know about the bus's
location, as it will dynamically obtain addresses for the entities it needs to
know about. If not, it needs to know both (a) who is authoritative for bookings
and properties, (b) where the authority resides for each resource, and (c) how
the various authorities constructs URLs for entities of interest. This would
breach the local knowledge requirement and tighly couple the service
architecture.


#### Typical dont's

- Remote procedure call, e.g. APIs like `GET /api/bookings/123/cancel`. This
  must be replaced with state transfer (`PATCH
  /api/bookings/123?state=cancelled`) or
  higher-level concepts (`POST /api/bookings/123/cancellation`).
  <br/>
  _Smell_: the API contains verbs (typically actions/calls) instead of nouns
  (typically concepts/resources).

- Sharing a database layer. If two "services" communicate through Mongo,
  RabbitMQ, etc, they're actually one single service. They must communicate over
  HTTP, and there are no exceptions.

--------------------------------------------------------------------------------

### Defining a service

TODO

- use cases
- authoritative on which concepts
- responsible for which function
- API
- Events
- Arch diagram

all part of the README besides the usual sections (getting started, installing,
running, debugging, contributing)

example of the search service


--------------------------------------------------------------------------------

### Preferred technology stack

Because a zoo of technologies leads to disaster, we purposedly limit the set of
technologies we use.

From top to bottom of the production stack:

| Concern                 | Technology                          |
|-------------------------|-------------------------------------|
| Styling                 | Sass + Compass + Bootstrap 3+       |
| Front-end logic         | Coffeescript + Backbone.JS          |
| Serving HTTP            | Unicorn                             |
| Responding to requests  | Rails 4                             |
| Querying HTTP           | Faraday                             |
| Logic                   | Ruby 2.1+                           |
| Persisting data         | ActiveRecord/MySQL                  |
| Caching data            | Memcache                            |
| Background processing   | Resque+Redis                        |
| Hosting                 | Heroku                              |

In development:

| Concern                 | Technology                          |
|-------------------------|-------------------------------------|
| Unit/integration testing| RSpec 2                             |
| Acceptance testing      | Rspec + Capybara + PhantomJS        |

Alternatives should only be considered when there's a legitimate reason to
(which does not, ever, include "I want to play with it"). Using an alternative
should convince a majority amongst the team's technical leadership.

| Concern                 | Alternative technologies            |
|-------------------------|-------------------------------------|
| Styling                 | *none*                              |
| Front-end logic         | *none*                              |
| Serving HTTP            | Rainbows                            |
| Responding to requests  | Sinatra                             |
| Querying HTTP           | *none*                              |
| Logic                   | *none*                              |
| Persisting data         | Mongo, Redis                        |
| Caching data            | Redis                               |
| Background processing   | DJ (monorail only)                  |
| Hosting                 | Amazon EC2                          |


#### Introducing new technologies

Adding a technology to the lists above can only be done by a consensus of the
technical leads, with veto from the lead of engineering.

To put it simply, the philosophy is:

- Ruby is core. If it can be done it Ruby with reasonable performance, it
  should.
- Introducing _any_ new technology in the stack must be (a) justified by use
  cases that cannot be covered by the existing stack, and (b) at least half
  the team must be trained with the new technology before it reaches
  production.

Excellent case reflecting our thought process (by @eparreno):

> A couple of friends of mine are working at GitHub, and they told me that they
> chose to use MRI across all the apps instead of having some of them using
> JRuby and some others using MRI. They prefer to pay the price of MRI "low
> performance" rather than maintaining different stacks.



#### Other technical requirements

- JSON default, Gziped JSON and MessagePack optional seconds.
- SSL only, reject non-SSL
- HTTP Basic authentication, token authentication only when dealing with
  non-HouseTrip 3rd party that requires it

--------------------------------------------------------------------------------

### Extracting a feature into a service

Imagine a tightly-coupled feature currently living in a monolithic application,
which you'd like to extract into a service.

For instance, a search engine: that is, for a holiday rental website, a function
that conceptually maps

    search := (properties, availability, pricing, parameters) -> (properties, prices)

The following series of steps is the (strongly) recommended way to perform the
extraction.

1. Define the domain concepts, and who has authority on them (here, the
   monolithic application would retain authority on properties, availaiblity,
   and pricing).
2. Define the API of the service (as a RESTful HTTP API).
3. Define a client interface, with a Ruby API that closely matches the service's API (this can be done
   before implementing the service).
4. Implement the client interface in terms of the original implementation of the
   feature (thus making it a _facade_)
5. Change all existing use cases of the feature to use the client.
6. Implement the service.
7. Modify the client to use the service instead of the original implementation.
8. Remove the original implementation.

The key idea here is to implement a client facade. In our experience, for any
significant feature, any other approach is highly likely to fail or take
significantly more resource overall.

Step 6 (service implementation) can be started in parallel just after step 2
(API), although it may be prudent to consider the API might suffer iteration
while working on the facade.

Step 7 (service client) can likewise be started earlier, although prudence is
advised for similar reasons.


### Service configuration

As per the 12factor principles, configuration lives in the environment.

This means that while Yaml file may exist in the repo, they should be about
data. Therefore it is a smell this to have enviroment names mentioned in such files.

For Ruby apps the `dotenv` gem must be used, as it reproduces the runtime behaviour of Heroku.

- There should be one general `.env` file for settings shared across environments,
  and one `.env.<name>` file per environment where these should be overridden.
- Settings **should not** be copied between files if the values are identical.
- The `.env` file should have sensible settings that "just work" in development.
- Settings should be prefixed with the service name.

Setttings should also be clearly commented

Example:

    # .env
    # base URL for the upstream service
    MYAPP_UPSTREAM_SERVICE=https://geonames.org/
    # timeout for requests
    MYAPP_TIMEOUT=10

    # .env.staging
    # be less tolerant than the default to mimic production
    MYAPP_TIMEOUT=5


