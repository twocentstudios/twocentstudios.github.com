---
layout: post
title: "Images Into Music: Transformation"
date: 2016-10-12 06:19:33
---

> This post discusses transformers, the second module of the turning-an-image-into-an-original-piece-of-music project I outlined in [this post](http://twocentstudios.com/2016/10/10/transforming-images-into-music/). Skim that post first to understand the goal of the project. You can also read about the first module, deconstructors, in [this post](http://twocentstudios.com/2016/10/11/images-into-music-deconstruction/).

I'll define a transformer as the algorithm responsible for deterministically generating a musical composition based solely on a single image as the input.

Transformers use a palette of [deconstructors](http://twocentstudios.com/2016/10/11/images-into-music-deconstruction/) to generate some pseudo-random numbers, then apply those numbers in a deterministic way to a decision engine. The decision engine generates a piece of music using a musical grammar and eventually creates an output in a MIDI-like DSL.

In this post we'll be discussing the theory behind mapping pseudo-random data to the various decisions that must be made to create a piece of music. We'll do so by creating an example transformer. We won't yet discuss the MIDI-like DSL part.

## Choosing a musical key

Let's start with an example of a very simple decision that must be made for our piece of music: what key will it be in?

In standard Western music, we have a choice of the following 12 keys:

> C, C#, D, D#, E, F, F#, G, G#, A, A#, B

Using 12 possible keys in our transformer will allow a variety of different sounding pieces to be created.

The determination of what input data we use to determine which of the 12 keys is chosen is part of the creativity and unique character of the transformer. We have several deconstructors available to us. For this example, let's use the `averageGray` of the input image.

```swift
// Expresses a percentage 0...1 inclusive
typealias Normalized = Double

struct Gray {
    let gray: Normalized
}

extension ImageData {
    func averageGray() -> Gray { }
}
```

Our entire input image will be converted to grayscale, then all its values will be averaged. The final result is that we'll have a single `Double` value constrained 0.0 to 1.0 inclusive that represents the data in this photo. A solid black image will produce 0.0, a solid white image will produce 1.0, and everything else will produce some number in between.

The most straightforward way to proceed from here is to create 12 equal-sized buckets along the 0.0 to 1.0 number line that correspond to each potential musical key. Whichever bucket the `averageGray` value falls into determines our key.

```
0.0..<0.083 -> C
0.083..<0.166 -> C#
...
0.917...1.0 -> B
```

For example, if the `averageGray` of our input image was `0.121`, it would fall into the second bucket above, and our resulting piece would be created in the key of C#.

We can even create a function that will automate this decision making process for us. 

```swift
/// Returns exactly one entry of the array based on the input.
func exactlyOneOf<T>(_ input: Normalized, items: [T]) -> T { }
```

And an example of how we'd use it:

```swift
let imageData: ImageData = ... // converted from the input image
let averageGrayValue: Normalized = imageData.averageGray().gray
let possibleKeys = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
let outputKey = exactlyOneOf(averageGrayValue, items: possibleKeys)
```

## Probability

Astute readers might notice a potential oversight in the previous algorithm related to the probability distribution of the `averageGray` function. There are a Pandora's Box of questions we need dive into in order for our transformer to produce the "expected" results.

### Should any key be more popular than the others?

Or in mathematical terms, what is the probability distribution of keys based on the deconstructor we've chosen (in our example, `averageGray`)?

The answer is almost certainly that the probability distribution of all input images will not be equal across the normalized values between 0.0 and 1.0, but what will it be? And do we care?

For the particular example of choosing a musical key for the piece, it might not matter as much that some keys will be chosen more often than others. All musical keys will produce nominally pleasing music, if not with a slightly different character. It's definitely a judgement call, but personally I would say we should shoot for equal distribution among our input space.

Which leads to the next question...

### What is our input space?

Technically, our input space is defined as any `CGImage`. It could be a solid color, a selfie, a Renaissance painting, a landscape photo, television static, etc.

However, we can narrow down the expected input space considerably by targeting iOS as our eventual distribution platform, and saying a user's camera roll is the only photo source.

Now we can say with some confidence that the input space will consist of some combination of photos taken by the device's built-in camera and its captured screenshots. We can use this assumption to determine probability distributions for each of our image data deconstructors.

In a later post, I'll explore using my own camera roll as an example data source to view the probability distributions of several image data deconstructors.

For now, let's move on in our example transformer.

## Drums

Now that the key of our piece has been decided, next we need generate some drums. Well, maybe just a kick drum for now.

Our first decision only had one dimension so to speak (I'm playing fast and loose with the definition of dimension here). The key is static throughout the piece so we only needed to choose once between twelve options.

Drums, however, primarily involve a second dimension. That is: their placement on the timeline (assuming each drum hit has the same duration).

### Goals

We have some tradeoffs to consider in designing our algorithm. Let's revisit our two goals for a transformer:

* All pieces of music generated should be pleasing to the ear.
* All pieces of music should be unique.

### Strategies

There are two strategies we can consider, each playing to one of those two strengths.

* Strategy A: determine at least two (but more is better) allowable patterns and use data to choose between them.
* Strategy B: place some constraints on which beats we can place drum hits, but otherwise allow the data to fill in the blanks.

#### Strategy A: Guaranteed Musicality

Strategy A ensures that all pieces generated by this transformer will have musically valid drums because it can only choose between musically valid drum beats we've written in advance. We gain confidence in the musicality of the output by sacrificing entropy. The likelihood that two images produce the same drum beat is much greater than Strategy B.

An example of A is below. We've created 4 different options for drum patterns, with hits on the timeline indicated by `x` and rest beats indicated by `-`.

1. `x-x-x-x-`
2. `x---x---`
3. `x-x-x---`
4. `x---x-x-`

#### Strategy B: Uniqueness

Strategy B dramatically increases the entropy (a "good" thing), at the cost of increased complexity and possibility that the generated beat will be "unmusical" (it'll sound weird).

An example of B is below, specified as rules.

1. A hit must always occur on beat 1.
2. A hit may occur on beats 2, 3, 4, 5, 6, 7, or 8 in any combination.

It's possible that Strategy B could produce the following patterns as well as hundreds more:

* `x-------`
* `xxxxxxxx`
* `x--x-x-x`

In deciding between prebaked options like in Strategy A, and more complicated algorithms like Strategy B, it is up to the transformer's creator to weigh the tradeoffs.

## Other Instruments

Creating algorithms becomes even more complex as we start to introduce more of the required dimensions into our transformer.

A bass line generation algorithm must include logic for the following conditions and more:

* the number of notes in a measure.
* how many unique measures are in a bar.
* how many unique bars are in the piece.
* how often each of the unique set of bars is repeated.
* the placement of notes on the timeline.
* the duration of notes might be variable (e.g. quarter-note, eighth-note). 
* the minimum and maximum pitch of notes might fall between a specific interval (e.g. C1 to C3). 
* the allowable pitches themselves might be constrained to a specific musical scale (e.g. major, minor, blues). 
* the pattern might be constrained to a set of prebaked known chord progressions (e.g. 1-4-5-1, 1-6-4-5).
* how the bass line aligns with the other parts of the piece (e.g. drums, melody).

Creating melodies and harmonies becomes even more complex since our ears will focus and follow them more closely.

## Wrap up

In this post, we've looked at how we can go about using deconstructed image data to make decisions in generating our music. We looked at how to structure algorithms to create our own musical grammar. And we looked at the many dimensions we have to keep in mind when designing our algorithm.

In being the key creative part of this project, the strategies and success criteria are quite unbounded. I'm optimistic that the module structure around transformers and the tooling I've created so far will enable the creation of many interesting algorithms.
