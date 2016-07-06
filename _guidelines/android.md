---
layout: guidelines
title: Android
collection: guidelines
published: true
---

# Java First

There's no denying an Android developer is first and foremost a Java developer. 

Be sure to check the [Java guidelines](/guide/java) first :)

# Android Always

## How we do backround operations

Although Android provides many ways to perform background operations to access network resources, read/write to the disk or other computationally-intensive tasks, at Deliveroo, we strive to keep up with current trends and best practices. One such trend is to use RxJava.

### Not your grandma's threading - the RxJava Manifesto

Move **away** from dealing with

- [Thread](https://developer.android.com/reference/java/lang/Thread.html)
- [AsyncTask](https://developer.android.com/reference/android/os/AsyncTask.html)
- [Loaders](https://developer.android.com/reference/android/content/Loader.html)

**Why?** Complexity. 

The _Androidy_ ways of dealing with complex operations have severe limitations. They lack compositional APIs, which make expressing background operations as a sequence of steps where inputs and outputs are passed on and transformed seamless from one step to the other.

Just imagine the simple task for fetching a JSON resource over the network, parse it, perform some other computations for each entry in parallel, then when everything is ready save the whole result to the disk. 

Let's not forget the mobile environment is prone to failures of many types from flaky networks to Android APIs and device fragmentation.

Without the power of composing and transforming these operations, while maintaining a fault-tolerant approach, meaning one operation can fail without failing the entire chain, it's a nightmare for any Android developer to deal with this task.

Threads, AsyncTaks and Loaders are a thing of the past. We, as modern developers, want to move away from _callback hell_ and _context switching_, into greener pastures where we have a uniform way of describing a series of tasks, how to transform and compose their results, how to handle successes and failures in a common place. 

Behold [RxJava](https://github.com/ReactiveX/RxJava).

### Brief introduction

There are thousands of resources out there describing RxJava in detail.

- [The Reactive Manifesto](http://www.reactivemanifesto.org/)
- [RxJava Wiki](https://github.com/ReactiveX/RxJava/wiki/Additional-Reading)
- [Dan Lew's blog of wisdom](http://blog.danlew.net/)
- [Introduction to Reactive](http://www.introtorx.com/)

RxJava relies heavily on the [Observer Pattern](https://en.wikipedia.org/wiki/Observer_pattern).

#### Observables

An `Observable` is an object whose state is of interest. Other objects may register themselves to be automatically notified of such changes. An Observable is similar to `Iterable` or `Stream`, where 0 to N events can occur, followed by a _complete event_. An _error event_ can occur at any time, also completing the Observable.

There are two types of Observables in RxJava

##### Non-blocking observables
- allows asynchronous execution of events
- can unsubscribe from it the at any moment

##### Blocking Observables
- using `BlockingObservable` subclass
- events are generated synchronously - there is no way to set up a Scheduler for a different thread
- cannot unsubscribe in the middle of an event stream 


**NOTES** 

- RxJava is **single-threaded** by default, but you can request Observables to execute on different threads using `subscribeOn` and `observeOn` methods.
- Along side execution on a different thread, RxJava also supports **parallel** execution of events


#### Observers

An `Observer` is an object that wishes to be notified when the state of another object changes. Observers **subscribe** themselves to an Observable and afterwards, any changes to that Observable are sent to the Observers as asynchronous notifications.

By themselvers, Observers are passive objects, meaning they don't take up any resources until they have an event to act upon. This is very important for a memory efficient event-driven application.

#### Subscriber

```java
public abstract class Subscriber<T> implements Observer<T>, Subscription {
	...
}
```

A `Subscriber` is a special case of Observer that handles subscription and un-subscription. Normally we don't have to deal directly with Subscribers, but there are cases where we want to handle unsubscribing events.

#### Subjects

A `Subject` is simulaneously an Observable and a Subscriber. 

- as a `Subscriber`, it receives events from other Observables. 
- as an `Observable`, it can choose to re-emit these events as its own.

A `Subject` exposes the `onNext()`, `onComplete()`, and `onError()` methods from its Observer part, which allow other objects to add events in its pipeline.

There are [four types](http://reactivex.io/documentation/subject.html) of Subjects:

- `PublishSubject` emits events to subscribers after the point of subscription; events emitted before that are not seen

- `BehaviorSubject` requires a _start state event_ and begins by emitting the most recent item from its source Observable (or a default value if none has been emitted) and continues to emit subsequent events; it is useful when we need to emit a **current state** to subscribers.

- `AsyncSubject` will only emit _the last event_ seen before the `onCompleted` call, all other events are consummed without being re-emitted; this is useful when we want to capture **only the final state** of a stream of events, not the intermediary ones

- `ReplaySubject` emits all events from its source Observable regardles when the Subscriber subscribed

#### Subscriptions

The result of calling `subscribe` on an Observable is a `Subscription`. It has a method called `unsubscribe` which can be called to disconnect the Observer from an Observable.

#### Schedulers

A `Scheduler` allows specifying the thread the Observable code will be executed on.

There are several pre-defined [Schedulers](http://reactivex.io/RxJava/javadoc/rx/schedulers/Schedulers.html) but the most frequently used ones are:

- `Schedulers.computation()` has a number of threads equal to the number of processing cores of the computer running on; useful for expensive computations
- `Schedulers.io()` used for long-running I/O processes like network communications or talking to the database; it's backed by a thread pool that will grow as needed
- `Schedulers.immediate()` executes the work immediately on the current thread
- `Schedulers.newTread()` creates a new Thead for each unit of work
- `Schedulers.test()` useful for debugging and tests as it allows _advancing the clock_ manually to observe the event flow


#### Creating Observables

// TODO

#### Transforming Observables

// TODO



// TODO

#### Android Lifecycle or 'Oh noes, Context is leaking'

// TODO
