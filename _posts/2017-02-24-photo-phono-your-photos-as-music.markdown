---
layout: post
title: Photo/Phono - Your Photos as Music
date: 2017-02-24 07:10:39
tags: apple ios photophono app
---

My latest app is called Photo/Photo. It's an iOS app that turns your photos into original musical compositions. It's an experiment in procedurally/algorithmically generated music.

> You can download it from the App Store [here](https://itunes.apple.com/us/app/photo-phono/id1202606014?mt=8).

Using Photo/Phono is pretty simple. 

* Pick which "composer" module you want to use to transform your photo.
* Select a photo from your photo library.
* Listen to a brand new composition composed from the data in your photo.
* When you find a photo and composition pair you like, share it.

<video src="/images/photophono-preview_video.mov" controls preload="none" poster="/images/photophono-preview_video_poster.png"></video>

{% caption_img /images/photophono-screens.png Walkthrough %}

### Rules

There are a few basic rules I wanted to abide by while designing the app:

* **Compositions are deterministic.** A particular photo will always return the same composition. There are no outside elements of randomness used to create a composition.
* **Compositions are unique.** This is more of a guideline. No two photos should have the same exact composition. I couldn't quite guarantee this rule, so in practice you may find visually similar photos may have similar sounding compositions. 

### How does the transformation process work?

An image is selected. Time to get to work.

First, the image is decomposed into various representations of numerical data. Some examples: 

* the average red color value of the whole image
* the average saturation value of one row of pixels
* the number of faces in the image
* the dominant colors of the image

This step gives us plenty of raw data to work with. (I go into more detail in [this post](http://twocentstudios.com/2016/10/11/images-into-music-deconstruction/)).

Next, for each instrument, the algorithm uses the photo data to make decisions on how notes should be created. A note can have a location in the piece, a pitch, a loudness, and a duration. That's a lot of decisions that need to be made.

Notes are created in an custom intermediate format that's a little easier to work with. This allows the algorithm to more easily concatenate bars or sections, with less complexity than is required by the MIDI specification. The basic building block looks like this:

```swift
struct NoteEvent {
    var number: NoteNumber
    var velocity: NoteVelocity
    var position: Beats
    var duration: Beats
}
```

Now that we have an representation of the piece that contains the notes in bars in sections for each instrument, it can be transformed into MIDI data. But there's still one more step before our MIDI data will be audible.

Each composer module is paired with a file called a [SoundFont](https://en.wikipedia.org/wiki/SoundFont). Since MIDI data is just instructions on how to play the music, a SoundFont is needed to actually generate the sound waves we hear. It's similar to a piece of sheet music needing an instrument to be played on. The sheet music is just instructions, and it could be played on a grand piano, harpsichord, an upright piano, etc.

Finally, our MIDI data and SoundFont are handed off to the system's audio frameworks and played back through the speakers or headphones.

### But how does the composing module actually _create_ the piece?

I go into more technical detail in [this post](http://twocentstudios.com/2016/10/12/image-into-music-transformation/), but here is an overview and a bit of background.

Each composer algorithm works differently. I wanted each algorithm to be free to explore using a palate of data and a canvas of MIDI so to speak. The only two rules are the ones mentioned above regarding being deterministic and being unique.

However, one of my other goals for this project was for the music to be a reflection of the artist creating the algorithm. It was a challenge to myself as a composer and a student of music theory to ask myself: when I sit down to write music, how do I actually _do_ it? Would it be possible to enumerate all the different ways I know how to create aesthetically pleasing music and encode those into the computer?

I can't say that the two composer algorithms I've created at first launch are the pinnacle of my abilities. But through the process of designing these, I've already learned a lot. And I have a handful of ideas of how I'd like to approach making the next one.

(If you're a composer interested in designing your own algorithm for Photo/Photo, please get in touch!)

For the above reasons and more, I ultimately decided against exploring machine-learning for this project. There's lots of amazing research in this field (I have a few links below).

### Technical notes

* I wrote about a few technical challenges creating the sharing feature. Here are posts about [bouncing MIDI to audio](http://twocentstudios.com/2017/02/20/bouncing-midi-to-audio-on-ios/) and [creating a movie with an image and audio](http://twocentstudios.com/2017/02/20/creating-a-movie-with-an-image-and-audio-on-ios/).
* The UI is only a few screens, but it gave me a chance to experiment with an MVVM+C (Model-View-ViewModel + Coordinator) architecture. I found a couple techniques that worked out well that I'm going to reproduce on future projects.
* I used [RxSwift](https://github.com/ReactiveX/RxSwift) instead of [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) on this project. ReactiveSwift was under heavy development when I was getting started, and I also wanted to get some experience with the RxSwift API. I'm probably going to move back to ReactiveSwift for my next project though.
* This project is 100% Swift. I love the language itself and especially look forward to writing it in a few years once the language and toolchain have stabilized. Some souring experiences were: going through a somewhat painful Swift 2.2 to 3.0 transition half way through the project, dealing with the frequent loss of autocomplete and syntax highlighting, and slow build times even with my reasonably small codebase.
* I did all the design work myself, starting with some drawings in my notebook, then moving to a Sketch file. I tried to use some of the newer, bolder iOS 10 aesthetic found in Music.app and News.app.
* This is the first project I've used Auto Layout exclusively (albeit using the [Mortar](https://github.com/jmfieldman/Mortar) helper library). I still find that working directly with frames is more predictable in how long it will take to create a complex layout, whereas implementing a layout using Auto Layout can range from trivial to impossible.

### Wrap Up

Starting off with the simple idea, "How would you turn a photo into music?" led to solving a lot of interesting problems and learning a lot (while getting to scratch a musical itch). I hope you enjoy the app!

Here are some links:

* [Photo/Phono on the App Store](https://itunes.apple.com/us/app/photo-phono/id1202606014?mt=8)
* [Sony Computer Science Laboratories - Music Research](http://www.flow-machines.com/)
* [Wolfram Tones](http://tones.wolfram.com/) - "An Experiment in a New Kind of Music"
* [What Makes Music Sound Good?](http://dmitri.tymoczko.com/whatmakesmusicsoundgood.html) - Research by Dmitri Tymoczko

Feedback is welcome! I'm [@twocentstudios](https://twitter.com/twocentstudios) on Twitter.
