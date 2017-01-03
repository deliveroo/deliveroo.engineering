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

## Naming branches, commits, and pull-requests

We orchestrate most of our work using a ticketing system (Jira). Assuming a
ticket ID'd `AB-123` and titled "Install the Mr Fusion",

- The branch should be named `AB-123/install-the-mr-fusion`. The case of the
  ticket ID and the slash are important.
- All commits pertaining to the ticket should include the ticket ID in the
  commit message. The preferred format is `AB-123: Install the Mr Fusion`.
- The pull request title should include the ticket ID. The preferred format is as
  for commit messages.

_Rationale_: having a consistent convention enables integrations. For instance,
the above ensures that commits and PRs are reported into Jira, making it
possible for someone to traverse links to read a story's implementation instead
of searching.

Note that [git-whistles](https://github.com/mezis/git-whistles) will do most of
this for you: naming the branch right, the PR when issuing it, and even pasting
the ticket description into your PR for better reviewer comfort!


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


## Commit messages

Writing good commit messages is important. Not just for yourself, but for other
developers on your project. This includes:

* new (or recently absent) developers who want to get up to speed on progress
* interested external parties who want to follow progress of a project
* any future developers (including yourself) who want to see why a change was
  made

### Content

A good commit message briefly summarises the "what" for scanning purposes, but
also includes the "why". If the "what" in the message isn't enough, the diff is
there as a fallback. This isn't true for the "why" of a change - this can be
much harder or impossible to reconstruct, but is often of great significance.

#### Example

```ABC-123: Set cache headers```

prefer:

```
ABC-123: Set cache headers

IE 6 was doing foo, so we need to do X.
See http://example.com/why-is-this-broken for more details.
```

#### Links to issue trackers

A link to a ticket in an issue tracker should not be seen as an alternative to
writing a commit message.

While a link can add some extra context for people reviewing a pull-request,
the commit message should stand on its own.  There's no guarantee that
the link will continue to work in the future when someone is looking through
the commit history to understand why a change was made.

### Tense

Write commit messages in the present tense. This follows the Git conventions
(matching messages generated by commands like `merge` and `revert`). It also
makes more sense when it's quoted in a revert commit. So for example "Fix bug"
and not "Fixed bug".


### Structure

Commit messages should start with a one-line summary no longer than 50
characters. Various Git tools (including GitHub) use this as the commit
summary, so you should format it like an email subject, with a leading capital
and no full stop. For example:

> AB-123: Leverage the best synergies going forward

You should leave a blank line before the rest of the commit message, which you
should wrap at around 72 characters: this makes it easier to view commit
messages in a terminal.


#### Example

Taken from [Tim Pope’s guidelines](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

> Capitalized, short (50 chars or less) summary
>
> More detailed explanatory text, if necessary.  Wrap it to about 72
characters or so.  In some contexts, the first line is treated as the
subject of an email and the rest of the text as the body.  The blank
line separating the summary from the body is critical (unless you omit
the body entirely); tools like rebase can get confused if you run the
two together.
>
> Write your commit message in the present tense: "Fix bug" and not "Fixed
bug."  This convention matches up with commit messages generated by
commands like git merge and git revert.
>
> Further paragraphs come after blank lines.
>
> - Bullet points are okay, too
> - Typically a hyphen or asterisk is used for the bullet, preceded by a
  single space, with blank lines in between, but conventions vary here
> - Use a hanging indent

### Recommended blog posts on this topic

* [5 useful tips for a better commit message](http://robots.thoughtbot.com/5-useful-tips-for-a-better-commit-message)
* [Every line of code is always documented](http://mislav.uniqpath.com/2014/02/hidden-documentation/)
