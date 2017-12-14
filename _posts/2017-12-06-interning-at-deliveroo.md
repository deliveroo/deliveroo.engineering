---
layout: post
title:  "Interning at Deliveroo"
authors:
  - "Reemma Muthal Puredath"
date:   2017-12-06 00:00:00
excerpt: >
  _Reemma writes to us after her time working with Deliveroo during her internship to tell us about her impressions of the company, her team, and what she accomplished with us over the Summer._
---

<figure>
![Visiting the Paris team](/images/posts/interning-at-deliveroo/my-team-in-france.jpg)
</figure>

It might be worthwhile to give you context as to who I am before describing my journey as an intern at Deliveroo so here goes. I am currently a 3rd year undergraduate studying computer science at UCL, and my experience in programming dates back to September 2015 when I ran my first C program. Since then I’ve dipped my toes into a couple of other languages and frameworks as well as trying to be more involved with the tech community in London to gain a wider appreciation for the subject. Last year, I picked up an internship opportunity with a fintech startup in Shoreditch and left having learnt so much about everything from new frameworks to the working culture in a company.

I got the opportunity to be interviewed by Deliveroo through [HackCampus](https://www.hackcampus.io/)— a non-profit organization that aims to connect students seeking internships with startups. I was fairly impressed by how organized the interview process was and for hearing back so quickly. When I entered the office for the first time, I had to get over the initial shock of realising how big the engineering team was. Compared to my previous internship where the tech team comprised of three people (myself included), there were now tenfold the number of software engineers just in one team!

I was placed in one of the Rider Engineering Teams as a Backend Software Engineer - the unfamiliarity of the role initially triggered my nerves a little and I considered moving to something else. While keeping the option of moving teams open, the software engineer who played the role of my manager, also assured me that I could take my time to get up to speed with Ruby and then have the opportunity to work on some projects that would have a significant impact on the company and the user experience. Enticed by the idea of being able to make high-value contributions to Deliveroo, I decided to stick to the team and it was probably one of the best decisions I’ve made. I spent the first week getting familiar with Ruby and working on side projects. During this time, my team were immensely helpful and would suggest various sources and project ideas to get me started.

In my second week, I was introduced to my mentor, [Mo Valipour](https://twitter.com/mvalipour), who was currently helping launch an important new feature for Riders in Paris. This meant the opportunity to go to Paris as well, and meet the rest of the team working there! My mentor played a huge role in getting me to start pushing code for Deliveroo. I started off attending retros and working on tickets and I was offered the chance to pair program with my mentor and other members of the team which was an awesome way of getting to know everyone’s roles in the team, and for me, it was a more natural way to getting familiar with the codebase.

Some work included moving functionality from our monolith to a separate service that involved creating new RESTful endpoints to send and receive events. Another project that I contributed to was to build more features to help riders be and feel safer, the social impact of its result added a lot more value to it for me.

Towards the last three weeks of the internship, I was given the option of working on the Rider Telemetry Project, which was needed to ensure the logistics algorithms have the best data for pairing the right riders and orders. In the first week, I analysed the existing code and wrote some documentation for the existing functions to improve my understanding of how things currently work. Currently, the clients poll the server to exchange telemetry data. One of the most concerning issues with HTTP Polling is that every request and response is a full HTTP message and for small messages, you’re sending out a full set of header in the message framing which will represent a significant percentage of that message and cause a lot of unnecessary overhead. We don’t even need to mention the risks of service degradation with HTTP polling.

The following week was spent researching alternative methods, digging deeper to find out how each of them worked, and analysing how viable of a solution it was. My three main ideas were to replace HTTP Polling with: [MQTT](http://mqtt.org/) or [websockets](https://en.wikipedia.org/wiki/WebSocket) (or MQTT over websockets). MQTT seemed like the perfect, snazzy solution at first. It was TCP based, payload agnostic and super lightweight. The second option was to replace polling with websockets, a protocol that gives you a [full-duplex connection](https://en.wikipedia.org/wiki/Duplex_(telecommunications)#Full_duplex) over a single TCP connection, providing a persistent communication between client and server.

I presented my ideas back to the team and with the feedback I received, it became more apparent that MQTT may be an overkill for what we’re trying to achieve now. So websockets it was. The last week of my internship was spent implementing the websockets into an existing api endpoint that was consumed by the rider iOS and Android clients. I played around with the socket creating a proxy client in NodeJS and observing the fake telemetry data getting logged in our systems.

Those were just the technical aspects of my internship, the cultural aspects were just as enjoyable. From the traditional Friday lunch Hunger Games (tons of Deliveroo-ed food) to cracking open a cold one on our very own rooftop garden overlooking an amazing view of London. I even got the opportunity to try out the rider experience, delivering the food! Most importantly, Deliveroo gave me a nurturing space to learn and develop my skills, and my team and all the people I met, played a crucial role in that process. I’m so happy to have met such cool people and I finally started using Twitter because I’ve found tech people I can follow and look up to.

See you next summer!
