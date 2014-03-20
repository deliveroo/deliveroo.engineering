
# Building services

We strive towards a service-oriented, event-driven architecture.

This guide intends to pave the road and help readers make good architecture and
design decisions when building services.

--------------------------------------------------------------------------------

### What's a service?


A service is a software entity that can be defined as a function of what third
parties it interacts with, which domain concepts it operates on, and how it
transforms
them.

Domain concepts typically map to classes (bookings, users), and domain entities
to instances (a given booking, a given user).

A service may have authority on some or all of the state of a set of entities of
the domain, and then usually exposes a representation of said entities to third
parties.

A service may be responsible for transformations of entity representations or
manipulatino of their state.

A service communicates with others by exchanging state information about
entities.


--------------------------------------------------------------------------------

### Principles / philosophy

The overarching principles in service design are:

- Compactness: a service is sole responsible for clearly defined functions on
  the domain, and for clearly defined sets of entities in the domain.
- Abstraction: a service's implementation details are entirely hidden behind its
  interface, including non-functionals (ie. scability of a service, or lack
  thereos, is not the consumer's concern).

#### 12 Factor App

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

Services only ever communicate with the rest of the world (other services or end
users) over and HTTP interface, respecting REST principles.

In particular (but not limited to):

- HTTP verbs should be used.
- GET requests should be idempotent and cacheable.
- URL terms in any API should reflect domain concepts.
- Hypermedia should be used whenever a response

representational state notification / event-driven

Local knowledge should be limited.
services shouldn't know most other services
typically, only the service that has authority on the concepts they need to
manipulate
or even just where the bus of events is located

this is achieved through configuration (i.e. through the environment)
no server names or URLs in a service's codebase

also achieve through good use of hypermedia links 
example -- GET booking, hypermedia to property

Typical dont's

- Remote procedure call, e.g. APIs like `GET /api/bookings/123/cancel`. This
  must be replaced with state transfer (`PATCH
  /api/bookings/123?state=cancelled`) or
  higher-level concepts (`POST /api/bookings/123/cancellation`).
- Sharing a database layer. If two "services" communicate through Mongo,
  RabbitMQ, etc, they're actually one single service. They must communicate over
  HTTP, and there are no exceptions.

--------------------------------------------------------------------------------

### Defining a service

--------------------------------------------------------------------------------

### Prefered technology stack

Because a zoo of technologies leads to disaster, we purpusedly limit the set of
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
| Hosting                 | Amazon EC2                          |

Adding a technology to the lists above can only be done by a consensus of the
technical leads, with veto from the lead of engineering.


--------------------------------------------------------------------------------

### Extracting a feature into a service

