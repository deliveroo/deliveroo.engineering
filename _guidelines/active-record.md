---
title:      "Active Record"
---


My mom told me that ActiveRecord doesn't scale!
Fortunately, here comes the...

# Guidelines for fast & reusable ActiveRecord

This is a smell of bad design:

> *I need to write a custom SQL query to do this !*
>
> — No one, ever

**This guide** is here to **help you** write ActiveRecord (or any ORM code,
really) that lets your app **scale** with good performance and without
prematurely optimising the hell out of it.

There should be no exceptions to this guide.  If you think you found one, you're
probably wrong, but still feel free to issue a pull request and be ready to
defend it!

## Principles & style

Layering and **separation of concerns** are overarching principles here.  There
should be a clear separation between your **database** and your **application**:
the former is there to persist data, period. When you put something in, it
should come out exactly as is, and pulling it out should be reasonably simple. 

In particular your database should not have any logic: all the (business) rules
should be in your application. This means that triggers, stored procedures
should be forbidden in general.

We make two exceptions to "logic in the database":

- foreign keys constraints are strongly recommended, provided they're also coded
  with Rails, using validations and the appropriate `dependent:` declarations on
  associations. <br/>
  This is because Rails cannot enforce relationship integrity efficiently.
- default values are accepted provided they're also supported by Rails
  (automatic in Rails 4+). <br/>
  This is because default values are a common requirement and are both a pain
  and a source of performance issues if done in Rails.

The only case where your database will "do" something for you beyond storage is
when counting, or otherwise aggregating persisted data. This is essentially for
performance reasons.


### Controllers, views, presenters, decorators

Controllers, views, helpers, view objects, presenters, decorators should never
contain any SQL. At all. Even SQL expressions. Seriously, you'll thank us later.

The rationale: a class/object that contains SQL
- cannot be tested without the database. This makes testing slower and more
  brittle.
- spreads the responsibility of interacting with the database across multiple
  places. We choose to strictly reserve database interaction to query objects,
  models, and migrations (more on this below).

They should not use relation builders (the `where`, `order`, `group` methods and
friends) but instead rely on named scopes; unless the named scopes are trivial.

Good:

```ruby
@users = current_user.posts.created_after(1.year.ago)
```

Okay:

```ruby
@users = current_user.posts.where(created_at: 1.year.ago .. Time.current)
```
    
Bad:

```ruby
@users = Posts.where('user_id = ? AND created_at > ?', current_user.id, 1.year.ago)
```

Worse:

```ruby
@users = User.find_by_sql(OH_GOD_KILL_ME)
```


### Models

Models should not contain any SQL queries.

They can, however, exceptionally contain SQL _expressions_ in the form of
`where` conditions for instance; although using
[Arel](https://github.com/rails/arel) to express conditions is preferred when
possible. The only place where this should happen is **named scopes**, which you
should use extensively.

Okay:

```ruby
scope :created_after, -> { |timestamp| where('created_at > ?', timestamp) }
```

Better (no SQL, no issue with using the scope in joins):

```ruby
scope :created_after, -> { |timestamp| 
  where self.class.arel_table[:created_at].gt timestamp
}
```

#### Scope chains

If a scope contains a SQL snippet (ie. if it's not pure Arel), it should be unit
tested.

It's okay to define class methods for often-used chains of scopes, as long as
they return a `Relation` or something scopish:

```ruby
module ClassMethods
  def recently_created_in_account(date:, account:)
    created_after(date).account_is(account)
  end
end
extend ClassMethods
```

Be careful though, if you're doing anything more complex than chaining a few
scopes it probably needs to go to a query object (see below).

For the sake of reuse, remember that scopes are code: make scopes generic as
necessary, avoid scope proliferation.

Good:

```ruby
scope :created_after, -> { |timestamp| ... }
```
    
Bad:

```ruby
scope :created_since_last_year, -> { where('created_at > ?', 1.year.ago) }
scope :created_since_yesterday, -> { where('created_at > ?', 1.day.ago.beginning_of_day) }
```

#### Naming

We choose to name scopes using the `{attribute}_{operator}` pattern when
possible.

Scope parameters should be records, not IDs, wherever possible and not hurtful
for performance.

Good: `User.account_is(account)`, `User.created_after(date)` 

Bad: `User.member_of(account)`, `User.recently_created(date)`,
`User.account_id_is(account.id)`


### Migrations

Migrations are one of the only places which should contain SQL queries. In fact,
migrations should contain _only_ SQL queries, and **no code using ActiveRecord
models**.

This is because your migration has to work up and down even if your model no
longer exists, has been renamed, or has had and internal API change!

Migrations _maybe_ exceptionally use PORO models to facilitate complex data
changes, though.

Good (roughly):

```ruby
def up
  add_column :users, :age, :integer
  update %{
    UPDATE users
    SET age = TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE())
  }
end
```

Bad:

```ruby
def up
  add_column :users, :age, :integer
  User.find_each do |u|
    u.age = Date.today.year - u.date_of_birth.year
    u.save!
  end
end
```

If applicable, remember to clear the cache[^cache] after running migrations that
change data if the affected model is cached; or to send update events on the
event bus[^bus] to refresh subscribers.

[^cache]: [Clearing the Rails cache in the Deliveroo monolith](https://makandracards.com/deliveroo/41342-orderweb-clearing-the-rails-cache).

[^bus]: [Event bus basics at Deliveroo](https://makandracards.com/deliveroo/41074-event-bus-basics-howto).

#### Zero-downtime migrations

Because we do rolling deploys (with Heroku's "preboot" feature), both the old
and new code will be running at the same time.

There are two options to make this work without causing exceptions:

Preferred:

- The new code should ship with the migration. It must support that the
  migration has not been run yet.
  The migration is run manually after the deploy is completed.
- This pattern works bet when _changing_ or _deleting_ tables or columns.

Okay:

- The migration is shipped before the new code ships, from a separate pull
  request. The old code must work with and without migrations.
- This pattern makes the most sense when _adding_ tables or columns that are not
  used by old code, but it's not required.


### Query objects

An application of [one of the
PoEAA](http://www.martinfowler.com/eaaCatalog/queryObject.html), this is meant
to encapsulate a query:

- it is instantiated with a number of criteria
- it has an `#execute` method that either has a side effect, or iterates over
  query results

This is the only type of classes where `ActiveRecord::Base#find_by_sql` or
`ActiveRecord::Base#connection` are allowed.  You'll typically use your
connection's `#select_values`, `#select_rows`, and `#update` methods to do
something useful.

Example (roughly):

```ruby
class User::RecentlyCreatedFinder
  def initialize(account: nil, timestamp: nil)
    @account = account or raise ArgumentError
    @timestamp = timestamp || 1.week.ago
  end
  
  def call
    ids = User.connection.select_values(sanitize([%{
      SELECT id FROM users
      WHERE created_at < ? AND account_id = ?
    }, @timestamp, @account.id]))
    ids.each { |id| yield User.find(id) }
  end
end
```

Note that it's still vastly preferred to use Railsy querying and Arel in query
objects.

Improved example:

```ruby
class User::RecentlyCreatedFinder
  def initialize(account: nil, timestamp: nil)
    @account = account or raise ArgumentError
    @timestamp = timestamp || 1.week.ago
  end
  
  def call
    User.
    where(account_id: @account.id).
    where('created_at < ?', @timestamp).
    find_each do |user|
      yield user
    end
  end
end
```

In terms of usage, this translates into:

Good:

```ruby
query = User::RecentlyCreatedFinder.new(account: foo, timestamp: bar)
query.call do |user|
  do_stuff user
end
```

Bad:

```ruby
relation = User.where(account_id: foo.id).where('created_at < ?', bar)
relation.find_each do |user|
  do_stuff user
end
```

Using a query object is better because:
- it's easier to test (an iterator can be injected)
- it doesn't have odd "kind of enumerable but not really" properties like
  `ActiveRecord::Relation`


## Performance considerations

Coming soon.

### Indices

Coming soon.

### Multi-table queries

Coming soon.

### Memory swapping

Coming soon.

### Contention

Coming soon.

----

