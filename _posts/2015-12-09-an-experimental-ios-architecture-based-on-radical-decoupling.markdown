---
layout: post
title: An Experimental iOS Architecture Based on Radical Decoupling
date: 2015-12-09 3:49:49
---

This week I decided to do an experiment on a radically decoupled app architecture. The main thesis I wanted to explore was:

> What if all communication within an app was done over one event stream?

I built a Todo List app because that was the most original micro project I could think of in the heat of the moment. I'll walk through the idea behind the organization of the app, show some code snippets from the implementation, and then give a few closing thoughts on the pros and cons.

The whole project is on [Github](https://github.com/twocentstudios/todostream). This post targets the [0.1 tag](https://github.com/twocentstudios/todostream/releases/tag/0.1) for reference.

{% caption_img /images/event-mvvm-demo.gif Demo of the app %}

## Architecture Overview

I'll call this architecture EventMVVM for the sake of having a name to reference. It uses bits of the [MVVM](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) (Model-View-ViewModel) paradigm. It uses [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) as the plumbing for the event stream, but as I'll discuss later many possible tools could be used instead. It is written in Swift, which turns out to be marginally important due to the enums with associated values feature, and its ease of defining and using value types.

The best way I can explain the architecture is by naming and enumerating the actors involved, defining them, and listing the rules.

* Event
* EventsSignal & EventsObserver
* Server
* Model
* ViewModel
* View

### Event

An event is the building block of a message. It's defined as an enum, and each case has up to one associated value (note: it's different from a ReactiveCocoa Event). You can think of it as a strongly-typed `NSNotification`. Each case starts with `Request` or `Response` out of convention. Below are a few example cases.

{% highlight swift %}
/// Event.swift
enum Event {
    // Model
    case RequestReadTodos
    case ResponseTodos(Result<[Todo], NSError>)
    case RequestWriteTodo(Todo)
    
    // ...
    
    // ViewModel
    case RequestTodoViewModels
    case ResponseTodoViewModels(Result<[TodoViewModel], NSError>)
    case RequestDeleteTodoViewModel(TodoViewModel)
    
    // ...
}
{% endhighlight %}

* Model and ViewModel "type" events are both included in the `Event` enum.[^1]
* `RequestReadTodos` does not have a parameter since this app has no per-view filtering or sorting that needs to happen.[^2]
* We're using a [Result](https://github.com/antitypical/Result) to encapsulate the response value or error.[^3]
* All enum case associated values are value types which is important in ensuring system integrity. The same Event may be received by many objects on any number of threads.

[^1]: A future expansion to EventMVVM could have a `ModelEvent` and `ViewModel` event, and a typed stream for each. That way, a View objects would only see the ViewModel stream, whereas ViewModelServers (I'll cover this later) would see both ViewModel and Model streams.
[^2]: In a more complex app, there would need to be a `ReadTodosRequest` struct to encapsulate a sort descriptor and predicate. Or better yet, a more thorough TodoListViewModel that contains all this information.
[^3]: It turns out it would probably be better to embed an optional error parameter within the response itself. Otherwise, it becomes impossible to know which request the error is associated with. We'll kick that problem down the road for now.

### EventsSignal & EventsObserver

`eventsSignal` and `eventsObserver` will be our shared event streams. We'll inject them into classes and those classes will be able to attach observer blocks to `eventsSignal` and send new Events on `eventsObserver`.

{% highlight swift %}
/// AppContext.swift
class AppContext {
    let (eventsSignal, eventsObserver) = Signal<Event, NoError>.pipe()
    
    // ...
}
{% endhighlight %}

We've located this pair in a class called `AppContext`. These are implemented using a ReactiveCocoa signal and observer pair created by `.pipe()`. There are a few implementation details that we'll cover later.

In simple terms though the syntax is as follows:

{% highlight swift %}
// Create a new observer on the stream.
eventsSignal.observeNext { event in print(event) }

// Send a new Event on the stream.
eventsObserver.sendNext(Event.RequestTodoViewModels)
{% endhighlight %}

### Server

A server is a long-lived class that contains observers and may send messages. In our example app, there are two servers, `ViewModelServer` and `ModelServer`. These are created and retained by `AppDelegate`. From the names, you may posit that `ViewModelServer` sets up observers for the ViewModel-related duties of our application. For example, it is responsible for receiving requests for ViewModels and fulfilling them, either by transforming ViewModels provided in the event or by sending a new event requesting the data it needs.[^4][^5]

Servers represent the "smart" objects in our application. They're the orchestrators. They create and manipulate our ViewModel and Model value types and communicate with other servers by creating Events and attaching values to them.

[^4]: You could certainly combine `ViewModelServer` and `ModelServer` into one `Server` (or just dump everything in the AppDelegate), but MVVM helps us separate our concerns.
[^5]: One of the biggest open questions I have is if and how Server objects spawn one another. In any decent sized application, it would be unwieldy to have one `ViewModelServer` with hundreds or thousands of observers on one stream. It may also use too many resources. If we split ViewModelServers per ViewModel type, how would the primary `ViewModelServer` know how to manage the lifecycles of them?

### Model

A Model is a value type containing the base data. As in standard MVVM, it should not contain anything specific to an underlying database.

In the example application, I have extensions to serialize the `Todo` model object into a `TodoObject` for our Realm database.

The Model layer only knows about itself. It doesn't know about ViewModels or Views.

### ViewModel

A ViewModel is a value type containing properties directly consumable by the View layer. For example, text displayed by a `UILabel` should be a `String`. The ViewModel receives and stores a Model object in its `init` method and transforms it for consumption by the View layer. A ViewModel may expose other ViewModels for use by subviews, etc.

In this interpretation[^6], ViewModels are completely inert and cannot run asynchronous operations or send messages on the event stream. This ensures they can be passed around threads safely.

ViewModels don't know about the View layer. They can manipulate other ViewModels and Models.

[^6]: In most of my other work with MVVM, some ViewModels are classes and do the majority of the heavy lifting with regards to asynchronous work and organizing data flow within the app, while some are inert value types. The reasoning behind this is to make the ViewControllers a bit "dumber" by keeping that logic out of them.

### View

Our View layer is UIKit, including `UIViewController`s and `UIView`s and their subclasses. Although my original intention was to explore the View layer also sending its own events through the event stream, in this simple implementation it would have been overkill and probably more distracting than anything.[^7]

The View layer is only allowed to interact with the View and ViewModel layers. That means it knows nothing about Models.

[^7]: Examples of these types of events would be `ViewControllerDidBecomeActive(UIViewController)` or `ButtonWasTapped(UIButton)`. As you can see, this would break our assumptions of only sending value types through the stream, which requires some more thought. And as I've learned from working with other frameworks, you can jump through a lot of hoops to avoid doing things the way UIKit wants you to do them, and you usually come out the other side worse off.

## Implementation

So now that we've got a basic understanding of all the components of our system, lets dive into the code and see how it works.

### The Spec

What are the features of our Todo list? They end up being analogous to our `Event` cases. (For me, this was one of the coolest parts.) From `Event.swift`:

* `RequestTodoViewModels`: we want to be able to see all our todos in the default order with deleted items filtered out.
* `RequestToggleCompleteTodoViewModel`: we need to be able to mark todos as complete from the list view.
* `RequestDeleteTodoViewModel`: we'll add the ability to delete them from the list view too.
* `RequestNewTodoDetailViewModel`: we need to be able to create new todos.
* `RequestTodoDetailViewModel`: we need to be able to view/edit a todo in all its glory.
* `RequestUpdateDetailViewModel`: we need to be able to commit our changes.

Those are all of our requests. They'll all originate from the View layer. Since these are just events/messages we're broadcasting out, there won't necessarily be a direct 1-1 response. This has both positive and negative consequences for us.

One of the effects is that we need fewer types of response events. `RequestTodoViewModels` will have a 1-1 response with `ResponseTodoViewModels`, but `RequestToggleCompleteTodoViewModel`, `RequestDeleteTodoViewModel`, and `RequestUpdateDetailViewModel` will all respond with `ResponseTodoViewModel`. That simplifies our view code a bit, and it also ensures a view can get updates for a ViewModel that was changed from a different view with zero additional work by us.

Both `RequestNewTodoDetailViewModel` and `RequestTodoDetailViewModel` (aka new and edit) will respond from `ResponseTodoDetailViewModel`.

Interestingly enough, `RequestUpdateDetailViewModel` must respond from both `ResponseUpdateDetailViewModel` and `ResponseTodoViewModel` since their underlying todo Model changed. We'll explore this scenario in more detail later on.

In order to fill these requests from the View layer, the ViewModelServer will need to make its own requests for Model data. These are 1-to-1 request-response.

* `RequestReadTodos` -> `ResponseTodos`
* `RequestWriteTodo` -> `ResponseTodo`

We implement deletes by setting a flag on our Todo model. This technique makes it significantly easier to coordinate changes between our application layers.

Here is a very long diagram of how our four main objects send and observe events.

{% caption_img /images/event-mvvm-diagram.png Events get sent to and observed by our four primary objects %}

### Setting Up the System

{% highlight swift %}
/// AppDelegate.swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    var appContext: AppContext!
    var modelServer: ModelServer!
    var viewModelServer: ViewModelServer!

    // ...

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        self.appContext = AppContext()
        self.modelServer = ModelServer(configuration: Realm.Configuration.defaultConfiguration, appContext: appContext)
        self.viewModelServer = ViewModelServer(appContext: appContext)
        
        let todoListViewModel = TodoListViewModel()
        let todoListViewController = TodoListViewController(viewModel: todoListViewModel, appContext: appContext)
        let navigationController = UINavigationController(rootViewController: todoListViewController)
        
        // ...   
    }
}
{% endhighlight %}

As previously mentioned, the `AppContext` contains our eventSignal and eventObserver pair. We'll inject it into all of our other high-level components to allow them to communicate.

We have to retain the `ModelServer` and `ViewModelServer` since they have no direct references to the view layer or to one another.[^8]

Remember `TodoListViewModel` is just an inert struct. Although for this simple app, we could have had the `TodoListViewController` create its own ViewModel, it's better practice to inject it. You can easily imagine adding a "list of lists" feature to the app. In that case we (probably?) wouldn't have to change any of our interfaces.

[^8]: In "Classic" MVVM the View would own the ViewModel which would own the Model/Controller.

### View layer: List

It's actually pretty straightforward to see the boundaries of our system. The View layer will be making all the ViewModel requests and observing all the ViewModel responses.

Our subject of this section will be `TodoListViewController`. For reference:

{% highlight swift %}
// TodoListViewController.swift
final class TodoListViewController: UITableViewController {
    let appContext: AppContext
    var viewModel: TodoListViewModel
    
    // ...
}
{% endhighlight %}

We'll send our first event to request `TodoViewModel`s to fill the table view when the view appears.

{% highlight swift %}
// TodoListViewController.swift
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        appContext.eventsObserver.sendNext(Event.RequestTodoViewModels)
    }
{% endhighlight %}

Now we need to set up an observer for the response event. Observers in the View layer will always be placed in `viewDidLoad` and mirror the lifecycle of the `UIViewController` itself.

{% highlight swift %}
    override func viewDidLoad() {
        // ...
        
        appContext.eventsSignal
            // ...
            .observeNext { _ in
               // ...
            }
    }
{% endhighlight %}

#### Anatomy of an Observer

We'll have to take a deep dive into syntax now.

All of our observers have a very similar structure: 

* lifetime
* filtering
* unboxing
* mapping
* error handling
* output

For the View layer output is usually in the form of side effects (e.g. updating the view model or reloading the table view). For the other Servers, the output is usually sending another Event.

Let's take a look at `Event.ResponseTodoViewModels`.

{% highlight swift %}
    appContext.eventsSignal
        .takeUntilNil { [weak self] in self }  // #1
        .map { event -> Result<[TodoViewModel], NSError>? in  // #2
            if case let .ResponseTodoViewModels(result) = event {
                return result
            }
            return nil
        }
        .ignoreNil()  // #2
        .promoteErrors(NSError)  // #3
        .attemptMap { $0 }  // #3
        .observeOn(UIScheduler())  // #4
        .flatMapError { [unowned self] error -> SignalProducer<[TodoViewModel], NoError> in  // #3
            self.presentError(error)
            return .empty
        }
        .observeNext { [unowned self] todoViewModels in  // #5
            let change = self.viewModel.incorporateTodoViewModels(todoViewModels)
            switch change {
            case .Reload:
                self.tableView.reloadData()
            case .NoOp:
                break
            }
        }
{% endhighlight %}

* **#1**: This is an implementation detail of ReactiveCocoa that (kind of[^9]) limits the lifetime of our observer to the lifetime of `self`. In other words, stop processing this observer when this instance of `TodoListViewController` goes away.
* **#2**: This is where where we filter and unbox the value from the event if necessary. Remember, we're observing the firehose of Events that are sent throughout the app. We only want `Event.ResponseTodoViewModels`, and if so, we want its value passed along. For all the other events that come through, they'll be mapped to `nil` and discarded by the `ignoreNil()` operator.
* **#3**: This is our error handling. `promoteErrors` is an implementation detail of ReactiveCocoa which turns a signal incapable of erroring into one that can send errors of a certain type. `attemptMap` then unboxes the `Result` object and allows us to use ReactiveCocoa's built in error processing. `flatMapError` is where we have our error side effects, in this case, presenting the error as an alert. If we used `observeError` instead, our observer would be disposed of after the first error event which is not what we want.[^11]
* **#4**: Events can be delivered on any thread by the eventsSignal. Therefore, for any thread critical work we need to specify a target scheduler. In this case, our critical work is UI-related, thus we use the `UIScheduler`. Note that only the operators *after* `observeOn` will be executed on the `UIScheduler`.[^12]
* **#5**: Finally, we have a non-error value from the correct event. We'll use this to completely replace the TodoListViewModel and conditionally reload the table view if any change to the list was actually made.

[^9]: To be accurate, the observer will be triggered to complete when any event is sent and self is no longer alive. For our purposes, this shouldn't be a huge deal. There are other ways to solve this problem, but they require a lot more syntactic baggage.
[^11]: In retrospect, it may have been clearer to let the `Result` pass all the way through to `observeNext` and handle both success and error cases within the same block.
[^12]: [`Scheduler`](https://github.com/ReactiveCocoa/ReactiveCocoa/blob/master/ReactiveCocoa/Swift/Scheduler.swift) is a ReactiveCocoa primitive. It's pretty slick.

Keep in mind, this example is actually one of the trickier ones due to the error handling and multiple unwrapping stages.

#### More Actions

We'll use the `UITableViewRowAction` API to send events for marking todos as complete or deleting them.

{% highlight swift %}
// TodoListViewController.swift
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let todoViewModel = viewModel.viewModelAtIndexPath(indexPath)
        
        let toggleCompleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: todoViewModel.completeActionTitle) { [unowned self] (action, path) -> Void in
            self.appContext.eventsObserver.sendNext(Event.RequestToggleCompleteTodoViewModel(todoViewModel))
        }
        
        // ...
        
        return [deleteAction, toggleCompleteAction]
    }
{% endhighlight %}

Each of these Events are simply modifying a ViewModel. The View layer only cares about changes at the granularity level of TodoViewModel.

We want to observe `ResponseTodoViewModel` so that our view is always showing the most accurate todos. We also want to animate changes because that's nice.

{% highlight swift %}
// TodoListViewController.swift - viewDidLoad()
    appContext.eventsSignal
        // Event.ResponseTodoViewModel
        // ...
        .observeNext { [unowned self] todoViewModel in
            let change = self.viewModel.incorporateTodoViewModel(todoViewModel)
            switch change {
            case let .Insert(indexPath):
                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
            case let .Delete(indexPath):
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
            case let .Reload(indexPath):
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            case .NoOp:
                break
            }
        }
{% endhighlight %}

Those are the basics of the View layer. Let's move to the `ViewModelServer` to see how we can respond to these request Events and issue new ones.

### ViewModel: List

`ViewModelServer` is one big init method for setting up observers.

{% highlight swift %}
// ViewModelServer.swift
final class ViewModelServer {   
    init(appContext: AppContext) {
        // ... all observers go here    
    }
}
{% endhighlight %}

#### Event.RequestTodoViewModels

`ViewModelServer` listens for ViewModel requests and sends ViewModel response Events.

`.RequestTodoViewModels` is pretty simple. It just creates a corresponding request from the model layer.[^14]

{% highlight swift %}
    appContext.eventsSignal
        // ... Event.RequestTodoViewModels
        .map { _ in Event.RequestReadTodos }
        .observeOn(appContext.scheduler)
        .observe(appContext.eventsObserver)
{% endhighlight %}

We're sending this event back to the eventsObserver to dispatch our new Event. Notice we have to dispatch this event on a specific scheduler. If we don't, we'll hit a deadlock. It's a ReactiveCocoa implementation detail and beyond the scope of this post, so for the time being, just notice we have to add that line to any observers that map to new events.

[^14]: If you are unfamiliar to MVVM, you may be wondering why the View layer didn't simply issue a RequestReadTodos Event directly instead of relaying the RequestTodoViewModels Event through the ViewModelServer. It's a welcome layer of indirection to have our View layer be unaware of all matters related to the Model layer. It introduces a predictability for yourself and others on the project that all types of objects and values obey the same set of rules with regards to what they're allowed to do and which other objects they're allowed to talk to. It it certainly overhead, and feels like it in the early stages of a project, but in large projects I've rarely found it to be unwarranted optimization.

#### Event.ResponseTodos

We can now expect a response to the Model event we just sent out.

{% highlight swift %}
    appContext.eventsSignal
        // ... Event.ResponseTodos
        .map { result -> Result<[TodoViewModel], NSError> in
            return result
                .map { todos in todos.map { (todo: Todo) -> TodoViewModel in TodoViewModel(todo: todo) } }
                .mapError { $0 } // placeholder for error mapping
        }
        .map { Event.ResponseTodoViewModels($0) }
        .observeOn(appContext.scheduler)
        .observe(appContext.eventsObserver)
{% endhighlight %}

We're mapping `Result<[Todo], NSError>` to `Result<[TodoViewModel], NSError>` and sending the result as a new Event. There's a placeholder for where we could map the error from the Model layer to one more suited to show the user.[^15]

[^15]: It was lazy to not include a typed error enum from the Model layer. The transformation pipeline we have set up makes it easy to make our data available in the right representation for the right context.

#### Other ViewModel Events

In the view layer, we saw that two events, `RequestToggleCompleteTodoViewModel` and `RequestDeleteTodoViewModel`, could be sent to change individual ViewModels on the fly.

The map block for delete is:

{% highlight swift %}
    .map { todoViewModel -> Event in
        var todo = todoViewModel.todo
        todo.deleted = true
        return Event.RequestWriteTodo(todo)
    }
{% endhighlight %}

The map block for complete is:

{% highlight swift %}
    .map { todoViewModel -> Event in
        var todo = todoViewModel.todo
        todo.completedAt = todo.complete ? nil : NSDate()
        return Event.RequestWriteTodo(todo)
    }
{% endhighlight %}

Straightforward transformations, then we fire off a message.

Both events will receive responses on `Event.ResponseTodo`.

{% highlight swift %}
    .map { result -> Result<TodoViewModel, NSError> in
        return result.map { todo in TodoViewModel(todo: todo) }
    }
    .map { Event.ResponseTodoViewModel($0) }
{% endhighlight %}

### Other Highlights

I won't dive much deeper into the other events. I'll only mention a few other highlights that were interesting.

#### TodoDetailViewModel

The `TodoDetailViewController` accepts a `TodoDetailViewModel` that allows the user to mutate its properties. When done is tapped, `TodoDetailViewController` will send a request to the `ViewModelServer` with its `TodoDetailViewModel`. The `ViewModelServer` will validate all the new parameters and send a response. The response event `Event.ResponseUpdateDetailViewModel` is interesting because it will be observed by three different objects.

* `TodoDetailViewController` will observe it for errors. If there are errors with the validation, it will present the error above the current context.
* `TodoListViewController` will observe it for non-errors, interpreting that as a sign that the user has finished editing the view model and it should dismiss the `TodoDetailViewController`.
* `ViewModelServer` will observe a message it itself will be sending because it has to now create an updated todo Model and send a write todo Event. The response to that will come back through the normal Event stream and be updated transparently by the `TodoListViewController`.

#### ResponseUpdateDetailViewModel

I sort of like how the common CRUD new and edit actions are rolled into one interface. Both previously saved and unsaved Todos can be treated similarly. Validation is treated as asynchronous, and could therefore easily be a server-side operation.

#### Loading

I didn't implement any loading indicators, but it would be trivial to do so. The ViewController would observe its own Request event and toggle a loading indicator on as a side effect. Then it would toggle the loading indicator off as a side effect of the Response event.

#### Unique Identifiers

One thing you may notice in the code base is that every value type must be equatable. Since requests and responses are not directly paired, having a unique identifier is critical to being able to filter and operate on responses. There are actually two concepts of equality that come into play. The first is normal equality, as in "do these two models have the exact same values for all of their parameters?". The second is equal identity, as in "do these two models represent the same underlying resource?" (i.e. `lhs.id == rhs.id`). Equal identity is useful in operations where a model has been updated and you want to replace it.

#### Testing

I'd consider testing to be straightforward in the ViewModelServer and ModelServer layers. Each of these Servers registers observers at are essentially pure functions in that they receive a single event and dispatch a single event. An example unit test:

{% highlight swift %}
// todostreamTests.swift
    // ...
    
    func testRequestToggleCompleteTodoViewModel() {
        viewModelServer = ViewModelServer(appContext: appContext)
        let todo = Todo()
        XCTAssert(todo.complete == false)
        let todoViewModel = TodoViewModel(todo: todo)
        let event = Event.RequestToggleCompleteTodoViewModel(todoViewModel)
        
        let expectation = expectationWithDescription("")
        appContext.eventsSignal.observeNext { (e: todostream.Event) in
            if case let todostream.Event.RequestWriteTodo(model) = e {
                XCTAssert(model.complete == true)
                expectation.fulfill()
            }
        }
        
        appContext.eventsObserver.sendNext(event)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
{% endhighlight %}

The above section tests one observer in ViewModelServer and expects the result Event to be at the boundary between the ViewModelServer and ModelServer.

Integration testing isn't outside the realm of possibility either. Here's an example integration test for the same event that instead waits at the boundary between the View and ViewModelServer layers:

{% highlight swift %}
// todostreamTests.swift
    // ...
    
    func testIntegrationRequestToggleCompleteTodoViewModel() {
        viewModelServer = ViewModelServer(appContext: appContext)
        modelServer = ModelServer(configuration: Realm.Configuration.defaultConfiguration, appContext: appContext)
        let todo = Todo()
        XCTAssert(todo.complete == false)
        let todoViewModel = TodoViewModel(todo: todo)
        let event = Event.RequestToggleCompleteTodoViewModel(todoViewModel)
        
        let expectation = expectationWithDescription("")
        appContext.eventsSignal.observeNext { (e: todostream.Event) in
            if case let todostream.Event.ResponseTodoViewModel(result) = e {
                let model = result.value!.todo
                XCTAssert(model.id == todo.id)
                XCTAssert(model.complete == true)
                expectation.fulfill()
            }
        }
        
        appContext.eventsObserver.sendNext(event)
        
        waitForExpectationsWithTimeout(1.0, handler: nil)
    }
{% endhighlight %}

In this case, behind the scenes there are two other events sent in the meantime, but we're only waiting for the last one.

Both servers are very shallow and only have the EventSignal as a dependency.

## Retrospective

Now that we've seen some of the implementation of a very basic app, let's take a step back and look at the pros and cons we discovered along the way.

* **PRO** Some things that are hard in other paradigms are easier! :D
* **CON** Some things that are easy in other paradigms are harder! :(
* **PRO** It was actually a lot of fun writing in this style.
* **CON** There are probably performance implications that are currently unknown regarding having lots of observers alive, each receiving lots of events that must be filtered.
* **PRO** Threading seems to be very safe.
* **CON** Still a lot of unsolved problems. How to deal with image loading? Auth systems? Multi-step operations that must be ordered specifically? Re-sorting the list? More complicated view change types? Wrapping other asynchronous APIs? The list is endless. A half-baked todo app hardly pushes the bounds of system complexity.
* **PRO** All the code (minus UIKit) is all stylistically similar and very functional.
* **CON** All events are public (to the system) and therefore more unexpected consequences are likely to occur as the system grows in size and complexity.
* **CON** There's a fair amount of boilerplate in observer declarations.
* **PRO** It's easier to reason about ownership and lifetime of objects.
* **CON** Using Result for error handling doesn't quite fit. I need to investigate another hunch I have about how to do it better.[^13]
* **PRO** Testing is arguably a fairly painless process.
* **PRO** It would be possible to "playback" a user's entire session by piping the serialized saved output from `eventsSignal` into the `eventsObserver` in a new session.
* **PRO** Analytics would be very easy to set up as a separate Server-type object that could listen into Events as they are placed onto the stream and transform them and POST them to a server as necessary.

[^13]: Spoiler alert: it's adding an `error` parameter to all models and view models.

## Library

After I finished building this Todo app, I realized that ReactiveCocoa wasn't necessarily the best tool for implementing EventMVVM. I don't use a lot of its features and there are some quirks because I'm not using it as it was intended to be used.[^10]

I decided to see if I could write my own simple library that was tailored to implementing EventMVVM. It took a day of wrestling with the type system, but I have an alpha that I'm going to try to test out. It's only about 100 lines of code. Unfortunately, it couldn't automate all the things I wanted to so the observing process still has some warts. I'll try to find some time to write something up about the library later.

You can see my progress on [Github](https://github.com/twocentstudios/CircuitMVVM).

[^10]: It could probably be implemented with `NSNotificationCenter` (not that I'd ever try that). Or any of the other Reactive Swift libraries.

## Wrap up

It was fun exploring the EventMVVM architecture paradigm. I might keep exploring it on the side. I would definitely not recommend implementing anything of consequence with it.

Please let me know on [Twitter](https://twitter.com/twocentstudios) if you have any thoughts about the EventMVVM. I'm sure there's already a name for this style (maybe it's just the [observer pattern](https://en.wikipedia.org/wiki/Observer_pattern)?).

How cool is it though that I could add this one observer to `AppDelegate` and get a log of every Event passed in the system?

{% highlight swift %}
appContext.eventsSignal.observeNext { print($0) }
{% endhighlight %}

---