---
layout: post
title: "Timehop: A Retrospective"
date: 2015-11-03 12:19:53
---

I worked at [Timehop](http://timehop.com) as an iOS Engineer for almost two and a half years. The experience meant a lot to me both personally and professionally, and I believe it set me on the right course for my future in this industry.

Here are a few thoughts I have about what I learned along the way. Granted, most of them are the kind of lessons you come across every other day in Medium posts from those in the industry, but it feels important to have lived them first hand.

## Shipping

> There are a million reasons not to ship... but you have to ship anyway.

My most important lesson was learning to scope down to the bare essentials and compromise on bugs. It's easier to argue for project scope than it is for whether a bug is a "show-stopper", but it's important to always have the idea of shipping resting heavily on your shoulders pushing you to make the hard decisions.

Over time I got a lot better at understanding how design and engineering decisions affect scope and shipping schedules. Most of that is gained with experience. When you're first starting out, coming up with one solution to an engineering problem is cause for celebration. But when you need to get that feature out the door in two weeks instead of two months, that's when as an engineer, you need to have three potential solutions in your head and understand the cost/benefit for each. Then, you need to communicate those concerns clearly to the rest of the team so that everyone is on the same page with the tradeoffs that have to be made.

> "I can get a prototype out to our beta group in three days, but if it's successful, I'll need to more or less start over with an alternate implementation to make it scale to the rest of our user base. Is that acceptable?"

A simple example of this that came up time and again was receiving designs for custom views and components that worked just slightly differently than the standard iOS components. I would have to evaluate each component, create a time estimate, then report back to the product manager and tell them, "hey, this navigation paradigm is slick, but it will stick out like a sore thumb from the rest of our app and I can ship two days faster by using a built-in component. Are you sure you want to do it this way?" Some of the time, the answer would be, "No, it doesn't affect the core user experience enough to warrant the delay." The remainder of the time, it would be, "It's worth it. Our hunch is that the navigation will significantly affect uptake of the feature."

Of course, that hunch is a gamble. Which leads me to instincts.

## Product Instincts

Your product instincts will get better with time. What I mean by instincts is your ability to predict the behavior of a diverse and statistically significant amount of people in response to your product or feature (note: your group of close friends is probably not diverse or statistically significant enough). How will they use it? How long will they use it for? Will they use it like you predict they will? Will they even use it at all?

> Your product instincts will get better with time... but only if you set up your experiments correctly and are brutally honest with yourself.

It's natural to think of product instinct as something "you have or you don't". Psychology and sociology are sciences though, and I believe that applying the scientific method to product can lead to better outcomes for users and for those learning from the results.

It is absolutely more difficult to design a product experience in a way that is based in a few key hypotheses, facilitates the collection of analytics data, and uses that data to ultimately prove or disprove the original hypotheses. **Without this process product development is simply taking disparate stabs in the dark and crossing your fingers that you'll hit some abstract goal.** Not only is it impossible to iterate effectively, it also denies the chance to learn from the outcome of an experiment and improve the instincts of the entire team. 

> "I predicted that users would tap the 'Follow All' button 60% of the time, but after one week of data collection it's only at 15%. I can now begin to ask the next questions such as 'do users understand the value of following others?' or 'do users just not see the button?'."

Forcing yourself and the rest of the product team to make hypotheses isn't about seeing who was right and wrong at the end of the experiment. It's not a competition. It's about forcing yourself to take all of your collective experience into account (and hopefully your direct experience from previous experiments) and draw a line in the sand. It's all too easy to forget your original hunches when the analytics numbers start rolling in, and by then you've missed a great opportunity to adjust your internal biases. 

More often than not, goals of your product experiments will fail and *that's okay*. You've learned something. The worst thing you can do is to sweep your failures under the rug. By ignoring failures, you'll be skipping the most important part of the iteration process: the part where you don't repeat your mistakes. When you don't learn from your experiments, each product cycle will be like starting from scratch, never progressing.

## Making Mistakes

Ultimately, someone has decide where to start and what path to take from there. As much as a meme the "idea person" has become, leading a product takes legitimate effort. Sustaining the product development cadence can be brutal and unforgiving (especially if you look at it as taking alternating stabs in the dark, which you shouldn't). Always having the right idea ready to go at the right time is something I respect greatly.

When I started at Timehop, my primary goal was to improve my craft of iOS development. Having a new feature spec'd out, designed up, and ready to implement is great for that. There were never a shortage of ideas, and thus there was always interesting development work to do. I've touched what feels like a dozen disparate iOS frameworks over my tenure, gaining a breadth of knowledge because I was pushed to implement features that on my own I would have judged to be too time consuming or too far out of my comfort zone.

On the flip side though, I only got a few chances to put my own ideas to the test. For those few chances, I am undoubtedly grateful. However, the rush of nurturing an idea from start to finish is an intoxicating feeling, one that I started to miss dearly as the day to day became implementing feature after feature. It was ultimately the desire to make my own mistakes that nudged me out the door.

> No one has all the answers. No one really knows what they're doing.

I participated in dozens and dozens of product experiments. Features that were pitched as sure wins often failed the hardest. Features that were incremental improvements or minor changes in response to something as innocuous as required Apple API deprecations sometimes produced our largest user influxes. At some point you have to come to terms with knowing that no one has all the answers and you have to brace yourself for a bumpy ride.

## The People

My favorite part about coming into work every day was working with such an amazing team of people. Team Timehop was both fun and talented, and inspired me to do some of my best work.

It was an honor to be part of something that brings joy to the lives of millions of people.