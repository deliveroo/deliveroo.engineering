---
layout: post
title:  "Improving Password Security"
authors:
  - "Alec Muffett"
excerpt: >
    Passwords are a pivotal tool in customer account security, however
    they are frequently at risk from "reuse" - people choose one or
    two passwords and then use them *everywhere*, which brings a
    host of security problems...
---

We want our customers to be safe online, and we --- specifically the
Deliveroo Infrastructure Security team --- want to better protect our
customers' accounts.  Technically, we're starting from a good place:
our passwords are hashed using the `bcrypt` algorithm, a robust and
industry-standard password hash. The Rails default for `bcrypt` is to
run at strength 10, meaning 2<sup>10</sup> = 1024 rounds of hashing, a
reasonable work factor for a modern password hash.

However, not everything in the world is under our control.

Sometimes customers reuse their passwords at other sites, and
sometimes _those_ sites do not store their passwords under a robust
password hashing algorithm.  Worse, sometimes __those__ sites get
_"popped"_ --- bad people hack into them and exfiltrate password data,
often sharing their findings with the world through pastebin sites and
bulletin-boards.

These actions put at risk any site where the owner has reused the same
login name and password.

There are excellent free tools which our customers may use to help
discover if they are at risk --- for instance Troy Hunt's
[Have I Been Pwned?](https://haveibeenpwned.com/) website; and we
recommend use of such tools as an aid to password security.

But we want to be more proactive.

Therefore, from today, we will be informing our customers when we
determine that the password which they use for Deliveroo is publicly
known in some way.  We will contact the impacted customers to request
that they change their password, and advise that they also change
that password at other sites where it is also used.

Security suffers from an element of collective responsibility; it's
not fair that a security failure at one site should compromise the
credentials of another site, but it happens. Until we can mitigate the
problem of credential reuse more thoroughly, this is one step which we
at Deliveroo can take to help make everyone a little more secure.

*(press queries to [press@deliveroo.co.uk](mailto:press@deliveroo.co.uk), please)*
