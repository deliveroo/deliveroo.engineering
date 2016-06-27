---
title:      "Meta"
subtitle:   "Guidelines about guidelines"
---

#### Why we do this

In a large team, building and maintaining multiple software assets, code
consistency and acquired good practices matter.

Having solid guidelines is a pillar of maintainable software, much like
continuous integration and a solid review process.


#### Using guidelines

We recommend that all new starters read the guidelines documents relevant to the
technologies they'll be using.

When reviewing any code, the guidelines apply: it is seriously frowned upon not
to follow them!

Of course, guidelines aren't law — one may ignore them, but there must be a
justification, and preferably a comment in the code.
"My team doesn't have time", or other forms of the [threshold of
misery](http://kerrizor.com/blog/2016/05/09/returning-from-the-threshold-of-misery),
usually aren't valid reasons to skirt the guidelines :smiling_imp:

#### Changing guidelines

Coding guidelines are curated collectively.
This is the process we choose to follow:

1. Anyone can submit a pull request to change, or add to any guideline document
   (including this one).

2. Changes are reviewed by lead engineers. Anyone can comment on the content.

3. During a 1 week grace period, :thumbsup: and :thumbsdown: are collected on the
   pull request (+1 comments are ignored).

4. If the change has collected enough :thumbsup:, a lead engineer merges it.
   <br/>
   This site is automatically updated.

From this point onwards, all engineers in the team should follow the updated
guidelines for _new_ code, and strive to bring _old_ code in compliance.

#### Notifying about changes

When a pull request is issued, the `#geeks` and `#tech-leads` channels in Slack
are pinged automatically (through Zapier).

Nothing is (currently) done automatically when a pull request is merged, though,
so you may want to broadcast in `#geek` or via email as appropriate.


#### Formatting guidelines

This site uses Jekyll and Github Pages, so Markdown is favoured.

Use of emoji is encouraged!

Please respect an 80 column limit in the source to facilitate reviews.

