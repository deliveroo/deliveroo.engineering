---
layout: post
title:  "Reset, Rebase Workflow"
author: "Ben Darlow"
date:   2017-10-04 00:00:00
excerpt: >
  Rebase is one of git's most powerful features. Most-commonly used to rewrite history by squashing related commits, and for keeping your branch up to date with master (without introducing unrelated merge commits), it can also facilitate some pretty clever workflow tricks which when used judiciously can let you factor out parts of your work into separate pull requests.

---

Small, atomic commits are the gold-standard for a nice, clean git commit history. If you embrace this ideology in your working practice you may find yourself committing frequently, but whilst you're in the early stages of developing a feature it's quite possible you'll end up making decisions that you reverse-course on, or tweak as the concept solidifies.

Potentially this can mean you end up with a commit history containing many small 'work in progress' commits which you don't necessarily want to merge into master in their current form. Sometimes you'll make a change, then decide to solve a problem an entirely different way, undoing that change later before your feature branch is even merged. You may also end up writing code that — whilst it _supports_ your work — has no direct requirement that it be _part of_ the feature you're building.

Keeping those commits in your feature branch — to be merged at the point that feature is 'done' — might make sense, but it might make _even more_ sense to split them out into their own separate pull request, and there's a workflow I've been using for a while to do just that. But in order to benefit from this workflow, we need to step through the dark, scary door marked `git rebase`…

## If we are to be prepared for it, we must first shed our fear of it

<figure>
![I stand here, before you now, truthfully unafraid](/images/posts/reset-rebase-workflow/morpheus.jpg)
</figure>

To paraphrase [Angus Croll][angus-croll-javascript], _you can't master a tool until you know it inside out – and fear and evasion are the enemies of knowledge_, so I encourage you _not_ to be [scared of git rebase][dont-be-scared-of-git-rebase]! There are numerous benefits to the workflow I'm about to describe, which you too can enjoy by conquering your fear of `git rebase`:

- [They're easier to review (and _get_ reviewed!)][pr-roulette]
- They make conflicts less likely, and easier to fix when they happen
- If you need to revert a change, it's easier to do this, and there are fewer side-effects
- You can reduce the cognitive overhead by focusing on the problem you're _really_ trying to solve
- The newly-separated feature is available earlier, and potentially could benefit your co-workers or users.

Focusing on that last one for a moment, let's say that we have a pull request for a branch called `new-widget-search`, which contains our shiny new widget search page. In amongst that code is the first implementation of the new widget, and it's working pretty well! There's no reason that this feature can't be merged into master (Continuous Integration permitting), and as it happens your co-worker Alison is nearly ready to start working on the new widget _editor_. Let's kill two birds with one stone by unblocking her and simultaneously making our pull request smaller.

## Branch, Rebase, Reset…

First of all, let's pull `master` down and rebase on top of it, so that we can be certain we're not missing anything important that's been merged into master in the time since the work in the `new-widget-search` branch began. Then, to make sure that nothing we do here is going to affect our existing branch, we can create a _new branch_ off of it:

```shell
$ git checkout master
$ git pull
$ git checkout new-widget-search
$ git rebase master
$ git checkout -b new-widget
```

Knowing that this branch only contains commits _ahead_ of master, we can then run this:

```shell
$ git reset master
```

…which _removes_ all commits in the branch, points `HEAD` to the tip of master, _but_ most importantly **leaves all changes from `new-widget-search` as unstaged changes**. One of the great things about this is that all the intermediary states of the files that changed are squashed into their final resulting state:

```shell
$ git status -s
 M app/assets/stylesheets/application.scss
 M app/controllers/widgets_controller.rb
?? app/assets/stylesheets/components/_new-widget-search.scss
?? app/assets/stylesheets/components/_new-widget.scss
?? app/views/components/new-widget-search-page.jsx
?? app/views/components/new-widget-search.jsx
?? app/views/components/new-widget.jsx
```

Here we can see the changes we've been making as a bunch of new files, plus a couple of modifications to existing source files. Since we want this pull request to comprise _just_ the functionality related to the `new-widget` component, we'll now want to selectively stage some of these changes, commit them, and discard the rest. The easy bit is to add the new files we want:

```shell
$ git add app/views/components/new-widget.jsx
$ git add app/assets/stylesheets/components/_new-widget.scss
```

The changes to `application.scss` and `widgets_controller.rb` are a little trickier, since both of these contain new code just related to `new-widget`, _as well as_ new code related to the larger `new-widget-search` feature branch which we _don't_ want to commit here. What we need to do is _selectively stage_ part of the commit. This is a lot easier to do if you have a GUI git client (I use [Git Tower][git-tower]) but you can do it from the command line too:

```shell
$ git add -p app/assets/stylesheets/application.scss
```

This will prompt you to create a patch:

```diff
diff --git a/application.scss b/application.scss
index 0b91044..1183059 100644
--- a/application.scss
+++ b/application.scss
@@ -8,6 +8,8 @@
 // Components
 @import 'components/buttons';
 @import 'components/modal';
+@import 'components/new-widget';
+@import 'components/new-widget-search';

 // Pages
 @import 'pages/home';
Stage this hunk [y,n,q,a,d,/,e,?]?
```

Since we don't want to include the entirety of this hunk — just the line that adds `components/new-widget` — we'll want to edit this interactively, so press `e` to launch the diff editor, where you'll see something like this:

```diff
# Manual hunk edit mode -- see bottom for a quick guide
@@ -8,6 +8,8 @@
 // Components
 @import 'components/buttons';
 @import 'components/modal';
+@import 'components/new-widget';
+@import 'components/new-widget-search';

 // Pages
 @import 'pages/home';
# ---
# To remove '-' lines, make them ' ' lines (context).
# To remove '+' lines, delete them.
# Lines starting with # will be removed.
#
# If the patch applies cleanly, the edited hunk will immediately be
# marked for staging. If it does not apply cleanly, you will be given
# an opportunity to edit again. If all lines of the hunk are removed,
# then the edit is aborted and the hunk is left unchanged.
```

To unstage the change which adds the reference to `'components/new-widget-search'`, simply delete that whole line, then save and close the file. Repeating the same process with `widgets_controller.rb` we now see the following output when we run `git status -s`:

```shell
$ git status -s
MM app/assets/stylesheets/application.scss
A  app/assets/stylesheets/components/_new-widget.scss
?? app/assets/stylesheets/components/_new-widget-search.scss
MM app/controllers/widgets_controller.rb
?? app/views/components/new-widget-search.jsx
A  app/views/components/new-widget.jsx
?? app/views/containers/new-widget-search-page.jsx
```

We can now safely create a commit from _just_ the staged changes:

```shell
$ git commit -m "Add new-widget component"
```

Once you're done, you can push your new branch, create another pull request and kick off the review process to get it merged into master! Now might be a good point to let Alison know that the `new-widget` component is ready to go, so she can start building her own feature that makes use of it.

## Committing with hindsight

<figure>
![Oh man, it’s a scenario *four*.](/images/posts/reset-rebase-workflow/morty.jpg)
</figure>

Once you've done all of that, you _could_ choose to discard the unstaged changes you're left over with and then rebase your original branch of top of master. If you did, all of the changes related to `new-widget` will magically disappear from your branch, making your PR smaller. However, if you were building your feature branch from many 'work-in-progress' commits, you might also want to take this opportunity to do some tidying up.

For any given non-trivial problem, your understanding of the problem will almost always be a lot more coherent at _the end_ of the process than it was at the beginning. This is inevitably reflected in the commits your solution is comprised of, even if the final outcome was far more elegant and effective than it may have been to begin with. Ideally we'd be able to benefit from hindsight from the beginning of our work, and luckily that's something that the _reset-rebase_ workflow gives us!

Let's assume that your work on the main `new-widget-search` feature is pretty close to complete; after a few rounds of revision and refactoring the branch is looking good. It's just a shame about the many messy `WIP` and `Fix typo` commits! Luckily the unstaged changes we now have in our working copy give us the perfect opportunity to create some tidy, feature-specific commits. And since all the changes have been squashed already, we don't need to worry about conflict resolution from intermediary stages of development.

Following the same process as above, create a new branch from the `new-widget` branch you created earlier:

```shell
$ git checkout -b new-widget-search-rebased new-widget
```

At this point, using exactly the same procedure as before, we can start creating a series of _structured, atomic commits_ that reflect units of related work, by staging new files and relevant lines of _new code_ from existing files. Once all that's done, a quick check of the history should reveals this much cleaner series of commits:

```shell
$ git log
commit 46aa1b9bdda9e9d96f978381503a983e9e890bad
Author: Ben Darlow <ob.fusc@t.ed>
Date:   Thu Sep 7 16:31:26 2017 +0100

    Implement New Widget Search page

commit 77407db02c62df3326a0f380818457aadbc3c1ca
Author: Ben Darlow <ob.fusc@t.ed>
Date:   Thu Sep 7 16:15:58 2017 +0100

    Implement new widget

commit 707548c16a44f629584fc4bae93b8014888c19a8
Author: Ben Darlow <ob.fusc@t.ed>
Date:   Thu Sep 7 14:29:04 2017 +0100

    Initial commit
```

Once you're happy with the state of this new feature branch, you can safely delete the old branch, and rename the newer branch to `new-widget-search` in its place:

```shell
$ git branch --delete --force new-widget-search
$ git branch --move new-widget-search-rebased new-widget-search
```

If you already pushed the branch, you'll also want to ensure you set the remote URL for this newer branch to the existing one, then _force push_ to overwrite the old branch. Of course, all the usual caveats about using force push apply: if anybody else is working on this branch too, make sure you talk to them before you force push and wipe out their changes!

```shell
$ git branch --set-upstream new-widget-search origin/new-widget-search
$ git push --force origin new-widget-search
```

After this, you should be in a position to create another, new pull request based on your actual feature, which should be tidier, smaller and — with a bit of luck — easier to review!

[dont-be-scared-of-git-rebase]: https://nathanleclaire.com/blog/2014/09/14/dont-be-scared-of-git-rebase/
[angus-croll-javascript]: https://javascriptweblog.wordpress.com/2011/02/07/truth-equality-and-javascript/
[pr-roulette]: /2017/09/06/play-pull-request-roulette.html
[git-tower]: https://www.git-tower.com/
