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
