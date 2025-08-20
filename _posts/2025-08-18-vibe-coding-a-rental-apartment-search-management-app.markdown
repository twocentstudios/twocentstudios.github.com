---
layout: post
title: Vibe Coding a Rental Apartment Search Management App
date: 2025-08-18 17:46:25
tags: claude web react typescript vibecoding
---

I've been apartment hunting here in the Tokyo-area with my girlfriend. We've been sending links to various rental property listings back and forth in LINE (messaging app) and emailing with brokers. In a chat interface, it was hard keeping up with the status of each of the properties we'd seen, we wanted to see, we'd inquired about, etc. Classic project management problem.

{% caption_img /images/bukkenlist-suumo-listing-example.jpg h400 Example SUUMO property listing page slightly edited for clarity %}

I decided to skip the step of putting each property into a shared spreadsheet and jump straight to vibe coding a web app with Claude Code. I've never worked on a full-stack TypeScript app before, and my impression is that LLMs are most proficient at it, so that's what I went with.

{% caption_img /images/bukkenlist-finished-desktop-interface.jpg h400 Finished desktop interface for Bukkenlist %}

My goal was to create a shared space where we could keep track of the status of listings, add new ones easily, do calculations like 2-year amortized cost, keep a notes and ratings field for each of us, see all the salient points of a property at a glance, and archive properties that we decide against or are already taken.

After a day of work, it supported scraping SUUMO listings and worked on mobile and desktop web. Another 2 half-days of work and it supports 4 listing sites, maps, expired listings, and English/Japanese localization. I called it Bukkenlist 物件リスト.

{% caption_img /images/bukkenlist-day1-and-final-comparison.jpg h400 App progression from end of day 1 (left) to final polished version (right) - there's not much visual difference %}

This was "vibe coding" in the customary definition of "not looking at the generated code at all". I see the code scrolling past in the terminal window but I'm letting Claude commit it after I check that the rendered result looks and works as intended in the browser window. For this project, I'm playing the role of product manager and QA engineer. However, I did make the decisions about using SQLite for storage, the schema, and the deployment strategy. And I helped Claude dig itself out of holes in the way only an engineer can.

**The TL;DR:** In 2 working days I produced a completely functional web app with much better usability than the spreadsheet it would compete with. Using an AI tool like Claude Code aimed at professionals, it's hard for me to imagine someone with no coding background being able to get to the same finish line I did. But with the existing cadre of no-code AI tools, perhaps this would be a perfectly scoped project.

## The full development process

I have a Claude Code $100/mo Max subscription. I used the pattern of using "plan mode" with Opus aggressively to ensure proper context gathering and then "accept edits" mode with Sonnet to execute the plan. These were long sessions, so I actually blew through my usage limits once or twice with 1 or 2 hours remaining (with my usual Swift projects I hadn't hit the Max limit for Sonnet before). At those times, I switched over to the nascent OpenAI Codex CLI (with a $20/mo Pro plan) to see how it did. Everything about Codex still feels months behind Claude Code, but it did handle some of the tasks I threw at it well enough.

### Day 1

Learning from some [past experiments](/2025/06/22/vinylogue-swift-rewrite/), I decided this time to be more intentional with my initial getting-started prompts. I didn't dump my entire vision for the app onto the model and have it create a full product requirements doc and phase-by-phase development plan. I thought staying in the loop would ensure the best chance of success and even minor scalability. 

SUUMO listing scraping was the most risky part, so I had it start by creating some infrastructure around fetching and parsing the HTML for a few example listings and comparing the results with the values I'd plucked out by hand. 

{% caption_img /images/bukkenlist-console-parsing-results.jpg h400 Console showing results from the initial SUUMO listing parsing %}

Only after the parsing seemed relatively robust did I have Claude create the initial structure of the Express.js backend and React frontend. It used VITE but I only sort of know what role that plays. The first renderable version was a text field for the SUUMO URL, a submit button, and then a list of the keys and values parsed out.

{% caption_img /images/bukkenlist-first-working-interface.jpg h400 First working interface with URL input field and parsed listing key/values %}

Then it was time to add persistence. This was the part where I *should* have first decided on hosting, got that set up, *then* decided on the most low maintenance storage solution. Instead, I chose SQLite, which I've been interested in lately and have [already deployed](/2025/07/02/swift-vapor-fly-io-sqlite-config/) successfully on Fly.io.

With my engineer hat on, I made the initial decision to have Claude go with a mixed schema-less approach, storing a generous amount of metadata about each property in named columns, but then having a dumping ground JSON column with all the parsed key/value data. Hard to say whether that's made my life easier or harder while adding new listing sources. For a personal project with 2 users, I think it was a fine decision. For a real production site, I can already tell it would be a nightmare to maintain.

```
# Final schema of the `scrapes` table
     cid  name           type     notnull  dflt_value  pk
     ---  -------------  -------  -------  ----------  --
     0    id             INTEGER  0                    1
     1    url            TEXT     1                    0
     2    property_name  TEXT     0                    0
     3    scraped_data   TEXT     1                    0
     4    created_at     INTEGER  1                    0
     5    status         TEXT     0                    0
     6    archived       INTEGER  1        0           0
     7    kiyoko_notes   TEXT     0                    0
     8    chris_notes    TEXT     0                    0
     9    kiyoko_rating  INTEGER  0                    0
     10   chris_rating   INTEGER  0                    0
     11   source_site    TEXT     1        'suumo'     0
     12   color_id       TEXT     0                    0
     13   latitude       REAL     0                    0
     14   longitude      REAL     0                    0
     15   expired        INTEGER  1        0           0
 ```

From there I had Claude build out the master/detail list in desktop mode. It had little trouble putting together a passible design.

{% caption_img /images/bukkenlist-initial-master-detail-view.jpg h400 Initial master-detail interface showing property list and selected property detail %}

I added delete and refresh support since those were helpful in manual testing. Refresh should re-run the scraping and parsing and replace all the fields with the freshly parsed content.

Then it was kind of the fun part: pushing around the fields in the UI to make it more pretty and readable.

Next I had to add image carousel support which was surprisingly easy. I prompted Claude to do some extra research for best practices before deciding on a solution.

{% caption_img /images/bukkenlist-ui-reorganizing-carousel.jpg h400 Reorganized UI with image carousel %}

I added deterministic unique color generation for each property based on its unique ID mapped to a hue value 0-359 in HSV. I use this technique often in projects as a nice touch to make resources easier to identify.

{% caption_img /images/bukkenlist-color-id-support.jpg h400 Properties with unique color IDs for intuitive identification %}

I can't sightread Japanese as fast as I can English, so I had Claude add full UI localization in both English and Japanese to the entire app and have it save the preference in local storage. This helped speed up QA of parser errors going forward.

{% caption_img /images/bukkenlist-localization-support.jpg h400 English/Japanese localization toggle %}

I wanted to highlight the at-a-glance parts each property that were especially important to the two of us, so I added those in big font next to the image carousel.

{% caption_img /images/bukkenlist-at-a-glance-properties.jpg h400 First version of the at-a-glance property details %}

From here it was a lot of polish. I felt like I was in full product manager flow-state, just picking off the next obvious change in the UI and prompting Claude to have a go at it.

The whole point of the app was to facilitate our apartment search process, which ultimately meant appending our own information to listings. I added an open-ended status field to track things like "requested viewing" or "viewing on 8/24". I added an open-ended notes field for each of us, then a 4-level rating system. In the notes field, we've been adding merits/demerits. The rating system is an easy way to clearly communicate our enthusiasm towards each property and see it at a glance in the sidebar.

{% caption_img /images/bukkenlist-notes-and-ratings.jpg h400 First version of the notes and rating system for each (hardcoded) user %}

A cool feature I'd very loosely prototyped with a single ChatGPT query a few days previously was an "amortized cost" field, calculated from several fields. There are so many disparate fees for each listing (monthly rent, management fees, security deposit, key money, parking fee, etc.) that it's hard to do an apples-to-apples comparison of how expensive properties actually are. It's elementary school math, but just annoying to do.

It was pretty simple to add this field: parse out the semantic values, multiply the monthly costs by the lease term, add the one-time costs, then divide by the lease term to get the overall monthly cost.

{% caption_img /images/bukkenlist-all-in-cost.jpg h400 Amortized cost calculation for true monthly expense comparison %}

I was on the fence about whether to build out a full user table and authentication system. It may have been worth seeing whether Claude could have one-shotted multi-user support. Instead, I opted for a simple password auth and full editing support for any field. I'm pretty happy with this solution and proud of myself for not going overboard on the spec. It's much easier to share a single password than deal with a create account flow on multiple devices or while on the go. I set some strict rate limits for password attempts and page requests in general and know that if the site gets hacked and trashed somehow it's not a huge deal.

{% caption_img /images/bukkenlist-login-screen.jpg h400 Simple password login screen to gate the whole app %}

It was finally time for deployment! I was definitely procrastinating on this, but I wanted to get it online before I went to bed.

Looking into some of the common free hosting services that target JS, I realized Vercel was serverless and I'd need a different solution for the SQLite storage. I could have tried Turso for SQLite hosting, but signing up for 2 services felt like too much complexity. I went back to Fly.io since I have some experience with them and an existing account and all the CLI stuff installed.

Claude was happy to set up all the deployment stuff and mostly one-shotted it. The big issue came with my underlying scraping implementation. Scraping was based on [Playwright](https://playwright.dev/) which needs to spin up a full Chromium instance and that takes 10+ seconds on a 2 GB machine. I have aggressive suspension set for my Fly.io instances which means this heavy startup cost needs to be paid every time a new listing is added. I also didn't want to pay for a full 2 GB machine on Fly.

I started another vibe spike to replace Playwright with Puppeteer and a lighter Chromium fork based on [this guide](https://vercel.com/guides/deploying-puppeteer-with-nextjs-on-vercel) from Vercel. With a lot of trial and error (including rewriting the parser), I got the memory requirement down to 512 MB at the cost of 30+ second scraping.

At this point, I took a step back and thought about whether I actually needed a full Chromium-based scraper. After all, I'd never actually verified whether these sites were doing enough JS rendering to require it. I don't have a lot of experience with scrapers and this project was an attempt to fix that. I had Claude do yet another spike with some initial research as to what the most common tools were for low-resource scraping and it chose [JSDOM](https://github.com/jsdom/jsdom). After rewriting the parser yet again, it turned out this worked fine and was super fast and easily deployable to a tiny 256 MB machine.

If I'd have tried deploying immediately after finishing the very first version of the scraper, I'd have had a much easier time. But I also realized I wouldn't have had much invested at this point, and my motivation to continue may not have survived this deployment slog. An interesting paradox! In theory I would have saved hours, but in practice I may not have shipped anything. It's also possible I would have chosen a different deployment service that affected my choice of persistence solution, etc. Decision ordering really matters, and I'm trying to get better at it. But also, LLMs make spikes, backtracking, and rewrites so low-cost/low-effort that as long as you're willing to ignore sunk costs and your motivation survives you can end up with much more optimal solutions in the long run.

{% caption_img /images/bukkenlist-deployed-production-end-day1.jpg h400 App successfully deployed to production at the end of day 1 (Japanese interface) %}

My first commit was 4pm on Saturday and my last commit before going to sleep was 6am Sunday. I'd (re)watched 3 seasons of Silicon Valley in the background. I sent my girlfriend a link and the password and went to bed.

## Day 2 & 3

I woke up a couple hours later and made pancakes and got a message from my girlfriend with links to listings from 2 other services. So it was time to add support for more listing sources!

I had Claude do a refactor of the scraper in preparation for adding multi-service support. Again, this was vibe coding so I had no idea how well it did, but I trusted it. This took about an hour. I gave it a link to a new listing and had it run its scraping parsing iterative procedure to write an initial version of the parser. According to the git logs it took about an hour to write the two new scrapers and a guide for itself for writing future scrapers.

{% caption_img /images/bukkenlist-multi-source-support.jpg h300 Multi-source support showing listings from different rental websites %}

I realized the two of us would need to use my new site from our iPhones, so I added mobile support. This was way way faster than I expected. It took a bit more Claude coercing the next day to get it fully optimized, but the first attempt was definitely usable.

{% caption_img /images/bukkenlist-initial-mobile-interface.jpg h400 Initial mobile interface with separate property list screen (left) and property detail screen (right) %}

Sunday was a half-day. On Monday, I put in another half-day optimizing the mobile layout, adding another source, adding listing expiry support, maps support, and deep linking support.

Maps support was actually the most difficult single-feature I'd vibe coded for the whole project. Scraping the coordinates for a listing wasn't too bad, but deciding on the maps provider and implementation was difficult.

At first, I was planning on rendering out a static map image on the backend during property add because it seemed simplest and lowest cost. But since I already have an Apple Developer account, using the MapKit JS API was free so I went with that.

Turns out that Claude had a pretty awful time integrating the MapKit JS library. This is where I ran into a lot of frustration with vibe coding and not having any idea how React works, how JS library loading should work, how environment variables work on the client side, how JS library token authorization should work, and more. I was in thrashing mode with Claude, watching it implement "fixes" that seemed dubious even to me, a JS novice, and inevitably did not work at all.

I had to get a lot more hands on and spent a long dev cycle restarting the dev server, deploying to production over and over, copying and pasting browser console logs, and adding and removing secrets from the Fly.io admin page.

In the end, we got it working, but it's hard for me to say *why* Claude struggled so hard with this particular task and how I could have approached it differently.

{% caption_img /images/bukkenlist-maps-support.jpg h400 Map showing the property location and its relationship to closest station %}

## Iteration loop workflow

For my overall development experience, the local build and serve process was more effortless than iOS, but I found Claude's new background Bash processes feature frustrating. 

Claude would write some code, start a background server, test the code by making some calls to the server, make some code changes, then not realize that the server needed to be restarted and get stuck in a "why isn't the output changing" loop. I'd need to keep an eye out for this and intervene. 

After a while I took control of starting/stopping the dev server in a separate terminal window, but Claude would ignore this and keep trying to do its own thing. If I was working on this full time I would certainly spend some time making this flow more efficient. I dealt with the paper cuts.

## Final thoughts

We still have at least a few weeks left in the apartment hunting process. The less we need to use this app the happier I will be.

For the time investment, I'd consider this app overkill. It's useful individually, but for a production app it wouldn't work as scraping is presumably against the TOSes. The parsing is sloppy. There's no user account system. There's no sharing system. There's no base SaaS functionality. Even individually, it would have taken a lot less time to simply enter the key fields into a spreadsheet manually.

But this was a good experience seeing how feasible vibe coding is for someone with my background. There were several points in the process where I hit that beautiful flow state and really loved it. But there were also stretches where Claude was thrashing and I was losing my patience. Or when I was the tool of the LLM clicking boxes in admin panels or doing visual QA while it was doing the interesting architecture and coding tasks.

One thing's for certain: I never would have attempted a project like this without an LLM agent. If I did, I probably would have lost motivation after finishing the first scraper. I probably would have used a technology I already knew even if it was not the most prudent choice in 2025.

I'd like to try some of the more "batteries included" vibe coding environments (e.g. Lovable, Bolt, Replit, V0) to do a similarly scoped project in the near future. I'm most comfortable with Claude Code at the moment because I'm used to the freedom + sharp edges combination. But it's hard for me to imagine a non-programmer or even a junior programmer being able to dig themselves out of the holes I found myself in a few times. There's just a *lot* to know still to get an MVP designed, developed, and deployed.

I can see how using a vibe coding environment with less freedom but more well-paved integrations could prevent dead-ends and thrashing and bad developer experience. Maybe within the year both Claude Code and the vibe coding platforms will have converged into providing decent enough support for users of any background.

