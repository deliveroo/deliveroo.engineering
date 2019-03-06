---
layout: post
title:  "Shipping Quickly with a Large Team"
authors:
  - "Phil Hack"
excerpt: >
    We will walk through some proven techniques that we used to ship greenfield software quickly with a large team. 
---

We came up against a situation where we need to build a greenfield app, had tight deadlines, and had 7 engineers available. Amazing! there are 7 engineers available!... now how can we work effectively?
  
Should we adhere to the [two pizza rule](http://blog.idonethis.com/two-pizza-team/), where a team should not be larger than what two pizzas can feed? This is backed by science and is an great rule to follow. However, if we followed it, our team size would be 2-3 since I can eat an entire pizza myself. So we stepped back and thought about how can we meet the requirements and delivery this quickly, effectively, and have all 7 engineers contributing. 


We shipped the product on time with all 7 engineers contributing. These were some techniques we used.

## Design an architecture
We needed a dashboard which users could login, interact with to perform specific business functions. The architecture should allow for future internal system to interact with it. It needs to scale. 

To minimize merge conflicts, allow for reuse, and build for scale, we elected to create two apps that both deployed independently and lived in separate git repositories.

<figure class="small">
![Simplified Architecture Diagram](/images/posts/shipping-quickly-with-a-large-team/architecture-diagram.png)
</figure> 

### Dashboard
We built the React front end which sat on top of a thin NodeJS proxy. 
Utilizing middleware meant that we didn't have to write any mapping code.
  
This proxy routed requests to our internal API and provided a layer of security. It would validate the JWT’s against our identity server, as well as pass authenticated requests that passed a whitelist through to an API.
Using the approach also meant that we wrote less code since we didn't need to write any object mappers.


### Internal API
We built an internal API in [Go](https://golang.org/). This served as both the home for the domain logic, kafka event consumers and producer, and allowed other systems in the business to be able to consume this API in the future.

Once we had determined this was the direc

## Establish patterns
Before having the whole team start delivering features, it’s important to carve out some patterns.

With the react front end, we decided to use [redux](https://redux.js.org), [axios](https://github.com/axios/axios), [http-proxy-middleware](https://github.com/chimurai/http-proxy-middleware), and [jest](https://jestjs.io). We carved out some patterns for making an API call, redux actions, reducer, and selectors.

On the Go API, we also set up some patterns including how we structure the API, http handlers, authentication, database access, api client pattern, and kafka consumers.

Once we had these patterns in place, more engineers start building features.

## Pair Program
Pairing can be highly effective. When a developer pairs, they get a built in design review, code review, and shared context. When one member is on holiday or ill, the task can still be worked on. Our team also determines when certain tasks can be split up and worked on in parrallel without paring: a divide and conquer approach.  

## Avoiding Merge Conflicts
We had a situation where we need to build out three aggregators, that consumed information from another API, aggregated it, and surfaced it in a specific way. This was actually core to the business logic of the app. We used the output the aggregators in business logic and to surface back up to the client.

We struggled with 2 things:
How do we name these “aggregators”?
This is a critical piece to get done and each one of these delivers a vertical feature slice that our end users will be able to see and start to use. How can we get 6 devs working effectively on building these?

We addressed this in 2 ways:
We weren’t sure what exactly to name them. We had good ideas, but they didn’t seem quite right. So we derferend the decision.
We deferred it by creating 3 jira tickets, JIRA-111, JIRA-222, JIRA-333 with all of the details required to implement them.
We established a pattern and an interface in go
We created individual interfaces in individual files. We named each file after the ticket number.
All of the aggregators relied on a specific API client to consume the data, so we built that client ahead of time and used dependency injection to pass it into the aggregators.


**aggregator.go**
```go
type Aggregator interface {
  PAY111
  PAY222
  PAY333 
}
```

**pay111.go**
```go
type PAY111 interface {
	GetPAY111Summary(name string, start time.Time, end time.Time) (ConcreteView, error)
}
```

**pay222.go**
```go
type PAY222 interface {
	GetPAY222Summary(name string, start time.Time, end time.Time) (ConcreteView, error)
}
```

**pay333.go**
```go
type PAY333 interface {
	GetPAY333Summary(name string, start time.Time, end time.Time) (ConcreteView, error)
}
```

By carving out a common interface, establishing a common pattern, and splitting each interface into its own file, had zero merge conflicts. We were able to build these all concurrently.
Once we had these built, we really understood how they should be named. So we simply renamed the interfaces, renamed the structs, renamed the files, and done.

## Summary

I’ve covered some techniques we used to build a scalable application quickly and effectively make use of all of the engineers on the team.
Using these approaches allowed all 7 engineers to build vertically sliced features with minimal merge conflicts, iterate, and ship quickly.
A few other techniques we used which were not mentioned in this post were: having stories written for 1 to 2 sprints ahead, deferring decisions asking ourselves what are the minimum things that need to be done to build this feature, and do we really need it.