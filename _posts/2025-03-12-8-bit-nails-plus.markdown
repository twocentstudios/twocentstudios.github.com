---
layout: post
title: "8-bit Nails Plus"
date: 2025-03-12 23:00:00
image: /images/eight-bit-nails-list-upsell.jpg
tags: 8bitnails ios
---

I've released 8-bit Nails v1.1 to the App Store. It includes some new features alongside a one-time in-app purchase to unlock them.

In this post I want to share some notes about the new features and my decision to add an in-app purchase.

## In-App Purchase

A previously released app Count Biki includes in-app purchases but only as a tip that unlocks alternate app icons (admittedly no longer as popular as a perk as they once were). I wanted to start my indie app business journey by testing the waters with tip-based payment before trying other business models.

Unfortunately, Count Biki hasn't had enough traffic to even begin to get the purchase funnel going. I'd probably need hundreds of thousands or even millions of users to generate any sort of revenue via the voluntary tipping model.

8-bit Nails is also a pretty simple app. It's not a utility that assists users in accomplishing a specific goal, so it's hard to justify a large price tag, especially a subscription. Perhaps I'm still undervaluing the app and will need to re-evaluate the business model again, but for now, I decided to add a single one-time purchase for "8-bit Nails Plus" which unlocks all the features of the app at once, forever.

The purchase screen is the image below. It's a standard layout but I tried to make it a little flashy. I think it could be improved with some more illustrative images beneath each benefit.

{% caption_img /images/eight-bit-nails-purchase-screen.jpg h400 8-bit Nails Plus purchase screen %}

v1.0 of the app allowed users to create unlimited nail sets. However, from v1.1 onwards, users will need to purchase Plus to create more than 5 nail sets. Any users that already have more than 5 (I don't think there's any) will need to purchase Plus before they can add more.

{% caption_img /images/eight-bit-nails-list-upsell.jpg h200 Plus upsell on the home screen %}

I'm hoping that creating 5 nail sets is a good signal that users are enjoying the app and are willing to pay to continue. (I also started prompting for a review after users add their 3rd nail set). Limiting the main resource of the app doesn't sit well with me, but it's something I have to experiment with in this early stage.

## Widgets

Plus users can add a widget to their home screen or Today View. The widget shows their current nails. As Apple has opened up the iOS home screen more and more, iOS users have gotten more comfortable personalizing and decorating the home screen beyond simply having rows of apps.

{% caption_img /images/eight-bit-nails-latest-nails-widget.jpg h300 Latest nails widget %}

## Canvas resizing

I added the ability for Plus users to resize the canvas. This was a suggestion from a user who noted that the default 10w by 16h canvas didn't allow for designs with a center line. I decided to include 4 options with similar aspect ratios: small and large, each with a odd/even variant.

{% caption_img /images/eight-bit-nails-canvas-resizing.jpg h400 Canvas resizing screen %}

I was hesitant to introduce image resizing because it can be very disruptive to the image if you've already "completed" your design. There's a balance between forcing users to choose a canvas size before they start drawing and know what it means, and waiting until it's too costly to change it. In the end, I made the preview screen so users could see what the result would be before deciding to irreversibly alter the canvas size.

The rescaling algorithm is nearest-neighbor which makes sense for pixel art. I was also considering adding an option for clipping, but it's hard to imagine the cases where clipping makes more sense.

Under the hood, the app technically supports any canvas size, but there are a lot of assumptions based on the aspect ratio of nails. Therefore I wanted to keep it limited for now. Also, too large a canvas and touch drawing gets too difficult and time consuming.

## List layout

I made some changes to the layout of the nails list. The share and view large buttons were hidden and I wanted to make sure it was easy for users to access them. It makes the home screen a little more cluttered, but I feel okay about shifting the balance a bit towards usability and discoverability.

{% caption_img /images/eight-bit-nails-list-layout.jpg h400 Nails list with buttons pulled out beneath the row %}

## Rendering improvements

As discussed in detail in my previous post [Rendering Pixel Art with SwiftUI](/2025/03/10/pixel-art-swift-ui/), I made some improvements to the rendering for nails across the app. Users will see less anti-aliasing artifacts, especially in share images.

{% caption_img /images/eight-bit-nails-share-render.png h200 Share images look nicer %}

## Next steps

There are a few other features I'm considering adding like allowing nail outline customization or share image customization. But I'm going to wait for user feedback before any more overboard with guesses about what will drive downloads and usage (and revenue).

I'm planning to start uploading some videos to social media of me painting some nails with the app as a way to get the word out about the app. I haven't experimented with ads or social media marketing yet and I think this could be a good opportunity to get started.

My other goal with adding a non-consumable in-app purchase (i.e. one-time unlock) was to have a reusable implementation for other apps. Working with StoreKit and testing all scenarios is complex and time consuming. I'm banking on this upfront work decreasing the time to add payments to future apps significantly.
