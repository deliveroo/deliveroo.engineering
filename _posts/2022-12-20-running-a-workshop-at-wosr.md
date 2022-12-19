---
layout: post

title: Stepping out of my comfort zone to run a workshop at the WOSR conference
authors:
- "Natasha Stokes"
excerpt: >
  How I ran a workshop at the Women of Silicon Roundabout conference and really got out of my comfort zone to do so.
date: 2022-12-20T14:10:16+0100
---

On the 22-23rd November 2022, the Women of Silicon Roundabout conference came to the London ExCeL with Deliveroo as the headline sponsor. Over 250 speakers brought talks and workshops over the two days, giving attendees a huge rage of insights, advice, and inspiration. The overarching theme of the conference was The Power of Resilience, and I’d like to share my own story of resilience and adapting to unexpected situations.

<figure style="text-align: center;">
![The Deliveroo team at the WOSR booth](/images/posts/running-a-workshop-at-wosr/deliveroo-team.jpeg)
*The Deliveroo team at the WOSR booth*
</figure>

As the headline sponsor, Deliveroo ran an incredible keynote on building resilience and being your authentic self, and we also ran a more technical workshop on Architecting with Image and Text AI which I was a speaker for.

To start the workshop, myself and one of our Staff Software Engineers, James King, gave a 20 minute presentation about the topic, covering how Deliveroo uses image and text AIs, why they can be useful, and what needs to be considered when implementing one. The attendees were then encouraged to gather into groups and spend the remaining 40 minutes discussing a scenario we provided (or their own scenario) and come up with a high level architecture of how they would implement text and image AI to solve the business problem.

Seems like a pretty standard workshop, right? The catch was that when I agreed to help run this, I had no knowledge or experience with AI or ML!

## Going out of my comfort zone

So why on earth would I run a workshop on a topic I wasn’t familiar with?

By the time I got involved, the workshop had already been submitted, approved, and a rough plan put together for the format. Since I already knew I was going to the conference to volunteer at the Deliveroo booth, I thought it would be interesting to also help out as a volunteer by talking to and helping attendees in the second half of the workshop. Even though I have never worked with image or text AIs, it is an interesting area and I thought it would be a great opportunity to learn more about how we use these tools at Deliveroo.

Then the twist - unfortunately, the person who was originally going to run the workshop was no longer going to be able to attend the conference! When asked if I would be interested in presenting at the start of the workshop, my two thoughts were: “Are you sure you meant to ask me?” and “This would be a great opportunity to push myself out of my comfort zone, and to learn even more about these technologies”.

It was very tempting to submit to imposter syndrome and think that I was not the right person for this, to ask the organisers to find someone else. But ultimately I realised that if I want opportunities to push myself, I need to let myself have them when they come along. Knowing that the attendees of this workshop would also not have experience or deep understanding of AIs meant that I was actually perfectly placed to make sure we were going into the right level of detail, and not making it too complicated or overwhelming!

## Finding subject matter experts

The first thing I knew I had to do was to learn as much as possible in the time I had before the workshop. Luckily there are lots of resources out there, and lots of people at Deliveroo willing to share their knowledge!

We knew that we wanted our main focus to be on [Amazon Lex](https://aws.amazon.com/lex/) and [Rekognition](https://aws.amazon.com/rekognition/), and I spent lots of time researching both of these tools, their uses, and how they would be integrated into other tools and systems. The AWS documentation was great for giving this overview, as well as exploring some Deliveroo code that implements them!

We were then able to reach out to individuals in Deliveroo who had actually worked on those implementations. Once we had found a Rekognition expert, we set up a session with everyone who was going to be speaking or helping at the workshop. This was a great opportunity for us to take lots of notes and ask lots of questions. Our expert took us through:
 * How the AI works
 * The specific feature it is used for in Deliveroo
 * How the team implemented it
 * All the things they had to consider when implementing it
 * What their plans for future improvements are

The next step was to take all of these notes and learnings and turn them into a cohesive presentation.

## Turning the content into my voice

I wanted to make sure that I wouldn’t just be reading off slides word for word and that I was able to explain the concepts in a natural way. Part of this was all the learning I did to make sure I really understood the content and part was turning it into my own voice! I took the notes we had taken during the expert session and through my own research, and extracted some really simple bullet points. Then I came up with a structure that made sense to me:
* What is Amazon Rekognition?
* Where do Deliveroo use it?
* Why do Deliveroo use it?
* How was it implemented, and how do we use the data it gives us?
* Considerations and caveats

After sorting my simple bullet points into these sections, I was able to flesh them out into my own words. I practised talking through each section both with the slides and without, and I didn’t worry about trying to make it the same every time. We also did several practice runs with both presenters and with all the volunteers to make sure that the presentation took the time we wanted it to, and so that everyone was familiar with all of the content. We also used this opportunity to flag anything that we needed to change or clarify.

## The workshop experience

All that was left was to actually run the workshop! Attendees were able to book onto the workshop using the conference app, the session had 60 spaces and was fully booked by the morning of the 23rd. After so much practice I wasn’t actually that nervous to present, and the 20 minutes whizzed by.

The group of attendees were very engaged and everyone really got into the activity. It was great to have time to talk to each group, answering their questions and hearing their ideas. Everyone approached the activity differently, with some groups using our Deliveroo example, and others coming up with their own. One of the most interesting parts for me was actually talking about the limitations of an AI like Rekognition, and how that generally wasn’t considered by people!

I’m really glad that I took this opportunity and really pushed myself out of my comfort zone. It was great having the motivation to learn a completely new technology and to be able to then pass on those learnings to other people. The WOSR conference was a fantastic and incredibly supportive community, and I learned that I loved sharing knowledge and encouraging others in their ideas. 

<figure style="text-align: center;">
![Myself and James King presenting](/images/posts/running-a-workshop-at-wosr/presenting.jpg)
*Myself and James King presenting*
</figure>

<figure style="text-align: center;">
![Attendees in breakout groups](/images/posts/running-a-workshop-at-wosr/attendees.jpg)
*Attendees in breakout groups*
</figure>

I’m sure this won’t be the last time that I push myself out of my comfort zone, and it certainly won’t be the last workshop I run. I’m already planning the next one! 

