---
layout: post
title: "Eki Live - Zero-Touch Assistant for Navigating Tokyo's Railways"
date: 2025-06-03 12:27:00
image: /images/eki-live-live-activity-en.png
tags: ekilive app
---

I'm excited to announce my latest app Eki Like or 駅ライブ in Japanese.

{% caption_img /images/eki-live-v1-app-icon.png h200 App icon for Eki Live v1.0 %}

Tokyo-area residents can download it [on the App Store](https://apps.apple.com/us/app/eki-live/id6745218674).

Eki Live tracks the train you're currently on and shows the current/next station on your route.

The main interface is a Live Activity:

{% caption_img /images/eki-live-live-activity-en.png h300 Live Activity on the lock screen and Dynamic Island %}

But there's also a more detailed view inside the app:

{% caption_img /images/eki-live-v1-home-en.jpg h400 Home screen of Eki Live (English version) %}

The unique point of Eki Live is that it's designed as a **zero-touch** app:

- The app runs silently (and lightly) in the background throughout the day.
- When it detects you're on a train, the app automatically determines which railway line you're on and which direction you're headed.
- The app starts a Live Activity that appears on your lock screen and Dynamic Island (on supported iPhones).
- When your trip is over, the Live Activity automatically disappears.

All this happens with *zero user interaction*.

I've been using the app during the last few months of development and I think it's kind of magical. Please [give it a try](https://apps.apple.com/us/app/eki-live/id6745218674) and send me your thoughts at [support@twocentstudios.com](support@twocentstudios.com?subject=Eki%20Live%20Feedback).

If you'd like a deep dive into Eki Live, why I made it, its limitations, and what I've got planned for it next, please keep reading.

## Limitations

Eki Live relies primarily on Apple's Location Services framework – which itself relies mostly on GPS data. Therefore, Eki Live has very limited operation on underground railway lines. This often includes the many stations that are covered or partially underground, as well as tunnels and dense city-areas.

For efficient background standby operation, Eki Live uses a Location Services API called *significant location changes*. The app stays asleep in the background like all other apps on your device, but is awoken by the system when your device moves some distance from its previous location. When awoken, Eki Live briefly checks whether the device is moving at train-speeds, and if not, it goes right back to sleep. This means that Eki Live will wake up and find your current railway at minimum a few hundred meters after you've departed your origin station and sometimes longer. The detection time can be random depending on several factors (whether the system is already using your location, your battery level, etc.).

When GPS accuracy drops significantly, Eki Live will report stations as **Nearby** instead of **Next** or **Now**. When no new GPS coordinates have been delivered by the system in over 60 seconds, Eki Live will switch to reduced accuracy mode with hatching and a low signal indicator shown in the Live Activity and in the app.

{% caption_img /images/eki-live-v1-reduced-accuracy.jpg h400 Reduced accuracy mode is triggered when no GPS coordinates have been received in 60 seconds or more %} 

As of v1.0, Eki Live will dismiss itself once you've stopped moving at train speeds for a period of about 10 minutes. This is only a temporarily limitation and will be improved. If you're feeling impatient, you can swipe left on the Live Activity on the lock screen to dismiss it.

Similarly, Eki Live will usually handle above ground transfers within a couple hundred meters of the transfer station, but it depends on how divergent the new railway line is from the previous one. This is also a limitation I think I'll be able to improve in the near future.

Differentiating between railway lines that run parallel is difficult for Eki Live's tracking algorithm without more input than just GPS. At the moment, Eki Live will use data about which stations you've stopped at versus which you've passed to determine which of up to several parallel railways you're currently on. But this can take as much time as it takes to get to a few stations. If you're feeling impatient, you can always tap Eki Live's Live Activity to open the app and tap another railway candidate.

{% caption_img /images/eki-live-v1-railway-selection.jpg h400 You can open the app to manually select your current railway if it's not the top candidate; in this example the Meguro-line %}

Eki Live does not currently differentiate between local and express trains for railways that have them. However, Eki Live will sometimes show stations as **Passing** instead of **Now** when it has high confidence a station will be passed and not stopped at. This depends on many cars the train has and which car (front or back) you are currently occupying.

Finally, there is an undocumented hard-limit on the number of Live Activities an iOS app can start during a period of time while the app is in the background. As of iOS 18.4, the limit is 10 times per 24-hour window. This means that Eki Live will only be able to *start* 10 Live Activities per day from the background. In practice this should be an incredibly rare occurrence. But if it does happen, the workaround would be to open the app, which would start the Live Activity directly on device.

My mission from version 1.0 onward is to overcome these limitations one-by-one to make the app fulfill its promise of being truly zero-touch on any railway.

## Privacy

The goal of Eki Live is to improve your ease of navigation around Tokyo. Eki Live does not and will never have ads or sell data to third-parties.

Eki Live does not send any raw location data (i.e. latitude, longitude) off device (I have no interest in knowing where you are or where you've been).

The only exception to the above is a technical detail due to an Apple API limitation, which I will explain below. 

In order for the app to start a Live Activity automatically while the app is not open, it must send data to Apple's push notification server (APNS). APNS then forwards the data back to the device.

When Eki Live is running in the background and determines which railway line you're on, it sends (as an example) the following information to a twocentstudios.com server:

```
{
  focusStationPhaseKey: 'focusStationPhase.upcoming',
  focusStation: 'Jiyugaoka',
  laterLaterStation: 'Gakugei-daigaku',
  laterStation: 'Toritsu-daigaku',
  railway: 'Toyoko Line',
  railwayDestinationStation: 'Shibuya',
  railwayHexColor: '#DA0442',
  isReducedAccuracy: false
}
```

The above information is packaged up without any parsing or logging and forwarded directly to APNS. It has only the information required to populate the first state of the Live Activity that will start on your device. The device address keys for APNS are generated anonymously by the operating system and are also not logged or associated with you in any way.

Only the first set of data must be relayed through APNS in order to start the Live Activity. After the Live Activity successfully starts, it is updated directly on the device without any external server communication.

I hope this superfluous server-based workaround for the ActivityKit API will be eliminated in the future.

If for some reason you want to opt-out of any server-based communication:

- Deny background Location Services permissions (please still permit "when in use" Location Services permissions)
- Open the app manually each time you'd like to start tracking a journey.

All static data for stations and railways is included when downloading the app and is stored locally on your device. All location-based searching happens locally.

## Battery impact

Eki Live is carefully designed to minimize battery impact. 

I'm acutely aware that iOS users are extremely protective of battery life, and apps that run in the background are rightfully treated with great suspect. 

Eki Live has two states:

- idle in the background
- tracking a journey

In short, in my testing, Eki Live has the following battery impact:

- **While idle** - an unmeasurably small amount of battery impact.
- **While actively tracking a journey** - about the same battery impact as listening to a song on bluetooth headphones locally in the Music app.

If you're looking for more detail, I'll clarify exactly how Eki Live affects battery life below.

While idle in the background, Eki Live uses zero processing power. It may or may not use some resident memory (an attribute managed by the operating system alongside all other backgrounded apps).

When iOS detects your device has moved some hundreds of meters, it will wake up Eki Live for a few seconds to provide location data. Eki Live will quickly check whether your device is moving at train speeds. If it's not, it goes right back to sleep. 

If the device *is* moving, Eki Live switches into tracking mode.

In tracking mode, Eki Live processes new GPS coordinates up to one coordinate per second while moving, and fewer while stopped at stations. Processing involves a few local SQLite database queries and some math operations. When the app is open, the map is updated as new GPS coordinates are received. When the app is closed, the app will only send updates when the contents of the Live Activity change (e.g. the station phase changes from "soon" to "now").

The processing work described above still has some room for optimizations, so future releases will include battery life improvements.

## Eki Live and ambient computing

Eki Live is an experiment in [ambient computing](https://en.wikipedia.org/wiki/Ambient_intelligence). Ambient computing is technology that blends into the environment and uses context to respond to human behavior without explicit commands. In the case of Eki Live, the app uses iPhone sensors to determine whether it's on a train and integrate the sensor data with map data to determine which railway you're on.

My friend Sergio and I were at lunch talking about smartphones and apps several years ago. He said something that, at the time, didn't totally make sense based on how limited iOS was outside of the app ecosystem. Paraphrasing him: "People don't want to open apps. I should be able to get 90% of what I need from an app without opening it."

In the long early years of iOS, push notifications were the only way for an app to escape its bounds and integrate into other parts of the system UI. I was skeptical of Sergio's sentiment at the time because it felt impossible to achieve. Push notifications are somewhat one-dimensional in what kind of user value you can deliver.

In the more recent era of iOS, there are many more integration points for apps into the system UI: [Widgets](https://support.apple.com/en-us/118610), [Live Activities](https://support.apple.com/guide/iphone/use-the-dynamic-island-iph28f50d10d/ios), [App Clips](https://developer.apple.com/app-clips/), [Shortcuts](https://support.apple.com/guide/shortcuts/welcome/ios), [Spotlight](https://support.apple.com/en-us/118232), etc. Each of these carves out a new niche and bridges the gap between app UI and system UI.

Outside the iOS world, there's been an influx of consumer hardware experiments that push ambient computing in some way: wearables like the defunct [Humane pin](https://en.wikipedia.org/wiki/Humane_Inc.); voice assistants like Alexa speakers; and robot vacuums to name a few. Mixed reality wearables may eventually become ubiquitous and escape the app-centered philosophy still core to the OS of the Apple Vision Pro.

All this is to say that Eki Live is my own skeptical experiment into escaping the app-bounds. As an app dev, the easiest delusion to fall into is "people want to open my app". Eki Live is the first app I've tried to design around users getting value from the app without needing to open it or even remember it exists.

The key phrase in that last sentence is "user value". Showing users exactly what they want before they know they want it is very very hard. And to me, it's annoying when it's not right. For example, the "context aware" Widget Stacks built into iOS are hopeless. For all but the most obvious use cases it's impossible to predict what people want to do with 100% accuracy. The only reason I started working on Eki Live was based on *probably* having the ability to predict when someone was riding a train and then being able to present the UI automatically in a non-obtrusive way that still provided enough value.

And, from a development perspective, it was not easy to connect all those dots. As of version 1.0, the dots are still somewhat loosely connected (as detailed in the Limitations section above):

- The app waking up in the background is limited by the accuracy of the Core Location APIs to quickly report significant location changes.
- The app being able to accurately detect your current railway line is based on the accuracy of GPS and the density of other railways in the area.
- The amount of information the app can show is limited to the space allotted to Live Activities on the lock screen and Dynamic Island.

If all these parts worked flawlessly, you would always have an indicator of the current/next station inconspicuously located in view. But what is the *value* in that?

## Why do train passengers need to see the current/next station?

Put simply, when riding a train, you need to know what station you're at so you can decide *whether or not to get off the train*. By nature, the current/next station information is only relevant for a few minutes at a time, and thus your awareness of it as a rider needs to be continuously updated.

Something I noticed during my alpha testing of Eki Live is that there's a psychological aspect to *needing* to know where you are at any given time. This might affect certain people more than others. Whether it's a nagging feeling of "oh no, did I miss my stop?" or something deeper about being moved through space in a way that humans only began to experience in the last couple hundred years, I still feel it's difficult to completely give up my awareness as a passenger in a train, car, etc. Although this phenomenon may be real and may drive retention, it's probably not enough of a top-of-mind motivator for someone want to download the app.

There are a few *train native* ways to stay updated on the train's current location or otherwise know when to get off the train (I'll ignore app-based tools for the moment).

### Door-adjacent live-updating signage

Most train cars have a full color LCD or at least dot-matrix screen near the doors that shows the current or next station on the line:

{% caption_img /images/eki-live-jr-door-lcd-sign.jpg h400 Next station information in an LCD screen above the door on a JR Line car %}

However:

- The screen cycles through several different information sets like all stops, platform maps, delay information, etc., so the exact information you need may be unavailable at the moment you need it (when quickly deciding whether to exit the train before the doors close).
- The screen cycles through ~4 languages/scripts, so it may be unreadable to you for short periods.
- The screen may not be visible from all standing/sitting positions, especially on crowded trains.
- The text on the screen may be too small to read from your position.
- Dot-matrix screens are particularly low-information density and hard to parse.

### Audio announcements

Announcements for the train's current location are made over the loudspeakers in each car. They usually include an announcement for:

- The next station as soon as the doors close at the current station.
- The approaching station within a couple hundred meters.
- The current station as the doors are opening.

Depending on the line, these announcements are made consecutively in Japanese and English. They sometimes include a list of the connecting railway lines at a station, which side the doors will open on, a reminder of the rules of riding the train, or non-automated, urgent information about delays or accidents.

Audio announcements are useful, but also have weak points:

- Audio announcements are push-based not pull-based (i.e. not on-demand) – you need to pay attention at the right time or always be passively listening.
- Audio announcements can be difficult to hear in noisy cars.
- Audio announcements are inaudible when listening to music or spoken-word content on headphones.
- Non-automated announcements (live from the conductor) can be especially difficult to understand.

### Platform signage

When pulling into a station, the station's name and its one or two adjacent stations are often written in various locations along the platform. Generally, whether or not you can see one of them as a rider is random depending on which train car you're in, your relationship to a window facing the platform, and whether there are other passengers (on the train or waiting on the platform) blocking your view.

{% caption_img /images/station-detail-bashamichi-photo.jpg h200 Platform signage on the opposite wall of the platform at Bashamichi station %} 

### Timetable

If you somehow have access to the train's timetable *and* the train you're riding stays true to that timetable through your arrival station, you could use your watch to know approximately when to get off the train.

My other train-related app [Eki Bright](/2024/07/27/eki-bright-tokyo-area-train-timetables/) actually facilitates this method once you've selected your destination in the app. It shows your arrival time next to the current time as a Live Activity.

{% caption_img /images/eki-bright-arrival-time-dynamic-island.jpg h200 Eki Bright's Live Activity showing a 15:11 arrival time at Naka-meguro station after setting up a DIY Route in the app %}

### Navigation apps

Any number of popular navigation apps (Google Maps, Apple Maps, Jourdan Norikai Annai) will show you all kinds of information about your journey, both within the app and in other parts of the system via Live Activities, widgets, notifications, etc.

However, the main downside to all of these apps is that you always need to explicitly tell the app that you've started a trip, where your destination is, and which specific departed train you're riding. Or if you just want to see your current location on a map, you need to open the app and wait for the GPS to kick in.

If you're just taking a quick trip or you're on a route you know well, it's usually not worth the hassle to open a navigation app to search for and select your exact itinerary, especially if you've already departed.

### Where Eki Live shines

Eki Live is especially useful for those everyday, routine rides. You don't need to remember to open an app. You don't need to bother selecting a route. It just appears when its relevant and disappears when it's not. It adds another layer of security and awareness, especially when you've got your headphones in and are locked into reading an article or manga, watching a video, scrolling endlessly, or deep in a mobile game. It only needs a few pixels of otherwise unused screen real estate.

Tourists may also find Eki Live useful, but I haven't explored this use case fully. In theory, having another tool that automatically shows information about what railway line you're riding could help tourists from getting lost. But especially with Eki Live's current limitations on underground operation, thinking about another app may be a distraction.

## Roadmap

The first thing on the roadmap is to get a general feel for whether this idea connects with people:

- Is the value-proposition presented in a way that makes people curious enough to download the app, set it up, and see it working as designed with their own eyes?
- Do users start to rely on it enough to complain about its limitations?

This means marketing the app well enough to fill the top of the funnel.

Assuming the above two points check out and the app concept is worth pursuing further, I'll be working on two concurrent high-level goals:

1. **Improve usability**: add more ways for users to customize the app if they so choose - snooze automatic tracking for some period of time; better support manually triggered tracking; add station arrival alarms; show more information in the app about the current railway; show estimated arrival times.
2. **Improve the tracking algorithm**: improve the train alighting detection; improve the differentiation between parallel railways; underground railway detection.

I'd also like to incorporate some of the research done for Eki Live into Eki Bright as I originally intended. But that is lower priority until the concept of Eki Live is thoroughly proven or disproven.

## Wrap up

I'm really looking forward to receiving feedback from everyone that tries out Eki Live. There are so many unique ways people get around Tokyo. Hopefully Eki Live can find its niche.