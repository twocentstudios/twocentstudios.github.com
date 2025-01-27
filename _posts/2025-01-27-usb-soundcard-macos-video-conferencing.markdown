---
layout: post
title: "Using a USB Soundcard with Video Conferencing Apps on macOS"
date: 2025-01-27 12:43:00
image: /images/soundcard-macos-ladiocast-setup.png
tags: macOS
---

## Problem

Video conferencing apps (e.g. Zoom, Google Meet) generally do not support USB soundcards (e.g. UA Volt, Focusrite Scarlett) with **multiple inputs** on macOS the way proper recording software does. It's possible to select the entire soundcard input, but not specify which of the multiple inputs will be used, or how they will be combined.

{% caption_img /images/soundcard-macos-zoom-volt.png h450 Zoom settings for my UA Volt as an input do not allow specifying which input channel to use %}

For example, I have a 2-input [UA Volt 2](https://www.uaudio.com/uad-plugins/volt-2-usb.html). I plug a Rode NT2-A condenser mic into _INPUT 1_ via an XLR cable and use the Volt's 48V phantom power. I often use _INPUT 2_ for direct input electric guitar recording.

{% caption_img /images/soundcard-macos-volt-device.jpg h250 Your soundcard probably looks something like this UA Volt 2 %}

## Solution

The solution I've found through random forum posts is annoying, but free and reasonable until the day that video conferencing providers or Apple support this use case natively.

### Step 1: Download LadioCast and BlackHole

[LadioCast](https://apps.apple.com/us/app/ladiocast/id411213048?mt=12) does the input mixing. It's available for free on the Mac App Store. While running, it sits in your Menu Bar and has a popup window for configuration.

[BlackHole](https://github.com/ExistentialAudio/BlackHole) acts as an virtual audio input that other apps can use, but LadioCast can write to using real device input. The BlackHole **2ch variant is fine** for this use case. Follow the directions on the GitHub page to download the installer or use Homebrew.

I open LadioCast before I start a video call and close it after I finish because it adds the "an app is using mic" indicator to the macOS menu bar I find annoying. If you don't care, it doesn't hurt to leave it open all the time.

BlackHole runs in the background all the time with no issues.

To be safe, restart your Mac after installing these, running them, giving permissions, etc.

### Step 2: Configure LadioCast

For my use case, I want to have my UA Volt input 1 act as a mono input. In other words, it should have the same level on both the left and right stereo input channel. I've configured it as so:

{% caption_img /images/soundcard-macos-ladiocast-setup.png h200 Ladiocast settings I use for routing input 1 of my UA Volt as a mono source %}

The important parts are that I've:

- selected Volt 2 as the input device
- set channel 1 to both left and right
- set the output to be +0db
- set the output to _main_, highlighted red
- set the main output to device Blackhole 2ch

If your configuration is set up correctly, you should see green bars on both sides firing while using your mic.

You should only need to do this configuration once. Your settings will be saved after you close and reopen LadioCast.

### Step 3: Configure your video conferencing software

For this example I'm using Zoom.

Set your microphone to _BlackHole 2ch_ and you should be good to go.

{% caption_img /images/soundcard-macos-zoom-setup.png h450 Zoom configured to use the LadioCast -> Blackhole setup %}

## Other notes

This setup should also work if you want to record audio using simple apps with the same input selection limitations like QuickTime.

As mentioned in the references below, there are other ways to accomplish this using heavier software packages like GarageBand, Logic Pro, OBS, etc., but in my experience, the method in this post is the most lightweight I've found so far.

I thought macOS's built-in Audio MIDI Setup app could handle this via the _Create Aggregate Device_ function, but it cannot.

If you've come across better ways, feel free to email me and I'll update this post.

## References

- [macos - How can I mix multi-channel input device down to mono? - Ask Different](https://apple.stackexchange.com/questions/400173/how-can-i-mix-multi-channel-input-device-down-to-mono?rq=1)
- [macos - How can I force Mac OS X to treat my Mackie Onyx Blackjack as a mono input device? - Ask Different](https://apple.stackexchange.com/questions/37538/how-can-i-force-mac-os-x-to-treat-my-mackie-onyx-blackjack-as-a-mono-input-devic?rq=1)
- [ExistentialAudio/BlackHole: BlackHole is a modern macOS audio loopback driver that allows applications to pass audio to other applications with zero additional latency.](https://github.com/ExistentialAudio/BlackHole)
- [Existential Audio - How To Stream From Logic Pro X to Zoom](https://existential.audio/howto/StreamFromLogicProXtoZoom.php)[Existential Audio - How To Stream From Logic Pro X to Zoom](https://existential.audio/howto/StreamFromLogicProXtoZoom.php)
- [Create an Aggregate Device to combine multiple audio devices - Apple Support](https://support.apple.com/en-us/102171)
- [LadioCast on the Mac App Store](https://apps.apple.com/us/app/ladiocast/id411213048?mt=12)
