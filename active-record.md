My mom told me that ActiveRecord doesn't scale!
Fortunately, here comes the...

# Guidelines for fast & reusable ActiveRecord

This is a smell of bad design:

> *I need to write a custom SQL query to do this !*
>
> — No one, ever

**This guide** is here to **help you** write ActiveRecord (or any ORM code, really) that lets your app **scale** with good performance and without prematurely optimizing the hell out of it.

There should be no exceptions to this guide.
If you think you found one, you're probably wrong, but still feel free to issue a pull request and be ready to defend it!

## Principles & style

Layering and **separation of concerns** are overarching principles here.
There should be a clear separation between your **database** and your **application**: the former is there to persist data, period. When you put something in, it should come out exactly as is, and pulling it out should be reasonably simple. 

In particular your database should not have any logic: all the (business) rules should be in your application. This means that default values, foreign key checks, triggers, stored procedures should be forbidden in general.

The only case where your database will "do" something for you beyond storage is when counting, or otherwise aggregating persisted data. This is essentially for performance reasons.


### Controllers, views, helpers

Controllers, views, helpers, view objects, presenters, decorators should never contain any SQL. At all. Even SQL expressions. Seriously, you'll thank us later.

They should not use relation builders (the `where`, `order`, `group` methods and friends) but instead rely on named scopes at all times.

Good: 

    @users = current_user.account.users.created_after(1.year.ago)
    
Bad:

    @users = User.where('account_id = ? AND created_at > ?', foo, bar)

Worse:

    @users = User.find_by_sql(OH_GOD_KILL_ME)


### Models

Models should not contain any SQL query.

They can, however, contain SQL _expressions_ in the form of `where` conditions for instance.
The only place where this should happen is **named scopes**, which you should use extensively.

    scope :recently_created, -> { |timestamp| where('created_at > ?', timestamp) }

You can define class methods for often-used chains of scopes, as long as they return a `Relation` or smething scopish:

    module ClassMethods
      def recently_created_in_account(date, account)
        recently_created(date).member_of(account)
      end
    end
    extend ClassMethods

Be careful though, if you're doing anything more complex than chaining a few scopes it probably needs to go to a query object (see below).

For the sake of reuse, remember that scopes are code: make scopes generic as necessary, avoid scope proliferation.

Good:

    scope :created_after, -> { |timestamp| ... }
    
Bad:

    scope :created_since_last_year, -> { where('created_at > ?', 1.year.ago) }
    scope :created_since_yesterday, -> { where('created_at > ?', 1.day.ago.beginning_of_day) }


### Migrations

Migrations are one of the only places which should contain SQL queries. In fact, migrations should contain _only_ SQL queries, and **no code using models**.

This is because your migration has to work up and down even if your model no longer exists, has been renamed, or has had and internal API change!

Good (roughly):

    def up
      add_column :users, :age, :integer
      update %{
        UPDATE users
        SET age = TIMESTAMPDIFF(YEAR,date_of_birth,CURDATE())
      }
    end

Bad:

    def up
      add_column :users, :age, :integer
      User.find_each do |u|
        u.age = Date.today.year - u.date_of_birth.year
        u.save!
      end
    end



### Query objects

An application of [one of the PoEAA](http://www.martinfowler.com/eaaCatalog/queryObject.html), this is meant to encapsulate a query:

- it is instanciated with a number of criteria
- it has an `#execute` method that either has a side effect, or iterates over query results

This is the only type of classes where `ActiveRecord::Base#find_by_sql` or `ActiveRecord::Base#connection` are allowed.
You'll typically use your connection's `#select_values`, `#select_rows`, and `#update` methods to do something useful.

Example (roughly):

    class Query::RecentlyCreatedUserFinder
      def initialize(account:nil, timestamp:nil)
        @account = account or raise ArgumentError
        @timestamp = timestamp || 1.week.ago
      end
      
      def execute
      	ids = User.connection.select_values(sanitize([%{
          SELECT id FROM users
          WHERE created_at < ? AND account_id = ?
        }, @timestamp, @account.id]))
        ids.each { |id| yield User.find(id) }
      end
    end



## Performance considerations

You don't need a database administrator—if you follow a few simple rules. Otherwise carelessly crafted queries can easily blow up your app servers, your database servers, or both.


### Indices

Starting with the obvious. If there's no index for your particular query, it will be slow.

Rules of thumb:

- always create an **index on foreign keys** (every field ending with `_id`).
- always run `EXPLAIN` on non-trivial queries
- do not add more indices until you actually have a problem.

More indices do not always help: the more indices, the slower the updates, and your RDBMS _will_ get confused and pick the wrong one.


### Multi-table queries

Rule of thumb: count one for each of `group`, `join`, `having`, `where`, `order` in your query. More than three? Things will blow up.

In particular, multiple joins are a symptom of over-normalized data modeling.

Rule of thumb: do not be afraid to **introduce join models** (and the corresponding join tables). They're easier to test, and they represent concepts you'll have to name anyways.

If that isn't enough: precalculate, use caching, and **do your math in Ruby**. Your app code can scale very well (possibly through scheduled jobs), the database cannot.  


### Memory swapping

Rule of thumb: if you're not certain how many records your query will retrieve, eventually it's going to retreive too many and you'll blow up your machine's memory (known as _swapping_).

Alway **paginate or limit** unless domain knowledge tells you clearly you don't have to.

Good:

    User.paginate(page:1, per_page:10)
    User.limit(10)
    
Fine:

    User.find_in_batches

Bad:

    User.all



### Contention

It's a lot easier for any (database) server to schedule and parallelise lots of small tasks than a few monstrous ones.

If a given query touches (reads from or writes to) more than a few 1000 rows or 5% of a given table at a time (whichever is the smaller), you're going to blow things up.

Of course this is particularly true if the table in question is heavily used.

Rule of thumb: **use batches** to process groups of records.

Good:

	User.find_each { |u| puts u.id }
    
Bad:

	User.each { |u| puts u.id }


Sometimes it will be a bit more complex to batch your queries, so you'll want to introduce this only once you have "enough" records:

Good:

    offset, step, max_id = 0, 100, User.maximum(:id)
    
    while offset < max_id
      User.where('id BETWEEN ? AND ?', offset, offset + step - 1)
          .update_all(updated_at: Time.now)
      offset += step
    end

Bad:

    User.update_all(updated_at: Time.now)



