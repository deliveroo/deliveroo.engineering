---
layout:     guidelines
title:      "Seed Data"
collection: guidelines
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Why Use Seed Data?

There are two major uses for seed data:

1. To give a set of realistic data to develop against, including _ad hoc_ testing and user interface work.
2. To speed up automated test runs by pre-populating some data rather than continually recreating it.

A commonly used approach is to work with copies of production data, often anonymised to at least some extent. However, this is extremly risky because it is very easy to leak PII (personally identifiable information), particularly if laptops are taken home. **Do not have copies of production data on your development machine -- even anonymised ones!**

Instead of using production-based data, seed data should be generated to give a small but sufficient data set for use in development and test scenarios. Using the same data for both allows developers to become familiar with the available data.

## Generating Seed Data

The recommended approach for generating seed data is to use [FactoryGirl](https://github.com/thoughtbot/factory_girl) which has many powerful methods for creating Active Record objects, and use these factories from the `db:seed` rake task. This means that the data is generated via the models which reduces the chance of it getting stale or out-of-sync.

A basic `db/seeds.rb` file for a service with users might look something like this:

```ruby
FactoryGirl.find_definitions
FactoryGirl.create_list :user, 10
```

When creating seed data it's important not to use random data as it must be the same every time; gems like [Faker](https://github.com/stympy/faker) can be great for runtime test data but you shouldn't use them here. Using FactoryGirl's sequences lets you generate unique but consistent test data, for example:

```ruby
FactoryGirl.define do
  factory :user do
    sequence(:first_name) { |n| "John#{n}" }
    sequence(:last_name) { |n| "Doe#{n}" }
    sequence(:email) { |n| "johndoe#{n}@example.org" }
    sequence(:mobile) { |n| "+447#{n.to_s.rjust(9, '0')}" }
    sequence(:password) { |n| "pa55w0rd#{n}!" }
  end
end
```

## Considerations

### How Much Data?

How much seed data you should generate is a balance between necessity and speed. The less data you generate the faster your builds will be, but if you don't have enough then you won't be able to test things like paging. The correct answer then is as little as possible, but not too little.

As an example, you'll need enough restaurants to fill at least one, but perhaps two or three listing pages in a single zone. You'll also want a small number of restaurants in a handful of other cities and countries to be able to test variants of the code there and localisation.

### Performance Testing

Because you won't have a dataset nearly the size of the production one, it makes it very difficult to test performance on the local system. However, if you stick to good engineering practices (particularly around [Active Record](/guidelines/active-record)) then you should rarely have a problem.

If there are performance problems with the code then they should be found on a staging or pre-production environment which should be using a larger anonymised dataset.

### Migration Testing

Testing migrations can also be tricky as sometimes the data in real databases isn't quite as clean as the idealised seed data on your machine. These problems will surface when run in a staging or pre-production environment and the problematic data can be explored there.

Keeping migrations atomic or idempotent will ensure that if there are problems on the full dataset that they can be re-run once the problem is resolved.


## Creating Factories

### Return valid records. Every Time!

When creating factories, set the minimum required columns to return a valid record.

For Example:

```ruby
# Bad because FactoryGirl.create(:user) throws and exception!
FactoryGirl.define do
  factory :user do
    name "John"
  end
end
```

`FactoryGirl.create(:user)` should return a valid user! Every time!

  If we are getting an `ActiveRecord::RecordInvalid: Validation failed: Surname type can't be blank`.
    Please add a reasonable default for the `surname` field.

```ruby
# Good because FactoryGirl.create(:user) returns a valid record.
FactoryGirl.define do
  factory :user do
    name "John"
    surname "Lennon"
  end
end
```

  If calling `FactoryGirl.create(:user)` multiple times causes `ActiveRecord::RecordInvalid: Validation failed: Name 'John' is taken`.
    Please use `sequence` for the `name` field or use `faker`, so every record will have a unique `name`.

```ruby
# Good because 2.times { FactoryGirl.create(:user) } doesn't raise an exception
FactoryGirl.define do
  factory :user do
    sequence(:name) { "John the #{n}" }
  end
end
```

You can use `faker` to achieve the same effect.

```ruby
# Good because 2.times { FactoryGirl.create(:user) } doesn't raise an exception
FactoryGirl.define do
  factory :user do
    name { Faker::Name.name }
  end
end
```

### Return a record in isolation to other records.

Example

```ruby
# Bad because relying on database to have a specific record.
FactoryGirl.define do
  factory :user do
    company  { Company.find_by_name('Apple') }
  end
end
```
Never rely on the database being in a specific state. In the example above, we are relying on the fact that a `Company` record with the name "Apple" must be created for us to use this factory.

Why not this?


```ruby
# Good
FactoryGirl.define do
  factory :user do
    association :company
  end
end

FactoryGirl.define do
  factory :company do
    name "Apple"
  end
end
```
So `FactoryGirl.create(:user)` wouldn't rely on the existing data but instead will create a company record - using company factory- if necessary.


### Return unique records.

Make sure that calling `FactoryGirl.create` multiple times will return unique records.

Example


```ruby
# Bad - every created user will have the same id, email address etc.
FactoryGirl.define do
  factory :user do
    initialize_with { User.find_by_email("bob@example.com") }
  end
end
```

Not only we are relying on the fact that our user factory needs another user to be created before but also
everytime we call `FactoryGirl.create(:user)` we will get the same user which is not the expected behaviour for a Factory.

Please make sure calling the `create` on the factory always returns unique records.

```ruby
# Good
FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| "bob@example_{n}.com") }
  end
end
```
You can also generate unique column values using `faker`

```ruby
# Good
FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
  end
end
```

So we will have a unique record each time we called :create.