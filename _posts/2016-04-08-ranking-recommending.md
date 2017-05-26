---
layout: post
title:  "Ranking and Recommending"
author: "Julien Letessier"
date:   2016-04-08 00:00:00
exerpt: >
  There can be too much of a good thing.

  When faced with multifarious choices on an e-commerce website, users can
  easily get frustrated; a solid user interface to help the selection process
  can help, but can you imagine your Google search results not being ordered by
  relevance?


  This talk introduces approaches and techniques for ranking and recommendation
  in an e-commerce context, and elaborates on using neural networks and
  collaborative filtering to power sorting of search engine results.


  This talk aims to provide just a birds-eye view of these topics as a platform
  for deeper research.  You don't need to be a rocket scientist to read through!

---

This first deck has just the slides; given I tend to keep my slides light on
text, you might want to scroll down and read the summary - or the version with
presenter notes.

<script async class="speakerdeck-embed" data-id="82eadb1220844e1b8f4eede8d4bfd006" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

Why are ranking and recommending important in an e-commerce setting?

Simply because users can have choice overload, or be put off by the very first
results they see—many readers will be familiar with the important of what's
"above the fold". Scrolling is painful!

"Ranking" intuitively means "put the good things on top", so one needs two
things to rank: a definition of "good", and some mechanism to compare two things
in terms of "goodness".

"Good" here is the business outcome a ranker is trying to optimise (sort
against); the likelihood of the user to order is typical, although one might
want to blend this with revenue or average basket value (large baskets are
"better" than small ones).

To add to the complexity, we'd want ranking to take into account the _user_
perusing search themselves — e.g. their age, gender, order history might be
relevant to providing a better ranked list or offerings.

A naive approach consists in sorting search results by popularity, or measured
historical likelihood-to-order, or user ratings. Or... some form of blended
average of all of these.

This technique can provide good results in some cases, but has limitations.
It is prone to bootstrapping issues (how to rank a newly-listed product?) and
cannot model nonlinear relations between the sorting criteria and the expected
outcome.

The presentation outlines neural networks and their mechanics, as a generalist
modeling technique applied to the ranking problem. While sometimes daunting, NNs
can be simple to train and use, and almost always predict better than humans (or
more conventional modeling techniques).

The last part of the presentation focuses on recommending, which is really just
ranking by taking the user into account. While neural networks can be used for
recommendations too, we detail the workings of a variant of collaborative
filtering that's relatively easy to build and apply to e-commerce.

<script async class="speakerdeck-embed" data-id="0bd5e3edda564e2dad08073dff9344a7" data-ratio="1.41436464088398" src="//speakerdeck.com/assets/embed.js"></script>


For further reading, I recommend (pun intended) reading:

- my [more in-depth exploration](http://dec0de.me/2014/10/learning-to-rank-1) of
  neural networks used in an e-commerce search engine.
- two excellent books, [Programming collective
  intelligence](http://shop.oreilly.com/product/9780596529321.do) and [Machine
  learning for hackers](http://shop.oreilly.com/product/0636920018483.do)
- Udacity's [online course](https://www.udacity.com/course/deep-learning--ud730)
  on "Deep learning" (free)

