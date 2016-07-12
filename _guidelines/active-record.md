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

Coming soon.

### Migrations

Coming soon.

### Query objects

Coming soon.


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


