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

### An introductory example

Before we dig into some theory and principles, here's a simplified example of a
"federation of services" used to build a simple e-commerce application.

We could build this with 1 front-end application and 3 services:

- `users-srv` is responsible for users and authentication. Its API allows for
  user account creation and update, to create session tokens, and verify the
  validity of session tokens. Its domain concepts are `User` and `Session`.

- `payment-srv` is responsible for payments and accounting. It provides an
  abstracted interface to place orders and pay for them. Its concepts are
  `Order` and `Payment`. `User` is also exposed within this "bounded context" —
  the service cares about a user's balance, but not about its session.

- `inventory-srv` is responsible for managing catalog and stock, and schedule
  deliveries via a 3rd-party API. Its concepts are also `Order` (bounded to what
  an order contains, but not the price, for instance), `Item` (things that can
  be ordered, and their stock levels), and `User` (so an order can be tracked,
  for instance).

Each of these would be an entirely separate application, with its own
repository, database, monitoring, and API. The front-end application, during a
typical checkout, would probably perform a sequence of API calls that look like
this:

{: .table.table-sm}

| Step                                    | HTTP request                                      | Payload |
|-----------------------------------------|---------------------------------------------------|---------|
| Get details and stock level for an item | `GET inventory-srv.example.com/items/1234`        |
| Sign in                                 | `POST users-srv.example.com/sessions`             | user ID, password. return session token and link to user |
| Get user's name and default address     | `GET users-srv.example.com/users/123`             |
| Place the order to lock inventory       | `POST inventory-srv.example.com/users/123/orders` | list of items IDs |
| Pay for the order                       | `POST payment-srv.example.com/users/123/orders`   | total price, payment token |
| Confirm the order if payment suceeded   | `PATCH inventory-srv.example.com/orders/1337`     | status: confirmed |

Note that this is vastly simplified — and many questions are pending; we'll
clarify in further sections.
For instance:

- Which service "owns" each entity (e.g. orders)?
- Will the inventory service really just accept a PATCH on confirmation or would
  it want proof that the order has been paid for?
- How does this align with events? E.g. `order created` would come from the
  inventory, but would the order service also emit an `order updated` event for
  when it's paid?

-----------

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
only address a few domain concepts and be **very** resistant to adding
more.

A service may, in fact, be large in terms of lines of code but it should always
adhere to the principle of limiting the number of domain concepts it operates
on.

We voluntarily don't use the term "micro-service" as it tends to refer to
single-function RPC services, whereas we favour services responsible for a
handful of concepts.

Rule of thumb: you should be able to count the nouns in a service's API on one
hand.

Rationale: if left unchecked, services degenerate into monoliths; this is
natural as  "just adding code" to any codebase  is the immediate shortest path
to shipping new functionnality (a local maximum in terms of team velocity, if
you will). One key goal of service architectures is to allow scaling not just
the infrastructure, but the _team_ working on a set of pieces of software.



----------------------

### Principles / philosophy

The overarching principles in service design are:

- **Cohesion**: a service is sole responsible for clearly defined functions on
  the domain, and for clearly defined sets of entities in the domain (a.k.a
  compactness, autonomy).
- **Abstraction**: a service's implementation details are entirely hidden behind
  its interface, including non-functionals (the fact a particular service uses
  Redis, or its autoscaling behaviour, should not be visible at all for the
  consumer).
- **UNIX philosophy**:
  - A service should be small. Small is beautiful.
  - Make each service do one thing well.
  - Build a prototype as soon as possible.
  - The "scope" for a service should be defined in the README, once and for all.

Here are sanity check questions to check against these pillars:

- Could I write an unambiguous tweet to describe this service?
- If my service is actually implemented with people typing quickly and paper
  storage instead of framework X and database Y, would the interface (API) still
  make sense?
- Can I split my service in two and have an interface that's still as simple?


#### Twelve Factor App

We adopt the principles outlined in the [12 Factor App](http://12factor.net/) to
build good services. As a summary:

1. Codebase: One codebase per service, tracked in revision control, many deploys
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
- DELETE requests should only suceed if the resource exists.
- URL terms in any API should reflect domain concepts.
- Hypermedia links should be provided in responses.

#### Representational State Notification

Or in other words, **push > poll**.

{: .dg-sidebar}

> ###### Why no payloads in events?
>
> Events should not include an entity representation because that places
> enormous constraints on the bus infrastructure: in terms of data,
> full representations are several orders of magnitude larger than events.
>
> A typical use cases for payloads is when intermediary states of an entity
> matter; they may be "missed" if the consumer has to query for the
> representation.
>
> In terms of domain modeling, this is usually a mistake: if a consumer cares
> about state changes for a given entity (and not just about its latest
> representation), this means the state changes are part of the domain, and
> should themselves be entities.
>
> Consider assigning a rider to an order: we could "just" model this as a
> relation from order to rider; but because we care about _when_ and _where_ the
> assignment happened (as well as about _un_assignments), we model them as a
> top-level concept.

When services need to coordinate or synchronise state information about domain
entities (normally flowing out of the service that has authority on that part
of the domain), this should be achieved in an event-driven manner.

An event can simply be defined as:

- The identity of the entity whose state changed (i.e. its authoritative URL)
- The type of state change, one of *created*, *updated*, *deleted*.

An event should generally *not* have a "payload", i.e. a representation of the
entity; that should be queried with an explicit HTTP GET request.

Consumer services should register with the authoritative service to receive
those events. This should be achieved through an event bus.

Local knowledge should be limited: authoritative services should not know about
their consumers (they never reference consumer DNS names).
Generally, services shouldn't know most other services unless necessary.

Consumer services know about source services through configuration (i.e. through
the environment): no server names or URLs in a service's codebase

**EXAMPLE:** In the monolith, if an order changes, we should publish an event
via [routemaster](https://github.com/mezis/routemaster/) for the appropriate
topic. A future "Order Search Service" could be a consumer of that event so that
it can shove the data into ElasticSearch and offer a fast search UX.

------------------------

### API design basics

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


