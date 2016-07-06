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
prematurely optimizing the hell out of it.

There should be no exceptions to this guide.  If you think you found one, you're
probably wrong, but still feel free to issue a pull request and be ready to
defend it!

## Principles & style

Layering and **separation of concerns** are overarching principles here.  There
should be a clear separation between your **database** and your **application**:
the former is there to persist data, period. When you put something in, it
should come out exactly as is, and pulling it out should be reasonably simple. 

In particular your database should not have any logic: all the (business) rules
should be in your application. This means that default values, foreign key
checks, triggers, stored procedures should be forbidden in general.

The only case where your database will "do" something for you beyond storage is
when counting, or otherwise aggregating persisted data. This is essentially for
performance reasons.


### Controllers, views, presenters, decorators

Controllers, views, helpers, view objects, presenters, decorators should never
contain any SQL. At all. Even SQL expressions. Seriously, you'll thank us later.

They should not use relation builders (the `where`, `order`, `group` methods and
friends) but instead rely on named scopes at all times.

Good:

```ruby
@users = current_user.account.users.created_after(1.year.ago)
```

Okayish: 

```ruby
@users = current_user.account.users.where(created_at: 1.year.ago .. Time.current)
```
    
Bad:

```ruby
@users = User.where('account_id = ? AND created_at > ?', foo, bar)
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


