---
layout: post
title: "Rewriting a 12 Year Old Objective-C iOS App with Claude Code"
date: 2025-06-22 17:56:00
image: /images/vinylogue-v2-main-screens.jpg
tags: vinylogue apple ios
---

Last week, I rewrote my iOS app [Vinylogue](https://itunes.apple.com/us/app/vinylogue-for-last.fm/id617471119?ls=1&mt=8) to Swift and SwiftUI with the help of [Claude Code](https://www.anthropic.com/claude-code). I originally created Vinylogue [back in 2013](/2013/04/03/the-making-of-vinylogue/) targeting iOS 6. Recently, I've been wanting to try out Claude Code, and I decided updating Vinylogue would be a good test project for it.

TL;DR: Using Claude Code made this rewrite super fun and productive and was absolutely worth the $20, even considering the time I spent learning the limitations of the tool and how it's still relatively unoptimized for Apple platforms development.

## Table of Contents

- Overview
- The goal of the rewrite
- A walkthrough of my daily accomplishments and phases of the rewrite
- Specifics of working with Claude Code including:
	- Lessons learned
	- Genres of tasks I used it for
	- What I want to try next time
	- Lots of stray observations

## Overview

Vinylogue is an app that shows you and your friends' last.fm album listening history for "this week in history"; i.e. if it's the first week in June 2025, it shows the first week in June 2024, 2023, etc.

It has three main screens: a users list, the weekly albums list, and an album detail view. There's also various screens for settings, onboarding, user list editing, etc.

{% caption_img /images/vinylogue-v2-main-screens.jpg h500 Vinylogue v2.0 main screens: Users List, Weekly Albums, and Album Detail %}

If you happen to be an active [Last.fm](https://last.fm) user, give the app a spin by [downloading it from the App Store](https://itunes.apple.com/us/app/vinylogue-for-last.fm/id617471119?ls=1&mt=8). And it's been [open source on GitHub since v1.0](https://github.com/twocentstudios/vinylogue).

Overall, the experience of rewriting the app was a lot of fun with Claude Code. Even with the learning curve and my non-optimal device environment, the amount of progress I made was exponentially higher than I could have alone. As much as I've considered rewriting the app in Swift over the years, I could never justify it; the app still worked well enough, has very few active users, and makes no money. 

Using Claude Code to automate a lot of tedious work of porting the data models, dominant color algorithm, and data migration code left me with an unusual abundance of time and energy to focus on the parts I was interested in: ensuring the visual design matched exactly; improving caching and pre-caching behavior, improving the friend management UX, and reworking the chart year navigation.

<video src="/images/vinylogue-v2-dominant-color-demo.mp4" controls preload="none" poster="/images/vinylogue-v2-dominant-color-demo-poster.jpg" height="720"></video>

<video src="/images/vinylogue-v2-chart-year-navigation.mp4" controls preload="none" poster="/images/vinylogue-v2-chart-year-navigation-poster.jpg" height="720"></video> 

I could have probably stopped at day 3 and had pretty close feature parity, but I was having so much fun challenging Claude that I started experimenting with more robust architectures. I migrated the entire codebase to the [Point-Free co.](https://www.pointfree.co) Modern Swift-UI architecture using [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) and [swift-sharing](https://github.com/pointfreeco/swift-sharing) using their open source [SyncUps](https://github.com/pointfreeco/syncups) codebase as a template.

The SyncUps architecture unlocked the ability to have Claude follow a [blog post](https://blog.winsmith.de/english/ios/2020/04/14/xcuitest-screenshots.html) I found about using UITests to automatically generate screenshots for the App Store. A few years ago, App Store review started clamping down on use of copyrighted images in App Store screenshots, and I'd have to manually add a pixelation filter to each image before uploading. It was easier to work with Claude to incorporate the pixelation filter as an option in the app code than to do that work manually.

{% caption_img /images/vinylogue-v2-pixelated-weekly-chart.jpg h400 Pixelated version of the weekly album chart view showing privacy-protected album covers %}

I got so carried away that I did plenty more refactorings to have Claude look for duplicate SwiftUI View code that could be extracted and reused across multiple screen-level Views. I had it make a few proposals for how it'd be best to reorganize the project's folder structure. I never had to get into the weeds refactoring and burn brain cycles, so I almost always felt fresh to use my mental energy on the higher-level planning.

In the end, I'm actually much more proud of the cleanliness of the Vinylogue codebase than my other codebases I've worked on this year. It's not that I couldn't spend a few days pushing files around in those other codebases, but since I'm an indie dev, I'm not getting paid for that and it's hard to justify doing that work when I could be doing marketing.

Over the past few months, I've been using the ChatGPT app with its less intrusive Xcode integration to do some selective coding work using o3 and o4-mini. Although Claude Sonnet is seemingly not as "smart" as several other frontier models, Claude Code unlocked a new level of usefulness for me due to:

- Its ability to view the xcodebuild output and fix its own syntax errors.
- Its ability to plan, create its own TODO lists, and methodically execute on its plan.
- Its ability to quickly navigate around my codebase with various amounts of guidance by me.
- Its ability to incorporate documentation and other context.

The above abilities increased the scope of net-positive productive use cases for LLM-assisted coding. The amount, accuracy, and complexity of code that an LLM writes needs to be surprisingly high to justify me copying and pasting code from a chat interface or manually applying (often broken) diffs. When the time and effort cost for me, the developer, goes to zero for making changes, suddenly both 1-line changes and multi-file refactors with ample opportunity for syntax errors are both productive use-cases.

Those are my overall thoughts about the experience. Before I dig into the meat of this post, here are some quick stats about the rewrite:

- **$353** - theoretical spend on Claude Code if I had used the API
- **$20** - actual spend on Anthropic Pro subscription
- **+11,275 −8,249** - total lines changed in the [v2.0 pull request](https://github.com/twocentstudios/vinylogue/pull/5)
- **5,609** - lines of Swift code (excluding tests)
- **52** - Swift files (excluding tests)
- **7** - calendar days of work from first commit to App Store submission

{% caption_img /images/vinylogue-v2-vibemeter-spend.png h300 Theoretical spend calculated via VibeMeter app %}
	
**As a quick disclaimer**, LLMs and the developer tools space is moving so fast that a lot of these observations will be immediately dated. For reference, the app/tool versions I used in this post:

- Claude Code v1.0.31
- Sonnet 4
- Xcode 16.5
- iOS 18.5
	
## Goal of the Rewrite

In early 2013, I was in another period of indie dev between full-time jobs. I was churning through a few app ideas, learning a lot but biting off more than I could chew and not releasing anything. I got some inspiration after I started using an app called [Timehop](https://timehop.com), the first service of its kind that aggregated your past social media activity in what Facebook would later popularize as "This Day in History". I was an avid Last.fm user, and by that time Last.fm had already become a niche service, so I decided it would be fun to make a Timehop-for-Last.fm. I developed the "feature-complete" v1.1 app in 5 weeks.

I wrote a [very detailed blog post](/2013/04/03/the-making-of-vinylogue/) about the design and development of the app. The Timehop team found that post and hired me as an iOS contractor for a few months before I moved from Chicago to New York to join the team full-time. 

{% caption_img /images/vinylogue-v1-main-screens.jpg h500 Vinylogue v1.1 main screens: Users List, Weekly Albums, and Album Detail %}

The fact that this app got me my first *real* iOS developer role makes Vinylogue significant and nostalgic for me. 

I've done my best to make the few changes required over the years to ensure the app still works in modern iOS versions on modern devices. But the fact that's it's Objective-C with a very opinionated reactive architecture made it so the cost of developing new features was always too high.

Regardless, I've continued to check the app weekly and use it as a nice reminder to listen back to albums I haven't revisited in a while.

Based on glowing reviews around the internet, I've been wanting to try Claude Code, but hesitated because:

- The pay-per-token model felt unideal to me; I didn't want to pay an unbounded amount to get burned learning a tool that in the end didn't make me any more productive
- My current projects were not ideal for intensive LLM-assisted coding - I figured I probably wouldn't learn how to use Claude Code effectively without a more greenfield project

Vinylogue popped into my head as a great test project: it was greenfield, but had a complete product spec, design spec, and reference codebase to draw from. There was no deadline, no external code-quality bar to hit, and if it wasn't working out, I could give up any time and still have the same tried-and-true codebase around for the foreseeable future.

So **the goal starting out** was: 

- learn Claude Code as a tool
- determine what kinds of tasks and projects Claude Code could be useful for
- update Vinylogue to modern Swift and SwiftUI while making a few small improvements
- leave the door open for new feature work in the future

## Project daily summary

Below is a graph with the high-level breakdown of code changes over the week.

{% caption_img /images/vinylogue-v2-swift-lines-graph.png h400 Lines of Swift code added and removed during the rewrite, grouped by 5-hour time blocks %}

### Day 1: Scaffolding 

[End of day 1 - commit 2c4843b](https://github.com/twocentstudios/vinylogue/tree/2c4843b4f8aec49e30f8c6c4230bdcb2cdf6fddc)

{% caption_img /images/vinylogue-v2-day1-progress.jpg h500 Screenshots of the app after day 1: basic scaffolding and initial SwiftUI implementation %}

As you can see from the above graph, Claude Code cranked out the foundation of the project on the first day. Due to the usage limitations of the Anthropic Pro subscription, I could only use it for about 1 hour every 5 hours. So even though the first day represented the most code written, it was only about 4 hours of usage total. I was doing work on other projects and eating and doing chores in the downtime.

My goal for the first day was simply to get a feel for Claude Code and see what it was capable of. I wanted to see what its tendencies were when it had little direction. I gave Claude Code [a spec that OpenAI's o3 had written](https://github.com/twocentstudios/vinylogue/blob/cb1ad8350870cf2c6643f4f90daeb0148b707ef7/Planning/PRD.md) based on the Objective-C codebase and screenshots of the current version, but Claude basically threw that out and [wrote its own spec](https://github.com/twocentstudios/vinylogue/blob/9902e4f5d313c6ffb5f0fd6191979c78fdac87c4/Planning/PRD.md) before starting to crank through the [8 sprints worth of TODOs](https://github.com/twocentstudios/vinylogue/blob/9902e4f5d313c6ffb5f0fd6191979c78fdac87c4/Planning/sprint-00.md). I was intentionally not providing any input on design or architecture. After it worked through a sprint, I'd give the code a once over, but mostly commit it to the working branch.

It felt very productive, but this was essentially just a more advanced version of scaffolding (something my friend Jens compared to Ruby on Rails' scaffold command). Over the course of the week, this version of the code would be the clay I'd be molding and detailing to get to the final form.

Claude Code had defaulted to what I'd consider an iOS 16 SwiftUI architecture. It used a mix of `@Environment` and singletons for services, `@StateObject` with `@ObservableObject` and `@Published` properties for ViewModel-ish objects. It had strewn about `UserDefaults` calls and wasn't particularly consistent about any other architecture decision. It ignored all my instructions about styling and tried to support dark mode, dynamic type, random accessibility attributes.

But it mostly worked! Especially convenient for me was the reams of `Codable` objects, parsing, and API client code required to do the `weekly chart list -> weekly chart -> list of albums` data transformation from the Last.fm API. All that worked out of the box, even if I did spend some time later in the week optimizing the caching and pre-caching.

I learned a lot on this first day. And having so much of the foundational code out of the way without much mental energy expended increased my appetite for the scope of the rewrite.

### Day 2: Styling & Core UX

[End of day 2 - commit 03d763a](https://github.com/twocentstudios/vinylogue/tree/03d763a)

{% caption_img /images/vinylogue-v2-day2-progress.jpg h500 Screenshots of the app after day 2: improved styling and core UX implementation %}

The second day was mostly about styling and cleanup and small bug fixes. After a couple tries, I gave up on having Claude Code try to faithfully recreate the styling 1-to-1. Without a feedback loop in place for it to view the visual results of its code, I suspect it was a fool's errand. Instead, I spent a little time creating color and font helpers, then using them in the `UsersListView` to lay it out exactly as I wanted.

From there, Claude was mostly capable of using that view's styling to get the auxiliary views like the settings view and edit friends view to 98% correct and using all the standardized helper functions.

The edit friends view in particular was more complicated than it used to be in v1.3.1, so I spent some time fixing some of Claude's scaffolding bugs and deciding exactly how the UX should be.

I also had Claude Code do a Swift Concurrency audit and I helped it migrate the codebase to strict Swift 6 mode.

### Day 3: UI & UX focus

Day 3 I continued hand-polishing the UI for the most important screens. I implemented the overscroll year-navigation mechanism in a SwiftUI Preview, then had Claude Code help me copy it into the View and wire it up.

I was also finding new excuses to push the scope. I integrated [swift-dependencies](https://github.com/pointfreeco/swift-dependencies), double-checked the loading and error states, and added haptic feedback.

This is the day that I *could* have buckled in and focused on finishing up the v2 rewrite to be functionally equivalent to v1, including its warts. I could have left the code quality in a somewhat embarrassing state. But at this point I still had lots of energy and motivation. Stopping here would have felt like leaving too much low hanging fruit.

### Day 4: Circling back

I finally got around to matching the visual style of the v1 `AlbumDetailView`. This includes porting the [custom dominant color algorithm](https://github.com/twocentstudios/vinylogue/blob/906c1ce86c8bdb926db6dcb0eada664b80fb8743/Vinylogue/Core/Infrastructure/ColorExtraction.swift) from [v1](https://github.com/twocentstudios/vinylogue/blob/5409d38a061770c0f84325ca7e0e7dccbe8d587f/vinylogue/UIImage%2BTCSImageRepresentativeColors.m). At first, Claude Code took a shortcut and used the average color CIFilter. I forced it to convert my Objective-C code line-by-line, and it did a great job besides using an erroneous color space value that took about 5-10 minutes to track down.

V1 did not have any sort of precaching system, so album images always appeared to load very slowly (mostly due to a limitation in the Last.fm API). On day 4 I added data and image precaching so that navigating between years would be seamless.

I finally tested the important v1 data migration code (for the current user and friends), and it turns out Claude had failed miserably. To be fair, the NSCoding implementation is not as straightforward as Codable, so it took some guidance from me, along with a test plist file, in order to get it working.

### Day 5: Architecture and screenshot automation

Being an indie dev responsible for releasing apps and updates means lots of overhead in creating App Store screenshots and marketing info. I wanted to experiment with using UITests to generate screenshots, but a big blocker to this was ensuring I could inject mock data so that screenshots wouldn't change each time I ran the process. This led to me finding my swift-dependencies implementation was unideal (read: working, but incorrect).

So I took on another side-quest of refactoring the app architecture, inspired by the [Point-Free co. SyncUps app](https://github.com/pointfreeco/syncups). Feeding this codebase to Claude Code and having it make the first pass got me to about 80% refactored. Formalizing the rules and having it take another pass got it to 90%. Doing the final audit for the last few problem classes got it to 100%. It was kind of amazing to be able to stay at a high level of abstraction and see what a given architecture looks like for your codebase. I could have thrown this refactor out with no harm done, but it accomplished my goals and felt like it made the codebase more maintainable. Spending a little extra time formalizing my adapted architecture rules on a relatively simple codebase opens up the possibility of using this codebase as a template for refactoring my other, more messy codebases.

With the architecture refactoring complete, it was now possible to have Claude Code finish up the automated App Store screenshotting code. I used Perplexity to research all the prior art, found [this blog post](https://blog.winsmith.de/english/ios/2020/04/14/xcuitest-screenshots.html), fed the blog post to Claude, and had it follow the blog post step-by-step to create a custom bash script, UITest, and modifications to my top-level `App`.

I'd already considered automated screenshotting a stretch goal, but I wanted to push even further. I added a toggle-able pixelate filter to all the album images so I'd have a set of screenshots available for App Store use and external advertising, all without me needing to open Pixelamator. This was quick and straightforward now that the new architecture was in place and because NukeUI has a great image processing pipeline feature that can run CIFilters.

{% caption_img /images/vinylogue-v2-pixelated-comparison.jpg h500 Comparison of non-pixelated and pixelated versions of the weekly album charts for App Store compliance %}

### Days 6 & 7: Prepare for App Store

By day 6, the app was feeling super polished. I was a little worried about the migration from v1.0 still since you only get one shot at that, so I spent some more time manually testing it.

Since this app is open source, I cleaned up the project folder, rewrote the README, and prepared the marketing images.

Uploading to the App Store, I found that a few of the v1 xcodeproj settings had not been properly migrated to the xcodegen project.yml file. I needed to disable iPad support and force portrait orientation and add the non-exempt encryption plist setting. Claude Code could do all that with loose prompting; I never needed to look up the key names or dig into the xcodegen docs.

At the last minute, I found an issue with image caching that I'd missed (I thought I had disabled both data and image precaching for `DEBUG` builds only, but in fact the image cache had been misconfigured the whole time).

Finally, I uploaded a build to the App Store, submitted it, and it was approved and released the next morning.

Claude Code helped me create a Release on GitHub by uploading images. It even looked through my old versions' screenshots and created a Release for those versions too.

## Most interesting parts of v2.0

The v2 Swift rewrite is intentionally nearly identical to the Objective-C v1. However, there are a few user-facing and under-the-hood parts I'd like to highlight.

### Overscroll year navigation paradigm

The weekly album chart view in v1 had a unique left/right button/slider paradigm for navigating between years. Honestly, it was kind of strange, but I always liked how it gave the app some extra personality.

<video src="/images/vinylogue-v1-year-navigation.mp4" controls preload="none" poster="/images/vinylogue-v1-year-navigation-poster.jpg" height="720"></video>

In my original [blog post](/2013/04/03/the-making-of-vinylogue/), I actually mentioned how my first sketches planned for year navigation to be at the top and bottom edges. 

{% caption_img /images/vinylogue-wireframe.jpg h400 Original notebook sketch showing the planned top/bottom year navigation design from 2013 %}

At the time, I gave up on the top/bottom paradigm because it felt strange as section header/footer for years with few albums, and there was no concept of safe areas yet.

I decided to cash out some of my excess mental energy for v2 to try to update the year navigation paradigm, actually forgetting that the top and bottom buttons were what I'd originally planned over a decade ago.

<video src="/images/vinylogue-v2-chart-year-navigation.mp4" controls preload="none" poster="/images/vinylogue-v2-chart-year-navigation-poster.jpg" height="720"></video> 

I think it turned out alright! It's non-standard UX, but I feel like it's unique in the same way the v1 implementation was.

I'll note the standard Apple refresh control triggers the refresh immediately once you hit the overscroll threshold, but mine requires you to release above the threshold in order to trigger the navigation.

### Dominant color album detail animation

I remember during v1 development that the album detail view animation was a happy accident due to the dominant color and album image loading being unoptimized.

I made sure to faithfully port the dominant color algorithm and set up the SwiftUI View so that the animation always triggers consistently, even though the more robust image precaching means that the image is pre-loaded 99% of the time.

<video src="/images/vinylogue-v2-dominant-color-demo.mp4" controls preload="none" poster="/images/vinylogue-v2-dominant-color-demo-poster.jpg" height="720"></video>

The last small piece was ensuring that the back button (missing in v1, but returning in v2) also changed its tint color to match the rest of the text on the screen. I accomplished this with a custom `PreferenceKey`.

### Caching and pre-caching

As mentioned before, I never got around to optimizing the caching and pre-caching behavior of data and images in v1. The Last.fm API is unchanged in the last decade, but average internet speeds and disk sizes means that I don't feel as hesitant to pre-cache data to ensure browsing your listening history is seamless.

### Legacy data migration

I hate when companies release an app major version update and put the icing on the cake by force logging you out. I know I don't have many users, but I still feel obligated to treat them with respect and migrate the small amount of unique local data they've entrusted with the app.

Honestly, this data migration was one of the biggest discouraging factors in me not taking on this rewriting project in the past. I knew unraveling the NSCoding implementation would be a tedious, thankless task. Although Claude Code could not one-shot it, working with it made this task bearable, and I'm glad I did it.

### Vinyl loading spinner

The vinyl loading spinner is a small flourish, and honestly not even that present anymore now that there's much more precaching, but I'm still happy to have it scattered around the app.

{% caption_img /images/vinylogue-v2-vinyl-loading-spinner.gif h400 Vinyl loading spinner animation showing the rotating record effect %}

### Automated App Store screenshots

Automating App Store screenshots was arguably unnecessary for an app with only 3 screens and no localization. But as a test for Claude Code, it was a resounding success. I'll absolutely be referencing this implementation for my other apps in the near future.

### Under the hood

Finally, I got a chance to shore up my skills in implementing modern Swift concurrency, swift-sharing, and swift-dependencies in a low-stakes environment. I see this as a mirror to implementing ReactiveCocoa in v1 all those years ago, and then using that knowledge in production on the Timehop app.

## Working with Claude Code

I want to devote a section to braindumping all my impressions of Claude Code, both for readers and for future me. I imagine looking back on this in even a year will be nostalgic.

### Lessons learned

Note: most of these are general and some are specific to iOS and Apple Platforms development

#### Ignore all lessons

The first lesson is to ignore all lessons. Obviously this is tongue-in-cheek, but what I mean is that I'm glad I didn't try to optimize my usage of Claude Code out of the gate. It was much better to use it with its defaults, push it hard to find its limits, then incorporate tips & tricks I'd found through osmosis *after* I'd felt the pain those tips were meant to address.

Keep the below lessons in mind, but if you're just getting started with Claude Code, don't try to follow them all at once.

#### Add the `--quiet` flag to xcodebuild with building and testing

Claude Code already knows about xcodebuild and most of its options. But if you let xcodebuild run without `--quiet`, Claude Code will read all the useless output, quickly overflowing its context window, especially when the build fails.

#### Compact context before you need to

Claude Code will show you in the bottom UI how close it is to filling up its context window. Once it hits that limit, it'll automatically run `/compact` for you regardless of where it's at executing your latest instructions. This is fine when you're getting started and learning. But it's better to keep an eye on the context window usage and proactively either `/compact` with additional instructions on what it should focus on during the compact, or even `/clear` to start a new session with a known set of context (i.e. `CLAUDE.md`).

Early in development, I was strategically compacting a lot. But once the project was more mature, I used `/clear` much more liberally since I was hopping around the codebase and working on lots of different, smaller concerns.

#### Use the project root CLAUDE.md for important workflow instructions

Since these instructions will get read in each time you `/compact` or `/clear` its good to have the most important instructions about your workflow in here. For me, this included which simulator and os version to use in `xcodebuild`, always using the `--quiet` flag, always running `xcodegen` if files were added, always building and testing before returning control back to me, etc.

In my code source root one folder down, I put another `CLAUDE.md` that was more focused on the codebase itself. Later on, within each subfolder of the source, I had Claude Code generate its own short `CLAUDE.md` files summarizing the important parts of the code that existed in those folders. For example, the [`/Features`](https://github.com/twocentstudios/vinylogue/blob/master/Vinylogue/Features/CLAUDE.md) directory contains architecture rules about creating new Views and Stores that are only relevant when working in that parent folder.

#### Use `@` to point Claude Code directly to files you're working with

This is a bit of a tradeoff, but if you already know the exact file you need Claude to work on, then just use `@` to reference it. In the Claude Code UI, you'll see the fuzzy file picker pop up. Of course, Claude Code can use bash tools to find any symbol references, but this takes it a couple extra steps and uses up a little bit of extra context. Hard to say whether the tradeoff is worth it, so experiment and see what works best for you.

Optionally, depending on the scope of your request, you can also ask Claude Code to spin up a subagent to find all the required files and symbol references and pass them back to the main agent. That keeps the main agent context's clean while also unburdening you to need to do all the context gathering yourself.

#### Learn the proper usage of `plan` mode

Shift+Tab toggles `plan` mode (you'll see it in the bottom UI). Although Claude Code defaults to doing a least a little planning for every request by creating a little TODO list before it dives into code, by entering `plan` mode you can ensure it spends more time thinking and writing, then waiting for your approval before making *any* code changes.

You'll need to experiment yourself of when this extra step feels warranted. Maybe try overusing it at first until you start to instinctually understand when it feels like overkill. 

I didn't start using `plan` mode until later in the development of v2. I found it useful, but mostly because I also understood the kinds of requests (both the inherent scope of the task *and* the amount of context and explanation I gave for the task) that caused Claude Code to fail when it immediately jumped into coding.

#### Warp was not a convenient terminal to use with Claude Code

I started using [Warp](https://www.warp.dev) a few years back as my daily driver. I never really used its built in LLM features that much, but I liked its overall setup and usability for my limited purposes.

However, Warp was not particularly well suited as a driver for Claude Code. There were a lot of scrolling bugs and overall it just felt like the two were fighting each other. (Note: Warp just released their own coding agent as Warp v2.0).

I started using [Ghostty](https://ghostty.org) towards the end of development and its simplicity has worked well with Claude Code so far.

#### The Anthropic Pro plan's limits are fine for starting out

As mentioned earlier, at the beginning of development, Claude Code was cranking so hard that I was burning through my 5-hour usage limits in 60-90 minutes.

This meant a lot of waiting at first, but overall, I don't think this was a bad thing. Getting feedback on how hard I was pushing it gave me natural feedback about how to manage its context window (e.g. how `xcodebuild` without `--quiet` was overflowing the context window).

After the 2nd day, I either stopped hitting the usage limits or would only hit them near the end of a 5-hour window. Partially because I was working more on my own, partially because there was just less code for it to write or the scope of changes was smaller.

Eventually I may upgrade to Max, if only to test out the Opus model. But for now, I recommend the Pro tier as fine for beginners to learn the tool.

#### Be proactive in creating feedback loops for Claude Code

One of Claude Code's biggest strengths is its ability to use feedback loops to turn unsuccessful one-shot prompts into successful many-shot tasks with the help of tools. When Claude Code can make an attempt at solving a problem and see the results, it's way more likely to be successful in accomplishing the original task without needing a human in the loop.

Claude Code's ability to use `xcodebuild` was a game-changer for me, turning an imperfect model into a workhorse. For multi-file refactors, it could usually get the project building again after 1 or 2 attempts without needing to bother me for its predictable mistakes like misspelling a function name or using some older syntax or forgetting to update a file.

Giving Claude Code (a natively probabilistic tool) the ability to use the Swift compiler (a natively deterministic tool) provides the best of both worlds.

I've yet to find a clean way to have Claude Code iterate on UI the way humans do with the iOS simulator and SwiftUI Previews. Automating the App Store screenshots with UITests may have been the first step in accomplishing that (or at least that's one potential strategy).

The point is that connecting feedback loops for Claude – either on the input side or the output side – is remarkably powerful in leveling up the base model's capabilities to accomplish your task.

#### Be proactive in finding ways to serve documentation to Claude Code

Speaking of the input side, later on in my development I automated a way for Claude Code to look up documentation for the Swift Packages I used by moving my derived data directory to the project folder and pointing it to the checkouts/sources folder of each key dependency I use where it could find the `.docc` documentation bundle.

I added the following to the project source level CLAUDE.md:

```markdown
## Swift Package Dependencies

- **Nuke**
  - Advanced image loading and caching framework with powerful performance optimizations
  - [Documentation](DerivedData/Vinylogue/SourcePackages/checkouts/Nuke/Documentation/Nuke.docc/)
- **NukeUI** (part of Nuke)
  - SwiftUI components for declarative image loading with LazyImage and FetchImage
  - [Documentation](DerivedData/Vinylogue/SourcePackages/checkouts/Nuke/Documentation/NukeUI.docc/)
- **Sharing** (Point-Free)
  - Type-safe shared state management library for global app state persistence
  - [Documentation](DerivedData/Vinylogue/SourcePackages/checkouts/swift-sharing/Sources/Sharing/Documentation.docc/)
- **Dependencies** (Point-Free)
  - Dependency injection framework for testable and modular Swift applications
  - [Documentation](DerivedData/Vinylogue/SourcePackages/checkouts/swift-dependencies/Sources/Dependencies/Documentation.docc/)
  
## Code Architecture Reference

- Point-Free Co. SyncUps
    - https://uithub.com/pointfreeco/syncups?accept=text/html&maxTokens=50000&ext=swift
```

I'm still trying to find a clever way to give Claude Code native access to the latest Apple Frameworks documentation. One option is [llm.codes](https://steipete.me/posts/llm-codes-transform-developer-docs). I've also used the [Dia](https://www.diabrowser.com/) to automatically convert a loaded Apple docs page to markdown before copying it into the Claude Code prompt manually.

#### Periodically ask Claude Code for solicited code audits

Claude Code will not proactively audit your code through any particular lens. It's good to remember that you can ask it specifically to do a full walkthrough of your (small?) codebase looking for improvements. This could be a security audit, accessibility audit, code re-use audit, dynamic type audit, Swift concurrency audit, etc.

You can also ask it to do several audits in parallel through subagents. Or, have multiple subagents do the *same* audit type and have the main agent gather the results.

#### Periodically have Claude Code run `-warn-long-function-bodies` and fix warnings

While developing with Swift, for as long as I can remember, there have been cases where I unintentionally introduce a stray statement that strains the Swift compiler on each build and I only notice it a couple days later when it's too late.

Keeping the [-warn-long-function-bodies](https://github.com/fastred/Optimizing-Swift-Build-Times/blob/18f7052834d17040c66c848e28dcc9431c9d60fe/README.md#type-checking-of-functions-and-expressions) compiler flag on during development is one way to get notified about this early and often, but it can also be annoying due to the non-deterministic nature of build times.

It's quick and easy to ask Claude Code to add this build flag with ~200ms as the threshold, build the project, check for warnings, and automatically fix them. Then have it clean up and revert the build flag once it's done.

#### The bar for automating things is way lower with Claude Code

I consider it a personal failing, but I've always had an aversion to learning bash scripting. There's lots of different rules of thumb about when you as a developer should dedicate time to automating a manual process. For me, that rule was basically never. It always felt like too much a burden to not only write, but to maintain automation when it inevitably breaks.

With Claude Code, my outlook on automation has completely changed. LLMs in general are just way better at writing one-file scripts than they are at writing sprawling applications. It's simply much faster to ask Claude Code to bang off a script to automate a task. Even for one-off tasks.

The [script](https://github.com/twocentstudios/vinylogue/blob/906c1ce86c8bdb926db6dcb0eada664b80fb8743/generate-app-store-screenshots.zsh) Claude Code wrote to automate my App Store screenshots is just one example. I also had it write a one-off script to generate the graphs earlier in this blog post.

#### Continue using your existing developer tools alongside Claude Code

See how well Claude Code works with your existing developer tools and workflow before introducing anything new. 

I found keeping GitHub Desktop as my code review tool for Claude Code's various excursions worked great. I could keep an eye on the git staging area and selectively commit files the same way I do when I'm developing on my own.

I used Perplexity, Google search, and the ChatGPT app to do various research and context gathering outside of Claude Code. Each felt like it covered certain limitations of Claude Code, whether it be the model or the UI.

And of course, using Xcode for my own editing, building, browsing, testing, and simulator running workflows was familiar (and predictably painful).

I'd say keep an awareness of friction points in your workflow and gradually address them one-by-one. I had plenty of time and mental energy to think about my tooling while Claude Code was doing the grunt work of refactoring and pushing files around for me.

### The kinds of tasks I used Claude Code for

#### Scaffolding

- [bffa00c - "lastfm client and tests"](https://github.com/twocentstudios/vinylogue/commit/bffa00c)
- [88bbc1e - "onboarding and migration"](https://github.com/twocentstudios/vinylogue/commit/88bbc1e)

At the start of a new project or feature, you can use Claude Code as a way to get smarter scaffolding for a project. It's dangerous though if you think of this code as shippable code instead of scaffolding. You really do have to maintain the discipline to continue to build off of the generated code, test it, polish it, iterate on it.

More concretely, Claude Code seems to be pretty great at creating `Codable` models, especially if you give it an example json file. Networking clients too since there's presumably plenty of examples in its training data.

#### Targeted refactoring

- [2de5aa8 - "Refactor Album to UserChartAlbum"](https://github.com/twocentstudios/vinylogue/commit/2de5aa8)

One example of a targeted refactoring I did was at the very end of the project. I previously had an `Album` struct that was using lots of optionals to express different levels of `loaded`. 

I did my own bit of planning up front to devise exactly how I wanted `Album` to be structured to express being partially and fully loaded. Along the way, I realized that `Album` was also being mutated with some specialization based on `WeeklyChart` it was originally fetched with. So it wasn't really independent `Album` whose information could be shared across years. This could have been a source of subtle bugs, especially with caching.

I gave Claude Code that revised structure, now `UserChartAlbum`, and told it to refactor the codebase to use it. Of course, doing this kind of refactor is much safer with static typing and a compiler helping you out as a human, but Claude Code knocked this out in a couple minutes, also using the compiler to help itself.

#### Pushing code around

- [32aef1b - "don't pass whole model"](https://github.com/twocentstudios/vinylogue/commit/32aef1b)

Another type of refactoring is pushing variables and functions around between classes that sit at the boundaries of one another. Or extracting a class's method into a pure static func.

I used this kind of refactor a lot for extracting SwiftUI Views. Also for migrating `@State` vars from Views into `@Observable` classes. These are particularly error prone to do as a human because the Swift compiler completely gives up on providing useful error messages when you've misspelled something in a View body.

#### Deconstructing SwiftUI Views to satisfy the Swift compiler

- [809625f - "refactor WeeklyAlbumsView for compilation times"](https://github.com/twocentstudios/vinylogue/commit/809625f)

There's a natural tension when writing SwiftUI where *writing* Views is generally easier when working inside one big View. But this makes both the compiler and the runtime unhappy (performance suffers). When iterating on the presentation and structure of Views, it's disruptive to have to keep extracting variables and thinking up names for each sub View instance.

Claude Code is really great as a solution to this problem because both extracting and recombining Views is incredibly cheap.

#### Following architecture rules

- [2bf6da1 - "Migrate to point-free style"](https://github.com/twocentstudios/vinylogue/commit/2bf6da1)
- [bc3aa42 - "Migrate onboarding, settings, weekly albums, album detail"](https://github.com/twocentstudios/vinylogue/commit/bc3aa42)

After my big architecture refactor, I [created a set of rules](https://github.com/twocentstudios/vinylogue/blob/906c1ce86c8bdb926db6dcb0eada664b80fb8743/Vinylogue/Features/CLAUDE.md#store-creation-and-navigation-rules) in the `CLAUDE.md` file in the `Features` subdirectory that holds my SwiftUI Views and Stores (`Store` being an alias for `ViewModel` or `@Observable` class). For example, for sheet-based navigation:

```markdown
### Sheet-Based Navigation
**Pattern**: Parent stores create optional child stores for modal presentations

**Rules**:
1. **Parent Store**: Creates optional child store property (`var childStore: ChildStore?`)
2. **Parent Store**: Provides method to create child store (`func showChild() { childStore = ChildStore() }`)
3. **Parent View**: Uses `sheet(item: $store.childStore)` modifier
4. **Child View**: Accepts store as parameter (`@Bindable var store: ChildStore`)
5. **Child Store**: Must conform to `Identifiable` (class identity-based)
6. **Dependency Injection**: Use `withDependencies(from: self)` only if parent has `@Dependency` vars
```

Whenever Claude Code starts work on a new screen in the future, it will read these rules and examples in the `CLAUDE.md` and follow them when structuring the new screen.

#### Copying over styling

My environment isn't set up yet to give Claude Code all the tools it needs to properly iterate on a visual design. But after I created the exact visual design for a screen in SwiftUI, it had no problem copying over those design elements to other Views.

#### Removing a Secrets file in git history

When doing a folder structure refactoring near the end of the project, I moved the `Secrets.swift` file that has my Last.fm API key in plain text and forgot to update the hardcoded location in `.gitignore`, causing it to be committed deep in the history. I noticed this right before pushing to the public GitHub repo. I'd have to use git to extract it from the commit history.

I've done this kind of excavation before, but it's incredibly nerve-wracking and error prone. I asked Claude Code to help and it knocked it out.

Of course, there's a lesson to be learned here that I should be doing my secrets management better, and I did update the `.gitignore` to be more fool-proof, but regardless of that, it still saved me a lot of mental effort.

#### Full audits for reusable code

I asked Claude Code a few times to do full audits of my project to find and extract duplicate code, especially in SwiftUI Views. You can be as hands-on or hands-off as you'd like. For me, I specifically instructed it to consider whether the code was functionally duplicated or not, i.e. whether it was expected that each instance of the duplicate code should be able to evolve independently. So treating Claude Code as a static analysis tool with a little extra smarts.

I'd review its results in GitHub Desktop as usual and commit only the extractions that made sense to me.

#### Transliterating code between programming languages

- [f4d9402 - "use old color extraction algorithm"](https://github.com/twocentstudios/vinylogue/commit/f4d9402)

I used Claude Code to port my [dominant color algorithm](https://github.com/twocentstudios/vinylogue/blob/906c1ce86c8bdb926db6dcb0eada664b80fb8743/Vinylogue/Core/Infrastructure/ColorExtraction.swift) from Objective-C to Swift line-by-line.

It's only a couple hundred lines, but it would have been tedious and not particularly fun to do this by hand.

#### Error message writing and mapping

Claude Code wrote a lot of decent error handling code out of the box. Of course, error handling code, both internal and user facing, deserves proper consideration. But having a scaffolding in place made it easier to iterate in the right direction.

#### Organizing images in a GitHub release

I like documenting my GitHub PRs, Issues, Releases, etc. with screenshots laid out in tables. I've done this manually for years, and I've never figured out a way to automate it.

When creating [Releases](https://github.com/twocentstudios/vinylogue/releases), I realized Claude Code was very much able to pick the proper screenshots out of my project directory, upload them, and insert links into a properly formatted markdown table. This saved me 10-15 minutes at least of tedious clicking, dragging around, and formatting.

### What I want to try next time

- I want to give Claude Code a way to view simulator screenshots and/or video to allow it to iterate on its designs.
- Or at least experiment with UITests or snapshot tests.
- I want to get give Claude Code scripts to run for `xcodebuild`, etc. so it's more consistent and wastes less time when it forgets which simulators are available. The only downside is keeping these up to date when I update Xcode versions.
- I want to be more mindful of the the way it writes unit tests and come up with my own best practices, including which types of files I test.
- I want to try some version of TDD.
- I want to ask Claude Code to update some sort of append-only log each time it takes a wrong path and corrects its own mistake. Automating the collection of tips and tricks and ensuring we can incorporate those into long-term memory.
- I want to automate more App Store release process steps.
- I want to move my personal workflow stuff to my home directory `CLAUDE.md`.
- I want to find more useful MCPs for iOS dev.
- I want to find a better way to manage files that aren't in the xcodeproj e.g. markdown, images, etc.
- I want to find a source for up-to-date Apple platform docs that can be quickly referenced within Claude Code.

### Stray observations about working with Claude Code

- I didn't have CLAUDE.md file at first and didn't understand context limit, clearing, or compacting.
- Pre-planning with a product requirements document didn't really feel like it helped much. I'm pretty sure there's a skill to this too and I'll need to start up a lot of greenfield projects or features to learn what works.
- For the first day or two, I intentionally didn't make any code changes or give code-level guidance so I could see what Claude Code's tendencies were. For my own learning, I think this was useful so that I only give it specific instructions about the things I disagree with the base model on.
- To that end, my impression of Claude Sonnet 4 is that by default it writes iOS 16 style code.
- I added `xcodegen` very early because editing `xcodeproj` directly is error-prone and overall a nightmare.
- I used `swiftformat` with my longstanding config file. Using a linting/formatting tool means you don't need to fill up the context with notes about code style.
- However, Claude Code would sometimes trip up when applying diffs because after running swiftformat, the code structure in its context history would no longer match what was properly formatted in the file.
- My flow was to review Claude Code's changes in GitHub Desktop, sometimes make my own changes in Xcode, stage files and write commit messages myself. I liked this flow because it enforced some discipline about me being the one responsible for the code I was committing.
- Out of the box, Claude Code wrote tons of tests. I mostly ignored these but my impression was that most of them were flawed and useless.
- Claude Code also tried to write UITests while it was still in the scaffolding phase and the UI was very far from being pixel perfect. I had to shut it down and ensure it never wrote UITests again via `CLAUDE.md`.
- Claude Code did pretty well in building the project and fixing its own issues. To me, this is where Claude Code leapfrogs standard chat LLM interfaces in usefulness.
- Claude Code knew how to use `xcodebuild` out of the box. But it was very inconsistent on which build flags, simulators, OS versions, etc. it picked.
- I slowly added to the project directory CLAUDE.md, mostly very targeted statements about the development flow and not much about the project contents.
- The Pro plan's usage limit resets every 5 hours. During scaffolding I ran into this limit after about 60-90 minutes of usage. Later on, I'd run into the limit towards the end of the usage period or never.
- The Pro plan only allows usage of Sonnet, so I have not experimented with Opus yet.
- With its initial multi-sprint plan in place, Claude Code knocked out a functional prototype in about 3-4 hours of total compute time on the first day. This was mostly unguided work; I did not contribute much yet.
- I never gave Claude Code direct access to the iOS simulator. Therefore it was only indirectly useful for visual design work.
- Claude Code really wanted to implement dark mode, Dynamic Type, and full accessibility support.
- I enjoyed doing the visual design work so I took responsibility for that part of the work.
- After I did the visual design work for one screen, Claude Code did a decent job getting the other screens to 90-95% complete.
- My ambitions grew a lot over the first couple days working on the project as I became more familiar with Claude Code's capabilities.
- It was almost overwhelming at times to decide what I wanted to do next.
- I intentionally didn't attempt to have Claude Code work on different features in parallel. I was still in-the-loop enough that my manual testing was the blocker, and having multiple instances to review in my environment would have quickly overwhelmed me. As I gain experience, I think my appetite for parallelizing will grow. Also, I think parallel usage would probably necessitate the usage limits of the Max plan.
- After a couple days, I started using `/compact` more intentionally, and with additional instructions so that I was more in control.
- Towards the end of development, tasks were mostly unrelated, so I was using `/clear` more often than `/compact`. Especially because my collection of `CLAUDE.md` files was much more robust.
- As I started using more frameworks and becoming more opinionated about the code quality, I started looking for more efficient ways to feed context into Claude Code. I tried [uithub](https://uithub.com), [gitingest](https://gitingest.com/), [context7](https://context7.com/). But context is still so precious that a lot of the time I'd do my own work up front to find the exact markdown file I wanted it to read to understand how the library would solve the current problem we were working on.
- Moving Xcode's DerivedData folder into the project directory is a weighty decision with pros and cons, but it certainly helped for giving Claude Code a easily discoverable location for Swift Package documentation and code.
- Refactoring is one of my favorite use cases for Claude Code. Being able to concretely see what a project-wide refactor looks like in a matter of minutes is incredible as a learning device. For example, if I manually did a big exploratory refactor related to an architecture change and it took a week of work, I'd be much more opposed to throwing away that work, even if it objectively made the codebase worse. Having Claude Code automate that work allows you to keep your objectivity, evaluate the new strategy as an impartial observer, and ruthlessly throw out the work with no hard feelings.
- Relatedly, the ability to stay at the macro-level of evaluating a codebase for 90% of the time while Claude Code handles the micro-level work feels like such a huge productively multiplier.
- I was naive at first thinking that Claude Code one-shotted the implementation of the legacy data migrator component. Even spot-checking this code during the refactoring phase would have at least put this work higher on my TODO list.
- Having a deep catalog of structurally pure, well-documented, and focused open source code to provide as template or reference code to Claude Code will be a huge multiplier going forward.
- I haven't tried using `ultrathink` or other thinking modifiers in my prompts yet.
- I found it useful to have Claude Code's scaffolding in place after the first day and iterate from there, especially since I didn't start out with a target architecture in mind. But there's a fine line; you can quickly find yourself drowning in slop before you get it under control.
- I didn't use the `--dangerously-skip-permissions` mode. Most CLI tools I simply approved for the session as they were proposed since most are safe by nature (`find`, `grep`, `xcodebuild`, etc.).
- I found it easier to do research using Perplexity or OpenAI o3 for particular tasks rather than mix this kind of work up with the Claude Code context. It was much more efficient to find the exact blog post or API with these GUI tools and then feed Claude Code the exact URL. The right tool for the right job.
- Claude Code is so adept at using CLI commands that I didn't regularly end up using many MCPs. I imagine I will start to use more in the future as the ecosystem matures.
- At some point I had Claude Code audit the entire project and delete all of its useless comments. Now that I know its penchant for over-documenting (at least to my tastes), I can try to devise a succinct rule regarding inline docs to add to `CLAUDE.md`.

