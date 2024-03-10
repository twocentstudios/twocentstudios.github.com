---
layout: post
title: Indie Game Devlog 01
date: 2024-03-10 18:17:22
image: 
draft: true
---

I'm making an indie game about a high school rock band playing a show and trying to decide their future.

(Yes, I'm practicing my pitch already, and yes, I realize it still has a ways to go, haha.)

As briefly mentioned in the last devlog, this idea started as the kernel of something similar a few years ago. The bones of the story are autobiographical, but the night the game takes place will be completely fictional.

## Planning

Over the course of a few weeks, I started filling up a document with various ideas about the game while I was working on other projects.

The first three decisions were:

1. what genre of game I wanted to make 
2. what scope could I reasonably target as a self-funded solo developer
3. what unique things can I bring to the table

These three decisions are inexorably linked. After all, 60-hour FPSes are out of reach. I don't have any unique takes on the tower defense genre, nor would I sign myself up to playtest my own version for hundreds of hours.

Beautifully-rendered narrative games with a few puzzles and a few fetch quests seem to be the most fitting of my requirements.

My background is in making music and playing in bands, specifically rock bands below the mainstream. This hobby has a humble but steady following over the last two or three decades. And although stories about the underground music scene pop up from time to time in the mainstream (see: Scott Pilgrim, High Fidelity, School of Rock, Nick & Nora's Infinite Playlist), in the video game world they're mostly non-existent. Plenty of games have great soundtracks, but music-focused games are overrepresented as rhythm games.

I realized I'd love to write a story about what it was like to be in the local music scene of my Chicago-suburb. There was plenty of inter-band and inter-personal drama, plenty of growing-up happening, and plenty of ambitions to share our music more broadly. Telling this story over one night would keep the scope naturally small. There'd be plenty of major and minor characters at a show to guide the narrative. The entire game could take place in a small music venue; an interesting environment that doesn't require acres of forest or building out entire cities.

There is plenty of prior art for narrative games. And at first I was ready to commit to something with literally zero unique game mechanics besides walking around and talking to NPCs in some order. However, as I get further along, I'm starting to think I may need at least a few unique mechanics or minigames to ensure the pacing feels right.

And speaking of pacing, once the story beats were roughed out, I realized I could divide the story up in a way where I could make the first vertical slice in a somewhat economical way. Sure, the intro act will require me to model the whole venue, but not all the characters, nor write all the dialog.

So my decisions were mostly made:

1. I'll make a narrative game with some light mechanics and mini games and free exploration within a limited environment
2. The game will be scoped to mostly one building, with a few acts with gradually expanding scope
3. The story and art will be the unique parts

## Story

I've modeled my story arc as several conflicts. There's a main overarching conflict that's somewhat abstract but intended to be the most gratifying when it's resolved. Then there are several smaller conflicts that drive the plot and player motivation from the beginning of the game to the end.

My goal in writing the intro scene was to introduce each of these conflicts amongst the characters that are involved. This will hopefully give the player motivation to keep playing to see how each conflict is resolved.

The player will have a fair amount of agency in exploring the story and getting to the end, although my ambitions are not to have serious narrative branching or multiple endings as a key differentiator. The player freedom makes it easier and harder to craft a cohesive narrative than a book or movie. Movies require very tight writing and plot progression, a skill I do not possess yet. Games with loose writing are more forgivable because the narrative is broken up between (interesting) gameplay.

I have a list of key characters. And a list of optional characters I may need to introduce in order to provide some insight to the main character regarding the overarching conflict.

There are several off-the-shelf tools for making narrative games or just branching dialogue. The first step was to pick any sort of dialogue system that could spit out an HTML game-like experience and start writing. After all, it wouldn't make any sense to do any art or game engine research if I didn't know what story I'd be supporting.

I chose Yarnspinner at first (although I eventually ported away from it). Writing the first few scenes was super helpful in falling into a bunch of more ambiguous decisions without having to think about them much. I started to naturally write characters a certain way. The story beats started to naturally flow in and out of the dialogue. It was obvious what order the scenes needed to progress. And the end of the intro act also fell into place.

I've never really written screenplay-type dialogue before so writing a half-dozen scenes took a few days. I also decided not spend any time up front nailing down character names, instead using the names these characters were based on. This has been helpful in keeping track of the characters in my head.

Using the Yarnspinner plugins, I could step through the dialogue like I was playing a game and see how it felt. I modeled the player walking around and choosing a character to speak to as a simple dialogue menu of choices with the built-in functionality.

## Game engine

I chose Godot for a few reasons. If I'd have started this project a year ago, Unity would be the easy choice. I even have a little experience working in Unity for an augmented reality project. However, after the big Unity pricing and licensing debacle of 2023, it seemed like not a stable way to move forward.

I'd seen a lot of support for Godot on social media over that time period, and the kind of games that seemed possible to make fell well within my ambitions. Plus, I knew if I had to put down the project for an extended period of time, I wouldn't need to keep paying a subscription fee nor risk losing access to all my progress.

I spent some time watching basics tutorials on YouTube and reading the documentation. After seeing the basic flows, I felt even more comfortable Godot would be a great choice.

Although my target is for the game to be 3D or 2.5D, one of the best decisions I made was to create the entire intro scene in very basic 2D components with no custom art before even thinking about 3D. The rest of this post will be discussing the 2D version.

## Development

Staring at a blank canvas is tough. I probably spent a little bit too long in the tutorial-hell because adding that first node is daunting.

It was one step at a time though. I added a ColorRect2D for my character, added a few more to make 4 walls. I added collision rects. I added some arrow key movement code from a tutorial to my player script. And suddenly I had a character.

![]()

It was exciting seeing even this working. I felt a new version of that joy I feel when getting the first version of an iOS app getting some list elements up on the screen.

Next was the dialogue system. All that time I spent planning to use Yarnspinner fell apart when I realized it required the C# version of the Godot binary. Although this isn't the end of the world, I wanted to limit the amount of moving parts I was working with. I'd already decided on using GDScript as my main programming language to take advantage of that simplicity. Surely there were other solutions.

Godot's plugin system is very convenient. It only took a few searches to find a well-supported DialogueManager plugin that had almost all the features of Yarnspinner, but with slightly different syntax and a simpler data model.

One big different I teased out was that Yarnspinner does it own internal state management whereas DialogueManager is stateless and requires the dev to expose their own state. Each strategy has its pros and cons, but I realized at least initially having the state management be a bit less *magic* would be a boon to my understanding while still getting my feet wet.

DialogueManager has great progressive onboarding: I could start by providing a dialogue file and using an example UI with only a line of code. When it came time for customization, I could duplicate the code and UI and make my changes.

After a quick bit of formatting work translating my script from Yarnspinner syntax to DialogueManager syntax, I was ready to add an NPC and a way to trigger a dialogue scene.

The DialogueManager dev also had a simple tutorial for setting up a basic NPC action system, which I followed and later modified as needed.

I now had a player and an NPC who could talk:

![]()

From here it was slowly chipping away at the TODOs I saw in front of me. Although I considered making more natural 2D art that I was comfortable throwing away later, I held off and did the best I could with in-engine rectangles.

The next few problems I solved were:

#### How do I give directionality to the player? How do I show that?

My initial movement code assumed the player only strafe, not rotate. I updated the movement code to rotate the player. I added what looked like eyes to show which direction the player was facing.

#### Where do I place my NPCs around the set?

Always trying to keep in mind that this was a prototype, I wanted to put the NPCs somewhere natural but also not spend a lot of time over-designing a rectangle-based environment. Doing the layout forced me to make clearer decisions than I'd needed to when writing the script.

#### How do I support a non-linear story?

The first script I wrote was non-linear for most of the character interactions. However, when laying out the characters on the stage and editing the script, I felt it'd be more straightforward to linearize the intro part of the story, where all the conflicts need to be set up precisely in order for the rest of the story to make sense and be playable non-linearly.

#### How do the NPCs move in and out after dialogue scenes?

I had to modify the story beats a bit so NPCs could move to new places around the scene without getting blocked by the player.

#### How does tweening and animation work?

I set up markers, paths, and programmatic tweens to try out some of the basic functionality of Godot. A lot of this was not strictly necessary for the prototype, but a good opportunity to learn Godot and game programming fundamentals. After all, the whole point of starting in 2D was learning the basics so that the complexities of 3D wouldn't be overwhelming.

#### How do I keep track of states?

I noticed familiar concepts like state machines in many Godot tutorials. I saw heavyweight and lightweight solutions. In the end I went with lightweight solutions of enums and a few booleans to keep track of the player's progression in talking to each NPCs.

#### How do I do fetch quests?

Fetch quests are a pretty common element in RPGs. A few fetch quests fell out of the script by accident while I was writing it. It seemed like a natural fit to have an NPC give the player "wristbands" to give to some other NPCs as a way to provide a small goal. This required a lightweight items overlay, so I had to learn about UI overlays in Godot.

I then added one more fetch quest: picking up a merch box from backstage and delivering it to another NPC. This required learning about modifying the node hierarchy at runtime and reusing nodes.

#### How should I make a cut scene?

The first scene of my script was the band driving together to the venue. This wouldn't have the same control scheme and would look more like a cutscene. I once again leaned into my ColorRect2D art style and drew up a van and my 3 main characters. I even went as far as animating them slightly so it looked like the car was moving.

## Exporting version 0.1

I finally had a playable version of my intro level finished.

The whole point of doing this prototype was to get some initial feedback about the story. So I needed a way to export it.

I already have an active iOS/macOS developer account and I'm working on a recent MacBook, so exporting a code signed and notarized app binary was doable even without the kind of detailed tutorials I was used to. Just the official Godot documentation was enough (although I had to fill in a few of the blanks myself).

Exporting for Windows from macOS was the wild west. I think I did it, but I haven't sent it to any testers yet, so I can't say for sure whether it worked.

## Playtesting

I sent the app to two friends and got some great feedback from them.

The rectangle art style was confusing in some parts, but they eventually figured out you were controlling a person from top-down and not driving a car.

I got positive feedback on some of the main conflict points I was trying to set up.

The main negative feedback was that the characters were hard to keep track of. This was mostly expected as I had kept the default dialogue UI anchored to the bottom of the screen.

Another bit of negative feedback was that the dialogue was too long overall, or perhaps it felt tedious alongside the mechanic of hitting the action button to display each line.

## Changes for version 0.2

- I added some more detail to the character designs to make it more clear of the top-down perspective.
- I did some light editing of the script. I think I'll need to do a fair bit more, but I'm going to wait until more of the real mechanics are in place to make that decision.
- I implemented a custom dialogue UI that appears above the speaking character.

## Minigame

Another big piece I wanted to put in place alongside the 2D prototype was the main minigame that will appear between story acts.

The band will need to write a song before the end of the night (driven by one of the story conflicts). In the mini game, the player will help piece together a song from various part options. For example, they'll choose what the guitar will play from several options. Then bass and drums and vocals. Between the intro and first act, they'll write the verse. Then between act 1 and act 2 they'll write the chorus. And etc.

I did a session in Logic writing a song with the various part options split up. I don't love the song yet so I'll probably try again a few more times. But I do think the overall concept of the mini game is looking promising.

## Next steps

I feel good enough about the 2D prototype and my understanding of the fundamentals of Godot that I'm ready to move on to the 3D version.

The 3D version will have many many more unknowns I need to uncover as soon as I can.

On the game play and programming side, there's camera movement and 3D navigation.

On the art side, there's basically everything: the aesthetics, the level design, the character design, the overall fidelity of each.

On the integration side, there's Blender and Godot and how to keep the iteration pipeline moving.

I'll have an update on these in the next devlog.