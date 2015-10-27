---
layout: post
title: Learning Ruby and Rails
tags:
- Commentary
- learning
- Rails
- rails
- ruby
status: publish
type: post
published: true
redirect_from: "/blog/2011/05/06/learning-ruby-and-rails.html"
---
Last October, a couple things came together at the same time which prompted to want to learn Rails.
<h2>Starting Out</h2>
I had been listening to Dan Benjamin's <a title="5by5" href="http://5by5.tv" target="_blank">5by5</a> podcasts nearly since they started at the beginning of the year, and always came away feeling like Ruby was a force to be reckoned with. I was also getting a little burnt out doing iOS stuff. All my coding in college was C and assembly. After that was strictly iOS for a year and change up to that point.

As I constantly brainstormed new app ideas and looked at the most successful apps that had come, gone, and stayed in the AppStore charts, I realized that the best ones (that aren't games) are viewports into webservices. The problem was that I didn't know anything about writing server-side anything. My web endeavors began and ended in high school before CSS was a toddler.

I was on a big productivity kick at work, trying to find ways to better connect the project groups in my office. Everyone was half-heartedly talking about group to-do lists, MS Project, spreadsheets on a server, all the usual suspects. My idea at the time was to have some kind of inter-office Twitter feed, and of course I needed to do some server-side stuff to get that to happen. (I can't remember exactly what happened, but I ended up giving up on the idea and with it, learning Rails).

At the time, I don't think I was aware of all the CMS frameworks in PHP and other languages that would make this a cakewalk. I know the WordPress theme would have been extremely easy to set up. But either way, I wanted to get my hands dirty. But I also wanted results. And because I was impatient, I skipped Ruby and dived straight into Rails.

That was my first mistake. I've read a few things about how most people could go either way with learning Ruby first or jumping straight into Rails. I couldn't quite make it without Ruby.

<span style="font-size: 20px; font-weight: bold;">Diving In</span>

It felt kind of like when your middle school teacher assigns a book to read and says, "If you get stuck, just skip the words you don't know and keep reading". Except that with diving straight into Rails, I felt like I didn't know a single word. As soon as I hit something I didn't understand, my brain would stick in a loop and I couldn't move on without understanding what the line meant. And without base Ruby, I could go nowhere.

So I tried <a title="tryruby" href="http://tryruby.org" target="_blank">tryruby</a>. But it kept crashing and I didn't have a pure Ruby project to work on, so it never really stuck.

I then tried a couple Rails tutorials, including Rails for Zombies. <a title="Rails for Zombies" href="http://railsforzombies.org/" target="_blank">Rails for Zombies</a> was great, but since my knowledge was so shallow, I was just going through the motions and not retaining anything. After a weekend or two of trying to power through the learning phase, I'm ashamed to say I quit. I gave up my idea for my office, and I quit. I came crawling back to iOS.
<h2>Doing It the Right Way</h2>
Fast forward to March. I came across the opportunity to learn Ruby for my day job. The idea of learning Ruby and Rails had still been simmering since the Fall. I was almost actively looking for any reason to learn them. The task I had to complete was to import a bunch of old customer support tickets into Zendesk. A nice, bite-sized Ruby project.

I knew that I really needed to learn Ruby this time around. Not just enough to fake my way through Rails, but really get a handle on the ins and outs. Luckily, I came across <a title="Ruby Koans" href="http://rubykoans.com/" target="_blank">Ruby Koans</a> which kicked my butt up and down the text editor. I can't say enough great things about it. Really wonderful little courselet.

As a quick aside, I've never really coded in a scripting language before, even Javascript, so one of the hardest things about Ruby at first was literally just understanding the entry point and the program flow. int main has always been my friend, but now I was just sitting at the terminal saying, "Great. I just wrote all these modules and classes and functions, now where do I use them?".

I worked through Koans, and went to start on my task. The first part was finding gems to help me out. I found a gem for the Zendesk-API, a csv parser, and an XML assembler. Looking through the source of these gems helped me understand more about program flow and best practices on code structure.

It took plenty of trial and error, but after all that I pounded out a nice little script to import a csv file into Zendesk using Ruby. It felt good.
<h2>Onto Rails</h2>
Fast forward again a month, and I realized that I was in a much better position to learn Rails now. It just so happened that administrating Zendesk for a little while and starting to use <a title="TestFlight" href="http://testflightapp.com" target="_blank">TestFlight</a> for my iOS beta testing really started to inspire another productivity kick around the office.

I'm pretty familiar with most of the engineering processes and workflows at my day job. The problem is that they're all pretty archaic. Lots of MS Office tools because that's what everyone knows. And even though they're not designed for it, Excel is used to lay out forms, email is used to do workflows, and even SharePoint is now in the mix. Using the wrong tools diverts a lot of time towards the wrong things.

So I decided that I was going to write a workflow system for an engineering process. It doesn't have a lot of data that needs stored, and it's mostly users interacting with one set of objects. I don't think it's more than I can chew, but I guess we'll see because it's not done yet.

I ran across a Rails tutorial I hadn't seen before. <a title="Ruby on Rails Tutorial" href="http://ruby.railstutorial.org/ruby-on-rails-tutorial-book" target="_blank">Ruby on Rails Tutorial</a> by Michael Hartl was exactly what I needed. Doesn't pull punches, but also patiently explains every step of the way. Again, highly recommended. Read it cover to cover, and I'm still going back for more. It gets pretty tough at the end though, especially for someone like me with little to no experience with databases.
<h2>Where am I Now?</h2>
I've brainstormed out my database tables, listed my routes, mocked up most of the screens, and I think I'm ready to dive into code. I wanted to mark this moment as a point of little knowledge that will hopefully make me feel better when I (hopefully) have a lot of Rails knowledge in the distant future.

If anyone had other good routes to Ruby and/or Rails fluency, I'd love to hear about it in the comments.
