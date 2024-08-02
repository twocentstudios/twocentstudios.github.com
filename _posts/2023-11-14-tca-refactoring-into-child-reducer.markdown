---
layout: post
title: Refactoring and Composing a Feature in The Composable Architecture
date: 2023-11-14 12:00:00
image: /images/count-reducer-refactor-screens.png
tags: apple ios tca
---

In this post, I'll show an example of how I refactored a reusable feature/view pair from two screen-level reducers in my app Count Biki that uses [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) (TCA). This post acts as a simplified walkthrough of the [pull request](https://github.com/twocentstudios/count-biki/pull/4) on the project's [open source repo](https://github.com/twocentstudios/count-biki).

This has some similarities to the case study [Reusable Favoriting](https://github.com/pointfreeco/swift-composable-architecture/blob/17c0cba2ef93f9322707f2c84e6b5680cd05baf0/Examples/CaseStudies/SwiftUICaseStudies/04-HigherOrderReducers-ReusableFavoriting.swift), so please refer to that official example as well.

## Background

[Count Biki](/2023/10/29/count-biki-japanese-numbers/) is my first App Store-released app using TCA. In my v1.0 release, I struggled to properly extend TCA concepts beyond just the basics illustrated in the case studies and example apps. I wrote about some of those lingering misunderstandings in [this post](/2023/10/31/count-biki-developing-the-app-for-ios/) too.

While working on the next set of features for the v1.1 and v1.2 releases, I've started to feel the dots start to connect regarding TCA. One of those is actually understanding reducer nesting to actually unlock the _composability_ part of The _Composable_ Architecture.

The goal of this post is to share a real world example of a small refactoring in hopes that it will help other TCA novices connect those same dots. And also solicit feedback from TCA veterans who may know better ways to accomplish the same refactorings I'll present.

## About the app and feature

Count Biki is a flashcard app for randomly generated Japanese numbers. The questions are audio read by the build-in text-to-speech (TTS)engine. The answers are numerals input by the user via the standard 10-key numeric keyboard.

A _session_ is a set of questions presented to the user about one _topic_.

Before choosing a topic, the user can optionally configure some settings. Once the user starts a _session_ by selecting a _topic_, they can configure a subset of settings related to voice and the TTS engine.

{% caption_img /images/count-reducer-refactor-screens.png The pre-session setting screen, the quiz screen, and the in-session settings screen. The red box is duplicated code that we want to refactor and compose. %}

The voice settings are in their own `List` `Section` and require:

- logic to handle the bindings
- glue code to convert the view state to some `Codable` state
- debounced writing to the persistence client

My first implementation of adding the pre-session setting screen was to simply duplicate both the view and reducer from the existing in-session settings feature. I did that (and a few other tasks) in the PR [Add question/time limit quiz modes](https://github.com/twocentstudios/count-biki/pull/3).

## Goal

Our goal is to:

1. refactor the duplicate code in the pre-session and in-session settings features for the voice settings into its own `Reducer` and `View` pair.
2. re-integrate this `SpeechSettingsFeature` and `SpeechSettingSection` back into the pre-session and in-session settings features.
3. ensure any parent features that were relying on communication with either pre-session or in-session settings features still work as expected.

{% caption_img /images/count-reducer-refactor-features.png Configuration of the features and dependencies before and after %}

# Refactoring

## In-session `SettingsFeature` before refactoring

Let's start by looking at a simplified version of the code from the in-session settings feature, named `SettingsFeature` before starting the refactor.

```swift
struct SettingsFeature: Reducer {
  struct State: Equatable {
    var availableVoices: [SpeechSynthesisVoice]
    @BindingState var rawSpeechRate: Float
    @BindingState var rawVoiceIdentifier: String?
    @BindingState var rawPitchMultiplier: Float
    let pitchMultiplierRange: ClosedRange<Float>
    let speechRateRange: ClosedRange<Float>
    var speechSettings: SpeechSynthesisSettings

    let topic: Topic // assume the `Topic` is set

    // The initial values for `speechSettings` are passed in from the parent feature. This feature is only responsible for modifying `speechSettings` in place, assuming the parent will monitor those changes. 
    init(speechSettings: SpeechSynthesisSettings) {
      @Dependency(\.speechSynthesisClient) var speechClient

      self.speechSettings = speechSettings

      // Read and set valid ranges and default values from `speechClient`.
      availableVoices = ...
      speechRateRange = ...
      pitchMultiplierRange = ...

      // Set the initial "raw" values that are bound directly to the view layer from the input `speechSettings`.
      rawVoiceIdentifier = ...
      rawSpeechRate = ...
      rawPitchMultiplier = ...
    }
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case doneButtonTapped
    case onSceneWillEnterForeground
    case onTask
    case pitchLabelDoubleTapped
    case rateLabelDoubleTapped
    case testVoiceButtonTapped
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency.Notification(\.sceneWillEnterForeground) var sceneWillEnterForeground
  @Dependency(\.speechSynthesisClient) var speechClient

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.$rawSpeechRate):
        state.speechSettings.rate = state.rawSpeechRate
        return .none
      case .binding(\.$rawVoiceIdentifier):
        state.speechSettings.voiceIdentifier = state.rawVoiceIdentifier
        return .none
      case .binding(\.$rawPitchMultiplier):
        state.speechSettings.pitchMultiplier = state.rawPitchMultiplier
        return .none
      case .binding:
        return .none
      case .doneButtonTapped:
        return .run { send in
          await dismiss()
        }
      case .pitchLabelDoubleTapped:
        state.rawPitchMultiplier = speechClient.pitchMultiplierAttributes().defaultPitch
        state.speechSettings.pitchMultiplier = state.rawPitchMultiplier
        return .none
      case .rateLabelDoubleTapped:
        state.rawSpeechRate = speechClient.speechRateAttributes().defaultRate
        state.speechSettings.rate = state.rawSpeechRate
        return .none
      case .onSceneWillEnterForeground:
        // We expect the user will leave the app to download more voices and we should refetch
        // voices from the system when the app returns to the foreground.
        state.availableVoices = speechClient.availableVoices()
        return .none
      case .onTask:
        return .run { send in
          for await _ in sceneWillEnterForeground {
            await send(.onSceneWillEnterForeground)
          }
        }
      case .testVoiceButtonTapped:
        // Use `speechClient` to speak a test phrase with the current `speechSettings`.
        // ...
      }
    }
  }
}
```

Nearly all the `State` and `Action` components are related to the speech settings. One method to start our refactor could be to rename the whole feature to `SpeechSettingsFeature` and _extract_ the parent `SettingsFeature` elements from it.

But before we do that, let's take a quick look at the view.

```swift
struct SettingsView: View {
  let store: StoreOf<SettingsFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        Form {
          Section {
            // Topic-related views
            // ...
          } header: {
            Text("Topic")
          }

          // Looks like almost all speech settings are contained within this `Section` besides the `.task` modifier.
          Section {
            if let $unwrappedVoiceIdentifier = Binding(viewStore.$rawVoiceIdentifier) {
              Picker(selection: $unwrappedVoiceIdentifier) {
                ForEach(viewStore.availableVoices) { voice in
                  Text(voice.name)
                    .tag(Optional(voice.voiceIdentifier))
                }
              } label: {
                Text("Voice name")
              }
              .pickerStyle(.navigationLink)
              NavigationLink {
                GetMoreVoicesView()
              } label: {
                Text("Get more voices")
              }
              HStack {
                Text("Rate")
                  .onTapGesture(count: 2) {
                    viewStore.send(.rateLabelDoubleTapped)
                  }
                Slider(value: viewStore.$rawSpeechRate, in: viewStore.speechRateRange, step: 0.05) {
                  Text("Speech rate")
                } minimumValueLabel: {
                  Image(systemName: "tortoise")
                } maximumValueLabel: {
                  Image(systemName: "hare")
                }
              }
              // Pitch settings slider (similar to rate above)
              // ...
              }
              Button {
                viewStore.send(.testVoiceButtonTapped)
              } label: {
                HStack(spacing: 10) {
                  Image(systemName: "person.wave.2")
                  Text("Test Voice")
                }
                .frame(maxWidth: .infinity, alignment: .center)
              }
            } else {
              NavigationLink {
                GetMoreVoicesView()
              } label: {
                HStack {
                  Text("Error: no voices found on device")
                    .foregroundStyle(Color.red)
                }
              }
            }
          } header: {
            Text("Voice Settings")
              .font(.subheadline)
          }
        }
        // Toolbar-styling modifiers
        // ...
      }
      .task {
        await viewStore.send(.onTask).finish()
      }
    }
  }
}
```

The `SettingsFeature` above looks very similar to the `PreSettingsFeature`, so I'll only show the result of that refactor later.

## In-session `SettingsFeature` after refactoring

Since `SettingsFeature` actually contains mostly `SpeechSettingsFeature` functionality, we'll rename the `SettingsFeature` to `SpeechSettingsFeature` and then create a new `SettingsFeature` as the parent.

```swift
struct SettingsFeature: Reducer {
    struct State: Equatable {
        // `SettingsFeature` holds the source of truth for `SpeechSettingsFeature.State`.
        var speechSettings: SpeechSettingsFeature.State

        let topic: Topic // assume `Topic` is set

        init() {
            self.speechSettings = .init()
        }
    }

    // This `Action` no longer needs `BindableAction` conformance.
    enum Action: Equatable {
        // `SettingsFeature` is only responsible for the `doneButton`.
        case doneButtonTapped

        // `SettingsFeature` forwards `SpeechSettingsFeature` actions to the child reducer.
        case speechSettings(SpeechSettingsFeature.Action)
    }

    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        // This scoping reducer is what's responsible for extracting the state and actions from the
        // parent reducer `SettingsReducer` and passing them through to the child `SpeechSettingsFeature`.
        Scope(state: \.speechSettings, action: /Action.speechSettings) {
            SpeechSettingsFeature()
        }
        Reduce { state, action in
            switch action {
            case .doneButtonTapped:
                return .run { send in
                    await dismiss()
                }
            case .speechSettings:
                return .none
            }
        }
    }
}
```

And the refactored `SettingsView`:

```swift
struct SettingsView: View {
  let store: StoreOf<SettingsFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        Form {
          Section {
            // Topic-related views
            // ...
          } header: {
            Text("Topic")
          }

          // We've refactored all this view code into `SpeechSettingsSection`.
          // However, `SpeechSettingsSection` expects a store with type `StoreOf<SpeechSettingsReducer>`,
          // so we have to scope the `StoreOf<SettingsFeature>` held by this view.
          SpeechSettingsSection(
            store: store.scope(state: \.speechSettings, action: { .speechSettings($0) })
          )
        }
        // Toolbar-styling modifiers
        // ...
      }
    }
  }
}
```

You'll notice that the `.task` modifier connected to the `SettingsView`'s `NavigationStack` lives as long as `SettingsView`. We're using `.task` in the `SpeechSettingsFeature` to listen for app foreground changes. We want to do that with the same lifetime as `SettingsView`. However, since `SpeechSettingsSection` is a section within a `Form`/`List`/`LazyVStack`, its lifetime will be tied to its position within the internal `ScrollView`. But we want it to have the same lifetime as the parent. Therefore, we manually pass the `.onTask` modifier from parent to child above instead of implementing `.onTask` directly from `SpeechSettingsSection` to `SpeechSettingsFeature`. It's a  subtle difference that could lead to bugs depending the user's scroll position.

## `SpeechSettingsFeature` after refactoring

`SpeechSettingsFeature` looks pretty similar to our before-refactoring version of `SettingsFeature`, but let's show the simple version of it after refactoring for completeness.

```swift
struct SpeechSettingsFeature: Reducer {
    struct State: Equatable {
        var availableVoices: [SpeechSynthesisVoice]
        @BindingState var rawSpeechRate: Float
        @BindingState var rawVoiceIdentifier: String?
        @BindingState var rawPitchMultiplier: Float
        let pitchMultiplierRange: ClosedRange<Float>
        let speechRateRange: ClosedRange<Float>

        var speechSettings: SpeechSynthesisSettings

        init() {
            @Dependency(\.speechSynthesisSettingsClient) var speechSettingsClient
            @Dependency(\.speechSynthesisClient) var speechClient

            self.speechSettings = speechSettingsClient.get()

            // Read and set valid ranges and default values from `speechClient`.
            availableVoices = ...
            speechRateRange = ...
            pitchMultiplierRange = ...

            // Set the initial "raw" values that are bound directly to the view layer from the input `speechSettings`.
            rawVoiceIdentifier = ...
            rawSpeechRate = ...
            rawPitchMultiplier = ...
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case onSceneWillEnterForeground
        case onTask
        case pitchLabelDoubleTapped
        case rateLabelDoubleTapped
        case testVoiceButtonTapped
    }

    private enum CancelID {
        case saveDebounce
    }

    @Dependency(\.continuousClock) var clock
    @Dependency.Notification(\.sceneWillEnterForeground) var sceneWillEnterForeground
    @Dependency(\.speechSynthesisSettingsClient) var speechSettingsClient
    @Dependency(\.speechSynthesisClient) var speechClient

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.$rawSpeechRate):
                state.speechSettings.rate = state.rawSpeechRate
                return .none
            case .binding(\.$rawVoiceIdentifier):
                state.speechSettings.voiceIdentifier = state.rawVoiceIdentifier
                return .none
            case .binding(\.$rawPitchMultiplier):
                state.speechSettings.pitchMultiplier = state.rawPitchMultiplier
                return .none
            case .binding:
                return .none
            case .pitchLabelDoubleTapped:
                state.rawPitchMultiplier = speechClient.pitchMultiplierAttributes().defaultPitch
                state.speechSettings.pitchMultiplier = state.rawPitchMultiplier
                return .none
            case .rateLabelDoubleTapped:
                state.rawSpeechRate = speechClient.speechRateAttributes().defaultRate
                state.speechSettings.rate = state.rawSpeechRate
                return .none
            case .onSceneWillEnterForeground:
                state.availableVoices = speechClient.availableVoices()
                return .none
            case .onTask:
                return .run { send in
                    for await _ in sceneWillEnterForeground {
                        await send(.onSceneWillEnterForeground)
                    }
                }
            case .testVoiceButtonTapped:
                let spokenText = "1234"
                enum CancelID { case speakAction }
                return .run { [settings = state.speechSettings] send in
                    await withTaskCancellation(id: CancelID.speakAction, cancelInFlight: true) {
                        do {
                            let utterance = SpeechSynthesisUtterance(speechString: spokenText, settings: settings)
                            try await speechClient.speak(utterance)
                        } catch {
                            assertionFailure(error.localizedDescription)
                        }
                    }
                }
            }
        }
        .onChange(of: \.speechSettings) { _, newValue in
            // We've added a debounced save to disk action that runs on any change to `speechSettings`.
            // This allows our feature to be more self-contained and reusable.
            // Other features will have to rely on observing state from `speechSettingsClient`
            // instead of passing it via actions through the reducer hierarchy.
            Reduce { state, _ in
                .run { _ in
                    try await withTaskCancellation(id: CancelID.saveDebounce, cancelInFlight: true) {
                        try await clock.sleep(for: .seconds(0.25))
                        do {
                            try speechSettingsClient.set(newValue)
                        } catch {
                            XCTFail("SpeechSettingsClient unexpectedly failed to write: \(error)")
                        }
                    }
                }
            }
        }
    }
}
```

And the `Section`:

```swift
struct SpeechSettingsSection: View {
    // Note: the `store` is now specialized to `SpeechSettingsFeature` and must be
    // properly scoped in the parent reducer.
    let store: StoreOf<SpeechSettingsFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Section {
                if let $unwrappedVoiceIdentifier = Binding(viewStore.$rawVoiceIdentifier) {
                    Picker(selection: $unwrappedVoiceIdentifier) {
                        ForEach(viewStore.availableVoices) { voice in
                            Text(voice.name)
                                .tag(Optional(voice.voiceIdentifier))
                        }
                    } label: {
                        Text("Voice name")
                    }
                    .pickerStyle(.navigationLink)
                    NavigationLink {
                        GetMoreVoicesView()
                    } label: {
                        Text("Get more voices")
                    }
                    HStack {
                        Text("Rate")
                            .onTapGesture(count: 2) {
                                viewStore.send(.rateLabelDoubleTapped)
                            }
                        Slider(value: viewStore.$rawSpeechRate, in: viewStore.speechRateRange, step: 0.05) {
                            Text("Speech rate")
                        } minimumValueLabel: {
                            Image(systemName: "tortoise")
                        } maximumValueLabel: {
                            Image(systemName: "hare")
                        }
                    }
                    HStack {
                        Text("Pitch")
                            .onTapGesture(count: 2) {
                                viewStore.send(.pitchLabelDoubleTapped)
                            }
                        Slider(value: viewStore.$rawPitchMultiplier, in: viewStore.pitchMultiplierRange, step: 0.05) {
                            Text("Pitch")
                        } minimumValueLabel: {
                            Image(systemName: "dial.low")
                        } maximumValueLabel: {
                            Image(systemName: "dial.high")
                        }
                    }
                    Button {
                        viewStore.send(.testVoiceButtonTapped)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "person.wave.2")
                            Text("Test Voice")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else {
                    NavigationLink {
                        GetMoreVoicesView()
                    } label: {
                        HStack {
                            Text("Error: no voices found on device")
                                .foregroundStyle(Color.red)
                        }
                    }
                }
            } header: {
                Text("Voice Settings")
                    .font(.subheadline)
            }
            .task {
                await viewStore.send(.onTask).finish()
            }
        }
    }
}
```

## Reconsidering parent/child communication

There's actually one more step we can take that will reduce the complexity of parent-to-child reducer communication. It has to do with how we're sharing the `SpeechSynthesisSettings` across features.

Let's look at a visual of the features one more time:

{% caption_img /images/count-reducer-refactor-screens.png The pre-session setting screen, the quiz screen, and the in-session settings screen %}

Regarding hierarchy:

- There is a quiz navigation screen that acts as a wrapper for navigating between the 3 quiz screens. The quiz screen is a the root of a `NavigationStack`. The summary screen can be pushed onto the stack. And the in-session settings is presented modally. This creates a layer of indirection between the quiz screen (which reads `SpeechSynthesisSettings`) and the in-session setting screen (which reads/writes `SpeechSynthesisSettings`).
- The pre-session settings screen and quiz navigation screen are siblings, and their presentation _is_ mutually-exclusive (only one is presented at a time).
- The in-session settings screen is a child of the quiz navigation screen.

{% caption_img /images/count-reducer-refactor-hierarchy-access.png The hierarchy of features that need some kind of access to `SpeechSynthesisSettings` %}

Regarding read and write access to `SpeechSynthesisSettings`:

- The pre-session settings screen needs read/write access to `SpeechSynthesisSettings`.
- The quiz screen needs read-only access to `SpeechSynthesisSettings`.
- The in-session settings screen needs read/write access to `SpeechSynthesisSettings`.
- The quiz navigation screen needs no access to `SpeechSynthesisSettings`.

Modeling this state is something I struggled with and wrote about [in my initial post](/2023/10/31/count-biki-developing-the-app-for-ios/) detailing the development of v1.0 of this app. Through the process of adding a few new features and refactoring, it's become much clearer of the two different strategies to model this kind of state and the tradeoffs for each.

By "this kind of state" I mean state that is:

- shared with varying read/write access between parent/child/sibling features.
- persisted in some form.

I wrote about the [two strategies to model state](/2023/11/13/tca-strategies-sharing-state) in TCA: _root ownership_ and _dependency ownership_.

What I realized is that in the above refactoring, I had unnecessarily been mixing both _root ownership_ and _dependency ownership_. Or, more precisely, I'd been superfluously using _root ownership_.

`SettingsFeature` and `PreSettingsFeature` did not need to hold onto and scope the state/actions of `SpeechSettingsFeature` because the source of truth for the underlying state of `SpeechSettingsFeature` is in the dependency `SpeechSynthesisSettingsClient`.

Let's take a look at the changes to `SettingsFeature` after one more step of refactoring. I won't show `PreSettingsFeature` because it's basically the same.

```diff
struct SettingsFeature: Reducer {
    struct State: Equatable {
-        var speechSettings: SpeechSettingsFeature.State

        let topic: Topic // assume `Topic` is set

        init() {
-            self.speechSettings = .init()
        }
    }

    // This `Action` no longer needs `BindableAction` conformance.
    enum Action: Equatable {
        case doneButtonTapped
-        case speechSettings(SpeechSettingsFeature.Action)
    }

    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
-        Scope(state: \.speechSettings, action: /Action.speechSettings) {
-            SpeechSettingsFeature()
-        }
        Reduce { state, action in
            switch action {
            case .doneButtonTapped:
                return .run { send in
                    await dismiss()
                }
-            case .speechSettings:
-                return .none
            }
        }
    }
}
```

```diff
struct SettingsView: View {
  let store: StoreOf<SettingsFeature>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        Form {
          Section {
            // Topic-related views
            // ...
          } header: {
            Text("Topic")
          }

          SpeechSettingsSection(
-            store: store.scope(state: \.speechSettings, action: { .speechSettings($0) })
+            store: Store(initialState: .init()) {
+                SpeechSettingsFeature()
+            }
          )
        }
        // Toolbar-styling modifiers
        // ...
      }
    }
  }
}
```

We were able to remove some unnecessary code and complexity from both `SettingsFeature` and `PreSettingsFeature`. `SpeechSettingsFeature` is now a drop-in feature.

As discussed in the [two strategies to model state](/2023/11/13/tca-strategies-sharing-state) post, there are tradeoffs to using the _root ownership_ and _dependency ownership_ strategies. In the case of `SpeechSettingsFeature`, _dependency ownership_ seems like the most reasonable choice at the moment.

## Conclusion

We succeeded in refactoring the duplicated functionality in `SettingsFeature` and `PreSettingsFeature` into one composable `SpeechSettingsFeature`. We also used this opportunity to convert the underlying state sharing strategy to _dependency ownership_.
