---
layout:     guidelines
title:      "Ruby Style Guide"
subtitle:   "Guidelines for writing Ruby"
collection: guidelines
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## About the style guide

This Ruby style guide recommends best practices so that real-world Ruby
programmers can write code that can be maintained by other real-world Ruby
programmers. A style guide that reflects real-world usage gets used, and a
style guide that holds to an ideal that has been rejected by the people it is
supposed to help risks not getting used at all &ndash; no matter how good it
is.

This guide is largely based upon Bozhidar Batsov’s 
[Ruby Style Guide][ruby-style-guide], based on feedback and suggestions from 
members of the Ruby community and various highly regarded Ruby programming 
resources, such as Programming Ruby 1.9[^programming-ruby] and 
The Ruby Programming Language[^the-ruby-programming-language].

[ruby-style-guide]: https://github.com/bbatsov/ruby-style-guide
[^programming-ruby]: [Programming Ruby 1.9](http://pragprog.com/book/ruby4/programming-ruby-1-9-2-0)
[^the-ruby-programming-language]: [The Ruby Programming Language](http://www.amazon.com/Ruby-Programming-Language-David-Flanagan/dp/0596516177)


## Formatting

> Nearly everybody is convinced that every style but their own is
> ugly and unreadable. Leave out the "but their own" and they're
> probably right...
>
> -- Jerry Coffin (on indentation)


### Indent with spaces
{: #indent-spaces}

Use `UTF-8` as the source file encoding. Use two **spaces** per indentation level. No hard tabs.

```ruby
# bad - four spaces
def some_method
    do_something
end

# good
def some_method
  do_something
end
```


### Line endings

Use Unix-style line endings (BSD/Solaris/Linux/OSX users are covered by 
default, Windows users have to be extra careful). You can add the following [git
configuration][git-autocrlf] setting to protect your project from Windows line 
endings creeping in:
{: #line-endings}

```
$ git config --global core.autocrlf true
```

Avoid trailing whitespace at the end of lines.

[git-autocrlf]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration#coreautocrlf-7kTgIgFwI4


### Separating statements and expressions
{: #separating-statements}

Don't use `;` to separate statements and expressions. As a corollary - use one 
expression per line.

```ruby
# bad
puts 'foobar'; # superfluous semicolon

puts 'foo'; puts 'bar' # two expression on the same line

# good
puts 'foobar'

puts 'foo'
puts 'bar'

puts 'foo', 'bar' # this applies to puts in particular
```

Prefer a single-line format for class definitions with no body.

```ruby
# bad
class FooError < StandardError
end

# okish
class FooError < StandardError; end

# good
FooError = Class.new(StandardError)
```

Avoid single-line methods. Although they are somewhat popular in the wild, 
there are a few peculiarities about their definition syntax that make their use
undesirable. At any rate - there should be no more than one expression in a
single-line method.

```ruby
# bad
def too_much; something; something_else; end

# okish - notice that the first ; is required
def no_braces_method; body end

# okish - notice that the second ; is optional
def no_braces_method; body; end

# okish - valid syntax, but no ; make it kind of hard to read
def some_method() body end

# good
def some_method
  body
end
```

One exception to the rule are empty-body methods.

```ruby
# good
def no_op; end
```


### Spaces around symbols

Use spaces around operators, after commas, colons and semicolons, around `{`
and before `}`. Whitespace might be (mostly) irrelevant to the Ruby 
interpreter, but its proper use is the key to writing easily readable code.

```ruby
sum = 1 + 2
a, b = 1, 2
1 > 2 ? true : false; puts 'Hi'
[1, 2, 3].each { |e| puts e }
```

The only exception, regarding operators, is the exponent operator:

```ruby
# bad
e = M * c ** 2

# good
e = M * c**2
```

No spaces after `(`, `[` or before `]`, `)`.

```ruby
some(arg).other
[1, 2, 3].length
```

`{` and `}` deserve a bit of clarification, since they are used for block and 
hash literals, as well as embedded expressions in strings. For hash literals 
two styles are common:

```ruby
# less readable
{one: 1, two: 2}

# better
{ one: 1, two: 2 }
```

The second variant is slightly more readable (and arguably more popular in the 
Ruby community in general) and should be used over the first.

As far as embedded expressions go, there are also two common options:

```ruby
# ok
"string#{ expr }"

# better - no spaces
"string#{expr}"
```

The second style is more popular and should be preferred.

Use spaces around the `=` operator when assigning default values to method 
parameters:

```ruby
# bad
def some_method(arg1=:default, arg2=nil, arg3=[])
  # do something...
end

# good
def some_method(arg1 = :default, arg2 = nil, arg3 = [])
  # do something...
end
```

While several Ruby books suggest the first style, the second is much more 
prominent in practice (and arguably a bit more readable).


### Indentation levels

Indent `when` as deep as `case`. Whilst many would disagree with this one, it's
the style established in both _Programming Ruby_ [^programming-ruby] and 
_The Ruby Programming Language_ [^the-ruby-programming-language] .

```ruby
case
when song.name == 'Misty'
  puts 'Not again!'
when song.duration > 120
  puts 'Too long!'
when Time.now.hour > 21
  puts "It's too late"
else
  song.play
end

kind = case year
       when 1850..1889 then 'Blues'
       when 1890..1909 then 'Ragtime'
       when 1910..1929 then 'New Orleans Jazz'
       when 1930..1939 then 'Swing'
       when 1940..1950 then 'Bebop'
       else 'Jazz'
       end
```

Indent the parameters of a method call if they span more than one line.

```ruby
# starting point (line is too long)
def send_mail(source)
  Mailer.deliver(to: 'bob@example.com', from: 'us@example.com', subject: 'Important message', body: source.text)
end

# bad (double indent)
def send_mail(source)
  Mailer.deliver(
      to: 'bob@example.com',
      from: 'us@example.com',
      subject: 'Important message',
      body: source.text)
end

# bad (aligning indent)
def send_mail(source)
  Mailer.deliver(to: 'bob@example.com',
                 from: 'us@example.com',
                 subject: 'Important message',
                 body: source.text)
end

# good (normal indent)
def send_mail(source)
  Mailer.deliver(
    to: 'bob@example.com',
    from: 'us@example.com',
    subject: 'Important message',
    body: source.text
  )
end
```


### Empty lines

Use empty lines between `def`s and to break up a method into logical 
paragraphs. Using two empty lines between methods is also recommended for 
visually distinguishing them from individual sections of a particular method:

```ruby
def some_method
  data = initialize(options)

  data.manipulate!

  data.result
end


def some_method
  result
end
```

Avoid line continuation `\` where not required. In practice, avoid using line 
continuations at all.

```ruby
# bad
result = 1 - \
         2

# good (but still ugly as hell)
result = 1 \
         - 2
```


### Optimise readability

Add underscores to large numeric literals to improve their readability.

```ruby
# bad - how many 0s are there?
num = 1000000

# good - much easier to parse for the human brain
num = 1_000_000
```

Limit lines to 100 characters, but try to keep them inside 80 characters where possible. This restriction is intended to encourage vertical readability[^bbatsov-ruby-linelength] rather than simply to make text fit inside a smaller editor window.

[^bbatsov-ruby-linelength]: [The Elements of Style in Ruby #1: Maximum Line Length](http://batsov.com/articles/2013/06/26/the-elements-of-style-in-ruby-number-1-maximum-line-length/)

### Documentation
{: #documentation-comments}

Use YARD and its conventions for API documentation.  Don't put an empty line
between the comment block and the `def`.


### Comments
{: #ruby-comments}

Don't use block comments. They cannot be preceded by whitespace and are not as
easy to spot as regular comments.

```ruby
# bad
== begin
comment line
another comment line
== end

# good
# comment line
# another comment line
```

## Syntax

Use `::` only to reference constants(this includes classes and modules). Never 
use `::` for method invocation:

```ruby
# bad
SomeClass::some_method
some_object::some_method

# good
SomeClass.some_method
some_object.some_method
SomeModule::SomeClass::SOME_CONST
```

Use `def` with parentheses when there are arguments. Omit the parentheses when
the method doesn't accept any arguments:

```ruby
# bad
def some_method()
 # body omitted
end

# good
def some_method
 # body omitted
end

# bad
def some_method_with_arguments arg1, arg2
 # body omitted
end

# good
def some_method_with_arguments(arg1, arg2)
 # body omitted
end
```

### Iterators
{: #ruby-iterators}

Never use `for`, unless you know exactly why. Most of the time iterators should
be used instead. `for` is implemented in terms of `each` (so you're adding a 
level of indirection), but with a twist - `for` doesn't introduce a new scope 
(unlike `each`) and variables defined in its block will be visible outside it.

```ruby
arr = [1, 2, 3]

# bad
for elem in arr do
  puts elem
end

# good
arr.each { |elem| puts elem }
```

### Control Flow

Never use `then` for multi-line `if/unless`:

```ruby
# bad
if some_condition then
  # body omitted
end

# good
if some_condition
  # body omitted
end
```

Favor the ternary operator(`?:`) over `if/then/else/end` constructs. It's more
common, and obviously more concise:

```ruby
# bad
result = if some_condition then something else something_else end

# good
result = some_condition ? something : something_else
```

Use one expression per branch in a ternary operator. This also means that 
ternary operators must not be nested. Prefer `if/else` constructs in these 
cases:

```ruby
# bad
some_condition ? (nested_condition ? nested_something : nested_something_else) : something_else

# good
if some_condition
  nested_condition ? nested_something : nested_something_else
else
  something_else
end
```

Never use `if x: ...` - as of Ruby 1.9 it has been removed. Use the ternary 
operator instead:

```ruby
# bad
result = if some_condition: something else something_else end

# good
result = some_condition ? something : something_else
```

Never use `if x; ...`. Use the ternary operator instead.

Use `when x then ...` for one-line cases. The alternative syntax `when x: ...`
has been removed as of Ruby 1.9.

Never use `when x; ...`. See the previous rule.

Use `!` instead of `not`:

```ruby
# bad - braces are required because of op precedence
x = (not something)

# good
x = !something
```

The `and` and `or` keywords are banned. It's just not worth it. Always use `&&`
and `||` instead:

```ruby
# bad
# boolean expression
if some_condition and some_other_condition
  do_something
end

# control flow
document.saved? or document.save!

# good
# boolean expression
if some_condition && some_other_condition
  do_something
end

# control flow
document.saved? || document.save!
```

Avoid multi-line `?:` (the ternary operator); use `if/unless` instead.

Favor modifier `if/unless` usage when you have a single-line body. Another good
alternative is the usage of control flow `&&/||`:

```ruby
# bad
if some_condition
  do_something
end

# good
do_something if some_condition

# another good option
some_condition && do_something
```

Favor `unless` over `if` for negative conditions (or control flow `||`):

```ruby
# bad
do_something if !some_condition

# bad
do_something if not some_condition

# good
do_something unless some_condition

# another good option
some_condition || do_something
```

Never use `unless` with `else`. Rewrite these with the positive case first:

```ruby
# bad
unless success?
  puts 'failure'
else
  puts 'success'
end

# good
if success?
  puts 'success'
else
  puts 'failure'
end
```

Don't use parentheses around the condition of an `if/unless/while/until`:

```ruby
# bad
if (x > 10)
  # body omitted
end

# good
if x > 10
  # body omitted
end
```

Favor modifier `while/until` usage when you have a single-line body:

```ruby
# bad
while some_condition
  do_something
end

# good
do_something while some_condition
```

Favor `until` over `while` for negative conditions:

```ruby
# bad
do_something while !some_condition

# good
do_something until some_condition
```

Use `Kernel#loop` with break rather than `begin/end/until` or `begin/end/while`
for post-loop tests:

```ruby
# bad
begin
 puts val
 val += 1
end while val < 0

# good
loop do
 puts val
 val += 1
 break unless val < 0
end
```

Omit parentheses around parameters for methods that are part of an internal DSL
(e.g. Rake, Rails, RSpec), methods that have "keyword" status in Ruby (e.g. 
`attr_reader`, `puts`) and attribute access methods. Use parentheses around the
arguments of all other method invocations:

```ruby
class Person
  attr_reader :name, :age

  # omitted
end

temperance = Person.new('Temperance', 30)
temperance.name

puts temperance.age

x = Math.sin(y)
array.delete(e)

bowling.score.should == 0
```

Omit parentheses for method calls with no arguments:

```ruby
# bad
Kernel.exit!()
2.even?()
fork()
'test'.upcase()

# good
Kernel.exit!
2.even?
fork
'test'.upcase
```

Prefer `{...}` over `do...end` for single-line blocks.  Avoid using `{...}` for
multi-line blocks (multiline chaining is always ugly). Always use `do...end` 
for "control flow" and "method definitions" (e.g. in Rakefiles and certain 
DSLs).  Avoid `do...end` when chaining:

```ruby
names = ['Bozhidar', 'Steve', 'Sarah']

# bad
names.each do |name|
  puts name
end

# good
names.each { |name| puts name }

# bad
names.select do |name|
  name.start_with?('S')
end.map { |name| name.upcase }

# good
names.select { |name| name.start_with?('S') }.map { |name| name.upcase }
```

Some will argue that multiline chaining would look OK with the use of `{...}`,
but they should ask themselves - is this code really readable and can the 
blocks' contents be extracted into nifty methods?

Avoid `return` where not required for flow of control:

```ruby
# bad
def some_method(some_arr)
  return some_arr.size
end

# good
def some_method(some_arr)
  some_arr.size
end
```

### Using `self`
{:#using-self}

Avoid `self` where not required (it is only required when calling a self
write accessor):

```ruby
# bad
def ready?
  if self.last_reviewed_at > self.last_updated_at
    self.worker.update(self.content, self.options)
    self.status = :in_progress
  end
  self.status == :verified
end

# good
def ready?
  if last_reviewed_at > last_updated_at
    worker.update(content, options)
    self.status = :in_progress
  end
  status == :verified
end
```

As a corollary, avoid shadowing methods with local variables unless they are
both equivalent:

```ruby
class Foo
  attr_accessor :options

  # ok
  def initialize(options)
    self.options = options
    # both options and self.options are equivalent here
  end

  # bad
  def do_something(options = {})
    unless options[:when] == :later
      output(self.options[:message])
    end
  end

  # good
  def do_something(params = {})
    unless params[:when] == :later
      output(options[:message])
    end
  end
end
```

### Assignments

Don't use the return value of `=` (an assignment) in conditional expressions:

```ruby
# bad (+ a warning)
if (v = array.grep(/foo/))
  do_something(v)
  ...
end

# bad (+ a warning)
if v = array.grep(/foo/)
  do_something(v)
  ...
end

# good
v = array.grep(/foo/)
if v
  do_something(v)
  ...
end
```

Use `||=` freely to initialize variables:

```ruby
# set name to Bozhidar, only if it's nil or false
name ||= 'Bozhidar'
```

Don't use `||=` to initialize boolean variables. (Consider what would happen if
the current value happened to be `false`.)

```ruby
# bad - would set enabled to true even if it was false
enabled ||= true

# good
enabled = true if enabled.nil?
```

Avoid explicit use of the case equality operator `===`. As its name implies 
it's meant to be used implicitly by `case` expressions and outside of them it 
yields some pretty confusing code:

```ruby
# bad
Array === something
(1..100) === 7
/something/ === some_string

# good
something.is_a?(Array)
(1..100).include?(7)
some_string =~ /something/
```

`TODO: find a home for this`:
Avoid using Perl-style special variables (like `$0-9`, `$`, etc.). They are 
quite cryptic and their use in anything but one-liner scripts is discouraged:

```ruby
# TODO: example?
```

### Method invocation

Never put a space between a method name and the opening parenthesis:

```ruby
# bad
f (3 + 2) + 1

# good
f(3 + 2) + 1
```

If the first argument to a method begins with an open parenthesis, always use
parentheses in the method invocation. For example, write `f((3 + 2) + 1)`.

Always run the Ruby interpreter with the `-w` option so it will warn you if you
forget either of the rules above!

Use the new lambda literal syntax for single line body blocks. Use the `lambda`
method for multi-line blocks:

```ruby
# bad
l = lambda { |a, b| a + b }
l.call(1, 2)

# correct, but looks extremely awkward
l = ->(a, b) do
  tmp = a * 7
  tmp * b / 50
end

# good
l = ->(a, b) { a + b }
l.call(1, 2)

l = lambda do |a, b|
  tmp = a * 7
  tmp * b / 50
end
```

Prefer `proc` over `Proc.new`:

```ruby
# bad
p = Proc.new { |n| puts n }

# good
p = proc { |n| puts n }
```

Use `_` for unused block parameters:

```ruby
# bad
result = hash.map { |k, v| v + 1 }

# good
result = hash.map { |_, v| v + 1 }
```

Use `$stdout/$stderr/$stdin` instead of `STDOUT/STDERR/STDIN`. 
`STDOUT/STDERR/STDIN` are constants, and while you can actually reassign 
(possibly to redirect some stream) constants in Ruby, you'll get an interpreter
warning if you do so.

Use `warn` instead of `$stderr.puts`. Apart from being more concise and clear,
`warn` allows you to suppress warnings if you need to (by setting the warn 
level to 0 via `-W0`).

### Favour Object-Orientism
{: #object-orientism}

Favour the use of `String#%` over not-so-Rubyish `sprintf`:

```ruby
# bad
sprintf('%{count} unicorns', { count: 11 })
# => '11 unicorns'

# good
'%{count} unicorns' % { count: 11 }
# => '11 unicorns'
```

Favor the use of `Array#join` over the fairly cryptic `Array#*` with a string 
argument:

```ruby
# bad
%w(one two three) * ', '
# => 'one, two, three'

# good
%w(one two three).join(', ')
# => 'one, two, three'
```

### Type checking

Use `[*var]` or `Array()` instead of explicit `Array` check, when dealing with
a variable you want to treat as an Array, but you're not certain it's an array:

```ruby
# bad
paths = [paths] unless paths.is_a? Array
paths.each { |path| do_something(path) }

# good
[*paths].each { |path| do_something(path) }

# good (and a bit more readable)
Array(paths).each { |path| do_something(path) }
```

Use ranges instead of complex comparison logic when possible:

```ruby
# bad
do_something if x >= 1000 && x < 2000

# good
do_something if (1000...2000).include?(x)
```
