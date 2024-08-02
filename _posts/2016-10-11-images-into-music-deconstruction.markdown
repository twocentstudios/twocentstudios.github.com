---
layout: post
title: "Images Into Music: Deconstruction"
date: 2016-10-11 22:29:44
tags: apple ios app
---

This post discusses _deconstructors_, the first module of the turning-an-image-into-an-original-piece-of-music project I outlined in [this post](http://twocentstudios.com/2016/10/10/transforming-images-into-music/). Skim that post first to understand the goal of the project.

## What is deconstruction?

I'm defining deconstruction as the process of turning raw image data into various streams of pseudo-random numbers. We can later use these numbers in our Transformation step. We'll  feed these numbers into a decision engine in order to generate music in a musical grammar.

## Why do deconstruction?

Our goal for this module is to get a variety of deterministic data we can feed into our decision engine in the next module. Imagine a painter's palette with each stream of data as a color on the palette that we can use to create our painting.

We can consider the lossless canonical form of image data as a bitmap of red, green, and blue numbers in a particular range. Or we could losslessly convert this data into a different colorspace to give us more information about the humanistic qualities of the colors, for example, how vivid the colors are. But there is also value in viewing this data in a lossy form, compressed, like into an average, or otherwise irreversibly mixed together.

## Types

Let's take a quick tour through the types we'll use in this module.

### Normalized

Since most of our image data representations are bounded, and we know those bounds ahead of time, we can "normalize" this data to any scale we wish. Normalization is a bit of a loaded term, but in our case we'll define it as a percentage inclusive of the minimum and maximum values:

```swift
// Expresses a percentage 0...1 inclusive
typealias Normalized = Double
```

### Input types

In the Cocoa world, our inputs will be `UIImage` or `NSImage`. We can further genericize by using `CGImage` as our common system image container, which if necessary can be converted back to a `UIImage` or converted to a `CIImage` for use in the Core Image framework.

### Colors

Color spaces can be represented by one or more sets of normalized numbers. We'll need to create structs for each.

```swift
struct RGB {
    let red: Normalized
    let green: Normalized
    let blue: Normalized
}

struct HSV {
    let hue: Normalized
    let saturation: Normalized
    let value: Normalized
}

struct Gray {
    let gray: Normalized
}
```

Other color spaces could be added later. For now we'll stick to the above popular three.

Looking ahead, it's probably a good idea to conform these to a protocol so we don't have to write the same algorithm for each color space later.

```swift
protocol ComponentRepresentable {
    var components: [Normalized] { get }
    
    init(components: [Normalized])
}
```

### Image data

Our desired output will mostly be normalized numbers. `CGImage` isn't particularly easy to pull these numbers out every time, so we'll use a struct to store the raw color data instead.

```swift
struct ImageData {
    let rowCount: Int
    let colCount: Int
    let rgbValues: [RGB]
}
```

Note `colCount` can be calculated lazily from `rowCount` and `rgbValues.count`.

`RGB` was arbitrarily chosen as the canonical color space. Other colorspaces can be converted to through `UIColor`. Another valid implementation would be to use `CGColor` as the canonical colorspace representation and convert to others from there.

### To image data

Our first transformation will be from `CGImage` to `ImageData`. Our function has the signature:

```swift
extension CGImage {
    func imageData() throws -> ImageData { }
}
```

However, we might need to preprocess the image to normalize its size.

```swift
extension CGImage {
    func resize(_ size: CGSize) -> CGImage { }
}
```

## Deconstructor examples

Now that we have an easily parseable format, we can write a some deconstructors. I'll selectively provide some code examples and some function signatures.

### Basic color space

Let's allow movement to some other color spaces.

```swift
extension ImageData {
    var hsvValues: [HSV] {
        return rgbValues.map { HSV(rgb: $0) }
    }
    
    var grayValues: [Gray] {
        return rgbValues.map { Gray(rgb: $0) }
    }
    
    var blackWhiteValues: [Gray] {
        return grayValues.map { Gray(gray: round($0.gray)) }
    }
}
```

### Rows and columns

Let's allow transformation to rows or columns as an array of arrays.

```swift
extension ImageData {
    var rgbRows: [[RGB]] { }
    var rgbCols: [[RGB]] { }
    var hsvRows: [[HSV]] { }
    var hsvCols: [[HSV]] { }
}
```

### Averages

Our most basic lossy data deconstruction is averages. We can average an entire image down to one value.

```swift
extension ImageData {
    func averageHSV() -> HSV { }
    func averageRGB() -> RGB { }
    func averageGray() -> Gray { }
}
```

Or we can get larger groups of data by averaging rows or columns.

```swift
extension ImageData {
    func rowAverageHSVs() -> [HSV] { }
    func rowAverageRGBs() -> [RGB] { }
    func colAverageHSVs() -> [HSV] { }
    func colAverageRGBs() -> [RGB] { }
}
```

### Representative Colors

Representative colors refers to the set of colors that appear most often in an image and therefore "represent" it best. It's an interesting field on its own and I'm currently using the thoroughly researched [DominantColor](https://github.com/indragiek/DominantColor) library. DominantColor uses k-means clustering to produce an array of around a dozen or so colors.

```swift
extension CGImage {
    func representativeHSVs() -> [HSV] { }
    func representativeRGBs() -> [RGB] { }
}
```

### Faces

A less random deconstructor is the faces deconstructor. It can provide us both the number of faces in an image and the percentage of the photo's area covered by faces.

I've written in detail about the algorithm in [this post](TODO).

Note this this deconstructor uses Core Image, and works best when used on the original resolution of the image.

```swift
extension CIImage {
    func faceCount() -> Int { }
    func areaOfFaces() -> Normalized { }
}
```

### More

I've already written a few other deconstructors including derivatives and image edges, but in theory your imagination is the limit on how this raw data can be processed. Future transformers (the module that ultimately uses our deconstructed data) can be based on future deconstructors.

## Why not write custom Core Image transforms?

Although Core Image is a very well supported framework on both iOS and macOS, there are a few reasons it doesn't work well for this project. 

Most importantly, Core Image expects all functions to be of the form `CIImage -> [String: Any] -> CIImage`. Or in other words, an input image, an arbitrary input dictionary of keys and values, and an output image. We usually want our output to be normalized numbers, sometimes grouped. It's more convenient for us to work in the numbers world rather than the image world.

Next, part of the reason for Core Image's existence is its "recipe" architecture, which assumes you're composing several transforms, then using the framework to efficiently apply all of these transforms at once to get your final image. In our case, we'll be using multiple transforms (aka deconstructors) in parallel, and thus would be sacrificing the benefits of the framework.

Lastly, the `[String: Any]` input unnecessarily loses a lot of type information. One of the primary disadvantages of using Core Image in general is the amount of time spent in the documentation looking for the available parameter names and hoping you don't make any typos. The (sometimes) numerical bounds of the prebaked transforms aren't usually provided, and require lots of guess and check. I personally wouldn't want to move more of the API into static documentation than I absolutely have to.

## Performance implications

Each deconstructor used in a transform incurs a performance penalty. Image processing is a notoriously processor and memory intensive field. There are many tradeoffs to consider when writing and using these deconstructors, and it's still too early in the project to determine what the maximum input image size can be that will produce a listenable piece of music in an acceptable amount of time for the user.

In early tests, 50x50 pixels produces an image in maybe a second or two on an iPhone 6 with a handful of simple deconstructors used.

Deconstructors themselves can be rewritten for performance ad infinitum, considering the constantly evolving performance attributes of the Swift language itself, structs vs classes, the theoretical limits of the algorithms, and usage of hardware acceleration through the Accelerate framework. Therefore, strategically I won't be optimizing each deconstructor until the UX specifications for maximum time limits are better understood.

## What can we do with all this data?

In a future post, I'll talk about the transformer module and how we'll actually go about using this pseudo-random data to make decisions in a composition.
