---
layout: post
title: "SwiftUI Group Still(?) Considered Harmful"
date: 2025-12-12 16:37:39
image: /images/swiftui-group-onappear-demo-poster.png
tags: apple swiftui ios
---

A number of years ago, I internalized a SwiftUI axiom after getting burned on what appeared at first as a heisenbug.

The axiom:

> Never use `Group` (with only a few exceptions).

TL;DR: I still think this is a useful axiom, although at some point over the last several iOS updates the behavior of `Group` is *less* harmful when applied naively. But there are still some reasons why it's useful to treat it with caution.

## `Group` distributes its modifiers amongst its subviews

`Group` is documented as a wrapper `View`. From the official docs (emphasis mine):

> Use a group to collect multiple views into a single instance, without affecting the layout of those views, like an `HStack`, `VStack`, or `Section` would. After creating a group, **any modifier you apply to the group affects all of that group’s members**.

Apple specifically calls out what "affects all of that group's members" means in the next paragraph, with an accompanying code sample:

```swift
Group {
    if isLoggedIn {
        WelcomeView()
    } else {
        LoginView()
    }
}
.navigationBarTitle("Start")
```

> The modifier applies to all members of the group — and not to the group itself. For example, if you apply `onAppear(perform:)` to the above group, it applies to all of the views produced by the if `isLoggedIn` conditional, and it executes every time `isLoggedIn` changes.

This burned me in the past because I had a screen pattern like the (very simplified version) below:

```swift
struct ContentView: View {
    @State var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                DataLoadedView()
            }
        }
        .onAppear {
            fetchData()
        }
    }
    
    private func fetchData() {
        // make network request
        // set `isLoading = false` in completion handler
    }
}
```

With `Group`'s documented behavior, the `onAppear` modifier is essentially distributed across the `Group`'s views:

```swift
Group {
    if isLoading {
        ProgressView()
            .onAppear {
                fetchData()
            }
    } else {
        DataLoadedView()
            .onAppear {
                fetchData()
            }
    }
}
```

The bug *was* (at the time) that `fetchData` will be called twice: once when `ProgressView` appears, and once again when `DataLoadedView` appears.

Of course, there are many new modifiers and patterns since iOS 13 or 14 or whenever I was bitten by this (probably before the documentation was added). Regardless, after learning about this behavior it sort of makes sense. And so I learned my lesson that `Group` should not be used in this case.

## What's changed with `Group`

I'd locked this knowledge away and hadn't considered it in years. However, coding agents seem to *love* to use `Group` to write the exact buggy code pattern I just illustrated above. I was curious enough to investigate it again.

Well it turns out that in iOS 26 and maybe even as far back as iOS 15, in most cases `Group` no longer distributes its `onAppear` or `task` calls amongst its subviews. Read on for the caveats.

From my testing, `onAppear`, `onDisappear`, `task`, and maybe other modifiers **seem to have been special-cased by Apple** to work at the `Group`-level and **not** be distributed to subviews like they used to. Note that this means the documentation for `Group` (that I quoted above) is now incorrect.

### `onAppear` and `task`

Consider the following `View`:

```swift
struct ContentView: View {
    @State var isLeft = true
    var body: some View {
        Group {
            if isLeft {
                Rectangle().fill(.red).frame(width: 50)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onAppear {
                        print("left")
                    }
            } else {
                Rectangle().fill(.blue).frame(width: 50)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onAppear {
                        print("right")
                    }
            }
        }
        .onAppear {
            print("group")
            Task {
                try? await Task.sleep(for: .seconds(1))
                isLeft.toggle()
            }
        }
    }
}
```

According to the docs, this code should loop between the left and right rectangles. However, as of iOS 26 (and as far back as I can test, iOS 15), it runs the `onAppear` modifier once and stays showing the right blue rectangle.

<video src="/images/swiftui-group-onappear-demo.mp4" controls preload="none" poster="/images/swiftui-group-onappear-demo-poster.png" width="400"></video>

The console:

```
left
group
right
```

### Screen-level Views

I stumbled on this lonely bug report from June 2020:

[Inconsistency in how Group's onAppear and onDisappear are called - Using Swift - Swift Forums](https://forums.swift.org/t/inconsistency-in-how-groups-onappear-and-ondisappear-are-called/37111)

> Something that I noticed today and didn't expect it is that if a `Group` is not the root view of the screen, its `onAppear` is called per each child, while for a `Group` that is the root, the method is called once, regardless of the number of its children.

```swift
struct ContentView: View {
    var body: some View {
        Group { // Group is the root of the screen, onAppear is called once
            Group {  // non-root view, onAppear is called once per each child
                Color(.red)
                Color(.yellow)
            }
            .onAppear { print(".:. onAppear2") }
            .onDisappear { print(".:. onDisappear2") }
            
            Color(.blue)
            Color(.purple)
        }
        .onAppear { print(".:. onAppear1") }
        .onDisappear { print(".:. onDisappear1") }
    }
}
/* Output:
.:. onAppear1
.:. onAppear2
.:. onAppear2
*/
```

My guess is that this was reported during iOS 13, right before iOS 14 beta.

I tested this code as well, and it turns out the OP's example no longer prints `onAppear2` twice on iOS 15 or iOS 26.

### List

The only case I've found (so far) where the documented `onAppear` (and `task`) distributed-across-subviews behavior still exists is when `Group` is within a `List`:

```swift
struct ContentView: View {
    @State var isLeft = true
    var body: some View {
        List {
            Group {
                if isLeft {
                    Rectangle().fill(.red).frame(width: 50)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onAppear {
                            print("left")
                        }
                } else {
                    Rectangle().fill(.blue).frame(width: 50)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .onAppear {
                            print("right")
                        }
                }
            }
            .onAppear {
                print("group")
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    isLeft.toggle()
                }
            }
        }
    }
}
```

<video src="/images/swiftui-group-list-demo.mp4" controls preload="none" poster="/images/swiftui-group-list-demo-poster.png" width="400"></video>

The console:

```
left
group
right
group
left
group
right
... (repeats forever)
```

### Regular modifiers with Group

As a check that `Group` still distributes its modifiers in the general case, I created a simple custom modifier that prints on `init` and applied it to the `Group`:

```swift
struct PrintModifier: ViewModifier {
    init() {
        print("modifier init")
    }

    func body(content: Content) -> some View {
        content
    }
}

struct ContentView: View {
    @State var isLeft = true
    var body: some View {
        Group {
            if isLeft {
                Rectangle().fill(.red).frame(width: 50)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onAppear {
                        print("left")
                    }
            } else {
                Rectangle().fill(.blue).frame(width: 50)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onAppear {
                        print("right")
                    }
            }
        }
        .modifier(PrintModifier())
        .onAppear {
            print("group")
            Task {
                try? await Task.sleep(for: .seconds(1))
                isLeft.toggle()
            }
        }
    }
}
```

The console:

```
modifier init
group
left
modifier init
right
```

As we can see, `PrintModifier` is being applied to each subview independently as is documented. We've somewhat proven to ourselves that in the general case, `Group` still distributes modifiers.

## When is Group useful?

When is `Group` still the right choice?

Honestly, not very often!

### Distributing a lot of modifiers across sibling views

If you really really really need to apply one or more modifiers independently to a set of sibling views **and** you need the sibling views to stay legible to their current parent container, `Group` is the right choice.

In the below toy example with Form:

```swift
Form {
    Text("Title")
    Group {
        Text("Subtitle")
        Text("Description")
    }
    .foregroundStyle(.secondary)
}
```

I would prefer simply duplicating the modifier manually:

```swift
Form {
    Text("Title")
    Text("Subtitle")
        .foregroundStyle(.secondary)
    Text("Description")
        .foregroundStyle(.secondary)
}
```

In my experience, the conditions that lead to `Group` being useful for this case are exceedingly rare. In a quick search of my current codebase, I have only a couple examples. 

This one just barely makes sense as it applies 4 modifiers to these 2 slightly different conditional subviews. Not quite large enough to justify separating out into named views; not quite small enough to duplicate the modifiers inline.

```swift
Group {
    switch routeOption {
    case .departure, .departureOnly:
        HStack(spacing: 3) {
            Image(systemName: "arrow.up.right").imageScale(.small).bold()
            Image(systemName: "train.side.middle.car")
        }
        .padding(.horizontal, 10)
    case .arrival, .arrivalOnly:
        HStack(spacing: 2) {
            Image(systemName: "train.side.middle.car")
            Image(systemName: "arrow.down.right").imageScale(.small).bold()
        }
        .padding(.horizontal, 11)
    }
}
.font(.caption)
.foregroundStyle(.secondary)
.padding(.vertical, 10)
.background(Material.ultraThick, in: RoundedRectangle(cornerRadius: 4))
```

### ~~Overcoming the 10-subview limit~~ (no longer applies)

Before Swift 5.9's variadic generics, ViewBuilder could only handle 10 non-enumerated subviews. This example is still in the `Group` docs but no longer applies:

```swift
// No longer applies as of Swift 5.9
var body: some View {
    VStack {
        Group {
            Text("1")
            Text("2")
            Text("3")
            Text("4")
            Text("5")
            Text("6")
            Text("7")
            Text("8")
            Text("9")
            Text("10")
        }
        Text("11")
    }
}
```
