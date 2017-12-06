---
layout: post
title:  "How to introduce Kotlin in your codebase"
authors:
  - "Maria Neumayer"
excerpt: >
  Kotlin was the big topic of the year in the Android community. In this blog post I will share a few tips and tricks we've learned while converting our application to Kotlin.

---

Kotlin was the big topic of the year in the Android community. Many of us are talking about it or have started using it. For us at Deliveroo the journey took off in April this year when we introduced Kotlin to the production app and now (after 8 months) we hit the major milestone of having a majority Kotlin app.

At Droidcon UK, Amal and I talked about our journey from Java to Kotlin. You can watch the talk [here](https://skillsmatter.com/skillscasts/10533-travelling-across-asia-our-journey-from-java-to-kotlin) and see our slides [here](https://speakerdeck.com/marianeum/travelling-across-asia-our-journey-from-java-to-kotlin). But if you prefer reading then here is a summarised version of what we learned on our journey.

## How to get started?

We started using Kotlin in tests more than two years ago. This gave us a chance to get used to the syntax, but because tests are so simple we couldn’t really learn all of Kotlin’s language features. So when we decided to use it in the production app we had to actually learn the language first. We all could have set off to learn the language individually (which we did too!), but learning the language together is much more fun and rewarding, so we set up Kotlin hour.

Kotlin hour is a bi-weekly catchup of the Android team where we talk about anything related to Kotlin. In the beginning that meant actually learning the language by:

 - Going through Kotlin koans
 - Giving presentations about the language and its features
 - Actually writing Kotlin by implementing our interview coding challenge in Kotlin

With this we could learn the language without risking breaking the production code by not knowing the language. Once we were confident we merged our first Kotlin pull request.

## How to share knowledge?

The more we used Kotlin, the more we learned about it and the more usages we found for great features like extension methods, the Kotlin stdlib functions and many others. We all found different tricks and had to share them with the rest of the team. One way to do that is through pull requests.

When creating a pull request we commented on interesting usages of Kotlin, areas we weren’t sure about or just questions about how to write something better. This also works when reviewing — we would recommend a feature to use, an easier way to write something or just share what we’ve learned from reading the pull request.

The most interesting or more complex things were then shared during Kotlin hour. This way everybody on the team could learn about cool tricks, or we could ask for help about how to best write something.

As you adopt Kotlin you’ll all learn different things at different times, so sharing them with the rest of the team means you’ll learn things faster!

## How do I convert to Kotlin?

Android Studio has a great conversion tool for Java code. This will get you started, but you’ll need to clean things up a bit afterwards. After converting a file you might be prompted with this dialog:

<figure>
![Kotlin conversion dialog](/images/posts/how-to-introduce-kotlin-in-your-codebase/conversion-dialog.jpg)
</figure>

In most cases it’s best to just hit cancel here as Android Studio will update a bunch of classes that use the class that you converted. However, there might be a lot of changes you won’t want. For example Kotlin doesn’t have static methods, but you can add the `JvmStatic` annotation to keep the static method in your Java code. This way you won’t have to update all the Java references.

This also means you won’t update lots of other files from just a single conversion. Sometimes you can’t avoid that, but sometimes — especially for classes referenced in many places —  you want to keep changes to a minimum. This could mean:

- Creating some temporary Kotlin methods to avoid more changes to your Java code     
- Cleaning up your Kotlin code to avoid big changes

Big changes will be hard to review and therefore bugs could sneak in easily. It’s best to avoid them.

## How do I best create a pull request with Kotlin conversions?

One thing we found is that having a clean commit history is essential. You’ll want to keep your conversion in a separate commit to your logic changes. So if you convert a class: convert it, clean up the conversion and then commit. Only then can you perform any other changes. This way reviewing the changes will be much easier.

You’ll also want to avoid keeping long living branches with Kotlin conversions. Once you convert a file to Kotlin git will identify it as a new file — your linear git history for that file will be lost. This means if anybody else changes anything in that file while you work on it, then you’ll have to fix that manually. So for bigger changes: create a pull request with only your conversions — once approved merge that. This way everybody can edit the file without ending up in conflict hell.


This is what worked best for us. I hope this gave you some insight and help in what to expect when converting your app to Kotlin too!
