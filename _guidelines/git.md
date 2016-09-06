---
layout:     guidelines
title:      "Git / Source Control"
collection: guidelines
---

# Deliveroo Git Usage Guide

*A mostly reasonable approach to Git*

## Table of Contents

  1. [Force Pushing](#force-pushing)

## Force Pushing

Force pushing is one of the **destructive** functions of git in that it unconditionally overwrites the remote repository with whatever you have locally, possibly overwriting any changes that a team member has pushed in the meantime.

When force pushing **always** use `--force-with-lease` to ensure there are no remote changes you are will destroy by accident.

Remember, when performing _destructive_ commands that effect remote: **Communication is key.**

- [Force Pushing Master:](#force-pushing--master) **Nope.** This is something that should never be done by anyone. Master should always be protected from force pushing and this should **never** be removed. If you need to undo something that is in master **revert** commits that are causing you issues and pr them in.
- [Force Pushing Your Own Branch:](#force-pushing--own-branch) **Sure.** If no one else is working on it and you created the branch then force push at will. If someone has come and asked you if they can add something to your branch then check with them *before* force pushing anything.
- [Force Pushing Someone Else's Branch](#force-pushing--own-branch) **Sometimes.** Talk to them about this before modifying their branch to ensure you know the full situation before force pushing.
