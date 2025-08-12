---
layout: post
title: "3 Swift Concurrency Challenges from the Last 2 Weeks"
date: 2025-08-12 11:38:00
tags: apple ios swift concurrency
---

I started my Apple platforms development journey a year before [Grand Central Dispatch](TODO) was released with iOS 4. I've lived through codebase migrations to [NSOperation](https://nshipster.com/nsoperation/). Then through the slew of FRP frameworks (of which I consider a concurrency solution): [ReactiveCocoa](TODO), [ReactiveSwift](TODO), [RxSwift](TODO), and finally [Combine](TODO).

My strategy for learning all these paradigms was best described as osmosis while encountering and solving real problems in codebases. Of course, you have to spend time setting breaking points and patiently stepping through with a debugger to see where all the thread hops are happening. Eventually, I reached the point where I could read code and predict which threads each section would run on. I had 80% of the operators memorized and knew exactly where in the docs to look for the remaining 20%.

Years in, that kind of confidence has eluded me so far with Swift Concurrency. I cannot yet read a snippet of code and predict what the call stack will look like. I haven't memorized enough of the syntax to formulate solutions in my head and write it fluently. I don't have a go-to location in the docs to find the primitive at the tip of my tongue.

I ask myself, why is my Swift Concurrency upskilling story so different?

Is the difference that GCD, NSOperation, and the reactive frameworks basically came out of the gate fully baked? Their paradigms may have merits and demerits, but after their first releases, anything new was additive or syntactic sugar. They were born as ugly as they'd always be.

Is it that my confidence was actually unearned and I never *really* understood what was happening in my code? The kind of bugs that Swift Concurrency aims to solve are often so rare that you can go a whole career without being able to recognize the symptoms.

Is it that Swift Concurrency promises a higher level of abstraction (isolation domains instead of threads), but is so leaky that the programmer now has to understand both the abstraction and the paradigm it's abstracting?

With that preface, I want to look at a few examples of Swift Concurrency challenges I've encountered recently. Let's see if these shed any light on why I'm finding it so hard to develop intuition.

Unlike most of my posts (I hope), these examples are unsolved problems with likely broken code.

## 1. UNNotificationCenter

I implemented push notifications in [Technicolor](TODO). I already had an overall architecture I was happy with, but elegantly massaging push notification support into it took some effort. I finally ended up with an implementation I thought I understood that still properly handled the multiple delegate callback points across `UIApplicationDelegate` via `@UIApplicationDelegateAdaptor` and `UNNotificationCenter`.

Besides the push token registration and user permissions, the key functionality of my push notifications wrapper client is to open the screen of the app that corresponds with the type of push notification the user tapped.

As far as I can tell, `UNNotificationCenter` has no documented concurrency story. Each developer that sets out to use the framework has to derive what thread each delegate method is called on through trial and error on a real device in production by tapping production push notifications. We haven't even started talking about Swift Concurrency yet.

To bring `User Notifications` framework into the concurrency world, each developer needs to start from zero, with zero guarantees and zero support from Apple.

So I started with this (simplified) implementation:

```swift
// Version 1
final class PushNotificationDelegateProxy: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private var notificationTapHandler: ((PushNotificationPayload) -> Void)?

    func setNotificationTapHandler(_ handler: @escaping (PushNotificationPayload) -> Void) {
        notificationTapHandler = handler
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        let payload = // Decode payload
        notificationTapHandler?(payload)
    }
}

@MainActor @Observable final class PushNotificationSettingsStore: Identifiable {
    @ObservationIgnored @Dependency(\.pushNotificationClient) var pushNotificationClient

    init() {
        pushNotificationClient.setDelegate()

        conditionallyRegisterForRemoteNotifications()

        // Set the notification tap handler
        pushNotificationClient.setNotificationTapHandler { [weak self] payload in
            Task { @MainActor in
                self?.actions.notificationReceived(payload)
            }
        }
    }
}
```

In my initial understanding, no matter what thread `userNotificationCenter(didReceive:)` called the `notificationTapHandler` closure, inside it the closure `notificationReceived(payload)` would be called on the main thread and could do any UI operations it needed to.

From what I remember, I confirmed this as working during debug on device. When I was running in production on TestFlight it crashed when I opened a push notification.

Still unsure as to why (was it that `@MainActor`-isolated `self` was captured inside a non-isolated closure), I added some code that, although inelegant, would surely fix the problem:

```swift
// Version 2
final class PushNotificationDelegateProxy: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private var notificationTapHandler: ((PushNotificationPayload) -> Void)?

    func setNotificationTapHandler(_ handler: @escaping (PushNotificationPayload) -> Void) {
        notificationTapHandler = handler
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        let payload = // Decode payload
        await MainActor.run {
        	notificationTapHandler?(payload)
        }
    }
}
```

Just sprinkle in `MainActor.run` everywhere, right? Just like back in the `DispatchQueue.main` days.

This also crashed (every time) in production, with the following stack trace:

```
Triggered by Thread:  5

Last Exception Backtrace:
0   CoreFoundation                	0x184a5721c __exceptionPreprocess + 164 (NSException.m:249)
1   libobjc.A.dylib               	0x181ef1abc objc_exception_throw + 88 (objc-exception.mm:356)
2   Foundation                    	0x183d55670 -[NSAssertionHandler handleFailureInMethod:object:file:lineNumber:description:] + 288 (NSException.m:252)
3   UIKitCore                     	0x1883ad4e8 -[UIApplication _performBlockAfterCATransactionCommitSynchronizes:] + 276 (UIApplication.m:3408)
4   UIKitCore                     	0x1883bdecc -[UIApplication _updateStateRestorationArchiveForBackgroundEvent:saveState:exitIfCouldNotRestoreState:updateSnapshot:windowScene:] + 528 (UIApplication.m:12129)
5   UIKitCore                     	0x1883be278 -[UIApplication _updateSnapshotAndStateRestorationWithAction:windowScene:] + 144 (UIApplication.m:12174)
6   technicolortv                 	0x1027d6670 @objc closure #1 in PushNotificationDelegateProxy.userNotificationCenter(_:didReceive:) + 80 (/<compiler-generated>:0)
// ...
12  libswift_Concurrency.dylib    	0x190521241 completeTaskWithClosure(swift::AsyncContext*, swift::SwiftError*) + 1 (Task.cpp:537)
```

State restoration somehow got triggered off the main thread? How? I guess I could understand if the problem were that `notificationTapHandler` is unsafe to be passed between isolation domains. But that's not what the crash is saying is it?

Let's push the isolation annotations even further:

```swift
extension UNUserNotificationCenter: @retroactive @unchecked Sendable {}
extension UNNotificationResponse: @retroactive @unchecked Sendable {}

final class PushNotificationDelegateProxy: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private var notificationTapHandler: (@MainActor (PushNotificationPayload) -> Void)?

    func setNotificationTapHandler(_ handler: @escaping @MainActor (PushNotificationPayload) -> Void) {
        notificationTapHandler = handler
    }

    @MainActor func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        let payload = // Decode payload
        notificationTapHandler?(payload)
    }
}
```

Let's try to force `userNotificationCenter(didReceive:)` to be called on the `@MainActor` by lying to the compiler in a bunch of places about sendability.

As far as I can tell, this no longer crashes although I haven't had time to thoroughly test it (since it requires multiple deployments to Test Flight and review cycles to extensively QA).

From this whole weeks-long process, I've learned essentially nothing about the proper usage of Swift Concurrency, my mental model is less well-formed than it used to be, and I still have a lingering problem that I cannot practically devote enough time to comprehensively solve right now.

Presumably no one at Apple is working on the User Notifications framework anymore. Nothing is being added to it. No one is giving it concurrency support. No one *has* (over the past decade and a half) or *will* document its concurrency story. The best we have is a [Stack Overflow post](https://stackoverflow.com/questions/73750724/how-can-usernotificationcenter-didreceive-cause-a-crash-even-with-nothing-in) with no unanimous best practice and no solution.

## 2. CMMotionActivityManager

[Core Motion](TODO) is another neglected framework that not many iOS devs have the pleasure of integrating. It seems to have mostly been "modernized" around iOS 7 when `NSOperation` had a small popularity bump. Also when the API best practices for getting permission from the device user were still being tweaked.

For a current project, I'm using [`CMMotionActivityManager`](TODO). It's a slightly higher-level data source for predicting whether the device is held by a user walking, cycling, driving, standing still, etc. It has two primary APIs:

- Request historical data for a time range (up to 1 week ago): [`queryActivityStarting(from:to:to:)`]()
- Get live streaming data while the app is in the foreground: [`startActivityUpdates(to:)`]()

`queryActivityStarting` returns once to the `OperationQueue` specified in the parameters. `startActivityUpdates` keeps returning values until `stopActivityUpdates()` is called.

I thought each of these would be relatively straightforward to wrap into a `withCheckedContinuation` and `AsyncStream`, respectively.

```swift
// Version 1: queryActivityStarting
Task { @MainActor [weak self] in
    guard let self else { return }

    // Check motion history for timeout
    let timeout = await withCheckedContinuation { continuation in
        activityManager.queryActivityStarting(
            from: startDate,
            to: endDate,
            to: OperationQueue.main
        ) { activities, error in
            guard let activities, error == nil else {
                continuation.resume(returning: nil)
                return
            }
            
            let value = // do work here to calculate timeout...
            continuation.resume(returning: value)
        }
    }
    
    // ...
}
```

My strategy recently has been the same as the Swift team's: isolate everything on the `@MainActor` unless there's a reason not to. So that's what I did in this case. However, is it correct to await with a `MainActor`-isolated `Task` while also having the `queryActivityStarting` function return on `OperationQueue.main`?

It seemed like it was working fine in debug, but then when I was field testing I was observing what seemed to be deadlocks and the continuation never completing.

So I'm already having trouble reliably reproducing the bug. I'm not even sure whether the bug is related to concurrency or whether `queryActivityStarting` just doesn't respond the way I'd expect. After all, there's a note in the docs that could be interpreted a number of ways:

> This method runs asynchronously, returning immediately and delivering the results to the specified handler block. **A delay of up to several minutes in reported activities is expected.**

In the end, I created this extension that forces `@MainActor` at the function level and includes a timeout just in case. It seems to work so far.

```swift
extension CMMotionActivityManager {
    @MainActor func activities(from start: Date, to end: Date, timeout: TimeInterval) async throws -> [CMMotionActivity]? {
        try await withThrowingTaskGroup(of: [CMMotionActivity]?.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    self.queryActivityStarting(from: start, to: end, to: .main) { activities, error in
                        switch (activities, error) {
                        case let (_, err?):
                            continuation.resume(throwing: err)
                        case let (list?, nil):
                            continuation.resume(returning: list)
                        default:
                            continuation.resume(returning: [])
                        }
                    }
                }
            }

            group.addTask {
                try? await Task.sleep(for: .seconds(timeout))
                return nil
            }

            guard let result = try await group.next() else {
                return nil
            }

            group.cancelAll()
            return result
        }
    }

    @MainActor func activityUpdates() -> AsyncStream<CMMotionActivity> {
        AsyncStream { continuation in
            startActivityUpdates(to: .main) { activity in
                guard let activity else {
                    continuation.finish()
                    return
                }
                continuation.yield(activity)
            }

            continuation.onTermination = { @Sendable _ in
                self.stopActivityUpdates()
            }
        }
    }
}
```

Again, I feel as if I've learned nothing. I have potentially worse intuition than I started with, and I may have to return to this problem again after I've released to production.

## 3. Actor Reentrancy

I've been working on a meatier problem within [Eki Live](TODO) for a couple months.

I have the following pipeline:

- Core Location produces `CLLocation` values up to 1 per second.
- `CLLocation`s are passed to an `actor RailwayTracker` which processes them using various info from a database and incorporates that data into the actor long-term state.
- `RailwayTracker` returns a value that is displayed in the UI via SwiftUI and can also update a LiveActivity.

Essentially:

```
CLLocationManagerDelegate -> RailwayTracker -> ContentView
```

The actual architecture is a bit more complex due the relationship between instances of classes doing each part of the work. But the overall pipeline design has always felt precarious due to the underlying assumptions that:

- Core Location will never produce `CLLocation` values faster than RailwayTracker can process them.
- `RailwayTracker` will always process inputs in order, serially.
- SwiftUI will receive outputs from `RailwayTracker` no faster than it can display them.

In practice, I was probably breaking at least the first constraint during testing, since I could simulate `CLLocation`s being produced at 20x real-time speed in a separate macOS app I was using to iterate on the algorithm within `RailwayTracker`.

When originally designing `RailwayTracker`, an `actor` seemed like the obvious choice. I wanted a separate isolation for its internal state and I knew it'd be doing enough heavy work that it wasn't feasible to do on the main actor.

However, I misinterpreted the behavior `actor`, thinking that an actor *also* ensured that an instance's functions would be need to complete before they could be called again. In practice, `actor`s don't do anything to prevent [reentrancy](https://mjtsai.com/blog/2024/07/29/actor-reentrancy-in-swift/).

Meaning that the input locations could be being processed out-of-order by the actor with the database operations being interleaved and there being all kinds of chaos and unspecified behavior.

While doing some new work on the project, I wanted to take another stab at hardening the entire pipeline using Swift Concurrency.

I researched the current state of the Apple officially-sanctioned [swift-async-algorithms](https://github.com/apple/swift-async-algorithms) package. It seemed to be in committee-hell with no real forward progress in the last 2+ years. There's less than half of the `Combine` operator API implemented. There's something called an [`AsyncChannel`](https://github.com/apple/swift-async-algorithms/blob/main/Sources/AsyncAlgorithms/AsyncAlgorithms.docc/Guides/Channel.md). Would that be a good primitive to base my pipeline on?

I decided on my specification:

- CLLocation's should never be dropped.
- CLLocation's should always be fully processed one-by-one in the order they arrive.
- Pipeline output results should be delivered to one "subscriber" (mixing metaphors here), but I may need multiple in the near future.

I ended up with a generic wrapper abstraction called `SerialProcessor`:

```swift
final class SerialProcessor<Input: Sendable, Output: Sendable> {
    typealias Process = @Sendable (Input) async -> Output

    // Inbound (sync) and outbound (single-consumer) pipes
    private let inPair: (stream: AsyncStream<Input>, continuation: AsyncStream<Input>.Continuation)
    private let outPair: (stream: AsyncStream<Output>, continuation: AsyncStream<Output>.Continuation)

    private let worker: Task<Void, Never>
    private let process: Process

    /// Single-consumer stream of `Output`.
    var results: AsyncStream<Output> { outPair.stream }

    init(
        inputBuffering: AsyncStream<Input>.Continuation.BufferingPolicy = .unbounded,
        outputBuffering: AsyncStream<Output>.Continuation.BufferingPolicy = .unbounded,
        process: @escaping Process
    ) {
        self.process = process

        let inPair = AsyncStream.makeStream(of: Input.self, bufferingPolicy: inputBuffering)
        let outPair = AsyncStream.makeStream(of: Output.self, bufferingPolicy: outputBuffering)
        self.inPair = inPair
        self.outPair = outPair

        worker = Task {
            for await input in inPair.stream {
                let output = await process(input)
                outPair.continuation.yield(output)
            }
            outPair.continuation.finish()
        }
    }

    deinit {
        finish()
    }

    func submit(_ input: Input) {
        inPair.continuation.yield(input)
    }

    func finish() {
        inPair.continuation.finish()
        worker.cancel()
    }
}
```

I couldn't use `AsyncChannel` for the input side because its `send` function is `async` and therefore requires an async context. I don't have that inside the `CLLocationManagerDelegate` callback function that delivers `CLLocation`s and creating a new `Task` for each new `CLLocation` would break the serial ordering guarantee.

In the non-realtime system implementation, usage looks like this:

```swift
// Set up the processing
let railwayTracker = RailwayTracker(railwayDatabase: database)
let serialProcessor = SerialProcessor(
    inputBuffering: .unbounded,
    outputBuffering: .unbounded,
    process: { @Sendable input in
        await railwayTracker.process(input)
    }
)

// Queue all locations immediately for processing
// This is in a `Task` so it will run after `serialProcessor.results` is set up
Task {
    for location in locations {
        serialProcessor.submit(location)
    }
}

// Cache the results as they arrive
for await result in serialProcessor.results {
    resultsCache[result.location.id] = result
}
```

In the realtime system version, I believe the implementation will look something like this (although I'm not at this point in the project yet):

```swift
// Set up the processing global
let railwayTracker = RailwayTracker(railwayDatabase: database)
let serialProcessor = SerialProcessor(
    inputBuffering: .unbounded,
    outputBuffering: .bufferingNewest(1), // for UI, drop late values
    process: { @Sendable input in
        await railwayTracker.process(input)
    }
)

// Where we receive new locations from the system
extension LocationManagerDelegate: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    	// Get the shared `serialProcessor` from somewhere global then...
    	for location in locations {
			serialProcessor.submit(location)
		}
	}
}

// In some View Model...
@MainActor @Observable final class ContentViewModel {
	@ObservationIgnored let serialProcessor: SerialProcessor<CLLocation, RailwayTrackerResult>
	private(set) var latestResult: RailwayTrackerResult?

	func task() async {
		for await result in serialProcessor.results {
		    latestResult = result
		}
	}
	
	// ...
}
```

In my testing of the non-realtime setup, the system seemed to work correctly. It buffers inputs as expected, and even drops outputs if I use `.bufferingNewest(1)`.

I'm still actively working on this problem (and should be doing so right now instead of writing this post).

There are other libraries like [AsyncExtensions](https://github.com/sideeffect-io/AsyncExtensions) that build on the Swift primitives. However, getting my head around the shape of the problems they can solve and what I can accomplish with the primitives has been tough.

## Final thoughts and complaints

Swift Concurrency is just such a bummer. We still need to know about lower-level primitives like locks and mutexes and threads. We still need to have working knowledge of past solutions like Grand Central Dispatch in order to interact with our own and Apple's legacy APIs. Unlike previous solutions, there are fewer primitives for managing serial vs. concurrent processing. It adds a new abstraction layer and several new concepts (isolation, actors, structured/unstructured) that probably will make sense eventually but don't right now. It adds a dozen new keywords with more essential ones arriving with each new point update. It's difficult or impossible to find sanctioned sample code that provides a glimpse into what a "best practice" could be. We're still not safe from runtime crashes. 

I could keep going but I'm tired of complaining. I just want to have the confidence to write my features without having to budget multiple days of field testing and debugging time and reading the Swift forums.

