---
layout: post
title:  "Where are they now?"
authors:
  - "Joshua Levin"
  - "Jenny Sivapalan"
  - "Troy Harris"
excerpt: >
  How Deliveroo does Hack days and then takes it to production

---

# Deliveroo Hack Day 2019 - Incremental Wins
<figure>
![2019 Hack day logo](/images/posts/where-are-they-now/hackdaylogo.png)
</figure>

### Why hack?
At Deliveroo we've had different forms of hack days, from teams taking the initiative to run them internally to organisation-wide events. This hack day event we encouraged everyone in Tech to attend and take a break from the current projects and responsibilities. 

We're rapidly growing our teams; the organisation wide hack day helps us to get to know different people and spark new interests in what's going on in our community. It encourages us to think about different ideas we could do and an opportunity to prototype and share what we've learnt.

If a hack day idea is close to be shipped and we believe it will bring value to the user we encourage spending the time to getting it done. An example of this is we beta test our apps to employees, the Android team were able to add a prompt to encourage employees to upgrade to the latest version with the tap of a button.

Other ideas may take more time to complete and here we encourage members of a hack day team to work with engineering managers and product managers to outline the proposal and work towards how we prioritise the idea.

### Incremental Wins
You know how it is, we move fast and aim for the tasks that provide the most valuable results.  But along the way we realise there’s that one thing, or those many things, that bug us.  

Perhaps it’s a process that has to be followed and hasn’t been simplified. Or maybe there’s a gap in our capabilities that always seems like a lower priority compared to the main project.  It doesn’t have to be the long forgotten ticket at the bottom of the backlog.  It doesn’t even have to be your team’s responsibility!  In 2019 Deliveroo turned the spotlight on the small ideas, the incremental wins that add up to something much greater.

<figure>
![Hack day room](/images/posts/where-are-they-now/excelroom.png)
</figure>

2019 saw over 120 engineers take part in the hacking with 32 teams presenting.  It was held over two days at the Excel center, one and a half days for hacking and a couple of hours for teams to make five minute presentations followed by voting.  

Voting was done in five categories:
* Best Overall
* Biggest Productivity/Performance Boost
* Best Mobile/Device Hack
* Valuable Little Problem
* Happy Customers Award

Troy and Joe created the trophies: 3d-printed Roo logos with air plants in the ears.

<figure>
![Trophy 3d model](/images/posts/where-are-they-now/rooward2.png)
</figure>

<figure>
![Trophy printed with airplants](/images/posts/where-are-they-now/rooward1.jpg)
</figure>

There was swagger in the form of laptop stickers and popsockets.

<figure>
![Hack day merch](/images/posts/where-are-they-now/roomerch.png)
</figure>

And of course, there was food.

<figure>
![Fruits and pastries](/images/posts/where-are-they-now/food2.png)
</figure>

<figure>
![Salads](/images/posts/where-are-they-now/food4.png)
</figure>

We saw Slackbots to help on-call engineers, how web push notifications could help our riders during the sign up process, and were greatly amused by an IOT solution for monitoring busy toilets.  When the dust settled, winners announced and laptops packed up, it was time to go to the pub next door.

There’s one big question remaining though...

# What happened next?

A hack should not go quietly into the night.  The power of focusing on an incremental win is that the target need is real and, with a proof of concept, the argument for putting more work in and getting it into production grows stronger.  We’ll be catching up with some of the hacks that continued to have work done to them.

## Bot on Call - Best Overall winner

### Erika, Nina, John, Lukas, Florian

<figure>
![Bot on call team](/images/posts/where-are-they-now/botoncall.png)
</figure>

The Bot on Call team wanted to use a SlackBot to automate many of the processes involved in our on call processes.

Lukas: “It is definitely still being worked on and we plan to have part of it launched in production this month.”

Erika: “We did a demo for Alison (a Senior Technical Programme Manager who is also the on-call manager)...and she got really excited so she helped us with defining an MVP...hoping to get something in production in the next couple of weeks.”

Florian: “We’re still working on bot-on-call...We’re currently refactoring it, to make it more robust and being able to publish it.”

The bot-on-call project has launched and is now in production simplifying Deliveroo’s on-call process.

## Hopper Local - Biggest Productivity winner

### Adelina, JP, Jennie, Skip, Matt, Jesus, David

<figure>
![Hopper local team](/images/posts/where-are-they-now/hopperlocal.png)
</figure>

Hopper is Deliveroo’s internal release tool.  As Deliveroo’s microservice count increases, it becomes more important than ever to ensure developers can get set up as easily as possible.  The hopper local team created a local service that could build external dependencies easily from a docker environment.

Jesus: “The team has been working on scoping the work for our first increment and release a beta version...There is a very good reception for the project as there is a real need to run our micro services locally in a more scalable way.”

## Apps Accessibility - Happy Customers Award winner

### Maya, Sarah, Victoria

<figure>
![App accessibility team](/images/posts/where-are-they-now/appaccessibility.png)
</figure>

The app accessibility team conducted usability tests and audits to examine how the consumer app fared with accessibility and identified opportunities to improve it.

From the group: “After identifying several improvement opportunities, we kicked off a working group to address these accessibility issues. We were able to raise greater awareness of accessibility issues, which has been awesome, and have seen a good uptake of colleagues interested in joining the group to evolve it further!”

## Food for the on-call people - Valuable Little Problem

### Daniel

Daniel saw an opportunity to make it easier for on-call engineers to claim their meal allowance by integrating with our PagerDuty schedules.

Daniel: “The food for the on call people project integrated Pagerduty - which is our alerting and notification system for incidents - with our DfB product. When an on call engineer is on call we allow them to claim an allowance to lighten the load in what can be stressful times.  

We’ve shipped a beta internally that we’re testing and are looking to expand it to a wider audience - so any tech company that uses both deliveroo and pagerduty can take advantage of this convenience.”

## Component-Centric Content Infrastructure

### Lim

Lim noticed the need to empower non-technical stakeholders to prototype web pages faster, both in terms of content as well as in terms of visual structure, while being compliant to the quality standard of Deliveroo’s consumer web.

Lim: “I was able to demo the project to various different people and at some point the entire Growth team. We were able to identify a good first use case to tackle as an MVP and just kicked off the project yesterday to implement this MVP.”

The project has since released in production.

## UI to Manage Deliveroo Offer Campaigns

### Krissy, Stephanie, Steve, Claire, Carlos

Creating big offer campaigns for events like Black Friday or weekly group deals like "Treat Yourself Tuesday" started off as a manual task requiring engineering effort to run. It turns out our customers love a good offer, so this needed to scale sooner rather than later. The hack day team decided to take the initiative here and build a UI proof of concept to cut the need for engineering time per campaign. This turned into a fully-fledged tool that ticked that box not long after the day!

Kriselda: “After hack day, we created a new epic for getting the UI to a production-ready state, and extracted the todos into tickets ready to prioritise in one of our weekly sprints. We included finishing it off as part of our Q3 roadmap and it didn't take long for our hackday efforts became a real thing. Obviously, our engineers love it.”

## Load Generator

### Mitchell, Claire, Alex, Ben, Antonio, Carlos, Tim

Mitchell and Alex had already started the load generator service in their own time before the hack day but spend the time working on usability features.

Mitchell: “The team who built it has actually been using it pretty frequently...we try to dedicate a few hours a week to picking up some [improvements or bugs].”

Alex: “It’s actually been used quite a lot. I have been able to use it when upgrading [our website], making sure that a major version increase in Debian didn’t introduce any memory/cpu consumption leaks. [On another team] it helped them realise the need for a db read replica.“

## Sandboxed staging

### Dario De Bastian

Dario was frustrated that his team would get conflicts in staging because of clashes and so he set out to create sandboxed staging systems they could all work on independently.

Dario: “[We] didn’t manage to finish that during hack day as we had issues with terraform and sandbox...after the hack day and the changes to terraform for sandbox, it’s been finally completed and deployed.”

# You and who?

Support and assistance from peers and leadership is vital to bringing an idea to production.

JP wrote an excellent article on getting support from your team (the snippets below have been cropped to paraphrase).

<figure>
![JP Hastings-Spital from hack to production](/images/posts/where-are-they-now/jparticle1.png)
![The key is communication with your team](/images/posts/where-are-they-now/jparticle2.png)
![There are slack channels where you can ask for help](/images/posts/where-are-they-now/jparticle3.png)
</figure>

Lukas: “We've had offers of help from engineers outside of the original team, but we have declined these as we didn't think increasing the size of the team would make us go any faster, however, we have had a lot of help from Alison (on-call manager) getting permissions and accounts set up.”

Erika: “[My team] know I'm also working on this and my manager actively encouraged me to do it.”

Florian: “We received support from the EMs of our teams and Alison and encouragement to ship it.”

Mitchell: “My director has asked about how we’re using it and what challenges we’ve found with it. Alison has said that she is onboard for us promoting it and encouraging teams to use it before September/Q4 starts and make sure that services are able to handle the expected increase in traffic.”

Alex: “There have been days where my team is okay with me working on this project. I’ve been giving the other front-end engineers in my team the reviews, so I’ve been getting help that way.”

Lim: “[My product manager] was very keen on it as it solves a bunch of problems we currently face, so he has been the primary helper in terms of getting buy-ins from various stakeholders to let my entire team make it a team’s priority in Q3.”

Dario: “I want to give credit to Ben for help during the hack day and Egis for help after.”

Daniel: “Finance were super helpful. It involved some policy changes on our end to unlock [food for on-call engineers].”

# Onto the future

Deliveroo will continue to hold hackdays and we hope that each time we’re able to gain something, learn a little more and take advantage of the creativity that they bring.  Encouraging people to work with others outside of their team was one of the key pieces of feedback that we received and promoting non-engineering disciplines to join was also high up the list.  We’ll take these on board and look to the future with anticipation.

Hack on,

Deliveroo Engineering.
