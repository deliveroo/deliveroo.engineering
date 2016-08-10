---
title:      "HTTP services"
---


# Building mini-services

We strive towards a service-oriented, event-driven architecture. This guide
intends to pave the road and help readers make good architecture and design
decisions when building services.


- [What's a service?](#whats-a-service)
- [Principles / philosophy](#principles--philosophy)
- [Preferred technology stack](#preferred-technology-stack)
- [Configuration](#service-configuration)
- [Continuous Deployment](#continuous-deployment)
- [Logging](#logging)
- [Monitoring](#monitoring)
- [Backups](#backups)
- [Seeding a service](#seeding-a-service)
- [Defining a service](#defining-a-service)
- [Extracting a feature into a service](#extracting-a-feature-into-a-service)

----------------------

### What's a service?


A service is a software entity that can be defined as a function of what third
parties it interacts with, which domain concepts it operates on, and how it
transforms them via domain entities.

Domain concepts typically map to classes (bookings, users), and domain entities
to instances (a given booking, a given user).

A service may have authority on some or all of the state of a set of entities of
the domain, and then usually exposes a representation of said entities to third
parties.

A service may be responsible for transformations of entity representations or
manipulation of their state.

A service communicates with others by exchanging state information about
entities.

#### What is a **mini** service?

The **mini** in mini service applies to the number of domain concepts a service
operates on. All services should endeavour to be small _in scope_, i.e. should
only address one (or two) domain concepts and be **very** resistant to adding
more.

A service may, in fact, be large in terms of lines of code but it should always
adhere to the principle of limiting the number of domain concepts it operates
on.

We voluntarily don't use the term "micro-service" as it tends to refer to
single-function RPC services, whereas we favour single-noun services.

----------------------

### Principles / philosophy

The overarching principles in service design are:

- **Cohesion**: a service is sole responsible for clearly defined functions on
  the domain, and for clearly defined sets of entities in the domain (a.k.a
  compactness, autonomy).
- **Abstraction**: a service's implementation details are entirely hidden behind
  its interface, including non-functionals (ie. scalability of a service, or
  lack thereof, is not the consumer's concern).
- **UNIX philosophy**:
  - A service should be small. Small is beautiful.
  - Make each service do one thing well.
  - Build a prototype as soon as possible.
  - The "scope" for a service should be defined in the README, once and for all.

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
9. Disposability: Maximise robustness with fast startup and graceful shutdown
10. Dev/prod parity: Keep development, staging, and production as similar as possible
11. Logs: Treat logs as event streams
12. Admin processes: Run admin/management tasks as one-off processes

#### REST over HTTP

Services must only ever communicate with the rest of the world (other services
or end users) over an HTTP interface, respecting REST principles.

In particular (but not limited to):

- HTTP verbs should be used.
- GET requests should have no side-effects (on any entity of this concept or
  others) and be cacheable.
- PUT and PATCH requests should be idempotent (submitting them more than once
  should not change state further)
- URL terms in any API should reflect domain concepts.
- Hypermedia links should be provided in responses.

#### Representational State Notification

Or in other words, **ask, don't tell**.

When services need to coordinate or synchronise state information about domain
entities (normally flowing out of the service that has authority on that part
of the domain), this should be achieved in an event-driven manner.

An event can simply be defined as:

- The identity of the entity whose state changed (i.e. its authoritative URL)
- The type of state change, one of *created*, *updated*, *deleted*.

An event should *not* have a "payload", i.e. a representation of the entity.

Note that an event itself is an entity, one that is typically only ever created
over HTTP.

Consumer services should register with the authoritative service to receive
those events. Ideally, this should be achieved through an event bus.

Local knowledge should be limited: authoritative services should not know about
their consumers (they never reference to consumer DNS names).
Generally, services shouldn't know most other services unless necessary.

Consumer services know about source services through configuration (i.e. through
the environment): no server names or URLs in a service's codebase

**EXAMPLE:** In the monorail if an order changes we publish an event via
[RouteMaster](https://github.com/mezis/routemaster/) for the appropriate
Topic. A future Order Search Service cound be a consumer of that event so that
it can shoeve the data into ElasticSearch and offer a fast search UX.

------------------------

### API design basic

----------------------

### Service configuration

----------

### Continuous Deployment

----------

### Logging

--------

### Monitoring

---------

### Backups

--------------

### Seeding a service

--------

### Defining a service

--------

### Extracting a feature into a service


