---
layout: post
title: Simple AJAX Comments with Rails
date: 2012-11-15 09:50
comments: true
categories: rails
redirect_from: "/blog/2012/11/15/simple-ajax-comments-with-rails"
---

> Update 2014-06-08: This post is over two years old now. Although I've heard the below walkthrough works  mostly as expected, I've been away from Rails too long to know the ins and outs of the current version of Rails and all the gems used. So a word of warning: I can't guarantee all of the below will work line-for-line anymore. Feel free to ping me on Twitter if you find any changes.

I've been working on and off with Rails for a few years now, but when I started I had little HTML/CSS/JS knowledge from which to build. Most of my web experience I learned along the way in the context of Rails.

HTML and CSS were much easier to build familiarity with than JavaScript. I always found more time-tested best practices concerning HTML and CSS than I did with JS/AJAX. AJAX with Rails techniques seemed to have changed significantly between releases of Rails major (and even minor) versions.

I am by no means an expert, but my goal with this post is to walk beginners through a working technique for vanilla AJAX comments on resources based on Rails 3.2.x.

## What we're making

Our goal is to make a comment form that we can attach to any resource in our Rails app. It will look something like this:

{% caption_img /images/rails-comments-ss-1.png Our goal %}

The layout is pretty standard. A create form sits on top of a list of comments (newest first).

Our example resource throughout this post is an "Event". We'll only discuss it in terms of being an example generic resource with comments that belong to it.

### Create

When a logged in user enters a comment and clicks "Create Comment", the browser sends a message back to the server with the comment body, the resource name, and resource id. Once the server processes the message, it will send the comment body rendered in HTML in the same partial as the other comments were rendered with.

In the meantime, on the client side, we'll be doing some basic jQuery effects to let the user know their comment is being processed. We'll disable the textarea and submit button so they don't accidentally submit the same comment twice.

Once the server returns our new HTML, we'll reenable the form controls, clear the text from the textarea, and then add the new HTML to the top of the comment list.

To keep it simple for now, we won't be handling the error cases in significant detail.

#### Processing order

* route: GET /event/1
* controller: events#show
* view: events/show.html.haml
* partial: comments/_form.html.haml
* partial: comments/_comment.html.haml
* user: add comment body and click create
* js: comments.js.coffee -> ajax:beforeSend
* route: POST /comments
* controller: comments#create
* partial: comments/_comment.html.haml
* js: comments.js.coffee -> ajax:success

We'll touch on each of these steps, but not necessarily in that order.

### Delete

We'll also allow users to delete comments (eventually only comments they've created!). When they click the 'x' next to the comment, we'll prompt them with a standard confirmation. If they answer yes, we'll then send the comment id to the server.

On the browser side, we'll immediately dim the comment to half opacity to let the user know we're trying to delete the comment. Once we receive a response indicating the comment has been removed from the database, we'll then hide the comment in their browser the rest of the way.

There are a few error conditions we should handle here as well, but we won't look at those in this post.

#### Processing order

* route: GET /event/1
* controller: events#show
* view: events/show.html.haml
* partial: comments/_form.html.haml
* partial: comments/_comment.html.haml
* user: click "x" next to comment
* user: click "yes" to confirm
* js: comments.js.coffee -> ajax:beforeSend
* route: DELETE /comments/1
* controller: comments#destroy
* partial: comment.json
* js: comments.js.coffee -> ajax:success

The first half is the same as we'll see for comment creation, so we'll focus on the last half mostly in that order.

## Where to start?

First place to start is getting our backend comment system in place. We'll be using the [acts_as_commentable_with_threading](https://github.com/elight/acts_as_commentable_with_threading) gem (although we won't be using the threading right away).

The instructions for setting this up are pretty simple. I'm just using ActiveRecord and SQLite right now.

* Put the gem in your bundle `gem acts_as_commentable_with_threading`.
* Run `bundle install`.
* Run the migrations `rails g acts_as_commentable_with_threading_migration`.
* Run `rake db:migrate`.
* Add `acts_as_commentable` to the `Event` model class (and any other model you want to have comments).
		
		# event.rb
		class Event < ActiveRecord::Base
  			acts_as_commentable
		end		

This post is supposed to be more about AJAX than Rails associations, but it's worth mentioning that acts_as_commentable uses a [polymorphic association](http://guides.rubyonrails.org/association_basics.html#polymorphic-associations). This means that any of your models can reference the same kind of comment model object, and we don't have to have a separate table in our database for an `EventComment` or a `VideoComment` for example. Each comment record keeps track of what type of object its parent is, which will be important later since we need to know information about the parent in order to create a comment.

## Routes

Next we'll set up our routes just to get that out of the way. We're going to let the `CommentsController` handle creation and deletion of comments, so the routes should point there.

		# routes.rb
		resources :comments, :only => [:create, :destroy]
		
This will give us two methods from the following urls (from `rake routes`).

		$ rake routes
		comments 	POST 		/comments(.:format) 	comments#create
		comment 	DELETE 	/comments/:id(.:format) 	comments#destroy
		
This is going to give us a `commments_path` helper and `comment_path(:id)` helper to complete our POST and DELETE requests,  respectively. It will forward requests to those URLs to the `CommentsController`'s `create` and `destroy` methods. The create method has no parameters in the URL string. The destroy method takes the comment's `id` as the single parameter of the URL string. Like we mentioned earlier, in order to create the comment, we'll need a few more parameters. We'll talk more about that when we get to the form.

### Alternate implementation

Aside: An alternate implementation worth mentioning is to include comments as a [nested resource](http://guides.rubyonrails.org/routing.html#nested-resources) beneath each resource that has them. It would look something like this:

		# routes.rb - alternate
		resources :events
			resources :comments, :only => [:create, :destroy]
		end
		
		resources :videos
			resources :comments, :only => [:create, :destroy]
		end

This works fine if your resources are all siblings. In my case, I have `Video` nested within `Event` already. It gets pretty hairy pretty quickly and gives you (unnecessarily) complicated routes and URLs. In this case, we'll go with the other implementation that includes the necessary data about the comment's parent in the HTTP POST data rather than the URL string.

Again, it works either way so always tailor your implementation based on your particular situation.

## show.html.haml

Now that we've got the bridge between the view and the controller built (the route), we'll tackle the show view template.

Our goal is to be able put the comment "block" (the add new form and the list of previously created comments) anywhere. In this example, we'll stick it in the `show` view of the `EventsController`.

(Sidebar: I use [Haml](http://www.haml.info) and [simple form](https://github.com/plataformatec/simple_form), sorry in advance to users of other templates. Hopefully you can still follow along.)

		/ show.html.haml
		.event
			%h1= @event.name
		.comments
			%h2 Comments
			= render :partial => 'comments/form', :locals => { :comment => @new_comment }
			= render :partial => 'comments/comment', :collection => @comments, :as => :comment
			
As you can see, our show template expects 3 different instance variables from the `EventsController`.

* `@event`: the unique `Event` object we're showing.
* `@new_comment`: a new `Comment` object that acts as our framework for building out the comment form. It exists only in Rails for now and has not been created in the database yet.
* `@comments`: an array of all or just a subset of the `Comment` objects that exist as children of the `@event` object (in reverse chronological order of course).

In our `views/comments` folder, we have the two partials `_form.html.haml` and `_comment.html.haml`. `_form` expects a local variable named `comment` as an input to help build the new comment form. `comment.html.haml` is our partial for displaying a single comment. It takes a collection of `comment`s and tells the renderer to treat each object in the collection as a `comment`.

## events#show

Before we dig into writing each partial, let's step backwards in the chain of events and go back to our `EventsController` to set up those instances variables that the show template will be looking for.

		# events_controller.rb
		class EventsController < ApplicationController
		  def show
		    @event = Event.find(params[:id])
		    @comments = @event.comment_threads.order('created_at desc')
		    @new_comment = Comment.build_from(@event, current_user.id, "")
		  end
		end

The first line of the `show` method should be par for the course. We're pulling the event in question from the database based on the `id` provided in the URL. Rails automatically inserts a `render 'show'` for us at the end of the method.

The second line looks a little fishy. We're using a helper method included in `acts_as_commentable_with_threading` to get the comments associated with the `@event` and order them by date. You might also want to do pagination at this step too, but with our nested event->comment architecture, it might also warrant an AJAX solution to load more (that's a topic for another post).

The third line creates a placeholder comment object that acts as sort of a carrier for our parent object info. This new blank comment object will carry with it a reference to the parent `@event` and therefore its object type and id, and the current user. The `build_from` method is another helper created by `acts_as_commentable_with_threading`.

## comments/_form.html.haml

Now we can continue on to our new comment form partial.

		# _form.html.haml
		.comment-form
		  = simple_form_for comment, :remote => true do |f|
		    = f.input :body, :input_html => { :rows => "2" }, :label => false
		    = f.input :commentable_id, :as => :hidden, :value => comment.commentable_id
		    = f.input :commentable_type, :as => :hidden, :value => comment.commentable_type
		    = f.button :submit, :class => "btn btn-primary", :disable_with => "Submitting…"

Let's step through line by line.

First, we'll wrap the form with the `comment-form` class.

Next, we're going to use simple form to create a form block for our comment. Adding `:remote => true` will provide the Rails magic to turn our standard form into an AJAX one. The form_for helper is smart enough in this case to pick the correct URL and HTTP method. We could specify it directly as:

		= simple_form_for comment, :url => comment_path, :method => 'post', :remote => true do |f|

The first input is the textarea for our comment body. Nothing special here, just limiting the rows to 2 and turning the label off.

The next two inputs are hidden from the user and will be included with the form submission to the server. We're including the `commentable_type` or class name of the parent object and its id so that our `CommentsController` will know what object to link the new comment to.

Aside: I want to mention that since these hidden inputs are technically open to alteration, they must be properly sanitized by the server before being acted upon. By altering these values, the user could potentially create a new comment on a different object type and/or an object they aren't allowed to see.

Our last form element is a submit button with Twitter Bootstrap classes for styling. Clicking this will trigger the AJAX action and submit our form data to the `CommentsController` for handling. The `disable_with` takes care of some of the JS we'd have to write by disabling the submit button.

I'm going to skip the JS for now and move onto the `CommentsController` implementation. We'll get back to the JS in a moment.

## CommentsController

If you recall earlier, we set up routes to our `CommentsController` for two methods: `create` and `destroy`. Let's take a look at `create`.

		# comments_controller.rb
		class CommentsController < ApplicationController
		  def create
		    @comment_hash = params[:comment]
		    @obj = @comment_hash[:commentable_type].constantize.find(@comment_hash[:commentable_id])
		    # Not implemented: check to see whether the user has permission to create a comment on this object
		    @comment = Comment.build_from(@obj, current_user.id, @comment_hash[:body])
		    if @comment.save
		      render :partial => "comments/comment", :locals => { :comment => @comment }, :layout => false, :status => :created
		    else
		      render :js => "alert('error saving comment');"
		    end
		  end
		end
		
The first thing we do is grab a reference to the form data. Our form data is in the params hash under the `:comment` symbol. We'll store it as `@comment_hash` for use below.

Next we need to derive the parent object where the comment was created. Luckily, we included the commentable_type and commentable_id in our form data. `@comment_hash[:commentable_type]` will return the string `"Event"`. We can't call find on a string, so we have to turn it into a symbol that Ruby recognizes. We can use `constantize` to do this conversion (it would be a good idea at this point to check to make sure the commentable_type is legitimate). With a fully qualified `Event` class we can call the class method `find` and pass it the `:commentable_id`. Out pops our event object.

The next step is to determine whether the current_user has permission to create the comment on the object. This depends on your authentication system, but should definitely be included.

We now have references to all the objects we need in order to create the comment. We'll use the `build_from` helper method again and give it the object, current_user, and the body of the comment.

We need to save the comment back to the database. If the save is successful, we're going to do a few things.

* Render the single comment partial with our new comment as the local variable. This will give the comment all the markup it needs to be inserted directly into the existing page.
* `:layout => false` will tell the renderer not to include all the extra header and footer markup.
* `:status => :created` returns the HTTP status code 201 as is proper.

If the save is not successful, we need to tell the user that there was a problem. I'm leaving this outside the scope of the post simply because there are several different ways of doing this depending on how you set up your layout. Above, all we're doing is popping up an alert box to the user. You should consider this an incomplete implementation.

Aside: using Rails to render HTML is a technique opposite that of returning raw JSON and using client-side JS libraries to handle all things view related. You may want to look into something like [Ember.js](http://emberjs.com).

## JavaScript for create

We're finally back to the JavaScript, or more specifically, CoffeeScript. I'm not an expert in either, but for this stuff you don't need to be one. I'm using CoffeeScript because it makes the code slightly cleaner.

The only CoffeeScript we're going to write can sit comfortably in the asset pipeline in the `comments.js.coffee` file (more specifically, app/assets/javascripts).

		# comments.js.coffee
		jQuery ->
		  # Create a comment
		  $(".comment-form")
		    .on "ajax:beforeSend", (evt, xhr, settings) ->
		      $(this).find('textarea')
		        .addClass('uneditable-input')
		        .attr('disabled', 'disabled');
		    .on "ajax:success", (evt, data, status, xhr) ->
		      $(this).find('textarea')
		        .removeClass('uneditable-input')
		        .removeAttr('disabled', 'disabled')
		        .val('');
		      $(xhr.responseText).hide().insertAfter($(this)).show('slow')
		      
What is code actually doing? We're simply registering for callbacks on the AJAX requests that will originate from our comment form. When those events occur, we're going to run functions.

`$(.comment-form)` targets the `comment-form` class we applied to the `div` that wraps our comment form partial. This allows us to actually use multiple comment forms on a single page if we want to.

`.on` is the jQuery function that binds an event to a function. It replaces the older jQuery functions `.bind`, `.delegate`, and `.live`. You can read about it [here](http://api.jquery.com/on/).

The first event we're binding to is `"ajax:beforeSend"`. When the user clicks the submit button, Rails will trigger this event, and our function will be called. The arguments passed to the function (and all the available callbacks) can be found on the [jquery-ujs wiki](https://github.com/rails/jquery-ujs/wiki/ajax).

The function that runs on this event is embedded as anonymous. We could call a function that exists elsewhere just as easily. 

`$(this)` is the jQuery object version of the `.comment-form` `div` that was involved in the click. Alternatively, we could grab a reference to the form from `$(evt.currentTarget)`. We'll use `$(this)` to extract the textarea element in the next line. `.find('textarea')` will select `textarea` elements within the form. In our case, we only have one. We then chain two functions together to perform two operations on the `textarea`s.

		$(this).find('textarea')
		  .addClass('uneditable-input')
		  .attr('disabled', 'disabled');

is equivalent to:

		$(this).find('textarea').addClass('uneditable-input');
		$(this).find('textarea').attr('disabled', 'disabled');
		
`addClass` adds the `uneditable-input` class to our textarea, which will perform some Bootstrap styling to our textarea, but not actually make it uneditable.

`attr` adds the `disabled='disabled'` element to our textarea actually disabling the user input.

We're then chaining another `.on` for the `ajax:success` event that gets called if the AJAX call returns successfully. Our first move is to find the `textarea` and undo the temporary disabling (you may want to consider doing this at the `ajax:complete` event, because it should be done regardless of whether the AJAX was successful). You'll notice we chained one additional function `.val('')` at the end. This will clear the `textarea` in anticipation of the user adding another comment. You wouldn't want to do that in the error case, because the user should have an opportunity to resubmit the comment without having to retype it.

We're finally ready to add the nicely formatted comment to the top of our comment feed.

* `$(xhr.responseText)` gets a jQuery object version of the response HTML returned by the server.
* `.hide()` disappears our new `div` so it can be animated in.
* `.insertAfter($(this))` places our new `div` after the comment form. If you want to put it somewhere more specific, you can replace the `$(this)` selector with a more specific selector.
* `.show('slow')` animates our new `div` sliding down from the form.

## _comment.html.haml / deletion

I skipped our single comment template, so I'll add it here for completeness. This will lead us into the comment deletion section.

		# _comment.html.haml
		%div.comment{ :id => "comment-#{comment.id}" }
		  %hr
		  = link_to "×", comment_path(comment), :method => :delete, :remote => true, :confirm => "Are you sure you want to remove this comment?", :disable_with => "×", :class => 'close'
		  %h4
		    = comment.user.username
		    %small= comment.updated_at
		  %p= comment.body
		  
Our wrapper div has a `comment` class, and a CSS id unique to each comment. We're not actually going to use that id, but it could be useful in the future.

`link_to` should look familiar. Our display text is an x. The link will go to the delete path we created earlier in the Routes section. To refresh your memory, it will go to `/comments/:id`. `:method => :delete` tells Rails to use the `DELETE` HTML method.

`:remote => true` performs the Rails AJAX magic like we saw earlier with the creation form. `:confirm` pops up a JS alert to confirm the user wants to do remove the comment. `:disable_with` makes sure the user can't try to delete the comment while the server is processing the first request. And the `close` class is Bootstrap styling.

Another reminder: you'll probably want to conditionally display the delete link to the comment creator and admins. [Draper](https://github.com/drapergem/draper) is a good option for doing this cleanly.

The rest of the markup should be pretty straightforward.

## Back to CommentsController

Time to add the `destroy` method to your `CommentsController`.

		# comments_controller.rb
		def destroy
		  @comment = Comment.find(params[:id])
		  if @comment.destroy
		    render :json => @comment, :status => :ok
		  else
		    render :js => "alert('error deleting comment');"
		  end
		end

`@comment` will track down the comment-to-be deleted from the database (check that user is allowed to delete it!).

Then try to destroy the comment. This time, when the call completes successfully, I'm sending raw json back to the client with an `ok` status. There are a myriad of options here. Use what's best for your app.

And on error I'm copping out again and sending back JS.

Aside: if you want to do some informal testing, I recommend throwing a `sleep 5` call before the `if` statement so you have more time to observe your AJAX.

## JavaScript for destroy

Back to our `comments.js.coffee` file.

		jQuery ->
		  # Create a comment
		  # ...
		
		  # Delete a comment
		  $(document)
		    .on "ajax:beforeSend", ".comment", ->
		      $(this).fadeTo('fast', 0.5)
		    .on "ajax:success", ".comment", ->
		      $(this).hide('fast')
		    .on "ajax:error", ".comment", ->
		      $(this).fadeTo('fast', 1)

We're going to use the other incarnation of `.on` for the reason I'll explain in a moment. This time we're calling `.on` on the whole DOM. We specify our event first as we did before, but now we'll add the `".comment"` selector as the second argument. Again, this applies to all of our comment `div`s with the `comment` class.

We're not going to bother including the arguments to the `ajax` event callbacks (for example `(evt, xhr, settings)`); we don't need them.

`$(this)` refers to the comment `div` that generated the event. We're going fade the entire comment to half opacity before sending the request to the server by calling `.fadeTo('fast', 0.5)`. On success, we'll animate the comment fading the rest of the way out and disappearing to show the user the request was completed succesfully. On error, we'll fade the comment back to full opacity to show that the comment still exists.

The reason we used `$(document)` this time instead of calling `.on` on the selector directly is because it will apply the callback to newly created DOM elements as well. For example, I can add a comment and then immediately delete it without refreshing the page.

## Wrap up

This turned out to be quite the mega-post. I may have gone into too much detail, but I'm hoping this has enlightened any new Rails devs out there.

We didn't actually write that much JavaScript, and most of it was simply for decoration. But this should give you the building blocks you need to add more interesting functionality on AJAX triggers. I highly recommend [this jQuery reference/overview](http://oscarotero.com/jquery).

Discuss this on [Hacker News](http://news.ycombinator.com/item?id=4798823).