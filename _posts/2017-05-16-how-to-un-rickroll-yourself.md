---
layout: post
title:  "How to un-rickroll yourself"
authors:
  - "Robert Saunders"
excerpt: >
  A story of how leaving your laptop unlocked can lose the entire morning.
---

This post is a warning to the dangers of forgetting to lock your laptop in an environment where:

1. Leaving your laptop unlocked is discouraged by a culture of jovial shaming.
2. People are smart and creative.

Yesterday I return to my workstation to see my unlocked desktop staring back at me.  🤦‍♂️

I quickly scan though our company slack to assess the damage and find a 'i ❤️ Android' post and a new Android Emoji on my profile (I am an iOS Developer).  However, I think I got away lightly.  I keep my new slack emoji as a reminder to lock my laptop.

A few hours later a tab pops open on chrome and [Rick Astley starts singing at me](https://www.youtube.com/watch?v=dQw4w9WgXcQ).  I realise I am the victim of a much more sophisticated prank.

I had been playing around with a feature to share a link to a restaurant menu over bluetooth.  It happens without a prompt sometimes.  I'm not sure exactly how they have done it, but I am quite tired so, I just disable bluetooth and go home.

The next day I am browsing JIRA and it happens again.  I am much more alert and up for a challenge.

First, I check my chrome extensions. Everything looks normal, but I check the author of each extension to make sure that the rickroll is not [masquerading as google docs](http://www.popsci.com/massive-phishing-scheme-just-hijacked-gmail-accounts-by-disguising-itself-as-shared-google-doc).

I check to see if there are any [cron jobs](https://www.cyberciti.biz/faq/linux-show-what-cron-jobs-are-setup/) set up on my machine - nothing.  I check my downloads, installed applications and terminal history (`history 100`).  Nothing sticks out.

I figure somewhere sitting in a file is the rickroll youtube URL [https://www.youtube.com/watch?v=dQw4w9WgXcQ](https://youtu.be/2Z4m4lnjxkY?t=1m46s) so I start to grep everything for the youtube ID

    grep -r 'dQw4w9WgXcQ' /

This takes ages and I start to realise why norton scans used to take so long.  I figure that most of the larger system files would have system write protection so I narrow my scan to the home folder (`~`) and I get 2 hits relatively quickly as the scan continues.

```
...local/share/heroku/cli/lib/npm/test/tap/legacy-platform.js
...nvm/versions/node/v5.12.0/lib/node_modules/npm/test/tap/legacy-platform.js
```

Excited I check the files.  It looks fairly innocent, but perhaps it is cleverly disguised.  I google the file and it its referenced in quite a [few repos](https://github.com/inexor-game-obsolete/platform/blob/master/bin/windows/all/npm/node_modules/npm/test/tap/legacy-platform.js).  It appears that it's a unit test that someone just happened to put the rickroll url in.

This gets me thinking.  I can `gem install` without `sudo`, so could the prankster.  I list my gems and brews, but again nothing stands out.  I google 'Gem install rickroll' and find a [rick-roll-terminal.sh](https://gist.github.com/codfish/6998b08a05c222861804#file-rick-roll-terminal-sh-L5) gist

> ... prankee needs to be running rvm, rbenv, or some other
> ruby version manager that doesn't require sudo permissions to
> install gems

This looks promising!  I check the script and it appears to clean up after itself so could explain why there were no suspicious gems.  However a closer examination shows it downloads a rickroll image and prints it as ASCII in the terminal.  Very creative - but not it.

I decide that the url might be encoded to avoid detection, I try a desperate search for 'rickroll' in my home directory.

    grep -r 'rickroll' ~

I don't really expect it to work, but I get 2 hits.

```
....rubygems.org..../versions:rickrolling_roulette 0.0.1,0.0.2 7ca0e1c107583a7e4f9c7e10dea1db92
....rubygems.org..../versions:webrickroll 0.0.1,0.0.2 127bf6111dbdf0f2a7c57c2d03b2d035
```

Unfortunately it appears these are just caches of the master list of all gems.  Out of interest, [these gems](https://github.com/eadonj/rickrolling_roulette) intercept links via a middleware and hijack them so you can 'fully enjoy the benefits and wonders of Rick Astley'.

I am starting to run out of ideas. I decide I need a consistent reproduction steps.  All complex bugs are solved by finding exact steps to reproduce.

I set my system time ahead 12 hours - nothing, 24 hours - nothing, 5 weeks - nothing.

Perhaps the process will die if I restart my machine?  I restart and I get instantly rick-rolled. I restart one more time to be sure it was not a coincidence again it happens.  The process must restart itself automatically on login.

I go to system preferences to check my login items.  They look normal - just `iTunes Helper` and our colleague Paul's excellent [`Trailer.app`](https://ptsochantaris.github.io/trailer/).  However I notice that Docker and Postgres have restarted but are not in the list.  I research how they do it and it turns out there is another way.  A folder called [`LaunchAgents`](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html).  A quick scan and I find `com.lock.yo.screen.plist`.

```
<plist version="1.0">
<dict>
 <key>Label</key>
 <string>com.lock.yo.screen</string>
 <key>RunAtLoad</key>
 <true/>
 <key>ProgramArguments</key>
 <array>
 <string>/usr/bin/open</string>
 <string>-a</string>
 <string>/Applications/Google Chrome.app</string>
 <string>https://www.youtube.com/watch?v=dQw4w9WgXcQ</string>
 </array>
 <key>StartInterval</key>
 <integer>7200</integer>
</dict>
</plist>
```

It runs `open -a 'Google Chrome.app' https://www.youtube.com/watch?v=dQw4w9WgXcQ` every 2 hours.  I delete the file and restart.  To my delight, Rick has given up.

## Some lessons

1. Find consistent reproduction steps.
2. Verify assumptions. Often you appear to find what you are looking for, but you should carefully test to see if it fits all the evidence.  [We have a tendency to jump on the first thing that verifies our initial assumptions right](https://en.wikipedia.org/wiki/Confirmation_bias) (e.g. `rickrolling_roulette`).
3. Determination can yields results, but you can often save a load of time by asking for help.
4. Lock your laptop.


![Rick](/images/posts/how-to-un-rickroll-yourself/rick_roll.jpg)
