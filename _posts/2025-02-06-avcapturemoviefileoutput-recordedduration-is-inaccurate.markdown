---
layout: post
title: "AVCaptureMovieFileOutput recordedDuration Value is Inaccurate"
date: 2025-02-06 23:10:00
image: /images/avfoundation-recordedDuration.png
tags: apple ios handcrankcamera
---

In the AVFoundation framework on Apple platforms, `AVCaptureMovieFileOutput` (or more accurately, the abstract base class `AVCaptureFileOutput`) has a property called [`recordedDuration`](https://developer.apple.com/documentation/avfoundation/avcapturefileoutput/1389028-recordedduration).

> If recording is in progress, this property returns the total time recorded so far.

Like in the [AVCam sample project](https://developer.apple.com/documentation/avfoundation/capture_setup/avcam_building_a_camera_app), this property is often used to show the elapsed time to the user while they're recording a video at a base increment of seconds.

Through testing, I've found this value is only accurate to around 0.06 seconds or 16 frames per second (FPS). If you try to sample the `recordedDuration` property faster, say at 30 FPS, you'll see repeated values.

If you need more accuracy than this, you can use one of the following strategies.

### Calculating an accurate `recordedDuration` on iOS 18.2+

On iOS 18.2+, `AVCaptureFileOutputRecordingDelegate` includes the method:

```swift
optional func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, startPTS: CMTime, from connections: [AVCaptureConnection])
```

`startPTS` stands for "start presentation timestamp". It looks like a random `CMTime`, but it's in reference to a `CMClock` instance. In this case `AVCaptureSession`'s `synchronizationClock`.

To get the amount of time elapsed since recording, you can therefore use:

```swift
let recordedDurationCMTime = captureSession.synchronizationClock!.time - startPTS
let recordedDurationSeconds = recordedDurationCMTime.seconds
```

### Calculating mostly accurate `recordedDuration` before iOS 18.2

Older versions of iOS don't include the `startPTS` variant of `fileOutput(didStartRecordingTo:)`.

Therefore, the best we can do is capture our own `startPTS` from the `synchronizationClock` at the moment of the delegate callback:

```swift
func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    self.startPTS = captureSession.synchronizationClock!.time
}
```

Then use the `recordedDurationCMTime` code from the above section.

### Calculating a slightly less accurate `recordedDuration` converting to the host time clock

Using `AVCaptureSession.synchronizationClock` in other parts of your app might be inconvenient. You can instead convert the `startPTS` to be in relation to the host time clock. Then, in the rest of your app, you can reference the singleton `CMClock.hostTimeClock` more easily.

```swift
let hostClockStartPTS = captureSession.synchronizationClock!.convertTime(startPTS, to: CMClock.hostTimeClock)
```

In my testing, the synchronizationClock and hostTimeClock are very close in value already. Essentially less than 1 ms difference or around 1000 FPS. However, they are different clocks and the `CMClock` utilities report that they can "drift".

```swift
print(captureSession.synchronizationClock!.mightDrift(relativeTo: CMClock.hostTimeClock)) // true
```

Depending on your use case, you may want to avoid using the `hostTimeClock` and instead continue to reference `captureSession.synchronizationClock`. `CMClock` does not have a lot of documentation, so I can't make any accuracy guarantees.

### Calculating the most accurate `recordedDuration` using `AVCaptureVideoDataOutput`

You can get the absolute best accuracy by not using `AVCaptureMovieFileOutput` and instead using `AVCaptureVideoDataOutput` to get the presentation timestamps of the raw frame buffers yourself. This is left as an exercise to the reader. The implementation is much more involved, but it's not uncommon to attempt.

You can view an example of working with presentation timestamps in this way in the docs for [AVCaptureSession.synchronizationClock](https://developer.apple.com/documentation/avfoundation/avcapturesession/3915813-synchronizationclock).

