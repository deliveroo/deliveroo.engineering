---
layout: post
title:  "What it’s like to be an Android developer at Deliveroo"
author: "Evelina Vrabie"
excerpt: >
  I've been with Deliveroo for over a year now, so it's a good time to share what it's like to be an Android developer here, how we do development, what tools we use, what are our practices etc. If you're an engineer yourself maybe this article will help you decide if the way we work fits with yours - maybe you'll be part of the team releasing our next Android app!
---

## Team size
Deliveroo is a very hot startup, "[a giant in the making](http://www.forbes.com/sites/parmyolson/2015/11/25/british-startup-deliveroo-may-be-a-giant-in-the-making)" to quote Forbes. Since I've joined, we've had to move three offices to accommodate the ever growing engineering team, which now has around 200 people in total.
Our Android developers are spread across three teams, all London-based. We're in charge of building and maintaining the apps for customers to place orders, for restaurants to accept orders, and for riders to deliver orders to customers. I've been working in the *consumer team* since joining the company in November '15. The consumer team has now four Android developers: Ana, Plato, Maria and myself. Overall, our Android team is one of the most gender-balanced team I've ever worked on! 🎉  

The other two teams are a bit smaller, two developers each (but soon to grow). Having small to medium teams is great because each developer has the opportunity to work on new features all the time. 
We've recently transitioned from platform teams to feature teams, to better focus and align our development efforts with areas like user acquisition, conversion, retention and customer experience.


## Processes
Deliveroo enjoys being able to improve quickly, so we use agile processes in our work. We mostly use Scrum, but all our processes are adjusted for our needs, rather than following them for the sake of process. Our sprints are usually two weeks (and we get to give them 
funny names like condiments, sweets, music etc.) with weekly retrospectives, backlog grooming and planning.
At Deliveroo, we don't let technical debt creep up, so our teams dedicate around 20% of each sprint to hygiene tickets. These include things from cleaning up bits of code to trying out new libraries, design patterns and experimenting with the UI.


## Coding practices
Our team takes code quality extremely seriously.  We also believe in code reviews as the best way to drive code quality and increase knowledge sharing. Each ticket we work on goes through the review and QA process: we open a pull request against our codebase on Github, which gets reviewed by at least two members of the team,  goes to our QA team and after everything is given the thumbs up, the code is merged into the main branch as part of our CI process. An important thing to mention is that each PR will normally contain the implementation **plus the tests**. We write both unit and integration tests, but unit tests are *a must*.

The engineering team at Deliveroo values pair-programming and promotes cross-team work. I've had the opportunity to work with a bit of backend Ruby and frontend web and I felt warmly encouraged and supported by our team. 

Check out our collection of [technical guidelines](http://deliveroo.engineering/guidelines/) to find out more how we build things at Deliveroo!


## Good architecture
A good Android app has to invest in an architecture that allows it to grow while still remaining maintainable. That's why our team has come up with an MVP architecture we share across projects, which allows us to decouple the business layer from the presentation one and makes testing easy. We're constantly improving the architecture and we share some of the common functionality as internal libraries between our Android teams. 


## Tools and libraries
We use most of the well-known Android libraries out there: [OkHttp](http://square.github.io/okhttp/), [Retrofit2](https://square.github.io/retrofit/), [Butterknife](http://jakewharton.github.io/butterknife/), [Glide](https://github.com/bumptech/glide), [RxJava](https://github.com/ReactiveX/RxJava), [Robolectric](http://robolectric.org/), [Espresso](https://google.github.io/android-testing-support-library/docs/espresso/) etc. We've recently introduced [Kotlin](https://kotlinlang.org/) in our unit tests, because the language simplicity helps keeping the tests more readable and shorter than when written in Java. 

We're constantly updating our code to look for ways to monitor and improve performance, minimize the number of bugs and increase code coverage in our tests. For static analysis we found [Codacy](https://www.codacy.com/) works reasonable well and for bug reporting we currently use [Crashlytics](https://fabric.io/kits/ios/crashlytics). Every tool is seamless integrated in our CI process, so we rarely have to manually run any.

## Fun
The Android team at Deliveroo is great! Everyone is smart, driven and knowledgeable but most importantly, everyone is super fun to work with! We love our team outings and our *androodevs* meetups where we share the newest and coolest news and knowledge from the Android world on a weekly basis. Conference-going is supported and encouraged by our management, specially as [speakers](https://skillsmatter.com/skillscasts/9116-battle-of-immutables-autovalue-vs-lombok). Deliveroo had a very strong presence this year at [Droidcon UK](https://www.flickr.com/photos/skillsmatter/30321287490/in/album-72157672179802194/) as a Gold sponsor and one of our developers got a ticket to Google I/O in US!

## Interview process
Hopefully this post has given you an overview of what's like to be an Android dev at Deliveroo, but there's so much more to say! It's a great place to work! Our interview process is on the cool side too: just two interviews, a quick phone one, followed by a two-hour on-site, pair-programming interview, where you get to meet our team, ask questions and learn something new (or **teach us** something new)! 

In short, if you're looking for a great place to work (have I mentioned free food... 🍔 &nbsp;&nbsp;?), a young company with a great product and a fast-growing, fun-loving team with a knack for code quality, good processes and cutting-edge development practices, then come join us at Deliveroo!

<figure class="small">
![The Android Team](/images/posts/what-its-like-to-be-an-android-developer-at-deliveroo/android-team.png)
</figure>

