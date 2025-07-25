---
layout: post
title: "Reintroducing Technicolor: Binge Watch with Friends Over Space and Time"
date: 2025-07-25 14:00:00
tags: technicolor ios app
---

Although it's still in beta, I think it's a good time to reintroduce my web app side project called Technicolor.

Technicolor is chat app tailored for watching TV shows with friends asynchronously. I've found it to be a great way to stay in touch with friends in other cities/states/countries.

The current version of Technicolor is a native SwiftUI app available on iOS 17.4+ devices and macOS.

![TODO overview of the main iphone screens in light mode]()

## How it works

1. **Gather some friends**: Technicolor is optimized for IRL close friends. A group from 2-4 friends is most optimal.
1. **Choose a TV show to watch**: The best picks are shows that you can imagine generating a lot of reactions or hot takes, but choosing the right show is more art than science in my experience so far. Technicolor doesn't embed/include media, so all members must have access to the streaming service.
1. **Create a Room**: Each episode discussion lives in its own chat room. Technicolor uses [TMDB](TODO) as its media metadata provider.
1. **Watch the episode on your own schedule**: Each Room member watches the show and leaves comments tagged with the episode timestamp. If you watch first, you lay the foundation for discussion. If you watch later, you're often replying to existing comments. It's a unique experience each way.
1. **Mark as watched**: Tap the "Mark as Watched" button to alert other members via push notification that you've left comments.
1. **Read and reply**: Respond to comments from other members.
1. **Move onto the next episode**: Technicolor has helpers for quickly creating a Room for the next episode.

## Main features

### Navigate your watchlist in the Dashboard

![TODO Dashboard screen]()

Manage your watchlist on the Dashboard screen. The dashboard intelligently manages active Rooms so you have quick access to episodes you need to watch and those you need to read comments for.

Rooms are grouped logically by TV show and members.

Technicolor also supports movie watching groups. All movies watched by the same members are grouped in one section.

It's easy to create the next episode by tapping the more button and choosing "Create Room for S03E01".

![TODO Create next room]()

### Leave comments in a Room

![TODO Room interface]()

Comments in a Room are grouped into mini-threads by timestamp.

There's a custom control for selecting a timestamp by tapping and dragging like a video scrubber.

![TODO gif of using the timestamp control]()

Tap the info button to see a quick overview of metadata about the episode via TMDB.

### Start a new show

There's a flow for adding your first Room for a show. Search for a TV Show, Movie, or enter a custom title. Then select which friends you'll watch with.

![TODO: new room search screen]()

### Friend management

Technicolor has a full mutual-friend management system. You can only create new Rooms with users you have a mutual friendship with (or are already in an existing group with).

![TODO: me screen showing friendship operations]()

### Invites

In this beta phase, Technicolor uses a invite system to control new user sign-ups. A user can create unlimited invite codes to invite their IRL friends.

![TODO: invite screen]()

## Limitations

### Async-only

This native-first version of Technicolor follows a few other variants I've created and used over the years (see the History section below). 

In earlier versions, Technicolor could operate as both a live-streaming, synchronous client in addition to a async client. I found that live-streaming support, although kind of cool, didn't really make sense in the timestamp marked format. Normal chat apps work fine since everyone is synced and reading/writing comments in real time. There's also not much reason to keep the history around since everyone has already caught up on comments.

For this reason, and to keep implementation complexity low, I've left out Websocket support. Optimizing the UI and UX for asynchronous makes things much simpler to use, explain, and maintain.

### Apple platforms-only

*Most* of my friends are iOS/macOS users, and since I am an iOS specialist, I've decided to only target Apple platforms for now.

I'm considering a web version for the future to include my Android/Windows friends. But at the moment, it's already a lot to fill out the feature-set and polish the UX for a non-revenue generating side project.

## The future of Technicolor

I'm planning to do beta testing with my close friends for a while until all the primary flows of the app feel production ready.

I still have plenty of unimplemented ideas that could improve the episode-watching-commenting flow.

- There should be a timer mode that automatically counts up while the episode is running so you don't have to choose timestamps manually as often.
- The TMDB episode detail screen should also load the list of actors and characters in an episode for easy reference. Bonus points for being able to @-mention a character/actor in the chat box with autocomplete support.
- I've implemented subtitle fetching support on the backend, but haven't thought through exactly how to surface this info in the app. You could optionally attach a line from the subtitles to a new comment. Or subtitles could automatically appear in line near timestamps automatically.

I have reservations releasing a social network to the general public due to the amount of moderation required. Technicolor is closer to a private chat app than a social network. And with its current user relationship model it's probably safe enough and niche enough that bad actors can't wreak too much havoc. But I'd still probably need to implement message reporting, an admin dashboard for moderation, and some more safeguards around spamming. Being iOS/macOS-only also ensures that spam is less prevalent than it otherwise might be.

I could keep the invite system to both limit the growth rate, prevent abuse, and contribute to successful user onboarding.

I'd probably need to harden the backend API a little more, maybe put Cloudflare in front of it. The Fly.io instance currently goes to sleep when there's no activity to save money, so I could choose to keep it on. The machine specs are very weak so I could beef those up as well to ensure my users see the theoretical speed of Swift on the server.

## A brief history of Technicolor

I first wrote about Technicolor back in 2013 in [a post about my side projects](/2014/01/26/fall-2013-project-wrap-up/#:~:text=to%20show%20though.-,Technicolor%20TV,-Status%3A%20Under%20Infrequent).

The short version is that I moved from Chicago to New York and still wanted a way to watch TV shows with my Chicago friends. We'd still regularly get on video calls to do live stream watching, but for other shows we started emailing each other with our comments timestamped. These emails started to get unwieldy, and I posited that a simple web app could improve the watching experience while also facilitating episode management outside an email client.

The first version was implemented as a Ruby on Rails app deployed to Heroku and vending HTML and simple JavaScript. It supported the browser-only and not well-optimized for mobile devices (at the time, I didn't own a dedicated TV set and watched most shows on my computer).

After the initial short development period, Technicolor worked well enough that I didn't need to do much active development. Additionally, the code I wrote as a hobbyist Rails/JS-dev had already reached the point of complexity where it was no longer easy or safe to make even minor changes.

In late-2017 I moved to Japan and was motivated again to revive the side project as mobile first. I also wanted to explore a different backend architecture that was type-safe. I briefly started an Elixir backend, and although I already had a little experience with it, it soon became clear that it was too bespoke, especially for a side project I only had occasional time to devote to.

Swift on the server was starting to get some buzz, and some exploration with Vapor made it seem like there were theoretical merits to having a unified language for back-end and front-end development.

I started chipping away at development again (while still using the legacy web-app version), but I fell into side-project hell where each time I'd have the motivation to work on it, I'd spend the entire day updating Vapor, migrating Swift, changing hosting providers, or converting to the latest SwiftUI APIs. There was very little forward progress.

I fell into various scope-creep traps as well. Adding the invite system. Adding full mutual friendship support and blocking. My previous episode data provider TVDB went to a paid-only API, so I descoped that and moved to a Room system that had no media-linking.

Heroku's free tier was discontinued in 2022, and with it the legacy version of Technicolor went offline.

Coming off some headwinds with [my last rewrite experience](TODO: link to claude code vinylogue post), I finally decided to check the status of my codebase after over 2 years of dormancy. As I suspected, Claude Code made quick work of updating all my iOS code to my preferred architecture and the latest APIs. Unfortunately, the Vapor framework was a lot further behind the Swift 6 migration than I'd hoped, but still has reasonable support for most bread-and-butter web app capabilities.

I got somewhat lost in the scope creep flow, tearing through the implementation of all the features that had been rotting on my TODO list for literal decades. On the user-facing side, I'm especially proud of the very streamlined dashboard layout and the push notifications support (the impetus of the mobile-first rewrite in the first place). On the dev-tooling side, I'm proud of having a comprehensive server-side test suite and a custom release wizard script that prepares and submits both iOS and macOS versions of the app.

## Tech stack details

As mentioned above, Technicolor's backend is written using the [Swift Vapor](TODO) framework. It's hosted on [Fly.io](TODO). The client is an iOS target written in Swift and SwiftUI and supporting iOS 17+. There's technically a native macOS target via Mac Catalyst, but it actually looks and functions worse than the Designed for iPad version, so I'm probably going to deprecate the Mac Catalyst version.

I'll do a deeper dive into the tech stack in a future post because I think there's at least a few interesting and unique points to the architecture.

