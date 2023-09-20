---
layout: post
title: Testing Reducers and Interactors
date: 2018-02-18 22:21:38
---

In this post we'll discuss some techniques for testing the reducers and interactors we introduced in the previous [reducers post](/2017/08/02/transitioning-between-view-states-using-reducers/) and [interactors post](/2017/11/05/interactors/).

The entire test suite can be viewed in the [GitHub repo](https://github.com/twocentstudios/ViewState) for the example app. I'll be excerpting a few illustrative cases in this post.

## Goal

One of the prescribed benefits of splitting our architecture into inert view models, single-state change reducers, long lived interactors, and a view layer is so that we could test each component individually. 

Leaning on structs and enums as the input and output boundary of each component makes testing more straightforward; we need to create fewer mock classes to observe the behavior of the system.

Using a special `Scheduler` type to control the flow of time allows us to test asynchronous behavior without slowing down testing. It also allows us to mimic any sort of delays or operation ordering that would usually cause subtle, difficult to reproduce bugs in production.

## Preview

In the example app we had two systems: Profile and Posts. In this post we'll only be showing examples from the Profile.

The reducer is trivial to test. It's a pure function with two inputs, one output, and no side effects.

The interactor is a bit more complex. It will require a mock `Service` class for the data layer. It will require a special `Scheduler` type in order to control the flow of time.

## Testing the reducer

For the reducer, we'll be testing each of the valid transitions specified by this diagram:

{% caption_img /images/transitioning_view_states-04.png %}

These will be more akin to *unit tests*.

### Outline of ProfileInteractorReducerTests

Let's start with an outline of the `XCTestCase` subclass we'll be writing.

```swift
class ProfileInteractorReducerTests: XCTestCase {
    typealias Reducer = ProfileInteractor.Reducer
    
    let user = Mocks.user
    let error = Mocks.error
    
    func testInitializedLoad() {
        // TODO
    }

    func testLoadingLoaded() {
        // TODO
    }
    
    func testLoadingFailed() {
        // TODO
    }
    
    func testFailedLoad() {
        // TODO
    }
    
    func testLoadedLoad() {
        // TODO
    }
}
```

### Mocks and helpers

Because we've namespaced our reducer under `ProfileInteractor` we'll make a type alias to cut down on some boilerplate.

```swift
    typealias Reducer = ProfileInteractor.Reducer
```

We'll also make some mock structs to cut down on boilerplate.

```swift
    let user = Mocks.user
    let error = Mocks.error
```

Where the `Mock` enum acts as a namespace:

```swift
enum Mocks {
    static let user = User(id: 0,
                           avatarURL: URL(string: "https://en.gravatar.com/userimage/30721452/beb8f097031268cc19d5e6261603d419.jpeg")!,
                           username: "twocentstudios",
                           friendsCount: 100,
                           location: "Chicago",
                           website: URL(string: "twocentstudios.com")!)
    
    static let error = NSError(domain: "", code: 0, userInfo: nil)
    
    // ...
}
```

Finally, we'll need to ensure we've implemented equatable for all of the structs we'll use. This includes `ProfileViewModel`, `ProfileInteractor.Reducer.State`, `ProfileInteractor.Reducer.Command`, and `ProfileInteractor.Reducer.Effect`. Otherwise, we'd have no way to assert.

### Writing the reducer tests

With the boilerplate out of the way, let's write our first test.

Our first valid transition is a `ProfileViewModel` from `Initialized` to `Loading` state.

Remember that this state transition does not go directly from `Initialized` to `Loaded` and hit the network or perform other side effects. The reducer is a synchronous function. Its two outputs are 1. the state of the view model updated to `Loading` and 2. the `.load` `Effect` which will be used by the interactor to perform side effects.

> Refer to the [view state post](/2017/08/02/transitioning-between-view-states-using-reducers/) and [reducers post](/2017/08/02/transitioning-between-view-states-using-reducers/) for more background.

```swift
class ProfileInteractorReducerTests: XCTestCase {
    func testInitializedLoad() {
    
        // 1a. Create an initial `ProfileViewModel` and state containing it.
        let initialViewModel = ProfileViewModel(state: .initialized)
        let initialState = Reducer.State(viewModel: initialViewModel, effect: nil)
        // 1b. Specify the `Command` that will direct the state transition.
        let command = Reducer.Command.load
        
        // 2. Specify the target (expected) `ProfileViewModel`, `Effect`, and `State` combining the two.
        let targetViewModel = ProfileViewModel(state: .loading)
        let targetEffect = Reducer.Effect.load
        let targetState = Reducer.State(viewModel: targetViewModel, effect: targetEffect)
        
        // 3. Call the function with (1) and (2) and store the result.
        let result = Reducer.reduce(state: initialState, command: command)
        
        // 4. Assert the result from (4) is what we expect from (3).
        XCTAssertEqual(targetState, result)
    } 
}
```

This is about as straightforward as you can get with a test. 

1. Create some inert input data
2. Create our expected output structs
3. Call the function with the input data.
4. Assert that our function output equals the output we expect.

From here, we can copy paste this general structure and change the input and expected values.

> There are probably better ways to automate writing and testing the reducer since it's just a state machine. I'm open to ideas!

Let's show one more test for the transition from state `Loading` to `Failed`. Remember that the `Command` for this state transition comes as a result of the `Service` returning a value (presumably from the server), and all of that is handled by the interactor.

```swift
class ProfileInteractorReducerTests: XCTestCase {
    func testLoadingFailed() {
        let initialViewModel = ProfileViewModel(state: .loading)
        let initialState = Reducer.State(viewModel: initialViewModel, effect: nil)
        
        let command = Reducer.Command.failed(error)
        
        let targetViewModel = ProfileViewModel(state: .failed(error))
        let targetEffect: Reducer.Effect? = nil
        let targetState = Reducer.State(viewModel: targetViewModel, effect: targetEffect)
        
        let result = Reducer.reduce(state: initialState, command: command)
        
        XCTAssertEqual(targetState, result)
    }
}
```

The same sequence of statements is used, but we're comparing different inputs and outputs.

### Which transitions to test?

In the [source](), I'm only testing valid transitions. However, we could also test that invalid transitions are handled in a deterministic way. The rigor of your test coverage is up to you.

In the most rigorous implementation of a reducer, you could add an `Effect` for invalid transitions. Upstream, in the interactor, you could use that `Effect` to log an error to an external service. This would keep your reducer completely deterministic and side-effect free.

## Testing the interactor

For the interactor, we'll be testing end-to-end transitions. We could also mirror our reducer tests, but as you'll see, it makes more sense to lean towards *integration tests* here since we can now fully exercise the asynchronous nature of the interactor.

> I'll talk a little bit about integration testing with the interactor vs UI testing with UIKit and Xcode a bit later.

### Outline of ProfileInteractorTests

Going back to our state transition diagram:

{% caption_img /images/transitioning_view_states-04.png %}

Let's outline `ProfileInteractorTests`.

```swift
class ProfileInteractorTests: XCTestCase {
    typealias Command = ProfileInteractor.Command
    typealias Effect = ProfileInteractor.Effect
    
    let user = Mocks.user
    let error = Mocks.error
    
    // Initialized
    func testInitialState() {
        // TODO
    }
    
    // Initialized -> Load -> Loaded
    func testInitializedLoadSuccess() {
        // TODO
    }

    // Initialized -> Load -> Failed    
    func testInitializedLoadFailure() {
        // TODO
    }
    
    // Failed -> Load -> Success
    func testFailureThenSuccess() {
        // TODO
    }
}
```

We've decided on four cases:

1. **Initialized** - ensure our system starts in a known state.
2. **Initialized -> Load -> Loaded** - expected success case.
2. **Initialized -> Load -> Failed** - failure case.
2. **Failed -> Load -> Success** - retry failure to success case.

### Mocks and helpers

Like the reducer tests above, we'll use some `typealias`es and mocks to cut down on boilerplate.

We'll also need to add two new mock classes that our interactor(s) have as dependencies.

#### ProfileService

`Mock.ProfileService` should conform to `ProfileServiceType`:

```swift
protocol ProfileServiceType {
    func readProfile(userId: Int) -> SignalProducer<User, NSError>
}
```

Our mock should return a valid user or an error depending on what we want to test.

The simplest version of this mock can just mirror whatever `Result` we set.

```swift
enum Mocks {
    final class ProfileService: ProfileServiceType {
        var result: Result<User, NSError>!
        
        func readProfile(userId: Int) -> SignalProducer<User, NSError> {
            return SignalProducer(result: result)
        }
    }
}
```

But I made some helpers so the test code looks a little cleaner.

#### TestSchedulerContext

The interface for the interactor accepts a `SchedulerContextType`. This requires a more detailed explanation, but for now I'll explain the basics.

`SchedulerContextType` asks for three distinct schedulers: 

* `state` to update state by running the synchronous reducer function.
* `work` to dispatch asynchronous work like network requests.
* `output` to set the `viewModel` and `effect` variables.

This will allow us to manipulate the flow of time and observe/assert the state of the system at critical points.

```swift
struct TestSchedulerContext: SchedulerContextType {
    
    // ...
    
    init(state: TestScheduler = TestScheduler(), work: TestScheduler = TestScheduler(), output: TestScheduler = TestScheduler()) {
        self.testState = state
        self.testWork = work
        self.testOutput = output
    }
    
    func nextOutput() {
        testState.advance()
        testOutput.advance()
    }
    
    func doWork() {
        testWork.advance()
    }
}
```

I've added two helper functions to formalize how the schedulers should be advanced: `nextOutput` which accepts input, computes a new state, and delivers output; and `doWork` which simulates the service layer returning a new result.

#### TestObserver

`TestObserver` is a helper class specifically for testing the output of `ReactiveSwift` signals. This was originally written by the Kickstarter team (their source [here](https://github.com/kickstarter/Kickstarter-ReactiveExtensions/blob/15631b40c437d18db4187d9b8ad117115775ea3f/ReactiveExtensions/test-helpers/TestObserver.swift)).

The header comments explain its purpose:

```
A `TestObserver` is a wrapper around an `Observer` that saves all events 
to an internal array so that assertions can be made on a signal's behavior. 
To use, just create an instance of `TestObserver` that matches the type of 
signal/producer you are testing, and observer/start your signal by feeding 
it the wrapped observer. For example,

 let test = TestObserver<Int, NoError>()
 mySignal.observer(test.observer)
 
 // ... later ...
 
 test.assertValues([1, 2, 3])
```

### Writing the interactor tests

Let's start with the first test: ensuring our interactor has the expected initial state.

```swift
class ProfileInteractorTests: XCTestCase {
    // ...
    
    // Initialized
    func testInitialState() {
        let schedulerContext = TestSchedulerContext()
        let service = Mocks.ProfileService(user)
        
        // 1. Create the interactor with dependencies.
        let interactor = ProfileInteractor(userId: user.id, service: service, scheduler: schedulerContext)
        
        // 2. Create the expected view model.
        let targetViewModel = ProfileViewModel(state: .initialized)
        
        // 3. Probe the result view model stored in the property.
        let result = interactor.viewModel.value
        
        // 4. Assert equality.
        XCTAssertEqual(targetViewModel, result)
    }
}
```

> Note that we don't need to run the output scheduler since the interactor's `viewModel.value` is set on whatever scheduler `init` is called on.

```swift
class ProfileInteractorTests: XCTestCase {
    // ...
    
    // Initialized -> Load -> Loaded
    func testInitializedLoadSuccess() {
        let schedulerContext = TestSchedulerContext()
        let service = Mocks.ProfileService(user)
        
        // 1. Create the interactor with dependencies.
        let interactor = ProfileInteractor(userId: user.id, service: service, scheduler: schedulerContext)
        
        // 2. Create a TestObserver for the `Effect` output.
        let effect: TestObserver<Effect, NoError> = TestObserver()
        interactor.effect.observe(effect.observer)
        
        // 3. Create the `Command` to test.
        let command = Command.load
        
        // 4. Create the two expected view model states.
        let loadingViewModel = ProfileViewModel(state: .loading)
        let loadedViewModel = ProfileViewModel(state: .loaded(user))
        
        // 5. Send `Command.Load` to simulate the load start.
        interactor.commandSink.send(value: command)
        
        // 6. Tell the `schedulerContext` to run one output cycle.
        schedulerContext.nextOutput()
        
        // 7. Probe the result view model stored in the property.
        let loadingResult = interactor.viewModel.value
        
        // 8. Assert that the view model is now in `loading` state.
        XCTAssertEqual(loadingViewModel, loadingResult)
        
        // 9. Assert that there were no other side-effects produced.
        effect.assertValueCount(0)
        effect.assertDidNotComplete()
        
        // 10. Tell the `schedulerContext` to run one service cycle and one output cycle.
        schedulerContext.doWork()
        schedulerContext.nextOutput()
        
        // 11. Probe the result view model stored in the property again.
        let loadedResult = interactor.viewModel.value
        
        // 12. Assert that the view model is now in `loading` state.
        XCTAssertEqual(loadedViewModel, loadedResult)

        // 13. Assert that there were no other side-effects produced.
        effect.assertValueCount(0)
        effect.assertDidNotComplete()
    }
```

A couple things to note:

* [2][9][13] Because our `interactor.effect` is a stateless `Signal`, we need to use `TestObserver` to temporary capture its values (or lack there of) to assert.
* [6][10] We have to call functions on `schedulerContext` to artificially advance time.

The interactor tests are more like integration tests. There's a lot more internal behavior handled by the interactor in order to produce the `viewModel` and `effect` outputs. However, we get much more control and granularity as opposed to UI testing.

See [the source]() for the other two cases I decided to test. They're very similar.

## UI testing

Judging from the types of testing I've decided to focus on in this post, you can probably glean some of my views on testing.

My past team experience focused on using manual pre-release testing to discover UI bugs. We did no automated UI testing at all. The biggest reason was that almost every screen in our app changed in a non-trivial way at least once a month. Maintaining expectation images and UI automation testing would have required resources we didn't have.

In this post, I specifically target my tests in code outside of `UIKit`. The architecture itself from the last four posts is designed to push code as far as reasonably possible outside of `UIKit`. `UIKit` simply introduces far too much state and far too many side-effects into a system for me to feel confident that my tests are useful.

Although there has been lots of progress made both by Apple and in open source in making UI testing more useful and feasible, I still consider manual testing to be more resource efficient than writing and maintaining a suite of UI tests especially for the kinds of apps I currently work on.

I would love to have my mind changed though. I hope UI testing becomes more mainstream as tooling improves. And certainly if you have the design stability and the resources, automate as much testing as you can!

## Summary

In this post we looked at writing tests for our reducer and interactor.

The reducer tests were trivial unit tests. The interactor tests are more involved, but give us a lot of control to test the limited interface of the interactor.

Although on the surface scheduler contexts seem to complicate our code a bit, I think it's really useful to have both control and understanding of how and when code is being run. Notice that we didn't have to wait for any expectations. The test code follows a linear and logical progression.

A few questions I'd like to ponder for the future:

* Since our reducer is a straightforward state machine, are there better ways to automate testing?
* Is there a way we can eliminate at least one of the three scheduler context types? Perhaps the `state` scheduler can use the `output` scheduler instead?

## Further reading

* [objc.io: Test-Driven Reactive Programming](https://talk.objc.io/episodes/S01E53-test-driven-reactive-programming-at-kickstarer)
* [RxTest – How to test the Observable in Swift](http://adamborek.com/rxtests-rxactionsheet/)