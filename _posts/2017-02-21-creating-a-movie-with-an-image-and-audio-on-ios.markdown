---
layout: post
title: Creating a Movie with an Image and Audio on iOS
date: 2017-02-21 01:21:54
tags: apple ios
---

I'm going to cover a few data conversions in this post:

* `UIImage`/`CGImage` to `CVPixelBuffer`
* `UIImage` to QuickTimeMovie (.mov)
* Adding an audio track to a QuickTimeMovie

The code in this post targets Swift 3.0.1 and iOS 10.

Let's get started.

## Overview

Our goal is to generate a movie with the contents of a single `UIImage` and an audio file. The movie file will have the length of the audio file.

We're going to create a wrapper function to perform the full video creation.

* Image + Audio -> Movie

```swift
func createMovieWithSingleImageAndMusic(image: UIImage, audioFileURL: URL, assetExportPresetQuality: String, outputVideoFileURL: URL, completion: @escaping (Error?) -> ())
```

We'll need two more functions to perform the following conversions:

* Image -> Movie
* Movie + Audio -> Movie

```swift
func writeSingleImageToMovie(image: UIImage, movieLength: TimeInterval, outputFileURL: URL, completion: @escaping (Error?) -> ())

func addAudioToMovie(audioAsset: AVURLAsset, inputVideoAsset: AVURLAsset, outputVideoFileURL: URL, quality: String, completion: @escaping (Error?) -> ())
```

And finally one utility function to turn the image into a usable buffer for `AVAssetWriterInputPixelBufferAdaptor`.

* `CGImage` -> `CVPixelBuffer`

```swift
func pixelBuffer(fromImage image: CGImage, size: CGSize) throws -> CVPixelBuffer
```

## Implementation

Let's start with the utility functions and work our way up.

### CGImage -> CVPixelBuffer

```swift
static func pixelBuffer(fromImage image: CGImage, size: CGSize) throws -> CVPixelBuffer {
    let options: CFDictionary = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true] as CFDictionary
    var pxbuffer: CVPixelBuffer? = nil
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options, &pxbuffer)
    guard let buffer = pxbuffer, status == kCVReturnSuccess else { throw NSError.app() }
    
    CVPixelBufferLockBaseAddress(buffer, [])
    guard let pxdata = CVPixelBufferGetBaseAddress(buffer) else { throw NSError.app() }
    let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else { throw NSError.app() }
    context.concatenate(CGAffineTransform(rotationAngle: 0))
    context.draw(image, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    
    CVPixelBufferUnlockBaseAddress(buffer, [])
    
    return buffer
}
```

The above function does a few things.

* Create a `CVPixelBuffer` with attributes that allow us to write into it with a `CGContext`.
* Create a `CGContext` that targets the empty buffer we just created.
* Draw the image into the buffer.

### Image -> Movie

```swift
static func writeSingleImageToMovie(image: UIImage, movieLength: TimeInterval, outputFileURL: URL, completion: @escaping (Error?) -> ()) {
    do {
        let imageSize = image.size
        let videoWriter = try AVAssetWriter(outputURL: outputFileURL, fileType: AVFileTypeQuickTimeMovie)
        let videoSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecH264,
                                            AVVideoWidthKey: imageSize.width,
                                            AVVideoHeightKey: imageSize.height]
        let videoWriterInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: nil)
        
        if !videoWriter.canAdd(videoWriterInput) { throw NSError.app() }
        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriter.add(videoWriterInput)
        
        videoWriter.startWriting()
        let timeScale: Int32 = 600 // recommended in CMTime for movies.
        let halfMovieLength = Float64(movieLength/2.0) // videoWriter assumes frame lengths are equal.
        let startFrameTime = CMTimeMake(0, timeScale)
        let endFrameTime = CMTimeMakeWithSeconds(halfMovieLength, timeScale)
        videoWriter.startSession(atSourceTime: startFrameTime)
        
        guard let cgImage = image.cgImage else { throw NSError.app() }
        let buffer: CVPixelBuffer = try self.pixelBuffer(fromImage: cgImage, size: imageSize)
        while !adaptor.assetWriterInput.isReadyForMoreMediaData { usleep(10) }
        adaptor.append(buffer, withPresentationTime: startFrameTime)
        while !adaptor.assetWriterInput.isReadyForMoreMediaData { usleep(10) }
        adaptor.append(buffer, withPresentationTime: endFrameTime)
        
        videoWriterInput.markAsFinished()
        videoWriter.finishWriting {
            completion(videoWriter.error)
        }
    } catch {
        completion(error)
    }
}
```

I've wrapped everything in a do/catch block for more convenient error handling. I'm undecided whether I like this style or not.

You may want to pass in options for the `fileType` or `AVVideoCodecKey`. I've hardcoded them to `AVFileTypeQuickTimeMovie` and `AVVideoCodecH264`, respectfully.

The first half of this function is getting settings created and ensuring our writers are set up correctly.

`AVAssetWriter` assumes your frames will be the same length (this info is probably in the documentation somewhere, but I had to find it by trial and error). In order to get our movie to be the correct length, we'll use the same image as the first and last frame. The start frame will start a time 0 and the end frame will start at half our desired length. `AVAssetWriter` will write the frames as equal length.

Next, we convert the image to a pixel buffer using the function we created earlier. We're supposed to wait for the `assetWriterInput` to be ready to write, so we'll spin with a short sleep (in my anecdotal experience, the `assetWriterInput` keeps up fine in this situation and never needs to spin at all).

Finally, we'll call the completion block when the video has finished writing.

### Movie + Audio -> Movie

```swift
static func addAudioToMovie(audioAsset: AVURLAsset, inputVideoAsset: AVURLAsset, outputVideoFileURL: URL, quality: String, completion: @escaping (Error?) -> ()) {
    do {
        let composition = AVMutableComposition()
        
        guard let videoAssetTrack = inputVideoAsset.tracks(withMediaType: AVMediaTypeVideo).first else { throw NSError.app() }
        let compositionVideoTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, inputVideoAsset.duration), of: videoAssetTrack, at: kCMTimeZero)
        
        let audioStartTime = kCMTimeZero
        guard let audioAssetTrack = audioAsset.tracks(withMediaType: AVMediaTypeAudio).first else { throw NSError.app() }
        let compositionAudioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, audioAsset.duration), of: audioAssetTrack, at: audioStartTime)
        
        guard let assetExport = AVAssetExportSession(asset: composition, presetName: quality) else { throw NSError.app() }
        assetExport.outputFileType = AVFileTypeQuickTimeMovie
        assetExport.outputURL = outputVideoFileURL
        
        assetExport.exportAsynchronously {
            completion(assetExport.error)
        }
    } catch {
        completion(error)
    }
}
```

We'll first extract the video asset track from `inputVideoAsset` and add it to an `AVMutableComposition`. Then we'll do the same for the audio track from the `audioAsset`. It's assumed that the input assets have one and only one track.

Next, we'll create an `AVAssetExportSession` and begin the export.

### Image + Audio -> Movie

Finally we can write the wrapper function to tie the inputs and outputs together from functions we just wrote.

```swift
// See AVAssetExportSession.h for quality presets.
static func createMovieWithSingleImageAndMusic(image: UIImage, audioFileURL: URL, assetExportPresetQuality: String, outputVideoFileURL: URL, completion: @escaping (Error?) -> ()) {
    let audioAsset = AVURLAsset(url: audioFileURL)
    let length = TimeInterval(audioAsset.duration.seconds)
    let videoOnlyURL = outputVideoFileURL.appendingPathExtension(".tmp.mov")
    self.writeSingleImageToMovie(image: image, movieLength: length, outputFileURL: videoOnlyURL) { (error: Error?) in
        if let error = error {
            completion(error)
            return
        }
        let videoAsset = AVURLAsset(url: videoOnlyURL)
        self.addAudioToMovie(audioAsset: audioAsset, inputVideoAsset: videoAsset, outputVideoFileURL: outputVideoFileURL, quality: assetExportPresetQuality) { (error: Error?) in
            completion(error)
        }
    }
}
```

I don't like the completion handler nesting, but since it's only one level deep I consider it acceptable in this case. Using a reactive wrapper or `NSOperation` would be cleaner and allow cancellation too.

Another consideration would be to either allow the caller to provide a output URL for the intermediate video so that it can be cleaned up if necessary or to just perform the cleanup ourselves at the end of the operation after the final video has been created. In my specific situation, I was writing all the files to a temporary directory anyway.

## Wrap up

These functions were adapted from [this Stack Overflow answer](http://stackoverflow.com/questions/5640657/avfoundation-assetwriter-generate-movie-with-images-and-audio). I've cleaned it up and fixed some bugs.

Let me know if you have any improvements. I'm [@twocentstudios](https://twitter.com/twocentstudios) on Twitter.

See this code in the wild in my app [Phono/Photo](https://itunes.apple.com/us/app/photo-phono/id1202606014?mt=8).
