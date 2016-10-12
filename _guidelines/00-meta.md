---
layout:     guidelines
title:      "Meta-Guidelines"
subtitle:   "Guidelines about guidelines"
collection: guidelines
permalink:  /guidelines/meta/
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

### Why we do this

In a large team, building and maintaining multiple software assets, code
consistency and acquired good practices matter.

Having solid guidelines is a pillar of maintainable software, much like
continuous integration and a solid review process.


### Using guidelines

We recommend that all new starters read the guidelines documents relevant to the
technologies they'll be using.

When reviewing any code, the guidelines apply: it is seriously frowned upon not
to follow them!

Of course, guidelines aren't law — one may ignore them, but there must be a
justification, and preferably a comment in the code.
"My team doesn't have time", or other forms of the [threshold of
misery](http://kerrizor.com/blog/2016/05/09/returning-from-the-threshold-of-misery),
usually aren't valid reasons to skirt the guidelines :smiling_imp:

Note that the code in a pull request should follow the guidelines, _even_ if the
author of the PR isn't the author of the original code. This is how old code
gets updated over time.

### Changing guidelines

Coding guidelines are curated collectively.
This is the process we choose to follow:

1. Anyone can submit a pull request by creating a branch named 
   `guidelines/whatever-it-relates-to` to change or add to any existing 
   guideline document (including this one).

2. During a suitable grace period, feedback is collected on the pull request in 
   the form of comments, :thumbsup: or :thumbsdown:. Anyone can comment on the
   changes.

3. If the proposed changes have collected enough :thumbsup:, a lead engineer 
   merges it. This site is automatically updated.

From this point onwards, all engineers in the team should follow the updated
guidelines for _new_ code, and strive to bring _old_ code in compliance - over
time, as mentioned above. It is not recommended to upgrade old code in bulk, as
this can be much more difficult to test/QA properly.

### Notifying about changes

When a pull request is issued, the `#geeks` and `#tech-leads` channels in Slack
are pinged automatically (through Zapier).

Nothing is (currently) done automatically when a pull request is merged, though,
so you may want to broadcast in `#geeks` or via email as appropriate.


### Formatting guidelines

This site uses Jekyll and Github Pages, so Markdown is favoured. Jekyll uses
[Kramdown][kramdown]-flavoured Markdown, so you may need to change your formatting
slightly from Github-flavoured Markdown.

You may respect an 80 column limit in the source to facilitate reviews, or not
if you're content with Github wrapping lines for you.

Use of emoji is encouraged! :grin: The same aliases as standard Slack emoji work.

#### Adding a Table of Contents

Kramdown can generate a Table of Contents for you automatically, using the 
headings in your document as the items in the list. To use this, add the 
following Markdown to the top of your document (immediately after the Front 
Matter):

```markdown
## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}
```

This will add a heading with the text _Table of Contents_ which _doesn’t_ 
appear in the table of contents itself, followed by the TOC. The list item
shown here will be automatically replaced with the TOC contents.

#### Adding footnotes

When adding inline references to external sites, you may wish to use footnotes
to capture these, which are then displayed at the bottom of the guidelines
page. To use these, simply create a reference to the footnote in the location
you wish the link to appear, e.g.

```markdown
The name _Ruby_ was chosen in part because it is Yukihiro Matsumoto’s birthstone[^ruby].
```

You can then follow this in a suitable location (ideally close by) with the 
actual footnote reference. This can actually be any valid Markdown, but for
simplicity’s sake, you may just want to use a link to the reference source:

```markdown
[^ruby]: [The name "Ruby"](https://en.wikipedia.org/wiki/Ruby_(programming_language)#The_name_.22Ruby.22)
```

#### Adding code samples

Markdown supports several different types of indicating code blocks, but to
take advantage of syntax highlighting, use the following format (without any
indentation):

```markdown
  ```ruby
  def what?
    42
  end
  ```
```

[kramdown]: http://kramdown.gettalong.org/documentation.html
