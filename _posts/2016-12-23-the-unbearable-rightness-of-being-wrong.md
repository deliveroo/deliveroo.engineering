---
layout: post
title: "The Unbearable Rightness of Being Wrong (A Programmer's Guide to Sanity)"
author: "Kriselda Rabino"
excerpt: >
  Earlier this year, some awesome people who "read and write Ruby good" met at an event called RailsConf and delivered this poignant tweet in a bottle: ***"I love looking at my old code and hating it. It means I'm growing."***


  This simple reflection by the brilliant Sandi Metz really resonated with my own - not just surrounding code quality, but the journey of developing a wider architectural awareness as well as the communication skills & empathy needed to build good software efficiently.
hide_excerpt_on_post: true
---

Earlier this year, some awesome people who "read and write Ruby good" met at an event called RailsConf and delivered [this poignant tweet in a bottle](https://twitter.com/saronyitbarek/status/728692957415538688):


<blockquote class="twitter-tweet" data-lang="en" align="center">
<p lang="en" dir="ltr">&quot;I love looking at my old code and hating it. It means I&#39;m growing.&quot; - <a href="https://twitter.com/sandimetz">@sandimetz</a> <a href="https://twitter.com/hashtag/railsconf?src=hash">#railsconf</a></p>&mdash; Saron (@saronyitbarek) <a href="https://twitter.com/saronyitbarek/status/728692957415538688">May 6, 2016</a>
</blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>


This simple reflection by the brilliant [Sandi Metz](https://www.sandimetz.com) really resonated with my own - not just surrounding code quality, but the journey of developing a wider architectural awareness as well as the communication skills & empathy needed to build good software efficiently.

Not long after, I joined the Engineering lot here at Deliveroo and my growth rate skyrocketed (let's ignore the fact I'm 5'1 high in physical terms!), amplifying its meaning even more.

**Proof -** here's a serial Post-it that keeps making its way into our retrospectives:

<figure class="small">
![Graph on a Post-It: Comfort Zone v Knowledge](/images/posts/the-unbearable-rightness-of-being-wrong/comfortzone-v-knowledge.jpg)
</figure>

And this, in my opinion, is the most important tool any programmer needs to enjoy a life of code-writing zen. The ability to face the incessant unknown with humility and an adventurous curiosity. Not to mention the secret weapon words:

**"I don't know anything about that... yet!"**

Unfortunately, it's way too easy to fall victim to these alternative "I don't know" suffixes:

- **"... so I'm not going to ask questions about it, because I might sound stupid"**
- **"... so I'm not going to review this pull request, there's no value in that"**
- **"... so I'm not going to commit this code, everyone will see it and judge my abilities"**
- **"... and I specialise in this particular thing anyway; that's good enough, I should just keep doing what I'm already awesome at"**
- **"... so hells no am I writing a public blog post for the engineering team"** (hashtag SeeWhatIDidThere)

In fact, all of these are perfectly effective growth-*stunters*. Progression requires discomfort. This is why building collaborative, supportive teams and the right environment where it's okay to get things wrong is just as important as building software itself.

## Caching and Buildpacks and Slugs, Oh My!

Fortunately, the team here are just that - ready to help and lend a hand when [Stack Overflow](stackoverflow.com) just doesn't cut it. And it turns out being a Roo isn't just amazing for the variety of food at your fingertips - we get served a wide range of tasty technical challenges too.

I've already managed to ship code across a spectrum of areas, from the APIs supporting the app our restaurants use & internal event bus, to helping improve our customer analytics and mobile attribution, and even reacquainting with "The Frontend", getting to know ES6, React and the ever-scaling array of modern build tools.

To illustrate the benefits of my points above, here are just two slices of the **'Stuff Outside My Comfort Zone I Know Way More About Now' cake** my brain has consumed in the last 5 months.

### HTTP Caching in Rails

As we do the startup thing and move away from a monolith towards a growing number of services, there are numerous factors to consider, not just around building or maintaining the applications themselves, but ensuring they communicate with each other really well. A lot of these are documented in [our open guidelines for your reading pleasure](http://deliveroo.engineering/guidelines/api-design/).

One of these considerations is reducing roundtrips between the client and the server with suitable [HTTP cache headers](https://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html).

<figure class="small">
![Cache All The Things!](/images/posts/the-unbearable-rightness-of-being-wrong/cache-the-things.jpg)
</figure>

I remember my first real deep dive into HTTP caching whilst pairing with my team member, Mathilda. All the various Cache Control options, the subject of Conditional Requests and Etags, figuring out the best way to implement it all in a reusable way for upcoming endpoints without over-designing a solution - there were a lot of new concepts to try get right and potentially get very wrong.

However, this was also a great opportunity to demystify something quite important when it comes to building performant services, whilst revising many other fundamentals of HTTP.

With a mix of research, constructive code reviews and team knowledge-sharing, we speed-learnt a few best practices and helped set some initial standards for our internal API going forward.

By the way, I should've called this section **Understanding HTTP Caching Takes Time**. Actually implementing all those crazy concepts in Rails? It took about 5 lines of code:

```ruby
def show
  @sloth = Sloth.find(params[:id])
  expires_in(5.minutes, "must-revalidate": true, public: false)
  # responds with 304 if not stale

  if stale?(@menu, public: false)
    render json: SlothSerializer.new(@sloth)
  end
end
```

**Bonus story:** These topics fascinated me so much I gave a spontaneous [lightning talk](https://www.youtube.com/watch?v=WnlgKWCt8wQ) at this year's [EuRuKo](http://euruko2016.org) entitled The HTTPancake Request (no name regrets!). I also prepared an extended version of it for a [Women Hack for Non-Profits](http://www.womenhackfornonprofits.com) Tech Talks event at Twitter. You can find the slides for that [here](http://slides.com/krissygoround/httpancake-5#/).


### Custom Buildpacks aka Does My Slug Look Big In This?

We use [Heroku](https://www.heroku.com) to build, run and scale our apps. Each time you push to a repository, a compiler optimizes your application for distribution by pre-packaging and compressing it into something called a "slug". Obviously, the larger your codebase and dependencies, the bigger your slug size, and [Heroku impose a 300MB limit (post-compression)](https://devcenter.heroku.com/articles/slug-compiler#slug-size) for any one project.

This is one good reason to try reduce the monolith and embrace a multi-service architecture. In the meantime, there were a few changes we could implement to take us out of that slug size danger zone and keep us shipping.

<figure class="small">
![Dieting Slug](/images/posts/the-unbearable-rightness-of-being-wrong/fat-slug.jpg)
</figure>

One of the workarounds was to reduce the size of our dependencies, removing documentation and test files within select gem folders from the slug itself. This seemed like a simple enough task, as Heroku already let you [configure a `.slugignore` file in your project's root to specify exclusions](https://devcenter.heroku.com/articles/slug-compiler#ignoring-files-with-slugignore), much like .gitignore.

Unfortunately, it turned out the cleanup based on this configuration occurs before dependencies are installed, preventing us from solving our particular problem.

Luckily, others had already encountered this wall and I found this [open source custom buildpack](https://github.com/deliveroo/heroku-buildpack-post-build-clean) that mimicked the same functionality for any files post-build, simply by including a new file in your project's root called `.slug-post-clean`.

Of course, things are never that easy and though this buildpack covered most of our needs, it didn't cater for wildcards, which we needed due to compiled gem folders including versions in their name. Basically, we wanted our `.slug-post-clean` file to look something like this:

```
vendor/bundle/ruby/*/gems/sass-*/test
vendor/bundle/ruby/*/gems/nokogiri-*/test
```

It looked like I was going to have to wear my super dusty bash scripting hat and implement some file globbing capabilities.

I forked the repo, whipped up a quick and dirty sample Rails app to experiment with and got to work, refactoring some bits along the way. Once reviewed, we tested it on our staging instance and after a quick patch to reduce the output flooding the build logs, we successfully ran a production deploy with a ~10MB drop in slug size.

You can find this version of the buildpack [here](https://github.com/deliveroo/heroku-buildpack-post-build-clean) in case it comes in handy.


## Bring On The New Year

I look forward to watching [Deliveroo](https://deliveroo.co.uk) continue to grow freakishly fast, and myself alongside it over the next year. Unfortunately, staring at delicious food all day means I'll probably have to deal with the belly-based kind of growth too. In any case, I hope you took away something from this post, even if it's just the nice feeling that other developers encounter doubt too, and that's it's okay, embrace it.

Now, please enjoy this panda trying to be bigger by crawling on a snowman and it all going terribly wrong.

<figure class="small">
![Panda + Snowman](/images/posts/the-unbearable-rightness-of-being-wrong/panda-snowman.gif)
</figure>
