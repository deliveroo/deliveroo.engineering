---
layout: post
title:  "Determinating a Scavenger Hunt"
author: "Grace Chang"
excerpt: >
 The Deliveroos rose from the ashes of the experimental fire. Their war to grow the product had raged for decades, but the final battle would not be fought in the future. It would be fought here, in our present. Tonight...

---

## Come with Me if You Want to Grow

The Growth Team at Deliveroo, as the name suggests, is heavily invested in experimenting with new features to grow the product. Any new feature is usually a calculated experiment that we measure and analyse to ensure we make the right decision.

Recently, the team shipped a new feature that took several months of engineering work. Of course, we had to celebrate in a spectacular fashion. We decided to do a puzzle-solving [scavenger hunt](https://www.inthehiddencity.com/london/) in teams (among other [fun activities](http://www.novelty-automation.com/)).

## Nice Night for a Walk

So what does a scavenger hunt have to do with experimentation? Well, we looked at our given conditions:

* We have a fixed number of teams.
* We have a set of people with unique names.
* We needed to randomly assign these people into those teams.

That sounded quite familiar...

It turns out that they're the same requirements for assigning our product users to variants of an experiment.

## You are Determinated

We've been working on an improved experimentation framework to do these assignments, obviously  named Determinator. The algorithm works like this:

1. Take a unique identifier (e.g. a UUID).
   This makes sure we don't have any clashes.
2. Concatenate it with the unique identifier of the experiment (i.e. the name).
3. Hash it using MD5.
   Using a cryptographic hash means the bits will be randomly distributed.
4. Take a modulo of the resulting hash and determine the variant.
   We don't need the whole thing, so we just take a chunk of the bits.
5. ???
6. Profit!

The benefit of this method is that the result will always be the same, ie. deterministic (assuming the variants are always sorted in the same way). By making the assignment deterministic, we don't need to store this information -- it can just be regenerated again and we are always guaranteed that the results will be the same. It's also a lightweight calculation for computers that even mobile clients could do (in theory), so this also solves the issue of scaling.

While we didn't need a full-fledged experiment, it was still a fun way to test our algorithm to see how well it worked. So we wrote this random team assignment script.

```ruby
#!/bin/ruby
require 'digest/md5'
require 'active_support/inflector'

variants = { giraffes: 1, sloths: 1, red_pandas: 1 }
captains = { giraffes: 'Sarah Connor', sloths: 'Kyle Reese', red_pandas: 'Ed Traxler' }
names = %w(Names omitted for privacy but imagine 15 unique ones here)

def indicator_for(guid)
  Digest::MD5.digest(guid).unpack("nn").last
end

def variant_for(variants, indicator)
  variant_weight_total = variants.values.reduce(:+)
  scale_factor = 65_535 / variant_weight_total.to_f

  previous_upper_bound = 0
  variants.each do |name, weight|
    new_upper_bound = previous_upper_bound + scale_factor * weight
    return name if indicator <= new_upper_bound
    previous_upper_bound = new_upper_bound
  end

  raise ArgumentError, "A variant should have been found by this point; there is a bug in the code."
end

def sort_teams(names, variants)
  names.each_with_object({}) do |name, teams|
    indicator = indicator_for(name)
    variant = variant_for(variants, indicator)
    (teams[variant] ||= []) << name
  end
end

def print_teams(sorted_teams, captains)
  sorted_teams.each do |team, names|
    puts "Team #{team.to_s.titleize} (Captain: #{captains[team]})"
    puts names.join(", ")
    puts "\n"
  end
end

print_teams(sort_teams(names, variants), captains)
```

The result:
```
Team Sloths (Captain: Kyle Reese)
Names, for, but

Team Giraffes (Captain: Sarah Connor)
omitted, imagine, 15, here

Team Red Pandas (Captain: Ed Traxler)
privacy, unique, ones
```

For our scavenger hunt, we ended up with 3 teams of 6 people each, all randomly assigned (minus captains, for an unrelated reason). All that remained was to solve some puzzles.

## The Data Could be Called 'Results'

In a thrilling battle of wits, Teams Red Panda, Giraffe, and Sloth trekked through London City chasing puzzle after puzzle, with some well-deserved breaks in between. Some of the hints were tricky, but all the teams managed to complete everything by the combined brain powers of the Growth Team.

Who won in the end? Team Red Pandas eked out a close win against the rest.

| Team       | Time     |
| ---------- | -------- |
| Red Pandas | 01:11:08 |
| Giraffes   | 01:37:17 |
| Sloths     | 02:06:10 |

Congratulations, Red Pandas! 🎉
And...

## We'll Be Back.

<figure>![The Determinator](/images/posts/determinating-scavenger-hunt/determinator.jpg)</figure>

We're really excited to see real-life applications for Determinator before shipping it. Once we've fully tested it and ironed out all the kinks, we'll be releasing it to the open-source community, so be sure to keep an eye on this space for updates!
