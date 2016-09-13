# Building micro-services

We strive towards a service-oriented, event-driven architecture. This guide intends to pave the road and help readers make good architecture and design decisions when building services.


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

#### What is a **micro** service?

The **micro** in micro service applies to the number of domain concepts a service operates on. All services should endeavour to be small _in scope_, i.e. should only address one (or two) domain concepts and be **very** resistant to adding more.

A service may, in fact, be large in terms of lines of code but it should always adhere to the principle of limiting the number of domain concepts it operates on.

----------------------

### Principles / philosophy

The overarching principles in service design are:

- **Cohesion**: a service is sole responsible for clearly defined functions on
  the domain, and for clearly defined sets of entities in the domain (a.k.a
  compactness, autonomy).
- **Abstraction**: a service's implementation details are entirely hidden behind its
  interface, including non-functionals (ie. scalability of a service, or lack
  thereof, is not the consumer's concern).
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
- GET requests should have no side-effects (on any entity of this concept or others) and be cacheable.
- PUT and PATCH requests should be idempotent (submitting them more than once should not change state further)
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

Consumer services know about source services through configuration (i.e. through the environment): no server names or URLs in a service's codebase

**EXAMPLE:** In the MonoRail if a property changes we publish an event via [RouteMaster](https://github.com/HouseTrip/routemaster/) for the appropriate PropertiesTopic. The Property Search Service is a consumer of that event so that it can [synchronise](https://github.com/HouseTrip/property_search#search-service-syncing-overview) the new data.

------------------------

### API design basics

Again because of the local knowledge criterion, services should have minimal
knowledge of any service's API they consume.  This can be achieved through good
use of hypermedia links.

For instance, imagining a resource (API term for domain concept) named
`bookings` that references a resource named `property`, you'd want this type of
API:

    >> GET /api/bookings/123
    << {
    <<   id: "123",
    <<   _links: {
    <<     self:     "https://bookings.example.com/api/bookings/123",
    <<     property: "https://monolith.example.com/api/properties/456"
    <<   }
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
breach the local knowledge requirement and tightly couple the service
architecture.

#### Ruby clients
It is considered good practice to provide a ruby client to consume a service's API both as an example of how best to use the API and to abstract the mechanics of dealing with HTTP and JSON payloads.

**EXAMPLE:** The [ht-search_client gem](https://github.com/HouseTrip/ht-search_client)

#### Multi-tenancy
A service needs to support multiple "tenants" by configuring itself (through its environment) to support differing datasets that are environment specific. For example, to be able to test and deploy services you should have a "staging" environment that allows for developer and PM testing. You should also have a "sandbox" environment that is a replica of production (providing a stable environment for deployed services that are used internally) as well as a production environment.

[insert diagram here]

Services should be testable in isolation.

Whereas for monoliths it is common to have a "staging" and a "production"
instance of the monolith (the former being used for quality assurance), this
does _not_ map simply to just having a "staging" and a "production" instance for
each service in a federation—otherwise, there's a risk of high-coupling between
_teams_ making changes to services.

Re-using our introductory example with `app`, `user`, `payment`, and
`inventory`, this is how the different environments intertwine:

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


#### Further reading

API design has its specific set of guidelines, outlined in the [Designing
APIs](https://github.com/HouseTrip/guidelines/blob/master/apis.md) document.

----------------------

### Preferred technology stack

Because a zoo of technologies leads to disaster, we purposely limit the set of
technologies we use.

From top to bottom of the production stack:

| Concern                 | Technology                          |
|-------------------------|-------------------------------------|
| Styling                 | Sass + Compass + Bootstrap          |
| Front-end logic         | CoffeeScript + Backbone.js          |
| Serving HTTP            | Unicorn                             |
| Responding to requests  | Rails                               |
| Querying HTTP           | Faraday                             |
| Logic                   | Ruby                                |
| Persisting data         | ActiveRecord/MySQL                  |
| Caching data            | Redis                               |
| Background processing   | Resque                              |
| Hosting                 | Heroku                              |
| Logging                 | Papertrail                          |

**NOTE:** You should aim to use the latest, stable versions of the above.

In development:

| Concern                 | Technology                          |
|-------------------------|-------------------------------------|
| Unit/integration testing| RSpec                               |
| Acceptance testing      | RSpec + Capybara + PhantomJS        |

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
| Persisting data         | Mongo, Redis, ElasticSearch         |
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

----------------------

### Service configuration

As per the 12factor principles, configuration lives in the environment.
This means that while Yaml files may exist in the repo, they should be about
data. Therefore it is a smell to have environment names mentioned in such files.

For Ruby apps the `dotenv` gem must be used, as it reproduces the runtime behaviour of Heroku. The `.env` file should have sensible settings that "just work" in development, and can be used as an example list of settings for deployments.

Settings should be prefixed with the service name.
Settings should also be clearly commented.

Example:

    # .env
    # base URL for the upstream service
    MYAPP_UPSTREAM_SERVICE=https://geonames.org/
    # timeout for requests
    MYAPP_TIMEOUT=10


**NOTE**:

- You should not need `.env.example` as all sensible defaults for development should be in `.env`
- `.env` is committed to the repo but is _also_ in `.gitignore`. This does not mean it is ignored from the repo, just from the commit list. To explicitly add any future changes use `git add .env`
- Do not use `dotenv-rails` as this gem automatically loads `.env.[RAILS_ENV]` if it exists (although this behaviour is going away in v1.0).
- If you are not using Heroku, you can use [renv](https://github.com/HouseTrip/renv) to store configuration in a similar style.

----------

### Continuous Deployment

Services should strive to be deployed via Continuous Deployment (CD) when master is green. This can be done on Heroku easily enough via [deployment hooks](http://docs.travis-ci.com/user/deployment/heroku/) on Travis.

**NOTE**:

Apps running CD should, more than any other, have a zero-exception policy and excellent monitoring; otherwise it's all too easy to miss broken deploys.

----------

### Logging

With any service, logging is imperative to being able to work out what is going on and to track and trace errors.

In the case of an error, services should:

  - log the fact there _was_ an exception/failure at `WARN` level.
  - log the stack trace at `DEBUG` level
  - send the exception to HoneyBadger

In addition, services:

- **MUST** log every request
- **MAY** log Rails logs
- **MUST NOT** log ActiveRecord queries
- **MAY** log explicitly at INFO and higher, as required
- **SHOULD** log every asynchronous job
- Log level **MUST** be INFO in deployed apps.
- You **SHOULD** log to `$stdout` (per [12factor principles](http://12factor.net/logs)). In Rails this can be done with `config.logger = ::Logger.new(STDOUT)`
- You **SHOULD** log no more than 1-2 lines per user request or job.

Heroku captures logs by default but it is **REQUIRED** that you add [PaperTrail](https://papertrailapp.com) to make it easier to review and parse the logs. You also need to use [syslog drains](https://devcenter.heroku.com/articles/logging#syslog-drains) on Heroku to capture and store your logs, via Papertrail to [consolidate logging](http://help.papertrailapp.com/kb/hosting-services/heroku/#addon) under the HouseTrip account.

--------

### Monitoring

To monitor the _performance_ of your application, use [New Relic](http://newrelic.com).

To monitor the _availability_ of your application, use [Pingdom](https://www.pingdom.com).

To monitor the _functionality_ of your application, i.e. job queues, event streams, cache hits etc. etc. then use [Datadog](http://www.datadoghq.com)

---------

### Backups

Bad things do happen and an effective backup (and **restore**) strategy is a requirement for services that are storing information.

Backups should be:
- automated
- performed daily, or more frequently as required for the business case
- archived and stored separately to the deployment environment
- tested regularly to ensure the restoration process actually works!

Also, all environment-specific settings should be captured, i.e. backup `renv` files or `heroku config`.

--------------

### Seeding a service

You may need to seed a service, either for development purposes or to setup some form of initial state. You should not directly seed the data store that the service uses - e.g. with `rake db:seed` - but rather use one of these two approaches.

- direct usage of the service's API to create domain entities
- ingesting a series of events from RouteMaster and then querying other services, as required.

This ensures that the service's API is properly tested and that its data is correct, per the constraints of that API.

--------

### Defining a service

Before you start writing a service, it is important to establish the remit the service is going to be responsible for. Before any code is written it is recommended that you write a README for the project:

- outline the specific use cases for the service
- detail which domain concepts the service is the authority for
- specify the _business function_ the service is responsible for
- detail the API the service implements. More detail can documented via [Apiary](http://apiary.io/) as the API becomes more fully defined.
- A list of the events that the service responds to and/or emits.
- A picture paints a thousand words, draw an architecture diagram to communicate better how the service works.

**EXAMPLE:** The [property search service](https://github.com/HouseTrip/property_search/blob/master/README.md) is a good example of the level of detail required.

This README should form the basis for a discussion as to whether the service is actually required or the uses cases could be dealt with by other services. Only when it is determined that this service is a unique snowflake should you commence building it.

--------

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
