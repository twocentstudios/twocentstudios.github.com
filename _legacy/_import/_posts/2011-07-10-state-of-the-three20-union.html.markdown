--- 
layout: post
title: State of the Three20 Union
tags: 
- Commentary
- iOS
- Three20
status: publish
type: post
published: true
meta: 
  _edit_last: "1"
  sfw_comment_form_password: C53lbKypWsCf
---
I've been sitting on this topic for a little while now, and feel like I should finally weigh in on where the Three20 framework is at this point.
<h2>Where I Started</h2>
I started working with Three20 a little over a year ago. In that time, a lot of really talented people have improved the library to the point where it is today. They have done great work that all of us have benefitted from greatly. Recently, I got comfortable enough with the library to start filling in holes in the documentation using this blog.

But I think everyone in the community has started to feel the weight of Three20. I think the three main reasons for this are documentation, architecture, and community. All of which seem to be making each other worse as time goes on.
<h2>Documentation</h2>
Three20 has gotten continuous flak on Twitter, blogs, and anywhere else iOS devs talk for the lack of documentation. There's really no argument against that. Everyone acknowledges it.

A lot of people have gone out of their way to help with tutorials and blog posts that usually get a sliver of functionality across. But a lot of them are intermediate or advanced and assume you know about dependencies and other Three20 magic. And there's no nice neat repository for all of them. And a lot of them are out of date.

The startup docs written by Jeff are great for just that: getting started. This gives beginners a taste of what Three20 can do for them and completely leaves them out to dry once they try their first customization. So they look at the documentation and find nothing. Then they look at the source and find nothing. Then they search blogs and find a bunch of old stuff. Then they get pissed off after a number of hours or days and give up and post angry comments to Twitter.

With the mass of source that Three20 has, I can't blame them. It's tough to know where to start, especially if you want to use a large portion of the library. And this is definitely not something that can be explained in a short bit of source documentation. It's much better suited to an Apple "programming guide" type document. This just doesn't exist because I truly believe there aren't that many people that know the library inside and out. And those that do exist are busy fixing the plethora of issues and pull requests.
<h2>Architecture</h2>
The modularity that Jeff introduced sometime last year was heavily called for and a step in the right direction in theory. But I think the problem is that Three20 was originally written as a cohesive app, and you basically had to add all seven or so components anyway in order to get the thing to build (I always included the full library because I usually use all of it, so don't quote me on that).

There used to be a chart that had "The Three20 Ecosystem" showing how all the table stuff worked together. I still believe the concept behind the Three20 table structures has plenty of merit over Apple's. But you can definitely tell that the architecture is such that it works for the Facebook app, but not much else without a lot of rewriting, which almost defeats the purpose of having reusable library components.

Three20 has a lot of independent goodies and additions that don't have much to do with the architecture. But most of the components require you to do things The Three20 Way. And if you're going to use Three20 the way it was intended, you should probably be writing an app that has similar layout.

Three20 is best for making apps for web services that have assets in databases. I'm not sure how else to describe this, but maybe API-centered app is the best description. Think of Facebook then set your bounds somewhere outside of that. Most all your data used in the app should come from the cloud. The webservice should have a well-documented API. It should be heavily URL based.

This is because Three20's URL system does not do well with passing around data. Sure, it can do it. But it's not designed for it. You'll be fighting the whole way, especially with tablecells. Each view controller should have a corresponding URL on your webservice for best compatibility.

This post isn't about when you should use Three20 so I'll cut that example short. Needless to say, those new to Three20 don't know if they should or shouldn't be using it because there's no documentation because there are so few people that understand the library and we're back to the chicken and egg problem.
<h2>Community</h2>
I have to be frank with this one. There are plenty of great people in the Three20 community so I don't want to give the wrong impression that I know all the players and I can pass judgement freely. But from what I see, there's an increasing number of weight that is being added to the community due to many of the problems mentioned above.

Let me start with a fictional iOS developer. He's been developing using standard libraries for a year or so and has the basics of Objective-C, Foundation, and UIKit down. He hears something about a library from the Facebook developers, checks out the github page, sees some examples, and says, "Wow, this is awesome. This will save me a ton of time writing my own networking classes and photo rendering classes and all that other stuff that I need right now but don't have time to dig into the Apple frameworks to perfect." In one word, they get greedy.

This is perfectly normal. Perfectly acceptable too. This is exactly what I thought when I first saw the framework. After all, the whole point of a framework is having a black box to use where you need it without having to have thousands of developers write the same code. Spending more time on your app-specific business logic and app aesthetic is the siren song of most developers.

But whereas some developers give up and curse Three20 after not finding any documentation, there are also two other groups.

Group 1 digs even harder for documentation. They find and read every blog post, step through the source of every provided example, and even <em>read the source until they understand it</em>. Obviously this takes a long time, and thus the group is small.

Group 2 immediately pounds Stack Overflow and the Three20 forum with questions. They don't hesitate to file issues on github for anything and everything they don't understand and assume is a bug. A lot of the time, they really didn't understand the standard UIKit way in the first place, and are more or less spinning their tires and flinging mud in everyone else's faces.

Group 2 exists in every community, but they usually are indistinguishable because plenty of books and guides exist for all three groups to use. The main contributors are there to answer the really tough questions, but they mainly get to work on fixing mission-critical bugs and writing new features/components. So again, we come back to a lack of documentation making a different problem worse.
<h2>Where To Go From Here</h2>
Again, I am not trying to demean any of the hard work all the Three20 contributors have done, especially Joe's original idea and Jeff's great curation. My main question is this... <strong>is the Three20 framework salvageable?</strong>

From where I sit right now, I don't believe it is.

I think those moderately familiar with the library understand that there are a lot of inherent flaws baked into the framework. Hindsight has made those flaws easily visible, but still not extractable from the framework. It's a cliche to say that programmers love to rewrite their projects, but in this case I'd like to think we're rewriting this time from higher ground.

I know I'm not the only one that feels this way. Jeff's new <a href="https://github.com/jverkoey/nimbus" target="_blank">Nimbus</a> project seems to be the answer to many the above complaints. Documentation is the number one priority of the project, and so far Jeff is doing great out of the gate. Many of the best parts of Three20 will be ported over, but foreseeably with all the changes that have come from Jeff's hindsight of the project.

What do I mean by not salvageable? I think that more time should be spent rewriting Three20 as Nimbus than should be spent fixing the multitude of Three20 bugs that exist. That being said, I should probably put my money where my mouth is and help with some of that workload.

I hate to see Three20 collapse under its own weight seeing as how much great work has been put into it. The rapid iteration of the iOS frameworks requires even more rapid iteration of community-driven frameworks to keep up. I think the best way for Three20 to keep up is to gradually migrate to its new form. This will also give us a chance to reevaluate the need for some of the Three20 functionality that was written to cover up holes in previous iOS versions that have since been filled by Apple. It will also give a chance to incorporate other open source projects that have become well known and stable since Three20 was originally started.

This post was not meant to be an attack on the community, and I'm definitely not trying to be a Negative Nancy. I'd simply like to document my opinion on the source and exacerbation of Three20's problems so that hopefully the same mistakes can be avoided in the future.
