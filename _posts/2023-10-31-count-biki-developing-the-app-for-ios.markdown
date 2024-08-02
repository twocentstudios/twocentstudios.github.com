---
layout: post
title: Count Biki - Developing the App for iOS
date: 2023-10-31 19:16:28
image: /images/count-biki-v1-quiz-settings-parent-child.png
tags: apple ios countbiki tca
---

Continuing my series of posts about my latest iOS app, Count Biki, I'll discuss the more interesting parts of app at version 1.1.

{% caption_img /images/count-biki-app-icon.png h300 Count Biki app icon, featuring the character Count Biki %}

Please check out the other posts in the series:

- **[Count Biki - Drill Japanese Numbers](/2023/10/29/count-biki-japanese-numbers/)** - the motivation behind the app and the solution I've begun to explore from the learner (user) perspective
- **[Count Biki - App and Character Design](/2023/10/30/count-biki-app-and-character-design/)** - the design process and specifics of creating the Count Biki character
- **This post** - a guided tour of the codebase and implementation details

Japanese learners can download the app from the [App Store](https://apps.apple.com/us/app/count-biki/id6463796779).

Like many of my other apps, Count Biki is open source on [GitHub](https://github.com/twocentstudios/count-biki). The commit/tag referenced in this post is [v1.1](https://github.com/twocentstudios/count-biki/tree/v1.1), so the main branch will not fully align with the post's content.

## Stats

Before starting digging into the details, I'll go over some stats about the app for context.

- The app has 6 screens (5 with behavior).
- The app has around 3600 lines of Swift code.
- The app has a minimum deployment target of iOS 16.4.
- The app supports only portrait mode and the iPhone form factor. There's no technical reason for this. It was mostly to reduce complexity, promotional material requirements, and testing for the first release.
- The app uses about 5 packages via Swift Package Manager: ComposableArchitecture, Collections, AsyncExtensions, DependenciesAdditions, ConfettiSwiftUI. ComposableArchitecture relies on several other pointfreeco packages, which I also use directly.
- The app uses a basic xcodeproj file.
- The app was archived with Xcode 17.0.1, which includes support for Swift 5.9, iOS 17, and (colloquially) SwiftUI 4, although I don't use any iOS 17 specific APIs.
- The app has a SwiftUI `App` entrypoint.
- The only network requests made by the app are via StoreKit 2.
- The app embeds an `scnassets` file for SceneKit-related files.
- The app uses the `licenseplist` library installed via Homebrew for generating a license file for packages.
- The app embeds no analytics framework.

## Architecture

The app is built all-in with [The Composable Architecture (TCA) 1.0](https://github.com/pointfreeco/swift-composable-architecture). This includes passing and scoping `Store`s through the view layer, creating `Reducer`s with `State` and `Action`s for most screens, and creating dependencies in the style of the [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) library.

This post is not a tutorial on using TCA. However, I will do my best to describe my experience learning TCA by writing this app, and mention the convenient points and the points that tripped me up while developing it.

I started rewriting an existing app with TCA back in 2020, but never finished it. I got stuck due to performance problems and the rewrite fell off my radar. Since then I've used SwiftUI extensively for both production and prototyping. The architecture of most of those projects has been either loose MVVM or everything-in-the-view style. This includes [Goalie](https://github.com/twocentstudios/goalie), which I consider MVVM style.

I started off development for Count Biki by prototyping the [listening quiz feature](https://github.com/twocentstudios/count-biki/blob/8195c7fde3703166d5b3a41743c8a19486448a14/count/Feature/ListeningQuizFeature.swift). This is the core of the app and the most complex feature (although the in app purchase support is arguably more complex).

{% caption_img /images/count-biki-v1-listening-quiz.png h700 the listening quiz screen %}

Even as the most complex screen, it's not particularly complex. But getting started was relatively slow because I was referencing the TCA 1.0 [guided tour videos](https://www.pointfree.co/collections/composable-architecture/composable-architecture-1-0) (as they were being released), the TCA [case studies](https://github.com/pointfreeco/swift-composable-architecture/tree/main/Examples/CaseStudies/SwiftUICaseStudies), and the OSS [isowords](https://github.com/pointfreeco/isowords/) codebase.

Even though TCA is more ergonomic than it was when I first started experimenting with it a few years ago, there were a lot more concepts to digest this time around, particularly around navigation. `BindableAction`, `@Bindable`, `@PresentationState`, the `Destination` reducer pattern.

### Shared state

The most difficult conceptual problem I had with TCA was the techniques for sharing state across an app.

#### Parent and child reducer intercommunication

My preconception of Redux-like systems such as TCA was that there was one big bag of state and any reducer could grab any part of it. The scoping part of TCA – paring down the state and actions to hand off to a subsystem – tripped me up. It wasn't clear to me whether changes to state made in child stores would change that same state in the parent part. In other words, I think it's similar to the sort of implicit learning curve there was while learning SwiftUI, namely:

- how does a parent communicate to a child?
- how does a child communicate to a parent?
- where is the source of truth for a piece of state?

I know the answers to the SwiftUI variant of these questions much better than the TCA variant, but they were certainly hard-won answers.

#### Quiz and settings example – source of truth in parent state

A simple example of my sharing state confusion is with my listening quiz and settings screen. The system has the following behavior:

- The quiz screen needs read-only settings values.
- The settings screen allows read/write access to settings values.
- The quiz presents the settings screen modally.
- The settings values are persisted to disk.

{% caption_img /images/count-biki-v1-quiz-settings-parent-child.png The quiz and settings screens (parent and child) %}

In view terms, the quiz screen is the parent and the settings screen is the child. But the quiz reducer needs access to the settings values immediately, which means that settings state can't be modeled as optional view state. The "is the settings view visible?" part of the state and the "what are the settings?" part of the state can't be combined in this case.

I modeled this by:

1. having a full copy of the settings values owned by the quiz reducer.
2. keeping a copy of the settings values as optional destination state.
3. loading the settings values from the dependency on initialization of the quiz state.
4. copying the current settings values to the settings state when the settings button is tapped as representation that the view is presented.
5. updating the "source of truth" version of settings values when the settings reducer sends an updated version, and ensuring the latest value is persisted to disk.

```swift
struct ListeningQuizFeature: Reducer {
    struct State: Equatable {
        var speechSettings: SpeechSynthesisSettings // 1
        @PresentationState var destination: Destination.State? // 2
        // ...

        init() {
            @Dependency(\.speechSynthesisSettingsClient) var speechSettingsClient
            self.speechSettings = speechSettingsClient.get() // 3
        }
    }
    
    struct Destination: Reducer {
        enum State: Equatable {
            case settings(SettingsFeature.State) // 2
        }
        // ...
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // 4
            case .titleButtonTapped:
                state.destination = .settings(.init(
                    topicID: state.topicID,
                    speechSettings: state.speechSettings,
                    sessionChallenges: state.completedChallenges
                ))
                return .none
            
            // 5
            case let .destination(.presented(.settings(.delegate(.speechSettingsUpdated(newSpeechSettings))))):
                state.speechSettings = newSpeechSettings
                do {
                    try speechSettingsClient.set(newSpeechSettings)
                } catch {
                    XCTFail("SpeechSettingsClient unexpectedly failed to write")
                }
                return .none
            }
        }
    // ...
}
```

This strategy of keeping source-of-truth state in a parent, passing a copy to the child reducer, and playing back changes from child to parent to ensure the state is in sync is seemingly the strategy shared in the [SyncUps](https://github.com/pointfreeco/swift-composable-architecture/blob/9b0f600253f467f61cbd53f60ccc243cc4ff27cd/Examples/SyncUps/SyncUps/AppFeature.swift#L28-L73) example app.

I'm not 100% happy with my strategy. For this simple app, it's fine. But it perhaps unnecessarily spreads responsibility for the settings across multiple reducers.

#### About and IAP example - source-of-truth in a dependency

Another way to go about sharing state between parent, child, or sibling reducers is:

- keep the source-of-truth state in a dependency
- mutating the state through the dependency
- set up a one-way binding to copy the dependency state into the reducer state from any number of reducers

My first impression of this strategy was that it goes against the ethos of TCA/Redux. Especially for cases where the state is *not* owned by an external subsystem under only loose control by the application, like from an Apple framework. However, reading [this discussion](https://github.com/pointfreeco/swift-composable-architecture/discussions/2320) made me consider dependency-managed state as more often the preferred option.

Concretely, this means a dependency with a get/set/observe interface. As a very generic example:

```swift
struct CurrentUserClient {
  var currentUser: () -> User?
  var setCurrentUser: (User?) async -> Void
  var currentUserStream: () async -> AsyncStream<User?>
}
```

Then each reducer that reads/writes/observes the current user can use `CurrentUserClient` like so:

1. Create a reducer-local derived copy of the state as `var currentUser: User?` in `UserReducer.State`.
2. In `State.init`, read in `currentUser` from the dependency.
3. Add a `Action.setCurrentUser(User)` action.
4. On receiving the `setCurrentUser` action, update the state iff the current user has changed.
5. Add a `.onChangeOf(\.currentUser)` modifier to the reducer to write updated values to the dependency's setter.
6. In `Action.onTask`, set up a long running async stream that sends new values back into the system as actions through `Action.setCurrentUser`.
7. The reducer should make changes to its local copy of `State.currentUser`.

The get/set/observe-style state allows both push and pull state management in reducers. For example, a pull-style read-only version would only need (1) (2), then an `Action.refreshButtonTapped` that copies the current value from the dependency into local reducer state.

Unfortunately, I've yet to find a more automated version of encapsulating the read/write/observe system.

The closest I got to implementing this type of system was while implementing my `About` and `TransylvaniaTier` (In app purchase) features.

{% caption_img /images/count-biki-v1-about-tier-parent-child.png the about and IAP screens (as parent and child) %}

The about screen is the parent. The IAP screen is the child. The about screen observes the purchases state from a dependency and updates its own state and its child state in response to changes. The key parts of the [full reducer](https://github.com/twocentstudios/count-biki/blob/8195c7fde3703166d5b3a41743c8a19486448a14/count/Feature/AboutFeature.swift) are clipped out below:

```swift
struct AboutFeature: Reducer {
    struct State: Equatable {
        var appIcon: AppIconFeature.State
        var transylvaniaTier: TransylvaniaTierFeature.State

        init() {
            @Dependency(\.tierProductsClient.purchaseHistory) var purchaseHistory
            appIcon = .init(isAppIconChangingAvailable: purchaseHistory().status == .unlocked)
            transylvaniaTier = .init(tierHistory: purchaseHistory())
        }
    }

    // ...

    var body: some ReducerOf<Self> {
        // ...
        Reduce { state, action in
            switch action {
            case let .onPurchaseHistoryUpdated(newHistory):
                state.appIcon.isAppIconChangingAvailable = newHistory.status == .unlocked
                state.transylvaniaTier.tierHistory = newHistory
                return .none
            case .onTask:
                return .run { send in
                    for await newHistory in purchaseHistoryStream() {
                        await send(.onPurchaseHistoryUpdated(newHistory))
                    }
                }
            }
            // ...
        }
    }
}
```

I will probably refactor the about and IAP reducers to be more independent in the future. I will probably want to present the IAP screen from more places throughout the app, which will require it to handle its own purchase history state updates.

#### Reducers with no state sharing

For the record, I found writing TCA reducers without inter-system state sharing to be very straightforward and exhibit all the benefits of TCA (testability, side-effect isolation, previewability, etc.). Of course, this app has not had multiple contributors nor survived years of releases, so take my experience as you will.

#### Sidebar: starting with one reducer

During the exploratory phase of development, what I really wanted to do was have one reducer with one state and one action enum shared across all the views in my app. Of course this doesn't scale and perhaps would cause performance problems sooner than later. But after I was more confident in the view structure, it'd be obvious how to split up the reducers and communicate state changes between them, avoiding a lot of rework. I'm sure there's a way to do this, but while I was learning TCA I didn't feel confident enough to stray from the case studies.

### Navigation

Navigation was one of the later additions to the TCA 1.0 release. Since the app only has a few screens, and I did at least a little reconfiguration of the UX, I never felt like I put the navigation tools through their paces.

#### Going "by-the-book"

I consider navigation "by-the-book" as storing each piece of navigation state in the reducer, usually with a separate `Destination` reducer.

I did this in a few places in the app that have obvious boundaries of behavior: The topics screen, the quiz screen, the settings screen, the about screen, etc.

However, in a few places within `NavigationStack`, I decided to take the lazy way and use raw `NavigationLink`s. The obvious downside to this is that the navigation state can only be directly manipulated by the user and not programmatically (notably through deep linking). In practice, I haven't found this to be an issue yet. I found the TCA `NavigationStack` modeling to feel _heavy_ enough at the outset that I didn't want to delay my release implementing it by-the-book.

The topics screen in particular felt like there was little benefit in creating an additional reducer to handle a screen of static data. I wanted the flexibility to keep all that topic view structure and logic in one place, even though in reality it's covering both `TopicCategory` and `Topic` entities. (Aside: it's kind of similar how SwiftUI forms give you the ability to configure a picker as inline or as a completely separate screen added to the stack, and the presentation parts are abstracted away from the developer.)

As I get more comfortable with TCA, I'll probably go back and move some of the navigation primitives into the TCA world.

#### Scoping stores

When implementing store scoping within the view layer, I found myself struggling a bit to craft the correct syntax to express the relationship between the parent and child features.

When going by-the-book, the store scoping feels like boilerplate (there's not a lot to think about). But when I did want to play outside the sandbox a bit, I realized I was in over my head and couldn't even get the scoping statement to compile.

The frustrating part was that I knew I either had to:

- look at a lot more store scoping examples as the raw syntax  
- go back and rewatch the pointfree episodes about the theory behind store scoping  

Or perhaps both? At this point, I can definitely tell I'm missing a key piece of my understanding of the _composable_ part of TCA, but I'm not sure yet how to fill in that missing piece. Or at least what the most efficient way to do so is.

In the end, I mostly avoided the issue entirely by either going more by-the-book with the structure of my features or completely eschewing TCA navigation as discussed in the previous section.

### Dependencies

I consider TCA to have 4 interdependent domains of complexity:

1. Reducers - composing the app logic by defining `State` and `Action`, and modifying state and kicking off side-effects on each action.
2. View-layer integration - using `ViewStore` and scoping `Store`.
3. Dependencies - the distinct layer of world state and side-effects.
4. Testing Reducers - exploiting the malleability of the dependency protocol in order to isolate the reducer layer from the dependency layer, and exploiting the one-way dependency of the view layer on the reducer layer to ignore the view layer.

The TCA philosophy is to divide responsibilities amongst the reducer, view, and dependency layers to enable maximum testing ability of the reducer layer, in both unit and integration tests (for some definition of "unit" and "integration"). UI testing is reasonable but discouraged. Dependency testing is rarely mentioned, but is of course possible depending on how you the developer choose to design your dependencies.

#### Writing dependencies in the pointfreeco-style

The pointfreeco-style of dependency design is unique (in my experience). And there are three distinct attributes:

1. The dependency interface as a struct containing one or more variables of functions.
2. Writing the dependency implementation as a class/actor in a way that you can create an instance of it within a static initializer of the dependency interface. When wrapping a system class as a dependency, often the system class is [used directly](https://github.com/pointfreeco/isowords/blob/40d59a899bbe54810bb0d7af0f3b72379c56bafb/Sources/FeedbackGeneratorClient/LiveKey.swift#L5-L11) in the static initializer.
3. Treating this dependency interface as a singleton throughout your application, including being initialized independently at app startup and having the same lifetime as the app.

My impression is that none of the above three attributes are _absolute requirements_ to use TCA or the [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) library. However, most of the official examples contain the three attributes. (One notable exception is [swift-dependencies-additions](https://github.com/tgrapperon/swift-dependencies-additions), which has its own internal system of [proxies](https://github.com/tgrapperon/swift-dependencies-additions/blob/main/Sources/DependenciesAdditionsBasics/Proxies.swift) to enable a more convenient interface for simple getters and setters).

For reference from the TCA case studies, an example of (1), the dependency interface as a struct [(SpeechClient)](https://github.com/pointfreeco/swift-composable-architecture/blob/9b0f600253f467f61cbd53f60ccc243cc4ff27cd/Examples/SyncUps/SyncUps/Dependencies/SpeechRecognizer.swift#L4-L11):

```swift
struct SpeechClient {
  var authorizationStatus: @Sendable () -> SFSpeechRecognizerAuthorizationStatus
  var requestAuthorization: @Sendable () async -> SFSpeechRecognizerAuthorizationStatus
  var startTask: @Sendable (SFSpeechAudioBufferRecognitionRequest) async -> AsyncThrowingStream<SpeechRecognitionResult, Error>
}
```

And an example of (2), creating an actor and then using it in a static initializer:

```swift
private actor Speech {
  private var audioEngine: AVAudioEngine? = nil
  private var recognitionTask: SFSpeechRecognitionTask? = nil
  private var recognitionContinuation:
    AsyncThrowingStream<SpeechRecognitionResult, Error>.Continuation?

  func startTask(
    request: SFSpeechAudioBufferRecognitionRequest
  ) -> AsyncThrowingStream<SpeechRecognitionResult, Error> {
      // ...
    }
  }
}

extension SpeechClient: DependencyKey {
  static var liveValue: SpeechClient {
    let speech = Speech()
    return SpeechClient(
      authorizationStatus: { SFSpeechRecognizer.authorizationStatus() },
      requestAuthorization: { /* ... */ },
      startTask: { request in await speech.startTask(request: request) }
    )
  }
}
```

Regarding (3), the "global-ness" of dependencies, in theory, the store-scoping initializers allow you to override dependencies all the way down a reducer hierarchy. For example:

```swift
Store(initialState: SettingsFeature.State()) {
    SettingsFeature()
} withDependencies: { deps in
    // TODO: Does this create a new instance each time an action is sent to the reducer?
    deps.speechSynthesisClient = .init() 
}
```

Or at the reducer-level:

```swift
// TODO: Does this create a new instance each time an action is sent to the reducer?
Reduce { state, action in
    // ...
}
.dependency(\.speechSynthesisClient, .init())
```

However, the feasibility of initializing a fresh dependency with data from the system is unclear to me. Especially since it seems like the above code would initialize a fresh instance of `speechSynthesisClient` each time a reducer is run (thousands of times per app run!).

There are a few other topics on the discussion boards that mention the global lifetime of dependencies:

- [Dynamic dependencies · pointfreeco/swift-composable-architecture · Discussion #1287](https://github.com/pointfreeco/swift-composable-architecture/discussions/1287)
- [How to handle session-based dependencies? · pointfreeco/swift-dependencies · Discussion #42](https://github.com/pointfreeco/swift-dependencies/discussions/42)
- [Dependencies that depend on dynamic values · pointfreeco/swift-composable-architecture · Discussion #1775](https://github.com/pointfreeco/swift-composable-architecture/discussions/1775)

For more complex applications than my own, I consider this limitation to be something to be carefully considered and architected around.

The related problem of doing some sort of one-time dependency initialization and setting up relationships between dependencies at app startup is also unclear to me. I [asked about it](https://github.com/pointfreeco/swift-composable-architecture/discussions/1713#discussioncomment-6681618) on the TCA discussions board, and [discussion #1287](https://github.com/pointfreeco/swift-composable-architecture/discussions/1287) touches on it briefly, but due to a change in my app requirements, I no longer needed to follow up on it.

There is certainly a wealth of information in the discussion boards I've yet to fully digest in the context of a more complex app. (Just a reminder that I'm writing this blog post for myself too as a way to process my thoughts and understanding on these inter-related concerns.)

#### Heisenbugs encountered while overriding dependencies

`withDependencies` is most often used as a developer tool – for testing, SwiftUI previews, or temporary debugging.

There were a few times where I ran into heisenbugs where my overridden dependencies at the app root or in previews weren't getting overridden. Or they were getting overridden in a parent reducer but not a child. These situations felt nearly impossible to debug without doing a full code-review of `swift-dependencies` and `TaskLocal`s.

#### Overriding dependencies for use with SwiftUI Previews

A key piece of the `ListeningQuiz` screen is the text-to-speech playback for each question. `AVSpeechSynthesizer` does not work on SwiftUI Previews or even the iOS simulator. TCA allowed me to easily mock out this dependency on just Previews and the simulator so it didn't become a blocker for quick UI development. I could spend as much time as I normally would developing off-device when I wasn't doing TTS-related tasks.

```swift
extension SpeechSynthesisClient: TestDependencyKey {
    static var previewValue: Self {
        @Dependency(\.continuousClock) var clock
        return Self(
            availableVoices: { [.mock1, .mock2] },
            defaultVoice: { .mock1 },
            speak: { _ in
                // Simulate 2 seconds of speech time
                try? await clock.sleep(for: .seconds(2))
            },
            speechRateAttributes: {
                .init(minimumRate: 0.0, maximumRate: 1.0, defaultRate: 0.5)
            },
            pitchMultiplierAttributes: {
                .init(minimumPitch: 0.5, maximumPitch: 2.0, defaultPitch: 1.0)
            }
        )
    }
}
```

#### The use of dependencies in Count Biki

After all that foreword, I can talk at least a little bit about how I used dependencies in CountBiki.

##### Stateless clients

`SpeechSynthesisClient` is responsible for wrapping `AVSpeechSynthesizer`, Apple's top-level API for text-to-speech.

My tendency for designing clients is to separate configuration and side-effects. In other words, clients should be stateless by default. For example, most `NetworkClient` APIs are designed like:

```swift
// Set configuration on app init or when current user is updated
NetworkClient.shared.setSessionToken("123abc")
NetworkClient.shared.setCacheSize(1024*10*10)

// Make an authenticated network request in some other part of the app
let users = try await NetworkClient.shared.fetchFriends()
```

In the above example, the `NetworkClient` is both a source-of-truth for network-related state _and_ a way to perform side-effects.

For most use cases, this style of API is very reasonable. The benefit is that the caller of `fetchFriends` needs zero knowledge of the `NetworkClient` configuration details.

I prefer to have `NetworkClient` be stateless. At the callsite, the above example would look like this instead:

```swift
// `networkConfiguration` is passed around a subsystem via dependency injection or generated from existing state
let networkConfiguration: NetworkClient.Configuration = ...
let users = try await NetworkClient().fetchFriends(networkConfiguration)
```

One benefit of stateless clients is that it's trivial (or at least more-so) to add multi-account support and use the same `NetworkClient` instance.

Another benefit is that it avoids the dependency initialization catch-22 we discussed earlier. A `NetworkClient` initialized at app startup and with the same lifetime as the app has no initialization race condition for needing its configuration set to a valid state before making calls.

The `NetworkClient` example is probably a bad one though. The underlying `URLSession` is stateful by design. It maintains its own cache, so wrapping it with a stateless interface could actually increase the chance of bugs, or completely break caching functionality. Another downside is that functions that could be encapsulated within the `NetworkClient` such as seamlessly renewing expired session tokens.

All of that is to say I used the stateless client pattern for `SpeechSynthesisClient`.

```swift
struct SpeechSynthesisSettings: Equatable, Codable {
    var voiceIdentifier: String?
    var pitchMultiplier: Float?
    var volume: Float?
    var rate: Float?
    var preUtteranceDelay: TimeInterval?
    var postUtteranceDelay: TimeInterval?
}

struct SpeechSynthesisUtterance {
    var speechString: String
    var settings: SpeechSynthesisSettings
}

struct SpeechSynthesisClient {
    var speak: @Sendable (SpeechSynthesisUtterance) async throws -> Void
    // ...
}
```

`SpeechSynthesisSettings` are persisted using their own client `SpeechSynthesisSettingsClient`. The top-level feature is responsible for fetching the settings and configuring an utterance to provide to the stateless `SpeechSynthesisClient`.

The implementation of `SpeechSynthesisClient` is admittedly weak. I should be using an actor.

##### Separating settings

I erred on the side of splitting persisted settings into separate clients, even though they all use the same underlying storage. Specifically: `SpeechSynthesisSettingsClient` and `TierPurchaseHistoryClient`. There's some unnecessary indirection at this point.

##### Wrapping StoreKit

Implementing StoreKit for a consumables tip jar was a bit of a headache.

Consumables act differently than subscriptions, so there were a few misunderstanding before I landed on an API for the `TierProductsClient` dependency.

The API I wanted for consumers of the dependency was similar to the read/write/observe API I mentioned previously. However, several of the mutations happen within the dependency itself while it's observing internals of StoreKit.

I wanted to use Combine's `CurrentValueSubject`. Swift Concurrency does not have a built-in replacement for `CurrentValueSubject`, and using `CurrentValueSubject` safely within the confines of Swift Concurrency is not a fully endorsed activity (especially with compiler warnings set to maximum). I didn't want to add another package dependency, however [AsyncExtensions](https://github.com/sideeffect-io/AsyncExtensions) seemed to provide exactly the tool I needed.

##### Topics

I somewhat regret my `Topic` interface. A `Topic` is a wrapper for generating question/answer pairs. I thought my interface would be generic enough for all kinds of topics.

```swift
struct Topic: Identifiable, Equatable {
    enum Skill {
        case listening
        case reading
    }

    enum Category {
        case number
        case money
        case duration
        case dateTime
        case counter
    }

    let id: UUID
    let skill: Skill
    let category: Category
    let title: String
    let description: String
}
```

A `Topic` itself is only a bag of data attributes. However, I create a wrapper struct internally called `TopicGenerator` when defining each `Topic` that also provides a question generator function. This allows me to expose `Topic` to the rest of the app as behaviorless and `Equatable`, but still behavior associated with each `Topic` and defined inline with it.

```swift
private struct TopicGenerator: Identifiable {
    var id: UUID { topic.id }
    let topic: Topic
    var generateQuestion: @Sendable (WithRandomNumberGenerator) throws -> (Question)
}
```

The `WithRandomNumberGenerator` part turned out to be pretty useless. I thought it might be useful for testing or otherwise seeding and keeping some control over values generated, but in the end it was just another field I had to work around.

An example of a `TopicGenerator` definition within the code:

```swift
TopicGenerator(
    topic: Topic(
        id: Topic.id(for: 201),
        skill: .listening,
        category: .duration,
        title: "Hours",
        description: "1-48時間"
    ),
    generateQuestion: { rng in
        let answer = rng { Int.random(in: 1 ... 48, using: &$0) }
        let postfix = "時間"
        let displayText = "\(answer)\(postfix)"
        let acceptedAnswer = String(answer)
        return Question(
            topicID: Topic.id(for: 201),
            displayText: displayText,
            spokenText: displayText,
            answerPrefix: nil,
            answerPostfix: postfix,
            acceptedAnswer: acceptedAnswer
        )
    }
)
```

I'm defining a static ID for each `Topic` for a future where user answers are persisted and need to be associated back to a `Topic` internally.

Another part of the interface I went back and forth on was whether I should keep the generated question and user answer as `Int` or whether all answers should converge to `String`. I kept the latter method (`String`) but realized during development that allowing access to the numerical values would give more flexibility in comparing and reformatting values.

```swift
struct TopicClient {
    var allTopics: @Sendable () -> IdentifiedArrayOf<Topic>
    var generateQuestion: @Sendable (UUID) throws -> (Question)
}
```

The `TopicClient` itself simply abstracts away looking up a `Topic` by its ID and generating a `Question` for it.

A downside to this stateless design is that all `TopicGenerator`s must have the input signature (they can't take distinct parameters). Additionally, I can't guarantee within the `TopicClient` that subsequently generated questions aren't the same.

#### BikiAnimation

There's a unique friction point we sometimes encounter with SwiftUI being a declarative system but needing to interface with imperative events.

One of these friction points is animations.

For my Count Biki SceneKit model, I have 1 idle animation and 2 brief animations that play for a second or two each. One animation is triggered when the user gets a question right. One animation is played when the user gets a question wrong.

What's the right way to model this in SwiftUI?

This problem is easier to solve for something like the confetti animation that plays when the user gets a question right. We can model this as an integer that counts up by one each time the animation should play. The SwiftUI view will playback the animation any time that value changes (whether it be by 1 or 100).

```swift
struct State: Equatable {
    var confettiAnimation: Int = 0
    // ...
}

// Change `confettiAnimation` when a correct answer is submitted
Reduce { state, action in
    switch action {
    case .answerSubmitButtonTapped:
        // ...
        state.confettiAnimation += 1
    // ...
    }
}

// `ConfettiCannon` will observe changes to this value
VStack { /* ... */ }
    .confettiCannon(counter: viewStore.confettiAnimation)

// Or we can use `.animation` with any `Equatable` value
VStack { /* ... */ }
    .animation(.default, value: viewStore.confettiAnimation)
```

But for 2 different types of animation, how can we model it? Well we could just have 2 different counter variables and keep increasing the number of variables and the number of change observers. But this doesn't scale well.

Another way to model this is with a UUID wrapper:

```swift
struct BikiAnimation: Equatable {
    enum Kind {
        case correct
        case incorrect
    }

    let id: UUID
    let kind: Kind
}

struct State: Equatable {
    var bikiAnimation: BikiAnimation?
    // ...
}

Reduce { state, action in
    switch action {
    case .answerSubmitButtonTapped:
        // ...
        state.bikiAnimation = .init(id: UUID(), kind: .correct)
    // ...
    }
}

SceneView { /* ... */ }
    .onChange(of: bikiAnimation) { newValue in
        switch newValue?.kind {
        case .correct:
            sceneState.playCorrect()
        case .incorrect:
            sceneState.playIncorrect()
        case nil:
            break
        }
    }
```

### Testing

One of TCA's biggest wins is ease of testing. I dabbled in testing, but as of the 1.1 release I've only written 1 test. My reasons for this lack of tests are the usual excuses: it's an MVP; I wanted to ship and get user feedback ASAP; the view-layer and dependency-layers were actually more error prone than the reducer-layer logic; the structure of the app was constantly in flux during initial development.

Regardless of these excuses, I appreciate the testability facilitated by TCA and I'll certainly be adding more, not fewer, tests over time to the project.

## SwiftUI

Although the focus of this post has been its architecture and relationship to TCA, I do want to mention a few parts of the view layer that stand out in some way.

### BikiView

[`BikiView`](https://github.com/twocentstudios/count-biki/blob/8195c7fde3703166d5b3a41743c8a19486448a14/count/View/CountBikiView.swift) is the wrapper for the Count Biki character avatar derived from a SceneKit .scn file.

Wrapping stateful view architecture like SceneKit or UIKit in SwiftUI can sometime be tricky.

The `SceneState` struct holds onto the loaded `SCNScene` containing Biki, and also handles loading and playing back the animations on demand from the separate .dae files.

Note that adding this view to a hierarchy non-trivially increases CPU usage and energy usage for the device. For now, I think this is an okay trade off, but SceneKit's relative resource intensiveness is something to be aware of.

### Styling with base iOS classes

Apple's human interface guidelines define [system colors](https://developer.apple.com/design/human-interface-guidelines/color) and [system typography](https://developer.apple.com/design/human-interface-guidelines/typography).

When I'm not working closely with a designer, it's much easier to rely on the Apple-provided design system than create my own one-off design system. It takes a lot of the burden off of me as an individual to ensure proper accessibility, support dark mode, ensure a base-level of visual quality, and spend time designing my own controls.

The tradeoff is that the visual style is a lot less _fun_ and _unique_ than it could/should be.

For now, I feel okay about this compromise. After ensuring a base level of functionality, I feel more comfortable spending time exploring visual style adjustments.

Even after 5 versions, I still feel using the Apple design system primitives can be unintuitive. For example, many of the system colors are still defined only in `UIKit.UIColor` and not `SwiftUI.Color` – for example `UIColor.secondarySystemBackground`. `SwiftUI.Color` has the limited `primary` and `secondary` variants.

The meaning of `tint` and `accentColor` is subtly different, as are their SwiftUI modifiers (`.accentColor()` was deprecated and `.tintColor()` added in iOS 15).

Semantic/Dynamic Type font styles like `Font.title` and `Font.body` don't always map well to app styles, and there's never been much guidance from Apple on how to do so. 

Aside: I've never worked with a designer who understood or considered these semantic font styles or Dynamic Type. The most Apple advertises Dynamic Type to designers is these three sentences from the [HIG](https://developer.apple.com/design/human-interface-guidelines/typography):

> Consider using the built-in text styles. The system-defined text styles give you a convenient and consistent way to convey your information hierarchy through font size and weight. Using text styles with the system fonts also supports Dynamic Type and the larger accessibility type sizes (where available), which let people choose the text size that works for them.

### Laying out the quiz screen without a scroll view

It's arguably [best practice](https://lickability.com/blog/every-screen-in-your-app-should-be-a-scrolling-view/) to use a scroll view for every screen in your app by default.

The quiz screen is designed to be rapid fire, and wouldn't really make sense to force the user to scroll up and down constantly while they are trying to power through questions.

However, I was of course going against the laws of physics trying to fit in all the UI elements I wanted while still supporting all small screen sizes and accessibility Dynamic Type sizes. This was not an easy problem to solve, and for the version 1.1 release I had to cheat a bit by limiting the accessibility Dynamic Type size to the second level. I feel shame doing so, but at the moment it's better to artificially enforce a limit rather than have a broken layout.

{% caption_img /images/count-biki-v1-listening-quiz-accessibility.png h600 The listening quiz screen at maximum supported accessibility size %}

### Adding commas dynamically to the TextField

Text input is way more difficult than it seems. There's a ton of complexity wrapped around the simple SwiftUI interface of `TextField($text)`.

Answering a quiz question with only numbers is much simpler than all the functionality needed for a multi-lingual, editable text field. However, since `TextField` already exists, I preferred to use it with as few customizations as possible before implementing my own text input system from scratch.

However, my beta users ran into problems when answering questions with long numbers like `125400000`. Without comma separators, it quickly becomes impossible to know exactly which number you've entered.

Although it's certainly possible, I felt uncomfortable modifying the TextField's string while the user is typing to add separators, thinking that there'd be edge cases (especially with moving the cursor) I didn't have time to thoroughly test. As a pragmatic (and hopefully temporary) solution, I instead added formatted text that mirrors the input string right above the TextField.

{% caption_img /images/count-biki-v1-listening-quiz-formatted-text.png h200 A temporary solution for formatting the input string without interrupting the default TextField handling %}

## Conclusion

These were the various concerns running through my head while developing this simple app.

Usually when working in a team I write these kind of explanations in pull request descriptions. But in this case I've saved everything until the first release.

I don't like to share "solutions" to problems before I'm completely sure they're robust enough to survive the long term. That's why the slant of the above text is more "here was X problem and how I solved it" than "here's exactly how to solve X problem".

I also share some of these thoughts day-to-day on [Mastodon](https://hachyderm.io/@twocentstudios), so feel free to follow me there. And if you want to dig into the codebase, here's [one more link](https://github.com/twocentstudios/count-biki).

Thanks for reading this post or the whole series.
