---
layout: post
title: "You Are a Frameworks Engineer at Big Tech Corp"
date: 2025-12-19 21:33:38
image:
tags: commentary apple
---

You are a Frameworks engineer at Big Tech Corp (BTCorp).

You got the job out of university a few years ago and have mostly enjoyed it.

You've gotten used to the pace. Yearly release cycles.

You just finished your last release cycle working on Framework X, a new key feature in BTCorp's lineup that was internally forecasted to sell lots of hardware.

You're proud of what was shipped, but know there's still a lot of work to be done.

You've just been reassigned to a new team though. In fact, all of your colleagues working on Framework X have been reassigned. Word is that Framework X is essentially soft deprecated and will never receive any new features or bug fixes. Word is that it was poorly received by tech bloggers and marketing is already starting to scrub it from any materials they can.

You've been reassigned to Framework UI. Framework UI is a new UI framework for BTCorp's hardware. It's been a skunkworks project for a few years, but finally has the blessing of a VP. After all, Framework CoreUI, the UI framework that's been around for decades, has an awful reputation outside the company for being too hard to use. BTCorp has been losing developer mindshare and it's finally affecting the bottom line.

You and all your colleagues are used to Framework CoreUI though. There's plenty of knowledgeable individuals inside the company that have built or used Framework CoreUI; anyone inside the company can read Framework CoreUI's source code; and there's plenty of internal documentation at the source level.

You're happy to be on the Framework UI project. It seems like an interesting technical challenge. Supposedly there's a lot of executive team members that are monitoring it closely.

You could spin this into a coveted L5 promotion.

You learn that no one on the skunkworks team (or BTCorp at large) has built software with Framework UI that has shipped to users outside the company yet, but that doesn't bother you. BTCorp is well known for being secretive about new projects.

You meet with your new team and get assigned *your* function. You'll be responsible for everything to do with this function and have a year to get it implemented, documented, tested, and successfully presented at the next World Wide Developers Meetup (WWDM).

Your function is called `PaintColor`. It takes a `Path` and `Color` instance. There's another team working on `Color`.

Your `PaintColor` function is responsible for drawing color on a path. Any color on any path.

You work with your tech lead to understand the requirements. They tell you you should be calling through to Framework CoreUI under the hood. Most of Framework UI is actually just a wrapper over Framework CoreUI.

You're told the underlying goal is to abstract away a lot of the complexity of Framework CoreUI so third-party developers are less intimidated by BTCorp's tech stack.

You get to work and quickly realize that this isn't going to be as easy as you thought!

You're not just calling through to the existing Framework CoreUI `PaintColor` function. FrameworkUI is in BTCorp's oldest programming language. And you learn there's a new system in place in Framework UI that defers draw calls. There's a new concurrency system being tested but it's not ready yet.

You dig some more and find that going down to the byte level there's some very complicated mapping you need to do to convert colors. It's no problem because you're well versed in algorithms and data structures (you passed the coding test during your interview process at BTCorp after all).

You spend the next couple months getting the implementation perfect. There's tons of transforms and bit shifting. It's annoying you've had to rewrite it from scratch a few times already (the concurrency system keeps changing), but it's okay because this is *your* function and you're committed to getting it right.

You're satisfied with the implementation. In your automated testing, it displays all your test colors fine.

You've got plenty of time before the World Wide Developers Meetup.

You start documenting your function.

```
/// Paints a color on a path.
///
/// - Parameters:
///   - Path: a path.
///   - Color: a color.
function PaintColor(Path, Color)
```

You check the existing documentation for other functions in Framework UI and yours is far and beyond the most detailed. You were originally thinking about going into more detail about the edge cases, but you figure there's still so much about Framework UI that's in flux that it's best not to overcommit.

You hand off your documentation to the documentation team to copyedit and give final approval. They're already very busy and understaffed, so they tell you to check back in about a month.

You start working on your 30 minute presentation for WWDM. You're told to emphasize how easy it is to paint colors on paths using Framework UI.

You put together the simplest example you can in your first code sample on slide 24: `PaintColor(Path.square, Color.default)`.

You see nothing on the screen. Hmm... what's going on?, you think.

You start debugging. `Color.default` is an alias for `Color.blue`, the default system color. `Color.blue` doesn't show up either.

You try the other semantic colors: `Color.yellow`, `Color.red`, `Color.green`. All of them display fine. It's just `Color.blue` that's not painting.

Your function's only purpose is to paint colors and there's a color it won't paint.

Your earlier testing was only on `Color`s initialized from random hexadecimal strings. Semantic colors were only introduced recently by the team in charge of colors.

You dig deeper and find the exact low-level byte-code representation of `Color.blue` that was chosen by the team. You put that directly into your function and it's broken.

You dig even deeper and realize this goes far beyond your understanding of the system. As far as you can tell though, it's only this one color value that maps incorrectly into the Framework CoreUI painting function.

You start freaking out a little bit. You realize that you're going to need some help from the experts in the language team, the concurrency team, and Framework CoreUI team to get this solved.

You go talk to your manager. You explain what you've uncovered. Those teams are busy, your manager says. The WWDM presentation is the most important thing right now, your manager says, let's focus on that.

You go to lunch and meet with some friends on other teams. You explain the situation as a hypothetical and ask what they would do. No one inside BTCorp is going to use Framework UI, so who cares, they say.

You decide to stop by to see the `Color` team on the way back from lunch. You ask them if they have authority to tweak the semantic color values and they say no, you'll have to talk to the design team.

You head over to the design team's office, interrupting a designer at your level and they seem annoyed. You explain in too much detail the function you're working on and the situation with that exact shade of blue. They don't understand any of the terms you're using and besides, all this seems like your fault.

You ask the designer if they would please just shift the semantic blue color one bit in either direction. It would be imperceptible to users, you say with an unearned certainty that can't hide your desperation. The design team will not relent. It has to be *that* blue. This was decided months ago and is already used in all the promotional materials.

You go back to the team in charge of the `Color` implementation. You ask, could we add a new semantic color to the API called `Color.paintColorBlue` that's one bit off from `blue`? It will make it easier for all third-party developers to work around the bug during the beta period. The `Color` team's manager does not think this will be aesthetically pleasing in the API and may cause confusion. All affected third-party developers can just redefine the color themselves with the hexadecimal initializer, they say.

You give up with workarounds for now, confident you'll find time and resources to fix the bug before the final release that's still a couple months away.

You finish writing your WWDM presentation, using `Color.red` to show off your `PaintColor` function. At the end of the presentation, you add a quick aside that `Color.blue` and `Color.default` are currently broken.

You get a note back from the WWDM presentation review team that says they've cut the section about `PaintColor` being broken. The policy is not to mention any known bugs or malfunctions, as it makes BTCorp look bad and undermines confidence in the new Framework UI framework.

You ask the documentation team if you can still add a "known issue" to the Framework UI beta release notes. They respond that it's too close to WWDM and they don't have time. They haven't reviewed your main documentation yet either, but making any change will move it to the back of the queue. And you're planning on fixing the bug before the main release, so adding any note about it for just the beta period doesn't make sense.

You record your WWDM presentation.

Your presentation is lauded as one of the best at WWDM. All third-party developers are really excited about Framework UI. From what every can see, it's so much easier to paint colors on paths now. All the examples from the presentations, including yours, look like such an advancement over Framework CoreUI.

You attend a meet-the-framework-engineers session at WWDM, where third-party developers line up for hours to ask you and your colleagues questions. You're terrified someone's going to call out your bug. Luckily, Framework UI has only been available for a few hours, so only one developer asks you about the bug. You tell them to try restarting their computer and to get back in line. By the time they get to the front, you've gone home.

Your next few months in the beta period after WWDM are hectic. You've been pulled away to fix more important bugs in Framework UI. Management is panicking because it's become increasing clear that Framework UI is not yet capable of being used for real software.

You watch as Framework UI is released on time anyway. Long time third-party developers are angry they've invested time in learning it and trying to build apps with it before the beta period ends. But management still considers it a success, because the narrative among the tech press is positive and new third-party developers are onboarding at record pace. Veteran third-party developers are simply using Framework CoreUI as they always have, just like the developers inside BTCorp.

Your performance review season begins, and at the meeting your manager doesn't mention anything about the `Color.blue` bug you spent months agonizing over being unable to fix. Your manager does, however, mention a peer review from the design team that states you were "hard to work with". Regardless, you weren't going to get a promotion anyway, but your manager now has a something documented to justify it.

Your colleagues called it: it's been a few months since launch and no developer inside BTCorp has attempted to use Framework UI for production work. Most haven't even read the Getting Started page that the documentation team worked so hard on.

You decide to jump ship and quit BTCorp, using the outwardly successful launch of Framework UI to secure your next gig at Competing Tech Corp.

You check the third-party developer message board on your last day at BTCorp. You're curious to see if there's any feedback about Framework UI as you haven't really kept up with the launch. 

You scan the first page and see a message on the board with a title that mentions `Color.default` not working. The original poster tracked down the issue to `Color.blue` and even mentioned the same workaround.

You respond anonymously:

```
`Color.blue` is not supported in `PaintColor` at this time. 

If you're interested in this functionality, please submit a report to the external bug tracker.
```

You hit "Send" and not a moment later, the original poster has already responded, exasperated that they've already spent hours chasing down the bug, asking why supporting `Color.blue` would need to be considered as a separate feature, and why you couldn't have added this to the documentation.

You close your laptop and leave your badge at the reception desk on your way out.