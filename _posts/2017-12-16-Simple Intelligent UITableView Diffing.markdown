---
layout: post
title: Simple Intelligent UITableView Diffing
date: 2017-12-16 15:44:23
---

In this post we'll finally be implementing the view layer of our example application that shows a user profile. 

In the previous three blog posts, we've modeled the [view state](http://twocentstudios.com/2017/07/24/modeling-view-state/), then created a [reducer](http://twocentstudios.com/2017/08/02/transitioning-between-view-states-using-reducers/) to process changes to that view state, then created an [interactor](http://twocentstudios.com/2017/11/05/interactors/) to process input events and manage the view state over time.

## Goal

Our goal will be a normal data load from two sources that looks like this video:

<video src="/images/view_controller_with_interactor-normal_load.mov" controls preload="none" poster="/images/view_controller_with_interactor-normal_load-poster.png" height="600"></video>

And we want to be able to seamlessly reload from failure like the video below:

<video src="/images/view_controller_with_interactor-failed.mov" controls preload="none" poster="/images/view_controller_with_interactor-failed-poster.png" height="600"></video>

## Background

Our goal in creating an interactor and a fully specified view state was to allow our view layer to be very dumb. There are a few reasons this is beneficial:

* Massive view controller is a well documented phenomenon. View controllers with many concerns quickly become large, unmanageable, and buggy as requirements change.
* The view layer has other concerns it can be smart about. There's plenty of layout code, animations, styling, gesture handling, and UIKit ceremony that we don't want cluttered with state manipulation code.
* UIKit is notoriously difficult to test. We can either choose to avoid brittle UI tests while still being confident in our view logic, or we can use XCUITest for high level integration testing and navigation testing.

> Note that in this post, I'll be using [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift) and [Differ](https://github.com/tonyarnold/Differ) in my reference implementation.

## Goal

Like in most MVVM variants, we'll consider pretty much everything in `UIKit` as part of the view layer. That means `UIViewController`, `UIView`, and `UIApplication`.

The goal for our view layer will be:

1. Receive read-only view models from the interactor.
2. Configure the view to match the view model.
3. Send raw events (`Command`s) to the interactor in order to change the view state.

Let's take a look at the interface of the interactor we created in the last post for a hint as to how we'll achieve the goals we listed above.

```swift
final class Interactor {
    
    // Outputs
    let viewModel: Property<ViewModel>

    // Inputs
    enum Command {
        case load
    }
    
    let commandSink: Signal<Command, NoError>.Observer

    // ...
}
```

### 1. Receive read-only view models from the interactor

`Property<ViewModel>` provides us access to a `SignalProducer` which will emit the latest `ViewModel` on subscription and on every change.

`Property<ViewModel>` also provides us read-only access to `value`, the latest `ViewModel` that was sent through the `Signal`. We'll need access to this because of the way the `UITableView` datasource and delegate APIs work.

In the interactor, we ensured that `viewModel` is always set on the main thread.

## Implementation

We've already done most of the heavy lifting in the interactor, reducer, and view model definition. We'll mostly be doing the UI tasks of creating view subclasses, writing layout code, and implementing the required delegate methods for `UITableView`.

You can find all the example code in the public [GitHub repo](https://github.com/twocentstudios/ViewState). I won't be covering any of the boilerplate view layout or configuration in this post.

### Initialization

Let's dive into the view controller now. We'll assume our entire view controller/interactor/services system is configured in a coordinator or other layer above. That means `UserViewController` depends only on a `UserInteractor`.

```swift
final class UserViewController: UIViewController {
    init(interactor: UserInteractor) {
        self.interactor = interactor
        
        super.init(nibName: nil, bundle: nil)
    }
    
    // ...
}
```

### Configuration

We'll be using a straightforward `UITableView` with several cell types.

Remember from the previous post on [modeling view state](http://twocentstudios.com/2017/07/24/modeling-view-state/) we cataloged our cell types pretty thoroughly already.

```swift
struct UserViewModel {
    enum ViewModelType {
        case profileHeader(ProfileHeaderViewModel)
        case profileError(ErrorViewModel)
        case profileAttribute(ProfileAttributeViewModel)
        case contentHeader(String) // "Posts"
        case contentLoading
        case contentEmpty(String)
        case contentError(ErrorViewModel)
        case post(PostViewModel)
    }
    
    // ...
}
```

Now we can simply look at our design mockup and create a cell for each of the `ViewModelType` cases.

Each cell will have its own `configure(with: ViewModelType)` method to apply the specific view data. For example:

```swift
final class ProfileAttributeCell: UITableViewCell {
    
    // ...
    
    func configure(with viewModel: ProfileAttributeViewModel) {
        nameLabel.text = viewModel.name
        valueLabel.text = viewModel.value
    }
}
```

Then once we have all of our cell subclasses created, we'll register them with the table view (using a handy `register` extension on `UITableView`).

```swift
final class UserViewController: UIViewController {    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        // ...
        tableView.register(ProfileHeaderCell.self)
        tableView.register(ErrorCell.self)
        tableView.register(ProfileAttributeCell.self)
        tableView.register(ContentHeaderCell.self)
        tableView.register(ContentLoadingCell.self)
        tableView.register(ContentEmptyCell.self)
        tableView.register(PostCell.self)
        return tableView
    }()
```

### Reloading the table view - attempt #1

Let's start with a naive implementation of table view reloading.

```swift
final class UserViewController: UIViewController {

    // ...

    override func viewDidLoad() {
        
        // ...
        
        interactor.viewModel.producer
            .skipRepeats()
            .startWithValues { [unowned self] _ in
                self.tableView.reloadData()
            }
    }
    
    // ...
```

On `viewDidLoad` we're setting up an observer that sends the latest view model. When a new view model is sent (and it's not the same as the last one), we'll reload the entire table view.

Although this works, it doesn't look great. The cells snap in with no animation and it's a little jarring.

<video src="/images/view_controller_with_interactor-reload_data.mov" controls preload="none" poster="/images/view_controller_with_interactor-reload_data-poster.png" height="600"></video>

### Assigning data to cells

Now we need to implement the `UITableViewDataSource` methods.

We already made a nice helper in the view model to get the number of rows:

```swift
extension UserViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return interactor.viewModel.value.numberOfRows(in: section)
    }
    
    // ...
}
```

But our `cellForRowAtIndexPath` function has a little bit more to unpack:

```swift
extension UserViewController: UITableViewDataSource {
    // ...
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellViewModelType = interactor.viewModel.value.viewModel(at: indexPath) else { fatalError() }
        
        let returnCell: UITableViewCell
        switch cellViewModelType {
        case .profileHeader(let cellViewModel):
            let cell = tableView.dequeue(ProfileHeaderCell.self, for: indexPath)
            cell.configure(with: cellViewModel)
            returnCell = cell
        case .profileError(let cellViewModel):
            let cell = tableView.dequeue(ErrorCell.self, for: indexPath)
            cell.configure(with: cellViewModel)
            cell.button.reactive.controlEvents(.touchUpInside)
                .take(until: cell.reactive.prepareForReuse)
                .observeValues({ [unowned self] _ in
                    self.interactor.commandSink.send(value: .loadProfile)
                })
            returnCell = cell
        case .profileAttribute(let cellViewModel):
            let cell = tableView.dequeue(ProfileAttributeCell.self, for: indexPath)
            cell.configure(with: cellViewModel)
            returnCell = cell
        case .contentHeader(let cellViewModel):
            let cell = tableView.dequeue(ContentHeaderCell.self, for: indexPath)
            cell.configure(with: cellViewModel)
            returnCell = cell
        case .contentLoading:
            let cell = tableView.dequeue(ContentLoadingCell.self, for: indexPath)
            returnCell = cell
        case .contentEmpty(let cellViewModel):
            let cell = tableView.dequeue(ContentEmptyCell.self, for: indexPath)
            cell.configure(with: cellViewModel)
            returnCell = cell
        case .contentError(let cellViewModel):
            let cell = tableView.dequeue(ErrorCell.self, for: indexPath)
            cell.configure(with: cellViewModel)
            cell.button.reactive.controlEvents(.touchUpInside)
                .take(until: cell.reactive.prepareForReuse)
                .observeValues({ [unowned self] _ in
                    self.interactor.commandSink.send(value: .loadPosts)
                })
            returnCell = cell
        case .post(let cellViewModel):
            let cell = tableView.dequeue(PostCell.self, for: indexPath)
            cell.configure(with: cellViewModel)
            returnCell = cell
        }
        
        return returnCell
    }
}
```

We get a `cellViewModelType` from our view model helper which is of enum type `UserViewModel.ViewModelType`. That will tell us what kind of cell we need and what kind of associated data is paired with it.

Then we have a nice big `switch` statement that the compiler will enumerate the required cases for.

Most of the cases have the same three steps:

1. Dequeue the correct type of cell (with a helper function).
2. Configure the cell with the associated data (the type will always match).
3. Return the cell

Pretty simple!

The error cells are interactive and expose buttons. We'll use some reactive magic to transform button taps to commands on the interactor:

```swift
cell.button.reactive.controlEvents(.touchUpInside)
    .take(until: cell.reactive.prepareForReuse)
    .observeValues({ [unowned self] _ in
        self.interactor.commandSink.send(value: .loadProfile)
    })
```

`.take` will ensure that reused cells will dispose of their subscriptions and no longer send events. If we neglect this, each time the cell is reused, another subscription will be added and the interactor will end up receiving 2+ commands for every 1 button tap.

We'll use the exposed `commandSink` to send `UserInteractor.Command.loadProfile`. This is the behavior as if we called `interactor.loadProfile()` or `interactor.processCommand(.loadProfile)`, but we're not burdening the interactor with lifting messages into the reactive world (this is a judgement call and you can draw the line wherever feels most appropriate).

#### Reactive Aside: binding to sinks

Why leave the reactive world with `observeValues` just to re-enter by sending a value to a signal observer? It seems natural to write the following code instead:

```swift
cell.button.reactive.controlEvents(.touchUpInside)
    .take(until: cell.reactive.prepareForReuse)
    .map { _ in .loadProfile }
    .observe(interactor.commandSink)
```

I wish this worked (it's a lot more elegant!). However, the signal we're creating completes as expected when the cell is reused. Since we've wired the signal directly to `commandSink`, `commandSink` will also complete, leaving our interactor without the ability to receive any new commands.

### Kicking off the load

Finally, we need to kick off the initial data load request. I've decided to be pessimistic about data cache longevity and issue a new request on every `viewWillAppear`.

```swift
final class UserViewController: UIViewController {

    // ...

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        interactor.commandSink.send(value: .loadPosts)
        interactor.commandSink.send(value: .loadProfile)
    }
    
    // ...
```

We saw this same code in the error table view cells.

### Reloading the table view - attempt #2

Our view controller works! But that view reloading is still not great. Since we've already gone through the trouble of implementing `Equatable` for all of our view models, let's use a [diffing library](https://github.com/tonyarnold/Differ) to derive precision changes we can make to the table view.

```swift
final class UserViewController: UIViewController {

    // ...

    override func viewDidLoad() {
        
        // ...
        
        interactor.viewModel.producer
            .skipRepeats()
            .map { $0.viewModels }
            .scan([], { [unowned self] (old, new) -> [UserViewModel.ViewModelType] in
                self.tableView.animateRowChanges(oldData: old, newData: new, deletionAnimation: .fade, insertionAnimation: .fade)
                return new
            })
            .start()
    }
    
    // ...
```

There are a few ways to write this signal chain. Our technique will be to use `.scan` to get access to the previous and latest view models so that we can derive and apply a changeset with `Differ`'s `UITableView` extension.

It looks a lot nicer now.

The happy path loading successfully looks like this:

<video src="/images/view_controller_with_interactor-normal_load.mov" controls preload="none" poster="/images/view_controller_with_interactor-normal_load-poster.png" height="600"></video>

The two separate parts of our view that can fail can be reloaded completely independently even though they're in the same table view:

<video src="/images/view_controller_with_interactor-failed.mov" controls preload="none" poster="/images/view_controller_with_interactor-failed-poster.png" height="600"></video>

## Summary

In this post we looked at the implementation for a view layer that can:

* use the (equatable) view model structures we created the previous posts to populate the final representation of the views.
* react intelligently to changes in the entire view model.

This post concludes this short series about using view models, reducers, interactors, and diffing to create a heterogeneous view layer.

### Further reading

* [IGListKit](https://github.com/Instagram/IGListKit
) - a similar and more advanced take on intelligent table/collection diffing.
* [Complex table view state changes made easy](https://engineering.kitchenstories.io/this-simple-trick-will-change-how-you-think-about-table-views-706193654974) - a similar technique with a login module example.
* [NSFetchedResultsController](https://developer.apple.com/documentation/coredata/nsfetchedresultscontroller) - Change management via [NSFetchedResultsControllerDelegate](https://developer.apple.com/documentation/coredata/nsfetchedresultscontrollerdelegate).

Thanks for reading this post, and please let me know your thoughts and suggestions. I’m [@twocentstudios](https://twitter.com/twocentstudios) on Twitter.
