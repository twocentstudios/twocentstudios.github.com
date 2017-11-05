---
layout: post
title: Asynchronous Changes to View Models Using Interactors
date: 2017-11-05 17:08:47
---

In this post we'll take a look at a technique to facilitate the changes to our view states in Swift, as well as how to incorporate asynchronous behavior into this system. I'll refer to this system by the name _interactor_ throughout this post.

This will be the longest post in the series. It builds on the previous posts about [view models](/2017/07/24/modeling-view-state/) and [reducers](/2017/08/02/transitioning-between-view-states-using-reducers/) so please read those posts before continuing.

In the next post, we'll look at how we can use the interactor we've created in this post to drive our view layer.

## Background

So far, we've been working with stateless value types (view models) and a stateless function (reducer). Since our view layer is inherently stateful, we need a reference type to manage the current state (view model) and its changes over time.

In the last post about reducers, we mentioned finite state machines a few times. Our interactor will be the implementation of the finite state machine for our view state.

> Note that in this post, I'll be using [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) in my reference implementation.

## Architecture

I need to make a quick aside about how this architecture relates to prior art. The interactor, reducer, and view model I've discussed all belong to a middle layer between the view layer and the model layer, in many standard MVVM architectures called the view model layer.

In the architecture I'm presenting, there is a difference in nomenclature between a stateless view model and a stateful view model, whereas in classic MVVM, this distinction isn't made.

Going forward, an **interactor** will be a reference type that holds representations of state over time (variables, signals, data sources). A *view model* will be a value type that holds a representation of state at one moment in time.

## Goal

Our goal for the interactor is to:

1. accept events from the view layer.
2. expose the current view state to the view layer.
3. expose view state change events to the view layer.
4. expose side-effect events to the parent layer (coordinator).

### Template

This can be expressed in a template interface (we'll fill this in more later).

```swift
import ReactiveSwift
import Result

final class Interactor {
    enum Command { }
    enum Effect { }
    
    // Inputs
    let commandSink: Signal<Command, NoError>.Observer // 1
    
    // Outputs
    let viewModel: Property<ViewModel> // 2, 3
    let effect: Signal<Effect, NoError> // 4
}
```

The template above is common to all interactors. It covers all possible scenarios (and is quite testable too!).

{% caption_img /images/interactors-public-interface.png %}

Let's take a look at each goal in detail.

### 1. Accept events from the view layer

Just like we introduced `Reducer.Command` in the last post, we'll also have `Interactor.Command`. `Interactor.Command` is an enum that lists _all the events from the view layer that can cause the view model to change_.

You may be wondering why we need both `Reducer.Command` and `Interactor.Command`. `Reducer.Command` will include entries from `Interactor.Command` and additional entries from the results of internal asynchronous events.

`commandSink` is a signal observer. It's a write-only entry point into the reactive world. The way you would place events onto it from the view layer would be e.g. `interactor.commandSink.send(value: Interactor.Command.loadPosts)`. This is the reactive equivalent of calling something like `interactor.loadPosts()`.

### 2. Expose the current view state to the view layer

Interactors are tailored to working with `UITableView` and `UICollectionView` APIs which require access to the current state throughout their data source callbacks. Therefore our interactor must allow `get` access to the view model at any given time on the main thread.

Using ReactiveSwift's `Property` type gives us imperative access to its current value from the view layer e.g. `let currentViewModel = interactor.viewModel.value`.

### 3. Expose view state change events to the view layer

The sort of view state change events that the view layer requires will differ depending on the desired view implementation. In the simplest version, our view layer only needs change events it can use to trigger calls to `tableView.reloadData()`.

We can get this behavior from ReactiveSwift's `Property` type as well subscribing to its `producer` or `signal`.

```swift
// In view controller
interactor.viewModel.producer
    .startWithValues { [weak self] _ in
        self?.tableView.reloadData()
    }
```

### 4. expose side-effect events to the parent layer (coordinator)

In this architecture, the view layer is not responsible for navigation. Navigation-related side effects are determined by the interactor and exposed to its parent coordinator.

Similar to how was saw `Reducer.Effect` in the last post, we also have an `Interactor.Effect`. `Interactor.Effect` lists all the possible side effects that can occur as a result of events in the view layer and view state changes within the interactor.

The coordinator can subscribe to these side effects.

```swift
// In coordinator
interactor.effect
    .observeValues { (effect: Interactor.Effect) in
        // present a new view controller based on `effect`        
    }
```

## Implementation

In our example, there will be two interactors `ProfileInteractor` and `PostsInteractor` nested within `UserInteractor`.

View the full code for [`ProfileInteractor`](https://github.com/twocentstudios/ViewState/blob/8b7b75654baa5fcd4c0a41857fc948380641b6fd/viewstate/View%20Model/ProfileInteractor.swift), [`PostsInteractor`](https://github.com/twocentstudios/ViewState/blob/8b7b75654baa5fcd4c0a41857fc948380641b6fd/viewstate/View%20Model/PostsInteractor.swift), and [`UserInteractor`](https://github.com/twocentstudios/ViewState/blob/8b7b75654baa5fcd4c0a41857fc948380641b6fd/viewstate/View%20Model/UserInteractor.swift) in the `[example project](https://github.com/twocentstudios/ViewState).

### ProfileInteractor

Let's start with `ProfileInteractor` by copying our template from above.

```swift
final class ProfileInteractor {
    enum Command { 
        // TODO: what external messages must we support?
    }
    enum Effect { 
        // TODO: what effects will we produce?
    }
    
    // Inputs
    let commandSink: Signal<Command, NoError>.Observer
    private let commandSignal: Signal<Command, NoError>
    
    // Outputs
    let viewModel: Property<ProfileViewModel>
    let effect: Signal<Effect, NoError>
    
    // ...
}
```

We need to determine what messages/data `ProfileInteractor` can receive from the outside world and what effects it produces. Our current design of `ProfileInteractor` is read-only, so the `Command` and `Effect` are straightforward:

```swift
final class ProfileInteractor {
    enum Command { 
        case load
    }
    enum Effect { }
```

The only way the outside world can change `ProfileViewModel` is through `Command.load`. `ProfileInteractor` produces no side-effects.

Notice that we also added `commandSignal` above as an internal implementation detail. `commandSignal` is the read-only tap of the write-only `commandSink` `ProfileInteractor` exposes to the outside world.

`ProfileInteractor` has 1 initializer and 3 functions.

```swift
final class ProfileInteractor {
    // ...
    
    init(userId: Int, service: ProfileServiceType, scheduler: SchedulerContext = SchedulerContext()) {
        // TODO: set up the entire system.
        //
        // This will be the most complex part of the class, but also
        // the most templated across all interactors.
    }
    
    static private func toCommand(_ command: Command) -> Reducer.Command {
        // TODO: convert a `Command` from the interactor's domain to
        // an `Command` in the reducer's domain.
        //
        // This function has no side-effects.
    }
    
    static private func toEffect(_ effect: Reducer.Effect) -> Effect? {
        // TODO: convert an `Effect` from the reducer's domain to an
        // `Effect` in the interactor's domain.
        //
        // This function has no side-effects.
    }
    
    static private func toSignalProducer(effect: Reducer.Effect, userId: Int, service: ProfileServiceType) -> SignalProducer<Reducer.Command, NoError> {
        // TODO: produce a description of asynchronous work based on
        // an `Effect` provided by the reducer.
        //
        // The `SignalProducer` returns a new `Command` in the reducer's
        // domain.
        //
        // This function allows the reducer to be synchronous.
    }
```

The entire _state_ of this class is set up in `init` as a network of static `Signal`s.

#### Init

`init` contains mostly boilerplate of creating signals and wiring them together with pure transformation functions. In this post I'll explain which parts must be changed for `ProfileInteractor`. In a subsequent post, I'll explain how the system itself is designed.

```swift
    init(userId: Int, service: ProfileServiceType, scheduler: SchedulerContext = SchedulerContext()) { // 1 
        (self.commandSignal, self.commandSink) = Signal<Command, NoError>.pipe()
        
        let initialViewModel = ProfileViewModel(state: .initialized) // 2
        let initialEffect: Reducer.Effect? = nil // 3
        let initialState = Reducer.State(viewModel: initialViewModel, effect: initialEffect)
        
        let externalCommandSignal = commandSignal.map(ProfileInteractor.toCommand) // 4
        let (internalCommandSignal, internalCommandSink) = Signal<Reducer.Command, NoError>.pipe()
        let allCommandsSignal = Signal.merge([externalCommandSignal, internalCommandSignal])
        
        let stateReducer = allCommandsSignal
            .observe(on: scheduler.state)
            .scan(initialState) { (state: Reducer.State, command: Reducer.Command) -> Reducer.State in
                return Reducer.reduce(state: state, command: command)
            }
        
        let viewModelSignal = stateReducer
            .map { $0.viewModel }
            .skipRepeats()
            .observe(on: scheduler.output)
        
        let effectSignal = stateReducer
            .map { $0.effect }
            .skipNil()
            .map(ProfileInteractor.toEffect) // 5
            .skipNil()
            .observe(on: scheduler.output)
        
        stateReducer
            .observe(on: scheduler.work)
            .map { $0.effect }
            .skipNil()
            .flatMap(FlattenStrategy.merge) { (effect: Reducer.Effect) -> SignalProducer<Reducer.Command, NoError> in
                return ProfileInteractor.toSignalProducer(effect: effect, userId: userId, service: service) // 6
            }
            .observe(internalCommandSink)
        
        viewModel = Property(initial: initialViewModel, then: viewModelSignal)
        effect = effectSignal
    }
```

1. Our initializer signature may need different types of static input data and data services.
2. An interactor must always have a view model after it has finished initialization. It's up to us to choose. It's an easy choice because we already created an `initialized` state definition for our view model.
3. Because `Effect` is part of our reducer state, we must also choose an initial effect emitted during initialization. It will almost always be nil.
4. Target `ProfileInteractor.toCommand`.
5. Target `ProfileInteractor.toEffect`.
6. Target `ProfileInteractor.toSignalProducer`. You may need to provide different data or services in order to create the asynchronous jobs.

The rest of the `init` implementation is essentially the same across all interactors.

Now we'll fill in the implementations for the other 3 functions.

#### toCommand

In `toCommand` we only need to convert from `Interactor.Command` to `Reducer.Command`, and they're already straightforwardly aligned.

```swift
final class ProfileInteractor {
    // ...
    
    static private func toCommand(_ command: Command) -> Reducer.Command {
        switch command {
        case .load: return .load
        }
    }
    
    // ...
```

#### toEffect

In `toEffect` we're converting from `Reducer.Effect` to `Interactor.Effect`. However, `Interactor.Effect` is an empty `enum`: all effects from the reducer are handled internally by the interactor (in `toSignalProducer`). In more complex implementations, you'll see many types of effects here.

```swift
final class ProfileInteractor {
    // ...
    
    static private func toEffect(_ effect: Reducer.Effect) -> Effect? {
        return nil
    }
    
    // ...
```

#### toSignalProducer

In `toSignalProducer` we're handling effects from the reducer. If the reducer's message was `load`, we'll use `ProfileServiceType` to make an asynchronous request. The data we receive, either a `User` or an `NSError`, is returned from the signal as a `Reducer.Command` that will be fed back into the reducer.

```swift
final class ProfileInteractor {
    // ...
    
    static private func toSignalProducer(effect: Reducer.Effect, userId: Int, service: ProfileServiceType) -> SignalProducer<Reducer.Command, NoError> {
        switch effect {
        case .load:
            return service.readProfile(userId: userId)
                .map { (user: User) -> Reducer.Command in
                    return Reducer.Command.loaded(user)
                }
                .flatMapError { (error: NSError) -> SignalProducer<Reducer.Command, NoError> in
                    return SignalProducer(value: Reducer.Command.failed(error))
                }
        }
    }
    
    // ...
```

### PostsInteractor

`PostsInteractor` is similar to `ProfileInteractor` so we'll skip the detailed explanation. View the code [here]().

### UserInteractor

`UserInteractor` is a second type of interactor. It will compose `ProfileInteractor` and `PostsInteractor`, wiring them up and exposing `UserViewModel` to the outside world.

`UserInteractor` has some of the same elements of our interactor template, but does not require a dedicated reducer, and does not have any infrastructure for making asynchronous requests.

```swift
final class UserInteractor {
    enum Command {
        case loadProfile
        case loadPosts
    }
    enum Effect { }
    
    let commandSink: Signal<Command, NoError>.Observer
    private let commandSignal: Signal<Command, NoError>
    
    let viewModel: Property<UserViewModel>
    let effect: Signal<Effect, NoError>

    // ...
}
```

As the public interface to both child interactors `ProfileInteractor` and `PostsInteractor`, `UserInteractor` needs the `Command`s of each.

Its child interactors have no external effects, and therefore `UserInteractor` doesn't need to define any.

The rest of the interface looks the same as our other interactors, with `UserViewModel` exposed as in the `Property`.

Let's walk through `UserInteractor.init` to see how it compares to `ProfileInteractor`'s implementation.

```swift
final class UserInteractor {
    init(userId: Int, profileService: ProfileServiceType, postsService: PostsServiceType, scheduler: SchedulerContext = SchedulerContext()) { // 1        
        (self.commandSignal, self.commandSink) = Signal<Command, NoError>.pipe()
        
        // 2
        let profileInteractor = ProfileInteractor(userId: userId, service: profileService)
        let postsInteractor = PostsInteractor(userId: userId, service: postsService)
        
        // 3
        let initialViewModel = UserViewModel(profileViewModel: profileInteractor.viewModel.value, postsViewModel: postsInteractor.viewModel.value)
        
        // 4
        let viewModelSignal = Signal
            .combineLatest(profileInteractor.viewModel.signal, postsInteractor.viewModel.signal)
            .map(UserViewModel.init)
        
        viewModel = Property(initial: initialViewModel, then: viewModelSignal)
        
        // 5
        commandSignal.map(ProfileInteractor.fromCommand).skipNil().observe(profileInteractor.commandSink)
        commandSignal.map(PostsInteractor.fromCommand).skipNil().observe(postsInteractor.commandSink)
        
        // 6
        effect = Signal.merge([
            profileInteractor.effect.map(UserInteractor.toEffect).skipNil(),
            postsInteractor.effect.map(UserInteractor.toEffect).skipNil()
            ])
    }
}
```

1. The initializer signature contains all objects required to create its child interactors.
2. Create the child interactors!
3. Like always, we need to make sure our view model `Property` is initialized with a valid view model. We do so by manually combining the initial values of the child interactors' view models.
4. `combineLatest` is our makeshift reducer. It always combines the latest values of our two child view models and creates a brand new `UserViewModel`.
5. Map commands of the parent interactor type to commands of the child interactor types.
6. Merge effects from both child interactors into one stream.

## Summary

In this post, we discussed the design of a generic `Interactor` component.

The goal of the interactor is to accept events from the view layer, expose the current state of and changes to the view model, and expose side-effects generated alongside view model changes.

Communication into and out of all interactors is done through 3 dedicated channels: `Command` input, `Effect` output, and `ViewModel` `Property` output which includes state and change events. Communication through these channels is done through dedicated `struct`s or `enum`s.

In subsequent posts, we'll discuss:

* How the interactor is used by the view layer.
* A detailed look at how the reactive system created in `init` works.
* How to test an interactor.

### Further reading

* [RxFeedback](https://github.com/kzaher/RxFeedback) - feedback architecture for [RxSwift](https://github.com/ReactiveX/RxSwift)
* [ReactiveFeedback](https://github.com/Babylonpartners/ReactiveFeedback) - feedback architecture for [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift)
* [inamiy: ReactiveAutomaton](https://github.com/inamiy/ReactiveAutomaton)
* [ReSwift](https://github.com/ReSwift/ReSwift)

Thanks for reading this post, and please let me know your thoughts and suggestions. I’m [@twocentstudios](https://twitter.com/twocentstudios) on Twitter.
