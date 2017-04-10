---
layout: post
title:  "Hackday and the £17 soda"
author: "Troy Harris"
excerpt: >
  We started at Deliveroo 4 months ago and have been building an API test framework which has now just completed stage 1.  
    
  **TL/DR** We’re pretty happy here at Deliveroo, we’re learning, we’re having fun, we’re doing it at pace. 
  `Soda == Doughnuts`
  
---

## So I better start from the beginning...

Joining Deliveroo Engineering back in November 2016 as two ex Yammer / Microsoft employees, [Victoria Puscas](https://www.linkedin.com/in/vpuscas/) 
and I have been been toiling away on the first stage of an API framework we’re attempting to inject into the deployment pipeline, 
and we’re happy to say stage 1 is now complete!  

Before we talk a little more about the process, the next stage, and the hackday £17 soda we’d like to say a few things 
about our Deliveroo first impressions:


- **Pace** - Things are moving extremely fast at Deliveroo! We’re coming up to our third office move due to the growing 
number of engineers.  
- **Culture** – our weekly company-wide lunch (lovingly named "the Hunger
Games"), our rotating product team bakery challenge ("Bunday Monday" is a
great start to the week), "Ride together" where our employees help the riders
deliver food on Friday lunchtimes, "Game nights" from board games to Oculus Rift sessions,
"Hack/Away days" where you can learn and hack to your hearts content. We have fun!  
- **Growth mindset** - Training / Conference days, Speaker support groups, always learning!  
- **Data** - Just wow! We’ve got data scientists doing some absolutely amazing work providing the business 
with razor sharp vision.  
- **Mindful** - There’s a lot of passion and consideration for all things Deliveroo, from restaurants to [Deliveroo 
Editions](https://foodscene.deliveroo.co.uk/promotions/deliveroo-editions.html) (delivery-kitchen concept), riders and improving their experience, and customers getting an exceptional meal!  




## So now onto Loris the API test framework

When we interviewed at Deliveroo we talked in depth to [Dan Webb](https://twitter.com/danwrong) - our soon-to-be Manager - about testing, how we could help 
level up QAs, and an automated test framework we’d like to implement. We wanted to **quickly model the critical 
end-to-end business flow that starts with the consumer and finishes at the delivery**. Fortunately he liked our plan 
and we set to task.


## Where did we start? 
With the wonderful team of QAs who allowed us to pillage their test plans, and steal some of their valuable time. 
We went from team to team on a mission of discovery to understand what was the beginning and end of a Deliveroo order. 
It was a great way to meet the team, understand processes, and get our bearings. 

As we collated documents, we configured our environments with mobile emulators, proxies, hooked into logging, poked and 
prodded endpoints, and got an understanding of the deployment process. Within 2 weeks a single spreadsheet with a 
simple list of 12 steps was created, and most importantly a discussion began on what we should call the new framework, 
with a tip of the hat to Yammer’s ‘Otter’ internal test framework, we chose a name which we thought was short, cute, and 
anything but slow - Loris, our soon to be slender API test framework.

Our first commit, the framework's README.md, and manifesto include the following objectives:

- Aim to automate basic business flows, and regression scenarios
- No longer than 5 minute full test suite duration
- Shared ownership
- There are no gatekeepers
- It is not: a UI framework, dump for ALL test scenarios, mobile test framework
- Add a scenario if it is: a positive business flow, critical business flow 
- Don't add scenario for: valid/invalid data types, structure of payload, two service interaction, 
just a http response code, endpoint check without context

This allowed us to **establish boundaries for what we valued in our framework**, and set expectations for what we would 
deliver. These early discussions continue to help us prioritise work quickly and without much debate.

Now there’s one thing we really wanted to get right, and it sounds obvious, we aim to **double our efforts with communication!** 
I’ve seen frameworks implemented by contractors who spend a few days discussing what the team needs, disappearing for 
3 months and slapping something on the table as they walk out for their South American adventure! That framework lasts 
about 2 months before it gets ripped out and re-written. 

Communicating early and often with developers and QAs allows you to do two things:  Tap into some serious talent to 
refactor your growing framework's foundations, and begin levelling up your QAs from manual testers to automation gurus. 

After 3 months we completed stage 1 which allows us to complete the full Deliveroo order **end-to-end business flow in 
~16 seconds**. 

It looks a little like this:


 
<figure>![Rubmine structure](/images/posts/hackday-and-the-17pound-soda/rubymine_structure.png)  
<caption>Framework directory structure, and description of classes within them</caption>
</figure>

## So what’s next for Loris? 

We’ve just completed another milestone which is to run across 11 out of 12 countries (UAE has a different payment 
provider we'll be automating soon), but this has our suite running in just under 5 minutes on a slow day, which means 
we hit our self-imposed limit for execution time.  

To solve this we ended up moving from [Travis](https://travis-ci.com) to [CircleCI](https://circleci.com/) which 
let us run across multiple nodes, bringing it back down to ~2 mins.  

Loris is now well on the way to becoming her own service so we can **become part of the deploy pipeline**, and 
additional payment types are being implemented thanks to our new team member [Pauric Ward](https://www.linkedin.com/in/linuxpauric/).  

<hr>
# The Hackday £17 soda 

<blockquote class="twitter-tweet" data-lang="en" align="center">
<p lang="en" dir="ltr">When your hackday hack brings you crosstown doughnuts everyone&#39;s a winner <a href="https://t.co/vxtuyG0HiK">pic.twitter.com/vxtuyG0HiK</a></p>&mdash; Troy Harris (@TroyHarrisOz) <a href="https://twitter.com/TroyHarrisOz/status/846093658784976897">March 26, 2017</a>
</blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>  

<br>
Deliveroo ran its first engineering Hack Away day in early March which was smoothly organised by Engineering lead 
[Edd Sowden](https://twitter.com/edds). There were multiple speaking tracks throughout the day ranging from 'Future architecture' with 
[Julien Letessier](https://github.com/mezis), to 'Machine learning with Deliveroo Algos' with [Alessio Dore](https://www.linkedin.com/in/alessio-dore-70026ba/). 
There was also time for some hacking, and **this is where a £2.50 soda was purchased for £17**.

**Note:**   
- When pointing a test framework at PRODUCTION remove the £12 tip!  
- Customer support is your friend when incorrectly placing an order  
- POSTs via Zapier like repository IDs. Don’t use slug names, find your ID via the Travis CLI.

### 1. Controller 

To fire off our doughnut order, and have our phone shout "DOUGHNUTS!") we'll use a bluetooth button to trigger our 
Travis build. Purchase your [Flic.io bluetooth button](https://flic.io/)  
  
### 2. Triggering builds through Travis API  
Read this: [Travis triggering builds](https://docs.travis-ci.com/user/triggering-builds/)  
 
Test build triggered with Curl:  

```shell
body='{
"request": {
  "branch":"donutz"
}}'

curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token xxxxxx" \
  -d "$body" \
  https://api.travis-ci.org/repo/tastydeliveroo%2Fdonutz/requests
```  

### 3. Flic bluetooth button Zapier integration 
Read up on [How to use Zapier webhooks](https://zapier.com/blog/how-use-zapier-webhooks/)
 
Add your [Zapier integration](https://zapier.com/zapbook/flic/)  

<figure>
![Zapier payload](/images/posts/hackday-and-the-17pound-soda/zapier_payload.png) 
</figure>  


### 4. Point your API framework at Production 
Press the button - _'DOUGHNUTS!'_ - What could possibly go wrong?  


### 5. Consume doughnuts  
Thank you [Crosstown doughnuts](https://www.crosstowndoughnuts.com/)!  


<hr>
<center> Thanks for reading, we hope you’ve enjoyed Loris at stage 1!</center>   
    
<center>Team SETI, Deliveroo Engineering</center>
