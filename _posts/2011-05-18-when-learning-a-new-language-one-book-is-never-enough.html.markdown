--- 
layout: post
title: When Learning a New Language, One Book is Never Enough
tags: 
- Commentary
status: publish
type: post
published: true
meta: 
  _edit_last: "1"
  sfw_comment_form_password: cY4OtNtbggVw
---
How do you go about learning a new programming language or tool?

My steps to learning a new language are traditionally as follows:
<ol>
	<li>Stare blankly at source code of new language until my eyes and brain hurt.</li>
	<li>Acquire a book and fight my way through it, reading from cover to cover.</li>
	<li>Use said book and Google to code up whatever idea had originally inspired me to learn the language.</li>
	<li>Find more well-written (I hope?) source code and this time actually understand about half of it.</li>
	<li>Acquire a second book and read through it slightly faster than the first, seeing things I read in the first explained in a slightly different way.</li>
	<li>Work on a more complicated idea, using all previous knowledge acquired.</li>
	<li>Start using only Google, Github, and targeted blog posts to gain more knowledge.</li>
</ol>
As a kid (high school, college), I realize I relied way too much on one source of information when learning a new language. Of course, the internet wasn't the same as it is now, but the bookshelves were definitely filled with plenty of "Beginning Zombiescript++" books. Heck, I remember pulling random books off the shelves and leafing through them just to try to figure out why I would want to use whatever language they were teaching. Most of time I couldn't figure it out.

I've seen it a million times through my schooling years; I just don't really get things the first time through. A lot of the time that was because I didn't really understand why I needed to know what I was being taught in the first place (which is an entire topic of its own). But even if I saw the entire birds-eye view of a subject, it would still take seeing it from a different angle to really get me to connect the dots.

(Aside: I know of the popular technique of immediately trying to teach what you've just learned. At the initial stages of learning, I find this pointless. Mostly because it only really makes sense for memorization type exercises, and if you're trying to teach something serious, you're not really teaching, you're pandering to be corrected. I only feel comfortable publicly teaching after I know I have enough knowledge to put together that general birds-eye view curriculum and have proven successes.)

One particular event in college when things really lined up for me was learning assembly in two different courses at the same time. I was learning x86 assembly in my systems programming class, while at the same time learning TI DSP assembly in my digital signal processing lab. Before starting these, it wasn't obvious to me that assembly wasn't like C++ or other high level languages that you wrote once and someone else wrote the compiler for each system type to make it run. Seeing how the instruction sets were tailored to the main function of each processor (processing digital signals, running complex operating systems, etc.) opened my eyes to the underlying logic of how these systems were designed in a way it wouldn't have understood if I were just taking one of the classes.

<strong>When you're learning something new, get as many perspectives as you can on whatever you're learning early on.</strong> Not only will it help you better understand the subject itself, but it will also prevent you from getting a "brainwashed" view of your subject. If one author thinks the best way to teach iOS programming is to start with learning everything there is to know about views, you might be a little disappointed when you realize you didn't have to worry about them at all to write your first UITableView driven app. Likewise, if the author you're reading thinks it's fine and dandy to never touch the CoreGraphics framework, having another perspective might change your mind if you're building a very customized UI.

The other thing to hunt out furiously when you're first starting out is the big picture. Knowing what you don't know, knowing what you need to know now, and knowing what you can do with libraries and frameworks is the main focus here. I was painfully unaware of how to find good opensource libraries when I started out iOS programming, and in turn wrote a ton of basic low-level stuff from scratch. A lot of it was wrong, and a lot of it worked anyway even though it was so hacked together it was indecipherable the next day. I did learn a lot from this, but only by seeing it done correctly later (usually <em>much</em> later). And also by getting a few apps under my belt and revisiting it to assess the damage. There are some cases where it's a good idea to roll your own, but it's almost always a better idea to use it as a guided exercise so you can immediately learn from your mistakes.

The last tip I have is to push yourself in your research often. This usually means reading blogs and opensource projects containing advanced topics and problems about your chosen subject. You will almost certainly run into terms, algorithms, techniques, and ideas you will need to know in the future. Bookmark anything that jumps out at you, and maybe try to gather enough understanding to write a one paragraph summary of it (for your own personal future reference). It's good to get that first meeting out of the way so you're ready to start building recognition the next time you see them.
