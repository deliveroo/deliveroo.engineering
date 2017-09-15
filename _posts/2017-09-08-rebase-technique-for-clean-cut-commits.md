---
layout: post
title:  "A rebase technique to achieve clean-cut Git commits"
author: "Evelina Vrabie"
excerpt: >
  In my [previous article](/2017/09/06/play-pull-request-roulette.html) I went through some DOs and DON'Ts for mastering Pull Requests and get them reviewed as quickly as possible. I'm following that by illustrating a Git rebase technique that can help you achieve clean-cut commits which allow your reviewers to read your PR like a story with well-defined chapters.
---

## I am a cats and Git rebase person

In the world of `dogs` vs `cats`, `chocolate` vs `whipped-cream` and Git [merge][git-merge] vs [rebase][git-rebase], I am the latter. Like for many other things in software, [there is a flame war out there][so-merge-vs-rebase] on "Merge-Vs-Rebase" so I'm not going to pour more gasoline on that :) If `rebase` is not your thing, that's totally fine, feel free to stop here.


My appreciation for Git `rebase` stems from being a "clean-commits" practitioner, which means that I like having a clean commit history and some other things that go along with that. I've mentioned a few in [my previous article][pr-roulette]. I have some more about sanitizing your repository, that can be used no matter in which camp you find yourself.

### Properly naming your branches 

I prefer `ticket-number-short-summary-of-changes` vs `ticket-number/short-summary-of-changes`. If you use a Git GUI like [Tower][git-tower] or [SourceTree][sourcetree], the second style will collapse the description by default, folder-style. If you have more than 5 branches and you're looking to quickly `checkout` one of them, you might need to expand a few to find the one you want. If you use the command-line, it's easier to start typing and press a key to auto-complete the branch name, so that's not an issue. 

### Keep your repository clean

I've seen repositories with hundreds of branches lying around, long after they've served their purpose. I prefer to sanitize my repository and delete a branch immediately after it has been successfully merged back into its parent. You don't need to worry about losing anything, in GitHub you can restore the branch after deletion. If you're not using GitHub, then [git reflog][git-reflog] is your best option to restore it. It takes a bit of discipline to clean up after yourself, but in the long run, it will result in a clean repo that won't scare a new joiner who checks out your project.

### To squash or not to squash commits

Before merging your branch into its parent you could take it one step further and [squash][git-commit] all your commits into a single one containing all messages. This way, you have a single point in time with all the changes that you've made. It's easy to revert all-at-once, too. Your production-ready branch history will read like a book with well-defined chapters. It works well if the code you're merging is production-ready, which means you probably will not go back and change it a hundred times more immediately after.

## Git aliases for command-line enthusiasts

I use both a GUI tool and the command-line to get my way around Git. To look at diffs and other routine things for which I can't instantly remember the Git command-line equivalent, like how to search for a file or a commit, I use [Tower][git-tower]. I wish I had a better memory to remember more commands but I'm only human, so, annoyingly, my brain keeps recycling things like that :)

For command-line, I prefer the [Zsh][zsh-shell] shell instead of Bash because I'm a fan of [Oh-My-Zsh][oh-my-zsh] plugins, especially the [Git one][git-aliases]. _You can also manually define these aliases in the profile of your shell of choice_. Having these aliases has helped me save a lot of time, because I use them dozen of times per day.

```shell
alias gst="git status"
```

## Rebase workflow to achieve clean-cut commits

One thing I do very often to achieve clean-cut commits is to _go back and modify existing commits_ when appropriate.
For example, let's say I have committed A, B, C and now I realised I forgot a change that would go well commit B. 
I could just create a new commit D, to say something like "Add a test for the change I made in B" but this will make it hard for people to follow if they use the "commit-by-commit" approach described in my [previous article][pr-roulette]. 
Instead, what I tend to do (using [Oh-My-Zsh][oh-my-zsh] aliases) is rebase to modify commit B.

### Stash all current changes that you don't want in commit B

```shell
$ git stash save # or alias gsta 
```

### Look at the tree of commits to find the hash of the commit before the one you want to change

```shell
$ git log --graph --max-count = 10 # or alias glgg
```
For example, I could be looking at something like this:

```shell
* commit f442511407a73d51ab9c974c38d21b77d1ea6d8d
| Author: Evelina Vrabie <evelina.vrabie@deliveroo.co.uk>
| Date:   Fri Sep 8 11:15:55 2017 +0100
|
|     Commit C
|
* commit 6724df5805295198006d00079aebfb516e656df7
| Author: Evelina Vrabie <evelina.vrabie@deliveroo.co.uk>
| Date:   Fri Sep 8 10:45:31 2017 +0100
|
|     Commit B
|
* commit cafbc74551945e0ece617fd4720466a80f0ea88e
| Author: Evelina Vrabie <evelina.vrabie@deliveroo.co.uk>
| Date:   Thu Sep 7 17:16:16 2017 +0100
|
|     Commit A
|
*   commit 0f0e7a97e554085722daad685737b86dd74c15ed
|\  Merge: f7ebe2cdb cbbd464a9
| | Author: Ana Capatina <anikiki@users.noreply.github.com>
| | Date:   Thu Sep 7 15:04:43 2017 +0100
| |
| |     Merge pull request #156 from deliveroo/CCC-173-unavailable-items
| |
| |     [CCC-173] Unavailable items can be added to basket
| |
:
```

### Rebase on the commit _before the one you want to edit_

In this example, that's commit A.

```shell
$ git rebase -i cafbc74551945e0ece617fd4720466a80f0ea88e  # or alias grbi <hash>
```

### Choose how you want to change commit B

You have multiple options:

+ `reword` (change the commit message and description)
+ `edit` (add, remove files, change the commit message)
+ `squash` (merge multiple commits into one and keep their messages)
+ `fixup` (like `squash` but good for all those intermediary "Work in progress" commits that don't add any value) 
+ `drop` (remove the commit changes altogether).


```
pick 6724df580 Commit B
pick f44251140 Commit C

 # Rebase 0f0e7a97e..f44251140 onto 0f0e7a97e (3 commands)
 #
 # Commands:
 # p, pick = use commit
 # r, reword = use commit, but edit the commit message
 # e, edit = use commit, but stop for amending
 # s, squash = use commit, but meld into previous commit
 # f, fixup = like "squash", but discard this commit's log message
 # x, exec = run command (the rest of the line) using shell
 # d, drop = remove commit
 #
 # These lines can be re-ordered; they are executed from top to bottom.
 #
 # If you remove a line here THAT COMMIT WILL BE LOST.
 #
 # However, if you remove everything, the rebase will be aborted.
 #
 # Note that empty commits are commented out
```

### Edit commit B, to add your changes

```
e 6724df580 Commit B
pick f44251140 Commit C
```

Save the choice and notice it tells you what to do next.

```
Stopped at 6724df580... Commit B
You can amend the commit now, with

	git commit --amend

Once you are satisfied with your changes, run

	git rebase --continue
```

### Track your changed files and _amend the commit_:

```shell
$ git add <files changed> # or alias ga <files changed> 
$ git commit --ammend # or alias gc --amend 
```

### Check you're happy with the commit description and save then continue the rebase.

```shell
$ git rebase --continue # or alias grbc
```

### Push your changes to rewrite the commit history

If you published your branch by the time you want to rewrite commit B, then you will have to **force push** your changes to the remote repository, in order to rewrite the commit history.

```shell
$ git push --force origin $(current_branch) # or alias ggp --force
```

### ☢️ WARNING ☢️

You have to be careful with `push --force`, because rewriting commit history **after your branch is visible to other people** might cause disruption. This technique is best used **before you publish your branch**. If you do it after, do it before you open a pull request and don't forget to notify your team, to prevent someone branching off your branch and suddenly having lots of conflicts with your new changes.

I use this rebase technique dozens of times a day and those Git aliases helped me speed up things by quite a bit.

To learn more about Git `rebase`, make sure to check my colleague Ben's detailed [article on the topic][reset-rebase-workflow].

<figure class="small">
![What if](/images/posts/rebase-technique-for-clean-cut-commits/what-if-the-ultimate-question-of-life-the-universe-and-everything-is-git-rebase-i-master.jpg)
</figure>

[pr-roulette]: /2017/09/06/play-pull-request-roulette.html
[git-merge]: https://git-scm.com/docs/git-merge
[git-rebase]: https://git-scm.com/docs/git-rebase
[git-commit]: https://git-scm.com/docs/git-commit
[so-merge-vs-rebase]: https://stackoverflow.com/questions/804115/when-do-you-use-git-rebase-instead-of-git-merge
[git-tower]: https://www.git-tower.com/
[sourcetree]: https://www.sourcetreeapp.com/
[zsh-shell]: http://www.zsh.org/
[oh-my-zsh]: http://ohmyz.sh/
[git-reflog]: https://confluence.atlassian.com/bbkb/how-to-restore-a-deleted-branch-765757540.html
[git-aliases]: https://github.com/robbyrussell/oh-my-zsh/wiki/Cheatsheet
[reset-rebase-workflow]: /2017-09-07-reset-rebase-workflow.html