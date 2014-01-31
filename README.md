# HouseTrip RSpec Style Guide

### Table of contents

1. [Code organization](#code-organization)
2. [Syntax](#syntax)
3. [Single expectations](#single-expectations)
4. [Describing objects](#describing-objects)
5. [Using contexts](#using-contexts)
6. [subject](#subject)
7. [let](#let)
8. [Mocks and stubs](#mocks-and-stubs)
9. [Integration testing](#integration-testing)
10. [Shared examples](#shared-examples)
11. [Custom matchers](#custom-matchers)
12. [Test interface](#test-interface)
13. [Stub HTTP requests](#stub-http-requests)
14. [Other stuff](#other-stuff)

## Code organization

- In a context, define `before` blocks, then `let` blocks, then leave a blank line and start defining assertions.
- If you have a subject for the context place it between pre-definitions and assertions, again with a blank line
- Keep any code that's not assertions outside `it` blocks. Use `let` and `before` blocks for that.

```ruby
describe Review do
  context 'with a photo' do
    before { initialize_stuff }
    let(:photo) { Photo.new }

    subject { Review.new }

    it { should be_blank }
    its(:rating) { should be_nil }
  end
end
```

## Syntax

Make heavy use of RSpec helpers.

- For all predicates you can use the `be_` syntax

```ruby
# bad
it { subject.published? eql(true) }

# good
it { subject be_published }
```

- When testing size of an array or array-like object (e.g.: an ActiveRecord relation) use the `have` matcher. RSpec will send the trailing method and `size` to the object for you

```ruby
# bad
it { subject.reivew.size.should eql(3) }

# good
it { should have(3).reviews }
```

## Single expectations

The 'one expectation' tip is more broadly expressed as 'each test should make only one assertion'. This helps you on finding possible errors, going directly to the failing test, and to make your code readable.

In isolated unit specs, you want each example to specify one (and only one) behavior. Multiple expectations in the same example are a signal that you may be specifying multiple behaviors.

```ruby
# bad
it 'checks a new review'
  review = Review.new(:rating => 9)

  review.rating.should eql(9)
  review.should be_valid
end

# good
context 'with a new review'
  subject { Review.new(:rating => 9) }

  it { should be_valid }
  its(:rating) { should eql(9) }
end
```

## Describing objects

```ruby
# bad
describe 'the authenticate method for User' do
describe 'if the user is an admin' do

# good
describe '.authenticate' do
describe '#admin?' do
```

## Using contexts

```ruby
# bad
it 'has 200 status code if logged in' do
  expect(response).to respond_with 200
end

it 'has 401 status code if not logged in' do
  expect(response).to respond_with 401
end

# good
context 'when logged in' do
  it { should respond_with 200 }
end

context 'when logged out' do
  it { should respond_with 401 }
end
```

## subject

- If you have several tests related to the same subject use subject{} to DRY them up.
- Make use of `its` to send messages to the `subject` and check its characteristics

```ruby
# bad
it { expect(assigns('message')).to match /it was born in Belville/ }
it { expect(assigns('message').creator).to match /Topolino/ }

# good
subject { assigns('message') }
it { should match /it was born in Billville/ }
its(:creator) { should match /Topolino/ }
```

## let

When you have to assign a variable instead of using a before block to create an instance variable, use let. Using let the variable lazy loads only when it is used the first time in the test and get cached until that specific test is finished.

```ruby
# bad
describe '#type_id' do
  before { @resource = FactoryGirl.create :device }
  before { @type     = Type.find @resource.type_id }

  it 'sets the type_id field' do
    expect(@resource.type_id).to == @type.id
  end
end

# good
describe '#type_id' do
  let(:resource) { FactoryGirl.create :device }
  let(:type)     { Type.find resource.type_id }

  it 'sets the type_id field' do
    resource.type_id.should eql(type.id)
  end
end
```

If you need something initialized immediately (e.g.: database records are involved) use `let!`, so that your object gets evaluated like it was in a `before` block.


## Mocks and stubs

- Never mock or stub stuff of the class you're testing
- Stub external dependencies

## Integration testing

Integration tests in Rspec live int the `spec/features` folder and need to be tagged with `:js => true` in order to be run with javascript support (PhantomJS via Poltergeist). Interaction with the page content should only be done through page objects which are stored in `spec/support/pages`. This enforces better encapsulation and enables reuse.

## Shared examples

TBD

## Custom matchers

TBD

## Test interface, not implementation

Test object inner workings and application behaviour (integration tests). If you are about to test a controller, stop and move away logic from it.

TBD

## Stub HTTP requests

TBD

## Other stuff

### Credits

Thanks to [@andreareginato](https://github.com/andreareginato) for [Better Specs](http://betterspecs.org/) which was a big inspiration for this style guide

### Licence

Copyright (c) 2013, HouseTrip

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.


