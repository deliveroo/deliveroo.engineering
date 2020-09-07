---
layout: post
title:  "Increase the Reliability of a Go Codebase with Object Constructors"
authors:
  - "Tugberk Ugurlu"
excerpt: >
  One of the limitations of Go programming language is the lack of built-in object constructor 
  support. In this post, we will see how this can have a negative impact on the code we write 
  and how we can get around that by gluing together some of the existing language concepts.
---

Coming from a heavy production experience with languages such as C# and TypeScript, I must admit 
that my journey with Go has been a bumpy ride so far, but it's for sure a positive one overall. 
Go certainly shines in some parts such as its runtime efficiency, built-in 
tooling support and its simplicity which allows you to get up to speed with it so quickly! 
However, there are some areas where it limits your ability to express and model your 
software in code in a robust way, especially in a codebase where you get to work on as a team 
such as lack of [sum types](https://github.com/golang/go/issues/19412) and generics support (luckily, [generics support seems to be on its way](https://go.googlesource.com/proposal/+/master/design/go2draft-generics-overview.md)). 
One of these limitations I have come across is not [having any built-in constructor support](https://twitter.com/tourismgeek/status/1074325233220374528).

I stumbled upon this limitation while learning Go, but I was mostly being open-minded. After seeing a few of the 
problems which lack of constructors caused, I can see the value of constructors to be adopted in most Go codebases. 
In this post, I will share a solution that worked for our team, and the advantages of adopting such solution.

> I must give credit to [John Arundel](https://twitter.com/bitfield). Thanks to [the discussion we have had on Twitter](https://twitter.com/bitfield/status/1074637347193581568), I am able 
to express a solution to this problem here which is based on [what John made me aware of first](https://twitter.com/bitfield/status/1074682570389028866).

Now, when I say constructors in the title of the post here, I must confess that it’s a bit of a 
overstatement because I don’t see a way of having pure object constructors like we have with C# or Java in Go 
without changes in the language itself. However, we can work around the lack of constructors in 
Go by leveraging some other aspects of the language such as package scoping and interfaces and 
essentially [adopt the factory method pattern](https://en.wikipedia.org/wiki/Factory_method_pattern).

Let’s first touch on these two aspects of Go, and see how we can use them to our advantage to make our code 
more robust and protect against unexpected consumptions in the feature.

## Package Scoping
Go doesn’t have access modifiers such as private, internal or public per se. However, you can 
influence whether a type should be internal to a package or should be exposed through naming in 
Go respectively by "unexporting" or "exporting" them. When your type is named by starting with a
lowercase letter, it will only be available within the package itself. This rule also applies to the 
functions, and members of the types such as fields and methods.

For example, the following code sample does not compile:

`singers/jazzsinger.go` file:

```golang
package singers

type jazzSinger struct {
}

func (jazzSinger) Sing() string {
	return "Des yeux qui font baisser les miens"
}
```

`main.go` file:

```golang
package main

import (
	"fmt"
        "github.com/tugberkugurlu/go-package-scope/singers"
)

func main() {
	s := singers.jazzSinger{}
	fmt.Println(s.Sing())
}
```

If we were to run this code, we would get the following error:

```
➜  go-package-scope go run main.go
# command-line-arguments
./main.go:9:7: cannot refer to unexported name singers.jazzSinger
./main.go:9:7: undefined: singers.jazzSinger
```

This sort of demonstrates how package scoping works in Go. You can learn more about packages in 
Go from [Uday's great article on this topic](https://medium.com/rungo/everything-you-need-to-know-about-packages-in-go-b8bac62b74cc) 
but this should be enough for us to get going for our example.

## Interfaces
Let's now look at interfaces in Go, which act very similar to what you would expect them to be. However, the way you "implement" (in Go "satisfy") interfaces is very different to how you would do in C#, Java or TypeScript. The main difference is that you don’t explicitly declare that a struct implements an interface in Go. A struct is considered to be satisfying an interface by the compiler as long as it provides all the methods within it with matching signatures, or in the Go terminology, as long as the ["method set"](https://golang.org/ref/spec#Method_sets) of the type can satisfy the interface requirements. Let’s look at the following example:

```golang
package main

import (
	"fmt"
)

type Singer interface {
	Sing() string
}

type jazzSinger struct {
}

func (jazzSinger) Sing() string {
	return "Des yeux qui font baisser les miens"
}

func main() {
	s := jazzSinger{}
	singToConsole(s)
}

func singToConsole(singer Singer) {
	fmt.Println(singer.Sing())
}
```

[This code happily executes](https://play.golang.org/p/LvZzuzSDB9B). Notice that jazzSinger 
struct doesn’t say anything about implementing the Singer interface. This is what’s called 
[structural typing](https://en.wikipedia.org/wiki/Structural_type_system), as opposed to 
[nominal typing](https://en.wikipedia.org/wiki/Nominal_type_system) like one of C#’s 
characteristics (see the diff [here](https://medium.com/@thejameskyle/type-systems-structural-vs-nominal-typing-explained-56511dd969f4)). 

We can understand from this that Go has a way to abstract away the implementation and this fact 
will hugely help us when it comes to work around the lack of constructors in Go.

## Bringing All These Together

These two aspects of the language can be brought together to allow us to hide the implementation 
from the contract by only exposing what we need. The challenge here is to be able to provide a 
way to construct the implementation. Fortunately, there is a workaround for this in Go: we can 
define an exported function within the package, which has access to the internal implementation, 
but also exposes it through the interface, as shown in the example below:

```golang
package singers

type Singer interface {
	Sing() string
}

type jazzSinger struct {
}

func (jazzSinger) Sing() string {
	return "Des yeux qui font baisser les miens"
}

func NewJazzSinger() Singer {
	return jazzSinger{}
}
```

`NewJazzSinger` function here can be accessed by the package consumer but jazzSinger struct is still hidden.

```golang
package main

import (
	"fmt"
	"github.com/tugberkugurlu/go-package-scope/singers"
)

func main() {
	s := singers.NewJazzSinger()
	singToConsole(s)
}

func singToConsole(singer singers.Singer) {
	fmt.Println(singer.Sing())
}
```

Why is this good and how does this make our code more reliable? Let's go over the main advantages of this 
technique, and how they make our code more reliable.

### Changes in the struct's fields would make our code fail at compile time, rather than runtime

Unlike other languages (such as TypeScript), Go doesn't have a way to enforce assigning fields directly 
(omitted fields default to the zero value, which may not always be what you want) - so the compiler 
would not help us here - we would need to track all updates to the struct's fields manually, which is 
tedious and error prone (specially in large codebases). Best case scenario, the code would be well tested 
and the unit tests would break. Worst case scenario, the code would blow up at Runtime, which would require 
a rollback of this release. To make matters worse, your application could be happily working without any 
crashes, but the its behaviour could be wrong due to the way the implementation might work. This one is 
the hardest and potentially harmful bugs to catch as it could have a larger impact on your efforts and 
the outcome you wanted to achieve in the first place.

Let's imagine our `jazzSinger` would start getting lyrics from an external resource. You would structure this by providing an interface and allowing jazzSinger to call into that, which would look like the following snippet/example:

```golang
package singers

// Lyrics

type LyricsProvider interface {
	GetRandom() string
}

type jazzLyricsProvider struct {
}

func (jazzLyricsProvider) GetRandom() string {
	return "Des yeux qui font baisser les miens"
}

func NewJazzLyricsProvider() LyricsProvider {
	return jazzLyricsProvider{}
}

// Singer

type Singer interface {
	Sing() string
}

type jazzSinger struct {
	lyrics LyricsProvider
}

func (js jazzSinger) Sing() string {
	return js.lyrics.GetRandom() 
}

func NewJazzSinger(lyrics LyricsProvider) Singer {
	return jazzSinger{
		lyrics: lyrics,
	}
}
```

If we were to build our application directly without modifying the main package (which is the consumer of the singers package), we would see the following error:

```
➜  go-package-scope go build main.go 
# command-line-arguments
./main.go:9:28: not enough arguments in call to singers.NewJazzSinger
	have ()
	want (singers.LyricsProvider)
```

We wouldn't get this level of feedback if we were to initialize the struct directly. What we would get instead is a failure:

```
➜  go-package-scope go run main.go  
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x18 pc=0x1091512]

goroutine 1 [running]:
github.com/tugberkugurlu/go-package-scope/singers.JazzSinger.Sing(0x0, 0x0, 0x1010095, 0xc00000e1e0)
	/Users/tugberkugurlu/go/src/github.com/tugberkugurlu/go-package-scope/singers/jazzsinger.go:31 +0x22
main.singToConsole(0x10d7520, 0xc00000e1e0)
	/Users/tugberkugurlu/go/src/github.com/tugberkugurlu/go-package-scope/main.go:14 +0x35
main.main()
	/Users/tugberkugurlu/go/src/github.com/tugberkugurlu/go-package-scope/main.go:10 +0x57
exit status 2
```

### Allows you to provide parameter validation as early as possible 

Enforcing parameter validation also allows the consumer to explicitly act on potential errors. 
I must be honest here, we mostly need this level of validation due to Go's inability to enforce nil pointer check before accessing the value, which is provided in languages like TypeScript. [My post on TypeScript](https://www.telerik.com/blogs/uncovering-typescript-for-c-developers#no-more-billion-dollar-mistakes-protection-against-null-and-undefined) demonstrates what I mean by this. However, there are genuinely other cases where a compiler cannot guard against your own 
business logic. In our example above, we can still make our code compile successfully with 
the constructor implementation but get a runtime error:

```golang
package main

import (
	"fmt"
	"github.com/tugberkugurlu/go-package-scope/singers"
)

func main() {
	s := singers.NewJazzSinger(nil)
	singToConsole(s)
}

func singToConsole(singer singers.Singer) {
	fmt.Println(singer.Sing())
}
```

When we run we see the error below - even though the code compiled successfully:

```
➜  go-package-scope go build main.go
➜  go-package-scope ./main 
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x18 pc=0x1091512]

goroutine 1 [running]:
github.com/tugberkugurlu/go-package-scope/singers.jazzSinger.Sing(0x0, 0x0, 0x1010095, 0xc00008e030)
	/Users/tugberkugurlu/go/src/github.com/tugberkugurlu/go-package-scope/singers/jazzsinger.go:31 +0x22
main.singToConsole(0x10d75a0, 0xc00008e030)
	/Users/tugberkugurlu/go/src/github.com/tugberkugurlu/go-package-scope/main.go:14 +0x35
main.main()
	/Users/tugberkugurlu/go/src/github.com/tugberkugurlu/go-package-scope/main.go:10 +0x5c
```

There isn't a solution available in Go as far as I am aware which would allow us to fail for these cases during compilation. However, thanks to the dedicated constructor for this object, we can explicitly signal potential construction errors by returning multiple values from the function call:

```golang
func NewJazzSinger(lyrics LyricsProvider) (Singer, error) {
	if lyrics == nil {
		return nil, errors.New("lyrics cannot be nil")
	}
	return jazzSinger{
		lyrics: lyrics,
	}, nil
}
```

At the time of consumption, it becomes very explicit to deal with returned result:

```golang
s, err := singers.NewJazzSinger(nil)
if err != nil {
	log.Fatal(err)
}
// ...
```

### Allows you to control the flow of your implementation

The code below is a simplified and intended-use scenario of an interesting bug we had in production a while ago:

```golang
package main

import (
	"fmt"
)

type JazzSinger struct {
	count int
}

func (j *JazzSinger) Sing() string {
	j.count++
	return "Des yeux qui font baisser les miens"
}

func (j *JazzSinger) Count() int {
	return j.count
}

func main() {
	s := &JazzSinger{}
	singToConsole(s)
	fmt.Println(s.Count())
	singToConsole(s)
	fmt.Println(s.Count())
}

func singToConsole(singer *JazzSinger) {
	fmt.Println(singer.Sing())
}
```

This code works as expected: the singer sings, and the count is incremented. All great!

```
Des yeux qui font baisser les miens
1
Des yeux qui font baisser les miens
2
```

This works because our method signature on the `JazzSinger` struct accepts a pointer to an instance of `JazzSinger` which 
means that the count will be incremented as expected even if the type is passed around, and that's what's happening with 
the above scenario. 

However, can we guess what will happen if we change our usage as below:

```golang
func main() {
	s := JazzSinger{}
	singToConsole(s)
	fmt.Println(s.Count())
	singToConsole(s)
	fmt.Println(s.Count())
}

func singToConsole(singer JazzSinger) {
	fmt.Println(singer.Sing())
}
```

My first guess was that compiler will would here, and this is a perfectly reasonable assumption to make 
since we are not passing a pointer to `Sing` method call. If you made the same assumption as I did, you would be 
wrong. This compiles perfectly but it won't work as expected:

```
Des yeux qui font baisser les miens
0
Des yeux qui font baisser les miens
0
```

The worst part is that this would actually work if we were to get rid of the `singToConsole` function and embed its implementation:

```golang
func main() {
	s := JazzSinger{}
	s.Sing()
	fmt.Println(s.Count())
	s.Sing()
	fmt.Println(s.Count())
}
```

```
Des yeux qui font baisser les miens
1
Des yeux qui font baisser les miens
2
```

This is the exact reason why your tests will pass even if they have the wrong usage!

```golang
package main

import (
	"github.com/deliveroo/assert-go"
	"testing"
)

func TestJazzSinger(t *testing.T) {
	t.Run("count increments as expected", func(t *testing.T) {
		singer := JazzSinger{}
		singer.Sing()
		singer.Sing()
		assert.Equal(t, singer.Count(), 2)
	})
}
```

```
➜  jazz-singer git:(master) ✗ go test -v
=== RUN   TestJazzSinger
=== RUN   TestJazzSinger/count_increments_as_expected
--- PASS: TestJazzSinger (0.00s)
    --- PASS: TestJazzSinger/count_increments_as_expected (0.00s)
PASS
ok  	github.com/tugberkugurlu/algos-go/jazz-singer	0.549s
```

After a bit more digging, it turned out that this is actually the intended behavior of Go, and it's 
even [documented in its spec](https://golang.org/ref/spec#Calls):

> A method call x.m() is valid if the method set of (the type of) x contains m and the argument list can be assigned to the parameter list of m. If x is addressable and &x's method set contains m, x.m() is shorthand for (&x).m().

I am still unsure why this could be useful, but it is what it is, and it's so easy to make the same mistake since you can ensure how 
the consumer will flow the type as the creator of the type if it can be constructed freely. In fact, the decision of how the type 
should be flowed should be the decision of the owner (i.e. its package) of the type, not the consumer, and I have never found a case 
where I needed to flow a type both as a pointer or value. Languages like C# puts the burden of this choice onto the author of the 
type by forcing them to choose between a `class` and `struct`.

In Go, you can make this safer through the use of the constructor pattern as well, by ensuring that your struct is not allowed to be constructed directly and you controlling how the initialized value should be flowed.

```golang
package singers

type Singer interface {
	Sing()  string
	Count() int
}

type jazzSinger struct {
	count int
}

func (j *jazzSinger) Sing() string {
	j.count++
	return "Des yeux qui font baisser les miens"
}

func (j *jazzSinger) Count() string {
	return j.count
}

func NewJazzSinger() Singer {
	return &jazzSinger{}
}
```

The consumer of this type needs to construct it through `NewJazzSinger` function here, which is making the decision to flow the type as a pointer because it needs to be able to mutate its own state as it's being used.

```golang
package main

import (
	"fmt"
	"github.com/tugberkugurlu/go-package-scope/singers"
)

func main() {
	s := singers.NewJazzSinger()
	singToConsole(s)
	fmt.Println(s.Count())
	singToConsole(s)
	fmt.Println(s.Count())
}

func singToConsole(singer singers.Singer) {
	fmt.Println(singer.Sing())
}
```

## Conclusion

Modelling your domain is hard and it's even harder if you have rich models which hold a mutable state 
along with explicit behaviours. Go programming language may may not give you all the tools to directly 
model your domain in a rich way as some other programming languages provide. However, it's still 
possible to make it work for some cases by adopting some usage principles. 
Constructor pattern is one of them, and it has been one of the most 
useful ones for me since I can confidently encapsulate the initialisation logic of my model by enforcing 
state validity within a package scope.
