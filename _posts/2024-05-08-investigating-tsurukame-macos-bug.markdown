---
layout: post
title: Investigating a Bug in the Tsurukame macOS App
date: 2024-05-08 14:45:00
image: /images/tsurukame-bug-04.png
---

I procrastinated on doing my kanji reviews over the weekend by [fixing a bug](https://github.com/davidsansome/tsurukame/pull/709) in the open source [Tsurukame for Wanikani app](https://github.com/davidsansome/tsurukame/). This is a quick write-up about how I went about diagnosing and fixing the bug from fork to pull request.

{% caption_img /images/tsurukame-bug-01.png Tsurukame is an native iOS interface to the Wanikani flashcard system for Japanese kanji and vocabulary, developed and maintained by David Sansome. %}

[Issue #706 - MacOS: Text input gets highlighted during reviews](https://github.com/davidsansome/tsurukame/issues/706) was reported by another app user a few weeks ago:

> After maybe the first half a second or so of a review being open, whatever text you have typed gets highlighted. If you are continuing to type that initial input gets deleted.

<video src="/images/tsurukame-bug-02.mp4" loop controls preload width="500"></video>

In the above video, after getting the meaning "bombing" correct, as I'm typing the reading the ぼう suddenly gets selected and is therefore deleted when I continue typing.

I noticed this bug as well and it was honestly causing enough friction in my reviews that I finally decided to investigate the bug in earnest.

### Setting up project and building

I fork the repo, then clone my fork to my local machine. I follow the instructions on the README to `pod install`, open the xcworkspace in Xcode 15.3, change the signing identifiers, and run the signing identifiers helper script.

Since on the App Store the app is listed under "iPhone & iPad Apps" section, I choose the "My Mac (Designed for iPad)" build destination.

When trying to build, Xcode complains about not having the WatchOS SDK, so I simply delete the two WatchOS targets and try to build again. It builds without any problems.

I set up the simulator app with my API key and verify I can reproduce the bug.

### Finding the relevant view controller

I start by figuring out the name of the view controller.

#### Strategy 1: View Debugger

The easiest way to do this is to navigate to the screen in the simulator and then use the view debugger. The view controller is called `ReviewViewController`. The upside to this strategy is that I also get the name of the text field (`AnswerTextField`).

{% caption_img /images/tsurukame-bug-03.png Using the view debugger is often the easiest way to discover class names. %}

#### Strategy 2: Searching for label text

Another way to find the view controller is search the project for the label text "Reviews". This leads me to `MainViewController.swift`:

```swift
let reviewsItem = BasicModelItem(style: .value1,
                                title: "Reviews",
                                subtitle: "",
                                accessoryType: .disclosureIndicator,
                                target: self,
                                action: #selector(startReviews))
```

I search for the selector `startReviews` which leads me to the segue and `ReviewContainerViewController`:

```swift
case "startReviews":
    // ,..
    let vc = segue.destination as! ReviewContainerViewController
    vc.setup(services: services, items: items)
```

`ReviewContainerViewController` has two options, the more obvious one being `ReviewViewController`:

```swift
reviewVC = (storyboard!
    .instantiateViewController(withIdentifier: "reviewViewController") as! ReviewViewController)
reviewVC.setup(services: services, items: items, showMenuButton: true, showSubjectHistory: true,
                delegate: self, isPracticeSession: isPracticeSession)

let menuVC = storyboard!
    .instantiateViewController(withIdentifier: "reviewMenuViewController") as! ReviewMenuViewController
menuVC.delegate = self
```

### Finding the relevant code

I previously found the `UITextField` is named `answerTextField`. It's actually a subclass of type `AnswerTextField`. Just to double check, there's not much functionality in the subclass implementation, so I can try to ignore it for now and assume the offending code is in the view controller.

Searching for uses of `answerTextField`, I find a section of the view controller that implements the `UITextFieldDelegate` protocol. My instinct tells me this is a good place to start putting breakpoints. I put a breakpoint in:

```swift
func textField(_: UITextField, shouldChangeCharactersIn _: NSRange, replacementString _: String) -> Bool
```

Looking at the backtrace, it turns out that the delegate is actually delegated through another class called `TKMKanaInput`. I can confirm this by seeing that the expression in `ReviewViewController` sets the `UITextFieldDelegate` to `kanaInput`:

```swift
answerField.delegate = kanaInput
```

And `kanaInput` sets its delegate to `self` which is `ReviewViewController`.

```swift
kanaInput = TKMKanaInput(delegate: self)
```

The effective delegate chain is `UITextField` -> `TKMKanaInput` -> `ReviewViewController`.

The bug is happening because the text field contents are getting selected unexpectedly. When I look at the available methods on the `UITextFieldDelegate` protocol, I notice one related to selection that could be useful:

```swift
@available(iOS 13.0, *) optional func textFieldDidChangeSelection(_ textField: UITextField)
```

This API is only available on iOS 13 and the deployment target for Tsurukame is iOS 12. I temporarily update the deployment target to iOS 13 so I can use this API for debugging.

I add the delegate conformance to `TKMKanaInput`. `TKMKanaInput` is written in Objective-C so we need to add that version instead of the Swift signature:

```objc
- (void)textFieldDidChangeSelection:(UITextField *)textField {
  NULL; // <-- breakpoint here
}
```

I add a `NULL` so I can set a breakpoint.

With the breakpoint added, this method gets called too often to be useful. Basically on any change. I want it to get called only when the selection length is non-zero.

Checking the `UITextField` API, I can check the value of this range with the following line in LLDB:

```objc
po (BOOL)[textField.selectedTextRange isEmpty]
```

It's false only when the bug occurs (or when I manually select some text, but I can avoid doing that).

I change the breakpoint condition to be:

```objc
(BOOL)[textField.selectedTextRange isEmpty] == NO
```

{% caption_img /images/tsurukame-bug-05.png Using Xcode's conditional breakpoint functionality to ignore the many irrelevant calls to this method. %}

Note: when I used `false` instead of `NO` the breakpoint would always catch no matter what.

I build and run the app, submit a reading answer, then immediately start typing. The breakpoint triggers!

{% caption_img /images/tsurukame-bug-04.png Our breakpoint triggers at the exact time the text field's contents are selected. %}

Ascending the stack trace, I see a hit in app code within `ReviewViewController`.

```swift
@objc func animationDidStop(animationID _: NSString, finished _: NSNumber, context: UnsafeMutableRawPointer) {
  // ...
  if ctx.subjectDetailsViewShown {
    // ...
  } else {
    // ...
    answerField.becomeFirstResponder() // <-- breakpoint triggers here
  }
  // ...
}
```

This makes sense for a few reasons:

- The selection bug was occurring ~0.5-1.0 seconds after switching review items; this amount of time is consistent with animations.
- The responder chain is one of the few ways to programmatically alter `UITextField` and `UITextView`.
- The UIKit internal behavior for text-related tasks especially is opaque and notoriously fickle between even point releases of iOS.
- Mapping iOS input behavior to macOS is never 1-to-1, and is a hot-spot for leaky abstractions.

I've found the offending line of code, so now I can decide how to fix it.

### Why does this code exist in the first place?

Before modifying the code in any way, it's best to try to understand why this code was written.

I pop open Xcode's git blame viewer (named "Authors" in the Editor Options). The commit includes a pull request number #186. 

{% caption_img /images/tsurukame-bug-06.png Git blame in Xcode (no blame being thrown from here though). %}

I open [this PR in GitHub](https://github.com/davidsansome/tsurukame/pull/186).

The line of code was added by itself in this PR, and it was added specifically for macOS support back in 10.15 (it's now 14.4):

> Without this patch, you have to click the mouse to focus on the text entry box after each animation. With this patch, you can type answers one after another, like on an iPhone or iPad.

### Proposing and testing a potential fix

Now I can remove the `answerField.becomeFirstResponder()` call and then,

1. Check to see whether the behavior reported in #186 still occurs on macOS
2. Check to see whether the errant selection behavior (my target bug) still occurs on macOS
3. Check to see no behavior changes occur on iPhone

I remove the line and:

1. The behavior reported in #186 no longer occurs. Presumably it was "fixed" at the iOS/macOS system layer.
2. The errant selection behavior no longer occurs. Our bug is fixed!
3. No behavior changes occur on iPhone. No problem there.

### Committing, submitting, and documenting the fix

- I make a new local branch.
- I commit the code with a decent commit title and description.
- I push to my remote fork on GitHub.
- I [open a PR #709](https://github.com/davidsansome/tsurukame/pull/709) on the canonical repo.
- I write up a succinct PR description linking the bug report issue and the old PR.
- I submit the PR for review by the maintainer.

## Epilogue

The maintainer approved and merged the PR almost immediately. CI ran and produced a new TestFlight build, but unfortunately, the TestFlight build is not runnable on macOS, so I'll have to use my debug build for day-to-day reviews until the next version is ready for the App Store.

I'm happy that this bug will no longer slow me down during reviews! Open source is great.
