# Writing sustainable test suites

A good test suite, beyond providing coverage, should be sustainable: TDD should
remain possible as the service or application grows.

We've all experienced the pain of clumsy, slow test suites: this document aims
to provide a cookbook of best practices to avoid new apps/services falling in
the same traps.

This document is written with Ruby and RSpec in mind.


## Key features of a good test suite

1. Run time of the overall test suite should never exceed 5 minutes.

2. It is possible to run a partial build on file modifications.

3. Run time of partial build should never exceed 10 seconds.

4. The test suite should run consistently, no matter what the order if the
   indiividual tests is.


## Running partial builds

Using `guard` and `guard-rspec` is recommended for all Ruby gems and
applications.

Using auto-loaders (spring, zeus, spork) is **discouraged**: temptation to use
them is usually a symptom of other issues (bad `spec_helper`, application too
large), and they always end up creating more issues than they solve (weird load
dependency issues, test suite unstability).


## Running consistently

Rspec should always be configured to run in random order (the default).
"Flakyness", ie. tests randomly failing depending un run order is a **bug**, and
a flaky test suite gives no confidence that regressions are avoided.

Flaky tests suites should be resolved as a priority, as any further development
is compromised.


## Running the whole suite quickly

- Limit integration tests to core features. An excellent unit test suite is
  sufficient to cover mosst failure scenarios.

- Always fail early, using RSpec's `--fail-fast` for instance.

- Run integration tests last. With `guard`, you can achieve this by having
  separate `rspec` groups for integration/acceptance tests.

  The rationale here is that integration tests are by nature slower (integration
  tests cannot have internal stubs or mocks, and often need persistence to
  databases), and you'll want to get the rapid feedback from your unit tests
  first.



## Running individual tests quickly

Individual tests (in RSpec, test files) are often bound by

- "environment" load time (including RSpec environment)
- "setup" time around each discrete test (e.g. clearing a database)

### Keep the environment small

As an example, [Routemaster's
`spec_helper`](https://github.com/HouseTrip/routemaster/blob/master/spec/spec_helper.rb)
is very short: it just configures RSpec.

It doesn't load any code, or any "environment", not should it.

Remember that this file will be loaded every single time you run a partial test
(e.g. after saving a file if using Guard), so the cost of adding things to
`spec_helper` is huge.

In particular, your `spec_helper` should never connect to a database, or compile
any code not required for basic RSpec setup.


### Require just what is needed

Rails comes with a bad practice that is hugely damaging both to decoupling
functionnality and to speed of tests: it loads "all the things" every time the
environment is loaded—which means reading Ruby sources from disk and compiling
it. For even a medium-sized application, that can easily be 1000s of files.

Rails's bad behaviour is why when a class `A` references a class `B` (peharps
`A` is a factory of `B`'s, for instance), you don't need to `require 'b'` in
`a.rb`. **You should** make dependencies explicit.

If you're not directly writing a Rails application (e.g. in a gem, or a Sinatra
app), you should make all dependencies explicit in your source:

- each file requires only what is needed (other files, gems)
- all entries in the Gemfile have `require: false`

Top-level files will indirectly load the required tree (`config.ru` will load
`app.rb`, which will load the various controllers, which will load the various
models).

The same rule applies in tests: each test file requires
- the very small `spec_helper`;
- any files in `spec/support` it needs to function;
- the single class that is being tested;
- (optionally) support classes, e.g classes of objects you need to inject as
  dependencies.

This guarantees running just that spec has a minimal footprint, does not
increase the time taken by a full run (`require` is free for already-loaded
files), and increases decoupling (random runs will surface implicit
dependencies).

As an example of `spec/support` cases, on might

- load the Rails environment in integration tests;
- in a query object test, load
  [`spec/support/persistence`](https://github.com/HouseTrip/routemaster/blob/master/spec/support/persistence.rb)
  to connect to databases, and automatically clean databases before discrete tests;
- in a controller test, load
  [`spec/support/rack_test`](https://github.com/HouseTrip/routemaster/blob/master/spec/support/rack_test.rb)
  to add the requisite methods to the RSpec DSL.
- in an API test, load `spec/support/webmock` to stub out external API calls.


## Running the whole suite quickly

This relies mainly on well-designed classes, so this section includes key
recommendations to that effect.

### Testable classes

Respecting SOLID goes a long way to make classes testable. In particular, a
layered/hexagonal/service design will abstract out persistence, which is the key
contributor to slow tests.


#### Heavily use service objects, and avoid persistence in service objects.

Service objects normally have a very compact concern, and a single public method
(often called `run`).

If your service depends on stored data, avoid loading it in the service object;
prefer to delegate that role to query objects (which can me mocked).

Likewise, avoid persisting data in service objects, and leave that role to the
caller.
In consumers of service ojects, mock them out, and stub `save!` in any output
objects for instance.


#### Keep "models" thin and never implement business logic in models.

A different angle on the previous recipe, really: if your models are thin you
can mock them out in any service object or other consumer.

Any addition of a method to models, even "sugar" methods (that test or combine
attributes) is a smell. Save-time callbacks are the strongest smell of bad
coupling.

If you need to react to persistence events, `after_save` is not your friend,
neither are observers; prefer using a local event bus like the excellent
[wisper](https://github.com/krisleech/wisper).

If you need sugar, write a presenter using `SimpleDelegator`.


#### Test persistence in query objects only.

Some queries are complex and you cannot avoid testing them. In a fast test
suite, query objects are _only_ run in their own tests (and in integration
tests).


## Miscellaneous: smelling out bad practices



- Stubbing out methods on the object being tested is a symtom of bad internal APIs
  or poor coupling.

- Testing private methods is often a symtom of "god objects".

- Stubbing private method is a combination of the above :)

- Using stub chains is a smell you should be using dependency injection (and
  injecting test doubles)

- Mocks falling out of sync (when using dependency injection) can be resolved
  using [verified
  doubles](https://relishapp.com/rspec/rspec-mocks/v/3-0/docs/verifying-doubles).
