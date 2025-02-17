---
layout: post
title: "8-bit Nails - Pixel Art Nail Diary"
date: 2025-02-17 12:22:00
image: /images/8-bit-nails-app-icon.jpg
tags: 8bitnails app
---

This week I released 8-bit Nails. It's a light-hearted app for nail painting enthusiasts to express their creativity through pixel art and document their manicures.

Download it [on the App Store](https://apps.apple.com/us/app/8-bit-nails/id6737764793).

{% caption_img /images/8-bit-nails-marketing-images.jpg h400 Marketing screenshots for 8-bit Nails on v1.0 release %}

After you or a loved one gets their nails done IRL, jump into 8-bit Nails and create a matching set of nails with your own vision in pixel art style. Manicures can be simple or elaborate, and using your creativity to translate them into pixel art style is a fun challenge.

The drawing tools are simple, but there are a few built-in helpers to selectively copy an individual nail across to other nails. You can customize the nail on each hand.

{% caption_img /images/8-bit-nails-drawing-tools.jpg h450 8-bit Nails includes helper tools to eliminate the boring parts of painting %}

The system color picker is available, and the already used colors are easily accessible as a dynamic palette. And undo and redo functions are available for each nail.

{% caption_img /images/8-bit-nails-color-picker.jpg h450 The color picker %}

After you've finished pixel-fying your nails, they appear in the diary tagged with the current date. You can look back to see each of your nails over time.

{% caption_img /images/8-bit-nails-diary.jpg h450 The main screen shows a diary of your nails with most recent at the top %}

There's also a full screen viewer when you want to show off your work in person.

{% caption_img /images/8-bit-nails-large-view.jpg h450 View your nails in full screen %}

And finally, there's a special shareable image version with an auto-generated background color. Save this to your camera roll or send it to friends.

{% caption_img /images/8-bit-nails-shareable-image.jpg h250 An example shareable image %}

## Background

My girlfriend is a nail enthusiast. She gets her nails painted every couple of weeks. I liked seeing what new designs she had and a budding idea came to me of having a painting app to keep track of them. While prototyping, I realized having a full suite of drawing tools and brushes was way too complicated and intimidating. But arbitrarily limiting the drawing resolution created a fun constraint, made it easier to paint on a smartphone-sized touch screen, and ensured that there was a soft-limit on the time it takes to get to the finish line.

I finished a prototype version over a weekend, got it on Test Flight, and sent her an invite before the holidays. Over time, I've slightly improved the tools, fixed a few bugs, and added a few nice-to-have helpers. It was fun to see how both her and I interpreted her nails differently in pixel art style. Only after a couple rounds, I think each of us has gotten better at translating the pixel art style. Some of the more complex 3D designs she's gotten IRL have been especially fun to try to paint in the app.

When I started developing the app, I wasn't planning on taking it beyond something for the two of us. But as I chipped away at features and slowly noticed how popular manicures were with those around me, I decided it'd be worthwhile to put the finishing touches on the app and release it publicly on the App Store.

There are already a slew of manicure-related apps on the App Store. All fall into the category of games, photos for inspiration, or hyper-realistic painting simulators. Most are targeted towards young girls.

Similarly, there are plenty of pixel art apps. On the casual side, there are paint-by-numbers apps. On the tools side, there are full pixel art suites with layers and other complex tools.

I'm curious to see whether a cross between the two categories will find an audience.

## Development

On the technical side, I'm using SwiftUI and no external frameworks. Since my original goal was a personal app, the code reflects that.

Data for all nail sets are saved to one file. The data is saved as matrix of color values and drawn live in a SwiftUI `Canvas` View. Currently, the canvas is hard-coded to 10x16 pixels, but the code supports any resolution.

I use the system color picker. Undo/redo is implemented as a stack of nail data for each nail in the set. I wanted to experiment with some custom transitions so I didn't use any `sheet` or `NavigationStack` views this time; all views are layered in a `ZStack`.

If the app starts to get traction, I'm planning on cleaning up the codebase. I realize with my last app Eki Bright I probably leaned a little too hard on the side of a clean codebase. If I want to continue on the indie dev path, I'll need to keep optimizing for coding practices that facilitate a sustainable business, which means more up-front research, more marketing, more monetization, and more failing fast. All things that spending excess time in the codebase takes away from.

I think it'd be fun to add a widget that shows your latest nails on your home screen. And allow customization of the nail shape. Besides that, I'm going to wait to see what real users are looking for.
