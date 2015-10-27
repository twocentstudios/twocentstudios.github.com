---
layout: post
title: didShowModel Blues
tags:
- Animation
- showMenu
- TTTableViewController
- UX
status: publish
type: post
published: true
redirect_from: "/blog/2011/04/05/didshowmodel-blues.html"
---
I'm working with a TTTableViewController right now. Try to stay with me.

TableViewController gets pushed onto the navigation stack, hits the network looking for data, and loads the data. I want to animate the top cell so it looks like it moves a little to the right then bounces back into place. This is supposed to key the user into the fact that there's more info lurking beneath the top cell layer and that they should swipe to reveal it (a la the showMenu: and hideMenu: pre-rolled functions).

My first thought (which always seems to be wrong) was to trigger this in didShowModel in the TTTableViewController. This is supposed to be the moment when all the layout is has been completed, right? To test my theory, if I call showMenu not animated to push all the views right, then call hideMenu animated, it should swoop in just as the cells load.

It doesn't seem to work that way. The behavior I viewed in this situation was instead that the showMenu didn't have any effect, and then the hideMenu (triggered a second later with a timer) would swipe everything off to the left (instead of bringing it from off-screen back into front and center). After didShowModel completes, is something going on in the TT objects that's resetting the move I'm doing?

For now, it seems like the best solution, although a bit hacky, is to set a short timer (0.3 seconds) in the didShowModel that calls back to a function with a CAAnimation group. This gives both the TTTableViewController time to lay out its views and get out of dodge, and also lets the user see the table momentarily before it starts moving. This is essentially the same as setting an animation delay.

With that problem out of the way, I have to say that the animation effect is kind of cool, but I feel like it will definitely be fatiguing to users to see this animation every time the table loads. Should it be only for the first five table loads the user ever does? Should it be only for the first table load in every launch? Only for the first couple days after download? I'm thinking option A, but I'll have to wait until the beta testing to zero in on that answer.

In any case, I'll have to step through the TTTableViewController code to find out where the layout is getting reset. If anyone else has done this before, let me know in the comments.
