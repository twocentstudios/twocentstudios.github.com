---
layout: post
title: TTTableViewController & didReceiveMemoryWarning
tags:
- apple
- ios
- three20
status: publish
type: post
published: true
redirect_from: "/blog/2011/05/01/tttableviewcontroller-didreceivememorywarning.html"
---
<i>Note: this is adapted from my post on the Three20 forums <a href="http://forums.three20.info/discussion/98/tttableviewcontroller-didreceivememorywarning">here</a> and was relevant for at least v1.0.5.</i>

I was having trouble with a rare situation in which my app with two tabs would randomly mutate its table cells. It was more difficult to track down that this was occurring after a memory warning than it was to fix the actual problem. I was doing a lot of my view loading in init, something I hadn't fixed from when I had originally started writing this particular app over a year ago.

After moving moving the relevant assignments to loadView and viewDidLoad, I was still running into the problem where a memory warning would clear the loadingView, errorView, or emptyView on the tab that wasn't currently visible.

<img src="/images/memory-warning_before-after.png" alt="" title="memory-warning_before-after" width="550" height="412" class="size-large wp-image-73" />

After some backtracing through TTModelViewController and TTTableViewController, I narrowed down the problem to updateViewStates in TTModelViewController. At this line:

```
if (!_flags.isShowingLoading &amp;&amp; !_flags.isShowingModel &amp;&amp; !_flags.isShowingError) {
  showEmpty = !_flags.isShowingEmpty;
  _flags.isShowingEmpty = YES;
}
```

The if statement evaluates to true as expected because the controller is not showing an error, the model, or loading. The problem is in the next line. _flags.isShowingEmpty has not been reset even though it isn't showing empty anymore due to the clear by didReceiveMemory warning. Therefore, the local variable showEmpty is set to NO, and _flags.isShowingEmpty is set unconditionally to YES even though it isn't really showing the empty view.

The way to fix this locally is to override didReceiveMemoryWarning in your TTTableViewController subclass.

```
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  [self invalidateModel];
}
```

invalidateModel calls resetViewStates in the model. This will set all the view _flags to NO and the next pass through updateViewStates will trigger the correct action.

The permanent fix in Three20's TTModelViewController would be:

```
- (void)didReceiveMemoryWarning {
  if (_hasViewAppeared &amp;&amp; !_isViewAppearing) {
    [super didReceiveMemoryWarning];
    [self resetViewStates];  // add this line
    [self refresh];
  } else {
    [super didReceiveMemoryWarning];
  }
}
``` 
