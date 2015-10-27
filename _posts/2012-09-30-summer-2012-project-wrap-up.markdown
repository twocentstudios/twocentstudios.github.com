---
layout: post
title: Summer 2012 Project Wrap Up
date: 2012-09-30 07:08
comments: true
categories: wrap-up
redirect_from: "/blog/2012/09/30/summer-2012-project-wrap-up"
---

A lot has happened since my last quarterly project wrap-up. I've done a lot of little projects here and there, abandoned a few, and dreamed up a bunch more that I can't wait to start on. Here's a summary of the smaller things that might not have gotten their own posts over the last couple months.

## To-be-titled Music App

Early in the summer, I decided to start seriously working on the music app I've been talking about since last Winter. It went through several iterations of what format it should be and what the scope of it should be. I coded up a quick Rails app to see the basic concept in a couple days, but left it untouched for a while because at the time it didn't seem like the browser was the right primary format for it.

After spending a few more weeks rethinking the purpose of the app, it seemed possible to strip the app down to its core and do an iPad/iPhone only release. Initially everything was going to be local to the user's device. Then, of course, the scope started to expand, and eventually I found myself and what I considered to be a happy medium of still having a core iOS UI, hosting backend data with Parse, and leveraging existing social media sharing.

In prep for the iOS app, I circled back to a new iOS library from Github called [Reactive Cocoa](https://github.com/github/ReactiveCocoa). I spent a number of days just wrapping my head around the concept and example code, and finally felt confident enough to start diving in myself.

I spent a few consecutive weekends with my Graphic Designer friend CJ doing wire framing, prioritizing features, learning some more about the Parse framework, and starting on some prototypes of the backend. We even spent a full day going through vocabulary related to our concept to come up with a good name and good terminology within the app to best describe what the user would be doing.

At a certain point though, a few things converged and the project sort of sputtered out. CJ and I seemed to have more divergent ideas about what the core purpose of the app was, which was sort of a wakeup call that maybe it would be best to do more of that up-front work of surveying users and seeing if we actually have any interest in what the concept is.

And so the project is currently on hold. I don't plan on giving up on it. The plan now is to build a few smaller projects before starting up again in order to be able to leverage that experience. Rails has proven to be a much quicker platform to prototype on, and thus my first steps will be to build out a shell that I can start soliciting user feedback from.

## TestPlanIt

One of the first big Rails undertakings I started almost a year ago was an app targeted at a specific data management task I wanted to solve for a friend of mine at my day job. He is a Test Engineer, which basically means receiving physical samples and a test plan, performing the test, acquiring data, writing a test report, and distributing it.

My initial cobbled together solution to this problem involved a SharePoint list with a few basic bells and whistles. I always imagined a much better system with full database representation of all the elements he works with, and thus started wire framing a Rails app that could accomplish this on my nights and weekends.

It turned out that my vision was a little bit too complex to accomplish with my early Rails knowledge. A lot of it had to do with my Javascript deficiencies. And after a ton of work, eventually the project sort of died under the weight of its own complexity.

Fast-forward now to early summer. My Test Engineer friend brought up his data organization and workflow problems, and I started to think about the problem again. I revised my initial data model to reduce the complexity in a way that didn't decrease functionality much, and basically started over again. I had dabbled in a few other projects since then and my familiarity with Rails-related technologies had given me enough skill to be able to power through the roadblocks that had hindered me the last time around. I reused some of my haml and some model code which saved time with the tedious aspects. 

In what I think was less than a few weeks, I had already gotten the core of the app working well beyond what I used to have. I was already adding embellishments (PDF export support, amongst others), but realized that there was still a great deal of work left to do making the app enterprise-ready (roles & permissions, deployment). It was at this point that we started working on implementing our new Product Lifecycle/Data Management application (see [this post](http://twocentstudios.com/blog/2012/05/27/flexible-parts-a-part-attributing-prototype-project/)). I realized that my app would probably never be used in production, and therefore stopped actively working on it. I took it as a learning experience and used that knowledge to build more apps like Flexible Parts.

## myGengo API Wrapper

I [wrote about this](http://twocentstudios.com/blog/2012/06/18/objective-c-api-wrapper-for-mygengo/) in detail, but the overall summary is that I missed Objective-C and wanted to do a little weekend project.

Looking back, I don't think I did myself as much of a service as I should have with this project. I took shortcuts that I shouldn't have because deep down I knew that I probably wouldn't be using what I had written at all. Kind of another learning experience in choosing personal/open-source projects.

## EngSurvey

My Test Engineer friend from work came to me with another request. He also needed an automatic survey system for his test reports. For ISO certification, you need to have some sort of feedback system from your clients (the Engineers that need their samples tested) about your reports.

I found an almost framework-scale gem called [Surveyor](https://github.com/NUBIC/surveyor) which got me almost 80% of the way there. The last 20% is always the hardest. My friend wasn't great at giving me requirements, I saw a lot of headaches ahead in deploying it internally, and the project wasn't high on either of our priority lists, so this project died out as well.

## Codecademy

I had read a lot about Codecademy since their New Years push. A non-programming friend of mine had been doing the full course for a few months, so I decided to check out the jQuery course. I finished about half the lessons which helped ready me for the AJAX part of my next few projects.

## HaveRead

I got a request from another co-worker to find a solution to a problem she had. Her one requirement was that she needed a way to send off a document to a dozen or so people and simply collect responses of when they had read the document. I explained the voting feature of Outlook mail, but she didn't seem to think that would be simple enough.

She needed it urgently of course. I threw together a Rails project to do this in about two half-days of work (naming them is always the hardest part). In the process I learned a little more simple AJAX and using the CarrierWave gem, which would help me in an adjacent project I was working on.

I showed her what I had, and although she was impressed, she said the limitation I have of running it off my laptop wouldn't work out in the short term. But that she would consider using it in the future.

I wasn't too bothered because it was a quick project and I learned a lot doing it. It was getting a little tiresome though that deployment was becoming a problem. Heroku or other cloud services weren't an option because they were outside the company firewall. And getting my own VM in the company was blocked by too much red tape since I wasn't part of the IT department. For the time being, the only way to deploy at work was to run the dev server on my machine and send links to my (non-static) IP, which is the technique I used in my next project.

## SolidWorks Model Challenge Friday

Part of my (new) day job was administrating [SolidWorks](http://www.solidworks.com/) for our couple dozen Mechanical Engineers. We have a bunch of younger Engineers that still love a good modeling challenge, and from a seed of an idea sprang "Model Challenge Friday". We'd spend half an hour on Friday morning designing/modeling various objects. The goal was speed and creativity, and to give the Engineers a sandbox to experiment with new techniques that they might not be comfortable with doing on real mission-critical projects.

In a lot of ways, it was inspired by the kind of projects I mentioned above. Stuff I never intended to launch and support, but instead used to experiment with new gems or techniques without having to get bogged down in details irrelevant to that goal.

I tried to participate in the first two weeks, but realized quickly that I could barely model a cylinder in an hour. I spent the next two weeks giving myself a crash course in 3D modeling with some help from my fellow Engineers. Before long, I was modeling up my own chair designs and actually participating in the contests. After a few more Fridays, I was to the point where other judges couldn't tell which design was mine (because they used to be so simplistic and bad).

The judging was initially done by passing some unmarked printouts around the office area for an informal poll of the fan favorite design. This process was just begging to be web-appified though.

The next few weeks I spent several nights and weekend days working on my next Rails app to facilitate this process.

My design goals were the following.
* Engineers would have user accounts.
* Registered users could submit screenshots of their designs each week to the contest.
* Voters would be able to vote without logging in, but they should only be able to vote once per contest.
* Entries would not show the creator's name until the contest was over.
* When the contest was declared over, the votes would be automatically tallied and a winner declared.

This required a good combination of normal CRUD layouts, AJAX for voting, CarrierWave for image uploads, Bootstrap for a basic design, cookies to store voting status, and of course running my ad-hoc "production server" on my laptop.

After informally launching one Friday as sort of test, things went over really well. The system worked almost flawlessly (except for a few unscrupulous Engineers voting for themselves by not logging in). I realized quickly that I had compromised my dev server by using it to store real production data and thus had a bit of a problem on my hands working on improvements without breaking stuff.

We used my new creation for a few weeks. It worked well. I made some improvements to the entry browsing using the Bootstrap js components and digging around for other good js plugins. Eventually though, the contest itself died out when suddenly we all seemed to get too busy for that half hour.

## AppleCart

I've talked about AppleCart in detail [here](http://twocentstudios.com/blog/2012/09/18/applecart-my-first-production-rails-app/), but the long and short of it is that the app has been a big success so far in raising money for the American Cancer Society and keeping things organized in the drive.

## What's Next?

I've started transitioning out of my day job role and into a more freelance/consulting lifestyle. I plan on doing this for a little while to increase my skill level and be able to tackle more theoretical and practical programming problems faster than I would by doing so only on nights and weekends. Time and energy have always been an issue, and especially with a lengthy commute, it just makes more sense to go all-in and laser focus on what I really want to do for the rest of my life.

Some of the programming related things I'm planning on doing with my time this Fall:
* Tackle a bunch of small projects I've wanted to explore on iOS and Rails.
* Really dig into RSpec and TDD.
* Finish some programming books I've started, and few more I haven't opened yet.
* Start contributing to an open source project.
* Immerse myself in the code bases of a few well-known projects to learn more about architecture and best-practices.
* Begin learning a functional programming language.
* Keep exploring the elements of traditional graphic design.
* Do a project with a NoSQL database.
* Go to a start-up event in Chicago.
* Watch at least one conference talk a week on YouTube.
* Organize my browser bookmarks.

I don't know where the priorities will end up being for each of those, but here's to a healthy and productive Fall.