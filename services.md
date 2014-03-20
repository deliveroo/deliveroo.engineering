
# Building services

We strive towards a service-oriented, event-driven architecture.

This guide intends to pave the road and help readers make good architecture and
design decisions when building services.

--------------------------------------------------------------------------------

### What's a service?



Should be possible to define a serivce as a function of what 3rd parties it
interacts with, which domain concepts it operates on, and how it transforms
them.


Domain concepts (bookings, users) and entities (a given booking, a given user).

Authority on a concept's data (state)

Responsibility for transformations, interactions with a given set of 3rd parties

Communication with others
exchanging state information about domain entities


--------------------------------------------------------------------------------

### Principles / philosophy

12factor

rest

representational state notification / event-driven

limited local knowledge

Typical dont's

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

