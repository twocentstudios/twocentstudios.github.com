---
layout: post
title: Indie Game Devlog 00
date: 2024-03-09 14:17:22
image:
---

As of last month, I've started making a narrative indie game.

## Long sidebar about starting projects

Starting new projects at this stage of my life/career carries a duality.

On one hand, it's easier than it's ever been. I have 2 decades of compounding knowledge, both general and specific to starting and finishing projects. I can see the future better than I've ever been able to. I can divide up a project into checkpoints, checkpoints into sub-checkpoints, sub-checkpoints into tasks, tasks into sub-tasks. I know that I need to pace myself. I know I need to measure out my initial motivation, and find new sources of motivation along the journey to keep me going.

On the other hand, it's harder than it's ever been. My experience has given me scar tissue. I'm more risk averse due to past failures. Not wanting to repeat past mistakes nudges me away from paths that may have cleared since I encountered them blocked. I don't have the energy of relative youth. Having an accurate prediction of the arduousness of the project intimidates me from starting. Being a self-supporting adult carries its own societal expectations of how I should be spending my working years.

All this is to say I've started a new project.

The me of long past would have announced my project long before I wrote the first word, typed the first line of code, drew the first line. The me now knows himself well enough to know that it's equal odds that I lose interest and give up on the project before I have anything to show the world.

Luckily, I've made it to that first early checkpoint in this project! Far enough at least that I feel I can write this devlog in good conscience.

## My History with Games

This section's going to be self-indulgent. I think it's useful for me to take a look back at what experiences have contributed to my desire to start this over-ambitious project.

Watching a lot of [Noclip](https://www.youtube.com/@NoclipDocs) game documentaries lately, it feels like the vast majority of game devs who have hit the level of success you need to get a documentary made about you are people who starting making games almost as early as they started playing them.

I can't really say I fall into that former category. I have in my own way always loved video games, but usually as a distraction to other pursuits like music and art. I played some of the early NES games at my aunt and uncle's house. My parents wouldn't let me have a tv-bound console at home, but they did let my brother and I share a Game Boy for our bi-monthly car trips to see our grandparents.

I was in elementary school at the time and [Zelda: Link's Awakening](https://en.wikipedia.org/wiki/The_Legend_of_Zelda:_Link%27s_Awakening) drove my first game design attempt. My neighborhood friend and I drew our own dungeon designs with pencil and paper. We distributed keys and locked doors. Placed enemies and boss rooms. Doodled inelegantly. Of course, we didn't really know how to take things any further than crude drawings at this point.

Later in this era, I'd say the other games that left an impact on me were [Zelda: Ocarina of Time](https://en.wikipedia.org/wiki/The_Legend_of_Zelda:_Ocarina_of_Time), [Super Mario 64](https://en.wikipedia.org/wiki/Super_Mario_64), [Golden Eye 007](https://en.wikipedia.org/wiki/GoldenEye_007_(1997_video_game)), and [Half-Life](https://en.wikipedia.org/wiki/Half-Life_(video_game)). For most of my life, how 3D games worked was a complete mystery to me. Everything from 3D modeling to textures to cameras to networking.

I started programming for real with my [TI-83+ graphing calculator](https://en.wikipedia.org/wiki/TI-83_series) in middle school. I made some really simple games with the [TI-BASIC](https://en.wikipedia.org/wiki/TI-BASIC) language. There were some understandable limitations programming on a calculator for a 1-bit black & white screen. But this prepared me for using Visual Basic 6 and then C++ in freshman and sophomore year of high school. My final project in the C++ class was a mini-golf game that printed ASCII to the command line. I think the inspiration for that was a mini-golf game I would play on my mom's flip phone.

In this era my game playing was more social and recreational: [Team Fortress Classic (TFC)](https://en.wikipedia.org/wiki/Team_Fortress_Classic) on PC and [Halo 2](https://en.wikipedia.org/wiki/Halo_2#Multiplayer) multiplayer on Xbox. Although I played Adobe/Macromedia Flash games in this era, I never went beyond the short movie making into ActionScript. I never got into the very popular modding scene for TFC/Half-Life. Choosing either of those hobbies instead of making music throughout high school probably could have pushed me into game programming or computer science in college instead of electrical/computer engineering.

After college I continued to dabble in games when I had access to them. I played a few subsequent Zelda-series games. Some first person shooters. [Resident Evil 4](https://en.wikipedia.org/wiki/Resident_Evil_4) definitely left a big impression on me.

I remember when the indie game golden age started. A friend of mine showed our group [Castle Crashers](https://en.wikipedia.org/wiki/Castle_Crashers) one night while we were hanging out. He even supported the fledging [Ouya](https://en.wikipedia.org/wiki/Ouya) console Kickstarter. We watched the very well produced [Indie Game The Movie](https://buy.indiegamethemovie.com/). I love this movie for how well it illustrates the human condition of creating things. However, the lack of pulling-back-the-curtain segments regarding design or development combined with the scary numbers of 5+ (gasp) years it took to make those games probably scared me off from attempting a game.

I bought the Humble Indie Bundle V including [Braid](https://en.wikipedia.org/wiki/Braid_(video_game)), [Super Meat Boy](https://en.wikipedia.org/wiki/Super_Meat_Boy), and [Sword & Sworcery](https://en.wikipedia.org/wiki/Superbrothers:_Sword_%26_Sworcery_EP). At that time I was pushing hard into my career change from electrical engineer to iOS engineer. Game dev, even at the indie level, was still a mystery to me.

2 other games I played in that era deeply affected my design sensibilities: [Gone Home](https://en.wikipedia.org/wiki/Gone_Home) and [Bioshock Infinite](https://en.wikipedia.org/wiki/BioShock_Infinite). 

A friend of mine was raving on Twitter about how well done Gone Home was, so on a whim I bought it and played it through in one sitting. I remember expecting something completely different; after all, it had all the initial trappings of an FPS horror game. Upon finishing it, I remember liking the story, but being disappointed simply due to my expectations. At the time, a "game" had a certain definition to me. Gone Home broke that mold, and seemingly paved the way for hundreds of other innovative games since.

Bioshock Infinite had the initial trappings of classic AAA FPS gameplay, but the story felt deeper and more ambitious than anything I'd played up to then. [The Last of Us](https://en.wikipedia.org/wiki/The_Last_of_Us) series pushed that boundary even further.

My next era of gaming was getting a Switch and a one-generation-behind PS4. Of course, Nintendo continued to knock it out of the park with [Mario Odyssey](https://en.wikipedia.org/wiki/Super_Mario_Odyssey) and [Zelda: Breath of the Wild](https://en.wikipedia.org/wiki/The_Legend_of_Zelda:_Breath_of_the_Wild). But the story of me finally having the courage to start my own indie game starts to get back on track during the pandemic.

I played [Firewatch](https://en.wikipedia.org/wiki/Firewatch) based on some glowing Twitter reviews and beautiful concept art. I played it through in maybe two sittings and enjoyed it enough to start digging into the making-of Game Developer Conference (GDC) talks. I continued pulling the thread on the GDC talks and learning more about all facets of game development from a interested spectator's point of view.

I then played [A Short Hike](https://en.wikipedia.org/wiki/A_Short_Hike) – again, probably based on a swell of Twitter reviews. I absolutely adored the game. With this game, the "shortness" of the game finally hit me as a positive choice. It suddenly felt like a massive competitive advantage that you could make something so easily digestible yet impactful.

But it wasn't until I found A Short Hike's developer's 30 minute [making-of GDC talk](https://www.youtube.com/watch?v=ZW8gWgpptI8) that pushed me to take the first false step into game dev. The talk succinctly mixed the backstory, trials, and crucially the technology and art behind the game in a way that finally felt accessible to me. And even though Adam obviously has years of very specific game dev experience, the fact that the initial release timeline of the game was 3 months made the idea of game dev feel attainable as long as the scope was limited.

After watching Adam's talk, I sat down and wrote a one-pager concept for an indie game. The plot and mechanics were both very amorphous and very ambitious. I didn't look at that document again until recently, but the idea itself stuck in my head well enough.

Fast forward a few years. I've played through many more reasonably apportioned indie games recently. [Old Man's Journey](https://en.wikipedia.org/wiki/Old_Man%27s_Journey) was beautifully illustrated with a wholesome story. The [Frog Detective](https://en.wikipedia.org/wiki/The_Haunted_Island,_a_Frog_Detective_Game) saga was simple and written with so much personality. [Genesis Noir](https://en.wikipedia.org/wiki/Genesis_Noir) was unique and stunning and avant-garde. [Untitled Goose Game](https://en.wikipedia.org/wiki/Untitled_Goose_Game) perfected a highly playable concept. [Return of the Obra Dinn](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn) was mind bending and unbelievably well crafted. [Tunic](https://en.wikipedia.org/wiki/Tunic_(video_game))'s art, story, and mechanics left me in awe that a nearly solo team could create something so polished.

I've ever so slowly been soaking in game design, with each new game pushing my curiosity further. I finally feel like I understand the scope of an indie game well enough that it might be possible to make one.

## The story I want to tell

I went on a ski trip recently with an old friend. There's plenty of time to chat on slopes, and we got far enough into game talk that I pitched that early version of the game I'd one-paged a few years ago. I think it was this mental exercise that finally made things click for me.

After sampling all these small, one-or-two-sitting indie games over the years with varying balances of story/mechanics/art, I finally understood how I actually wanted to combine all the pieces.

I like great-feeling mechanics as much as the next gamer, but I've never felt a particular affinity towards deriving the subtleties of a great platformer or endless runner. I never really got into fighting games. FPSes are so subtly different from one another that I can't imagine I'd ever have a unique take on them. Turn-based RPGs bore me. I find crafting and management systems tedious. I'm rarely in the mood for the mental overhead of pure puzzle games. There's whole classes of other games that simply can't be made by small teams. (Sidebar: I think I've always loved Zelda games because they have a little bit of all the above game types, and they do it all very well).

What I do love is good stories, dimensional characters, and insightful dialog. I'm particularly drawn to TV drama-length stories (6-12 hour-long episodes) that have time to breathe and develop their characters. I've loved great narratives told through mechanics-light games. Where you can explore at your leisure, talk to characters non-linearly, and otherwise experience a story in ways arguably deeper than you can with traditional media.

I think what I'm 1. most currently interested in and 2. most currently capable of is a heavily narrative focused game. It should be short, but draw the player into the world enough to have them emotionally moved by the end. The story, characters, environments, and dialog must carry the entire enterprise. The second most important part has to be the art and animations. Finally, I won't specifically focus on perfecting any classic game mechanics. But I do want something unique that fits deeply into the story.

The idea from my one-pager was an overly ambitious, sprawling narrative that covered my experience building a local rock band through my high school years. When I finally forced myself to sit down and consider making a game seriously as a solo dev, the constraints immediately gave this original idea four walls to sit within. Instead of four years of narrative, the story would take place over one night. All of the sudden, the theme and the conflicts of the story started to form. All the autobiographical details started falling into their fictional places.

I started adding to a new one-pager over the course of a few weeks while working on other projects. Each day I'd get out of the shower with a dozen new ideas to dump into the document. In my head I started to see the arcs, the set, the characters, parts of the game play. It's since grown to 5000 words.

## What skills do I need to tell the story?

Looking at all the game-related titles in the scrolling credits of a AAA game is daunting to say the least.

Part of my planning was making a list of all the roles and going through them one-by-one to evaluate whether I knew them, knew enough to be dangerous, could learn them, or could reasonably ask someone for help.

#### Writing

I'm not particularly versed in writing fiction, but it's always something I've wanted to do.

#### Art

I've never considered myself an artist, but about 4 years ago I started to seriously make the rounds of trying my hand at several art styles.

First it was rotoscope animation with various software, then digital painting, then 3D modeling, then 3D set design, then basics of shaders, then 3D character design, then 3D character modeling/rigging/animation.

I sort of accidentally learned a lot of the required disciplines and software required to make a 2D or 3D game.

#### Programming

I've been programming professionally for over a decade, but almost exclusively outside the realm of games and game engines. My programming knowledge is completely adjacent to game programming, but I feel relatively confident I can pick up what I need both quickly and then gradually as required.

I don't think my game will be doing anything particularly innovative that will require inventing new levels of physics simulation. I'm hoping base game engine functionality, off-the-shelf plugins, and tutorial code will get me 90% of the way there.

#### Sound

I've been writing, recording, and performing music since middle school (it's what the game is about after all). I have some confidence I can adapt these skills to a passible level for the game. However, I'm still a bit worried about sound effects and foley.

#### Marketing

Marketing is my biggest weakness for sure. I wish I could say I already have a solid plan for how I'm going to stand out amongst the dozens or hundreds or whatever games released every day. But honestly, the best I have right now is to start writing and posting stuff like this blog ASAP and start getting the artwork looking attractive ASAP. In the meantime, I've been watching a lot of GDC talks about marketing specifically and trying to internalize the good habits required to make what I make a success.

## What is success though?

I thought a lot about this before I officially drew my line in the sand and said "now's the time I make a game".

The naive part of me wants superficial success: lots of downloads, a chunk of cash (to fund whatever's next), a splash of notoriety (to kickstart interest in whatever's next). But I think I have some more sustainable and genuine definitions of success that aren't so binary. And they also leave so room to cut my losses logically and sunk my costs if that's the right move.

My main measure of success is to make a piece of art that I'm proud of. Like all successful art, I want the game to express something about me that I can't through other media.

The next measure of success will be to gain a new appreciation of the games I have and will play. Even in these early stages, I've already learned enough to appreciate the subtle differences between 3rd person controller mechanics, PS1-era texturing, and sprawling narrative trees in my favorite games. There's nothing quite like making your own art to gain a deeper appreciation of how your favorite art is made.

Finally, the games community is almost by definition full of passionate artists who make things for the same reasons I do. I want to meet more of these people and hopefully work with some of them on whatever the next big project might be.

## Conclusion

So that's the entire story so far. In the next devlog I'll share my process of making version 0.1 of the game, and where I think it'll go next.
