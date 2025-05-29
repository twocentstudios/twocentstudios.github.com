---
layout: post
title: "Train Tracker Devlog"
date: 2025-04-15 17:06:00
image: /images/train-tracker-debug-dashboard.jpg
tags: ekibright ekilive ios
---

Last month, I took a step back from development of my train timetables [iOS app Eki Bright](/2024/07/27/eki-bright-tokyo-area-train-timetables) to think about the app in a broader context. I've iterated on Version 1 on and off for nearly a year, with use cases emerging out of a basic feature set and evolving with my own daily usage of the app.

{% caption_img /images/eki-bright-v1-7-marketing.png h250 Marketing screenshots for Eki Bright v1.7 %}

As a solo developer, it's difficult to maintain a clear perspective about any given project as it grows. It's a balance of having a strong vision but carefully allowing reality to gently guide that vision.

All this is to say I spent some time thinking hard about what version 2 of Eki Bright would look like if I started over today. How could I optimize the app for the way I use it now? How can I entice potential users and provide value to new users immediately?

If I stopped with version 1, as a user, I'd be relatively satisfied. I know how to navigate the app and work around the various UX speed bumps and oil slicks to achieve my goal of riding the train system here in Tokyo. I can overlook the problems in the app in ways a random iPhone user wouldn't. I knowingly stopped short of perfection on a few feature implementations in favor of getting them shipped.

I started to see a vision for how the app could work in a *progressive enhancement* sort of way for the various use cases I've uncovered. I started to see how important it was to do as much heavy lifting in the app as possible. There's always going to be tension between a "semi-pro" app that gives the user full control while also doing work on their behalf without asking.

A key part of the vision for version 2 that emerged was that Eki Bright can be a lot smarter about understanding the user's context. With location services, it should be possible to understand whether the user is walking to a train station and wants to know if they should run to get the next train, or whether they're riding a train and want to know when they'll arrive at their destination.

I started by segmenting out users into part of an app usage lifecycle:

- What would make a iPhone user want to download the app in the first place? Why (if at all) are Tokyo residents unsatisfied with their current navigation apps?
- For a first time user, what feature could act as an immediate hook/wedge to provide value with zero setup or explanation and remind them to come back again the next day?
- For users who have seen consistent results, what motivation would they have to want to dig deeper and trade some customization effort to get significantly more value out of the app?
- For users who have used the app consistently for some time, what features can be enhanced automatically based on usage history?

The features that make up this theoretical system are quite complicated! An interface that adapts to the kind of user, the user's usage history, and the user's current context was somewhat of a overwhelming task for me to take on all at once.

{% caption_img /images/eki-bright-v2-feature-list.jpg h400 Sketching out the lattice of features that could make up Eki Bright v2 %}

So after doing some brainstorming and pencil mockups, I decided to start prototyping a "hook" feature to capture that first segment of users: those who have not downloaded the app and first time users. A feature that is buzzy and attractive to prospective users, and is low touch and requires nearly zero configuration for first time users.

That feature was a *train finder*.

With the timetable data embedded in the app combined with live location data from the user's device, I reasoned it should be possible to find the exact train a user was riding if they opened Eki Bright while enroute. If the app could do this, it'd cut down on the work necessary to unlock downstream benefits for the user like:

- Checking what time the train will arrive at a destination station
- Setting an alarm for the destination station
- Checking what other stations are stops along the way
- Setting up a [DIY route](/2025/01/24/eki-bright-the-case-for-diy-routing/) to more thoroughly track a transfer
- Sharing a route and arrival time to a friend

At this point, I still intended the train finder feature to be part of Eki Bright. I imagined the user opening up the Eki Bright app along their journey, the app quickly booting up location services and narrowing down the possible railways and trains within a few seconds, and the user being able to quickly take some related actions from there.

My friend David asked "why not have it run in the background so you don't need to open the app?" I initially balked, not wanting to add background location tracking to Eki Bright due to its potential to be heavy on the device battery. I also couldn't see how background tracking could streamline the experience beyond reducing that 1-2 second train calculation time with the tradeoff that all this work would waste battery in the cases the user never opened the app. The background activity idea stayed in the back of my mind though.

I started prototyping the algorithm for turning a time-series of GPS coordinates into a railway, a direction on that railway, and ultimately a train.

{% caption_img /images/train-tracker-first-algorithm.jpg h400 Thinking through an train tracking algorithm. This particular algorithm turned out to be a dud. %}

After my first day working on the algorithm, I realized that it was going to require a lot iteration on real data from inside the various trains running all over Tokyo. It wasn't reasonable to think I could ride a train all day with my iPhone and MacBook debugging the algorithm on live data.

I therefore spent a day creating an app for collecting sessions of GPS coordinates. This has turned out to be a huge boon for development efficiency.

{% caption_img /images/gps-collector-screens.jpg h300 GPS collector app I created and used to get batches of real data from the field %}

This personal-use GPS Collector app allows me to collect raw data from Core Location in the background and annotate it while riding the various routes I take around the Tokyo area. I divide each trip up into a *session*, then manually annotate the session with the railway, direction, departure station, and arrival station to serve as ground truth annotations. I allow exporting in GPX format (for usage within Xcode) and as JSON I can import into and decode with other apps.

Seeing the raw data revealed a litany of edge cases my algorithm would need to handle. First off, any train that goes underground is a non-starter for a GPS-reliant system; I'd have to make peace with that fact for now. Core Location data includes speed and heading, which is useful, but is itself a derived value and can be gleaned from other sources. GPS accuracy will sometimes plummet temporarily inside the boundaries of a station and sometimes randomly inside dense city limits. Waypoints are usually returned one-per-second, but sometimes will cut out for seconds or minutes. Some trains go from underground to above ground at least once along their designated route.

I spent a week or so collecting GPS data while working on other apps. I returned to Eki Bright to finish up a first draft of an algorithm that took an entire time-series of GPS data and returned a ranked list of candidates: a railway, the direction on that railway, and the previous and next station.

```swift
struct RidingTrainFinderCandidate {
    let railway: Railway
    let direction: RailDirection
    let previousStation: Station
    let nextStation: Station
    // let train: TrainTimetable -- TODO: determine which train
}
```

I added a debug viewer to visualize how my algorithm was responding to test data as it was played back. It was mostly working! It was also kind of fun to watch the playback. Being able to throw together a view like this for the sole purpose of debugging an algorithm is a huge win for SwiftUI.

<video src="/images/train-tracker-debug-view-01.mp4" controls poster="/images/train-tracker-debug-view-01.png" preload="none" height="400"></video>

I'd hit a development checkpoint, and as cool as my little debug tracker view was, I was still far from a shippable feature that solved a real problem. My next step was extending the algorithm to guess which train the user was on (not exactly a straightforward algorithm to write based on the shape of my train timetable data).

However, I thought back to my friend David's remark about an app that works in the background. I thought, if I freed myself from the artificial constraints of Eki Bright as it currently existed, how could this algorithm still be useful?

A new vision emerged of an app that solved a much shallower problem:

- Sometimes when I'm on a crowded train and I've got my headphones in, it's hard to tell what station I'm approaching. I can't see the display above the train car door or out the window.
- What if I had a Live Activity in my Dynamic Island that updated live as I stopped at or passed each station along a railway?
- And what if I didn't have to manually select what railway I was on and what direction I was going?
- Better yet, what if I *didn't even have to open the app* and the Live Activity would automatically appear when I was riding a train and disappear when I got off?

If I could pull it off, this feature would be supplemental to any other navigation app. It also has a bit of "cool technology" vibe to it that could entice a download and serve as a conversation piece.

Realizing this new vision came with its own new implementation challenges.

- Monitor significant location changes in the background to save battery life, then switch to live location monitoring when moving at train speeds.
- Detect the railway and railway direction.
- Continuously update which stations have been visited and passed, and which station is next on the railway, even if it's far away.
- Start a Live Activity in the background when confidence in the current railway is high enough.
- Update the Live Activity as the user approaches, arrives at, and departs a station.
- End the Live Activity and switch back to monitoring significant location changes once the user has alighted their train.

I knew that significant location changes, app background activity, and the way each of these system features interacts with the relatively new (iOS 16+) Live Activities API was going to pose as the biggest risk to executing the seamless zero-touch app experience I envisioned.

I started by creating a new app project and creating a GRDB-backed event logging system. Next, I configured the app to request background location permission. I then created the bones of a location tracking algorithm that preserved battery life. I logged app lifecycle events and events for my location tracking algorithm to ensure I could quickly debug why the app was or wasn't "waking up" or "sleeping" when I expected it to while out in the field.

{% caption_img /images/train-tracker-app-events.jpg h400 Log of app events so I can verify background behavior %}

The next big task was reimagining my existing railway-finding algorithm for a different system lifecycle. This also meant I needed to pare down my very large train timetable static database for this new use case. I only needed the list of railways and stations. I followed a similar development flow as last time; I created a couple new debug views to view the live GPS waypoints and follow these waypoints on a map alongside the train tracking algorithm outputs.

{% caption_img /images/train-tracker-waypoints-view.jpg h400 Raw waypoints view to allow confirmation of incoming data %}

I started with a version that played back existing GPS data. A dashboard view showed just the user-facing data: the detected railway and "focus" station.

{% caption_img /images/train-tracker-debug-dashboard.jpg h400 A debug view that plays back previously captured GPS data at variable speed and shows user-facing data %}

There was also a list view showing the scores assigned by the algorithm and used to determine the ultimate result shown to the user.

{% caption_img /images/train-tracker-debug-list.jpg h400 The derived scores used by the algorithm to determine what railway and focus station is shown to the user %}

Then, once I was satisfied with the algorithm accuracy on the snapshot data, I migrated this view to use only live device data.

Watching the algorithm run live was exciting. I felt like I'd hit another checkpoint as the device would wake up and start gathering GPS data in the background, then start showing me which railway I was on and which station was next as soon as I opened it.

{% caption_img /images/train-tracker-debug-live-tracking.jpg h400 Same as above but using live GPS data %}

With a basic (but admittedly incomplete) tracking algorithm proven, the last piece of the puzzle I needed to de-risk was starting the Live Activity automatically in the background. Unfortunately this is where I hit a frustrating roadblock.

In a careful scan of the lengthy [Live Activities documentation](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Review-Live-Activity-presentations), I found the line:

> Your app can only start Live Activities while it’s in the foreground. However, you can update or end a Live Activity from your app while it runs in the background.

I confirmed this artificial limitation by attempting it and logging errors in my event tracking database.

> LiveActivities Error: The operation couldn't be completed. Target is not foreground

I felt like requiring the user to open the app each time they wanted the live activity to run – even if it was as simple as opening and immediately closing the app – would be too tedious an ask as a prerequisite for daily usage.

Before I neutered my vision or gave up on the idea entirely, I had one card left up my sleeve. From the documentation:

> Starting with iOS 17.2 and iPadOS 17.2, you can also start Live Activities with ActivityKit push notifications.

So a push notification from a server can start a Live Activity without being initiated by a user (as I'd personally experienced with the Apple Sports app), but for some reason it can't be started by the device itself? Strange, but since my app is already running in the background, I could technically fire off a network request to my own server with the data I wanted to start the Live Activity with and use my server as a pseudo-proxy to start a Live Activity. It feels like a loophole, but perhaps it's simply a case of an Apple product manager not re-evaluating an initial safeguard after changing a related feature.

Setting up push notifications is *involved*. I really did not want to be on the hook for maintaining another set of dependencies, but it was the only option left on the table.

> Aside: is it possible to send a push notification directly from a device instead of through an intermediary server controlled by the developer? In other words, could the device send a request to the APNS server directly that would send a push notification right back to it? In theory it seems possible, with the big security downside that the p8 key would need to be included in plain text within the app bundle.

I'll leave the long debug story of how I got push notifications working for another time, but after a couple days of development, I confirmed that I could indeed start a Live Activity from the background using an intermediary server.

Whether or not the App Store app review team considers this to be a permitted workaround is still a huge risk. I'm not sure how I can determine their stance without finishing up version 1 of the app and submitting it for review. Even an unfinished version going through Test Flight review isn't a guarantee App Store review will also approve.

So this is my current checkpoint: a new app binary with lot of debug screens that starts and updates Live Activities from the background as the user rides a railway in Tokyo.

{% caption_img /images/train-tracker-proto-live-activity.jpg h400 Prototype version of the working train tracker Live Activity on the lock screen %}

{% caption_img /images/train-tracker-proto-dynamic-island.jpg h400 Prototype version of the working train tracker Live Activity in the Dynamic Island %}

My plan is to release this app standalone. How it fits into the existing and future Eki Bright vision isn't yet determined. Perhaps the train tracker app is a free marketing driver for Eki Bright. Perhaps the train tracker app evolves separately from Eki Bright and eventually obsoletes Eki Bright. I'm not sure, but my instinct is to test it in the market in isolation first.

What do I need to finish up in order to ship?

- Improve the algorithm to determine the correct railway faster, handle transfers, and off-board seamlessly.
- Improve the design of the Live Activity.
- Remove the debug screens and rework the in-app UI for onboarding, settings, and simple monitoring.
- Create branding and add all the required info for the App Store.

I'm getting faster at getting through this part of the process, but it still takes time. However, I do feel some accomplishment in having semi-efficiently prototyped enough to de-risk this project.

I'm planning to write a few technical posts that detail the caveats of Live Activities once I'm more confident in the robustness of my implementation. Until then.
