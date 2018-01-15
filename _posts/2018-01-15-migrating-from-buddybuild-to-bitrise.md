---
layout: post
title:  "Migrating from Buddybuild to Bitrise"
authors:
  - "Maria Neumayer"
excerpt: >
  At the start of the year Apple announced the acquisition of Buddybuild and stopping Android support by March. This meant we quickly had to find an alternative - Bitrise came out to be the best option. Here's why, and how we switched.

---

## Why Bitrise?

We use CI for various things:
- Run our unit and instrumentation tests to ensure there's no regressions
- Create an APK and deploy it to fabric and/or Google Play
- Create nightly builds to deploy to the Google Play alpha channel for internal testing

We looked at various options, including Nevercode, Visual Studio App Centre and Circle CI. Bitrise turned out to be the most flexible and feature rich option out of those that could support all of our use cases.

## What's the difference between Buddybuild and Bitrise?

Buddybuild is set up to be very user friendly - changing your build settings is often just a simple toggle away. This means it's very easy to set up and change settings, but it also comes with a disadvantage: it's not very flexible. If the UI doesn't support something you had to either find a workaround or hope they will add support for it.

Bitrise is different. It has a lot of integrations which you can chain together as individual steps to a workflow. Each integration has its own configurations. If there's an integration missing you can add a custom script step with whatever logic you want. This gives you a lot of flexibility and control, but you still get simplicity of having pre-built integrations. All integrations are versioned, so an update to an integration should not break your builds.

## How to set up your configuration?

Your Bitrise configuration is a combination of triggers, workflows and steps. Steps are individual integrations that can be chained together in a workflow. Triggers (as the name suggests) define when a workflow will run. You can create triggers for pull requests, pushes and tags, or set up scheduled builds. For our setup we have triggers for pull requests, pushes on master, creating release tags and the scheduled nightly builds. Each of those triggers run different workflows to ensure the correct steps run.
<aside>
<figure class="small">
![Part of our master workflow](/images/posts/migrating-from-buddybuild-to-bitrise/workflow.jpg)
</figure>
</aside>

I found a good way to set up a workflow is to create various building blocks. Workflows can be chained together, so you can create a workflow for setup, which will clone the repository, pull the cache and install missing Android SDK components. This workflow can then be reused across other workflows.

To assemble the app and run the tests there's a few integrations available:
- Gradle runner to run a gradle task
- Gradle unit tests to run unit tests
- Virtual device testing for instrumentation tests

If you want to run the instrumentation tests you will first have to use the gradle runner to assemble the debug APK and the Android test APK. You can also run instrumentation tests on the Firebase Test Lab, but that's currently in private beta.

To sign the APK there's a Sign APK step. Similar to Buddybuild you can upload your keystore details and let Bitrise do its magic. If you have multiple keystores you can use the generic file storage and environment variables to upload the alternative ones.

Once everything's built you can deploy to Bitrise, which will send out the build to testers - just like Buddybuild. You can also publish to Google Play if needed. We also wanted to publish to fabric and for that we had to add another gradle runner step and call the Crashlytics upload task.

## How about custom scripts?

Custom scripts can be added as a script step anywhere in your workflow. You can either run script files in your repository or just copy the script into the script content of the step. When you add the step Bitrise will automatically add a few common commands you might want to use.
There's a small gotcha here: If you want to export environment variables for later steps you have to use the [envman](https://github.com/bitrise-io/envman/#usage-example-simple-bash-example) command instead of simply calling export.

## What if I don't always want to run a step?

The workflow UI just exposes a toggle to run a step if a previous step failed, but there might be other conditions you're having. For us we wanted to only deploy to fabric if the last commit was a special QA commit. We used a custom script to expose an environment variable which we want to check later on. With the UI there's no way to run a step based on an environment variable. Luckily there's the option to modify the generated `bitrise.yml` file directly.

Open the last tab of the workflow page called `bitrise.yml`. From here find the step you want to modify and add a "run_if" line. To check if our environment variable we had to use this code: {% raw %}`run_if: '{{enveq "PR_READY_FOR_QA" "true"}}'`{% endraw %}. That's it! Now the step will only run if the PR is ready for QA.

<figure class="small">
![Example of a run if condition](/images/posts/migrating-from-buddybuild-to-bitrise/runif-condition.jpg)
</figure>

## What's missing?

There are a few things missing. One being a nice output for unit tests, but this is being worked on. Bitrise also doesn't have an SDK (yet?), so crash reporting and feedback won't be available. This isn't a big problem for us, but if it is for you you might want to look at other tools supporting feedback or crash reporting.


So far we're very happy with our choice. We're still in early days, but so far it's looking very promising.
