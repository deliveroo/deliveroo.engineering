---
layout: post
title:  “I assess quality……therefore I am”
author: "Festus Ifiti jr"
excerpt: >
  Friends, engineers, fellow food enthusiasts…lend me your ears. Before my interview with Deliveroo in November, I read some articles from the engineering blog and I promised myself that when I did start working for this amazing company, I would participate and write an article about all things QA…. I also had a little bet with[Troy Harris](https://twitter.com/TroyHarrisOz/). He fulfilled his end of the bargain so I’m fulfilling mine.
  
  In this blog, I'm going to talk about my Deliveroo Interview experience, the current QA process, taking responsibility, my typical working day and Brown Bag sessions.

---


## “If you can talk with crowds and keep your virtue”


When I interviewed at Deliveroo, I spoke about bridging the gap between manual and automation, writing our test scripts in the given-when-then steps format. [Sarah Gregory](https://www.linkedin.com/in/sarahgregoryuk/), my soon to be QA work colleague, liked my idea and we spent the rest of the interview talking about how I would implement this new process.

I had a meet up with the VP of engineering [Dan Webb](https://twitter.com/danwrong) a few days after I started. I talked about how I would improve the QA process and the VP simply told me to “implement” and “If you need money for tools, it shouldn’t be a problem.”

It was pretty evident early on that Deliveroo is a forward thinking company, who are not afraid to try out new ideas.

## “If you can keep your head when all about you are losing theirs and blaming it on you”


It’s not easy being a QA when there’s a bug. A natural response is to say, “Why wasn’t this application tested properly?” Nobody really says, “Why wasn’t this application built properly?” The pressure is always on, but can this pressure and responsibility be shared throughout all stakeholders? 

At Deliveroo, the QAs write detailed test scripts using BDD (Behaviour Driven Development.) We have scripts for functional components of the application as well as scripts for offline behaviour (500 server errors, bad network/Wi-Fi disconnected), background/killing the application. We’re always looking for ways to improve the application and if we can limit crashes this will improve customer satisfaction.

Every time we have a new feature or if we have a new release, these scripts are shared between everybody in the team and because BDD uses natural language, stakeholders can understand the scripts.

At Deliveroo, we believe in testing from the beginning of the process; I’ve been in companies where they say they do, but they don’t. As soon as we have a specification, requirements are drawn up, low level requirements are fleshed out and test cases are written. If we can find errors on paper, this is easy and very cheap to fix rather than the bug manifesting into something horrendous later in the process. 


## “If you can trust yourself when all men doubt you”

It’s everybody’s responsibility to improve the application, developers don’t only develop, product don’t only design and QA’s don’t only define quality. Everybody at Deliveroo is encouraged to pipe up, speak and provide luscious cakes. I’ve said the following since my arrival in December – “Why does the iOS app look different to the android app?” “Can we have possible options on the pop up notification?” Why do we have a swipe option? Surely a button would be better?” etc

These great matters and many more are discussed every day, if the team believe that your idea is beneficial to the app, tasks are created and added to the sprint backlog. And perhaps the most important question of all…. “Who creates these funky emoji’s on slack?” Nobody has taken ownership of this but I am determined to get to the bottom of this.

## “If you can fill the unforgiving minute with sixty seconds worth of distance run”

Every day is something different, it’s a challenge, there’s a lot of work and you can never be bored. I’ve used a plethora of tools to aid me in my work. Last week, I was working closely with the backend engineers to check that the rider locale was present at a specific endpoint. [Charles Proxy](https://www.charlesproxy.com/) was used to aid me in this investigation.

A couple of weeks back, I was simulating doze mode on android, marshmallow/nougat devices, [adb commands](https://developer.android.com/studio/command-line/adb.html) were used to ascertain how the application behaves when the phone is idle.

An event was added on iOS to ascertain how many riders are using the external map rather than the one built into the app. Firebase analytics was used to track this event.

Over the past few weeks I’ve been working on adding tests to Loris, Loris is the end to end API test framework. The aim is to automate basic business flows, and regression scenarios. If you want to know more about this lovely service its authors, Victoria Puscas and Troy Harris, have [written a post here explaining it](http://deliveroo.engineering/2017/03/28/hackday-and-the-17pound-soda.html).

## “If you can dream…and not make dreams your master”

Every two weeks the QAs have a brown bag session. For anybody that doesn’t know what this is, a brown bag session is an informal meeting, training or presentation that happens during a lunch period. 

We have at least one QA in each team (Consumer, Payments, Rider, Restaurant, Logistics… Growth and many more) and it’s our collective aim to learn from each other, improve technically, help relieve any spikes and improve communication.

The first brown bag session was about how to have a trusted environment where creativity/experimentation around process is welcomed and valued. The second brown bag session was hosted by yours truly, I was talking about all things BDD and using [Hiptest](https://hiptest.net/) as a tool to house all our test cases. The third brown bag session was truly amazing, showing that learning a skill can take about 20hrs before you become proficient(ish).

Deliveroo is a forward-thinking company where new ideas are harnessed/cultivated and not shelved.


## “Yours is the Earth and everything that’s in it, And which is more – you’ll be a man, my son”

Thank you for reading my blog, if I am allowed to write another article, my next topic of conversation will be mobile automation and how we’re using that to further improve the QA process.


