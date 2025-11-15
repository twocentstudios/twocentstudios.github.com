---
layout: post
title: "Comprehensible Later: Read-it-later for Language Learners"
date: 2025-11-15 11:57:31
image:
tags: apple ios comprehensiblelater app
---

This post is a short retrospective on Comprehensible Later, my working-title for a read-it-later iOS app prototype I worked on last week. Although it's currently in private beta on Test Flight, I want to share the motivation and technical challenges I ran into while working on it.

## What is Comprehensible Input

[Comprehensible Input](https://en.wikipedia.org/wiki/Input_hypothesis) is part of a language acquisition framework first introduced by [Dr. Stephen D. Krashen](https://www.sdkrashen.com/). The framework states that language is separately _acquired_ and _learned_. _Acquisition_ happens by ensuring ample input (reading or listening) with the important caveat that the input is _comprehensible_ at the learner's current level. _Learning_ happens through comprehensive study of rules and vocabulary. From this [summary](https://www.dreaming.com/blog-posts/the-og-immersion-method):

> When we receive comprehensible input, the conditions are met for our brain to be able to use its natural ability to acquire language, without having to do anything else. There’s no need to study, review vocabulary, or practice anything. Watching and reading itself results in acquisition.

In some senses, this method seems intuitive, not in the least since almost all children acquire language skills before they begin formal teaching. In a second-language context, [graded readers](https://en.wikipedia.org/wiki/Graded_reader) – books written for various non-native language levels – have existed for over a century. Wikipedia even has a [simple English](https://simple.wikipedia.org/) language variant for many common articles. I've occasionally used the modern [Satori Reader](https://www.satorireader.com/) service for Japanese graded texts. 

But I think the important part is recognizing exactly _how basic_ you need to make some input in order for it to be understandable, especially at the absolute-beginner level. In a since-removed introductory YouTube video from the creator, he shows a session of an instructor sitting with a zero-level beginner student, pointing at vivid images in a travel magazine and gesturing heavily and explaining the contents very slowly in the target language as the primary means of bootstrapping.

Language is so multi-dimensional that it's incredibly time consuming – both as a creator _and_ a consumer of materials – to get the exact level of material that is both comprehensible but challenging enough to increase your overall ability. Then add another dimension of _motivation_: as a reader, how do you find materials with a subject matter that's interesting to you and will keep you motivated to push through word-after-word, page-after-page, day-after-day?

This led to a hypothesis:

- Graded readers are usually close to the correct difficulty to facilitate learning, but do not have an audience wide enough to support a wide variety of interesting subject material.
- Native materials cover an infinite range of interesting topics, but are infeasible to read until the latest stages of language acquisition. 
- One of the most commonly accepted use-cases for LLMs is text summary and translation.

**What if we used LLMs to translate any native article on-demand to the user's exact target language level?**

The barriers to this being feasible are:

- Can an LLM properly translate from e.g. Native Japanese to JLPT N4 level Japanese in a "natural" way – where it is simultaneously challenging, comprehensible, and accurate?
- Can the translation happen fast enough to fit within a user's desired language-learning workflow?
- What additional resources are required to facilitate language learning? In-line dictionary lookup? An SRS system? Customized word lists?
- What unique points are there to each target language that increase the interface complexity? For example, for Japanese learning, should we include furigana for all potentially unknown kanji?
- Does it also make sense to allow translation from e.g. Native English to simple Japanese (if the target language is Japanese)?

## Specification for the prototype app

I've used 2025 frontier LLMs to write and translate simple versions of text before, so I'm confident it's either possible now at a minimally acceptable translation quality or will be in the very near future.

What I wasn't confident about is whether it's cost prohibitive or time prohibitive to use the highest quality reasoning models to do the translation.

In retrospect, I should have spent at least a little more time doing bench testing on the API versions of various models on a wide array of sample articles. Instead, I took the less (more?) pragmatic route of jumping into the implementation for an app prototype that I could start using ASAP in context, as well as distribute to a few friends.

My initial thought was that my main source of content would be blog posts and news articles I come across from my everyday feed scrolling. But I also felt I should support translating raw text too, like that from social media posts.

I considered a Safari Extension to replace existing text on a webpage with the simplified translation, similar to how the built-in translation function in Safari works. But my gut-feeling was that this would be too limiting for language learning use cases. Even reading a text at a simpler level of a target language still takes enough time that it would be better to ensure the user doesn't feel obligated to read everything at once. Additionally, this wouldn't work for native text outside of Safari.

My next thought was a Share Extension. Share Extensions are old iOS technology, but still highly used and useful. In a share extension I could display the translated article content in a dedicated modal and have full control over its presentation and layout.

However, I also wanted to support the read-it-later use case. Personally, I stumble upon articles when doing feed scrolling sessions when I have a few minutes on the train but don't necessarily have the time to read the whole article, even in English, at that time. I use Instapaper for read-it-later for English articles and I felt this would be a similarly useful use case to model my app after.

With that in mind I got to work on the actual prototype with the following initial spec: 

- A native app that:
	- keeps a list of articles imported from URLs or as raw text.
	- has a detail view that shows both the original and translated versions of the text.
- A share extension that:
	- immediately processes the shared URL or text and displays it in the share modal.
	- allows the user to optionally save the translated text in the app for later.

## Implementation

I worked through several iterations of a detailed implementation spec with Claude and Codex then set them off to work getting the foundations of the app in place. This wasn't exactly vibe coding because I specified technologies and packages to use up front and guided their output along the way. But I was still aiming to have the agents create the clay that I'd be molding in the next phase.

### Packages

The key packages that would make this closer to a weekend prototype and not a months-long project were:

- [swift-readability](https://github.com/Ryu0118/swift-readability) - wrapper for Firefox's reader-view parsing library for stripping down a full page HTML to its essential content.
- [AnyLanguageModel](https://github.com/mattt/AnyLanguageModel) - use any LLM API with Apple's Foundation Models SDK interface.
- [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) - display the full Markdown spec in SwiftUI (note: I later replaced this).
- [Demark](https://github.com/steipete/Demark) - convert HTML-to-Markdown.
- [Ink](https://github.com/JohnSundell/Ink) - convert Markdown-to-HTML.
- [sqlite-data](https://github.com/pointfreeco/sqlite-data) - SQLite wrapper for local article storage and observable data layer for the app.

### Data flow

The initial data flow for articles imported via URL was the following:

```
Input URL     ->     HTML Data    ->   HTML UTF-8 String   ->    Clean HTML   ->   Markdown   ->   Translated Markdown   ->   Display
         URLSession     String(data:encoding:)         Readability          Demark        AnyLanguageModel        swift-markdown-ui
```

The initial flow for raw text:

```
Input Text  ->  Translated Markdown  ->  Display
     AnyLanguageModel        swift-markdown-ui
```

However, due to limitations with the swift-markdown-ui package, the final version of the prototype uses this flow:

```
Input URL   ->    HTML Data    ->    HTML UTF-8 String    ->    Clean HTML   ->  Markdown    ->   Translated Markdown  ->  Translated HTML  ->   Display
         URLSession     String(data:encoding:)        Readability         Demark         AnyLanguageModel              Ink                WebView       
```

With the bones of the app architecture and dependencies in place, I began testing and optimizing the data flow.

### Readability

I found a small bug in the Readability Swift wrapper where the `baseURL` parameter was inaccessible to the `URL`-based initializer `Readability().parse(url:options:)`. This prevented relative image tags from getting properly resolved to a full address. For example, on my website image tags look like `/images/example.jpg` and are resolved by my browser automatically to be either `https://twocentstudios.com/images/example.jpg` (the real server) or `http://localhost:4000/images/example.jpg` (my local machine).

Luckily, the `baseURL` parameter was accessible in the `Readability().parse(html:options:baseURL:)` initializer. As a workaround I simply needed to fetch the page data myself with `URLSession`.

### Demark

Demark has two different HTML->Markdown parsing implementations: heavy-and-accurate or fast-and-inaccurate. Since the HTML is getting pre-processed by `Readability` in advance of being passed to Demark, I'm using the fast-and-inaccurate version that doesn't load the full page in a headless `WKWebView`.

### AnyLanguageModel

As of iOS 26, Apple's local Foundation model is slow, not-ubiquitously available on devices, and (arguably) barely functional for most use cases, especially mine. Within a few years I expect it may be useful. Similarly, my impression is that any other MLX-compatible models runnable on an iOS device are not yet accurate or fast enough for my use case.

Therefore, I grabbed both an OpenAI and Gemini API key and wired them up to AnyLanguageModel for testing. I ran a few trials with the top-tier, mini, and nano variants and decided on defaulting to the mini variant as a compromise between speed, cost, and accuracy. Specifically, Gemini Flash 2.5 is the current default, but I suspect I could spend several weeks creating and running benchmarks across the dozens of closed and open models.

[AnyLanguageModel](https://github.com/mattt/AnyLanguageModel) made it easy to build a user settings-based model switcher with very little code adjustments required on my side. Technically, Gemini ships an [OpenAI-compatible endpoint](https://ai.google.dev/gemini-api/docs/openai) so I could have kept even more of the same codepath. During debugging, I realized that AnyLanguageModel wasn't passing through the `instructions` parameter to OpenAI, so I submitted a [quick PR](https://github.com/mattt/AnyLanguageModel/pull/20) and Mattt had it merged and version bumped by the next day.

In a later mini-sprint, I added a full settings screen that allows switching model provider, model, target language, target difficulty, adding custom translation instructions, and even fully rewriting the system prompt. Of course, I would never include all these settings in a production app, but it's useful for my trusted beta testers to tinker if they so choose.

![setting screen](TODO)

By default, my (simple) system prompt is:

> Faithfully translate the native-level input markdown text into the target language with the target difficulty level.
> 
> Be creative in transforming difficult words into simpler phrases that use vocabulary at the target difficulty level. Combine or split sentences when necessary, but try to preserve paragraph integrity.
> 
> The output format should be standard Markdown including all supported markdown formatting like image/video tags. Preserve all structure from the input (paragraphs, lists, headings, links, images, videos). DO NOT ADD COMMENTARY.
> 
> Target language: \(targetLanguage)
> Target difficulty level: \(targetDifficulty)
> Additional notes: \(additionalNotes)

I'll discuss my impressions of the effectiveness of this prompt a little later on.

Something I noticed almost immediately during testing was that requests were taking at minimum 30 seconds and sometimes over 60 seconds to complete. It didn't really depend on model size either. I found the same performance characteristics for both OpenAI and Gemini APIs direct from first-party servers. I thought it might be the streaming API or perhaps some configuration in AnyLanguageModel I was not in control of, so I switched back to the single-request version. It didn't help. I also began testing the same prompt and inputs from the API sandbox pages like [OpenAI's playground](https://platform.openai.com/chat/edit) and [Google's AI Studio](https://aistudio.google.com/u/1/prompts/new_chat) and saw basically the same results. 

Although the slow translation speed is a pretty substantial blocker, I felt like, at least temporarily, I could work around it in the UX by leaning into the read-it-later nature of the app. I added support for Apple's [Background Tasks](https://developer.apple.com/documentation/backgroundtasks) API so there was a greater chance that articles added early in the day would be ready to read by the time the user opened the app. 

### App UI

With the translation flow in place, I began shaping the app UI.

The list of articles was simple enough. I held off on adding lots of important, but not urgent, contextual actions like archiving and deleting from the list view.

I did add both "import from pasteboard" and "import from free text" buttons to the toolbar.

I spent more time on the article detail view. Initially, it displayed the title, import state, and translated article. My focus for adding actions was to facilitate debugging primarily for myself and secondarily for my beta testers. This meant buttons for copying the original article text, copying translated article text, deleting an article, opening the original link, and retrying the translation (with different settings).

After some initial usage, I realized I wanted to see the original text and the translated text side-by-side so that I could compare the language usage by sentence and paragraph.

However, the most time-consuming and impactful change was the markdown display system. This was a tough decision, but I think ultimately necessary for the first version. 

Originally, I was planning to use [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) to display the translated markdown text in SwiftUI. This implementation was basically plug-and-play, rendered exactly as I wanted, supported images out of the box, and was performant. However, the [one fundamental and unsolvable issue](https://github.com/gonzalezreal/swift-markdown-ui/issues/264) is that SwiftUI Text only supports paragraph level copy support and does not support character-level or word-level selection. For language learning, I absolutely need the ability to select a word and use the context action "Look Up" or "Translate" or "Copy" button. swift-markdown-ui would not be able to support this and I needed to research other solutions.

I spent nearly a full day researching and experimenting with other Markdown solutions. My second preference was to convert Markdown to AttributedString either [natively](https://developer.apple.com/documentation/foundation/instantiating-attributed-strings-with-markdown-syntax) or [with a package](https://github.com/madebywindmill/MarkdownToAttributedString), then display the AttributedString in a [SwiftUI-wrapped UITextView](https://github.com/kevinhermawan/SelectableText) with selection enabled but editing disabled. However, both the native and package versions of AttributedString initialization failed at properly respecting whitespace, newlines, and supporting images. My estimation was that it'd take significantly more time for me to grok the full Markdown spec, all the underlying packages, and then implement the required patches than I was willing to spend for a prototype.

Therefore, I pivoted to using a browser-based target view instead. iOS 26 was blessed with [WebView](https://developer.apple.com/documentation/webkit/webview-swift.struct), a modern (again) implementation of `UIWebView` and `WKWebView` before it. With a `WebView` as the new target, I used [Ink](https://github.com/JohnSundell/Ink) to convert the LLM output Markdown back to HTML, added a barebones stylesheet, and loaded these contents. I don't love using a `WebView` for this use case since it's comparatively heavy, has plenty of rendering quirks (like white background flashes), and requires a full screen layout. But at the moment it's the least-worst option.

### Share Extension and Action Extension

Unfortunately, the slow translation speed meant some of the complexity of creating a fully-featured Share Extension was in vain; it didn't make sense for the user to wait 30-60 seconds for the share extension to load a preview of the article content like I'd originally planned.

My initial vision was to load a one-page preview of the translation as quickly as possible. Then, I'd allow the user to tap a button to continue viewing the full translation in line. Or at any time they could tap a button to save the article URL (or raw text) to the main app to read later. I was planning on having an "open in app" button too, but as far as I can tell it's not supported to open an app directly from a Share Extension.

I kept the full functionality of the share extension intact in case I can solve the translation speed issue in the future. But as another workaround, I added an Action Extension. An Action Extension appears in the bottom section of the system share sheet. Like a Share Extension it can also present custom UI, however since I already have a Share Extension I made my Action Extension have no UI and immediately save the URL to the app.

### Import flow

App Extensions can share data on device with the main app using an [App Group](https://developer.apple.com/documentation/Xcode/configuring-app-groups). When the user indicates they want to add the URL or raw text to the app, the Extension serializes an `Article` model to a `json` and writes a new file to the App Group. The main app monitors the shared App Group directory for new files. When it detects a new file, it adds the `Article` to the app's SQLite database. If the `Article` already finished translation, it will include the translated markdown and no further processing is necessary. Otherwise, it will be queued for processing.

I chose not to share the SQLite database between the main app and the extensions because, since the app and extensions are separate processes, there are [myriad issues](https://swiftpackageindex.com/groue/GRDB.swift/v7.8.0/documentation/grdb/databasesharing) with using SQLite in this way. Since data sharing is one way (from extension to app) there's no need to introduce that complexity.

Adding articles from the main app instance skips the file encoding/decoding step and simply writes a new `Article` to the database.

The processing code is admittedly a bit fragile, but in testing has worked well enough that I haven't felt an immediate need to rewrite it. It uses an `enum Status` stored alongside each `Article` in the database in order to manage the translation queue, including failures. [SQLiteData](https://github.com/pointfreeco/sqlite-data) supports observation, so both the article list view and the article detail view are always up to date on an `Article`'s status.

### Localization

Localizing a prototype would be something I'd never consider doing before the advent of coding agents. The actual act of translation between a base language and another language is insignificant compared to the amount of additional tooling and operational complexity of introducing localization keys, adding comments, handling interpolation, handling pluralization rules, handling error messages and other strings generated deep in business logic, and handling the indirection involved in looking up the values for the keys. The new `xcstrings` file's autogeneration definitely helps. But it's at least an order of magnitude more work in my opinion.

All that said, coding agents can automate enough of this work that I added full localization support for Japanese for one of my beta testers who wanted to try the app for converting English to simple English. I'm still cognizant of the ongoing support complexity full localization adds to a prototype, but for now it's not a decision I regret.

### Impressions so far

What I've learned so far is that the prompt needs to be more customized to each target language and should probably go as far as including an allow-list of words to use, especially for the most basic target difficulties.

I've found the models have a hard time with native Japanese news articles. Something about the language is just so dense that my first prompt attempt does not push the model to simplify enough.

Similar to what I've found with even commercial apps like Instapaper, a large percentage of sites now have enough paywall or otherwise reader-hostile javascript that it's not enough to fetch a simple URL directly from the source. I'm not ready to handle the endless, unforgiving work of handling all the edge cases of the open web, so URL fetching is going to be best effort for the foreseeable future.

The Readability library itself is not perfect at parsing out text from pages that aren't obviously written as "articles". This isn't all that different from the built-in Safari reader mode which isn't universally supported across the entire web.

Seeing some of my blog posts in super-simple English was really fun. One of my ongoing goals is to write simpler without giving up my voice, so seeing how an LLM breaks up my sentences and phrases and clauses is enlightening (of course, not at all related to the use case the prototype was built for).

For Japanese, there's some unpredictability on how the LLM deals with kanji. Usually it includes kanji as is, but sometimes it will add the reading in parentheses directly after for literally every word. For example, "果物（くだもの）を食べる（たべる）". Native ruby/furigana support would be ideal, and possibly easier using HTML than [AttributedString](https://github.com/ApolloZhu/RubyAttribute).

## What's next?

Comprehensible Later is on Test Flight in private beta with myself and a few friends. I'm planning on collecting feedback and evaluating the app's potential for wider release. It could take another generation or two of LLM. It could take as long as waiting for local models to improve. Or the entire concept could be flawed. I'm not sure yet. But that's what the prototype is for.

Regardless of the result, it was of course a good learning experience to see what it's like to build a read-it-later service for iOS in 2025.