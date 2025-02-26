---
layout: post
title: "Core Image Labo - Open Source iOS App for Core Image Experimentation"
date: 2025-02-25 15:22:00
image: /images/core-image-labo-app-icon.jpg
tags: coreimagelabo app ios apple
---

I wrote an iOS app called Core Image Labo for experimenting with [Core Image](https://developer.apple.com/documentation/coreimage) filters. It was a "weekend project" in service of a more fully-featured upcoming video-shooting app. I decided to clean it up and release on the App Store and as open source with an MIT license.

- Open source on [GitHub - Core Image Labo](https://github.com/twocentstudios/coreimagelab)
- Available on the [App Store - Core Image Labo](https://apps.apple.com/us/app/core-image-labo/id6742433427)

{% caption_img /images/core-image-labo-marketing.jpg h400 Marketing screenshots for Core Image Labo's v1.0 release %}

You first set up a global input image (or use the default), and optionally a global background/target image (these are used for composite and transition filter types, respectively).

Then you can add any number of CIFilters from the list of supported filters. I was most interested in filters with numerical inputs you could control via sliders, so that's what I've implemented first.

The other input types are slightly more complex (but very much reasonable) to model in UI like [CIVector](https://developer.apple.com/documentation/coreimage/civector) and [CGAffineTransform](https://developer.apple.com/documentation/corefoundation/cgaffinetransform), and I don't personally need to experiment with any of those filters at the moment, so I've held off on implementing support for them for v1.0.

Finally, there are some simple tools for exporting the filtered image you see in the preview and a JSON file containing values for the filters used.

I made an icon using Figma's vector tools. Lately I've been using Blender to make icons in 3D, but I've been realizing that 3D-rendered images actually require some de-rendering to make them more illustrative and easier to read in the small pixel format of an app icon. For this side project, it was a lot faster to start from a 2D vector and render with simple shapes and color fills.

{% caption_img /images/core-image-labo-app-icon.jpg h400 Core Image Labo's app icon created in Figma %}

There are already a few very robust tools for working with Core Image on macOS. Writing code helps me learn though, and it was nice to have my own sandbox to experiment with to (re)learn Core Image. I figured it might be useful to some other devs to have an open source base to work from in case they're doing something unique that isn't supported by the other commercial apps.

If you're a dev working with Core Image, give it a go and contribute a feature or a bug fix if you can.
