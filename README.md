# HouseTrip RSpec Style Guide

## Table of contents

1. [Code organization](#code-organization)

### Code organization

- In a context, define `before` blocks, then `let` blocks, then leave a blank line and start defining assertions.
- If you have a subject for the context place it between pre-definitions and assertions, again with a blank line

```ruby
context 'with a photo' do
  before { initialize_stuff }
  let(:review) { Review.new }

  subject { review }

  it { should be_blank }
  its(:rating) { should be_nil }
end
```

### describe

```ruby
# good
describe 'the authenticate method for User' do
describe 'if the user is an admin' do

# bad
describe '.authenticate' do
describe '#admin?' do
```

### context

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
