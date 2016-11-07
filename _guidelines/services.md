---
layout:     guidelines
title:      "Building mini-services"
subtitle:   "Designing for a service-oriented, event-driven architecture"
collection: guidelines
---

We strive towards a service-oriented, event-driven architecture. This guide
intends to pave the road and help readers make good architecture and design
decisions when building services.

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}


## An introductory example

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


## What's a service?


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

### What is a _mini_ service?

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
to shipping new functionality (a local maximum in terms of team velocity, if
you will). One key goal of service architectures is to allow scaling not just
the infrastructure, but the _team_ working on a set of pieces of software.


## Principles / philosophy

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


### Twelve Factor App

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

### REST over HTTP

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

### Representational State Notification

Or in other words, **push > poll**.

<aside>
#### Why no payloads in events?

Events should not include an entity representation because that places
enormous constraints on the bus infrastructure: in terms of data,
full representations are several orders of magnitude larger than events.

A typical use cases for payloads is when intermediary states of an entity
matter; they may be "missed" if the consumer has to query for the
representation.

In terms of domain modeling, this is usually a mistake: if a consumer cares
about state changes for a given entity (and not just about its latest
representation), this means the state changes are part of the domain, and
should themselves be entities.

Consider assigning a rider to an order: we could "just" model this as a
relation from order to rider; but because we care about _when_ and _where_ the
assignment happened (as well as about _un_-assignments), we model them as a
top-level concept.
</aside>

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


## API design basics

Again because of the local knowledge criterion, services should have minimal
knowledge of any service's API they consume.  This can be achieved through good
use of hypermedia links.

<aside>
### Why is this important?

Imagine a service that consumes bookings to aggregate statistics. Ideally, it
does so by listening to the event bus for booking lifecycle events. If using
hypermedia links as in the above, it only ever needs to know about the bus's
location, as it will dynamically obtain addresses for the entities it needs to
know about. If not, it needs to know both (a) who is authoritative for bookings
and properties, (b) where the authority resides for each resource, and (c) how
the various authorities constructs URLs for entities of interest. This would
breach the local knowledge requirement and tightly couple the service
architecture.
</aside>


For instance, imagining a resource (the API term matching "domain concept")
named `bookings` that references a resource named `hotel`, you'd want this
type of API:

```json
// GET /api/bookings/123
{
  "id": "123",
  "_links": {
    "self": {
      "href": "https://bookings.example.com/api/bookings/123"
    },
    "hotel": {
      "href": "https://monolith.example.com/api/hotels/456"
    }
  }
}
```

which lets you

- not rely on IDs (which are an internal implementation detail of our service);
- not need to know how the URL for a property entity is constructed.

### Ruby clients

It is not considered good practice to provide a dedicated Ruby client to
consume a particular internal API, e.g a `payment-srv-client` Ruby gem. This
would be a smell that the API is non-standard.

We may however provide (or extend) a generic library to abstract out traversal
of hypermedia links, caching, and authentication in the future.


### Typical dont's

- Remote procedure call, e.g. APIs like `GET /api/bookings/123/cancel`. This
  must be replaced with state transfer (`PATCH
  /api/bookings/123?state=cancelled`) or higher-level concepts (`POST
  /api/bookings/123/cancellation`).
  <br/>
  _Smell_: the API contains verbs (typically actions/calls) instead of nouns
  (typically concepts/resources).

- Sharing a database layer. If two "services" communicate through Mongo,
  RabbitMQ, etc—or even just connect to the same shared datastore—they're
  actually one single service. They must communicate over HTTP, exclusively, and
  there are no exceptions.
  <br/>
  _Smell_: one service connects to another service's database.


### Further reading

API design has its specific set of guidelines, outlined in the [Designing
APIs](../guides/) document.

## Preferred technology stack 


<aside>
### Does this feel restrictive?

Our experience tells us that, under pressure or temptation, new technologies
can be introduced that result in hard-to-maintain software.

If that's unconvincing, Dan McKinley of Stripe and Etsy fame sums it up well
in [Choose Boring Technology](http://mcfunley.com/choose-boring-technology)
([slides](http://mcfunley.com/choose-boring-technology-slides)).

New technologies can still most definitely be experimented with and introduced
in production, though—only, with due care!

The next section outlines our approach to doing so.
</aside>

Because a zoo of technologies leads to disaster, we purposely limit the set of
technologies we use.

_Reminder_: this applies to new services/apps, and signficant changes to
existing ones. Some existing services/apps might not be aligned to this at time
of writing.

We include front-end technologies here, as it's likely that some services (≈ app
exposing or consuming an internal API) also have a user interface.

From top to bottom of the production stack:

| Concern                 | Technology                          |
|-------------------------|-------------------------------------|
| Style & Layout          | SCSS + Bootstrap                    |
| Front-end logic         | Rails (UJS + JQuery)    	          |
| Caching HTTP						| Fastly CDN													|
| Serving HTTP            | Puma                                |
| Responding to requests  | Rails 5                             |
| Querying HTTP           | Faraday                             |
| Logic                   | Ruby                                |
| Persisting data         | ActiveRecord/PostgreSQL; Redis      |
| Caching data            | Redis                               |
| Background processing   | Sidekiq[^sidekiq]                   |
| Hosting                 | Heroku                              |
| Logging                 | Papertrail                          |

**NOTE:** You should aim to use the latest, stable versions of the above.

[^sidekiq]: Sidekiq should be used directly, not through ActiveJob. The latter hides the job engine behind a simplistic abstraction, which prevents access to advanced features, e.g. exclusive/loner jobs or automated retries with backoff.

In development:

| Concern                 | Technology                          |
|-------------------------|-------------------------------------|
| Unit/integration testing| RSpec                               |
| Acceptance testing      | RSpec + Capybara + PhantomJS        |

Alternatives should only be considered when there's a legitimate reason to
(which does not, ever, include "I want to play with it"). Using an alternative
should convince a majority amongst the team's technical leadership.

These alternatives are (currently) deemed acceptable in some use cases, where
the technology in the table above does not fit the bill (e.g. on reliability or
performance grounds).

| Concern                 | Alternative technologies            |
|-------------------------|-------------------------------------|
| Style & Layout          | *none*                              |
| Front-end logic         | React JS                            |
| Serving HTTP            | *none*                              |
| Caching HTTP						| *none*    													|
| Responding to requests  | *none*[^sinatra]                    |
| Querying HTTP           | *none*                              |
| Logic                   | *none*                              |
| Persisting data         | ElasticSearch                 			|
| Caching data            | *none*                              |
| Background processing   | Resque                  						|
| Hosting                 | *none*                          		|

[^sinatra]: We do not consider Sinatra any more. With a Rails 5 app in API mode, latency is comparable to Sinatra; and this avoids having an extra brick in the stack. It's also well established that Sinatra apps tend to grow to mimic Rails's MVC.

### Introducing new technologies

Adding a technology to the lists above can only be done by a consensus (beyond
the immediate engineers wishing to introduce it), and with a rationale.

To put it simply, the philosophy is:

- Ruby is core. If it can be done it Ruby with reasonable performance, it
  should.
- Introducing _any_ new technology in the stack must be (a) justified by use
  cases that cannot be covered by the existing stack, and (b) a sufficient part
  of the team should be trained with the new technology before it reaches
  production, so that maintenance can be ensured.

Excellent case reflecting our thought process:

> A couple of friends of mine are working at GitHub, and they told me that they
> chose to use MRI across all the apps instead of having some of them using
> JRuby and some others using MRI. They prefer to pay the price of MRI "low
> performance" rather than maintaining different stacks.


## Service configuration

As per the 12factor principles, configuration lives in the environment.  This
means that while Yaml files may exist in the repo, they should be about data.
Therefore it is a smell to have environment names ("staging", "production")
*anywhere* in a repository.

For Ruby apps the `dotenv` gem should be used, as it reproduces the runtime
behaviour of Heroku. The `.env` file should have sensible settings that "just
work" in development, and can be used as an example list of settings for
deployments. A `.env.development` file should be supported for local overrides.

Settings should be clearly commented (in `.env`).

Example:

```
# .env
# base URL for the upstream service
MYAPP_UPSTREAM_SERVICE=https://geonames.org/
# timeout for requests
MYAPP_TIMEOUT=10
```

Remarks:

- Providing `.env.example` is an antipattern as all sensible defaults for
  development should be in `.env`.
- `.env` is committed to the repo and should _not_ be in `.gitignore`.
- Use `dotenv-rails` as this gem automatically loads `.env.[RAILS_ENV]`,
  to support `.env.development` overrides.
- If you are not using Heroku, you can use [renv](https://github.com/mezis/renv)
  to store configuration in a similar style.


### Static v dynamic configuration

Note that:

1. The environment is limited to 16kB on Heroku. If it fills up, and there's an
   emergency that, say, requires we change a database URL, we can get screwed.
2. **Changing the environment restarts all servers**. At peak traffic, this will
   frequently result in degraded service during a warmup period. It's a risky
   operation in any event, as risky as a deploy.

The environment should be reserved for static configuration (enough for the
service to function). Dynamic configuration is a higher-level feature and can be
achieved in a number of ways (feature flagging; dedicated settings store in a
database for instance).

Good: using the environment for

- Resource handles to the database, cache, and other backing services
- Credentials to external services such as Amazon S3 or Twitter
- Per-environment values such as the canonical hostname for the deploy

Bad:

- List of featured products on a homepage.
- Per-country limits on vouchers.
- Instagram handles.


## Continuous Deployment

Services should strive to be deployed via Continuous Deployment (CD) when master
is green. This can be done on Heroku easily enough via [deployment
hooks](http://docs.travis-ci.com/user/deployment/heroku/) on Travis.

Remarks:

Apps running CD should, more than any other, have a zero-exception policy and
excellent monitoring; otherwise it's all too easy to miss broken deploys.


## Logging

With any service, logging is imperative to being able to work out what is going
on and to track and trace errors.

In the case of an error, services should:

  - log the fact there _was_ an exception/failure at `WARN` level.
  - log the stack trace at `DEBUG` level
  - send the exception to New Relic

In addition, services:

- **MUST** log every request
- **MAY** log Rails logs
- **MUST NOT** log ActiveRecord queries
- **MAY** log explicitly at INFO and higher, as required
- **SHOULD** log every asynchronous job
- Log level **MUST** be INFO in deployed apps.
- You **SHOULD** log to `$stdout` (per [12factor
  principles](http://12factor.net/logs)). The
  [rails_12factor](https://github.com/heroku/rails_12factor#rails-12factor-) gem
  sets that up for you if using Rails <5.
- You **SHOULD** log no more than 1-2 lines per user request or job.

Heroku captures logs by default but it is **REQUIRED** that you add
[PaperTrail](https://papertrailapp.com) to make it easier to review and parse
the logs. You also need to use [syslog
drains](https://devcenter.heroku.com/articles/logging#syslog-drains) on Heroku
to capture and store your logs, via Papertrail to [consolidate
logging](http://help.papertrailapp.com/kb/hosting-services/heroku/#addon) under
the organisation account.


## Monitoring

To monitor the _performance_ of your application, use [New
Relic](http://newrelic.com).

To monitor the _availability_ of your application, use
[Pingdom](https://www.pingdom.com).

To monitor the _functionality_ of your application, i.e. job queues, event
streams, cache hits, etc. use [Datadog](http://www.datadoghq.com)

All three should be set up when an app/service goes live.


## Backups

Bad things do happen and an effective backup (and **restore**) strategy is a
requirement for services that are storing information.

Backups should be:
- automated
- performed daily, or more frequently as required for the business case
- archived and stored separately to the deployment environment
- tested regularly to ensure the restoration process actually works!

Also, all environment-specific settings should be captured, i.e. backup `renv`
files or `heroku config`.


## Seeding a service


## Defining a service


## Extracting a feature into a service
