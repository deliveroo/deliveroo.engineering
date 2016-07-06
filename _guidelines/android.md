---
layout: guidelines
title: Android
collection: guidelines
published: true
---
## How we do background operations.

Although Android provides many ways to perform background operations to access network resources, read/write to the disk or other computationally-intensive tasks, at Deliveroo, we strive to keep up with current trends and best practices. One such trend is to use RxJava.

## Not your grandma's threading [RxJava manifesto]

Move **away** from dealing with
- [Thread](https://developer.android.com/reference/java/lang/Thread.html)
- [AsyncTask](https://developer.android.com/reference/android/os/AsyncTask.html)
- [Loaders](https://developer.android.com/reference/android/content/Loader.html)

**Why?**
Complexity. The _Androidy_ ways of dealing with complex operations have severe limitations. They lack compositional APIs, which make expressing background operations as a sequence of steps where inputs and outputs are passed on and transformed seamless from one step to the other.

Just imagine the simple task for fetching a JSON resource over the network, parse it, perform some other computations for each entry in parallel, then when everything is ready save the whole result to the disk. 

Let's not forget the mobile environment is prone to failures of many types from flaky networks to Android APIs and device fragmentation.

Without the power of composing and transforming these operations, while maintaining a fault-tolerant approach, meaning one operation can fail without failing the entire chain, it's a nightmare for any Android developer to deal with this task.

Threads, AsyncTaks and Loaders are a thing of the past. We, as modern developers, want to move away from _callback hell_ and _context switching_, into greener pastures where we have a uniform way of describing a series of tasks, how to transform and compose their results, how to handle successes and failures in a common place. Behold [RxJava](https://github.com/ReactiveX/RxJava).

## Brief introduction into main concepts

// TODO

## Creating Observables

// TODO

## Subscriptions

// TODO

## Android Lifecycle or 'Oh noes, Context is leaking'

// TODO
