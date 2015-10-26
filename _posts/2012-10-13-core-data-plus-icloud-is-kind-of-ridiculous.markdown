---
layout: post
title: "Core Data + iCloud is Kind Of Ridiculous"
date: 2012-10-13 19:48
comments: true
categories: iOS, Core Data, iCloud
---

I've spent most of the evening getting reacquainted with Core Data. My goal is to get up to speed enough to use it and iCloud for a simple app idea I want to prototype out. It's turning out to be a little more daunting than I had hoped.

## Past Core Data experience

On a previous app, I used Core Data to store values pulled from a server in a single table on the user's device as a makeshift cache so that it could be used as a fallback if the network was not available. This was almost two years ago. I could cobble together enough code from intros and blog posts to set up my one-table schema, set up my persistent store, pull a managed object context, do some simple storing, and some very simple fetching based on a unique object field.

I was using it as more of a nice-to-have than a core feature of my app, so I never had to dig into it that much.

In my new app, I'm also planning on storing a single table of data. But this time, that data is the heart of my app. It's also going to need to be sliced and diced in a number of different search contexts. And the biggest X-factor is that I want to be able to access and modify that data from different iOS devices. This is where iCloud comes in.

I almost used iCloud on my BrightBus application, but pulled out of that decision last minute because I needed to support older devices and didn't want to have two different document models. In the case of BrightBus, I wanted to store a collection of favorite stops. This is a simple plist, so it would be using the simpler UIDocument APIs.

## Commence learning

So now that I've decided that it makes sense to use Core Data and iCloud for this app, it's time to get started.

First thing, I need to set up a new app ID specific to this app that has iCloud enabled. Okay great, but I have no idea what to name my app  yet. Well I can just create a throwaway one and change it after I've got most of the app ready to go. Okay, but the ID will hang around forever in my account because you can't delete or rename them. Okay whatever.

Now a new provisioning profile, okay that's not that bad.

Let's make a new project. Again, not sure what the name is, but whatever, no one will see it anyway.

Now I've got to set the entitlements. Alright I'll use my app ID and reverse URL string. But oh wait, I used a dash in the app ID, but a space when I created the Xcode project. Ugh, let me go back and try again. Delete folder, create new project.

I have to decide whether I want people with iCloud disabled to be able to use my app. Uh, yeah probably, but oh wait that makes things much more complicated on my side? Uh… I'll punt on that decision while I do some more research.

I have to decide what data isn't important and can be regenerated and make a separate persistent store for that that won't go to iCloud. Or I can use CoreData configurations to handle that in a single store. I'm thinking that in my case it's all important so I don't have to worry about that.

I don't have to worry about seeding either, so that's good.

But if I start digging into the actual details of setting this stuff up, I get constants like `NSPersistantStoreUbiquitousContentNameKey` and `NSPersistentStoreDidImportUbiquitousContentChangesNotification` that look scary, but maybe if I watch this WWDC video enough, the framework designers' explanations will give me insight into what those words represent.

And then I stop for a second.

At this point I have to tally my pros and cons for using iCloud versus something like Parse, which I've done a little research into in the past but haven't actually used it on a production app.

#### iCloud

* pros
	* I don't have to worry about managing users accounts
	* I don't have to worry about storing user data on my servers
	* My app really is only storing individual data, but I can still post to Twitter and Facebook if need be
	* I can sync between iOS devices and Macs
* cons
	* If people don't have iCloud accounts, switch accounts, or delete my app's data from their accounts it gets hairy
	* I have to set up all the weird provisioning and entitlements and app keys right
	* I have to deal with conflicts
	* I can't ever run a normal web service or let users use this data from anything other than an iOS or OS X device
	* Have to worry about schema migrations if I decide to change stuff in the future = more/more difficult maintenance
	* Wow is this complicated (CoreDataController from WWDC sample is ~750 LOC and takes lots of shortcuts)
	
#### Parse

* pros
	* I (kind of) don't have to worry about managing user accounts
	* I don't have to worry about storing user data on my servers
	* I have access to all data in case there's a need
	* Users can get the data from a normal web service or any device I want
	* I can sync data
	* Schemaless = more flexible
	* Users can still use the service anonymously
* cons
	* I still have to deal with merge conflicts
	* Fetch performance is probably much worse because I have to hit the network (although there's a lot of caching so that could be ambiguous)
	
#### Neither (punt)

* pros
	* I can focus more on user experience within the app
	* No worrying about syncing edge cases
	* Less boilerplate
	* I can validate the main app idea faster
	* I don't have to deal with conflicts
* cons
	* Users may immediately request app access from multiple devices
	* I may want to add out-of-app features that need the infrastructure
	* It will be more difficult to migrate over to a network model later (the foundation of my app might need to be rearchitected)
	* I'm missing out on an opportunity to become skilled in one of the above technologies
	
This is a tough call. I'm going to finish out these CoreData + iCloud videos and sleep on it.

All I know is that with Rails and ActiveRecord this is a completely different ballgame. Yes, at first it was just as opaque, but it just seems so much more flexible up against the Core Data APIs. Apple exposes so much complexity in their APIs sometimes, and you think that in the vast majority of cases it just doesn't need to be that way.

Now I'm just ranting, so I'll have to sleep on it like I said and circle back in the morning.