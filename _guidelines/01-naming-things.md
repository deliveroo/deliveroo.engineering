---
layout:     guidelines
title:      "Naming things"
subtitle:   "How to call bits of code, apps, and such"
collection: guidelines
permalink:  /guidelines/naming/
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

### Why we need guidelines

Engineering wisdom often says that code gets read an order of magnitude more
often it gets written.

Understanding what's written is paramount to building features, or, more
critically, addressing issues — you wouldn't want to have to dig into
documentation, or hunt for the appropriate person, when you're having to
diagnose an incident occuring in production.


#### Avoid lingo and acronyms

Lingo and acronyms make onboarding engineers much harder. Even after onboarding,
they're a source of pain as different teams can build up lingo that reflects
their particular concerns.

Recommendation: favour explicit terms over lingo, and expand acronyms.

- Good: _Minimum order value_, _Time of day_.
- Bad: _MOV_, _TOD_.

In non-code contexts (wiki pages, emails), it's fine to use abbreviations as
long as the first use in the document is expanded.
  

#### Use transparent names

Fancy names are a staple in software engineering. Who doesn't like a cool name
or a [backronym](https://en.wikipedia.org/wiki/Backronym)!

They're also often hard to interpret if you're not already aware of what they
stand for

Even more importantly, using a "fancy name" when naming classes, apps, or
repositories can be a smell that the purpose or scope is ill-defined.

Recommendation: give names that reflect the domain and usage:

- Good: `model-training-etl`, `operations-dashboard`
- Bad: `mysterymachine`, `atlas`


#### Consistent app/repo naming

We want it to be easy to locate the codebase for a given app, especially when
hunting down issues.

Fortunately we [honour 12-factor](https://12factor.net/codebase), which means
each app is backed by exactly one repo.

Recommendation: App names should be exactly `roo-{repo}-{env}`, with the `roo-`
prefix optional if unambigous. 

Examples: `restaurant-portal-staging`, `rooit-production` (with the caveat that
DNS places a 32-character limit on domain name parts).




