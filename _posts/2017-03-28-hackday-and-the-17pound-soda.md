---
layout: post
title:  "Hackday and the £17 soda"
author: "Troy Harris"
excerpt: >
  We started at Deliveroo 4 months ago and have been building an API test framework which has now just completed stage 1.  
    
  <b>TL/DR</b> We’re pretty happy here at Deliveroo, we’re learning, we’re having fun, we’re doing it at pace. 
  Soda == Doughnutz*
  
---

## So I better start from the beginning...

Joining Deliveroo Engineering back in November 2016 as two ex Yammer / Microsoft employees, [Victoria Puscas](https://www.linkedin.com/in/vpuscas/) 
and I have been been toiling away on stage 1 of an API framework we’re attempting to inject into the deployment pipeline, 
and we’re happy to say stage 1 is now complete!  

Before we talk a little more about the process, the next stage, and the hackday* £17 soda we’d like to say a few things 
about Deliveroo first impressions:


- <b>Pace</b> - Things are moving extremely fast at Deliveroo! We’ve coming up to our third office move due to the growing 
numbers of engineers.  
- <b>Culture</b> - Hunger games, Bunday, Ride Together, Games nights, Hack/Away days, we have fun!  
- <b>Growth mindset</b> - Training / Conference days, Speaker support groups, always learning!  
- <b>Data</b> - Just wow! We’ve got data scientists doing some absolutely amazing work providing the business 
with razor sharp vision.  
- <b>Mindful</b> - There’s a lot of passion and consideration for all things Deliveroo, from restaurants to the Roobox, 
riders and improving their experience, and customers getting an exceptional meal!  




## So now onto Loris the API test framework

When we interviewed at Deliveroo we talked in depth to [Dan Webb](https://twitter.com/danwrong) our soon to be Manager about testing, how we can help 
level up QA’s, and an automated test framework we’d like to implement. We wanted to <b>quickly model the critical 
end-to-end business flow that starts with the consumer and finishes at the delivery</b>. Fortunately he liked our plan 
and we set to task.


## Where did we start? 
With the wonderful team of QA’s who allowed us to pillage their test plans, and steal some of their valuable time. 
We went from team to team on a mission of discovery to understand what was the beginning and end of a Deliveroo order. 
It was a great way to meet the team, understand processes, and get our bearings. 

As we collated documents, we configured our environments with mobile emulators, proxies, hooked into logging, poked and 
prodded endpoints, and got an understanding of the deployment process. Within 2 weeks a single spreadsheet with a 
simple list of 12 steps was created, and most importantly a discussion began on what we should call the new framework, 
with a tip of the hat to Yammer’s ‘Otter’ framework, we chose Loris, our soon to be slender API test framework.

Our first commit, the frameworks README.md, and manifesto include the following:

- Aim to automate basic business flows, and regression scenarios
- No longer than 5 minute full test suite duration
- It is not a: UI framework, dump for ALL test scenarios, mobile test framework
- Add a scenario if it is: a positive business flow, critical business flow 
- Don't add scenario for: valid/invalid data types, structure of payload, two service interaction, 
just a http response code, endpoint check without context
- Shared ownership
- There are no gatekeepers

This allowed us to <b>establish boundaries for what we valued in our framework</b>, and set expectations for what we would 
deliver. These early discussions continue to help us prioritise work quickly and without much debate.

Now there’s one thing we really wanted to get right, and it sounds obvious, <b>double your efforts on communication!</b> 
I’ve seen frameworks implemented by contractors who spend a few days discussing what the team needs, disappearing for 
3 months and slapping something on the table as they walk out for their South American adventure! That framework lasts 
about 2 months before it gets ripped out and re-written. 

Communicating early and often with developers and QA’s allows you to do two things:  Tap into some serious talent to 
refactor your growing frameworks foundations, and begin levelling up your QA’s from manual testers to automation gurus. 

After 3 months we completed stage 1 which allows us to complete the full Deliveroo order <b>end-to-end business flow in 
~16 seconds</b>. 

It looks a little like this:


 
![Rubmine structure](/images/posts/hackday-and-the-17pound-soda/rubymine_structure.png)  


## So what’s next for Loris? 

We’ve just completed another milestone which is to run across 11 out of 12 countries (UAE needs a payment type added), we started to top out at 5 minutes 
which means we hit our self limited 5 minute ceiling, so we quickly moved over from Travis to CircleCI and run across 
multiple nodes, we’re now back down to ~2 mins. Loris is now well on the way to becoming her own service so we 
can <b>become part of the deploy pipeline</b>, and additional payment types are being implemented thanks to our new 
team member [Pauric Ward](https://www.linkedin.com/in/linuxpauric/).  

<hr>
## <center> The Hackday £17 soda </center>

<blockquote class="twitter-tweet" data-lang="en" align="center">
<p lang="en" dir="ltr">When your hackday hack brings you crosstown doughnuts everyone&#39;s a winner <a href="https://t.co/vxtuyG0HiK">pic.twitter.com/vxtuyG0HiK</a></p>&mdash; Troy Harris (@TroyHarrisOz) <a href="https://twitter.com/TroyHarrisOz/status/846093658784976897">March 26, 2017</a>
</blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>  

<br>
Deliveroo ran its first engineering Hack Away day in early March which was smoothly organised by Engineering lead 
[Edd Sowden](https://twitter.com/edds). There were multiple speaking tracks throughout the day ranging from 'Future architecture' with 
[Julien Letessier](https://github.com/mezis), to 'Machine learning with Deliveroo Algos' with [Alessio Dore](https://www.linkedin.com/in/alessio-dore-70026ba/). 
There was also time for some hacking, and <b>this is where a £2.50 soda was purchased for £17</b>.

<b>Note:</b>   
- When pointing a test framework at PRODUCTION remove the £12 tip!  
- Customer support is your friend when incorrectly placing an order  
- POSTS's via Zapier like repository ID's. Don’t use slug names, find your ID via the Travis CLI.

<b> 1. Controller </b>  

To fire off our dougnut order, and have our phone shout "DOUGNUTS!" we'll use a bluetooth button to trigger our 
Travis build. Purchase your [Flic.io bluetooth button](https://flic.io/)  
  
<b> 2. Triggering builds through Travis API </b>  
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
<br>

<b> 3. Flic bluetooth button Zapier integration </b>  
Read up on [How to use Zapier webhooks](https://zapier.com/blog/how-use-zapier-webhooks/)
<br>  
Add your [Zapier integration](https://zapier.com/zapbook/flic/)  
<br>
![Zapier payload](/images/posts/hackday-and-the-17pound-soda/zapier_payload.png)  
<br>

<b> 3. Point your API framework at Production </b>  
Press the button - <em>'DOUGHNUTS!' </em> - What could possibly go wrong?  
<br>

<b> 4. Consume dougnuts </b>  
Thank you [Crosstown doughnuts](https://www.crosstowndoughnuts.com/)!  
<br>
![Crosstown dougnutz](/images/posts/hackday-and-the-17pound-soda/doughnutz.gif)
![Crosstown dougnutz](/images/posts/hackday-and-the-17pound-soda/doughnutz.gif)
![Crosstown dougnutz](/images/posts/hackday-and-the-17pound-soda/doughnutz.gif)  

<hr>
<center> Thanks for reading, we hope you’ve enjoyed Loris at stage 1!  
<br>  
Team SETI, Deliveroo Engineering</center>
