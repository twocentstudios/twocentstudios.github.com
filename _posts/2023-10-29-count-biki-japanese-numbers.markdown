---
layout: post
title: "Count Biki - Drill Japanese Numbers"
date: 2023-10-29 19:49:00
image: /images/count-biki-app-icon.png
tags: app countbiki
---

I'm proud to present my latest iOS app, Count Biki.

{% caption_img /images/count-biki-app-icon.png h300 Count Biki app icon %}

Count Biki a self-guided utility app for drilling numbers of all shapes and sizes in Japanese.

{% caption_img /images/count-biki-v1-listening-quiz.png h650 The listening quiz screen: the screen you'll spend the most time on %}

In this series of posts I'll talk about:

- **This post** - the motivation behind the app and the solution I've begun to explore from the learner (user) perspective
- **[Count Biki - App and Character Design](/2023/10/30/count-biki-app-and-character-design/)** - the design process and specifics of creating the Count Biki character
- **[Count Biki - Developing the App for iOS](/2023/10/31/count-biki-developing-the-app-for-ios/)** - the high-level implementation details

Japanese learners can download the app from the [App Store](https://apps.apple.com/us/app/count-biki/id6463796779).

Like many of my other apps, Count Biki is open source on [GitHub](https://github.com/twocentstudios/count-biki).

## Background

Counting to ten is one of the first things we learn in a foreign language. Each language has its own rules about how numbers combine to form larger numbers, how they combine with objects, and how they associate with the concept of time.

When I first moved to Japan, every couple shops or restaurants I'd visit wouldn't have a display at the cash register. The cashier would speak my 4 or 5 digit total aloud at native speed and I'd be lucky to get the first digit. I'd panic and fumble through the transaction, then forget about it until the next time. It was tough skill to practice.

Japanese has unique readings for days of the month, e.g. July 1st, October 9th, etc. We learn them in the 101-level course, but in daily conversation I'd rarely need to recall each specific reading with native accuracy to get my point across. The knowledge gracefully slipped away as it usually does.

Fast forward to now, and there are more language learning apps than ever. Even ones that help with numbers. However, I wanted a more streamlined way to practice all types of numbers, and I wanted to focus my development on Japanese and, as a learner, ensure I could practice the uniquely difficult parts of the language.

In cases like dealing with money, the numbers are essentially random. Therefore, I didn't want to rely on just hard coding a couple dozen entries. Computers are great at:

1. generating random numbers
2. generating speech from text
3. generating spelled out text from numbers

All the rules about our language systems are already encoded into our devices. I saw my role as being able to surfaces these tools in a convenient wrapper so we can drill the particular weak points of numbers endlessly.

## Available Topics

First in the UX flow, the learner choses a topic category. In the first release there are 4 categories: numbers, money, time durations, and dates & times.

{% caption_img /images/count-biki-v1-topic-categories.png h350 The topic categories screen %}

Within each topic category, there are several topics.

{% caption_img /images/count-biki-v1-topic-money.png h350 The topics screen within the money category %}

My goal in dividing up topics and categories was to remove the burden of configuring complicated sets of ranges and digit sliders from users. Of course, infinite customization can be added later. But for my first release, I wanted to make some guesses as to how the app can be immediately useful to many different skill levels, and also suggest scenarios that learners may not even recognize as unique and useful.

In the numbers category, the app covers ranges of numbers mostly based on the number of significant digits you need to input. It's rare to encounter someone reading you a 9-digit number with every digit as non-zero. People generally work with significant digits, maybe 3 or 4. So although there's a "Master" category that covers 5 significant digits, the higher order drills for 100 million (億) and 10 trillion (兆) still only use 3 or 4 significant digits (with the remainder being zeros).

In the money category, the app adds the 円 suffix and tailors the number ranges to cover common situations like the convenience store or restaurant. This category has been my most used so far.

In the time durations category, the app covers the main groupings from seconds to years. Although I considered adding some topics to mix them, I'd like to do some more research to determine what the most common pairings in daily life situations are. This also adds complexity to the user input section (what's the lowest friction way to enter in multiple unrelated numbers? The system date picker? One text box?).

In the dates & times category, the app covers similar variants as the time durations. However, these represent individual moments in time. And there are many variants that are commonly used. For example, 24-hour time is very common in the language, as is AM/PM (午前、午後). Days of the month and months have several exception readings. The app even (for fun) has an experimental topic for converting Japanese calendar years to Gregorian calendar years (this is not easy!).

## Listening Quiz

At launch, the only quiz skill supported is listening.

{% caption_img /images/count-biki-v1-listening-quiz.png h650 The listening quiz screen %}

1. behind the scenes, the app generates a number based on the topic as the question
2. the on-device text-to-speech engine speaks the question
3. the learner types their proposed answer in the input box
4. the learner taps the submit button to check their answer
5. if the answer is correct, the app plays some animations (Count Biki nods, confetti is thrown, and the device plays haptics) and the flow starts over
6. if the answer is incorrect, the app shows a red bar and play some other animations
7. the learner can tap the play button to replay the question
8. the learner can tap the show answer button to give up and show the answer

The app keeps track of the number of questions answered correctly, incorrectly, and skipped. But as of the initial release, this data is only kept for the duration of the session and is not persisted.

The only session mode available at launch is infinite drill mode. The app will keep generating questions forever, and it's up to the learner to decide when they'd like to quit or a switch to a different topic. I chose this mode as the default intentionally, as it matches well with the ethos of the app: it's a utility for additional practice. Although it adds some burden to the learner to choose their own curriculum, there's power in "staying out of the learner's way"). Eventually, I'd like to add a time attack mode and question attack mode to give learners the option of deciding on bounded study sessions in advance.

## Voices

The app uses iOS's built-in text-to-speech (TTS) engine. Although the on-device TTS is not perfect and requires some user configuration, I felt it was a good starting point in keeping the complexity, cost, and potential failure points low.

The iOS binary has a standard-quality TTS voice predownloaded for most languages. For Japanese, this voice is called Kyoko. As of iOS 17, there are 4 available Japanese voices: Kyoto, Otoya, Hattori, and O-ren. Kyoto and Otoya have a separate "enhanced" quality voice.

{% caption_img /images/count-biki-v1-accessibility-settings-voices.png h350 iOS spoken content voices accessibility settings in iOS 17  %}

As of the initial release of Count Biki, the learner can choose any of the voices they've downloaded from the iOS settings to use in their listening quiz. Using alternate voices requires going deep into the iOS accessibility settings and downloading ~70MB voice files. We've included instructions within the Count Biki settings that show the step-by-step of how to add voices, but unfortunately there's no way to make this process more automated yet.

{% caption_img /images/count-biki-v1-get-more-voices.png h550 The in-app explainer for how to download voices from iOS system settings %}

As AI-powered TTS engines become commodities over the next few years, I'll be looking to increase the variety, accuracy, and aesthetics of the TTS component of the app.

The iOS TTS engine does include APIs for changing the speaking rate and pitch. I find the default rate to be a little quick. In the Count Biki app settings the app includes sliders for modifying both the rate and pitch. The extreme settings are definitely extreme, but I didn't want to artificially limit them for the initial release.

{% caption_img /images/count-biki-v1-voice-settings.png h350 Voice settings within the session settings screen %}

## Quiz results

Generally, seeing the results of a quiz is important for a few reasons. You want to spend more time practicing questions you've missed. You want an overview of your progress over time in mastering a topic.

Going along with the utility ethos of the app, I've only included the most basic quiz results; the results are displayed inline on the listening quiz screen and  slightly more detailed on the session settings screen.

{% caption_img /images/count-biki-v1-session-results.png h350 Results as displayed on the session settings screen %}

As much as I wanted to create an elaborate results system for the initial release, the more I considered it, the more work I realized it would take to make it useful and not get in the way. It also seemed like it'd end up as an endless rabbit hole of complexity that would make implementing other skills and topics more difficult.

The naive solution of showing a big list or correct or incorrect questions doesn't seem like it'd add a lot of value on its own. I'd rather spend more time considering a few key metrics that I could extract for the user that are 1. understandable at a glance and 2. immediately actionable. I'm regretfully offloading the burden of progress tracking onto the user while the app is still taking shape.

## App info

Most apps have an info/settings page that collects all kinds of disparate non-essential functions. Count Biki will probably end up with its mutable settings spread out across a few different contexts, so this page is more about tips, support, and legal info.

{% caption_img /images/count-biki-v1-info-screen-top.png h650 The info screen %}

## In app purchases

When I was first charging for my apps, the App Store didn't have in app purchases. It was actually still the era of the "lite version" - a completely separate binary and listing on the App Store with only a subset of features that would link users to pay for and download the full version.

Since I'm starting to dip my toes in the water in building a self-sustaining independent app business, but my app isn't at subscription-level value yet (in my opinion), I figured I'd try out the tip jar payment model. The plan is that almost all features are free upon first release, but features added in the future will require a pay-what-you-want-once upgrade. I called this "Transylvania Tier" as a nod to the vampire theme.

{% caption_img /images/count-biki-v1-transylvania-tier.png h750 The tip-jar screen for unlocking 'Transylvania Tier' %}

There is one unlockable feature: alternate app icons.

{% caption_img /images/count-biki-v1-app-icons.png h350 The tip-jar screen for unlocking 'Transylvania Tier' %}

## Conclusion

I'm hoping Count Biki will prove to be an invaluable addition to learners' study materials. There are plenty more topics and features that complement the theme and goal of the app that I'll continue to chip away at over time and as I get more feedback from learners.

Thanks for reading this little checkpoint summary, and if you're a Japanese learner or developer, please check out the app on the [App Store](https://apps.apple.com/us/app/count-biki/id6463796779) or the source on [GitHub](https://github.com/twocentstudios/count-biki).

The next post in the series is [Count Biki - App and Character Design](/2023/10/30/count-biki-app-and-character-design/).