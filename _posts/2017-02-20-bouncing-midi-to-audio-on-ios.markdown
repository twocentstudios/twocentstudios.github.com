---
layout: post
title: Bouncing MIDI to Audio on iOS
date: 2017-02-20 18:58:18
tags: apple ios photophono
---

This post shows one way to create an audio file from MIDI data and a soundfont (.sf2) file on iOS. It targets iOS 10.2 and Swift 3.0.1.

I'll first go into some background about the problem. Then I'll detail the solution with some code in Swift. If you're only interested in the solution, please skip to that section.

## Background

iOS and macOS have an extensive set of audio/visual frameworks, both low level and high level.

In my app Phono/Photo, there are two tasks (amongst a few others) that focus on MIDI.

1. Play MIDI data from the speaker.
2. Transform MIDI data into a suitable wave format for the purposes of playback outside the app.

You might think these tasks would be similar, but, as of iOS 10, it turns out the former is trivial and the latter is a bit more complicated.

### Playing MIDI Data from the Speaker

In iOS 8, Apple began adding some higher level components to AVFoundation that both wrap their lower level AudioToolbox relatives and provide solutions to common tasks.

`AVMIDIPlayer` was added in iOS 8, and solves MIDI playback elegantly.

You can load MIDI from a file or from raw Data, provide a URL for a soundbank file, then control playback with a few straightforward methods. All the underlying components used to sequence the MIDI and synthesize it are encapsulated within.

In order to gain access to the output bus tap that contains the raw audio data, we'll essentially need to recreate `AVMIDIPlayer` using some other framework components.

### Strategy and Limitations

Our strategy will be to set up a chain of components to: 

1. Sequence the MIDI (send each MIDI event at the correct time).
2. Map a MIDI event to an audio file from the soundbank.
3. Record the audio that's produced.

Observing the output of this process limits us to real time processing speed. In other words, if the MIDI file is 60 seconds, it'll take 60 seconds to produce the output audio file.

> One strategy I haven't tried would be to pitch shift the MIDI up one octave, play it back at 2x, record it at 88.2kHz, then downsample to 44.1kHz. `AVAudioSession` presumably can't go past 48kHz though.

### Components We'll Need

We need to set up an `AVAudioEngine` with a few nodes. Conceptually, the chain will look something like this:

```
                                     Output Tap
                                         |                      
AVAudioSequencer -> AVAudioUnitMIDISynth -> AVAudioMixerNode ->
```

> Technically, the `AVAudioSequencer` is connected directly to the `AVAudioEngine`. And the `AVAudioMixerNode` is managed by the `AVAudioEngine` too.

`AVAudioSequencer` provides a modern interface to `MusicSequence` from the `AudioToolbox` framework.

`AVAudioUnitMIDISynth` is an `AVAudioUnit` we'll have to create ourselves by subclassing `AVAudioUnitMIDIInstrument`. The reason we can't use Apple's provided `AVAudioUnitSampler` (also a subclass of `AVAudioUnitMIDIInstrument`) is because our MIDI file is multi-timbral: it uses multiple instrument presets from the soundfont and plays notes simultaneously.

`AVAudioMixerNode` is the output of the `AVAudioEngine`, capable of combining multiple input nodes. In our case, we only need one.

I decided I don't want the user to hear the export progress, so the file output tap will go at the output of the `AVAudioUnitMIDISynth` and the output of the `AVAudioMixerNode` will be muted.

Now that we have a general diagram of how these components will fit together, let's get started on the implementation.

## Implementation

The following targets Swift 3.0.1 and iOS 10.

First let's create `AVAudioUnitMIDISynth`.

### AVAudioUnitMIDISynth

> Most of this code is adapted directly from [Gene De Lisa's blog](http://www.rockhoppertech.com/blog/multi-timbral-avaudiounitmidiinstrument/). He's prolific in writing about iOS and MIDI topics.

```swift
class AVAudioUnitMIDISynth: AVAudioUnitMIDIInstrument {
    init(soundBankURL: URL) throws {
        let description = AudioComponentDescription(
            componentType: kAudioUnitType_MusicDevice,
            componentSubType: kAudioUnitSubType_MIDISynth,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        
        super.init(audioComponentDescription: description)
        
        var bankURL = soundBankURL
        
        let status = AudioUnitSetProperty(
            self.audioUnit,
            AudioUnitPropertyID(kMusicDeviceProperty_SoundBankURL),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &bankURL,
            UInt32(MemoryLayout<URL>.size))
        
        if status != OSStatus(noErr) {
            throw NSError.app("\(status)")
        }
    }
    
    func setPreload(enabled: Bool) throws {
        guard let engine = self.engine else { throw NSError.app("Synth must be connected to an engine.") }
        if !engine.isRunning { throw NSError.app("Engine must be running.") }
        
        var enabledBit = enabled ? UInt32(1) : UInt32(0)
        
        let status = AudioUnitSetProperty(
            self.audioUnit,
            AudioUnitPropertyID(kAUMIDISynthProperty_EnablePreload),
            AudioUnitScope(kAudioUnitScope_Global),
            0,
            &enabledBit,
            UInt32(MemoryLayout<UInt32>.size))
        if status != noErr {
            throw NSError.app("\(status)")
        }
    }
}
```

In `init`, we're telling the AudioUnit that it's a MIDISynth. Then we'll set the soundbank that we want it to use.

The `setPreload` function is the critical part that will allow faithful playback of the instruments in the MIDI data. The MIDISynth AudioUnit has a property that allows it to preload instrument banks from the soundfont we provided on initialization. While this flag is set to true, any MIDI events sent to the MIDISynth, instead of being played, will be parsed for their instrument/bank messages and those instruments' samples will be loaded.

A caveat is that the MIDISynth must be connected to the `AVAudioEngine` which must also be running when the preload message is sent.

After we're done sending messages intended for preloading, the MIDISynth should have preload mode disabled, after which it will play any incoming MIDI message normally.

### MIDIFileBouncer

Let's put it all together in the `MIDIFileBouncer`.

Our inputs will be:

1. MIDI data
2. Soundbank URL
3. The AVAudioSession

```swift
class MIDIFileBouncer {
    fileprivate let audioSession: AVAudioSession
    
    fileprivate var engine: AVAudioEngine!
    fileprivate var sampler: AVAudioUnitMIDISynth!
    fileprivate var sequencer: AVAudioSequencer!

    deinit {
        self.engine.disconnectNodeInput(self.sampler, bus: 0)
        self.engine.detach(self.sampler)
        self.sequencer = nil
        self.sampler = nil
        self.engine = nil
    }
    
    init(midiFileData: Data, soundBankURL: URL, audioSession: AVAudioSession) throws {
        self.audioSession = audioSession
                
        self.engine = AVAudioEngine()
        self.sampler = try AVAudioUnitMIDISynth(soundBankURL: soundBankURL)
        
        self.engine.attach(self.sampler)
        
        // We'll tap the sampler output directly for recording
        // and mute the mixer output so that bouncing is silent to the user.
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        let mixer = self.engine.mainMixerNode
        mixer.outputVolume = 0.0
        self.engine.connect(self.sampler, to: mixer, format: audioFormat)
        
        self.sequencer = AVAudioSequencer(audioEngine: self.engine)
        try self.sequencer.load(from: midiFileData, options: [])
        self.sequencer.prepareToPlay()
    }  
}
```

> Regarding the deinit, the reason we're not declaring the engine, sampler, or sequencer as `let` (or non-optional) is because we need to specify their order of deallocation to avoid a crash (`audioEngine` is released before `sequencer` has finished with it). Please let me know if you know a more elegant way to avoid this crash.

In `init`, we're going to create an instance of our three required classes: `AVAudioEngine`, `AVAudioUnitMIDISynth`, and `AVAudioSequencer`. Then we'll wire them together and get the sequencer ready for playback.

Now onto our bounce function.

```swift
extension MIDIFileBouncer {
    func bounce(toFileURL fileURL: URL) throws {
        let outputNode = self.sampler!
        
        let sequenceLength = self.sequencer.tracks.map({ $0.lengthInSeconds }).max() ?? 0
        var writeError: NSError? = nil
        let outputFile = try AVAudioFile(forWriting: fileURL, settings: outputNode.outputFormat(forBus: 0).settings)
        
        try self.audioSession.setActive(true)
        self.engine.prepare()
        try self.engine.start()
        
        // Load the patches by playing the sequence through in preload mode.
        self.sequencer.rate = 100.0
        self.sequencer.currentPositionInSeconds = 0
        self.sequencer.prepareToPlay()
        try self.sampler.setPreload(enabled: true)
        try self.sequencer.start()
        while (self.sequencer.isPlaying
            && self.sequencer.currentPositionInSeconds < sequenceLength) {
                usleep(100000)
        }
        self.sequencer.stop()
        usleep(500000) // ensure all notes have rung out
        try self.sampler.setPreload(enabled: false)
        self.sequencer.rate = 1.0
        
        // Get sequencer ready again.
        self.sequencer.currentPositionInSeconds = 0
        self.sequencer.prepareToPlay()
                
        // Start recording.
        outputNode.installTap(onBus: 0, bufferSize: 4096, format: outputNode.outputFormat(forBus: 0)) { (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            do {
                try outputFile.write(from: buffer)
            } catch {
                writeError = error as NSError
            }
        }
        
        // Add silence to beginning.
        usleep(200000)

        // Start playback.
        try self.sequencer.start()
        
        // Continuously check for track finished or error while looping.
        while (self.sequencer.isPlaying
            && writeError == nil
            && self.sequencer.currentPositionInSeconds < sequenceLength) {
            usleep(100000)
        }
        
        // Ensure playback is stopped.
        self.sequencer.stop()
        
        // Add silence to end.
        usleep(1000000)

        // Stop recording.
        outputNode.removeTap(onBus: 0)
        self.engine.stop()
        try self.audioSession.setActive(false)
        
        // Return error if there was any issue during recording.
        if let writeError = writeError {
            throw writeError
        }
    }
}
```

The bounce function is synchronous. `AVAudioSequencer` is interesting in that it will play beyond the length of the MIDI track it's playing. It will play until it's told to stop or it's interrupted. We don't get a callback when the last MIDI event has rung out.

The most straightforward solution, although not the most efficient or elegant, is to sleep the current thread until either the sequencer has stopped for some external reason or it has played past the length of its last MIDI event. This is also arguably the most robust solution without the knowledge of whether we can observe `isPlaying`.

With that disclaimer in place, let's walk through the code.

* Calculate the sequence length for later use with help from `AVMusicTrack`.
* Set up an `AVAudioFile` to write the output buffers to.
* Start up the `AVAudioSession` and the `AVAudioEngine`.
* Play the entire sequence through once with the `AVAudioUnitMIDISynth` in preload mode as discussed earlier. However, we can cheat a little bit and play it through at 100x normal speed since it simply needs to see all the events. 
* Reset everything for the real recording session playback.
* Install a tap on the output of `AVAudioUnitMIDISynth` and write the output buffers to our `AVAudioFile`. 
* Start playback, wait for it to finish or error, then remove the bus.

I've added a few pauses to ensure there's adequate gaps of silence between the beginning and end of the file.

Assuming the function doesn't throw, a wave file will be written to the URL you provided to the function input as a `.caf` file. `AVFoundation` has additional facilities available to convert uncompressed audio to other formats.

## Wrap Up

The majority of this post was gleaned from a few invaluable sources.

* [Multi-timbral AVAudioUnitMIDIInstrument](http://www.rockhoppertech.com/blog/multi-timbral-avaudiounitmidiinstrument/)
* [Gene De Lisa's blog](http://www.rockhoppertech.com/blog/)
* [Apple Mailing List message about MIDISynth preload](https://lists.apple.com/archives/coreaudio-api/2016/Jan/msg00023.html)
* [Using AVAudioEngine for Playback, Mixing and Recording (AVAEMixerSample)](https://developer.apple.com/library/content/samplecode/AVAEMixerSample/Introduction/Intro.html#//apple_ref/doc/uid/TP40015134-Intro-DontLinkElementID_2)

Please message me on Twitter [@twocentstudios](https://twitter.com/twocentstudios) if you have ideas for improvements.

Download my app [Photo/Phono](https://itunes.apple.com/us/app/photo-phono/id1202606014?mt=8) and share a generated MIDI file to see this code in action.




