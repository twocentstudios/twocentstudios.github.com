---
layout: post
title: Fall 2015 Project Wrap Up
date: 2015-10-30 13:30:51
---

I've been back in Chicago left to my own devices for the past two months now. I'll be shipping out to Japan in a few weeks for a three month stint doing more of the same. I've had plenty of time to dig into a few various development areas I've wanted to explore. This is a quick wrap up of what I've been up to.

## Music Transfer

I own a [Synology DS414j](https://www.synology.com/en-us/products/DS414j) network attached storage device that's helped me organize and archive all of my personal data including mp3s, FLAC, music recording files, photos, videos, etc. I'm stuck in a weird position of wanting to take a subset of my mp3 collection on the road with me, while also wanting to add to the collection and have everything available to me. I'm still holding out from participating in streaming services since they don't always carry some of the smaller indie artists that release on Bandcamp and the like. This left me with a weird problem to solve and a lot of time to do it.

My first shot at this was writing a shell script to rsync a selection of my music from my NAS to a cache on my laptop and still use iTunes to sync from laptop to iPhone. It's a pretty simple script, but gave me a chance to dive into bash scripting, something I had previously avoided like the plague.

```sh
#!/bin/bash
set -e

src_music_root='/Volumes/music'
dest_music_root='/Users/ctrott/Music/Cache'
folder_list_path='/Users/ctrott/Code/temp/music_transfer/artists.txt'
log_path='/Users/ctrott/Code/temp/music_transfer/log.txt'

while read folder ; do
    echo "$music_root/$folder"
    rsync -av "$src_music_root/$folder" $dest_music_root >> $log_path
done < $folder_list_path
```

I'm still having a hard time getting my head around the seemly first-class path support. I'm used to having distinct types for `NSURL` vs `NSString`. Trying to concatenate paths from inputs and variables and literals has led to a lot of confusion. The combination of that confusion and the destructive nature of file system mutations leaves me wanting to use something like Rake or raw Ruby instead.

To that end, I did run through the [Command Line Crash Course](http://cli.learncodethehardway.org/book/) from the Learn Code The Hard Way series to pick up a few techniques I didn't know from before. I don't think I retained enough of it, so I might have to breeze through it again soon.

## GraphQL / React / React Native

I remember hearing about GraphQL at the Facebook Developer Conference last Spring and then seeing the announcement over the Summer. I read through the spec and it looked very thorough. I'm interested in a lot of the new infrastructure concepts and frameworks that Facebook has been developing over the past years (React, React-Native, Flux, GraphQL, etc.). So when I saw an interactive tutorial called [Learn GraphQL](https://learngraphql.com/) I decided to work through it.

I really enjoyed the tutorial and found it to be a nice intro to the capabilities. Unfortunately, I'm still finding the web world a bit opaque and hard to keep up with. I've never been particularly enthralled with js, so although I'm enthusiastic about the architecture concepts, I keep hitting stumbling blocks with the ever-changing ES5/ES6/ES7 syntaxes and toolchains that are required to even get started. Not to mention that these technologies are still rapidly evolving.

I also spent a few days looking at docs and walkthroughs for React and ReactNative. Again, the underlying concepts (immutability, one-way data flow, coalescing state) of those frameworks are like a siren song to me. The progress that's been made on those frameworks is very respectable. I'd like to dive in and give React and/or React Native a shot, but it's an opportunity cost cost-benefit analysis of whether I should be working on learning raw Swift and whether I can find a project that works well within React Native's limitations.

## Apple TV

For some reason, I was one of the developers chosen to receive a $1 Apple TV after it was announced at the September Apple event. I used an older Apple TV at the Timehop offices quite often and found the UI and UX to be quite a joy to use, so I was especially interested in what sort of apps I'd be able to make.

I received my Apple TV in the mail a week later, spent an hour or two downloading binaries and getting it set up, then another couple hours downloading Xcode betas and reading docs. I realized in dismay that I was on the vanguard since all my normal dependencies and dependency managers were unable to deal with a new platform right away.

## Constellations

One morning I stumbled across [rocket.chat](https://rocket.chat/), and noticed it had a pretty cool background effect of little particles drifting in space and connecting with a line when they got close enough.

> After I finished implementing it, I found that they used the open source [particle.js](https://github.com/VincentGarreau/particles.js/) for the effect.

I started working on a Swift and SpriteKit implementation for the Apple TV - a trifecta of things I hadn't worked with before.

Here's a quick demo of the "final" result

{% caption_img /images/constellations.gif a low-quality demo of constellations %}

I took about two days to get a demo going. It was slow going looking up documentation alternately on SpriteKit and Swift, but I felt proud to see the stars bouncing around the screen.

I ran into two problems, one of which I was able to fix.

The first problem was that I was rendering stars using `SKShapeNode()` with a circular path. I could only get something like 20fps with 30 stars - not nearly enough to fill the screen. A little googling suggested that `SKShapeNode()` is extremely performance adverse and causes constant rerendering. I changed my stars to use square `SKSpriteNode()`s instead, and the performance issues were more or less resolved.

The second problem was that using small stars confuses the physics engine when they bounce off the walls at low angles on incidence due to floating point rounding errors. This causes the stars to stick to the walls on contact and congregate in corners. Unfortunately, this seems to be a known issue with SpriteKit (amongst other game engines).

After I discovered the source to particles.js, I noticed that particles are allowed to leave the screen bounds and are recreated with a different location and direction. If I decided to release this, I'd probably implement it without using physics.

Since this project was just for fun and doesn't have much value outside maybe a screensaver, I decided not to bother releasing it.

## TinyKittens TV

I got in the habit of having animal livestreams on in the background while I wrote code all day at Timehop. I mostly watched the livestream from [TinyKittens](http://tinykittens.com), a non-profit society which rescues and fosters pregnant cats and their kittens before offering them up for adoption. I thought it'd be convenient to have an Apple TV app for selecting between the streams and viewing them.

I started digging and found the livestream.com API supported the two endpoints I needed and provided a streaming URL compatible with Apple devices.

With that, I got to work on another app for Apple TV. I first explored writing the app as a TVML app mostly assembled server-side, but was immediately frustrated trying to wrangle XML without a lot of background knowledge of how to do. There were too many possible languages and frameworks and implementations I could have used on the server side, and I realized I would rather learn more Swift and UIKit than I would writing a custom server backend that did the majority of the heavy lifting.

The dependency chain was still troublesome (and a moving target), so although I wanted to dive into ReactiveCocoa v4, I decided I should start with a quick and dirty version in Swift with no dependencies at all.

The first version was a massive view controller that did all the fetching and JSON parsing in line. It was also pretty ugly.

{% caption_img /images/tinykittenstv-01.png v0 of TinyKittens TV %}

I used the app for a few days and enjoyed it. The code was so ugly though, and I wanted to use more of Swift's language features and see what it was like to try to architect an app without the ReactiveCocoa conveniences I was used to. It was a good experience in that it made me appreciate reactive programming that much more.

It took about as long to refactor the app as it did to write V0. I added the Gloss JSON parsing library after getting CocoaPods set up (with Orta's `cocoapods-expert-difficulty` gem). I wrote my own simple `Result` type, wrapped a `throws` function (I really dislike Swift 2.0's `throws` syntax), set up some struct models, parsed some JSON, wrote a view model protocol, refactored the interface design to mirror Apple's focus support (with some really ugly frame layout code), added image assets (including a fun parallax icon), did some testing, and packaged it up for the App Store.

I got a rejection for an error message not being forthright enough, but I fixed that and resubmitted and was accepted in no time. It sounded like a lot of other developers had a hard time with this initial submission process. I'm sure Apple was being extra picky with the public release.

The app is pretty simple and I was tempted to add lots more bells and whistles, but I knew that I'd rather ship the V1 at launch than to sit on it while I toiled away with garnishes.

On a side note, I meant to use storyboards for the interface this time, but I got frustrated with them again and bailed. Someday...

The Apple TV launches today. The App Store right now only has a front page and a search page and links don't work, so discoverability isn't really that great yet. Hopefully I get a few downloads though.

It was a fun project overall. It's definitely useful to me. And it was great for getting up to speed with Swift without getting bogged down in a large project. I've posted the [source](https://github.com/twocentstudios/tinykittenstv) on Github. Below is a screenshot of V1.

{% caption_img /images/tinykittenstv-02.png V1 of TinyKittens TV released to the App Store %}

## Function Programming EdX FP101

ReactiveCocoa was sort of my gateway into functional programming. I've tried to dive into Haskell a few times over the last year, but always got tripped up before I could implement anything of consequence.

I saw that Erik Meijer's [EdX course](https://www.edx.org/course/introduction-functional-programming-delftx-fp101x-0) on functional programming was starting soon, so I decided to sign up and take a few hours out of every week to learn Haskell. I've done two weeks so far and am feeling good about it so far.

## Blog Migration

I spent a couple days migrating from Octopress to Jekyll. See [this post](/2015/10/27/site-makeover-and-jekyll-cheatsheet) for the details.

## Songwriting App

My friend Sarah and I are both musicians who write music. We've been kicking around the idea for over a year now of an app to assist songwriters in organizing demos and lyric sheets better than the Voice Recorder app.

I went back through some early designs I did in Sketch and made a few adjustments after Sarah and I had the chance to do some brainstorming a few weeks back. Once we agree on the design direction, I'm looking forward to getting started on the project.

{% caption_img /images/songwritingapp-01.png Some rough Sketch mockups of an app for songwriteres %}

## Wrap Up Wrap Up

It's been tough to find the right balance of time spent just exploring what's out there and spending time diving deep into a project. It definitely feels a bit like a waste when you look up and realize you've spent half a day just looking at the documentation for some obscure programming language, and then spent the other half of the day trying to get your environment set up just to run a demo for a framework you'll never use again. But I'm trying to use this time to keep an open mind about these experiences. There is some serendipity involved when trying to find your next big thing.
