---
layout: post
title:  "1 Year @ Deliveroo as a Backend Engineer"
authors:
  - "Nathan Ogunleye"
excerpt: >
  Hey there! I’m Nathan, a backend engineer at Deliveroo. Born and raised in London, I’ve been a software engineer for
  over 5 years and joined Deliveroo just over a year ago. I want to share with you my experience so far and what you can 
  expect in your first year. I hope nobody is reading. But if you are, then please keep this to yourself!

---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Probation (first 3 months)

My first week was an interesting one. This was the first new job I had started in this ‘new normal’ post-COVID-19 era. 
Being sent a work laptop by post and meeting my new colleagues virtually was a new experience.

I logged in to find my calendar pre-populated with a myriad of training sessions across the first two weeks. I’ll admit,
it was a little overwhelming. But it was reassuring to know that I was not the only one in this position. There were 
about 15-20 other people who had joined in the same week, each in varying positions in engineering, and many who had 
become familiar faces. The sessions ranged from engineering principles to designing systems at scale. I have to say, I 
was thoroughly impressed with the level of detail each training session had with comprehensive documentation to go with 
it. The latter part being a rare thing to see in an industry like ours, at least from my previous experience.

Free time in-between training allowed me to learn Go. Coming from a Java background, the differences were not too huge. 
C-based languages largely read the same. Although I had to get my mind out of the Object-Oriented Programming paradigm 
mindset as Go has no such concept. Having ‘grown-up’ with Java since university, this was a big pill to swallow. But, as
the kids say, ‘we move’.

I didn’t waste time meeting my new team in the Consumer org. My new joiner buddy messaged me on Slack on my first day to
introduce himself and the team. He was very helpful to get me settled in. He explained how our focus was to move our 
menus out of our monolith application into a microservice to allow for easier management and faster loading times. 
Despite the team having this goal, everyone seemed to work autonomously. Even though I had joined 3 months into the 
project with most of the groundwork already complete, we still had the freedom to do what we felt needed to be done.

## Post-probation
I think this is where the real challenge began. After my probationary period, you’re expected to start taking on more 
responsibility.

### Going on-call
This is something I was dreading. This was the first time I had to do anything like this in a job. Having seen from a 
distance how this has been done in other jobs, I figured it would be stressful. Thankfully Deliveroo has a process to 
ease engineers into the on-call rota. It starts with a training session (one when you join and another after probation 
to refresh your memory), shadowing (you follow and observe someone else on-call), reverse-shadowing (someone observes 
you), then you start on your own.

I had to skip the shadowing part as the on-call schedule was quite tight. Thankfully my reverse-shadow shift didn’t go 
too badly. I was paged a handful of times (if that) and everyone else on shift was very helpful too. Now up to this 
point, I had only worked on one service, so overseeing 6 other services I had never even touched or heard of before was 
quite daunting. But if you’re an experienced enough engineer, you’ll know the basic tools to look at when investigating 
an issue. On-call documentation (we call these Playbooks), DataDog logs, and other engineers are all the things you’ll 
need when looking into problems.

### Interviewing
Now this is something I’m still getting to grips with. This was also another task I was anxious about doing. I had never
interviewed anyone for a role until joining Deliveroo. What if I assess the candidate incorrectly? What if I gave the 
candidate a bad experience? These were the kind of questions that were running through my head. But at the same time, I 
was excited to finally be on the other side of the table (or screen).

But I’m sure you’ve guessed by now that, like going on-call, there is a process to get you started. A 2-hour in-depth 
training session is done to go through what is expected of you as an interviewer and what you should be doing and 
thinking. Then, you shadow another engineer and reverse-shadow afterwards. I like to think of these as having two 
engineers interviewing a candidate rather than having one interviewer and another watching.

Admittedly, during my own interview process I found the architecture portion challenging. But having been on the other 
side, I’ve come to understand how I could have done better. There is no one right answer. There are many ways to 
approach and solve a problem. One of the main things we look for is how you are conveying the solution to the problem as
well as the solution itself.

### Leading a project
This was something I was really looking forward to. One of the things that attracted me to work at Deliveroo was career 
development. Having the opportunity to move closer to a senior engineering position, I knew that performing senior 
responsibilities would include taking the lead in projects.

Towards the end of 2021, I worked on a new promotion to entice consumers to order groceries on our platform. This 
involved scoping out what needed to be done, diving into services I had never worked on before and learning more about 
the business domain (mainly how we calculate fees for the basket at checkout and how we advertise promotions and offers 
in the restaurant list). Thankfully the teams who worked on these respective areas were more than happy to offer help 
and advise on the best approach which made the job much easier.

I definitely learned time management in this project. I had a number of different tasks to do. Writing technical design 
documents, hosting weekly sync meetings, helping other engineers understand and work through issues they had found. It 
was _very_ involved and challenging as I had to be on top of everything. Juggling that and other personal commitments, I 
pulled through.

## What I’ve learned

### Everyone is willing to help
There are two core values that Deliveroo holds. **We succeed as a team** & **we never say it’s not my job**. These 
values could not be any more accurate. We have a plethora of Slack channels to ask any kind of questions you may have. 
From how the restaurant list works to how you pronounce the word "scone" (yes, seriously!). Even when you’re looking 
through code in a repository you’ve never seen or come across before, I’ve found that there will always be someone 
willing to help in any way possible. Whether that be sending code snippets or having a full-on deep dive session.

### Autonomy is a great thing
One aspect I probably admire the most is having the autonomy to do what you want. Now yes, your team may have their 
goals and priorities. But if you want to experiment with a new feature you are free to start a discussion on how to do 
so. If you want to try out a new Go library because you think it’ll help write code quicker, you are free to do so. If 
you want to set daily Slack alerts to remind your team of planned calendar events for the day, you are free to do so!

### It’s okay to fail
This is something I have to keep reminding myself on a regular basis. And in fact, this is probably one of my life 
mantras. It is okay to fail. This is how we grow. In the project I worked on to create a new grocery promotion towards 
the end of 2021, we managed to go live by the end of the year. But there were many many setbacks along the way. But that
was okay. I knew at the time that whatever went wrong during the project I’d do everything in my power to make sure it 
doesn’t happen again for future projects I work on. We love to run experiments here and sometimes they don’t work out 
the way we expect them to. But again, that’s okay. We reflect on our findings, take learnings from them and move 
forward. This is the kind of attitude every person should have in any function they work in. This is how we evolve to be
a better version of ourselves. I can say for sure that I’ve surpassed my own expectations in the last year.
