---
layout: post
title: A Deep Dive Into iOS Messages Extensions
date: 2016-06-25 01:39:29
---

Apple announced Messages Extensions as part of iOS 10 allowing third-party apps to integrate directly with the iMessage platform. This integration follows Facebook Messenger and pretty much every other major messaging platform in the US and abroad.

In this post I'll present an overview of Messages Extensions, walk through a simple example extension to illustrate some key features, and finally explore some advanced features of Messages.framework. Some of this information is gleaned directly from the WWDC talk and some is from poking around in the beta. Hopefully this will save you some time in having to kick the tires yourself. Sticker packs are pretty straightforward, so I won't be covering those.

I recommend watching the WWDC talk [iMessage Apps and Stickers Part 2](https://developer.apple.com/videos/play/wwdc2016/224/) and reviewing the code for [IceCreamBuilder](https://developer.apple.com/library/prerelease/content/samplecode/IceCreamBuilder), the Apple endorsed example for this topic. I consider that talk the primary source of information on Messages.framework. Here's a link to the [Messages.framework](https://developer.apple.com/reference/messages) docs.

Note: This post was originally written for iOS 10 beta1. It was partially updated for beta2 on 7/7/2016.

## Overview

### App Extension

Messages Extensions follow the App Extension target format introduced in iOS 8. Other examples include Today Extensions, custom keyboards, and Share Extensions. As an App Extension, it is bound by special rules outlined in the [App Extension Programming Guide](https://developer.apple.com/library/ios/documentation/General/Conceptual/ExtensibilityPG/ExtensionOverview.html#//apple_ref/doc/uid/TP40014214-CH2-SW2)

### Backwards Compatibility

Messages Extensions allow the creation and modification of a standardized encapsulated model/view pair `MSMessage`. Two of the main design points Apple needed to address in their implementation of Messages Extensions were:

1. User A creates a custom message using an extension. What happens if User B receiving a specially created message does not have the extension installed that was used to create the message?
2. User A creates a custom message using an extension. What happens if User B is on a previous version of iOS?

The answer to these was:

1. Use a standardized template layout (view model) preconfigured by the extension that requires no additional third-party code execution to display as intended. Use the principle of progressive enhancement to provide a richer interface for viewing/modifying messages.
2. Require model data to be encoded as a URL which allows fallback to a web browser.

### Core Ideas

At their core, Messages Extensions:

* provide the specification of a model and template view model (contained within an `MSMessage` instance).
* provide a rich interface to view, create, and manipulate these models (an `MSMessagesAppViewController` subclass).

Defining these bits further:

* The **model** is a URL (`MSMessage.url`). It is arguably designed to be very interoperable in the case that all parties do not have an extension installed.
* The **template view model** is a special framework-provided template object (`MSMessageTemplateLayout`). It is minimally configurable and designed to be a summary view of your content.
* The **rich interface** is a fully customizable `UIView` (`MSMessagesAppViewController`). This custom view can display a more domain appropriate representation of the model and allow creation and modification of the model.

### User Interface Points

Message Extensions have three basic interface points for Messages.app users:

**Message summary display**: all users running iOS 10+ and macOS Sierra+ will see a template view of a message created by an extension regardless of whether or not they have that specific extension installed. Users on previous versions will only receive the message's summary text and URL as two separate messages, but only if the URL has an http/https scheme.

{% caption_img /images/messages-layout-template.png MSMessageTemplateLayout (courtesy of WWDC). %}

**Message creation**: the initial creation of a message occurs in the compact view of your extension. By tapping the App Store logo to the left of the message text field, the keyboard is replaced by a paging scroll view containing all the installed Messages Extensions. Extensions in compact mode have a keyboard-sized viewport to display any content they wish. Users have the option to tap the disclosure button on the right side of the screen at any time to expand this view to full screen or recollapse it later.

{% caption_img /images/messages-collapsed-view-small.png The collapsed view of our example extension. %}

**Message viewing & modification**: for users who have your extension installed, tapping an existing message sent by another user or one they created will launch your extension into an expanded (full screen) viewport. Your extension receives the contents of the tapped message in order to configure itself for display and/or editing. For users that do not have your extension installed, a web browser will be opened with the message's URL (on compatible OS versions assuming an http/https schema).

{% caption_img /images/messages-expanded-view-small.png One state of the expanded view of our example extension. %}

### Model Strategies

There are two primary strategies for designing your app extension's model layer. The example extension presented later will be a standalone extension.

#### Standalone Extensions

If you're creating a standalone extension that exists only within the walls of Messages.app, you will have to encode all model data shared between conversation participants in `MSMessage`'s `url` field. Your extension itself will essentially be stateless or hold state that is only relevant to the current user (e.g. IceCreamBuilder saves the user's previously created stickers in `NSUserDefaults`).

```
?type=translation&question=What%20time%20is%20it?&answer=今何時ですか。
```

Although this strategy is simpler, the downside is that there is more opportunity for human-scale race conditions to occur, especially if the conversation has more than two participants. This scenario is discussed at the end of the WWDC session. For example, if two participants modify the same message at once, the latest message sent will "win" and overwrite the data.

### Webservice Extensions

If you're creating an extension to an existing webservice, you have the ability to use your servers to share state between participants. Instead of encoding all state into the `MSMessage`'s `url` field, you could provide a link to a resource and fetch it from the server as necessary via `NSURLSession`.

```
https://example.com/items/742932
```

Apple recommends this approach in the WWDC session (albeit somewhat casually, simply referencing "the cloud"), specifically mentioning the avoidance of race conditions.

Keep security in mind though. If your app is creating harmless, ephemeral resources, it may be acceptable to use the participant UUIDs provided by `MSConversation` as security tokens. These would not work for long term resources, as reinstalling your extension will regenerate the local participant UUID. You could also use `NSUserDefaults` to share your service's auth token for the user logged into your primary app. This technique is beyond the scope of this post, but see the [App Extension Programming Guide](https://developer.apple.com/library/ios/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html#//apple_ref/doc/uid/TP40014214-CH21-SW1) for more information.

## Example Extension Walkthrough

That's enough background for now. Let's dive into the example extension's implementation.

The whole project is on [Github](https://github.com/twocentstudios/Messages-Translator-Extension) if you'd like to skip straight to the source.

I'll be using iOS 10 beta1, Swift 3 beta, Xcode 8 beta.

### What We're Building

I'm currently learning Japanese. When I'm chatting with my Japanese friends (usually in LINE), it can be difficult asking for corrections of my attempts at writing Japanese. Usually my friends can work out my meaning, but don't bother correcting me since it's awkward to do so without a dedicated interface. The conversation usually goes off track if I try to ask them to correct me or we just go back to speaking English.

It would be cool to have collaborative interface for corrections/translations in an iMessage chat, so we're going to build it! Most of the inspiration comes from the HelloTalk app. HelloTalk provides dedicated messaging platform and tools for language learners. Here's an example:

{% caption_img /images/messages-hello-talk-small.png The HelloTalk interface for corrections and translations, respectively. %}

Not only are we going to build an interface for corrections, but since the concept is similar, we'll also build an option for asking for translations.

Here's an example correction request flow in our extension ([View the screen capture 5.3MB](/images/messages-correction.mov)):

> Chris: [correction request] 週末、東京**で**行きましたか。
> Miu: [correction] 週末、東京**に**行きましたか。
> Miu: [continuing conversation] はい、東京に行きました！

{% caption_img /images/messages-correction-flow-small.png The correction flow of our example app. %}

Here's an example translation request flow in our extension:

> Chris: [translation request] Did you go to Tokyo last weekend?
> Miu: [translation] 週末、東京に行きましたか。

{% caption_img /images/messages-translation-flow-small.png The translation flow of our example app. %}

Our extension won't have all the bells and whistles of HelloTalk, but hopefully it will show you the basics of creating your own Messages extension.

### High Level Data Flow

I like modeling applications as a series of data transformations and side effects. Let's take a step back and understand how data will flow through our extension.

The most straightforward flow will be a user tapping on an existing message created by our extension so let's start there.

Defining some of our terms:

* **URL**: Data is stored in the `url` parameter of an `MSMessage`. Everything we need to restore the state of our message must be contained in the `url` string.
* **Model**: This is our domain model, an enum we'll call `Pair` (referring to a question/answer pair) that contains `Translation` or `Correction` structs. All value types.
* **ViewState**: Another enum that describes each possible state our view can be in. It can be converted directly from any Pair.
* **View**: Our extension only has one `UIView` which is configured directly from a `ViewState` value.
* **ViewAction**: The View communicates well specified actions to its delegate.
* **MSMessageTemplateLayout**: This is basically another ViewState/ViewModel object provided by Messages.Framework and configured by us.

Below is the entire transformation flow:

```
MSConversation -> 
MSMessage -> 
URL -> 
Model -> 
ViewState -> 
View -> 
ViewAction + Model -> 
Model -> 
URL + MSMessageTemplateLayout -> 
MSMessage + MSSession -> 
MSConversation
```

Broken down:

* `MSConversation -> MSMessage -> URL`: We'll access the `url` property on the `MSMessage` instance on the `MSConversation` instance provided by Messages. `conversation.selectedMessage.url` if you will.
* `URL -> Model`: Our Model's properties will have been previously encoded (by us) into `URLQueryItem`s. We'll need a function to decode them.
* `Model -> ViewState`: Any Model value must be able to be shown to the user.
* `ViewState -> View`: Setting the `viewState` property on our view will configure the view by adding data to text fields, showing/hiding subviews, and changing labels.
* `View -> ViewAction`: We'll encode button taps and text field data into an enum of actions and pass the enum to the View's delegate. Our View won't have to know anything about how to transform these actions into a new Model or ViewState.
* `ViewAction + Model -> Model`: We need to combine an action with the old model to create a new model that includes the user's changes.
* `Model -> URL + MSMessageTemplateLayout`: Finally, we need to convert our model back to the the fields required to configure a new message.
* `URL + MSMessageTemplateLayout -> MSMessage + MSSession -> MSConversation`: We'll configure a new message, attaching an `MSSession` provided by Messages, then call `insertMessage` on the conversation.

That may seem like a lot of transformations, but in reality they're all simple ~10-20 line pure functions that cover all the possible enum cases.

We'll go into some of these transformations in more detail later on.

### Data Models

We're going to support both a correction type and a translation type. They're pretty similar, just a field for a question and a field for an answer. However:

* The correction type might already be correct, so there needs to be a state for that. 
* The corrector might not know what the requester is asking and thus can't correct it. 
* For the translation type, the translator may not know how to translate the request so there should also be a state for that.

#### Domain Model

We're going to go a little enum crazy because in my opinion that's one of the coolest features of Swift.

`Pair` represents a question/answer pair. It can be either a translation or a correction. 

```swift
enum Pair {
    case translation(Translation)
    case correction(Correction)
}
```

Our `Translation` type will have a question and an answer. We have two types of answer though, so we'll make another enum (`TranslationAnswer`) for that.

```swift
struct Translation {
    var question: String?
    var answer: TranslationAnswer?    
}

enum TranslationAnswer: RawRepresentable {
    case known(String)
    case unknown
}
```

The `Correction` type looks pretty similar. Just one more `CorrectionAnswer` case.

```swift
struct Correction {
    var question: String?
    var answer: CorrectionAnswer?    
}

enum CorrectionAnswer: RawRepresentable {
    case correct
    case incorrect(String)
    case unknown
}
```

> Another valid interpretation would have been to condense `Correction` and `CorrectionAnswer` into a single enum instead of using nullable properties. We're doing some of this transformation work in the `ViewState` instead.

#### Messages Framework Model

In order to do the `URL -> Model` and `Model -> URL` transformations, we'll need to devise an encoding scheme for our Model. There are a number of ways to do this, but we'll go with the simplest method.

* `Pair` (our top level enum) will encode its case as a `type` param. (e.g. `type=translation` or `type=correction`).
* `TransformationAnswer` and `CorrectionAnswer` will be conformed to the `RawRepresentable` protocol and converted to a single string field.
* `Pair`, `Transformation`, `Correction` will expose a `queryItems` property for the `Model -> URL` transformation. They will expose a custom nilable initializer receiving an array of `[URLQueryItem]`.

At the end of the day, the URL will look something like this:

```
?type=translation&question=What%20time%20is%20it?&answer=今何時ですか。
```

Unfortunately, it's still pretty boilerplatey. Check out the [source](https://github.com/twocentstudios/Messages-Translator-Extension/blob/master/MessagesExtension/URLQueryItem.swift) for the implementation details.

Other implementations could convert object graphs to a single JSON string first (URL encoded of course) and store this encoded string as a single `URLQueryItem`.

### View Models

#### ViewState

We have 10 possible view states.

* 1 introductory state.
* 2 intermediate steps for each `Pair` type.
* 3 end states for a `Translation`.
* 2 end states for a `Correction`.

```swift
enum ViewState {
    case promptNew
    case translationNew
    case translationPart(question: String)
    case translationCompleteUnknown(question: String)
    case translationCompleteKnown(question: String, answer: String)
    case correctionNew
    case correctionPart(question: String)
    case correctionCompleteIncorrect(question: String, answer: String)
    case correctionCompleteUnknown(question: String)
    case correctionCompleteCorrect(question: String)
}
```

With any case, we have enough information to completely lay out our interface.

See the implementation of the `Model -> ViewState` transformation [here](https://github.com/twocentstudios/Messages-Translator-Extension/blob/master/MessagesExtension/ViewState.swift).

Although in this case it would be possible to do a `ViewState -> Model` transformation, this type of transformation can be inherently lossy. We'll use a `ViewAction + Model -> Model` transformation instead to process changes.

#### ViewAction

As discussed a earlier, we'll be using another enum to succinctly communicate user actions from the View layer back to the Controller layer. The intention behind this is to keep any domain logic and transformations out of the View layer and present a strict interface between our application's layers defined by value types.

```swift
enum ViewAction {   
    case createNewTranslation
    case createNewCorrection
    case addTranslation(question: String)
    case completeTranslationKnown(answer: String)
    case completeTranslationUnknown
    case addCorrection(question: String)
    case completeCorrectionIncorrect(answer: String)
    case completeCorrectionCorrect
    case completeCorrectionUnknown
}
```

#### MSMessageTemplateLayout & MessageTemplateLayout

`MSMessageTemplateLayout` is Messages.app's generic view format for inline messages. It serves the same purpose of our ViewState. (`MSMessageTemplateLayout` is currently the sole subclass of the `MSMessageLayout` base class, which could allow Apple to provide other message layouts in the future.)

```swift
// Messages.framework
public class MSMessageTemplateLayout : MSMessageLayout {
    public var caption: String?
    public var subcaption: String?
    public var trailingCaption: String?
    public var trailingSubcaption: String?
    public var image: UIImage?
    public var mediaFileURL: URL?
    public var imageTitle: String?
    public var imageSubtitle: String?
}
```

> I'm a little disappointed that the text is `String` and not `AttributedString`, but I can see why Apple might want to keep customization to a minimum up front.

We'll only be using the caption and subcaptions so we'll make a helper struct to decouple our implementation from Messages. It's a bit pedantic to do so, but oh well.

```swift
struct MessageTemplateLayout {
    var caption: String?
    var subcaption: String?
    var trailingCaption: String?
    var trailingSubcaption: String?
}
```

Although we could do the transformation as `Pair ->  MessageTemplateLayout`, I think it makes our lives easier to convert from `ViewState ->  MessageTemplateLayout` instead.

### View

I usually don't use Storyboards, but for this occasion I decided to do so.

`MessagesView` is our custom view. It has a couple text fields, a bunch of labels, and a bunch of buttons. All of these subviews are shared amongst our various `ViewState`s and their actions and data are translated back to something our Controller understands.

There's a huge function that converts `ViewState -> View` by setting label text, hidden attributes, and button titles for each state.

`@IBAction -> ViewAction` happens in each tap handler before being provided to the view's delegate.

```swift
protocol MessagesViewDelegate: NSObjectProtocol {
    func didAction(_ view: MessagesView, action: ViewAction, state: ViewState)
}
```

The relevant code is [here](https://github.com/twocentstudios/Messages-Translator-Extension/blob/master/MessagesExtension/MessagesView.swift).

Another valid implementation would be to use two or more `UIViewController` subclasses and the UIViewController containment APIs.

### Controller

`MessagesViewController` is our `MSMessagesAppViewController` subclass. It will be responsible for performing most of the data transformations, holding state through the extension's lifecycle, and handling other calls from Messages.app.

Our controller has two instance variables:

* `@IBOutlet weak var messagesView: MessagesView!`: our only view.
* `var pair: Pair?`: the current model. We need to hold onto this temporarily while we're waiting for user input in order to do the `ViewAction + Pair -> Pair` transformation. This value may also change if we're performing a `ViewAction` that is not intended to produce an `MSMessage` but only alter the `ViewState` directly (e.g. `ViewState.promptNew -> ViewState.translationNew`).

### Entry Point

The entry point of our extension in the general case will be:

```swift
// MessagesViewController.swift
override func willBecomeActive(with conversation: MSConversation) { // ... }
```

* `conversation.selectedMessage == nil`: the user opened our extension in the extension browser and will be creating a new translation or correction.
* `conversation.selectedMessage != nil`: the user has tapped on a translation or correction embedded in an existing message in their timeline.

The full implementation with transformations annotated:

```swift
override func willBecomeActive(with conversation: MSConversation) {
    // MSConversation -> MSMessage -> URL -> Model
    self.pair = Pair(conversation: conversation)
    
    // Model -> ViewState
    let viewState = ViewState(pair: self.pair)
    
    // ViewState -> View
    self.messagesView.viewState = viewState
}
```

### Exit Point

The exit point of an Messages Extension in the general case will be a call to `MSConversation.insert` followed by `MyMessagesAppViewController.dismiss` and can be called from any part of your extension. This inserts a message (that your extension has just finished crafting) into the Messages.app's main text field allowing the user to (optionally) tap the send button.

In our case, we're channeling all user actions into the delegate method:

```swift
func didAction(_ view: MessagesView, action: ViewAction, state: ViewState) { // ... }
```

There are a few resulting view states where the behavior of inserting a message and dismissing is not correct. If the user is in the compact view and has decided to start a new translation, they're not finished interacting with our extension. In this case, we should request an expanded view:

```swift
// MessagesViewController.swift
self.requestPresentationStyle(.expanded)
```

Let's now walk through the entire function.

```swift
func didAction(_ view: MessagesView, action: ViewAction, state: ViewState) {
    // ViewAction + Pair -> Pair
    let newPair = action.combine(withPair: self.pair)
    
    // Pair -> ViewState
    let newViewState = ViewState(pair: newPair)
    
    switch newViewState {
    case .promptNew: break
    case .translationNew, .correctionNew: self.requestPresentationStyle(.expanded)
    default:
        guard let conversation = self.activeConversation else { fatalError("Expected a conversation") }
        
        // Always replace the selectedMessage by passing its `MSSession`.
        let session = conversation.selectedMessage?.session ?? MSSession()
        
        // Pair -> MSMessage
        guard let message = newPair.composeMessage(session) else { fatalError("Expected a message") }
        
        // ViewState -> String
        let changeDescription = state.changeDescription()
        
        // MSMessage + String
        conversation.insert(message, localizedChangeDescription: changeDescription) { // ... }
        
        self.dismiss()
    }
    
    // Set the new Pair and ViewState on our view controller
    // for the next run cycle.
    self.pair = newPair
    self.messagesView.viewState = newViewState
}
```

As you can see, we're mostly applying transformations based on the user's action (`ViewAction`), the input pair we saved earlier (`self.pair`), and some state saved in the superclass `MSMessagesAppViewController` (`self.activeConversation.selectedMessage.session`). These transformations produce a new `Pair` and `ViewState`, and the side effect of either an inserted `MSMessage` in the conversation or a view state change.

All side effects are located in our class closest to the outside world (the view controller), while other classes and structs define valid transformations. Notice in particular that the view does not change its own state directly from user actions such as button presses.

### More Complicated Flows

We've now looked at the most common lifecycle of `input -> user action -> output`. Now let's look at some other cases.

#### willSelect & didSelect

If your extension is already active when the user taps one of your extension's messages, the extension doesn't have to launch and therefore won't call our view controller's `willBecomeActive` & `didBecomeActive` as we were expecting. Instead, it will call `willSelect` & `didSelect`, so we also need to set the `Pair` and `ViewState` from this entry point too. Unfortunately, at iOS 10 beta1, `willSelect` & `didSelect` don't seem to be implemented. This was confirmed as a known issue in beta2. The workaround is to place this behavior in `willTransition`.

#### didReceive

While your extension is active, it's possible that one of the conversation's other participants will send a message to your extension. The original sender could have updated the message, or a third member of the group could have replied. In either case, you can monitor `didRecieve` to react to new messages outside of the `input -> user action -> output` cycle presented earlier and optionally alert the local participant that something has changed since they opened your extension.

#### didStartSending & didCancelSending

If you need to take direct action based on the user attempting to send or deciding not to send your message after it's been inserted into the conversation, override your view controller's `didStartSending` and/or `didCancelSending` functions. These would presumably be called after you've called `dismiss` inside the defacto exit point I described earlier.

Notice that `didStartSending` is called on an *attempt* to send, i.e. when the user taps the Messages.app's send button. Apple doesn't guarantee the message will be delivered to the other participants. This could create a few opportunities for edge cases you should be aware of. For example, if the message service goes down and you've `POST`ed resource state changes to your server successfully in `didStartSending`, other participants may see outdated information in their message's `MSMessageTemplateLayout` that represents that resource on your server. Rare, but still something to think about that synchronizing state using `MSMessage`s will not always be perfect.

Note that there also may be an issue with these two delegate methods with iOS 10 beta1 as well, possibly on the simulator but not real devices.

### Wrap Up

We've finished the basic walkthrough of our example Messages Extension. We haven't used all that Messages.framework is capable of, so we'll now take a look at some advanced features.

## More Advanced Features

Well, some of these features are advanced. Others I just didn't have an immediate use for in the example app. In any case...

### Collapsed View State

When your `MSMessagesAppViewController` is in its collapsed state, it won't have access to horizontal swipe or pan gestures. That's how users will swipe between different extensions.

Your text fields or anything that requires a keyboard will also be disabled since the keyboard would otherwise obscure your view.

### Expanding The View State

When your extension is launched by a user tapping an existing message, the view controller is automatically launched into expanded mode by Messages.app.

You can also request that your app be expanded after it has started in compact mode. In my tests on the simulator, my request to expand my extension was accepted no earlier than 0.3 seconds after `viewDidAppear`, the final callback we get from the view system (I set a timer). Those numbers may change, but the takeaway is that you can't *immediately* expand your extension with no user interaction having taken place.

### Saved Screenshots

Similar to how suspended apps are snapshotted by iOS before moving to the background, the same is done with Messages Extensions to give them the appearance of quick activation. Messages.app kills and revives extensions quite aggressively too. In the beta, this has led to some funky looking intermediate view states.

{% caption_img /images/messages-startup-artifacts-small.png IceCreamBuilder looking a little stretched out. %}

### Testing in the Simulator

Messages.app was added to the iOS simulator on iOS 10 to assist in debugging extensions. On every cold launch, Messages.app in the simulator is seeded with two conversation threads that are tied together. You can send messages from messagesuser1@simulated.icloud.com by tapping on the first thread and from messagesuser2@simulated.icloud.com by tapping on the second thread.

You can clear the message history by force quitting Messages.app. It's also cleared any time you recompile and attach the debugger. According to the release notes this may not be the behavior intended by Apple though.

I had some trouble using the macOS hardware keyboard with my extension's text fields in the beta.

{% caption_img /images/messages-simulator-home-small.png Messages.app in the iOS Simulator. %}

### Landscape Support

Apple [requires](https://forums.developer.apple.com/thread/50524) that Messages Extensions support both landscape and portrait as there is no way to prevent the normal autorotation behavior of Messages.app.

### MSMessage

As the unit encapsulating data and view specification, `MSMessage` has a few points we should cover.

#### Accessibility

The second "view" of a message if you will is the `accessibilityLabel` property. You should use this label to specifically spell out any implicit context in the `MSMessageTemplateLayout`.

#### Session

We ran into `MSSession` briefly in the sample app. The `MSSession` is an identifier you can use to link messages together. Messages.app will replace the contents of any previous message with the same session. When preparing an `MSMessage` for the user, if the message represents a resource that already exists, you should initialize the `MSMessage` with the previous `MSMessage`'s `MSSession`. Otherwise, use the designated initializer `MSSession()` to create a new one.

#### App Icon

Your extension's icon will appear in the top left corner of any message created by your extension.

In our example extension, you'll notice that since we don't send an image or video, our app icon covers up part of the caption. Hopefully that's something that will be fixed by Apple before launch.

#### NSCoding

`MSMessage` conforms to both `NSSecureCoding` and `NSCopying` making life a bit easier if you wanted to save messages wholesale.

#### Participants

Due to privacy concerns, the identities of a conversation's participants are obscured through the use of UUIDs.

* You can identify a message's sender from `MSMessage.senderParticipantIdentifier`.
* You can identify the local user from `MSConversation.localParticipantIdentifier`.
* You can identify all other participants from `MSConversation.remoteParticipantIdentifiers`.

These three properties should be enough for your extension to determine at any given time whether a message was sent by the current user.

You can insert these UUIDs directly into user-facing strings within `MSMessageTemplateLayout()` prefixed with a `$` and Messages.app will replace them with the contact's actual name before showing them to the user. However on the iOS Simulator and iOS 10 beta1 I haven't be able to reproduce the intended behavior. It still shows up as the raw UUID string in Messages (thanks to [@zachsimone](https://twitter.com/zachsimone) for the heads up). *Update 7/7/16: Fixed in beta2.*

For example:

```swift
let layout = MSMessageTemplateLayout()
layout.caption = "My name is $\(conversation.localParticipantIdentifer.uuidString)."
conversation.insert(message, localizedChangeDescription: nil)
```

#### MSMessageTemplateLayout Attributes

A couple quick notes on `MSMessageTemplateLayout`'s attributes.

* If you include both `image` and `mediaFileURL`, `mediaFileURL` will be ignored.
* Apple recommends your images be 300x300pt @3x, but also says you should experiment with what looks best for your use case.
* `mediaFileURL`/`image` can be an PNG, JPEG, GIF, or video.
* Media will be compressed before being sent.
* You should avoid writing text to an image due to possible compression/scaling artifacts rendering it illegible.
* If you don't include an `image` or `mediaFileURL` in your template, `imageTitle` and `imageSubtitle` will be ignored.
* `caption` is limited to 3 lines with an automatically added trailing ellipsis.
* `subcaption` is not shown unless a caption is present.
* `subcaption` is limited to 1 line and no trailing ellipsis is added.
* `trailingCaption`/`trailingSubcaption` seem to mirror the behavior of their `caption`/`subcaption` counterparts.

{% caption_img /images/messages-template-layout-test-large.png Various configurations of MSMessageTemplateLayout. %}

#### URLs

As previously mentioned, the URL you attach to an `MSMessage` will be available directly to the user in two cases:

* The recipient views the message on iOS 9 or earlier.
* The recipient views the message on macOS.

If your app does not have a default web presence that can render these links in a web browser, you may want to have the base URL point to a sort of 404 explanation page. Something like "Hey, you received a link created with MyApp. Open it on an iOS 10+ device to get started." You can still encode parameters in the query string this way.

Another gotcha is that only http/https scheme URLs will be sent to other platforms. If your message doesn't lose any context without a URL, you can use this to your advantage and not worry about implementing the 404 page.

#### Expiring

You can set your messages to expire by default by setting `shouldExpire` on the `MSMessage` instance. This behavior is the same as other Messages.app expiring messages and can be overridden by the recipient.

### Icon Template Sizes

For reference, here are the listed sizes for Messages App Icons.

Messages: 27x20pt @1x @2x @3x
Messages: 32x24pt @1x @2x @3x
Messages App Store: 1024x768pt @1x
Messages iPhone: 60x45pt @2x @3x
Messages iPad: 67x50pt @1x @2x
Messages iPad Pro: 74x55pt @2x

{% caption_img /images/messages-app-icon-sizes.png Various configurations of MSMessageTemplateLayout. %}

### Stickers

I've neglected the sticker classes, but these are worth mentioning as many extensions will be sticker focused. Apple's IceCreamBuilder example extension uses these classes.

#### MSSticker

`MSSticker` is the model class for stickers.

Create `MSSticker` by passing in a `fileURL` and `localizedDescription` of the sticker contents. The initializer can throw an `NSError`. From the docs:

* The file must have a maximum size of 500KB.
* The file must conform to kUTTypePNG, kUTTypeGIF or kUTTypeJPEG.
* The image loaded from the file must be no smaller than 300px X 300px and must be no larger 618px x 618px.

#### MSStickerView

The drop-in `UIView` subclass for stickers is `MSStickerView`. Initialize it with an `MSSticker` or set the `sticker` property later.

This class provides drag and drop behavior for pulling stickers from the collapsed view of an extension into the main conversation. It also provides outlets for inspecting and controlling animation of GIFs:

```swift
// MSStickerView.swift (abridged)
public var animationDuration: TimeInterval { get }
public func startAnimating()
public func stopAnimating()
public func isAnimating() -> Bool
```

## Things You Can't Do

I've seen a few questions already on the developer forums about what can and can't be done. I'll document a few of those here and may add more in the future.

### Sending Messages Without User Interaction

You cannot send a message directly on behalf of the user. That means you cannot skip the part where your newly minted message is deposited into the Messages.app text field and the user taps the send button. Apple wants to make sure that the user has the final say on what is sent on their behalf.

### Accessing Text Or Messages Not Created By Your App

You cannot access any information that was not created specifically by your extension. That means you cannot access the contents of Message.app's text field directly. You cannot access any other messages in the conversation history.

Any text input you require must be entered by the user into a text field you've created in the expanded mode of your extension.

## Known Issues

I've mentioned a few of the known issues in the text above. Here are a few more I'll add to as they're reported and resolved.

### Changes to insertMessage

The function signature of `MSConversation.insertMessage` has changed (beta1 -> beta2) for an unknown reason. The `localizedChangeDescription` parameter was removed. There is currently no way that I can determine to create a change description. The documentation is also out of line with the function itself.

## Wrap Up

I've given an overview of Messages Extensions. We then walked through an example extension that uses some of the available features of Messages.framework. Finally, we covered a few advanced features.

I'm excited to see what kinds of Messages Extensions are available at iOS 10 launch come this Fall.

I'll do my best to keep this post updated as subsequent betas are shipped. Feel free to ping me [@twocentstudios](https://twitter.com/twocentstudios) on Twitter if you have questions or comments.

*Thanks to Evan Coleman for reading drafts of this post.*
