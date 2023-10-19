---
layout: post
title: "Cookpad: A Retrospective"
date: 2023-10-18 22:25:00
---

It's been almost 5 years since my last series of posts, and 8 since [Timehop: A Retrospective](/2015/11/03/timehop-a-retrospective/). As my last day as an iOS engineer at Cookpad was June 30th, 2023, it's time to start another chapter of this blog.

While I only published publicly twice on the Cookpad developer blog ([Working with AWS AppSync on iOS](https://techlife.cookpad.com/entry/2019/06/14/160000) and [Path Drawing in SwiftUI](https://techlife.cookpad.com/entry/2023/06/21/162523)), on our company internal blog I wrote nearly 90 posts, including tutorial videos and recorded presentations. At the time I knew I'd regret publishing internally only, but the ease of writing for a known audience was too hard to break from.

In my next phase, I'll be making up for lost time. However, for the moment, I'll try to recap the last ~6 years at Cookpad.

## Overview

I worked in some capacity in 7 departments at Cookpad over my tenure, mostly as an iOS engineer, but also in and around AR, IoT, hardware, and ML. From my perspective, management at Cookpad was always encouraging of inter-company movement of engineers, even at smaller scales like 2-3 months ("study abroad"). I certainly appreciated these opportunities.

For context, I worked for Cookpad remotely from Chicago for Cookpad Japan for 6 months starting in April 2017. I moved to Japan in October 2017 and have lived here since.

## Cookpad Global

I started off on the [Cookpad Global](https://apps.apple.com/gb/app/cookpad-find-share-recipes/id585332633) team.

On Global I learned of the complexities of supporting a fully internationalized app, especially in the era where Apple's support for things like right-to-left languages was still primitive. I learned how intentional distributed work must be while working with groups in the UK and Japan from both Chicago and Japan. I re-learned that premature scaling (choose your preferred definition of "premature" and "scaling") is perhaps the most irrecoverable mistake startups can make. I continued to refine and put into practice my ideas about unidirectional architecture, immutable view models, and the tradeoffs of functional reactive systems.

It was a unique team where I worked closely with teammates from dozens of nationalities and cultures.

My three biggest (non-solo) projects were:

- Converting our app's navigation layer to use the nascent coordinator pattern.
- Rewriting our recipe editor.
- Rewriting our login module to support region switching, new OAuth services, and Apple's new Safari APIs specifically for login.

## Studio Satellite

Next was [Cookpad Studio Satellite](https://apps.apple.com/us/app/cookpad-studio/id1464118207), a startup project within the Cookpad TV organization with a team of around 5. Our goal was to make an app where any cook could easily shoot and edit their own quick-cut recipe video from their iPhone. In later stages pre-launch, we even bolted on a social network that included all the mainstays: a feed, likes, comments, profiles, etc.

{% caption_img /images/cookpad-studio-satellite.jpg h400 Video editor timeline of a pre-release version of Cookpad Studio Satellite %}

On this project I learned that I love prototyping, working on zero-to-one ideas, working with small teams, and having input (whether true or imagined) into the full product development process. I learned that there will always be stakeholders and that check will always come due.

I learned that sometimes your first users aren't who you originally thought they'd be. Specifically: we had a dedicated group of community managers from the Global division beta testing from the early versions of the app and giving us very detailed feedback, and yet we never treated them as our "real" users, instead sticking to our original plan of eventually launching to more traditional Cookpad users. It's speculation, but with some hindsight, I think those community managers could have a been the perfect group to seed the app to and grow from.

## Interlude: WWDC 2019

I attended WWDC for the first time 2019 with a small group of iOS engineers from Cookpad Japan and Cookpad Global. It turned out to be a massive year: iOS 13, SwiftUI, Combine, UICollectionViewDiffableDataSource, dark mode, etc. And it was also the final year of the "classic" in-person WWDC format before COVID19.

## OiCy (Smart Kitchen)

During a transitional period, I built a one-off app for the Smart Kitchen team. Our team used the app to present a concept during the [Smart Kitchen Summit Japan 2019](http://smartkitchensummit.mars.bindcloud.jp/food-innovation.co/sksj2019/index.html) conference. From concept to presenting the fully functioning app at the conference, it was less than 2 weeks. The app interfaced with a connected oven, inductive cooktop, condiment dispenser, and [variable hardness water dispenser](https://thespoon.tech/cookpad-has-100m-active-monthly-users-broadens-into-original-hardware-design-with-a-hard-soft-water-device/), and was remote controlled via the Multipeer Connectivity framework.

{% caption_img /images/cookpad-oicy-sksj-2019-presentation.png A video still from the OiCy Smart Kitchen Summit Japan 2019 presentation showing a hardware-integrated recipe app prototype. %}

Through the unique scope of this project – a one-off demo app used for a conference presentation – I learned how to radically tailor my development style to some given constraints. It can be surprisingly difficult to choose between development techniques that I know well and work well for 1M+ user-facing apps, and hacky techniques that get the prototype shipped by the end of the day.

In the end, the presentation was a success, but the smart kitchen division closed down a year or so later in late 2020.

## R&D

I joined the R&D division with a remit to prototype and productionize various R&D technologies under active research by our team of 5-10. I shipped an MVP that integrated image recognition into an app flow to estimate calories. This was another project that was developed and released internally within a few weeks.

My next big project was using image recognition to filter food photos in the main Cookpad's recipe photo picker. The main challenges were converting the machine learning model to Core ML and doing all processing transparently on device as a background task for potentially hundreds of thousands of photos. The feature was released for a brief period in beta, but was later rolled back after changes to privacy settings in iOS 14 rendered it too low impact to justify continued maintenance. However, my teammate and I won [patent JP,2022-040842,A](https://www.j-platpat.inpit.go.jp/c1800/PU/JP-7011011/3CE2815D9318E761AA5124BCD9A289ED1CEE4E6EE230751AC357FDA198F0AC47/15/en) ([US patent](https://patents.google.com/patent/US20230196769A1/en?oq=2023/0196769) is still pending) for the design of the feature.

{% caption_img /images/cookpad-patent-art.jpg h400 Diagram from food photo filter patent %}

Next, I worked with a small group of R&D members on an RGB and thermographic camera system placed above one's stovetop. As an R&D project, the scope of this project changed significantly over its lifetime. I wrote algorithms in Python for image registration, investigated HLS video streaming over AWS, and built myriad apps and tools in Swift and SwiftUI to move this data around.

Many of my projects during my time in R&D were short explorations. I researched, mostly from the applied technology side, topics like image segmentation, image classification, image inpainting, ML sound classification, pose detection, automatic video editing, and image generation with Stable Diffusion, ControlNet, and Textual Inversion.

However, my persistent focus in R&D was the field of augmented reality. This started with building a "recipe playground" app built in Unity for the Microsoft HoloLens 2 and used in the kitchen. Later, I began building prototypes with Apple's ARKit and RealityKit for iOS, with the knowledge that _eventually_ Apple would release a headset (Apple Vision Pro, announced at WWDC 2023).

Although my primary role was R&D during this period, I split my time on a few other teams as well, working an average of 2-3 days a week on each.

## Cookpad Japan's recipe app

I did a brief stint working part-time on Cookpad's flagship [recipe app](https://apps.apple.com/us/app/%E3%82%AF%E3%83%83%E3%82%AF%E3%83%91%E3%83%83%E3%83%89-no-1%E6%96%99%E7%90%86%E3%83%AC%E3%82%B7%E3%83%94%E6%A4%9C%E7%B4%A2%E3%82%A2%E3%83%97%E3%83%AA/id340368403) for the Japanese market as an iOS individual contributor. My biggest contribution was a recipe module presented when opening a recipe from an external source that included paging behavior between recommended recipes. The design spec was surprisingly complex and required significant planning work, experimentation, and eventually a custom UICollectionViewLayout.

{% caption_img /images/cookpad-japan-recipe-carousel.gif Recipe carousel in the Cookpad Japan app %}

## Tabedori

I joined the [Tabedori](https://note.com/tabedori/) team part-time for around 2 years. Tabedori was service within – but separate from – Cookpad run by a small team of between 4-8 members. I was originally slated to cover iOS duties for the 3 months of a coworker's childcare leave, but the product and team resonated so well with me that I stayed until the product was discontinued in 2023.

The service always served to teach people how to cook without recipes, but advanced through nearly 7 different versions over its lifetime, with myself contributing mostly as an iOS engineer for 2.5 versions. The first version I worked on was still primarily a UIKit codebase, but I added a chat system in SwiftUI, and then the final 2 versions of the app were all SwiftUI. It was the perfect environment for me to dive deep into the details of SwiftUI to understand its constantly evolving limitations from iOS 13 through 16 in real shipping app with a very opinionated style guide.

One of my favorite eras was participating in 2 intense prototyping and exploration periods between versions 5 and 6, then versions 6 and 7. It was during this time we developed, iterated, pitched, and discarded dozens of prototypes individually and as a team, working towards a release. In a short period I learned so much about animations, gestures, navigation, and rapid UI development in SwiftUI, while also considering the product and design angles.

{% caption_img /images/cookpad-tabedori-v7.jpg Tabedori version 7, developed with SwiftUI %}

## Cookpad Global Redux

I was invited to visit the Global headquarters in Bristol, UK for 2 months in late 2022. I had the chance to revisit a codebase I hadn't touched in 3 years while working alongside new and old coworkers and cooking in the office kitchen.

By this point the Cookpad Global iOS codebase and development process had matured significantly. I dove back into UIKit and specifically UICollectionViewDiffableDataSource and helped build an interface for exploring machine translated recipes from other countries.

## Cookpad Mart

After a company-wide restructuring in 2023, I found a new home in [Cookpad Mart](https://apps.apple.com/us/app/%E3%82%AF%E3%83%83%E3%82%AF%E3%83%91%E3%83%83%E3%83%89%E3%83%9E%E3%83%BC%E3%83%88-%E3%82%AF%E3%83%83%E3%82%AF%E3%83%91%E3%83%83%E3%83%89%E5%85%AC%E5%BC%8F/id1434632076) for my final few months at Cookpad. I had been a long-time user of Cookpad Mart's unique grocery delivery service since its early days and was looking forward to improving the service through the iOS app, its primary client-side interface.

As an e-commerce startup, Cookpad Mart has the conflicting goals of being stable, robust, and bug-free enough to support reliable exchanges of goods for payment, while also needing to iterate quickly to find product market fit and profitability. I was incredibly humbled jumping in and seeing the evolution of a 5 year old codebase and how the alumni iOS engineers had handled these constraints. Much of the required reliability came from systems built _around_ the codebase, rather than the codebase itself: test plans in every pull request, thorough code reviews, a weekly release cadence automated to the bone, "tap parties" where all iOS team members get together to thoroughly test each new feature, rotating QA participation from the product and design departments, and finally a culture of bug fixes being high priority.

Unfortunately, the Mart service itself underwent a massive pivot almost immediately after I joined the team.

## The End of the Story

Cookpad as a company went through some significant turmoil starting in early 2023 with the departure of the Japan CEO, then a call for a round of [voluntary retirements (PDF)](https://pdf.irpocket.com/C2193/NJLt/hAIz/SDEh.pdf) in February, a [CEO change (PDF)](https://pdf.irpocket.com/C2193/CaoZ/acVo/MlYT.pdf) in May, and finally a [larger round (PDF)](https://pdf.irpocket.com/C2193/CaoZ/qmSw/IQUI.pdf) of voluntary retirements in June.

I was part of that last round of voluntary retirements.

My honest thoughts? It was good time for me to go. I've been immersed in solving problems in the food and cooking domain for these past 6 years. Although I've always considered cooking a genuine interest – especially in the context of moving to a different country – there are several other domains that I'd like to explore.

So cheers to a good ride. The part I'll miss most is working with so many kind and talented coworkers, hopefully at least a few of which I'll be able to work with again.

