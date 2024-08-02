---
layout: post
title: TTTabStrip Controlled Multi-table Lazy-loading TTTableViewController
tags:
- apple
- ios
- three20
status: publish
type: post
published: true
redirect_from: "/blog/2011/03/13/tttabstrip-controlled-multi-table-lazy-loading-tttableviewcontroller.html"
---

Using a single TTTableViewController and a TTTabStrip can sometimes be an appropriate way to avoid drilling down through two tableviews. I'm going to walk through how to do this with a YouTube viewer as an example.

<img class="aligncenter size-medium wp-image-38" title="TTTabStrip Example" src="/images/TTTabStrip-Example.png" alt="" width="200" height="300" />

Above is an example of the effect we're going for. I've used the Associated Press YouTube playlist feed for this example, and obviously the interface isn't finished yet. This tutorial will focus solely on how to pull and show multiple models and datasources in a single TTTableViewController. There won't be a full example project, and there also won't be any layout code. If you're still interested, read on!

<h2>Structure Overview</h2>

Our TTTableViewController has one TTTabStrip and one TTTableView. The TTTabStrip will load all playlists of a user and display each playlist title as a button. When the user taps a button, the TTTableView will load all the videos in the selected playlist as tableitems. This will be done lazily, meaning that when the controller loads up, it will first load the playlists from the server into the TTTabStrip. It will then select the first tab and load its videos list from the server. It will only load each playlist when it has been selected by the user after that, and retain the contents if they are selected again.

TTTableViewController expects to have only one model and one datasource. Keeping this in mind, there are several ways to accomplish the lazy loading and switching. My first impulse was to do everything with a single datasource which loaded different models and changed its items on the fly, which turned out to be too complicated for its own good. I also tried loading everything from a master model, but that killed the ability to do lazy loading, and was also difficult communicating back and forth with the controller. I settled on doing all the heavy lifting in the TTTableViewController, and that's what I'll be showing.

<h2>Setting Up the Datasources</h2>

Since we've decided to use our TTTableViewController as the director, we'll need to set up a few pointers in the header.

```
// TCYouTubeController.h
@interface TCYouTubeViewController : TTTableViewController &lt;TTTabDelegate&gt;{
    // The TabStrip sitting above the table
	TTTabStrip* _playlistsBar;

    // The model that generates a list of playlists for the TabStrip
	TCYouTubePlaylistsModel *_playlistsModel;

    // An array of TCYouTubeDataSource objects, one for each playlist
	NSMutableArray *_playlistDataSources;

    // A ppinter to the playlist datasource currently being viewed
	TCYouTubePlaylistDataSource *_activePlaylistDataSource;
}

@property (nonatomic, retain) TCYouTubePlaylistsModel* playlistsModel;
@property (nonatomic, retain) NSMutableArray* playlistDataSources;
@property (nonatomic, retain) TCYouTubePlaylistDataSource* activePlaylistDataSource;

// Convenience method for setting the active playlist from an index
// (usually from a button in an array whose entries correspond
// to those of the playlistModels)
- (void)setActivePlaylistAtIndex:(NSInteger)xActiveIndex;

@end
```

We'll dig into what each of these pointers is going to do for us in a second. Moving onto the implementation:

In loadView:, set create a containerView to add your TTTabStrip and TTTableView to.

Next, we need to start the ball rolling in our createModel (defined in the TTTableController source). First check to make sure we haven't already loaded the playlists. If we haven't, create the model, add the controller as a delegate, and then start the load.

```
- (void)createModel {
	if (!_playlistsModel &amp;&amp; !_playlistsModel.isLoaded){
		TT_RELEASE_SAFELY(_playlistsModel);
		_playlistsModel = [[TCYouTubePlaylistsModel alloc] initWithUsername:kYouTubeUserName];
		[_playlistsModel.delegates addObject:self];
		[_playlistsModel load:TTURLRequestCachePolicyDefault more:NO];
	}
}
```

I'll dig into what the model code should be doing in a second. We'll stay in the controller for now.

Since we registered as a delegate, our controller will receive a modelDidFinishLoad message after hitting the network. Here we want to check a couple things.

First, since we'll be receiving this message for each type of model (both playlist and videos) we have to check whether it's the playlists model we're expecting. If it is, clear out the dataSources array, then prepare an empty array of tabitems to add to the TTTabStrip.

Next, loop through each playlist in the playlists model. Create a new videos (single playlist) dataSource for each playlist and add it to the array we set up in the header for this purpose. Finally, make a corresponding tab containing the playlist title and add it to the TTTabStrip.

Since this is the first load, we want to load up the first playlist if it exists. We do this by momentarily setting the tabstrip index to max, then back to 0. This will trigger the setActivePlaylistAtIndex and load as if the user had tapped the button.

```
- (void)modelDidFinishLoad:(id&lt;TTModel&gt;)model {
	[super modelDidFinishLoad:model];

	// For only the playlist model...
	if ([model isEqual:self.playlistsModel]){
		// Clear out datasources
		self.playlistDataSources = nil;
		NSMutableArray *TabItems = [NSMutableArray arrayWithCapacity:0];

		// Iterate through playlist objects in the model
		for (TCYouTubeObjectPlaylist* Playlist in self.playlistsModel.playlists){
			TCYouTubePlaylistDataSource* NewDataSource = [[TCYouTubePlaylistDataSource alloc] initWithPlaylist:Playlist];
			[self.playlistDataSources addObject:NewDataSource];
			TT_RELEASE_SAFELY(NewDataSource);

			// Add buttons for all the playlists
			[TabItems addObject:[[[TTTabItem alloc] initWithTitle:Playlist.title] autorelease]];
		}

		if ([TabItems count]){
			_playlistsBar.tabItems = [NSArray arrayWithArray:TabItems];
		}

		// Initiate loading the first playlist
		[_playlistsBar setSelectedTabIndex:NSIntegerMax];
		[_playlistsBar setSelectedTabIndex:0];
	}
}
```

To fulfill our responsibility as a TTTabDelegate, add the following function to the dot m:

```
#pragma mark TTTabDelegate
- (void)tabBar:(TTTabBar*)tabBar tabSelected:(NSInteger)selectedIndex{
	[self setActivePlaylistAtIndex:selectedIndex];
}
```

Here we're just passing along the message to our setActive helper function that the user changed the playlist tab.

```
- (void)setActivePlaylistAtIndex:(NSInteger)xActiveIndex{
	if (self.playlistDataSources.count &gt; xActiveIndex){
		self.activePlaylistDataSource = [self.playlistDataSources objectAtIndex:xActiveIndex];
		self.dataSource = self.activePlaylistDataSource;
	}
}
```

Setting self.dataSource will trigger a load from the network.

That's about all for controller. But before we move on, remember to dealloc, create initializers for all your variables, handle errors from modelDidFailLoadWithError, and also implement a load:more: mechanism if you need it (YouTube pages at 25 items).

<h2>The Playlists Model</h2>

Now that all the front end is patched in, we'll need to get the backend in place. The playlists model does not have a corresponding table datasource because we're loading the entries directly into the TTTabStrip (although you could probably make one if you wanted to).

Starting with the PlaylistsModel header, we have two pieces of data to store.

```
@interface TCYouTubePlaylistsModel : TTURLRequestModel  {
	NSString* _username;	//username to search for
	NSArray* _playlists;		//array of TCYouTubeObjectPlaylist
} 
```

We pass in a username from the controller, and the playlists will be available to the controller after the load.

The implementation is a textbook TTURLRequestModel.

```
- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more{
// assemble the URL based on the username

// create a TTURLRequest

// create a TTURLXMLResponse to do the parsing
}

- (void)requestDidFinishLoad:(TTURLRequest*)request {
// make sure the root object looks like it should

// loop through assembling objects and adding them to the array
}
```

<h2>The Videos DataSource & Model</h2>

The last piece is the DataSource and Model for each playlist. I preface these with Videos because they could probably load from other sources besides a playlist. These are what will be loaded into the tableview as cells.

In the model, we need to keep the following information:

```
@interface TCYouTubeVideosModel : TTURLRequestModel {
	NSString* _sourceURL;	//URL that returns video entries (username, playlist, etc.)
	NSArray* _videos;       //array of TCYouTubeObjectVideo
}
```

As I mentioned, the model needs a full source URL. This is for the purposes of reusability, and because that's what we get when we parse the playlists model.

The implementation will have the same format as the playlists model above. Except you'll probably be loading a lot more information into your object. The YouTube API is quite verbose (which is good!).

And because we'll be loading these objects into the table, we'll need a dataSource, TTTableItem, and TTTableCell. The dataSource should store its corresponding playlist object (containing the URL, title, etc.), and its model (used to get data about the videos in the data).

```
@interface TCYouTubePlaylistDataSource : TTListDataSource {
	TCYouTubeObjectPlaylist* _playlist;
	TCYouTubeVideosModel* _videosModel;
}
```

Since we need the playlist, make an initializer to accept it. Then make the model right away.

```
- (id)initWithPlaylist:(TCYouTubeObjectPlaylist*)xPlaylist{
	if (self = [super init]) {
		_playlist = [xPlaylist retain];
		_videosModel = [[TCYouTubeVideosModel alloc] initWithSourceURL:[xPlaylist playlistURL]];
	}
	return self;
}

- (id&lt;TTModel&gt;)model {
	return _videosModel;
}

```

Don't forget to create your TTTableItems in didLoadModel. In this case, my TCYouTubeObjectVideo is a subclass of a TTTableItem, so I skipped most of this step.

```
- (void)tableViewDidLoadModel:(UITableView*)tableView {
	self.items = [NSMutableArray arrayWithArray:[_videosModel videos]];
}
```

Connect up your TTTableItems and TTTableCells as I mentioned in my previous post <a href="/blog/2011/02/06/all-about-tttableitems-cells.html/">All About TTTableItems & Cells</a>.

```
- (Class)tableView:(UITableView *)tableView cellClassForObject:(id)object {
    if([object isKindOfClass:[TCYouTubeObjectVideo class]])
        return [TCYouTubeVideoMultipleCell class];
    else
        return [super tableView:tableView cellClassForObject:object];
}
```
<h2>Conclusion</h2>
Hopefully this has given you some insight on one way to load multiple table layouts with a single controller.

If you're looking for more information about how to do layout or work with YouTube, check out this walkthrough: <a href="http://www.karlmonaghan.com/2010/10/06/three20-youtube-table-cells/">Three20 YouTube table cells</a>. Although I haven't been able to get the webviews to load up for every video.

<h2>Update</h2>
It's important to clarify my getters and setters for playlistDataSource. I'm synthesizing it as:

`@property (nonatomic, retain) NSMutableArray* playlistDataSources;`

And I'm overriding the getter like so:
```
- (NSMutableArray*)playlistDataSources{
	if (_playlistDataSources == nil){
		_playlistDataSources = [[NSMutableArray alloc] init];	
	}
	return _playlistDataSources;
}
``` 
