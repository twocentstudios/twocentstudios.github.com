---
layout: post
title: "Core Location Modern API Tips"
date: 2024-12-02 22:20:00
image: /images/core-location-title-card.png
tags: apple ios ekibright
---

The Core Location framework for Apple platforms received some fresh API updates alongside even more permissions minutia in iOS 17 and iOS 18.

In this post I'll list as many gotchas as I've found in the "modern" Core Location as of iOS 18.1 while developing my train timetables app [Eki Bright](/2024/07/27/eki-bright-tokyo-area-train-timetables/). Some documented, some not. This is not a quick start or tutorial, but you may want to skim it if you're thinking about using an iOS 17+ Core Location API so you know what to look out for.

I'll be discussing iOS usage of Core Location exclusively (not macOS, visionOS, watchOS).

# Overall recommendations

## Prefer `CLLocationManager` over `CLMonitor` and `CLLocationUpdate`

`CLLocationManager` has been around since the beginning of iPhone OS. Its delegate-based API can feel a bit cumbersome in the current era, but overall, I would still recommend creating your own wrapper over `CLLocationManager` if the core competency of your app is even adjacent to location services.

As far as I can tell, `CLMonitor` and `CLLocationUpdate` are both wrappers themselves over `CLLocationManager` albeit with fewer options, fewer capabilities, and many more gotchas spread across iOS minor versions.

If you'd still like to try them, please read my observations below.

## Prefer `CLServiceSession` if your deployment target is iOS 18.0+

In my testing, `CLServiceSession` has worked as advertised and requires less babysitting than the older imperative location permission APIs.

Location services permissions is still ripe with complexity and edge cases, so I recommend reading all the documentation and my observations below.

# Official documentation

I'll start by listing the documentation for the iOS 17+ APIs I've found useful.

## WWDC videos

There are three videos from WWDC 2023 and 2024 from the Core Location team introducing iOS 17 and iOS 18 changes.

- [Discover streamlined location updates (2023)](https://developer.apple.com/videos/play/wwdc2023/10180)
- [Meet Core Location Monitor (2023)](https://developer.apple.com/videos/play/wwdc2023/10147)
- [What's new in location authorization (2024)](https://developer.apple.com/videos/play/wwdc2024/10212)

These videos do a nice job of explaining the rationale behind the new APIs. They also illustrate the intended usage pretty well for extremely simple use cases.

## Sample projects

The sample projects, although very freshly updated, do a poor job of actually proving the capabilities of the framework work as advertised. They're more useful in seeing how the API designers intend the framework user to compose all the pieces together.

- [Adopting live updates in Core Location](https://developer.apple.com/documentation/corelocation/adopting-live-updates-in-core-location)
- [Monitoring location changes with Core Location](https://developer.apple.com/documentation/corelocation/monitoring-location-changes-with-core-location)

## Warning about the documentation

Some official articles have been written or rewritten assuming your app's base deployment is iOS 17 or iOS 18. [Suspending authorization requests](https://developer.apple.com/documentation/corelocation/suspending-authorization-requests) shows only permission requests based on `CLServiceSession`.

...while some articles have not been updated. [Requesting authorization to use location services](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services) does not mention `CLServiceSession` at all.

Some newer API's documentation pages are missing important notes that exist in their deprecated counterpart API's pages. For example, [CLMonitor](https://developer.apple.com/documentation/corelocation/clmonitor-2r51v) and [startMonitoring(for:)](https://developer.apple.com/documentation/corelocation/cllocationmanager/startmonitoring(for:)).

Be sure to check the individual pages under [Deprecated symbols](https://developer.apple.com/documentation/corelocation/deprecated-symbols) as well.

# Tips

This section is an unstructured brain dump of everything I've run into while using the iOS 17+ Core Location APIs. I've divided up the subsections into:

- Permissions (`CLServiceSession`)
- Background operation
- Location updates firehose (`CLLocationUpdate`)
- Location monitoring (`CLMonitor`)

## Permissions

I recommend starting by reading [Requesting authorization to use location services](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services) carefully, and watching [What's new in location authorization](https://developer.apple.com/videos/play/wwdc2024/10212).

### Implicit vs. explicit CLServiceSession usage

In iOS 18+, `CLLocationUpdate` or `CLMonitor` allow implicit usage of permissions via the underlying `CLServiceSession` mechanism. If you're using iOS 17 or below, or using `CLLocationManager` you can skip this part.

As a pseudo flowchart:

If:

- You're only using either `CLLocationUpdate` or `CLMonitor` (not `CLLocationManager`) _and_
- You're supporting iOS 18+ _and_
- You only need `whenInUse` authorization without explicit full accuracy

Then you have 2 options:

1. Use implicit authorization: simply call `CLLocationUpdate` or `CLMonitor` and Core Location will take a `CLServiceSession` (the permissions mechanism) for you behind the scenes.
2. Use explicit authorization: add the `NSLocationRequireExplicitServiceSession` key to `Info.plist` and hold an instance of `CLServiceSession` for as long as you're getting values from `CLLocationUpdate` or `CLMonitor`.

If:

- You're only using either `CLLocationUpdate` or `CLMonitor` (not `CLLocationManager`) _and_
- You're supporting iOS 18+ _and_
- You need `always` authorization _or_ explicit full accuracy

Then:

You must take a `CLServiceSession`. You can still add `NSLocationRequireExplicitServiceSession` if you want to ensure you don't make a mistake.

### Testing the full accuracy permission prompt

One way to test the permission prompt for full accuracy usage is:

- Start a fresh copy of your app on a simulator.
- Trigger the location prompt and allow `whenInUse` permissions.
- Force quit the app.
- In the simulator's Settings.app, go to your app's settings page -> Location Services and disable Full Accuracy.
- Cold launch your app.
- Trigger your feature that requires full accuracy permissions.
- The permission prompt should appear.

{% caption_img /images/core-location-full-accuracy-prompt.jpg h380 An example of the temporary full accuracy permission prompt %}

If you approve this permission prompt it will still appear every time you trigger your feature in future cold launches (it's "temporary" after all).

### Localizing `fullAccuracyPurposeKey`

Full accuracy requests are available in two API:

- [init(authorization:fullAccuracyPurposeKey:)](https://developer.apple.com/documentation/corelocation/clservicesession-pt7n/init(authorization:fullaccuracypurposekey:))
- [requestTemporaryFullAccuracyAuthorization(withPurposeKey:completion:)](https://developer.apple.com/documentation/corelocation/cllocationmanager/requesttemporaryfullaccuracyauthorization(withpurposekey:completion:))

(This is another one of those cases where all the documentation is on the page of the deprecated API.)

I'm using `CLServiceSession` in the following manner:

```swift
CLServiceSession(authorization: .whenInUse, fullAccuracyPurposeKey: "NSLocationTemporaryUsageDescriptionDictionaryMonitor")
```

Specifying `fullAccuracyPurposeKey` tells `CLServiceSession` that the feature associated with the `CLServiceSession` instance prefers having `fullAccuracy`, and will try to prompt for it automatically when possible ("possible" being any number of rules).

The relevant part of the `Info.plist` should look like the below plist for specifying your app's reason for wanting full accuracy permission. Notice I have two different keys because I have two features that each instantiate their own `CLServiceSession`.

```xml
<plist version="1.0">
<dict>
	<key>NSLocationTemporaryUsageDescriptionDictionary</key>
	<dict>
		<key>NSLocationTemporaryUsageDescriptionDictionaryMonitor</key>
		<string>NSLocationTemporaryUsageDescriptionDictionaryMonitor</string>
		<key>NSLocationTemporaryUsageDescriptionDictionaryNearbyStations</key>
		<string>NSLocationTemporaryUsageDescriptionDictionaryNearbyStations</string>
	</dict>
</dict>
</plist>
```

If you're not localizing and have no `InfoPlist.xcstrings`, you can add the actual message you show the user to the `<string>your message</string>` part.

If you are localizing, then you should add `NSLocationTemporaryUsageDescriptionDictionaryMonitor` and `NSLocationTemporaryUsageDescriptionDictionaryNearbyStations` as keys in your `InfoPlist.xcstrings` file, with the corresponding translations.

In the above plist I've repeated the key name as the value, but it won't be used since I added the key to `InfoPlist.xcstrings`.

I've used a key name with the full prefix of the root dictionary key `NSLocationTemporaryUsageDescriptionDictionary`, but you can use any valid localization key name.

The setup is documented [in this API](https://developer.apple.com/documentation/corelocation/cllocationmanager/requesttemporaryfullaccuracyauthorization(withpurposekey:completion:)) and [in the forums](https://developer.apple.com/forums/thread/652801?answerId=624692022#624692022).

## Location updates in the background

If you need to run in the background based on location changes, you have a few requirements and a few options to consider.

- You must to add `Background Modes -> Location updates` to the `Signing & Capabilities` section of your app target.
- You must still add the proper permissions key (probably `NSLocationWhenInUseUsageDescription` or `NSLocationAlwaysAndWhenInUseUsageDescription`).
- You must have either `.whenInUse` or `.always` permission. As far as I know, `fullAccuracy` permission is not required but I imagine the lack of it would affect most features that require background location updates.
- You must either:
	- Run a Live Activity _or_
	- Create and hold an instance of [`CLBackgroundActivitySession`](https://developer.apple.com/documentation/corelocation/clbackgroundactivitysession-3mzv3) (which is conceptually a single-purpose pre-configured Live Activity).
- You must^ be subscribed to an `AsyncStream` from either a `CLLocationUpdates` of `CLMonitor` instance. (^I have not tested how the `CLLocationManager` APIs work with iOS 17+ location background APIs, so you are on your own verifying how they work.)

I want to specifically call out that `.always` permission is _not_ required to receive location updates in the background assuming the above requirements are satisfied. As discussed in [this article](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services), the main difference between `whenInUse` and `always` permission is that:

- With `always` permission, your app has the chance of being cold launched in the background in response to "significant location change, visits, and region monitoring services" if it was previously terminated.
- With `whenInUse` permission, if your app is terminated for any reason, the user must open it again before location updates may be received in the background.

Note: there's something called a [Location push service extension](https://developer.apple.com/documentation/corelocation/creating-a-location-push-service-extension) that requires `.always` permission, but I have no experience with what the other requirements are for this feature.

Relevant docs:

- [Handling location updates in the background](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background)
- [Discover streamlined location updates](https://developer.apple.com/videos/play/wwdc2023/10180)
- [Requesting authorization to use location services](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services)

## The location updates firehose (`CLLocationUpdate`)

`CLLocationUpdate.liveUpdates` returns a stream of both location coordinates, "errors", and permissions issues in the form of the `CLLocationUpdate` struct.

Although in theory the API is more streamlined for the simplest of use cases, I'd generally still recommend creating your own system around `CLLocationManager` if you're doing anything that requires stability, robustness, or reliability with Core Location. Regardless, some usage notes for `CLLocationUpdate` are below.

### iOS 18+ recommended

Although `CLLocationUpdate` was introduced in iOS 17, I don't recommend using it until iOS 18 for the following reasons:

In my testing, `CLLocationUpdate.liveUpdates` will return no results on iOS 17 when `fullAccuracy` permission is denied. I have no idea whether this was related to the permissions system and fixed in iOS 18 alongside `CLServiceSession` or whether it was simply a bug, but iOS 18 has the expected behavior of returning less accurate `CLLocationUpdate` results when `fullAccuracy` is denied by the user.

According to the WWDC video, when background usage is not requested by the app, Core Location handles automatically disabling `CLLocationUpdate.liveUpdates` when going to the background and re-enabling it when coming back into the foreground, but only in iOS 18 alongside `CLServiceSession`. I can't say for sure how it works in iOS 17, only that my view layer was handling this manually to make sure there were no issues.

`CLLocationUpdate` does not include any properties for permissions or other errors in iOS 17 (e.g. `authorizationDenied`, `locationUnavailable`).

Not a huge issue by any means, but `CLLocationUpdate.isStationary` was introduced in iOS 17 and deprecated in iOS 18 and renamed to `CLLocationUpdate.stationary`.

### `stationary` is rarely set (when the app is in the foreground?)

The `stationary` flag is set "on the last update before updates are paused because the device has stopped moving" according to the [WWDC video](https://developer.apple.com/videos/play/wwdc2024/10212?time=1003).

What "stopped moving" means is not explicitly documented.

In practice I've never seen an update with the `stationary` flag set to `true`. Based on hints from the WWDC videos, my hypothesis is that `stationary` is most relevant when using `CLLocationUpdate` and your app is in the background. Perhaps in that setting, Core Location will offer fewer updates and set the `stationary` flag more liberally.

### `CLLocationUpdate` has no concept of filtering

The "old" API `CLLocationManager` has `distanceFilter` and `desiredAccuracy` you can use to have Core Location filter updates on your behalf.

`CLLocationUpdate` does not have these options. You have to do filtering on the stream yourself.

Perhaps the `CLLocationUpdate.LiveConfiguration` values are supposed to influence this instead.

### `CLLocationUpdate.locationUnavailable` is unpredictable

`locationUnavailable` was introduced in iOS 18. Previously, a `CLLocationUpdate` could only have a `location == nil`.

I expected `locationUnavailable` to be useful as a way to change my UI and alert my users that there may be a temporary issue with getting their location.

In practice, the behavior changed in iOS 18.1 and `locationUnavailable` updates would be returned in quick succession and interspersed with normal location updates under what I'd consider ideal device conditions. It caused my UI to flicker in distressing ways (nod to SwiftUI) and was unpredictable enough to be hard to filter manually.

For now, I've started ignoring `locationUnavailable` updates completely. I'll probably revisit it again in iOS 19 to see whether it's stable enough to positively influence the UX.

### Updates are returned about 1 or 2 times per second

I haven't seen any official documentation about the update interval from `CLLocationUpdate.liveUpdates`. In practice I usually see updates on average of about 1 or 2 per second while in the foreground. It's similar on device and on the simulator. Just an FYI.

### Background behavior of `CLLocationUpdate`

I don't (yet) have a feature that uses `CLLocationUpdate` in the background so my testing has been light. But I can report that I've seen `CLLocationUpdate` send results while in the background as long as the app has been configured properly for it (see the above "Location updates in the background" section).

## Location monitoring (`CLMonitor`)

### Documented limitations

[Source](https://developer.apple.com/documentation/corelocation/cllocationmanager/startmonitoring(for:)) for most of the below quotes:

> An app can register up to 20 regions at a time.

From my testing in iOS 18.1, if you add more than 20, the `CLMonitor` will emit one event for each condition over the limit with state `CLMonitor.Event.State.unmonitored`.

According to the WWDC video, `CLMonitor.Event.conditionLimitExceeded` should also be set in this case, although I haven't confirmed this.

> The region monitoring service requires network connectivity.

However, a note from [startMonitoringSignificantLocationChanges](https://developer.apple.com/documentation/corelocation/cllocationmanager/startmonitoringsignificantlocationchanges()) says that "If the device is able to retrieve data from the network, the location manager is much more likely to deliver notifications in a timely manner."

So maybe network connectivity isn't always required?

> an app can expect to receive the appropriate region entered or region exited notification within 3 to 5 minutes on average, if not sooner.

This is more or less what I've experienced in my testing, with the simulator reporting slightly less on average than the device. It makes testing difficult and also makes it difficult to ensure my feature reacts predictably in the background.

> In iOS 6, regions with a radius between 1 and 400 meters work better on iPhone 4S or later devices.

Since this hasn't been updated since iOS 6, the only other advice I've found was in [this forums thread](https://developer.apple.com/forums/thread/757363?answerId=791471022#791471022) where an Apple engineer says to be careful about making the regions too small:

> Also, I wonder if your regions are appropriately large. If you are getting significant location updates every 5 miles, that means you are in an area where the mobile/wifi based signal coverage (which these services depend on) is only adequate for that kind of accuracy. If your region radii are smaller than what the horizontalAccuracy the significant location updates provide, you may actually miss the entry or exit events to those smaller regions.

The above quote broadly references a note buried in the [startMonitoringSignificantLocationChanges](https://developer.apple.com/documentation/corelocation/cllocationmanager/startmonitoringsignificantlocationchanges()) documentation:

> Apps can expect a notification as soon as the device moves 500 meters or more from its previous notification.

### CLMonitor on the iOS simulator

I had varying success using `CLMonitor` on the iOS 18.1 simulator alongside active location simulation using a GPX file (discussed later). It was a flakey enough that I'd recommend using a real device, although using one was only slightly more successful in verifying `CLMonitor` usage.

### CLMonitor.Event.State values

[CLMonitor.Event.State](https://developer.apple.com/documentation/corelocation/clmonitor-2r51v/event/state-swift.typealias) is an alias for the undocumented `__CLMonitoringState`. I can only access the values occasionally via autocomplete:

My understanding of the 4 states is:

- `unknown`: the initial state of the condition unless otherwise specified at the `add` callsite.
- `unmonitored`: I believe this is only used when there are too many conditions (over the 20 limit) and `CLMonitor` is reporting which conditions will not be monitored.
- `unsatisfied`: the device is outside the condition region.
- `satisfied`: the device is inside the condition region.

### How to set up `CLMonitor`

When using `CLMonitor` (on iOS 18+) you need to manage the lifetime of multiple objects:

- A `CLServiceSession` for ensuring Core Location knows your permission goals.
- A named `CLMonitor` instance for registering conditions.
- A `Task` that awaits `await monitor.events`.

If your requirements are simple – for example, you're only monitoring a static condition – you can do all this setup in one place and then tear everything down when cancelling the `monitor.events` stream.

My requirements are more complicated. The user can modify their route at any time, which triggers a full update of which conditions are monitored. The route may be discarded, at which point I need to stop all monitoring completely.

If the conditions you need to monitor change unpredictably, I recommend the following pseudocode when changing monitored conditions:

- If there are no more conditions to monitor:
	- Cancel any existing `Task` you have monitoring events already.
	- If a monitor exists, remove all conditions from it, and `nil` it out.
	- Call `invalidate` and  `nil` out the `CLBackgroundActivitySession` if it exists.
	- `nil` out the `CLServiceSession` if it exists.
- Otherwise:
	- Create a `CLServiceSession` if one does not already exist.
	- Create a `CLBackgroundActivitySession` if one does not already exist and you want monitoring to keep your `whenInUse` authorized app alive in the background without a dedicated Live Activity.
	- Create a `CLMonitor` with a static name if one does not already exist.
	- Calculate which identifiers you need to add and which ones you need to remove (or simpler: remove all conditions and add all new ones)
	- Remove unused conditions
	- Add new conditions
	- If a monitoring `Task` exists, do nothing.
	- Otherwise, start a new `Task` awaiting `CLMonitor.events` and save a reference to the `Task`.

### Tips for creating a system around CLMonitor

#### You should target iOS 18+

You can technically use `CLMonitor` with iOS 17, but handling permissions will be either be more complicated or less robust without `CLServiceSession` (iOS 18+).

#### You _need_ to keep a reference to `CLServiceSession`, `CLMonitor`, and the `Task` that contains your monitoring

This is because:

The `CLServiceSession` defines the authorization requirements of your use of location services for the lifetime of your feature that uses them.

It is dangerous to try to "recover" a `CLMonitor` with the same name via the initializer if you lose the reference. This means that `CLMonitor` is not designed to be cheaply created and discarded. I tried this strategy at first: create a monitor and discard the old one each time my conditions changed. However, the internal bookkeeping done by Core Location means that the `CLMonitor` may outlive your expectations. This means that if you try to initialize a `CLMonitor` with the same name too soon after you've discarded one, the app will crash with:

```
Assertion failure in +[CLMonitor _requestMonitorWithConfiguration:locationManager:completion:], CLMonitor.mm:517
Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Monitor named myMonitor is already in use'
```

From my testing, it seems best to subscribe to `CLMonitor.events` once and only once per instance of `CLMonitor` over the `CLMonitor`'s entire lifetime. Let me try to explain this thoroughly.

- You have a `CLMonitor`
- You add some conditions to the `CLMonitor`
- You subscribe to `CLMonitor.events`
- Now you want to change the conditions

At this point, you should keep the same `CLMonitor` and the subscription to `CLMonitor.events` alive and call `CLMonitor.add` and `CLMonitor.remove` as necessary.

The other reason it's "better" to do diffing and only add/remove conditions as necessary is because `CLMonitor` keeps some state on your behalf as illustrated by the `CLMonitor.record(for:)` API that returns a `CLMonitor.Record.lastEvent`.

#### Do not treat `CLMonitor` as cheaply disposable

You _should not_ discard the `CLMonitor` and immediately create a new one with the same name (crash described above) and you _should not_ cancel the subscription and create a new subscription.

`CLMonitor` has a bug (I presume) where any later subscription attempt to `CLMonitor.events` after the first has been cancelled will itself cancel and fall through immediately.

#### Do not subscribe to `CLMonitor` multiple times simultaneously

You _should not_ try to subscribe to the same `CLMonitor` multiple times for whatever reason you might want to do that. In my testing, events will be pushed out randomly between subscriptions. This may be a standard `AsyncStream` behavior, but regardless, I can't think of a reason why you'd want this behavior unless you were building some sort of system of distributed workers.

#### You _may_ tear down the system and stop monitoring completely, while still being able to recreate the system later

OK, so what about the situation where you _do_ want to completely stop monitoring but also retain the ability to start monitoring again later?

The "stop monitoring for now" situation should be covered by the above pseudocode. As long as you do the proper cleanup of cancelling the subscription, removing conditions from the `CLMonitor`, and removing your reference to the `CLMonitor` and `CLServiceSession` you should be set up fine to recreate the entire system at some later point (but _not_ right away, with "right away" meaning at least in the same run loop).

#### Define your system as an actor

`CLMonitor` is an `actor`, which means that basically every one of its APIs requires an `await`. I found it more idiomatic and convenient to define my wrapper system as an `actor`.

#### Reinitializing the system in a terminated/cold launch scenario

There are specific requirements around reinitializing a `CLMonitor` system after the app has been terminated. My use case doesn't require this functionality, and therefore my implementation does not handle it. If you do need to handle it (and have `.always` authorization), I encourage you to read [the docs](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background), [sample code](https://developer.apple.com/documentation/corelocation/monitoring-location-changes-with-core-location), and watch [the WWDC video](https://developer.apple.com/videos/play/wwdc2023/10147/).

#### Be careful about running multiple `CLMonitor` instances simultaneously

In theory, it should be fine to create multiple `CLMonitor` instances within the same app session. However, the "up to 20 conditions" limitation is per-app, so with multiple `CLMonitor`s you will need to ensure globally you're not exceeding that limit (if your use case has a danger of doing so).

I haven't tested running multiple `CLMonitor`s in parallel, so your milage my vary.

### `CLMonitor` wrapper sample code

Below is a lightly tested implementation of the above pseudocode based on my app's own implementation. I'd encourage you to use it only as reference when writing your own implementation based on your own app's requirements and testing it accordingly.

This implementation assumes you've set up the rest of your project correctly with permissions strings, background modes, etc.

This implementation allows you create an instance of `SampleLocationMonitor` with the same lifetime as your app (read: singleton). Call `monitor()` each time your set of conditions changes. If the input set of conditions is empty, the instance will go dormant, otherwise it will update the conditions interactively.

This implementation also supports background operation via `CLBackgroundActivitySession`. You should remove this if you already have a Live Activity tied to the lifetime of your monitoring. Or remove it if you don't need any updates in the background.

The missing piece (see "TODO" below) is what you want to do in response to receiving an event. In my case (not shown), I'm simply refreshing a Live Activity based on an existing schedule.

If you want access to all events, I would be careful about modifying this to return the `monitor.events` `AsyncStream` directly because of the limitations discussed above, namely: there can only be one subscription per `CLMonitor` _and_ you cannot cancel a subscription and create a new one later.

Instead, I'd consider either:

- Registering a closure along side each `MonitorCondition` for the `SampleLocationMonitor` to execute (this may be difficult to design due to Swift 6 concurrency isolation).
- Creating a long-lived `AsyncStream` as a property of and bound to the lifetime of `SampleLocationMonitor` that relays all events to a subscriber.

I haven't tested either strategy, so your milage my vary.

Anyway, here is the sample implementation:

```swift
struct MonitorCondition: Identifiable, Equatable, Sendable, Hashable {
    let id: String
    let coordinates: CLLocationCoordinate2D
    let radiusInMeters: CLLocationDistance
}

@available(iOS 18.0, *)
actor SampleLocationMonitor {
    private var authSession: CLServiceSession?
    private var monitor: CLMonitor?
    private var backgroundSession: CLBackgroundActivitySession?
    private var monitoringTask: Task<Void, any Error>?
    
    private static let monitorID = "monitor"

    func monitor(_ monitorConditions: Set<MonitorCondition>) async throws {
        guard !monitorConditions.isEmpty else {
            monitoringTask?.cancel()
            monitoringTask = nil
            if let monitor {
                let monitoringIdentifiers = await monitor.identifiers
                for identifier in monitoringIdentifiers {
                    await monitor.remove(identifier)
                }
                self.monitor = nil
            }
            backgroundSession?.invalidate()
            backgroundSession = nil
            authSession = nil
            return
        }
        
        let authSession = authSession ?? CLServiceSession(authorization: .whenInUse, fullAccuracyPurposeKey: "NSLocationTemporaryUsageDescriptionDictionarySampleLocationMonitor")
        self.authSession = authSession
        
        backgroundSession = backgroundSession ?? CLBackgroundActivitySession()
        
        let monitor: CLMonitor
        if let existingMonitor = self.monitor {
            monitor = existingMonitor
        } else {
            let newMonitor = await CLMonitor(Self.monitorID)
            monitor = newMonitor
            self.monitor = monitor
        }
        
        assert(monitorConditions.count <= 20, "CLMonitor supports up to 20 conditions")
        
        let existingIdentifiers = await Set(monitor.identifiers)
        let identifiersToAdd: Set<String> = Set(monitorConditions.map(\.id)).subtracting(existingIdentifiers)
        let identifiersToRemove: Set<String> = existingIdentifiers.subtracting(Set(monitorConditions.map(\.id)))
        
        for identifierToRemove in identifiersToRemove {
            await monitor.remove(identifierToRemove)
        }
        for monitorCondition in monitorConditions {
            guard identifiersToAdd.contains(monitorCondition.id) else { continue }
            let condition = CLMonitor.CircularGeographicCondition(center: monitorCondition.coordinates, radius: monitorCondition.radiusInMeters)
            await monitor.add(condition, identifier: monitorCondition.id, assuming: .unsatisfied)
        }
        
        guard self.monitoringTask == nil else { return }
        let monitoringTask = Task {
            for try await event in await monitor.events {
                // Optional: the last event if you need to do comparisons to derive _entry_ or _exit_ events.
                let lastEvent = await monitor.record(for: event.identifier)?.lastEvent

                // TODO: Do whatever you want to do with the events here
            }
        }
        self.monitoringTask = monitoringTask
    }
}
```

## Testing

### Simulating a moving location

I had some success using simulated location changes via GPX files. It works on both simulator and device.

The GPX file playback starts immediately on app launch. The file playback will repeat immediately after reaching the last entry.

I used this tutorial: [Simulating A Moving Location In iOS](https://digitalbunker.dev/simulating-a-moving-location-in-ios/).

### Fixing issue where GPX files cannot be selected in the file picker in Xcode

A strange issue blocked me from using location simulation at first.

In the file picker that appears when selecting "Add GPS Exchange to Project" in the Scheme editor, all GPX files would be greyed out and unselectable. The issue appeared in a few random Stack Overflow and forum posts scattered across several years.

Eventually I tracked it down to an app I had installed called Guitar Pro asserting ownership over `.gpx` files in macOS system wide. I confirmed this with the `mdls` CLI utility (output abridged for clarity):

```bash
$ mdls basha-yoko.gpx

_kMDItemDisplayNameWithExtensions  = "basha-yoko.gpx"
kMDItemContentCreationDate         = 2024-11-30 03:31:08 +0000
kMDItemContentType                 = "com.arobas-music.guitarpro6.document"
kMDItemContentTypeTree             = (
    "com.arobas-music.guitarpro6.document",
    "public.data",
    "public.item"
)
kMDItemDisplayName                 = "basha-yoko.gpx"
kMDItemDocumentIdentifier          = 57051
kMDItemKind                        = "Guitar Pro 6 document"
```

Uninstalling Guitar Pro was the only thing that fixed it long enough for me to select one file. After I restarted my computer, the file picker was broken again.

For anyone else suffering with this issue, you may be able to fix it by opening your `.xcscheme` file (sometimes embedded in the `.xcodeproj` or `.xcodeworkspace` bundle) and adding the following xml when `locations.gpx` is in the same folder as your `.xcodeproj`. Basically, the file path of `identifier` is in reference to the `.xcscheme` file, which in my case is two folders deep inside the `.xcodeproj` bundle.

```xml
<LocationScenarioReference
    identifier = "../../locations.gpx"
    referenceType = "0">
</LocationScenarioReference>
```

The only way to tell if it's working is by running it on the simulator and seeing it the location updates are played back as you'd expect. For me, Xcode still wouldn't show the GPX file as active in its UI.

I don't think your GPX file needs to be added to the `.xcodeproj` but I'm not 100% sure.

Reference: [Apple forums](https://forums.developer.apple.com/forums/thread/686875)

# Conclusion

I hope this post will help those in the Core Location avant-garde.

Core Location is an important part of my app, but I still have many other features to manage, so although I'll try to update this post with any new behavior I discover, I also welcome any well-researched tips or links to related blog posts. Feel free to send them over.
