---
layout: post
title: On MVVM, and Architecture Questions
date: 2014-06-08 15:31:52.000000000 -05:00
comments: true
categories: apple ios
redirect_from: "/blog/2014/06/08/on-mvvm-and-architecture-questions/"
---

> This post is something like a mini-walkthrough/tutorial, but it stops about half way from being complete. The goal is to elicit some discussion about the architecture of iOS apps from those experienced with both MVVM and MVC patterns.

There have been several converging iOS topics I've been interested in as of late. Each of these topics has influenced my approach to what I would consider a grand refactor of the Timehop app.

## A Bit of Background

Our architecture has remained more or less unchanged in the 1.5 years the app has been available on the App Store. The app is primarily backed by Core Data behind a legacy version of RestKit. We also use standard serialized files as well as NSUserDefaults in various modules of the app.

As Core Data often demands (via NSFetchedResultsController) our view controllers have classically been highly coupled with our data source layer. We often use UIImageView+Networking type categories to do fetching directly from the view layer. We use various techniques (within and without Rest Kit) to serialize, fetch, and map data. It's a mess.

But at the end of the day, this architecture has allowed us to move fast and try any number of features and enhancements in every corner of the app, and it's got us to the point where we are today: growing.

With millions of daily opens, our goal is an architecture that is performant, crash-free, and *very* light on maintenance.

## New Techniques

In order to achieve our architecture goals, we've been evaluating new techniques outside the mainstream iOS realm. The rest of this post will detail how we've attempted to incorporate these techniques into the app.

### ReactiveCocoa

I've been experimenting with [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) on a few [past projects](http://twocentstudios.com/blog/2013/04/03/the-making-of-vinylogue/), and even used it to implement a recent Timehop experiment called "Throwbacks". ReactiveCocoa is awesome. Its benefits deserve their own post, but suffice to say the team here is becoming comfortable enough with ReactiveCocoa techniques that it will play a major role in whatever the next version of Timehop becomes.

### MVVM

ReactiveCocoa goes hand in hand with the [MVVM](http://en.wikipedia.org/wiki/Model_View_ViewModel) architecture pattern. My only exposure to MVVM has been through the ReactiveCocoa ecosystem. MVVM is a difficult pattern without the aid of the concise binding framework like ReactiveCocoa to synchronize the view and view model layers.

### Testing & Dependency Injection

And the third component I've been dabbling in is automated testing. We haven't chosen a particular library yet, but most of the options are similar enough to fulfill our requirements of ensuring stability and future refactorability. Going along with testing, I've been reading about dependency injection as a way to ensure testability and keep components as modular as possible.

## Fitting the Pieces Together

So far, my friend and co-worker [Bruno](https://twitter.com/biasedbit) and I have written a couple components of our architecture from scratch with the goal of slowly replacing the tightly coupled components of our current app. Specifically, we've started with the Timehop settings screen. The settings screen primarily holds the logic for connecting and disconnecting the various social services from which we import data. There are also several various preference and contact screens.

This is where I'll start asking questions and positing solutions for how to architect an MVVM module that is testable and doesn't trip over its own layers of indirection.

## My Understanding of MVVM

MVVM is often introduced in this [simple diagram](https://github.com/ReactiveCocoa/ReactiveViewModel#model-view-viewmodel):

{% highlight text %}
View => View Model => Model
     <-            <-
{% endhighlight %}

Where `=>` represents some combination of ownership, strong references, direct observation, and events. `<-` represents the flow of data (but not direct references, weak or strong).

In Cocoa-land/objc-world:

* The view layer is comprised primarily of `UIView`s and `UIViewController`s. 
* The view model layer is comprised of plain `NSObject`s.
* The model layer is comprised of what I'll actually call controllers, but could also be known as clients, data sources, etc. The roles are more important to keep in mind than the names. Controllers are also usually `NSObject` subclasses. 
* Model objects are the fourth role and raw models are the fifth. 
    * We'll define model objects as simple dumb stores of data in properties on `NSObject`s. 
    * We'll define raw models as a representation of data in a non-native format (e.g. JSON string, `NSDictionary`, `NSManagedObject`, etc.).

### Rules

I've introduced the rules of each role in order to clarify the separation of concerns. Below are the rules that separate the concerns of each of the previous roles. Without context, the rules are somewhat abstract, so I'll introduce examples immediately afterwards.

#### Views

* Views are allowed to access views and view models.
* Views are *not* allowed to access controllers or model objects.
* Views bind their display properties directly to view model properties.
* Views pass user events to view models via `RACCommand`s/`RACAction`s, or alternatively by calling methods on the view models.

#### View Models

* View models are allowed to access view models, controllers, and model objects.
* View models are *not* allowed to access views or raw models.
* View models convert model objects from controllers into observable properties on `self`, or other view models.
* View models accept inputs from views or other view models which trigger actions on `self`, other view models, or controllers.

#### Controllers

* Controllers are allowed to access other controllers, model objects, and raw models.
* Controllers are *not* allowed to access view models or views.
* Controllers coordinate model object access from other controllers or directly from system level raw data stores (network, file system, database, etc.).
* Controllers vend asynchronous (or maybe better put *time-agnostic*) data (via `RACSignal`s) to view models or other controllers.
* Have to stress again that these are *not* view controllers!

### The MVVM Diagram Again

Let's make a more detailed version of that MVVM diagram for Cocoa specifically.

{% highlight text %}
View ========> View Model ========> Controller ========> Data Store
  |                |                    |
View           View Model           Controller
{% endhighlight %}

To clarify, `===>` represents an ownership as stated above. `|` also represents an ownership of the bottom object by the top object. A view could spawn one or more subviews, present other view controllers, and also bind to a view model. Similarly, a view model could keep a collection of view models for its owning view to distribute to that view's subviews. That view model can also have a controller and connect controllers to its sub-view models.

Secondly, here is the flow of objects between the roles.

{% highlight text %}
View <-------- View Model <-------- Controller <-------- Data Store
    (view model)        (model object)        (raw model)
{% endhighlight %}

Notice from the first chart that all relationships are unidirectional. Thus there is only direct coupling at one interface and in one direction. It's now possible to replace our view layer with a testing apparatus and test the interface between the view and view model directly. It's also possible to test the interface between the view model and controller layer.

Notice from the second chart that each role transforms one class of objects into another class. Our role graph starts to look like **a pipeline for transforming data from right to left, and pipeline for transforming user intentions from left to right.**

#### An Aside About Synchronous/Asynchronous

In most apps, there's an implicit distinction between methods that do synchronous work versus those that do asynchronous work. One best-practice is to write synchronous methods that are wrapped by asynchronous methods.

With ReactiveCocoa, synchronous and asynchronous are both treated as asynchronous. By treating everything as asynchronous, you would normally be committing your project upfront to an unnecessary burden of delegate or block callbacks strewn about the calling object. However, using a system with chainable operations, sane processing semantics (including built-in thread routing operations), and concise bindings makes it significantly easier to work with asynchronous data. Thus, treating all operations as asynchronous becomes a win when synchronous and asynchronous operations can be processed in the same ways (and combined). It is also a win because consumers of operations no longer require unnecessary knowledge of how expensive an operation might be.

### A Simple Example

Let's start with a simple example that will quickly spiral out of control. Imagine a view that represents a user's profile. It should show a photo of the user, a label with the user's name, a label with the number of friends the user has, and a refresh button because the user's friend count changes *a lot* in this example.

> This code was not written in an IDE, so please bear with typos.

#### View

The view is pretty simple.

{% highlight objc %}
@class HOPProfileViewModel

@interface HOPProfileView : UIView

@property (nonatomic, strong) HOPProfileViewModel *viewModel;

@end

@inteface ProfileView ()

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *friendCountLabel;
@property (nonatomic, strong) UIButton *refreshButton;

@end

@implementation ProfileView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    _avatarView = [[UIImageView alloc] init];
    [self addSubview:_avatarView];
    
    // ... create and add the other views as subviews
    
    RAC(self.avatarView, image) = RACObserve(self, viewModel.avatarImage);
    RAC(self.nameLabel, text) = RACObserve(self, viewModel.nameString);
    RAC(self.friendCountLabel, text) = RACObserve(self, viewModel.friendCountString);
    RAC(self.refreshButton, rac_command) = RACObserve(self, viewModel.refreshCommand); 
    
    return self;
}

- (void)layoutSubviews { /* ... */ }

@end
{% endhighlight %}
    
A few things going on here:

* The view is not bound to a view model for its entire lifecycle. This case is more rare. Most views should be bound to a particular view model for their entire lifecycle. Less mutability reduces view complexity greatly. You would normally require the view model be passed into the receiver on `init`. However, in this case we're allowing the view model to be swapped out during this view's life, and we therefore must reconfigure its data properly. You'd typically see this pattern in reusable views such as `UITableViewCell`s.
* We're creating a one way binding using ReactiveCocoa from our view model properties to view properties. Notice there is no data transformation at this stage.
* The ReactiveCocoa will ensure `self.avatarView.image` is set with the current image in the `self.viewModel.avatarImage` property. It will ensure this even if the `viewModel` object itself changes during this view's lifecycle. If our view was initialized with a view model, we could write `RAC(self.avatarView, image) = RACObserve(self.viewModel, avatarImage)` instead and only the `avatarImage` property will be observed.
* The label properties work the same way as the imageView's.
* `RACCommand` is a somewhat magical object that transparently manages state between an action and its asynchronous results. The important part to notice here is that the view model owns and configures the `RACCommand` object in question. Behind the scenes, the `rac_command` helper category on `UIButton` performs three tasks (heavily simplified):
    * Calls `-[execute:]` on the view model's `RACCommand` on the touchUpInside action.
    * Disables itself while the `RACCommand` is executing.
    * Re-enables itself when the `RACCommand` finishes executing.
* Imagine that there are standard `layoutSubviews` and `sizeThatFits:` methods.

You may be asking what this buys us so far over the typical pattern of passing in a model object to our view via a setter like `-[setData:(HOPUser *)]`.

* It's straightforward to add functionality to this view/view model pair. Need to load a low res cached image after a placeholder image followed by a high res network image? The view layer doesn't change. It will automatically adopt whatever image is currently stored by the view model. There will never be a sprawl of callbacks originating from views hitting the network.
* Our friend count is stored in our model as an `NSNumber` but our label needs a formatted `NSString`. The view layer isn't bothered with the conversion, whether it be a simple @25 -> "25" or @25 -> "This user has 25 friends".
* We can test the view model directly by allowing the test bench to compare `UIImage`s and `NSString`s.
* In a more proper version of this view, a superview would bind a view model to a more generic subview, and thus enable a set of ultra-reusable content blocks to be used throughout the app with one or more various view models. The glue code is simple one-to-one bindings.

In short, we've separated the data manipulation stage from the presentation.

#### View Model

Now let's tackle the view model. The interface should look pretty familiar.

{% highlight objc %}
@class HOPUser;

@interface HOPProfileViewModel : NSObject

@property (nonatomic, strong, readonly) UIImage *avatarImage;
@property (nonatomic, copy, readonly) NSString *nameString;
@property (nonatomic, copy, readonly) NSString *friendCountString;
@property (nonatomic, strong, readonly) RACCommand *refreshCommand;

- (instancetype)initWithUser:(HOPUser *)user;

@end
{% endhighlight %}
    
Notice all these properties are readonly. The view is free to observe all these properties and call `execute` on the `RACCommand`. The view model obscures all its internal operations and provides a limited window into its state to its observers (its view).

There's a designated initializer that accepts a `HOPUser` model object. For now, assume that another view model created this `HOPProfileViewModel` with a model object before it was bound to its view (I'll come back this as my most glaring questions about MVVM).

{% highlight objc %}
@interface HOPProfileViewModel ()
    
@property (nonatomic, strong) UIImage *avatarImage;
@property (nonatomic, copy) NSString *nameString;
@property (nonatomic, copy) NSString *friendCountString;
@property (nonatomic, strong) RACCommand *refreshCommand;

@end

@implementation HOPProfileViewModel

- (instancetype)initWithUser:(HOPUser *)user {
    self = [super init]
    if (!self) return nil;
            
    RAC(self, avatarImage) = 
        [[[[[RACObserve(self, user.avatarURL)
            ignore:nil]
            flattenMap:(RACSignal *)^(NSURL *avatarURL) {
                return [[HOPImageController sharedController] imageSignalForURL:avatarURL];
            }]
            startWith:[UIImage imageNamed:@"avatar-placeholder"]]
            deliverOn:[RACScheduler mainThreadScheduler]];
    
    RAC(self, nameString) = 
        [[RACObserve(self, user.name)
            ignore:nil]
            map:(NSString *)^(NSString *name) {
                return [name uppercaseString];
            }];
    
    RAC(self, friendCountString) = 
        [[RACObserve(self, user.friendCount)
            ignore:nil]
            map:(NSString *)^(NSNumber *friendCount) {
                return [NSString stringWithFormat:@"This user has %@ friends", friendCount];
            }];
            
    @weakify(self);
    _refreshCommand = [[RACCommand alloc] initWithSignalBlock:(RACSignal *)^(id _) {
        @strongify(self);
        return [[HOPNetworkController sharedController] fetchUserWithId:self.user.userId];
    }
    
    RAC(self, user) = 
        [[[_refreshCommand executionSignals] 
            switchToLatest] 
            startWith:user];
}

@end
{% endhighlight %}

Alright, there's a lot more going on in this view model than there was the view. And that's a good thing. There's some slightly advanced ReactiveCocoa, but don't get hung up on it. The goal is to understand the relationship between the view, view model, and controllers.

* First, we redeclare our outward-facing properties as readwrite internally.
* Our first property binding is the `avatarImage`. We see that our image is represented as a URL in the `HOPUser` model. We first observe the `avatarURL` property on whatever the view model's current user model is. Each time it changes, we take that URL and feed it into our singleton `HOPImageController`. The image controller is responsible for caching thumbnails, full images, and also fetching images from the network. This signal will send up to three different images which will eventually be assigned to `self.avatarImage`. The images may be fetched on background thread, so we make sure they're delivered to their eventual destination imageView on the main thread.
* The next property binding is `nameString`. We're only performing one mapping operation on this string: uppercasing.
* We map the friend count to a human-readable string.
* The `refreshCommand` is created from scratch. It subscribes to the signal block each time the command is executed (in our case, when the button is pressed). The command automatically keeps track of the state of our signal and will not execute again until the inner signal has completed. In this case, we're assuming our data comes from a shared `HOPNetworkController` which sends a `HOPUser` object and completes.
* The `self.user` mapping first assigns the `user` object passed into the `init` method, then takes the latest result from the command's execution.

There was a lot to digest in that example. Things to notice:

* All of the code was incredibly declarative. We stated exactly what each of our properties should be at any given time. They're all only set from one place.
* We have a lot of flexibility changing the operations on our model object's properties in response to product changes.
* It's incredibly easy to mock this object for our view. It only has four external properties. For example, our fake implementation could map our `self.avatarImage` property to `[[[RACSignal return:[UIImage imageNamed:@"final"]] delay:4] startWith:[UIImage imageNamed:@"placeholder"]];` which would simulate a placeholder image, a four second fake network delay, and a final image.
* I'll leave error handling for another post, but as a quick summary is the `RACSignal` contract makes it almost trivial to bubble up errors to the view model layer and present them in the proper way.

#### Controller

I have more questions than answers when it comes to the controller layer. I'll present the header files for the two classes we used above and we'll go from there.

{% highlight objc %}
@interface HOPImageController : NSObject

// The shared instance of this class.
// Inside it has three functions:
// * It maintains a separate network client for fetching raw image data.
// * It maintains a key/value store of imageURLs and images on disk.
// * It adds images from the network to the cache.
+ (instancetype)sharedController;

// The returned signal sends an image from the cache if available,
// then an image from the network, then completes.
// The signal sends an error if there was a network error.
- (RACSignal *)imageSignalForURL:(NSURL *)URL;

@end


@interface HOPNetworkController : NSObject

// The shared instance of this class.
// Inside it manages a network session.
+ (instancetype)sharedController;

// The returned signal sends a HOPUser, then completes.
// The signal sends an error if there was a network error.
- (RACSignal *)fetchUserWithUserId:(NSNumber *)userId;

@end
{% endhighlight %}
    
### Questions

I tried to include some non-trivial aspects to this view/view model/controller set up, but at the end of the day this set of objects has to exist in a much broader application.

In something run-of-the-mill like a `UITableView` system, there could quickly be a large graph of view models that each held arrays of view models which then have to be mapped to sections and reusable cells, and it can quickly become a mess of mapping view model class names to views, all while handling changing intermediary objects, refreshing, and errors at the individual cell level.

I left a lot of hanging questions in the system I've presented above (only somewhat purposefully). I'm hoping someone with more experience in MVVM can shed some light on these.

#### Where is the top of the object graph?

I stared off talking about testing, but by the end I was embedding singleton controllers deep within my view model implementation. In the interest of dependency injection, they should be specified at initialization. Being available as parameters for `init` is great for testing, but in the actual app, which view or view model should be responsible for creating the view model in question along with knowing exactly which controllers to provide? 

At a certain point, *some* object is going to have to connect all the dots and assemble the entire object graph. And at that point it may well be creating objects of all three roles (views, view models, and controllers). On one hand, it seems very offputting to allow one god object to have the entire map of the application. But on the other hand, that's sort of like an extreme form of composition: all lower level objects are very dumb with very specific inputs and outputs.

Is this what the router is in Rails? It starts stateless and uses its request input parameters to assemble the object graph, produce a response, then tear it down.

Are there other examples or patterns in other languages? I'm curious if this would all be more clear if I was more versed in Haskell, or enterprise Java, or any other number of languages.

Is the right answer for testing to have designated "testing" initializer that accepts a `HOPImageController` instance and a `HOPNetworkController` instance that can be mocks, while the application version is initialized with no parameters and configures its own controllers?

#### When should controllers be singletons?

Is there a hard and fast rule in MVVM for when a controller should be a singleton? When a resource starts storing state amongst disparate objects is that cause for being a singleton? Maybe the goal is actually on the opposite end: every controller should be a singleton to keep all services completely autonomous and interchangeable.

My first hunch on this was that controllers that sat adjacent to system raw object producers (e.g. the network interface, an SQLite db, the file system, `NSUserDefaults`, etc.) would be singletons. But I also saw, for example, a controller that reads a single file should be configurable with a file URL by a parent object. Maybe it just depends on where you draw the line between needing lots of helper controllers and doing all the fetching directly from the view model.

#### What are a view controller's responsibilities?

Don't get me wrong, doing some OS X development for the first time gave me a deep appreciation for `UIViewController`. But there's still a lot of API cruft that's developed on `UIViewController` that makes certain things difficult.

When you're trying to express your app as declaratively as possible, it's sometimes easy to get lost in what the view controller hierarchy looks like, and how the imperative view controller changes can really put a stick in your tires.

I don't have as many examples yet since I'm still sort of getting a lay of the land with MVVM, but maybe I'm wondering whether there's a two-tiered view system: the bottom tier is very dumb and just gets bound to view models, and then the top tier which does all the object graph assembly (and dependency injection) for the lower layers. Or is it a two-tiered view *and* view model system?

#### How should we treat the current user and the user's session?

In iOS apps, it's taken for granted that we only have to handle one user session at at time. In the Timehop app, we use the currentUser object on almost every screen.

Would it be The Right Way™ to pass this user object into a view model from the top of the object graph down to all the other view models/controllers that need it? Would this be a case where a singleton user session controller makes sense to store the currently logged in user? In either case, how can we react to a user logging out without depending on the way the view hierarchy is laid out?

Maybe the user session would be stored at the top level of the application, and then changes to the current user would be pushed directly to the top level view models and these view models would react accordingly. This would seemingly become quite unwieldy if a large number of sub view models had already been spawned from the top level view model. The top level view model would either have to distribute the current user to every other object directly and keep pushing new current users, or it would distribute the current user once and treat it as immutable on sub view models from then on.

Relatedly, what about the current user's auth token? In our example application, we have a network controller that requires the user's auth token to be sent in the header of nearly every request. Should the network controller be a singleton with a mutable `authToken` parameter maintained by the application? Should one network controller be created at the top level and passed directly from view model to view model? How do we propagate changes in the auth token? What does not using a singleton buy us in this situation?

My initial solution to this problem was to have a userSessionController singleton that holds the currentUser object. This singleton creates a new immutable instance of the network controller, database controller, user defaults controller, etc. whenever the currentUser object changes. Almost all requests from other controllers or view models go through the userSessionController singleton. The user session quickly becomes another god object distinctively separate from the app delegate, and now almost every view model and controller is bound directly to the userSessionController singleton.

I've talked myself in circles with this one. I can sort of see the pros and cons with each, and maybe the technique used is completely dependent on the individual product requirements for each app.

## Summary

I tried to explain MVVM at a high level the way I currently understand it. I wrote a flat example with a component from each role. I then explored several questions that arose from this exercise and a few other situations.

I would greatly appreciate any feedback on this post. In particular, I'd really like to flesh out my understanding of MVVM in large architectures that can scale to multiple data sources, hundreds of views, and millions of users all while staying snappy and crash-free.
