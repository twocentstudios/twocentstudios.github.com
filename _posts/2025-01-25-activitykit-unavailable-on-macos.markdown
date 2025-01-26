---
layout: post
title: "Fixing the Crash: ActivityKit is Unavailable on macOS"
date: 2025-01-25 11:10:00
image: /images/activity-kit-macos-link-optional.png
tags: apple ios ekibright
---

If you have an iOS app that:

- supports "Designed for iPad" or "Designed for iPhone" and is on the Mac App Store (or is otherwise available on macOS)
- uses the ActivityKit framework

Then your app will crash on macOS when you reference an ActivityKit symbol (through at least iOS 18.2).

{% caption_img /images/activity-kit-macos-crash.png h250 Welcome to Crashville %}

How to fix it:

### Link ActivityKit.framework as optional

- Go to project -> app target -> _Link Binary With Libraries_
- Add ActivityKit.framework
- Set ActivityKit.framework's status as _Optional_
- Repeat for the widget app extension target as well

{% caption_img /images/activity-kit-macos-link-optional.png h400 Link ActivityKit.framework as optional in app target and widget target %}

### Avoid calling ActivityKit symbols in your code

There are a lot of different ways to conditionally reference ActivityKit symbols.

Conditional referencing must be done at runtime since even when running on macOS the compiler directive `#if canImport(ActivityKit)` will still evaluate to `true`.

Use `if !ProcessInfo.processInfo.isiOSAppOnMac` to short circuit code that shouldn't run on macOS.

In the case of [Eki Bright](https://twocentstudios.com/2024/07/27/eki-bright-tokyo-area-train-timetables/), I have my direct usage of ActivityKit behind a dependency, defined and configured with the [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) library. This allows me to swap out a fully functional dependency with a dummy dependency at launch time.

```swift
/// LiveActivityClient.swift
import ActivityKit
import ComposableArchitecture
import WidgetKit

typealias ActivityID = String? // Same as `Activity.ID?`

@DependencyClient
struct LiveActivityClient {
    var startOrReplaceRouteActivity: @Sendable (_ routeItem: RouteItem?) async throws -> ActivityID
    var updateOrEndRouteActivity: @Sendable (_ now: Date) async -> Void
}

extension LiveActivityClient: DependencyKey {
    static let liveValue: Self = .init(
        startOrReplaceRouteActivity: { routeItem, segmentActivePhases, now in
            /// Call real implementation of `Activity.request`, etc.
        },
        updateOrEndRouteActivity: { now in
            /// Call real implementation of `activity.update`, `activity.end`, etc.
        }
    )

    static let unavailableValue: Self = .init(
        startOrReplaceRouteActivity: { _, _, _ in nil },
        updateOrEndRouteActivity: { _ in }
    )
}
```

Then in the `App.swift` file I use `.unavailableValue` instead of the default `.liveValue` on macOS:

```swift
@main
struct TrainApp: App {
    static let store =
        Store(initialState: .init()) {
            RootFeature()
        } withDependencies: {
            if ProcessInfo.processInfo.isiOSAppOnMac {
                $0.liveActivity = .unavailableValue // ActivityKit framework crashes on macOS
            }
        }

    var body: some Scene {
        WindowGroup {
            RootView(store: Self.store)
        }
    }
}
```

I can then use `@Dependency(\.liveActivity) var liveActivity` in any one of my features.

Of course, the implementation of your `unavailableValue` can also throw specific errors handled by your feature code. In my case, the LiveActivity silently failing on macOS is acceptable.

### Hardening your widget extension

If you're using ActivityKit.framework, then you may have a widget extension that configures the LiveActivity. In my case, I have a normal widget as well as a LiveActivity widget. In order to conditionally enable the LiveActivity widget on non-macOS platforms, I'm using the following technique from [this Stack Overflow post](https://stackoverflow.com/a/72807287):

```swift
@main
struct WidgetLauncher {
    static func main() {
        if ProcessInfo.processInfo.isiOSAppOnMac {
            WidgetOnlyBundle.main()
        } else {
            WidgetActivityBundle.main()
        }
    }
}

struct WidgetOnlyBundle: WidgetBundle {
    var body: some Widget {
        StationBookmarkWidget()
    }
}

struct WidgetActivityBundle: WidgetBundle {
    var body: some Widget {
        StationBookmarkWidget()
        RouteActivityWidget()
    }
}
```

However, there are some bugs with macOS widgets in Xcode 16.2 that I haven't found a workaround for yet. I can't 100% say this technique works, but if the default configuration doesn't work for you, try the above and see if it helps. I'm still [pretty confused](https://hachyderm.io/@twocentstudios/113887068005326578) about how to efficiently test and debug widgets on macOS, so I don't have a lot of guidance for this part.

### References

- [Stack Overflow: Launching a designed for iPad mac app crashes at startup: Library not loaded](https://stackoverflow.com/q/75589730)
- [Stack Overflow: WidgetBundle return widgets based on some logic](https://stackoverflow.com/a/72807287)
- [Apple Developer Forums: WidgetKit Simulator with Intent Configurations](https://forums.developer.apple.com/forums/thread/773125)
- [Apple Developer Documentation: Debugging Widgets](https://developer.apple.com/documentation/widgetkit/debugging-widgets)
