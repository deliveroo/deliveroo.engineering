# Writing sustainable test suites

A good test suite, beyond providing coverage, should be sustainable: TDD should
remain possible as the service or application grows.

We've all experienced the pain of clumsy, slow test suites: this document aims
to provide a cookbook of best practices to avoid new apps/services falling in
the same traps.

This document is written with Ruby and RSpec in mind.

_See also:_ Mike Pack has written a great article on [High-Low
testing](http://mikepackdev.com/blog_posts/39-high-low-testing) which shares the
same attitude as this document and has good complements.


## Key features of a good test suite

1. Run time of the overall test suite should be low enough to not leave "the
   zone". Ideally it should not exceed 5 minutes.

2. It is possible to run a partial build on file modifications.

3. Run time of partial build should be fast enough to give instant feedback on
   the class/method currently being changed. It should stay under 10 seconds.

4. The test suite should run consistently, no matter what the order of the
   individual tests is.


## Running partial builds

Using `guard` and `guard-rspec` is recommended for all Ruby gems and
applications.

Using auto-loaders (spring, zeus, spork) is **discouraged**: temptation to use
them is usually a symptom of other issues (bad `spec_helper`, application too
large), and they always end up creating more issues than they solve (weird load
dependency issues, test suite instability).


## Running consistently

RSpec should always be configured to run in random order (the default).
"Flakyness", ie. tests randomly failing depending on run order is a **bug**, and
a flaky test suite gives no confidence that regressions are avoided.

Flaky tests suites should be resolved as a priority, as any further development
is compromised.


## Running the whole suite quickly

- Limit integration tests to core features. An excellent unit test suite is
  sufficient to cover most failure scenarios.

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

It doesn't load any code, or any "environment", nor should it.

Remember that this file will be loaded every single time you run a partial test
(e.g. after saving a file if using Guard), so the cost of adding things to
`spec_helper` is huge.

In particular, your `spec_helper` should never connect to a database, or compile
any code not required for basic RSpec setup.


### Require just what is needed

Rails comes with a bad practice that is hugely damaging both to decoupling
functionality and to speed of tests: it loads "all the things" every time the
environment is loaded—which means reading Ruby sources from disk and compiling
it. For even a medium-sized application, that can easily be 1000s of files.

Rails's bad behaviour is why when a class `A` references a class `B` (perhaps
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
- (optionally) support classes, e.g. classes of objects you need to inject as
  dependencies.

This guarantees running just that spec has a minimal footprint, does not
increase the time taken by a full run (`require` is free for already-loaded
files), and increases decoupling (random runs will surface implicit
dependencies).

As an example of `spec/support` cases, one might

- load the Rails environment in integration tests;
- in a query object test, load
  [`spec/support/persistence`](https://github.com/HouseTrip/routemaster/blob/master/spec/support/persistence.rb)
  to connect to databases, and automatically clean databases before discrete tests;
- in a controller test, load
  [`spec/support/rack_test`](https://github.com/HouseTrip/routemaster/blob/master/spec/support/rack_test.rb)
  to add the requisite methods to the RSpec DSL.
- in an API test, load `spec/support/webmock` to stub out external API calls.

[`spec_requirer`](https://github.com/HouseTrip/spec_requirer) is a good way to
simplify loading just what you need for a readable syntax.



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
prefer to delegate that role to query objects (which can be mocked).

A common pattern is to inject repositories:

```ruby
class MyService
  def initialize(user_repo: User)
    @user_repo = user_repo
  end

  def execute
    @user_repo.find(...)
  end
end
```

In consumers of service objects, mock them out, and stub `save!` in any output
objects for instance.

Caveat: when using ActiveRecord, any "chained" query should be isolated into a
query object, otherwise the temptation to use `stub_chain` will be strong.
The query object can be mocked in the same way as a repository class.



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

Good:

```ruby
class User < ActiveRecord::Base ; end

class UserPresenter < SimpleDelegator
  def full_name
    "#{first_name} #{last_name}"
  end
end

class UserStateMachine
  def initialize(user)
    @user = user
  end

  def state=(new_state)
    # magic goes here
  end
end
```

Bad:

```ruby
class User < ActiveRecord::Base
  acts_as_kitchen_sink

  def full_name
    "#{first_name} #{last_name}"
  end
end
```


#### Test persistence in query objects only.

Some queries are complex and you cannot avoid testing them. In a fast test
suite, query objects are _only_ run in their own tests (and in integration
tests).


## Miscellaneous: smelling out bad practices



- Stubbing out methods on the object being tested is a symptom of bad internal APIs
  or poor coupling.

- Testing private methods is often a symptom of "god objects".

- Stubbing private method is a combination of the above :)
  In such cases, the private method can generally be isolated to its own
  testable class or value object:

    ```ruby
    private

    def calculate_it
      CalculateIt.new(data: @field1).value
    end
    ```


- Using stub chains is a smell you should be using dependency injection (and
  injecting test doubles):

    ```ruby
    # Bad
    def MyService.run
      last_booking = @user.bookings.last
      ...
    end

    mock_user.stub_method_chain(:bookings, :last).and_return(mock_booking)


    # Better
    def MyService.run
      last_booking = LastBookingFinder.new(@user).value
      ...
    end
    allow_any_instance_of(LastBookingFinder).to receive(:value).and_return(mock_booking)


    # Good
    def MyService.initialize(user:, booking_finder: nil)
      booking_finder ||= LastBookingFinder.new(user)
      ...
    end

    # in spec
    let(:fake_finder) { double value: mock_booking }
    subject { described_class.new(booking_finder: fake_finder) }
    ```

- Mocks falling out of sync (when using dependency injection) can be resolved
  using [verified
  doubles](https://relishapp.com/rspec/rspec-mocks/v/3-0/docs/verifying-doubles).
  This is **not** possible for ActiveRecord objects (their accessors are
  dynamically defined by checking the database schema); we recommend maintaining a
  factory of mocks for those (and keeping it in sync with the schema).

