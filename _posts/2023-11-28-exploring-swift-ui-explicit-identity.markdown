---
layout: post
title: Exploring SwiftUI Explicit Identity
date: 2023-11-28 23:17:22
image: /images/explicit-identity-1-1.png
---

In this post, I'll show a few examples of how specifying the explicit identity of a simple SwiftUI view affects the behavior of the view over time depending on its container view.

## Background

_View identity_ is an essential part to the deep story behind how the SwiftUI framework converts `View` protocol-conforming structs written by us into pixels on the screen, and how that process works over the lifetime of our app. This post assumes you already have a basic understanding of SwiftUI (I recommend viewing the resources at the bottom of this post to build your mental model of SwiftUI).

SwiftUI uses the concept of _view identity_ to track view lifetime, not only for efficient rendering but also to ensure the view-local state (like the kind marked by `@State`) that it maintains for us is not discarded prematurely.

SwiftUI tracks view identity in two ways: **structural identity** and **explicit identity**. This post discusses **explicit identity**: associating a `Hashable` value to a SwiftUI view through the `.id(...)` modifier, or (more commonly) using an initializer of `ForEach`, `List`, or other enumerable primitive views with an `Identifiable` associated value.

For example:

```swift
/// An `id` modifier will add explicit identity to the `Text` view returned by `body`. 
struct MyView: View {
    var body: some View {
        Text("Hello world")
            .id("text")
    }
}

/// This initializer of `List` requires a collection where each element has a stable identity.
/// Each `Text` will be assigned an explicit identifier.
struct MyListView: View {
    let items: [String] = ["a", "b"]
    var body: some View {
        List(items, id: \.self) { item in
            Text(item)
                // .id(item) <- applied automatically by `List`
        }
    }
}
```

For context, it's overwhelmingly more common to see explicit identity expressed with enumerating views like `ForEach`. In my experience, the `.id` modifier is usually only seen used alongside `ScrollViewReader` to force scroll to a certain view. Or, even more rarely, to force SwiftUI to reload a view, perhaps to trigger a `.transition` animation. The trivia in this post is most useful in the realm of the latter.

## Experiment setup

Let's define a view structure we can reuse for each experiment.

```swift
struct User: Identifiable, Equatable {
    let id: Int
    let name: String
}

struct ViewData: Equatable {
    var userTop = User(id: 0, name: "Abby")
    var userMiddle = User(id: 1, name: "Barry")
    var userBottom = User(id: 2, name: "Craig")
}

struct ContentView: View {
    @State var viewData = ViewData()
    @Namespace var ns // used later for `.matchedGeometryEffect`

    var body: some View {
        NavigationStack {
            // ** Each experiment will replace `EmptyView` **
            EmptyView()
                .navigationTitle("Experiment Title")
                .toolbar {
                    Button("Swap Abby & Craig") {
                        withAnimation {
                            let newBottom = viewData.userTop
                            viewData.userTop = viewData.userBottom
                            viewData.userBottom = newBottom
                        }
                    }
                }
        }
    }
}

struct UserView: View {
    let user: User

    // Internal state that will help us understand SwiftUI's lifetime of this view
    @State var internalFlag: Bool = false

    var body: some View {
        HStack {
            Text(user.name)
            Spacer()
            Toggle("", isOn: $internalFlag)
        }
    }
}
```

The view for each experiment will usually look like this:

{% caption_img /images/explicit-identity-setup.png The common view appearance for the experiments %}

In order to determine what's happening with SwiftUI's internal representation of our views in the render tree, we'll manually set the top and middle toggles (Abby and Barry) to "on", even though their default value is "off", like so:

{% caption_img /images/explicit-identity-1-1.png We'll manually set the initial state of the top and middle toggles to `on` %}

Note: in the post I'll be eliding styling modifiers in code blocks for brevity.

## Experiments

Our goal is to observe the behavior of explicit identity in a several situations. We'll see subtle differences in behavior based on changing the parent view that contains the views we've explicitly identified.

There are 3 cells that display the 3 users. Tapping the button swaps the top and bottom users (Abby and Craig).

Each cell has one piece of internal boolean `@State` represented in the UI by a `Toggle` control. In the experiments, we'll manually toggle this state to true. If it resets to `false` after tapping the button, we'll have a clue that SwiftUI thinks the view's identity changed and it recreated the underlying render tree view.

Note: there are other ways besides `@State` to monitor a view's lifetime: printing to the console inside `onAppear`, `onDisappear`, `onTask`; adding a non-default `.transition`; adding `Self._printChanges` in the `body` property.

All experiments were run on Xcode 15.0.1, iOS 17.0.1, and Swift 5.9.

### 1. VStack container with no explicit identity

Let's start with the simplest setup.

```swift
VStack {
    UserView(user: viewData.userTop)
    UserView(user: viewData.userMiddle)
    UserView(user: viewData.userBottom)
}
```

Initial|After 1st tap|After 2nd tap
-|-|-
![](/images/explicit-identity-1-1.png)|![](/images/explicit-identity-1-2.png)|![](/images/explicit-identity-1-1.png)

<video src="/images/explicit-identity-1.mov" controls preload="none" poster="/images/explicit-identity-1-1.png" width="100%"></video>

Without _explicit identity_, SwiftUI is relying on _structural identity_ to track the identity of each of the 3 `UserView`s.

This example shows us that SwiftUI is not recreating the underlying render tree views. The names are changing but the toggles are staying the same. As far as SwiftUI is concerned, the `UserView` dependency value `user` is changing, but the `UserView` maintains the same identity.

Abby's toggle looks like it was inherited by Craig after the first tap. Conceptually, it's true that you can consider the "name" part as jumping between non-moving cells in this setup.

For the record: `LazyVStack` has the same behavior as `VStack` when its content views have no explicit identity.

### 2. VStack container with explicit identity

Let's add explicit identity via the `.id` modifier to each cell.

```swift
VStack {
    UserView(user: viewData.userTop)
        .id(viewData.userTop.id)
    UserView(user: viewData.userMiddle)
        .id(viewData.userMiddle.id)
    UserView(user: viewData.userBottom)
        .id(viewData.userBottom.id)
}
```

Initial|After 1st tap|After 2nd tap
-|-|-
![](/images/explicit-identity-2-1.png)|![](/images/explicit-identity-2-2.png)|![](/images/explicit-identity-2-3.png)

<video src="/images/explicit-identity-2.mov" controls preload="none" poster="/images/explicit-identity-2-1.png" width="100%"></video>

The `UserView` `id` values before and after switching places:

ID Before|ID After
-|-
0|2
1|1
2|0

The top and bottom `UserView`'s `id` values changed, therefore SwiftUI considers them new views, ends the lifetime of their render tree equivalents, and creates new render tree views in their places, including the underlying storage for `UserView.internalFlag`.

Both the `Text` and `Toggle` of the top and bottom cells animate with the default `.opacity` transition. Although it looks the same as experiment (1), this is a _transition_ and not an in-place animation.

The middle view ("Barry") has not changed. Its explicit identity and structural identity did not change.

You may have thought that the top and bottom cells would swap places without being recreated. If that were the case, Abby's "on" toggle would follow her to the bottom row. Why doesn't it?

This is behavior specific to `VStack` (as opposed to `LazyVStack` or `ForEach` or `List`, which we'll see in a moment). This behavior is explained in the book [Thinking in SwiftUI](https://www.objc.io/books/thinking-in-swiftui/):

> It’s important to note that an explicit identifier like the one above doesn’t override the view’s implicit identity, but is instead applied on top of it.

`VStack` seems to enforce strong structural identity of our 3 views, and therefore even though it sees the same view type and the same id but in a different position, it doesn't try to maintain our views' identities across the reorder.

### 3. LazyVStack container with explicit identity

```swift
LazyVStack {
    UserView(user: viewData.userTop)
        .id(viewData.userTop.id)
    UserView(user: viewData.userMiddle)
        .id(viewData.userMiddle.id)
    UserView(user: viewData.userBottom)
        .id(viewData.userBottom.id)
}
```

Initial|After 1st tap|After 2nd tap
-|-|-
![](/images/explicit-identity-3-1.png)|![](/images/explicit-identity-3-2.png)|![](/images/explicit-identity-3-1.png)

<video src="/images/explicit-identity-3.mov" controls preload="none" poster="/images/explicit-identity-3-1.png" width="100%"></video>

After the first button tap, `LazyVStack` with explicit identity looks like it will have the same behavior as `VStack` from experiment 2. However, on the second button tap, we see that Abby's toggle value has been restored!

What's going on here?

It seems like SwiftUI is still deriving an identity for each view by combining structural identity and explicit identity, but `LazyVStack` isn't discarding the internal state even if a view with that identity is removed from its jurisdiction.

Let's think about the usual use case for `LazyVStack`. `LazyVStack` maintains a group of views within a `ScrollView`.

Quoting from [A Companion for SwiftUI](https://swiftui-lab.com/companion/) (**emphasis** mine):

> The child views of lazy stacks and grids are only created as they become visible. Once they have been created and made part of the view hierarchy, they will remain part of it, until they scroll out of view. However, **their states will remain in memory**.

The only surprising part then is that usually it's `ScrollView > LazyVStack > ForEach` cohort that are handling the adding/removing of views and maintaining explicit identifiers, but in this case we're the ones doing the manipulating and we're seeing similar behavior.

### 4. VStack container with matched geometry effect

```swift
VStack(spacing: 6) {
    UserView(user: viewData.userTop)
        .matchedGeometryEffect(id: viewData.userTop.id, in: ns)
        .id(viewData.userTop.id)
    UserView(user: viewData.userMiddle)
        .matchedGeometryEffect(id: viewData.userMiddle.id, in: ns)
        .id(viewData.userMiddle.id)
    UserView(user: viewData.userBottom)
        .matchedGeometryEffect(id: viewData.userBottom.id, in: ns)
        .id(viewData.userBottom.id)
}
```

Initial|After 1st tap|After 2nd tap
-|-|-
![](/images/explicit-identity-4-1.png)|![](/images/explicit-identity-4-2.png)|![](/images/explicit-identity-4-3.png)

<video src="/images/explicit-identity-4.mov" controls preload="none" poster="/images/explicit-identity-4-1.png" width="100%"></video>

`.matchedGeometryEffect` is a quirky modifier. I was curious whether we could force `VStack` to recognize the top and bottom views as having the same underlying identity.

The result is about half what we'd hope. The top and bottom views swap positions with an animation (good), but the `internalFlag` is still reset as we saw in experiment 1.

For those curious, removing the explicit `.id` from each cell has the same behavior as experiment 1.

### 5. ForEach

```swift
VStack(spacing: 6) {
    ForEach([viewData.userTop, viewData.userMiddle, viewData.userBottom]) { item in
        UserView(user: item)
    }
}
```

Initial|After 1st tap|After 2nd tap
-|-|-
![](/images/explicit-identity-5-1.png)|![](/images/explicit-identity-5-2.png)|![](/images/explicit-identity-5-1.png)

<video src="/images/explicit-identity-5.mov" controls preload="none" poster="/images/explicit-identity-5-1.png" width="100%"></video>

`ForEach` is the first enumerating view we're experimenting with that has first class support for explicit identity. The `User` struct conforms to `Identifiable`, and therefore `ForEach` is using this initializer (note the `Data.Element: Identifiable`):

```swift
extension ForEach where ID == Data.Element.ID, Content : View, Data.Element : Identifiable {

    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// It's important that the `id` of a data element doesn't change unless you
    /// replace the data element with a new data element that has a new
    /// identity. If the `id` of a data element changes, the content view
    /// generated from that data element loses any current state and animations.
    ///
    /// - Parameters:
    ///   - data: The identified data that the ``ForEach`` instance uses to
    ///     create views dynamically.
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content)
}
```

The behavior looks good! SwiftUI is not only maintaining the internal state of each cell, but also providing a slick animation swapping the top and bottom cells.

We can perhaps say that `ForEach` provides strong explicit identity and weak structural identity for its child views. Or maybe no structural identity at all.

### 6. List

```swift
List([viewData.userTop, viewData.userMiddle, viewData.userBottom]) { item in
    UserView(user: item)
}
```

Initial|After 1st tap|After 2nd tap
-|-|-
![](/images/explicit-identity-6-1.png)|![](/images/explicit-identity-6-2.png)|![](/images/explicit-identity-6-1.png)

<video src="/images/explicit-identity-6.mov" controls preload="none" poster="/images/explicit-identity-6-1.png" width="100%"></video>

`List` is the more opinionated version of `LazyVStack`+`ForEach`, implemented under-the-hood as a `UICollectionView` subclass.

{% caption_img /images/explicit-identity-view-debugger-list.png Under the hood: in iOS 17 List is implemented as a UICollectionView subclass %}

The behavior is exactly the same as `ForEach` in experiment 5. With the heartbreaking exception that there is no animation in the Xcode Preview (but there is on the full simulator).

## Conclusion

Although you probably won't encounter situations where you need to understand the subtleties of explicit identity we've uncovered in this post regularly, hopefully it has helped reinforce your mental model of how SwiftUI handles identity.

Any other interesting view identity behavior or trivia you've encountered? Let me know on [Mastodon](https://hackyderm.io/@twocentstudios).

## Recommended viewing/reading

- [A Day in the Life of a SwiftUI View — Chris Eidhof](https://chris.eidhof.nl/presentations/day-in-the-life/)
- [Demystify SwiftUI - WWDC21](https://developer.apple.com/videos/play/wwdc2021/10022/)
- [Thinking in SwiftUI · objc.io](https://www.objc.io/books/thinking-in-swiftui/)

## Full copy/pasteable code

```swift
import SwiftUI

struct User: Identifiable, Equatable {
    let id: Int
    let name: String
}

struct ViewData: Equatable {
    var userTop = User(id: 0, name: "Abby")
    var userMiddle = User(id: 1, name: "Barry")
    var userBottom = User(id: 2, name: "Craig")
}

struct UserView: View {
    let user: User

    // Internal state that will help us understand SwiftUI's lifetime of this view
    @State var internalFlag: Bool = false

    var body: some View {
        HStack {
            Text(user.name)
            Spacer()
            Toggle("", isOn: $internalFlag)
        }
        // .transition(.slide.combined(with: .opacity))
    }
}

#Preview("1. VStack") {
    struct ContentView: View {
        @State var viewData = ViewData()

        var body: some View {
            NavigationStack {
                VStack(spacing: 6) {
                    UserView(user: viewData.userTop)
                    UserView(user: viewData.userMiddle)
                    UserView(user: viewData.userBottom)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .navigationTitle("1. VStack")
                .toolbar {
                    Button("Swap Abby & Craig") {
                        withAnimation {
                            let swap = viewData.userTop
                            viewData.userTop = viewData.userBottom
                            viewData.userBottom = swap
                        }
                    }
                }
            }
        }
    }
    return ContentView()
}

#Preview("2. VStack w/ID") {
    struct ContentView: View {
        @State var viewData = ViewData()

        var body: some View {
            NavigationStack {
                VStack(spacing: 6) {
                    UserView(user: viewData.userTop)
                        .id(viewData.userTop.id)
                    UserView(user: viewData.userMiddle)
                        .id(viewData.userMiddle.id)
                    UserView(user: viewData.userBottom)
                        .id(viewData.userBottom.id)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .navigationTitle("2. VStack w/ID")
                .toolbar {
                    Button("Swap Abby & Craig") {
                        withAnimation {
                            let swap = viewData.userTop
                            viewData.userTop = viewData.userBottom
                            viewData.userBottom = swap
                        }
                    }
                }
            }
        }
    }
    return ContentView()
}

#Preview("3. LazyVStack w/ID") {
    struct ContentView: View {
        @State var viewData = ViewData()

        var body: some View {
            NavigationStack {
                LazyVStack(spacing: 6) {
                    UserView(user: viewData.userTop)
                        .id(viewData.userTop.id)
                    UserView(user: viewData.userMiddle)
                        .id(viewData.userMiddle.id)
                    UserView(user: viewData.userBottom)
                        .id(viewData.userBottom.id)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .navigationTitle("3. LazyVStack w/ID")
                .toolbar {
                    Button("Swap Abby & Craig") {
                        withAnimation {
                            let swap = viewData.userTop
                            viewData.userTop = viewData.userBottom
                            viewData.userBottom = swap
                        }
                    }
                }
            }
        }
    }
    return ContentView()
}

#Preview("4. VStack w/MGE") {
    struct ContentView: View {
        @State var viewData = ViewData()
        @Namespace var ns

        var body: some View {
            NavigationStack {
                VStack(spacing: 6) {
                    UserView(user: viewData.userTop)
                        .matchedGeometryEffect(id: viewData.userTop.id, in: ns)
                        .id(viewData.userTop.id)
                    UserView(user: viewData.userMiddle)
                        .matchedGeometryEffect(id: viewData.userMiddle.id, in: ns)
                        .id(viewData.userMiddle.id)
                    UserView(user: viewData.userBottom)
                        .matchedGeometryEffect(id: viewData.userBottom.id, in: ns)
                        .id(viewData.userBottom.id)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .navigationTitle("4. VStack w/MGE")
                .toolbar {
                    Button("Swap Abby & Craig") {
                        withAnimation {
                            let swap = viewData.userTop
                            viewData.userTop = viewData.userBottom
                            viewData.userBottom = swap
                        }
                    }
                }
            }
        }
    }
    return ContentView()
}

#Preview("5. ForEach") {
    struct ContentView: View {
        @State var viewData = ViewData()

        var body: some View {
            NavigationStack {
                VStack(spacing: 6) {
                    ForEach([viewData.userTop, viewData.userMiddle, viewData.userBottom]) { item in
                        UserView(user: item)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .navigationTitle("5. ForEach")
                .toolbar {
                    Button("Swap Abby & Craig") {
                        withAnimation {
                            let swap = viewData.userTop
                            viewData.userTop = viewData.userBottom
                            viewData.userBottom = swap
                        }
                    }
                }
            }
        }
    }
    return ContentView()
}

#Preview("6. List") {
    struct ContentView: View {
        @State var viewData = ViewData()

        var body: some View {
            NavigationStack {
                List([viewData.userTop, viewData.userMiddle, viewData.userBottom]) { item in
                    UserView(user: item)
                }
                .listStyle(.plain)
                .navigationTitle("6. List")
                .toolbar {
                    Button("Swap Abby & Craig") {
                        withAnimation {
                            let swap = viewData.userTop
                            viewData.userTop = viewData.userBottom
                            viewData.userBottom = swap
                        }
                    }
                }
            }
        }
    }
    return ContentView()
}

```
