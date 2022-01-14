---
layout: post
title:  "How to prepare for the Deliveroo Architecture Interview"
authors:
  - "Jacob Lever"
excerpt: >
  Read on for some tips on how to prepare for Deliveroo's Architecture Interview, written by the Engineers who themselves run the Architecture Interviews at Deliveroo.
---

At Deliveroo we are constantly trying to figure out the best way to run our interviews with the aim of finding talented engineers while also making the process as enjoyable and interesting as possible.

One of the trickiest interviews to prepare for, if you haven't done one before, is the backend Architecture/System Design interview. 

### Why do we have an Architecture Interview?
There's a lot going on in the system behind Deliveroo's apps: There are hundreds of services worked on by dozens of engineering teams and they all need to work seamlessly together to get that burger to you at 7pm on a Friday. This means it's really important that our engineers can reason about and design complicated interacting systems that can handle the scale Deliveroo operates at.

## How do I prepare?
Many companies have an Architecture Interview as part of their hiring process and it's typically one of the most open-ended in terms of scope. Having run many of these interviews myself I've put together the following list of tips that will hopefully help you show your best self in the interview, based on the ways in which I've seen candidates (who perhaps haven't done many Architecture interviews before) struggle.

Although these tips are obviously based on Deliveroo's Architecture Interview they will mostly apply to other companies hiring processes as well, so let's get to it:

### There's no single right answer
In the interview we'll be asking you to design a new system from scratch. The requirements for the system will be deliberately open ended and so there will not be a "correct solution". So, don't worry about trying to find a trick or technology that'll make it trivial and feel free to explain what technologies you think might be suitable, and where the trade-offs are, before picking one to use in your implantation. We're really looking to see how you go about turning a fuzzy project brief into a solid technical plan.

### Use what you know
As you may know (or may not know, that's fine too!) at Deliveroo we have a service-oriented architecture. You might have worked on a similar system in the past, or you might not, either way don't feel like you should use a particular type of architecture (remember there's no right answer). In my experience, the candidates who use architectures, languages and technologies that they have the most production experience with, whatever they are, tend to do the best. Ideally use technologies you are comfortable with (you could mention though that you think X technology might be better suited because of Y, but you've never used it, so are sticking to something you know).

### Start with an overview and then iterate
It's usually best to go for an iterative approach rather than trying to write down the perfect solution straight away (that's probably impossible anyway). Sketch out all the core components you think you'll need to get a minimal working system first, and then iterate and go into more detail (and add more components as needed). Given how broad the systems tend to be, it's easy to spend a lot of time going in depth in one particular area, but we only have about 45 minutes, so we can't cover everything!

Your interviewer might interrupt and move you on occasionally, but don't see that as a bad thing: they know the areas they want more detail in, and where the juicy problems are (you can always ask them if they want you to elaborate before you go into more detail).

### Scaling
How your design works at high scale will be important, but it's also fine to start with a design that will work great (and consistently) at low scale first and then to adapt it later to make it scale. This can be a good approach if a scalable solution doesn't spring to mind immediately and it's better to start somewhere (you can always point out that you know component X won't scale, but you are going to talk about what to use instead later).

### _(For remote interviews)_ Make sure you are comfortable using a virtual whiteboard tool
For onsite interviews we would generally do this interview on a whiteboard or good old pen and paper, but Architecture interviews - as well as a lot of life - are a little different at the moment. For remote interviews, you'll be asked to share your screen while you design your system. You can use whatever tool you like, and it's a good idea to get used to drawing boxes, lines and text with it before your interview. Some tools are not the most intuitive if you haven't used them before, so knowing the tool well will mean you have one less thing to think about during the interview. Some tools we've seen used a lot are [diagrams.net](https://www.diagrams.net/) and [whimsical.com](https://whimsical.com/).

Make sure you have also granted your browser all the necessary permissions to share your screen (you can create your own meeting at [meet.google.com](https://meet.google.com/) to test out presenting), so you can spend your time focusing on the interview, rather than fighting with technology!

### Try designing some systems
The best way to practice is by doing. Grab a pen and paper (or a virtual whiteboard) and have a go at designing a web-based system/service you are familiar with. Start simple, drawing out the core components and models you'd need, then think about how increasing the load on the system might make parts of your design struggle. You could, for example, design a social media site, a theatre booking system or even a food delivery service!

Whilst not everyone will have access to them, asking more experienced people you know to take you through a mock interview is also a great way of putting yourself on the spot and testing out what you do and don't know.

At the end of the day, there's no perfect way to prepare - every company runs their system design interviews differently, and your experience with one may not be the same as another. But if you understand why this topic is important to us as an engineering team, and plan your preparation accordingly, you'll be setting yourself up for success.
