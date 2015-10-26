---
layout: post
title: "How I Wrote Vinylogue for iOS with ReactiveCocoa"
date: 2013-04-03 12:36
comments: true
published: true
categories: iOS, ReactiveCocoa 
---

[Vinylogue](http://twocentstudios.com/apps/vinylogue "vinylogue") is a simple app I designed and developed for iOS that shows your last.fm weekly album charts from previous years. This post will detail the process of creating V1.0 of the app from start to almost finish (is an app ever really finished?).

The full source is available [on GitHub](https://github.com/twocentstudios/vinylogue).

Warning: this post is super long (10000+ words). I spend a lot of time discussing ReactiveCocoa techniques, a little bit of time on pre-production, and a little bit of time on design.

### Contents

* [Idea](#idea)
* [Planning](#planning)
* [Development pt.1](#development1)
* [Design](#design)
* [Development pt.2](#development2)
* [End](#end)

## [Idea](id:idea)

I recently came across an awesome app called [TimeHop](http://timehop.com) that compiles your past posts from Facebook, Twitter, etc. and shows you what you posted on that day one year ago. I love reminiscing through my old things, so this concept was right up my alley.

I also love music too though, and have been an avid [Last.fm](http://last.fm) user since 2006 or 2007, scrobbling tracks religiously. I thus have quite a history of my past album listens in their database, and with those listens, a lot of memories connected to those albums. I can remember exactly what I was doing, where I was, and mental snapshots when I see an album or group of albums together.

And so the idea of combining Last.fm and TimeHop was born.

## [Planning](id:planning)

### Getting a feel for the data

The first step was seeing what data was available from the Last.fm API. I could indeed get a weekly album chart (a list of albums, ranked by number of plays) for a specified user and week with [user.getWeeklyAlbumChart](http://www.last.fm/api/show/user.getWeeklyAlbumChart). It's also possible to get the same chart grouped by artist or track, but at the current time it seemed like albums would appeal to me most.

One of the great things about this particular API call is that you don't need a password for the username you're requesting. One of the bad things was that you can't just send a particular timestamp and let Last.fm figure out what week that date falls into.

The latter problem is solved by making another API request to [user.getWeeklyChartList](http://www.last.fm/api/show/user.getWeeklyChartList). This call provides the specific weekly date ranges in Epoch timestamps you can then use as an input to the user.getWeeklyAlbumChart call. The data looks something like this:

{% codeblock user.getWeeklyChartList lang:js %}
	"chart": [
		{
			"from": "1108296002",
			"to": "1108900802"
		},
		{
			"from": "1108900801",
			"to": "1109505601"
		},
		…
	]
{% endcodeblock %}

Two API calls so far to get most of our data. Not bad. So to document our information flow:

* take the current date
* subtract `n` years (1 year ago to start)
* figure out where that date is within the bounds of the Last.fm weeks
* request the charts for the username and date range
* display the data

Pretty simple. Time to dig in a little more.

### Features

It's best to draw a line in the sand about what the constraints of the app will be, at least in the first version. Below are my first set of constraints. They (inevitably) changed later in the project, and we'll discuss those changes as we make them.

* We'll support only one last.fm user.
* The user can view charts from the week range exactly `n` years ago (with the lower bound provided by Last.fm).
* The user cannot view any charts newer than one year ago.
* The app has a chart view and a settings view (keeping it very simple).

Again, I'll discuss changes as they happened in the process.

### Schema

Next I had to decide how the data would be structured and stored. The initial options were:

#### Keep everything transient

We should request everything from the network each time. Don't store anything in Core Data. We're only looking at old data and we don't have to worry about realtime feeds so we can use the regular old NSURLCache and set our cache times basically forever (in practice, it's a little more complicated than this).

(As an aside, I ended up using SDURLCache as a replacement for NSURLCache. From pure observation, NSURLCache was faster from memory, but I could not get it pull from disk between app terminations.)

The weekly charts technically only need to be pulled from the server once a year (I'll leave that as an exercise to the reader as to why). The chart data for a particular week is only relevant once per year the way the app is set up.

At the end of the day, the URL cache ends up being a dumb key-value store keyed on URLs and returning raw json data.

* Pros
	* Less complexity keeping data in sync.
* Cons
	* More data transferred. 
	* Longer waiting for previously requested data.

#### Incrementally build our own database of the data we request

We should set up a full schema of related objects. Data should be requested locally, and if it doesn't exist, it should be requested from the server and added to the local database.

* Pros
	* Speed of subsequent requests.
	* Less API requests.
	* May enable future features.
* Cons
	* Much greater complexity keeping data in sync and knowing when the cache is invalid.
	* More local storage required.
	
#### Decision

I was much more inclined to build a local database, but a big goal of this project was a quick ship. I decided to take a few hours building something out with [AFIncrementalStore](https://github.com/AFNetworking/AFIncrementalStore). It didn't take long to realize doing things this way would slow down development substantially. I decided to keep the local database method as a goal, but leave it until the app idea itself was validated with users. At the current time, it felt like premature optimization.

I went ahead with the two table Core Data schema since I already had it set up and my classes generated with [Mogenerator](https://github.com/rentzsch/mogenerator). I added fields for the data I wanted from the user.getWeeklyChartList API call.

Later, I would completely rid Core Data from the project and turn these model objects back into standard NSObject subclasses.

{% caption_img /images/vinylogue-schemav1.png Schema V1 %}

### Wireframing

Since I now had an idea of what data I had to work with, it was time to put together wireframes of what the main views would look like.

The aim was simplicity. One main view that shows a single week's charts. Another modal view for settings and about.

I wanted to go with a more classic look with a standard UINavigationBar. A UITableView as a given based on the nature of the data (unknown number of albums, 0 - ???).

{% caption_img /images/vinylogue-wireframe.jpg Essential elements of the weekly chart view / Proposed inter-year navigation mechanism %}

I also needed to show additional metadata including what week and year were being shown, and also what user was being shown. Maybe some sort of table header view?

The next decision was how the user should navigate to past and future years. The first thought was a pull-up-to-refresh-type control to go to the future, and a pull-down to go back. iOS users are pretty used to that control type being for refreshing data, and it probably wouldn't work with the metadata on a table header view already. Not to mention the amount of scrolling it might take to get to the bottom of the table view.

My solution was to combine the metadata header view and selection into one view/control. I like sliding things, so sliding left and right would request future and past years, respectively. While creating the control later, I also decided that classic arrow buttons would be a good idea so the functionality was immediately discoverable.

{% caption_img /images/vinylogue-slideselectview.jpg SlideSelectView %}

And finally, there was the table view cell itself. I wanted to keep this classic. Album image on the left, artist above album name, artist reemphasized and album name emphasized, and play count on the accessory side. I also left a placeholder for the numbered rank above the album image, but decided it was unnecessary later in the process.

{% caption_img /images/vinylogue-cell.jpg Cell detail %}

I wanted to get a feel for the settings view too, so I sketched that out. When I was getting my first prototype results back, I realized that if you listen to a lot of mixes, you'll have row after row of albums with 1 play. I personally wanted the option to only see "full" album listens, and decided to add an option to filter rows by play count.

{% caption_img /images/vinylogue-settings.jpg Settings view wireframe %}

## [Development](id:development1)

Finally time to dig into some coding (for real)! Well, almost time…

### Setup

Up to this project, I still was git cloning all my external libraries into a lib folder and doing the target settings dance with static libraries. It seemed like [CocoaPods](http://cocoapods.org) was nearly complete on all the popular and semi-popular open source libraries out there. I decided to give it a shot, and it turned out to be mostly a boon to development. I ran into a few snags when I was doing my first archive builds, but I'm of the persuasion now that every iOS project should budget at least a full day to dealing with Xcode quirks.

### ReactiveCocoa

I first learned about [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) (RAC) almost a year ago (Maybe March of 2012?) and was immediately interested and immediately confused. ReactiveCocoa is an Objective-C framework for Functional Reactive Programming. I spent a lot of time trying to understand the example projects and following development for the next few months. On a (yet to be released as of this writing) project before this one, I was comfortable enough with a few design patterns to use RAC in selected places throughout that app. Another one of my goals for this app was to try to use RAC wherever I could (and it made sense).

Luckily, RAC hit 1.0 right before I started the project and a substantial amount of [documentation](https://github.com/ReactiveCocoa/ReactiveCocoa/tree/master/Documentation) was added. For a good, brief overview of the library, I also recommend the [NSHipster](http://nshipster.com/reactivecocoa) writeup.

I'll be explaining my RAC code in some detail later in this post. I want to preface it by saying that I am still very much an RAC newbie and still getting a feel for its patterns, limitations, quirks, etc. Keep that in mind when reading through the code.

### Other Libraries

I tried to keep the dependencies lower than normal on this project. I did, however, use a few staples.

* [AFNetworking](https://github.com/AFNetworking/AFNetworking) - the defacto iOS/OS X networking library.
* [SDURLCache](https://github.com/rs/SDURLCache) - didn't add this until very close to shipping. I wrestled with NSURLCache during several non-adjacent coding sessions, and eventually decided to replace it with SDURLCache.
* [ViewUtils](https://github.com/nicklockwood/ViewUtils) - there's a bunch of UIView categories out there. I do a lot of manual view layout, so this library was invaluable.
* [DrawRectBlock](https://github.com/hsjunnesson/UIViewDrawRectBlock) - I don't like cluttering my file list with single-use view classes, so having access to drawRect when creating a new UIView is often helpful. (Especially with different colored top & bottom borders).
* [TestFlightSDK](https://testflightapp.com) - getting feedback from beta testers has improved my apps and workflow a lot. TestFlight is definitely doing some great work for the iOS community.
* [Crashlytics](http://crashlytics.com) & [Flurry](http://flurry.com) - I spent an entire day before App Store submission trying to figure out the best way to do analytics and crash reports (and how all the libraries fit together). The jury is still out on this, but I have to note that the people at  Crashlytics were super helpful and responsive in getting me set up.

### TCSLastFMAPIClient

We're going to start development from the back end (data) and move towards the front (views).

There are some older Last.fm Objective-C clients on GitHub, but it made sense to write my own since I was only using a few of the API endpoints and I wanted to use RAC as much as possible.

#### Interface

I followed the GitHub client RAC example as a template for my client. The initial interface looked like this:

{% codeblock (TCSLastFMAPIClient.h) lang:objc %}
	#import "AFHTTPClient.h"
	
	@class RACSignal;
	@class WeeklyChart;
	@class WeeklyAlbumChart;
	
	@interface TCSLastFMAPIClient : AFHTTPClient
	
	@property (nonatomic, readonly, copy) NSString *userName;
	
	+ (TCSLastFMAPIClient *)clientForUserName:(NSString *)userName;
	
	// returns a single NSArray of WeeklyChart objects
	- (RACSignal *)fetchWeeklyChartList;
	
	// returns a single NSArray of WeeklyAlbumChart objects
	- (RACSignal *)fetchWeeklyAlbumChartForChart:(WeeklyChart *)chart;
	
	@end
{% endcodeblock %}

A few things to notice:

* We're subclassing [AFHTTPClient](http://afnetworking.github.com/AFNetworking/Classes/AFHTTPClient.html).
* A client instance is specific to a last.fm user.
* We can request data from two API endpoints as discussed in the planning section.
* The `fetchWeeklyChartList` method only requires a username.
* the `fetchWeeklyAlbumChartForChart:` method requires a username and a WeeklyChart object returned by the former method. A WeeklyChart object simply holds an NSDate for `from` and `to`.

I want to focus on the `RACSignal` return types. I say in the comments that the methods "return an NSArray…" when what I mean is that they immediately return an `RACSignal`. Subscribing to that signal will (usually) result in an `NSArray` being sent to the subscriber in the `sendNext` method.

It's probably not immediately clear why I wouldn't just return the `NSArray`, but bear with me.

#### enqueueRequest

Feel free to read the [full implementation](https://github.com/twocentstudios/vinylogue/blob/master/vinylogue/TCSLastFMAPIClient.m), but I'm going to focus on a few methods in particular to explain the RAC parts. I'll explain this one inline with comments.

{% codeblock (TCSLastFMAPIClient.m) lang:objc %}
	// This is our request assembler/responder. 
	// It sits closest to the network stack in the code we'll write.
	- (RACSignal *)enqueueRequestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
	
		// An RACSubject is an RACSignal subclass that can 
		// be manually controlled. It's used to bridge the 
		// block callback structure of the AFHTTPRequestOperation to RAC.
		RACReplaySubject *subject = [RACReplaySubject subject];
		
		NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
	  	// Network caching is such a fickle thing in iOS that I don't really rely on this to do anything
	  	request.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	  
	  	// We assemble our operation callbacks here
		AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
		
		  // Last.fm returns error codes in the JSON data,
		  // so it makes sense to handle that on this level.
		  // Our endpoint methods should only care about good responses.
		  NSNumber *errorCode = [responseObject objectForKey:@"error"];
		  if (errorCode){
		  	// Make a new error object with the message we get
		  	// from the JSON data.
		    NSError *error = [NSError errorWithDomain:@"com.twocentstudios.vinylogue" code:[errorCode integerValue] userInfo:@{ NSLocalizedDescriptionKey: [responseObject objectForKey:@"message"] }];
		    
		    // Subscribers will "subscribeError:" to this signal
		    // to receive and handle the error. It also completes the request
		    // (subscribeComplete: won't be called).
		    [subject sendError:error];
		  }else{
		  	// If last.fm doesn't give us an error, go ahead and send
		  	// the response object along to the subscriber.
		    [subject sendNext:responseObject];
		    
		    // There's not going to be any more data, so this
		    // RACSignal is complete.
		    [subject sendCompleted];
		  }
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			// A network error is handled similarly to a Last.fm error.
			[subject sendError:error];
		}];
	  
		[self enqueueHTTPRequestOperation:operation];
	  	
	  	// RAC can be used for threading.
	  	// In this case, we want our "sendNext:" calls to be
	  	// processed by the API endpoint functions on a 
	  	// background thread. That way, the UI doesn't hang
	  	// while we're moving data from JSON -> new objects.
		return [subject deliverOn:[RACScheduler scheduler]];
	}
{% endcodeblock %}

So that's our first taste of RAC in action. RACSubjects are a little different than vanilla RACSignals, but again, they're very useful in bridging standard Foundation to RAC.

#### fetchWeeklyChartList

We're now at the point where an endpoint function can specify a URL and HTTP method and get a response object to process. I'm only going to explain one of the API endpoint functions (the simplest one), but the other ones should be very similar.

{% codeblock (TCSLastFMAPIClient.m) lang:objc %}
	// A public API endpoint function exposed in our interface
	- (RACSignal *)fetchWeeklyChartList{
		
	  // First, assemble a parameters dictionary to give to our enqueue method.
	  NSDictionary *params = @{@"method": @"user.getweeklychartlist",
	                           @"user": self.userName,
	                           @"api_key": kTCSLastFMAPIKeyString,
	                           @"format": @"json"};
	                           
	  // This is one big method chain we're returning.
	  // The first step is to get the proper request signal
	  // from the enqueue method.
	  return [[[self enqueueRequestWithMethod:@"GET" path:@"" parameters:params]
	  			
	  			// Then we hijack the signal's response and run it 
	  			// through some processing first.
	  			//
	  			// The "map:" blocks below are called with any
	  			// objects sent through the signal's "sendNext" call.
	  			// In this example, that object happens to be the
	  			// responseObject, which is an NSDictionary created
	  			// from a JSON file received from Last.fm.
	  			// 
	  			// The first processing we'll do is 
	  			// pull the object array from its shell.
	  			// I'm using an NSDictionary category to define a 
	  			// "arrayForKey" method that always returns an array,
	  			// even if there's only one object present in the
	  			// original dictionary.
	           map:^id(NSDictionary *responseObject) {
	             return [[responseObject objectForKey:@"weeklychartlist"] arrayForKey:@"chart"];
	             
	           // Next, we're going to iterate through the array
	           // and replace dictionaries with WeeklyChart objects.
	           // We use the "rac_sequence" method to turn an array
	           // into an RACSequence, then use the map function to
	           // do the replacement. Finally, we request a standard 
	           // array object from the RACSequence object.
	           }] map:^id(NSArray *chartList) {
	             return [[chartList.rac_sequence map:^id(NSDictionary *chartDictionary) {
	               WeeklyChart *chart = [[WeeklyChart alloc] init];
	               chart.from = [NSDate dateWithTimeIntervalSince1970:[[chartDictionary objectForKey:@"from"] doubleValue]];
	               chart.to = [NSDate dateWithTimeIntervalSince1970:[[chartDictionary objectForKey:@"to"] doubleValue]];
	               return chart;
	             }] array];
	           }];
	  
	}

{% endcodeblock %}

So it might look a little hairy, but it's essentially just a few processing steps chained together and all in once place.

We introduced the `RACSequence` at the end there to iterate through the array. There are more standard `NSArray` ways to do this, but `RACSequence`s are a subclass of `RACStream`s, which have a bunch of cool operators like `map`, `flatten`, `filter`, etc.

The main point to get out of this is that our API endpoint method defines several processing steps for a stream, then hands the stream off to its assumed subscriber. At the point the API endpoint method is called, none of this work will actually be done. It's not until the subscriber has called `subscribeNext` on the returned signal that the network request and subsequent processing be done. The subscriber doesn't even have to know that the original signal's `next` values are being modified.

That about does it for the API client. To summarize, the data flow is as follows:

* The client object's owner (we'll assume it's a controller) requests a signal from a public API endpoint method like `fetchWeeklyChartList`.
* The API endpoint method asks the `enqueue` method for a new signal for a specific network request.
* The `enqueue` method creates a new manually controlled signal, sets up the signal so that it will send responses when the network call completes, and then passes the signal to the API endpoint method.
* The API endpoint method sets up a list of processing steps that must be done with responses that are known to be good.
* The API endpoint passes the signal back to the controller.

At this point the signal is completely set up. It knows exactly where and how to get its data, and how to process the data once it has been received. But it is lazy and will only do so once the controller subscribes to it.

We haven't shown the act of subscribing yet, and we'll do that in the next section.

### TCSWeeklyAlbumChartViewController

Our primary view controller is called `TCSWeeklyAlbumChartViewController`. Its function is to request the weekly album charts for a particular user and display them in a table view. It also facilitates moving forward and backward in time to view charts from other years.

It was originally imagined that this would be, for lack of a better term, the root controller of the app. In its original implementation, it had many more responsibilities and had to be more mutable. During the coding process, the app architecture changed, allowing me to assume that the controller would have an immutable user, and simplifying things a bit.

#### Public Interface

The interface for this controller is pretty simple. Just one designated initializer.

{% codeblock (TCSWeeklyAlbumChartViewController.h) lang:objc %}
	@interface TCSWeeklyAlbumChartViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
	
	- (id)initWithUserName:(NSString *)userName playCountFilter:(NSUInteger)playCountFilter;
	
	@end
{% endcodeblock %}

Our controller needs to know which user it should display data for. It also needs to know which albums will be filtered based on play count. This controller will also handle all delegate and datasource duties from within. As a side note, I sometimes separate table datasources and delegates out to be their own classes. For this particular controller, things haven't gotten so complex that I've needed to refactor them out.

#### Private Interface

It's good OO practice to keep your class variables private by default, and that's what we'll do by defining our private interface in the source file. I'll go through all the class variables we've defined. 

##### Views

Let's start with the views.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	@interface TCSWeeklyAlbumChartViewController ()
	
	// Views
	@property (nonatomic, strong) TCSSlideSelectView *slideSelectView;
	@property (nonatomic, strong) UITableView *tableView;
	@property (nonatomic, strong) UIView *emptyView;
	@property (nonatomic, strong) UIView *errorView;
	@property (nonatomic, strong) UIImageView *loadingImageView;
	
	...
	
	@end
{% endcodeblock %}

The slideSelectView is the special view we use to move to past and future years. It sits on above the tableView and does not scroll.

The tableView displays an album and play count in each row.

The emptyView, errorView, and loadingImageView are used to show state to the user. The empty and error views are added and removed as subviews of the main view when necessary. The loadingImageView is a animated spinning record that is added as a custom view of the right bar button item.

##### Data

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	@interface TCSWeeklyAlbumChartViewController ()

	...
	
	// Datasources
	@property (atomic, copy) NSString *userName;
	@property (nonatomic) NSUInteger playCountFilter;
	@property (atomic, strong) TCSLastFMAPIClient *lastFMClient;
	
	@property (atomic, strong) NSArray *weeklyCharts; // list of to:from: dates we can request charts for
	@property (atomic, strong) NSArray *rawAlbumChartsForWeek; // unfiltered charts
	@property (atomic, strong) NSArray *albumChartsForWeek; // filtered charts to display
	
	@property (atomic, strong) NSCalendar *calendar; // convenience reference
	@property (atomic, strong) NSDate *now;
	@property (atomic, strong) NSDate *displayingDate;
	@property (atomic) NSUInteger displayingYearsAgo;
	@property (atomic, strong) WeeklyChart *displayingWeeklyChart;
	@property (atomic, strong) NSDate *earliestScrobbleDate;
	@property (atomic, strong) NSDate *latestScrobbleDate;
	
	...
	
	@end
{% endcodeblock %}
	
From a general overview, we're storing all the data we need to display, including some intermediate states. Why keep the intermediate state? We'll respond to changes in those intermediates and make the chain of events more malleable. Some variables will be observed by views. Some variables will be observed by RAC processing code to produce new values for other variables. As you'll see in a moment, we can completely separate our view and data code by using intermediate state variables instead of relying on linear processes.

I'll reprint our data flow from the planning section above adding some detail and variable names. Variables related to the step are in [brackets].

* take the current date [`now`]
* subtract `n` years (1 year ago to start) [`displayingDate` & `displayingYearsAgo` along with a convenience reference to the Gregorian `calendar`]
* figure out where that date is within the bounds of the Last.fm weeks [`weeklyCharts` & `displayingWeeklyChart`]
* request the charts for the username and date range [`rawAlbumChartsForWeek`]
* filter the charts based on play count and display the data [`albumChartsForWeek`]
* We also need to calculate the date bounds we can show charts for [`earliestScrobbleDate` & `latestScrobbleDate`]

We store a lastFMClient instance to call on as our source of external data.

##### Controller state

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	@interface TCSWeeklyAlbumChartViewController ()

	...
	
	// Controller state
	@property (atomic) BOOL canMoveForwardOneYear;
	@property (atomic) BOOL canMoveBackOneYear;
	@property (atomic) BOOL showingError;
	@property (atomic) NSString *showingErrorMessage;
	@property (atomic) BOOL showingEmpty;
	@property (atomic) BOOL showingLoading;
	
	@end
{% endcodeblock %}
	
We have some additional controller state variables set up. I have to admit that I'm not sure my implementation of empty/error views is the best. There was plenty of experimentation, and I ran into some trouble with threading. It works, but will eventually require a refactor.

canMoveForward/BackOneYear depend on which year the user is currently viewing as well as the earliest/latestScrobbleDate. The slideSelectView knows what it should allow based on these bools. Any of our data processes can decide they want to show an error, empty, or loading state. Other RAC processes observe these variables and show the appropriate views. (Again, this took some tweaking and is a little fragile.)

#### loadView

I'll annotate loadView inline:

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	- (void)loadView{
		// Create a blank root view
		self.view = [[UIView alloc] init];
		self.view.autoresizesSubviews = YES;
		
		// Begin creating the view hierarchy
		[self.view addSubview:self.slideSelectView];
		self.tableView.delegate = self;
		self.tableView.dataSource = self;
		[self.view addSubview:self.tableView];
		
		// loading view is shown as bar button item
		UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:self.loadingImageView];
		self.loadingImageView.hidden = YES;
		self.navigationItem.rightBarButtonItem = loadingItem;
		
		// double tap on the slide view to hide the nav bar and status bar
		UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doDoubleTap:)];
		doubleTap.numberOfTapsRequired = 2;
		[self.slideSelectView.frontView addGestureRecognizer:doubleTap];
	}
{% endcodeblock %}
	
All view attributes are defined in the view getters section. I've taken up this habit to keep my controllers a bit more tidy. The views are created at the first `self.[viewname]` call in loadView.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	// This custom view does most of its own configuration
	- (TCSSlideSelectView *)slideSelectView{
	  if (!_slideSelectView){
	    _slideSelectView = [[TCSSlideSelectView alloc] init];
	  }
	  return _slideSelectView;
	}
	
	// The tableview is also pretty vanilla. I'm using a custom
	// inner shadow view (although it's still not quite perfect).
	- (UITableView *)tableView{
	  if (!_tableView){
	    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
	    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	    _tableView.backgroundView = [[TCSInnerShadowView alloc] initWithColor:WHITE_SUBTLE shadowColor:GRAYCOLOR(210) shadowRadius:3.0f];
	  }
	  return _tableView;
	}
	
	// Spinning record animation. It uses 12 images in a standard UIImageView.
	- (UIImageView *)loadingImageView{
	  if (!_loadingImageView){
	    _loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
	    NSMutableArray *animationImages = [NSMutableArray arrayWithCapacity:12];
	    for (int i = 1; i < 13; i++){
	      [animationImages addObject:[UIImage imageNamed:[NSString stringWithFormat:@"loading%02i", i]]];
	    }
	    [_loadingImageView setAnimationImages:animationImages];
	    _loadingImageView.animationDuration = 0.5f; // trial and error
	    _loadingImageView.animationRepeatCount = 0; // repeat forever
	  }
	  return _loadingImageView;
	}
{% endcodeblock %}
	
#### viewDidLoad & RAC setup

Now for the fun stuff. The majority of the controller's functionality is set up in viewDidLoad within two helper methods, setUpViewSignals and setUpDataSignals.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	- (void)viewDidLoad{
	  [super viewDidLoad];
	  
	  [self setUpViewSignals];
	  [self setUpDataSignals];
	  
	  // these assignments trigger the controller to begin its actions
	  self.now = [NSDate date];
	  self.displayingYearsAgo = 1;
	}
{% endcodeblock %}

I'm going to start with the view signals to stress that as long as we know the exact meaning of our state variables, we can set up our views to react to them without knowing when or where they will be changed.

But before we can read through the code, we'll need a quick primer on some more bread-and-butter RAC methods.

##### @weakify & @strongify

Because RAC is heavily block-based, we can use the `EXTScope` preprocessor definitions within the companion `libextobjc` library to save our sanity when passing variables into blocks. Simply throw a `@weakify(my_variable)` before your RAC blocks to avoid the retain cycles, and then `@strongify(my_variable)` within each block to ensure the variable is not released during the block's execution. See the definitions [here](https://github.com/jspahrsummers/libextobjc/blob/master/extobjc/EXTScope.h).

##### RACAble(…) & RACAbleWithStart(…)

RACAble is simply magic [Key Value Observing](https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html). From the documentation:

> [RACAble] returns a signal which sends a value every time the value at the given path changes, and sends completed if self is deallocated.

This will be the backbone of our RAC code and is probably the easiest place to get started with RAC. It's easy to pepper these signals into existing code bases without having to rewrite from scratch. Or just use a few in a project to get started.

##### setUpViewSignals

Let's dive right into our first view signal to get a feel for it. I've separated it out into several expressions in order to simplify the explanation. In the actual source, it's a single expression.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	// Subscribing to all the signals that deal with views and UI
	- (void)setUpViewSignals{
	  @weakify(self);
	  
	  // SlideSelectView: Top Label
	  // Depends on: userName
	  RACSignal *userNameSignal = RACAbleWithStart(self.userName);
	  
	  // View changes must happen on the main thread
	  [userNameSignal deliverOn:[RACScheduler mainThreadScheduler]];
	  
	  // Change views based on the value of userName
	  [userNameSignal subscribeNext:^(NSString *userName) {
	    @strongify(self);
	    if (userName){
	      self.slideSelectView.topLabel.text = [NSString stringWithFormat:@"%@", userName];
	      self.showingError = NO;
	    }else{
	      self.slideSelectView.topLabel.text = @"No last.fm user";
	      self.showingErrorMessage = @"No last.fm user!";
	      self.showingError = YES;
	    }
	    [self.slideSelectView setNeedsLayout];
	  }]; 
	  
	  …
	
	}
{% endcodeblock %}

Let's deconstruct this. `RACAbleWithStart(self.userName)` creates an `RACSignal`. Again, an `RACSignal` can send `next` (with a value) and `error` or `complete` messages to its subscribers.

The `WithStart` part sends the current value of `self.userName` when it subscribed to. Without this, the block in `subscribeNext` would not be executed until `self.userName` changes for the first time after this subscription is created. In our case, because `self.userName` is only set once in the controller's `init` method (before the signal is created), it would never be called with a normal `RACAble`.

(At this point you may be wondering, "Why even observe the userName property if it's guaranteed to never change within the controller?" That's a good question. It's partly vestigial from when the value could change. It would very much be possible to transplant the code from within the `subscribeNext` block to `viewDidLoad`, but as you'll see it fits pretty well with the rest of the more dynamic view code.)

The next statement, `deliverOn:`, ~~modifies~~ transforms the signal into a new RACSignal on the specified thread to ensure `next` values are delivered on the main thread. This is a necessary because UIKit requires user interface changes to be done on the [main thread](http://developer.apple.com/library/ios/#documentation/uikit/reference/UIKit_Framework/Introduction/Introduction.html#//apple_ref/doc/uid/TP40006955-CH1-SW1). Like all other signal transformations, it only takes effect if the result is used.

`subscribeNext` is where our reaction code goes. Basically saying, "When the value of `self.userName` changes, execute the following block with the new value." In this example, we're going to change a label to show the userName. If it's `nil`, we'll throw up the error view.

I could have also used another variation of the `subscribeNext` method like `subscribeNext:complete:` to also add a block to execute when the signal completes. We don't really need to do anything on completion, so we'll just add a block for `next:`.

Instead of the `if/else`, we could have used two separate subscriptions that first `filter` for `nil` or empty userName. To keep it simple though, we'll just mix in the iterative style for now.

Alright, so one signal down. Let's look at another common pattern: combining multiple signals.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	- (void)setUpViewSignals{
	    @weakify(self);
	
	    …
	    
		// SlideSelectView: Bottom Label, Left Label, Right Label
		// Depend on: displayingDate, earliestScrobbleDate, latestScrobbleDate
		RACSignal *combinedSignal = [RACSignal combineLatest:@[ RACAbleWithStart(self.displayingDate), RACAbleWithStart(self.earliestScrobbleDate), RACAbleWithStart(self.latestScrobbleDate)] ];
		
		// Do it on the main thread
		[combinedSignal deliverOn:[RACScheduler mainThreadScheduler]];
		
		// Actions to perform when changing any of the three signals
		[combinedSignal subscribeNext:^(RACTuple *dates) {
		     NSDate *displayingDate = dates.first;
		     NSDate *earliestScrobbleDate = dates.second;
		     NSDate *latestScrobbleDate = dates.third;
		    @strongify(self);
		    if (displayingDate){
		      // Set the displaying date label
		      
		      // Calculate and set canMoveBackOneYear and canMoveForwardOneYear
		      
		      // Only show the left and right labels/arrows 
		      // if there's data there to jump to.
		      
		    }else{
		      // There's no displaying date, so set all labels to nil
		    }
		    
		 }];
		  
		…
		
	}
{% endcodeblock %}

I've separated out the expressions again, and I've replaced a bunch of tedious date calculation code and view updating code with comments in order to focus on what's happening with RAC. You can see everything in the source.

The slideSelectView has a couple components that depend on `displayingDate`, `earliestScrobbleDate`, and `latestScrobbleDate`. I want to update this view when any of these values change. Luckily, there's an RACSignal constructor for this.

`[RACSignal combineLatest:]` allows you to combine several signals into one signal. The new signal sends a `next:` message any time one of its component signals sends `next:`. There are a few variations of `combineLatest:` but the one we'll use in this example will combine all the latest `next:` values of our three component signals into a single [RACTuple](https://github.com/ReactiveCocoa/ReactiveCocoa/blob/master/ReactiveCocoaFramework/ReactiveCocoa/RACTuple.h) object. If you haven't heard of a tuple before, you can think of it like an array for now.

`combineLatest` takes an array of signals, which we'll generate on-the-fly with `RACAbleWithStart`.

When we subscribe, we expect a single `RACTuple` object to be delivered with the latest values of our component signals in the order we placed them in the original array. We can use the `RACTuple` helper methods `.first`, `.second`, etc. to break out the values we need.

Within the block, we calculate some booleans and set some labels. This could be broken up into multiple methods, but in this case, it made the most sense to do these calculations and assignments in the same place because they depend on the same set of signals.

Let's do one more view-related signal to show how primitive values are handled.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	- (void)setUpViewSignals{
	    @weakify(self);
	
	    …
	    
		// Show or hide the loading view
		[[[RACAble(self.showingLoading) distinctUntilChanged] 
		 deliverOn:[RACScheduler mainThreadScheduler]]
		 subscribeNext:^(NSNumber *showingLoading) {
		  @strongify(self);
		  BOOL isShowingLoading = [showingLoading boolValue];
		  if (isShowingLoading){
		    [self.loadingImageView startAnimating];
		    self.loadingImageView.hidden = NO;
		  }else{
		    [self.loadingImageView stopAnimating];
		    self.loadingImageView.hidden = YES;
		  }
		}];
		
		…
		
	}
{% endcodeblock %}

Here we're observing the `showingLoading` state variable. This variable will presumably be set by the data subscribers when they're about to do something with the network or process data.

This time I left the signal creation, modification, and subscription all in one call.

`RACAble(self.showingLoading)` creates the signal. `distinctUntilChanged` modifies the signal to only send a `next:` value to subscribers when that value is different from the last one. For example, let's assume `showingLoading` is `YES`. If somewhere in our controller, a method sets `showingLoading` to `NO`, then it is also set to `NO` later, the `subscribeNext:` block will only be executed on the first change from `YES` to `NO`.

We've seen `deliverOn:` a few times now. No surprises there.

Now for the subscription. You can see that the `next:` value is delivered as an `NSNumber` object even though `self.showingLoading` is a primitive `BOOL`. RAC will wrap primitives and structs in objects for us. So before we compare against the value, I'll use `[showingLoading boolValue]` to get the primitive back.

You can check out the rest of the view signals and subscriptions in the source.

##### setUpDataSignals

We'll introduce a couple new RAC concepts in this method. But first, here's an ugly ascii variable dependency graph. We'll use this to set up our signals.

		userName			now			displayingYearsAgo
			|				 \				/
		lastFMClient		  displayingDate
			|				 		/
		weeklyCharts		 	  /
			\				    /
			displayingWeeklyChart
					|
			rawAlbumChartsForWeek
					|
			albumChartsForWeek
					|
			[tableView reloadData]

When any of these variables change, they trigger a change upstream (downstream?) to the variables that depend on them.

For example, if the user changes `displayingDate` (moving to a past year), a change will be triggered in `displayingWeeklyChart`, which will trigger a change in `rawAlbumChartsForWeek` and so on. If our data was more time sensitive (by-the-minute instead of by-the-week), we could set up a signal for `now` that would trigger a change down the line every minute. Or if we decided to reuse our controller with different users, a `userName` change would trigger a change down the line.

We'll start with the userName observer.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	// All the signals that deal with acquiring and reacting to data changes
	- (void)setUpDataSignals{
	
	  @weakify(self);
	
	  // Setting the username triggers loading of the lastFMClient
	  [[RACAbleWithStart(self.userName) filter:^BOOL(id x) {
	    return (x != nil);
	  }] subscribeNext:^(NSString *userName) {
	    NSLog(@"Loading client for %@...", userName);
	    @strongify(self);
	    self.lastFMClient = [TCSLastFMAPIClient clientForUserName:userName];
	  }];
	  
	  …
	  
	}
{% endcodeblock %}

We've seen the `RACAbleWithStart` pattern. We're going to use `filter:` to act only on non-nil values of `userName`. Filter takes a block with an argument of the same type as is sent in `next:`. In this case, we don't need to cast it directly, we just know it shouldn't be nil. `filter`'s block returns a `BOOL` that indicates whether it should pass the `next` value to subscribers. Returning `YES` passes the value. Returning `NO` blocks it and the `subscribeNext` block will never see it. `filter` is a operation defined by `RACStream` like `map` which we saw earlier.

Next is another RAC pattern. You can automatically assign a property to the latest `next` value sent by a signal by using `RAC(my_property) = my_signal`. There are actually a couple other ways to accomplish this too. Here's an example from Vinylogue.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	- (void)setUpDataSignals{
	
	  @weakify(self);
	
	  …
	  
	  // Update the date being displayed based on the current date/time and how many years ago we want to go back
	  RAC(self.displayingDate) = [[[[RACSignal combineLatest:@[ RACAble(self.now), RACAble(self.displayingYearsAgo) ]]
		deliverOn:[RACScheduler scheduler]]
		map:^(RACTuple *t){
		  NSDate *now = t.first;
		  NSNumber *displayingYearsAgo = t.second;
		  NSLog(@"Calculating time range for %@ year(s) ago...", displayingYearsAgo);
		  NSDateComponents *components = [[NSDateComponents alloc] init];
		  components.year = -1*[displayingYearsAgo integerValue];
		  return [self.calendar dateByAddingComponents:components toDate:now options:0];
		}] filter:^BOOL(id x) {
		  NSLog(@"Time range calculated");
		  return (x != nil);
		}];
	  
	  …
	  
	}
{% endcodeblock %}

This one is a little tricky so let's step through it. First thing we're doing is setting up the `RAC(property)` assignment. `self.displayingDate` will be assigned to whatever `next` value comes out of our complicated signal on the other side of the equals sign.

We're creating a signal that combines our `self.now` and `self.displayingYearsAgo` signalified properties. Remember, they're not just regular properties. We've made them into signals by wrapping them with `RACAble`, and they send their values each time they're changed.

We're injecting a `deliverOn` with the default background scheduler `[RACScheduler scheduler]` before doing any work on the next values to make sure the work will be done off the main thread (ensuring a snappy UI).

Edit: Doing this on a background thread is probably overkill and most likely not the best idea since we're now changing controller properties off the main thread.

Remember that `combineLatest` creates an `RACTuple` with the `next` values of each signal it wraps. We break that tuple out into an `NSDate` and an `NSNumber` and use those to calculate a date in the past. Remember that `map` just modifies `next` values. It has to return a value to pass to subscribers. It doesn't have to be the same type; our input is an `RACTuple` and our output is an `NSDate` in this case.

Our last operation is a filter for nil. It's useless to assign nil to our displayingDate. If this returns `YES`, then our `next` date returned from `map` will automatically be assigned to `self.displayingDate`.

We'll do one expression in order to show how we use the Last.fm client functions we wrote earlier.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	- (void)setUpDataSignals{
	
	  @weakify(self);
	
	  …
	  
	 // When the weeklychart changes (being loaded the first time, 
	 // or the display date changed), fetch the list of albums for that time period.
	 [[[RACAble(self.displayingWeeklyChart) filter:^BOOL(id x) {
	   return (x != nil);
	 }] deliverOn:[RACScheduler scheduler]]
	  subscribeNext:^(WeeklyChart *displayingWeeklyChart) {
	    NSLog(@"Loading album charts for the selected week...");
	    @strongify(self);
	    [[[self.lastFMClient fetchWeeklyAlbumChartForChart:displayingWeeklyChart]
	      deliverOn:[RACScheduler scheduler]]
	     subscribeNext:^(NSArray *albumChartsForWeek) {
	       NSLog(@"Copying raw weekly charts...");
	       @strongify(self);
	       self.rawAlbumChartsForWeek = albumChartsForWeek;
	     } error:^(NSError *error) {
	       @strongify(self);
	       self.albumChartsForWeek = nil;
	       NSLog(@"There was an error fetching the weekly album charts!");
	       self.showingErrorMessage = error.localizedDescription;
	       self.showingError = YES;
	     }];
	  }];
	  
	  …
  
	}
{% endcodeblock %}

Once we have a specific time period to request charts for, we'll get a signal from the client by supplying the displayingWeeklyChart. We have a signal within a signal in this block. As soon as we `subscribeNext` to the signal that was returned from the client, it will request data from the network and do the processing. 

We also subscribed with an error block this time so we can pass the error along to the user. By setting `showingError` and `showingErrorMessage`, the view signal subscriptions we created earlier are triggered. Remember that in this subscription, we're still on a background thread. Changing these properties on a background thread will still trigger the view updates on the main thread. Pretty cool.

The rest of our `setUpDataSignals` method uses similar tricks with RAC, observing properties as outlined in our simple ascii chart. Check out the source to decipher the rest.

You should be at the point now where you can start picking through the signal operations in [RACSignal+Operations.h](https://github.com/ReactiveCocoa/ReactiveCocoa/blob/master/ReactiveCocoaFramework/ReactiveCocoa/RACSignal%2BOperations.h). [RACStream.h](https://github.com/ReactiveCocoa/ReactiveCocoa/blob/master/ReactiveCocoaFramework/ReactiveCocoa/RACStream.h) also has some operations you should be aware of.

In the next section we'll also briefly cover `RACCommand`s.

### TCSSlideSelectView

The slideSelectView is the extra special control we dreamed up earlier in the wireframing section.

{% caption_img /images/vinylogue-slideselectview.jpg Reminder of slideSelectView %}

We should break it out so we know how we should code the view hierarchy.

{% caption_img /images/vinylogue-slideselectviewbreakout.jpg slideSelectView broken out %}

Let's implement it!

#### Interface

From our sketch, we can deconstruct the views we need.

{% codeblock (TCSSlideSelectView.h) lang:objc %}
	@interface TCSSlideSelectView : UIView <UIScrollViewDelegate>
	
	@property (nonatomic, readonly) UIView *backView;
	@property (nonatomic, readonly) UIButton *backLeftButton;
	@property (nonatomic, readonly) UIButton *backRightButton;
	@property (nonatomic, readonly) UILabel *backLeftLabel;
	@property (nonatomic, readonly) UILabel *backRightLabel;
	
	@property (nonatomic, readonly) UIScrollView *scrollView;
	
	@property (nonatomic, readonly) UIView *frontView;
	@property (nonatomic, readonly) UILabel *topLabel;
	@property (nonatomic, readonly) UILabel *bottomLabel;
	
	// Signals will be fired when the scroll view is dragged past the offset
	@property (nonatomic) CGFloat pullLeftOffset;
	@property (nonatomic) CGFloat pullRightOffset;
	
	@property (nonatomic, strong) RACCommand *pullLeftCommand;
	@property (nonatomic, strong) RACCommand *pullRightCommand;
	
	@end
{% endcodeblock %}

We'll decide up front that this view will be somewhere between a generic and concrete view. A good future exercise would be figuring out how to make this view generic enough to be used by other controllers and apps. We've made it sort of generic by exposing all the subviews as readonly, therefore allowing other objects to change view colors and other properties, but not allowing them to replace views with their own.

We'll actually redefine these view properties in the private interface in the implementation file.

Although our view will have defaults for the pull offsets and commands, we'll allow outside classes to change or replace them at will.

The pull offsets are values that answer the question, "How far do I have to pull the scroll view to the right or left before an action is triggered?" The commands are `RACSignal` subclasses that are designed to send `next` values triggered off of an action, usually from the UI. We'll use these constructs instead of the delegate pattern to pass messages from our custom view to the controller that owns it.

#### Implementation

Here's the private interface:

{% codeblock (TCSSlideSelectView.m) lang:objc %}
	@interface TCSSlideSelectView ()
	
	@property (nonatomic, strong) UIView *backView;
	// redefine the rest of the views as strong instead of readonly
	// ...
	
	@end
{% endcodeblock %}
	
We'll define the view hierarchy and create defaults in `init`.

{% codeblock (TCSSlideSelectView.m) lang:objc %}
	- (id)init{
	  self = [super initWithFrame:CGRectZero];
	  if (self) {
	    [self addSubview:self.backView];
	    
	    [self.backView addSubview:self.backLeftLabel];
	    [self.backView addSubview:self.backRightLabel];
	    
	    [self.backView addSubview:self.scrollView];
	    
	    // Buttons technically sit above (but not on) 
	    // the scrollview in order to intercept touches
	    [self.backView addSubview:self.backLeftButton];
	    [self.backView addSubview:self.backRightButton];
	    
	    [self.scrollView addSubview:self.frontView];
	    [self.frontView addSubview:self.topLabel];
	    [self.frontView addSubview:self.bottomLabel];
	    
	    // Set up commands
	    self.pullLeftOffset = 40;
	    self.pullRightOffset = 40;
	    self.pullLeftCommand = [RACCommand command];
	    self.pullRightCommand = [RACCommand command];
	  }
	  return self;
	}
{% endcodeblock %}
	
Logically, the buttons would be behind the scrollView, but I was having trouble getting taps to get forwarded from the invisible scrollview to the button below it (maybe I should have just made the scrollView narrower?). Instead, the buttons sit above the scrollview and disappear when scrolling begins.

We also define defaults for the pull offsets and set up generic `RACCommand`s.

I use `layoutSubviews` to resize the views and lay them out. This is mostly self explanatory and tedious to explain. Feel free to read the source to see how I do that.

We'll move on to the more interesting part: using `RACCommand`s to pass messages.

{% codeblock (TCSSlideSelectView.m) lang:objc %}
	# pragma mark - UIScrollViewDelegate
	
	- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
	  [self showBackButtons:NO];
	}
	
	- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
	  CGFloat offset = scrollView.contentOffset.x;
	  if (offset <= -self.pullLeftOffset){
	    [self.pullLeftCommand execute:nil];
	  }else if(offset >= self.pullRightOffset){
	    [self.pullRightCommand execute:nil];
	  }
	  [self showBackButtons:YES];
	}
{% endcodeblock %}
	
Like I just mentioned before, we'll hide the buttons when scrolling starts and show them again when scrolling ends.

When scrolling ends, we check the x offset of the scrollview. If it's past the offsets that were set earlier, we use the `execute` method of the `RACCommand`. An `RACCommand` is just a subclass of an `RACSignal` with a few behavior modifications. `execute:` sends its argument in a `next` message to subscribers. In our example, we don't need to send any particular object, just the message is enough. We could have alternatively only had one command object and sent the direction as the message object. That's a little confusing though.

This design pattern works for a few reasons. If the command has no subscribers, the message will be ignored, no harm done. So far though, it isn't really that much different than creating a protocol and holding a reference to a delegate. I'll show you the interesting part in a second.

Before we move back to the controller to show how we handle these messages, here's how we handle the buttons:

{% codeblock (TCSSlideSelectView.m) lang:objc %}
	# pragma mark - private
	
	- (void)doLeftButton:(UIButton *)button{
	  [self.pullLeftCommand execute:nil];
	}
	
	- (void)doRightButton:(UIButton *)button{
	  [self.pullRightCommand execute:nil];
	}
{% endcodeblock %}

The buttons trigger the same action as the scrollView.

Another way to interface `UIControl`s with RAC is to use the `RACSignalSupport` category:

{% codeblock (UIControl+RACSignalSupport.h) lang:objc %}
	@interface UIControl (RACSignalSupport)
	
	// Creates and returns a signal that sends the sender of the control event
	// whenever one of the control events is triggered.
	- (RACSignal *)rac_signalForControlEvents:(UIControlEvents)controlEvents;
	
	@end
{% endcodeblock %}

Let's quickly jump back to the `TCSWeeklyAlbumChartViewController` to show how we interface with this custom control.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	- (void)setUpDataSignals{

	  …
	  
	  // Change displayed year by sliding the slideSelectView left or right
	  self.slideSelectView.pullLeftCommand = [RACCommand commandWithCanExecuteSignal:RACAble(self.canMoveBackOneYear)];
	  [self.slideSelectView.pullLeftCommand subscribeNext:^(id x) {
	    @strongify(self);
	    self.displayingYearsAgo += 1;
	  }];
	  self.slideSelectView.pullRightCommand = [RACCommand commandWithCanExecuteSignal:RACAble(self.canMoveForwardOneYear)];
	  [self.slideSelectView.pullRightCommand subscribeNext:^(id x) {
	    @strongify(self);
	    self.displayingYearsAgo -= 1;
	  }];
	  
	  …
	  
	}
{% endcodeblock %}
	
We're creating signals (commands) and assigning them to the slideSelectView. The slideSelectView will own these signals, but before the controller hands them over, it will add a special "canExecuteSignal" and then subscription instructions for each.

The command will check the latest value of its canExecute signal (which should be a `BOOL`) to decide whether it should fire before executing its `next` block. In the example, we don't want to let the user move to the past unless there are weeks to show there. We create a signal from our `BOOL` property `canMoveBackOneYear` and assign it to the command. Our `canMove` properties will now govern the actions of the slideSelectView for us.

When these commands are allowed to fire, they'll update our `displayingYearsAgo` property, and the changes will propagate through our ascii dependency chart.

That's about it for the slideSelectView. Now that we have the skeleton of our app created, time to start thinking about the design.

## [Design](id:design)

Alright, so we've now done a fair amount of development. There's at least enough for a prototype using built in controls. Now it's time to get a feel for how everything is going to look.

This is approximately what our app looks like at this point:

{% caption_img /images/vinylogue-uglyprototype.png Ugly working prototype %}

_I am not a designer_. I usually work with my friend CJ from [Oltman Design](http://oltmandesign.com), but since this was a low-stakes, unpaid project with a tight-timeline, I decided to give it a shot myself.

Many shops will complete the wireframes, UX, and then do the Photoshop mockups before even involving the developers. Since I'm doing everything, I sometimes pivot back and forth between the two, using new ideas while doing each to iterate in both directions.

You can also see that from my ugly prototype screen shot that I like to multicolor my views initially to make sure everything is being laid out as expected.

### Photoshop

I took my ugly mockup and threw it into photoshop, then styled on top of it. I wanted to start with a more colorful mockup and used this [color picker](http://color.hailpixel.com) to pick out a bunch of colors I liked (again, _not a designer!_).

Here is my first mock up:

{% caption_img /images/vinylogue-firstmockup.png First mock up %}

I chose iOS6's new Avenir Next font in a few weights because it's pretty, a little more unique, but still very readable and not too opinionated.

As a non-designer, I simply asked myself what the relative order of importance for each element was, and adjusted its relative color and size accordingly. The artist name is not as important as the album name, therefore the artist name is smaller and has less contrast. The album cover is important, so it is nice and big and the first thing you see on the left side (also a standard iOS design pattern). I added padding to the album images so they wouldn't bump up against each other on the top and bottom, which sometimes looks weird. The number of plays is big and stands out, while the word "plays" can be inferred after seeing it the first time, and can therefore be downplayed heavily. I gave the cells a classic one-line top highlight and bottom shadow.

For my slide control, I wanted to give it depth to imply it being stacked. A darker color and inner shadow accomplished this (although I've found Photoshop-style inner shadows much harder to implement with Core Animation and Core Graphics). The user name is mostly understood and is only there as a reminder, so it can be downplayed. The week is important so it should stand out.

I was originally planning on this being the only controller, so I put the logo top and center. The logo is just our normal Avenir Next font with a little extra tracking (not a designer). It looks just hipstery enough I think.

### Code the cell design

Now that there's a map for our cell layout, let's implement it.

#### Interface

{% codeblock (TCSAlbumArtistPlayCountCell.h) lang:objc %}
	@interface TCSAlbumArtistPlayCountCell : UITableViewCell
	
	@property (nonatomic, strong) WeeklyAlbumChart *object;
	
	- (void)refreshImage;
	
	+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView;
	
	@end
{% endcodeblock %}

We'll keep a reference to the model object we're displaying. There's some debate about the best way to implement the model/view relationship. Sometimes I borrow the concept of a "decorator" object from Rails that owns the model object and transforms its values into something displayable. I decided to keep this app simple this time and have the cell assign its own view attributes directly from the model object. If we didn't have a one-to-one relationship between views and model objects, I would definitely reconsider this.

Ignore `refreshImage` for now. That tackles a problem we'll run into later.

`heightForObject` is our class object that does a height calculation for an object before an instance of the cell is actually allocated. Part of the UITableView protocols is knowing the height of a cell before it is actually laid out. I have yet to figure out a good way to do this without doubling up on some layout calculation code, but alas I've gotten used to writing it.

#### Implementation

Our private instance variables:

{% codeblock (TCSAlbumArtistPlayCountCell.m) lang:objc %}
	@interface TCSAlbumArtistPlayCountCell ()
	
	@property (nonatomic, strong) UILabel *playCountLabel;
	@property (nonatomic, strong) UILabel *playCountTitleLabel;
	@property (nonatomic, strong) UILabel *rankLabel;
	@property (nonatomic, strong) UIView *backView;
	
	@property (nonatomic, strong) NSString *imageURLCache;
	
	@end
{% endcodeblock %}
	
I'm reusing `UITableViewCell`'s `textLabel` and `detailTextLabel` for my artist and album labels, and reusing the `imageView` for the album image. Our cells aren't currently selectable, so the cell only has a normal background view and not a selected one.

I'll come back to that `imageURLCache` string in a moment.

{% codeblock (TCSAlbumArtistPlayCountCell.m) lang:objc %}
	@implementation TCSAlbumArtistPlayCountCell
	
	- (id)init{
	  self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSStringFromClass([self class])];
	  if (self) {
	    self.selectionStyle = UITableViewCellSelectionStyleNone;
	    
	    self.backgroundView = self.backView;
	        
	    [self configureTextLabel];
	    [self configureDetailTextLabel];
	    [self configureImageView];
	    [self.contentView addSubview:self.playCountLabel];
	    [self.contentView addSubview:self.playCountTitleLabel];
	    [self.contentView addSubview:self.rankLabel];
	    
	  }
	  return self;
	}
	
	… 
	
	@end
{% endcodeblock %}

I create and/or configure my views in custom getters at the bottom of my implementation file. Nothing too interesting here. Moving on…

{% codeblock (TCSAlbumArtistPlayCountCell.m) lang:objc %}
	- (void)setObject:(WeeklyAlbumChart *)object {
	  if (_object == object)
	    return;
	  
	  _object = object;
	  self.textLabel.text = [object.artistName uppercaseString];
	  self.detailTextLabel.text = object.albumName;
	  self.playCountLabel.text = [object.playcount stringValue];
	  self.rankLabel.text = [object.rank stringValue];
	  
	  [self refreshImage];
	
	  if (object.playcountValue == 1){
	    self.playCountTitleLabel.text = NSLocalizedString(@"play", nil);
	  }else{
	    self.playCountTitleLabel.text = NSLocalizedString(@"plays", nil);
	  }
	}
{% endcodeblock %}
	
Our custom object setter is in charge of properly assigning model object data to our views. The interesting problem we come across is the albumImage. Let's look at the `refreshImage` instance method:

{% codeblock (TCSAlbumArtistPlayCountCell.m) lang:objc %}
	- (void)refreshImage{
	  UIImage *placeHolderImage = [UIImage imageNamed:placeholderImage];
	  if (self.imageView.image == nil){
	    self.imageView.image = placeHolderImage;
	  }
	  
	  if(self.object.albumImageURL && ![self.object.albumImageURL isEqualToString:self.imageURLCache]){
	    // prevent setting imageView unnecessarily
	    [self.imageView setImageWithURL:[NSURL URLWithString:self.object.albumImageURL] placeholderImage:placeHolderImage];
	    self.imageURLCache = self.object.albumImageURL;
	  }
	}
{% endcodeblock %}

What do we know about the image at this point? When our WeeklyAlbumChart object is originally created, it does not have an album image URLl The Last.fm API does not return that data with the call we're using. If we want that image URL, we have to request it using a separate `album.getInfo` API call. And it may not even exist for a particular album.

But getting that URL isn't the cell's responsibility. We don't want to create or pass in a copy of the lastFMAPIClient to each cell. That seems like the controller/datasource's responsibility.

Why don't we just request all these image URLs when we originally receive the album chart list from the API client? We could, but if that list has 50+ albums in it, that's 51+ API calls we just made. And if the user only scrolls through a couple, it's a lot of wasted data. We should strive to do it more lazily. Only request the album image URL if the cell is actually being displayed. Luckily, we have a nice table view delegate method for that.

{% codeblock (TCSWeeklyAlbumChartViewController.m) lang:objc %}
	- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
	  // If the object doesn't have an album URL yet, request it from the server then refresh the cell
	  TCSAlbumArtistPlayCountCell *albumCell = (TCSAlbumArtistPlayCountCell *)cell;
	  WeeklyAlbumChart *albumChart = [self.albumChartsForWeek objectAtIndex:indexPath.row];
	  if (albumChart.albumImageURL == nil) {
	    [[[self.lastFMClient fetchImageURLForWeeklyAlbumChart:albumChart] deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSString *albumImageURL) {
	      [albumCell refreshImage];
	    }];
	  }
	}
{% endcodeblock %}
	
In the controller, if the model object does not have an albumImageURL we request it using a new API client method (that returns an `RACSignal` of course). We subscribe, so when it's done we can refresh the cell and load the new image using `AFNetworking`'s `UIImageView` category that loads images asynchronously from a URL.

While we're waiting for our response, the user could possibly have scrolled past the cell, and the cell could be reassigned a new object. No problems though, because `refreshImage` will just fall through without doing anything and the URL will be saved and loaded the next time the object is assigned to the cell.

The last thing we should do is clear out our `imageURLCache` in `prepareForReuse`, although technically everything will still work without doing so.

All of this work seems like exactly the thing that RAC would excel at. Unfortunately, I wrestled with several such implementations but could not get things to work out as I wanted. On my to-do list is to try again and see if something unrelated was the problem.

I was considering digging into the view layout calculations, but I think as was with the slideSelectView, explaining the layout code would be tedious and superfluous. Check it out in the source if you're interested.

### Photoshop part 2

We coded up our cell layout and did the same for the slideSelectView and took a step back to see how it looks on the iPhone.

{% caption_img /images/vinylogue-codedlayout.png Coded layouts %}

Everything seems to be in the right place. Let's go ahead and adjust fonts and colors, then tweak the layout to get things as close to our mock up as possible.

{% caption_img /images/vinylogue-codedlayoutfontscolors.png Set fonts and colors %}

Cool. Looking pretty close to what we had in photoshop. We haven't gotten the inner shadows of the slideSelectView yet though. And the sharp rectangle of the slideSelectView's top view doesn't look particularly draggable. Let's round off the corners. We'll also add a button for opening up the settings (user name and play count, along with about info).

{% caption_img /images/vinylogue-codedlayouttweaks.png Some tweaks %}

### Settings

Next we need to create a settings controller and a controller for setting the user name.

I'm not going to go in depth for this one. I used a generic static table view datasource class I threw together for another project. You basically give it a specially coded dictionary with titles and optional selectors, then tell it what cell classes to use for headers and cells.

I didn't do this one in photoshop first. Since it's only one line of text per line, I simply coded it up and experimented a little with the fonts and colors I already had chosen.

{% caption_img /images/vinylogue-codedsettings.png First settings controller %}

I kept this theme going with the username input controller. I heavily borrowed the styling of the awesome and beautiful app [EyeDrop.me](http://eyedrop.me).

{% caption_img /images/vinylogue-usernamecontroller.png User name edit controller %}

### Iteration

We now have a functional app! But now we can take a step back and really look at what's going on.

1. The color scheme of the root controller is too much. The colors of the album art should draw the most focus not the background of the table cells nor the play count.
2. The flow of the settings page kind of works, but it feels a little odd.
3. My original thought was that this would be a one-user app, but during testing, I realized that:
	* We don't need to input a user's password to view their charts.
	* During testing I was viewing my friends' charts and enjoying perusing them.
	* Why not just having a landing page controller where we can easily select charts for different users!?
	
It seems obvious in hindsight, but at the time it was anything but.

So let's address each of these points.

1. I'm kind of liking the settings page. It was sort of an accident, but it's minimalist, which is easier to pull off for someone with no sense of design. It's also the way design trends have been going lately. Let's aim for that on the root controller.
2. We can probably address this along with #3.
3. The root controller should be a list of users.
	* Selecting a user pushes their chart on the nav controller.
	* Settings can be viewed and changed from the root controller.
	
{% caption_img /images/vinylogue-wireframe2.jpg Re-imagined wireframed controller flow %}

Awesome! A little more complicated, but overall a much more functional app.

### Photoshop part 3

Luckily all the layout is still winning our favor. All we have to do is tweak fonts and colors.

{% caption_img /images/vinylogue-mockup2.png Photoshop comp 2 %}

That looks a lot cleaner. The slideSelectView looks a little weird, but we'll play around with those colors on the device/simulator.

### Design implementation part 2

{% caption_img /images/vinylogue-codedlayout2.png Redesign on the simulator %}

Yeah, much better.

Let's check out the new users controller.

{% caption_img /images/vinylogue-usernamecontroller2.png Users controller %}

Looks good. UIKit automatically adds those table header view bottom borders and I can't reliably get rid of them. Weird.

Because we've moved the primary user name out of settings, here's the settings controller one more time.

{% caption_img /images/vinylogue-settings2.png Settings controller with no user name %}

## [Back to development](id:development2)

Alright, we totally skipped the implementation of the users controller. Let's touch on that and see if RAC has anything to do with it.

### Data store

We have a new decision to make: how will we set/store users? We have a few options:

1. The user adds their friends' user names manually.
	* Pros: simplest, may be what most users want.
	* Cons: may be difficult for users to find/enter their friends' usernames.
2. Automatically sync friends with last.fm.
	* Pros: users also might find this easiest.
	* Cons: may be difficult to keep the user's personal ordering.
3. Manually sync friends with last.fm on user request.
	* Pros: probably a good compromise as a "first run" option or default.
	* Cons: users may get upset if they sync again and everything is overwritten.

We should probably start with option 1. Later we can add option 3 if the interest is there. Keep an ear open for option 2.

(Update: V1.1 has friend list importing, which solves these problems by only importing friends not already in the list).

The easiest way to implement option 1 is NSUserDefaults. We should probably wrap it in its own datastore class in order to abstract out the implementation details and make option 3 easier to add in the future.

Our new app start up sequence is the following pseudo code in our AppDelegate:

1. Pull the play count filter setting from NSUserDefaults.
2. Create a user data store class instance that will pull user data from NSUserDefaults.
3. Create a UsersController and pass in our userStore and playCountFilter.

Why not have each controller interact with NSUserDefaults as needed? I consider NSUserDefaults a store for global variables. Doing all global IO in one place (the AppDelegate) is better separation of concerns.

At the end of the day it's a judgement call, and with an app this size there's only so much anti-pattern spagettification you can even create. With larger apps, it's a better idea to keep your controllers as functional (in the functional programming sense) as possible.

### Moving data around

`TCSFavoriteUsersController` has a by-the-book table view delegate and datasource implementation. It includes adding, removing, and rearranging elements in one section only.

An instance of `TCSFavoriteUsersController` is a spring board for 3 other controllers.

* `TCSSettingsViewController` - users can change the value of playCountFilter.
* `TCSUserNameViewController` - used to add a new friend or edit an existing friend.
* `TCSWeeklyAlbumChartViewController` - used to display charts.

We need to keep a connection to the Settings & UserName controllers we create and display because we need to know when they change values. Normally this is accomplished through the delegate pattern. Our parent controller will get a message with the new data and dismiss its child. We're going to try a different pattern using RAC.

This example is for editing the userName of a friend by tapping the cell during edit mode (this used to be done by tapping the accessory button, but changed before release).

{% codeblock (TCSFavoriteUsersViewController.m) lang:objc %}
	- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	  [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
     // Get the user name for the row using a helper function.
     // We could get the whole User object, but in this case 
     // we only need the name.
	  NSString *userName = [self userNameForIndexPath:indexPath];
	
	  // Selecting the cell has different behavior depending on 
	  // whether or not the controller is in edit mode.
	  if (!self.editing){
	  
	    // In non-editing mode, just present a new chart controller.
	    TCSWeeklyAlbumChartViewController *albumChartController = [[TCSWeeklyAlbumChartViewController alloc] initWithUserName:userName playCountFilter:self.playCountFilter];
	    [self.navigationController pushViewController:albumChartController animated:YES];
	  }else{
	    
	    TCSUserNameViewController *userNameController = [[TCSUserNameViewController alloc] initWithUserName:userName headerShowing:NO];
	    @weakify(self);
	    
	    // The userNameController has a signal (analogous to a protocol) that
	    // sends the User object if it has changed.
	    // We subscribe to it in advance, and write our instructions for
	    // processing changes.
	    [[userNameController userSignal] subscribeNext:^(User *user){
	      @strongify(self);
	      
	      // Section 0 is for the primary user.
	      // Section 1 is for friends.
	      // Our userStore class takes care of the actual replacement 
	      // and persistence.
	      if (indexPath.section == 0){
	        [self.userStore setUser:user];
	      }else{
	        [self.userStore replaceFriendAtIndex:indexPath.row withFriend:user];
	      }
	    }completed:^{
	      // The signal completing tells us that we can remove the user name controller.
	      [self.navigationController popViewControllerAnimated:YES];
	    }];
	    
	    [self.navigationController pushViewController:userNameController animated:YES];
	  }
	}
{% endcodeblock %}

The child controller has a signal instead of a protocol method. We place what would be the protocol method's contents in the signal subscription block.

What do I gain by doing it with RAC? Not much in this particular implementation. I can keep the response behavior localized in the controller definition, and expand it to its own method if it happens in multiple places.  I also could have done some filtering on the sending or receiving side or sent an error signal.

To make this work on the `TCSUserNameController.m` side, I first created a public property for the `userSignal`. Then, I created a new `RACSubject` in the designated `init` method of the controller. Remember, an `RACSubject` is capable of sending next, complete, or error values whenever we want.

We'll use a done button or textField's return button as our confirm button.

{% codeblock (TCSUserNameViewController.m) lang:objc %}
	#pragma mark - private
	
	- (void)doDone:(id)sender{
	  self.loading = YES;
	  [[[self.lastFMClient fetchUserForUserName:self.userNameField.text]
	     deliverOn:[RACScheduler mainThreadScheduler]]
	   subscribeNext:^(User *user) {
	    [self.userSignal sendNext:user];
	    [self.userSignal sendCompleted];
	  } error:^(NSError *error) {
	    [[[UIAlertView alloc] initWithTitle:@"Vinylogue" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
	    self.loading = NO;
	  } completed:^{
	    self.loading = NO;
	  }];
	}
{% endcodeblock %}

I initially implemented this by simply returning whatever userName the user entered in the box without any checking. As an additional feature, I implemented a network call into this step that checks the userName with Last.fm before returning it. The side effect is that the name gets formatted as it was intended.

## [Release](id:end)

We're skipping a few steps at the end here (testing, analyzing, prepping for the App Store), but this post is long enough as it is.

### Improvements

There are a few things I'd like to take a look at in future versions.

#### More stable threading

I'm doing some strange things with threading, including setting controller properties on background threads. Most of the time it seems to work out, but I need to take a step back and map out the flow of property setting and events.

#### Better cell image handling

I covered how I handle cell images above, but my method has some code smell and could probably use another look.

#### Testing

At this point in time, I haven't explored unit testing or UI automation testing at all, and would like to give those a shot with this project.

### V1.1

While the app was processing in the App Store, I worked on several improvement to V1.1. I added friend importing to the Scrobblers controller. I also created an album detail controller which changes background color based on the album image.

I'll be waiting to hear back from users before implementing any other new features.

## Final thoughts

Congrats if you made it this far. Although I didn't exactly hit all my goals for this post, I didn't think it'd be nearly this long either. I hope this post will add to the discussion about ReactiveCocoa. Ping me on twitter [@twocentstudios](http://twocentstudios.com) if you have comments or questions. Or check out the Hacker News [thread](https://news.ycombinator.com/item?id=5488070).