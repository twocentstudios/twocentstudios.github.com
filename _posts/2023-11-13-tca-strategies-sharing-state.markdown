---
layout: post
title: Strategies for Sharing State in The Composable Architecture
date: 2023-11-13 10:00:00
tags: apple ios tca
---

While working on new features for [Count Biki](/2023/10/29/count-biki-japanese-numbers/), I've started to clarify some of the [confusion points](/2023/10/31/count-biki-developing-the-app-for-ios#shared-state) I had about sharing state in a TCA app.

So far, I've identified two distinct strategies for sharing state based on source-of-truth ownership of the state: **root ownership** and **dependency ownership**. **Root ownership** includes **scope** and **copy-and-delegate** sub-strategies.

The kind of state in question here is:

1. shared across multiple features that could have parent/child/sibling/ancestor/descendant relationships.
2. longer lived than any one feature (and optionally persisted to disk).

### Strategy 1: root ownership

Root ownership is keeping some source-of-truth state in a `Store`'s `State`, and vending access to all descendant features through the standard TCA scoping mechanism that conceptually _links_ parent and child stores/features/views together.

I'm still workshopping the above definition, but I think it's clear with an example.

Root ownership is what is shown in pointfreeco's [SyncUps example app](https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples/SyncUps).

The primary model state in this app is an array of `SyncUp` models. These are stored within the `SyncUpsList` feature.

```swift
struct SyncUpsList: Reducer {
  struct State: Equatable {
    var syncUps: IdentifiedArrayOf<SyncUp> = []
    // ...
  }
  // ...
}
```

However, the _actual_ source-of-truth owner of this state is the parent reducer `AppFeature`:

```swift
struct AppFeature: Reducer {
  struct State: Equatable {
    var syncUpsList = SyncUpsList.State()
    // ...
  }
  // ...
}
```

I say it's the source-of-truth owner of the state because it's holding onto the `SyncUpsList.State` _and_ it uses a `Scope` reducer and `.scope` modifier to (conceptually) link these pieces of state together.

```swift
struct AppFeature: Reducer {
  // ...
  var body: some ReducerOf<Self> {
    Scope(state: \.syncUpsList, action: /Action.syncUpsList) {
      SyncUpsList()
    }
    // ...
  }
}

struct AppView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    NavigationStackStore(self.store.scope(state: \.path, action: { .path($0) })) {
      SyncUpsListView(
        store: self.store.scope(state: \.syncUpsList, action: { .syncUpsList($0) })
      )
    }
    // ...
  }
  // ...
}
```

This link allows both `AppFeature` and `SyncUpsList` to read/write the `syncUpsList` state as parent and child features.

Scoping state this way allows an unlimited number of parent and children to share (mutable) state.

We can additionally consider `AppFeature`  as the source-of-truth of the state/model because:

- `AppFeature` reads its initial `[SyncUp]` models from disk (via the `SyncUpsList.init` method).
- `AppFeature` writes changes of `[SyncUp]` to disk.

However, the SyncUps app uses another mechanism to "share" state. I'll call the second mechanism _copy-and-delegate_. It's mostly what it sounds like:

1. From a parent feature, make a copy of all or some part of the source-of-truth state, but keep it alongside the source-of-truth state (as e.g. part of a `Destination.State` or `Path.State`).
2. Make the parent reducer listen to delegate actions from child reducers that describe changes to the source-of-true state, and modify the own source-of-truth state accordingly.
3. Discard the copy of the state as necessary (since the relevant changes have been incorporated into the source-of-truth).

In a more isolated context, SyncUps uses this strategy for editing a `SyncUp` with the parent feature being `SyncUpDetail` and the child being `SyncUpForm`.

```swift
struct SyncUpDetail: Reducer {
  struct State: Equatable {
    @PresentationState var destination: Destination.State?
    var syncUp: SyncUp
  }
  // ...

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      
      // Copy: Create a copy of the `syncUp` for the editing form.
      // Store it in `destination` alongside the source-of-truth `syncUp`.
      case .editButtonTapped:
        state.destination = .edit(SyncUpForm.State(syncUp: state.syncUp))
        return .none

      // Delegate: Re-integrate the edited copy of `syncUp` into
      // its own source-of-truth state iff the user taps the done button.
      case .doneEditingButtonTapped:
        guard case let .some(.edit(editState)) = state.destination else { return .none }
        state.syncUp = editState.syncUp
        state.destination = nil
        return .none
      
      // ...
```

In this case, `SyncUpDetail` uses `.doneEditingButtonTapped` as the trigger to integrate the copy of the state (within `destination`) into `syncUp` rather than passing state through the action's associated value (like we'll see below).

The copy-and-delegate strategy makes sense especially for editing workflows that allow the user to discard their changes.

But `SyncUpDetail.State.syncUp` isn't storing the _app_'s source-of-truth value for that `syncUp`. `SyncUpDetail.State` was also created as a copy and stored in the `path` property of `AppFeature.State` alongside the source-of-truth array `syncUpsList`.

```swift
struct AppFeature: Reducer {
  struct State: Equatable {
    var path = StackState<Path.State>()
    var syncUpsList = SyncUpsList.State()
  }

  struct Path: Reducer {
    enum State: Equatable {
      case detail(SyncUpDetail.State)
      // ...
    }
    // ...
  }
```

`SyncUpDetail` must play back its changes to its parent via a delegate action. This is where we see a second layer of copy-and-delegate in practice.

```swift
struct SyncUpDetail: Reducer {
  // ...

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // ...
    }
    .onChange(of: \.syncUp) { oldValue, newValue in
      Reduce { state, action in
        .send(.delegate(.syncUpUpdated(newValue)))
      }
    }
  }
}
```

And the parent (in this case `AppFeature`) must listen for those delegate actions and use the state passed within to update its own source-of-truth state:

```swift
struct AppFeature: Reducer {
  var body: some ReducerOf<Self> {
    // ...
    Reduce { state, action in
      switch action {
      case let .path(.element(id, .detail(.delegate(delegateAction)))):
        guard case let .some(.detail(detailState)) = state.path[id: id] else { return .none }
        switch delegateAction {
        case let .syncUpUpdated(syncUp):
          state.syncUpsList.syncUps[id: syncUp.id] = syncUp
          return .none
      }
      // ...
    }
    // ...
  }
}
```

Just as we saw `SyncUpDetail` move the temporary state in `State.destination` to `State.syncUp` (via an `Action`), we also see `AppReducer` move the temporary state `State.path` into `State.syncUps` (via an `Action`).

What tripped me up about the **scope** vs. **copy-and-delegate** strategies at first was:

1. I didn't realize they were distinct strategies.
2. I didn't realize **copy-and-delegate** _was_ still fully integrated into the bread-and-butter scoping mechanism of TCA. After all, the parent reducer still needs to receive the delegate messages from the child reducer, which means there has to be _some_ link between them.
3. Navigation-as-first-class-state (in the form of `Destination`, `Path`, etc.) has a lot of benefits (deep-linking, testing, etc.). But it does complect _model state_ and _view state_. _Model state_ and _view state_ often have different lifetimes, and if you aren't careful you can lose track of the concept of source-of-truth.

`AppFeature` holds the _model state_ of `syncUpsList` side-by-side with the _view state_ of `path`.

```swift
struct AppFeature: Reducer {
  struct State: Equatable {
    var path = StackState<Path.State>()
    var syncUpsList = SyncUpsList.State()
  }
  // ...
}
```

But `syncUpsList` _itself_ could technically qualify as _view state_. Except that in this case, `SyncUpsListView` is the root of the `NavigationStack` which is the root of the `AppView` which has the same lifetime as the app itself.

Perhaps you could even further separate _view state_ into _view state_ and _navigation state_.

As a final note about **root ownership**, there are more advanced techniques for further processing state at the parent before handing it off to child reducers. It's basically using computed variables to derive a distinct subset of the model state on the fly. See the [Shared State](https://github.com/pointfreeco/swift-composable-architecture/blob/main/Examples/CaseStudies/SwiftUICaseStudies/01-GettingStarted-SharedState.swift) TCA case study to learn more it.

### Strategy 2: dependency ownership

The second major strategy for sharing state is to do it through a dependency.

Let's show an example before discussing why you may want to choose the dependency ownership strategy.

Going back to my app, Count Biki, we'll use `SpeechSynthesisSettingsClient` as an example of a dependency used to share state. It has a very simple get/set/observe interface. Under the hood, it's a wrapper over a `UserDefaults` dependency with a little bit of encoding/decoding processing thrown in.

```swift
struct SpeechSynthesisSettingsClient {
  var get: @Sendable () -> (SpeechSynthesisSettings)
  var set: @Sendable (SpeechSynthesisSettings) async throws -> Void
  var observe: @Sendable () -> AsyncStream<SpeechSynthesisSettings>
}
```

In contrast to **root ownership** (strategy 1), **dependency ownership** (strategy 2) does not _require_ features to be linked together in order to share state or pass messages as long as they only depend on the state contained in the dependency (the features still can be linked through the usual scoping mechanism of course).

Some combination of the get/set/observe interface will be used depending on the needs and assumptions of the feature:

State Access|State modified externally during lifetime?|-> Required APIs
-|-
read-only|no|get
read-only|yes|get/observe
read-write|no|get/set
read-write|yes|get/set/observe

It's safest to assume the state of the dependency will be modified externally by a different feature or by something else in the environment. However, it does add a bit more code and complexity.

When a feature uses state from a dependency this way, it's going to need its own _view state_ copy of the state (in the example case, `SpeechSynthesisSettings`) by the nature of TCA and SwiftUI. Having multiple copies of data is the first step to data getting out of sync and bugs. The safest way to keep the system organized and bug free in **dependency ownership** strategy is:

- Treat the dependency's state as the source-of-truth.
- Set up 1-way or 2-way bindings to ensure nothing gets out of sync.  

Our `SpeechSettingsFeature` is considered `read-write | no` in the table above:

- `SpeechSettingsFeature` `get`s the `speechSettings` from the client on `init`.
- `SpeechSettingsFeature` `set`s the `speechSettings` on the client on any change.
- `SpeechSettingsFeature` assumes that `speechSettings` will not be changed by other sources during its lifetime (and therefore does not need to `observe`).

```swift
struct SpeechSettingsFeature: Reducer {
  struct State: Equatable {
    // ...
    var speechSettings: SpeechSynthesisSettings

    init() {
      @Dependency(\.speechSynthesisSettingsClient) var speechSettingsClient
      speechSettings = speechSettingsClient.get()
      // ...
    }
  }

  @Dependency(\.speechSynthesisSettingsClient) var speechSettingsClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // ...
    }
    .onChange(of: \.speechSettings) { _, newValue in
      Reduce { state, _ in
        .run { _ in
            try await speechSettingsClient.set(newValue)
        } catch: { _, _ in
            XCTFail("SpeechSettingsClient unexpectedly failed to write")
        }
      }
    }
  }
}
```

Our `ListeningQuizFeature` is different from `SpeechSettingsFeature` above; it requires only read-only to `SpeechSynthesisSettings` but  _does_ expect it to change during its lifetime (the in-session settings screen is presented over it). Therefore, it needs to implement get/observe.

```swift
struct ListeningQuizFeature: Reducer {
  struct State: Equatable {
    var speechSettings: SpeechSynthesisSettings
    // ...

    init() {
      @Dependency(\.speechSynthesisSettingsClient) var speechSettingsClient
      speechSettings = speechSettingsClient.get()
      // ...
    }
  }

  enum Action: BindableAction, Equatable {
    case onSpeechSettingsUpdated(SpeechSynthesisSettings)
    case onTask
    // ...
  }

  @Dependency(\.speechSynthesisSettingsClient) var speechSettingsClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .onSpeechSettingsUpdated(newValue):
        state.speechSettings = newValue
        return .none
      case .onTask:
        return .run { send in
          for await newValue in speechSettingsClient.observe() {
            await send(.onSpeechSettingsUpdated(newValue))
          }
        }
      }
      // ...
    }
  }
}
```

We again `get` the initial value from the dependency on `init`. But now there's a two step process for observing new values from the dependency:

1. Use `for await` to monitor `observe()`. Each time the stream emits a new value, send it back into the system with the action `.onSpeechSettingsUpdated(newValue)`.
2. When the reducer receives .`onSpeechSettingsUpdated`, overwrite `state.speechSettings`.

Note that there's a very subtle bug possibility to look out for when implementing `viewStore.send(.onTask)` in the view layer:

```swift
struct ListeningQuizView: View {
  let store: StoreOf<ListeningQuizFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(spacing: 0) {
      // ...
      }
      .task {
        // Option A:
        await viewStore.send(.onTask).finish()
      }
      .task {
        // Option B:
        viewStore.send(.onTask)
      }
    }
  }
}
```

What's the difference between Option A and Option B?

- Option A ties the lifetime of the task within the reducer to the _appearance_ of the view.
- Option B ties the lifetime of the task within the reducer to the _lifetime_ of the view.

In our case, "the task within the reducer" means observing changes to `SpeechSynthesisSettings` as `for await settings in client.observe()`. The difference is a subtle because a lot of the time _appearance_ and _lifetime_ of the view are the same.

However, when using `NavigationStack` and pushing view B after view A, view A will disappear and then reappear when view B is popped, and the appearance and lifetime with be different.

If we used Option A in `ListeningQuizView`, then `ListeningQuizFeature` would no longer be observing changes to `SpeechSynthesisSettings` while another view was pushed on the stack above it. If that pushed view changed `SpeechSynthesisSettings` _and_ `.observe()` was _not_ implemented as a "replay" type of stream, then `ListeningQuizFeature` would be stuck using an old value of `SpeechSynthesisSettings`, and this would probably be considered a bug.

In the case of `ListeningQuizFeature`, `SpeechSynthesisSettings` is only changed via a view that is presented as a sheet. Presenting a sheet does not cause the presenting view to disappear. Additionally, our `.observe()` stream is implemented as a "replay"-type stream. Therefore both Option A and Option B are both reasonable choices.

Of course, I should also emphasize that the dependency ownership strategy needs to take into account concurrency and delays inherent in observation and therefore update races. In the case above, the state is limited in scope and update frequency, and not expected to be changed from multiple views.

So why would you want to choose the **dependency ownership** strategy over the **root ownership** strategy?

- Features are more dependent on the dependency but less dependent on one another.
- Your view hierarchy is unbounded (any view can present any other view) and doesn't share a lot of state between nearby features.
- Features that share state don't have an obvious common ancestor that should be responsible to maintaining source-of-truth and persistence duties.
- You're willing to accept the overhead of creating a dependency and interfacing with it in addition to the inter-feature communication you may need to maintain anyway.
- If most of your state is in a database, it will probably feel much more natural to architect your features with **dependency ownership**.

## Related discussions

- [Dynamic dependencies · pointfreeco/swift-composable-architecture · Discussion #1287](https://github.com/pointfreeco/swift-composable-architecture/discussions/1287)
- [How to handle session-based dependencies? · pointfreeco/swift-dependencies · Discussion #42](https://github.com/pointfreeco/swift-dependencies/discussions/42)
- [Dependencies that depend on dynamic values · pointfreeco/swift-composable-architecture · Discussion #1775](https://github.com/pointfreeco/swift-composable-architecture/discussions/1775)
