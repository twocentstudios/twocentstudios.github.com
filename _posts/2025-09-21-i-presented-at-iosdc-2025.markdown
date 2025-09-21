---
layout: post
title: I Presented At iOSDC 2025
date: 2025-09-21 10:14:02
image: images/iosdc25-livestream.jpg
tags: ios ekilive presentation

---

I gave a 20-minute presentation at iOSDC 2025 called "Let's Write a Train Tracking Algorithm". I'm still gathering up all the presentation materials, but so far:

- [Speaker Deck: Static slides](https://speakerdeck.com/twocentstudios/lets-write-a-train-tracking-algorithm)
- [GitHub: Open source code and presentation materials](https://github.com/twocentstudios/train-tracker-talk)
- [App Store: Eki Live](https://apps.apple.com/app/id6745218674)
- [Fortee: My talk proposal](https://fortee.jp/iosdc-japan-2025/proposal/a5e991ef-fec8-420b-8da8-de1f38c58182)
- [Blog: Eki Live Devlog 1](/2025/04/15/train-tracker-checkpoint-devlog/)
- [Blog: Eki Live Devlog 2](/2025/05/29/train-tracker-devlog-02/)

This is a more behind-the-scenes diary post. I'll follow up with more details from the actual talk after the conference has ended.

{% caption_img /images/iosdc25-livestream.jpg h300 Me looking especially jpg encoded on the live stream %}

## About the conference

iOSDC is a really great conference for both attendees and speakers. This is my first year speaking but I've attended the past 3 years. I like that there's an open proposal system and it draws a wide variety of speakers that are not necessarily on the "circuit". The rookies lighting talk system is also a fantastic way to create the next generation of great speakers in a supportive environment. I met some cool developers at the speakers' dinner that got me excited to do my own talk and to see their talks.

After my talk, there were several great questions during Q&A. And I had several more really interesting conversations with developers at the Ask the Speaker table.

This was my first conference talk presenting in Japanese. When I created my proposal, I knew I wanted to do it in Japanese. Although I'm sure the majority of iOSDC attendees could have understood the presentation in English (especially simplified), it felt like the right time to challenge myself.

Writing the talk in Japanese had a significant upside: I had to iterate the spoken lines for each slide several times to their most essential elements. My less expansive vocabulary resulted in a talk that is easier to understand by both developers and non-developers. My inability to improvise made the talk less fluid, but also ensured that my talk was optimized for time and I could learn it down to the word.

The final version of my presentation was 121 slides in 20 minutes. The slides layout was created in Deck Set. I created about 90 images and 5 videos captured from the maps in my custom apps and in Figma. The demo video was lightly edited in Final Cut Pro.

{% caption_img /images/iosdc25-deckset.png h400 My deck in Deck Set %}

Thanks to everyone who came to the talk and watched online. Special thanks to my friends who gave early feedback on my drafts.

I'm really happy I had this opportunity. I hope I'll have something interesting to propose for a talk for next year.

## How I developed the presentation materials

At the time of the call for proposals, I'd released Eki Live to the App Store with what I considered "version 2" of the underlying algorithm that determines the user's railway, the direction, and station and updates it over time.

{% caption_img /images/eki-live-v1-home-en.jpg h450 Eki Live's home screen, showing railway, direction, and next station %}

Before version 2, there was of course version 1 of the algorithm. Version 1 was the simplest method that worked for the least difficult train journey scenarios. The app would use the iPhone's distance from station coordinates to create a visit history for the stations on a railway line. This info was enough to provide an estimate of the railway, direction, and station in many cases. But version 1 of the algorithm had several unfixable flaws:

- The user had to visit at least 2 stations in order for a result to be produced.
- The algorithm was not differentiating between parallel railways that split at some point.
- There was no way to differentiate between parallel railways with different station configurations like the Tokaido and Keihin-Tohoku lines.

Although the rest of the app was ready, I didn't end up releasing version 1 of the tracking algorithm. It didn't quite feel magical enough.

I rewrote the algorithm to a version 2 before releasing the app. I spent more time collecting data and more time creating visual debug utility apps to assist in development.

However, the biggest change to the algorithm was obtaining and cleaning up railway coordinate data. The dataset I used for [Eki Bright](/eki-bright-tokyo-area-train-timetables/) only included station (and its coordinates) and railway data. Once I had access to the coordinate data, that opened up a new avenue for being able to estimate a railway instantly and then continue to refine the estimate over time.

In version 2, I doubled down on a scoring system for each aspect of the overall algorithm. Although my head was in the right place, this introduced far too much complexity for too little benefit. It took much longer than I'd hoped, but I eventually got this version to a state I was reasonably satisfied with and released it as Eki Live v1.0 to the App Store.

It would be much easier to develop the tracking algorithm assuming access to an infinite stream of accurate GPS coordinates from an iPhone. Unfortunately, this is not the case. The app needs to work within the bounds of the Core Location APIs for monitoring significant location changes so that device battery life can be preserved. The app also needs to *stop* tracking a journey when that journey ends. Therefore, there's two other separate heuristics I needed to iterate on that subtly affect the behavior of the tracking algorithm via the data provided to it.

When I submitted my talk proposal to iOSDC, I was planning on talking about the entire app. After all, there were so many unique and interesting problems I'd run into in the development process.

When my proposal was accepted, I started working on my talk with this in goal in mind: more of a high level overview of the app development. In that early draft of the talk, I set out a map for which data-gathering apps I needed to create. A main theme of this draft would be *why you should develop throwaway prototype apps to gather data before developing for production*.

Of course, it took a few weeks to develop what became 5 separate prototype apps plus the algorithm viewer app. Along the way, I became less and less satisfied with the prospect of presenting "version 2" of the tracking algorithm to an audience since it had many admitted flaws.

Once I'd finally created all my prototype apps and updated the talk draft, I realized I was already probably 5-10 minutes over time without talking about the tracking algorithm, UI, or Live Activity. I took a step back and realized that the tracking algorithm made for a more easily digestible story for newcomers to this problem than a bunch of minutia about the self-imposed constraints of data collection.

So in terms of the talk draft, I essentially started over. This time I focused purely on the tracking algorithm itself, telling a cleaned up story about how it has improved over time. Although I didn't show any of the several data collection apps I made, they were still useful in collecting real life data to use in examples and to develop the algorithm itself.

To fit the time constraints, I had to pare down a few examples and gloss over some details. But in spite of this, I was satisfied with the talk being code-free and accessible to even non-developers. It's a true challenge trying to set up all the background knowledge needed to understand a problem, present the problem, and have the audience understand the solution within the span of 2 or 3 slides. Especially when the solution was something that took me days or weeks to work out.

The tracking algorithm presented in my talk is version 3. But due to spending the last two weeks writing and practicing the talk, I didn't have time to actually integrate this version into the Eki Live app! The production version is still using tracking algorithm version 2 and in addition has some iOS 26 bugs (iOS 26 was released this week).

I still have a lot of work to do before I can (temporarily) put a bow on this project: integrating tracking algorithm version 3 into the app, improving the manual start/stop tracking UI, and recording and uploading my talk in English.

I wrote two development logs ([Devlog 1](/2025/04/15/train-tracker-checkpoint-devlog/) [Devlog 2](/2025/05/29/train-tracker-devlog-02/)) about Eki Live that go into further detail. Check them out and free free to reach out.

