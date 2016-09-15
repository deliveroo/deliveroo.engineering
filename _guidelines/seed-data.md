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

When creating seed data it's important not to use random data as it must be the same every time; gems like [Faker](https://github.com/stympy/faker) can be great for runtime test data you shouldn't use them here. Using FactoryGirl's sequences lets you generate unique but consistent test data, for example:

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

### Performance Testing

Because you won't have a dataset nearly the size of the production one, it makes it very difficult to test performance on the local system. However, if you stick to good engineering practices (particularly around [Active Record](/guidelines/active-record)) then you should rarely have a problem.

If there are performance problems with the code then they should be found on a staging or pre-production environment which should be using a larger anonymised dataset.

### Migration Testing

Testing migrations can also be tricky as sometimes the data in real databases isn't quite as clean as the idealised seed data on your machine. These problems will surface when run in a staging or pre-production environment and the problematic data can be explored there.

Keeping migrations atomic or idempotent will ensure that if there are problems on the full dataset that they can be re-run once the problem is resolved.
