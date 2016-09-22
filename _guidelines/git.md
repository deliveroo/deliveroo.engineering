---
layout:     guidelines
title:      "Git & Source Control"
subtitle:   "Guidelines for using Git source control"
collection: guidelines
---

## Table of Contents
{:.no_toc}

1. Automatic Table of Contents Here
{:toc}

## Force Pushing

Force pushing is one of the _destructive_ functions of git in that it unconditionally overwrites the remote repository with whatever you have locally, possibly overwriting any changes that a team member has pushed in the meantime.

You may want to amend or squash commits to keep a clean history, but know that this is a nice to have, and shouldn't be used when it will inhibit others to continue working uninterrupted.

When force pushing _always_ use `--force-with-lease` to ensure there are no remote changes you may destroy by accident.

Remember, when performing _destructive_ commands that effect remote: **Communication is key.**

### To Master
{: #force-pushing-master}

**Never**. This is something that should never be done by anyone. Master should always be protected from force pushing and this should _never_ be removed. If you need to undo something that is in master _revert_ commits that are causing you issues and pr them in.

### To Your Own Branch
{: #force-pushing-your-own-branch}

**Yes**. If no one else is working on it and you created the branch then force push at will. If someone has come and asked you if they can add something to your branch then check with them *before* force pushing anything.

### To Someone Else's Branch
{: #force-pushing-someone-elses-branch}

**Sometimes**. Talk to them about this before modifying their branch to ensure you know the full situation before force pushing.

### To A Merged Branch
{: #force-pushing-merged-branch}

**Never**. Force pushing a branch that has been merged to a branch that has a large exposure (for example staging or master) is not recommended. Merging to that branch again will be messy and problematic, and force pushing the branch with exposure will be even more so.

### To Remove Sensitive Data
{: #force-pushing-removing-sensitive-data}

**Yes**. If sensitive data has been pushed by accident (private keys, stats or other company secrets) force push in accordance with the other rules (where possible) to expunge them from git history. Know that _any_ information pushed should be deemed compromised and that anyone with a checkout of the code may retain a copy on their machine and any third parties (Github, Travis etc) whom might have caching that keeps the data alive. Notify senior staff of the issue and coordinate with them to get it sorted.
