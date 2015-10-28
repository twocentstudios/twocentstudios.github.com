---
layout: post
title: Objective-C API Wrapper for myGengo
date: 2012-06-18 20:28
comments: true
categories: 
redirect_from: "/blog/2012/06/18/objective-c-api-wrapper-for-mygengo/"
---

Last weekend, I decided to take on what I thought would be a small task and turned into be a moderately small task. I wrote an API wrapper for the myGengo translation web service.

MyGengo uses a worldwide base of qualified translators to provide quick turnaround times for translation jobs. One of their selling points is a well documented API that developers can use to create automated upload flows for their companies.

They have official API wrappers for C#, Java, Perl, PHP, Python, and Ruby. After I was completely finished writing my Objective-C wrapper, I realized they had a lot more unofficial APIs in even more various languages (including Objective-C, but I'll get to that in a bit). 

## Use Cases

I decided to take on an Objective-C wrapper for a couple reasons. Although the authentication is a little tricky, I still think it would be cool to have an iOS interface for their platform. One of the upsides to this would be being able to check translation statuses on the go and respond with comments. I'm not sure if anyone would be directly submitting text to translate from an iPhone (slightly more likely with an iPad). But a native OS X app might be useful, especially in situations like I found at my day job.

## Instruction Manuals

I used to write a lot of instruction manuals for electronics at my day job. The standard way our marketing department would handle these would be:

* The technical writer would write the copy in a Word document.
* The designer would copy all that into an Adobe InDesign document.
* The designer would create the layout.
* The designer would then copy the text back out into another Word document with a table row for each sentence and a column for each language.
* The Word doc would be emailed to a translator.
* Two to four days would pass.
* The translator would send back the Word document with the other languages filled in.
* The designer would copy the English pages of the InDesign document and copy and paste the text from the Word document into InDesign.
* The InDesign document would be routed for proofing and checked against the translation Word document.

It was a very arduous process as you can see, and resulted in a lot of errors. Being the impromptu technical writer with a little design in my blood, I decided to take on the task of learning InDesign well enough that I could write the copy for the manuals and do the basic layout directly in InDesign. This saved one step and a lot of back and forth with the designers trying to explain what needed to be done with some of the layout.

However, it did not solve the problem of having to copy text in and out of the final design document. This is where something like myGengo would have been cool. You could implement a way to read the raw text out of the InDesign document, then somehow provide the translation back into the template, all in an automated workflow. The designer could then focus on cleaning up the design and doing what they do best instead of all the manual copying and pasting that inevitably leads to errors.

I'm not sure if I'm ready to take on the task of automating this process with something like myGengo. Our company doesn't do enough manuals to justify the time, first of all. It would take a lot of effort to learn the InDesign file format well enough to parse it and insert text back into it. And finally, I'm not sure the old guard would get behind using someone other than their trusted translator to do the actual translation work.

## Implementation

That was a bit of a tangent, so lets talk more about the implementation.

Because I know Ruby fairly well, I decided to model my wrapper  closely off of the Ruby wrapper. I followed the structure closely (maybe a little too closely), but this helped get me started quickly, and I learned the layout of the API along the way.

### Overall Structure

I refactored the API into two parts about half way into my coding. The first class holds the authentication information in a singleton. The second class provides instances of the actual API handler that can be used by multiple view controllers.

The logic is that you can initialize the credentials singleton class once in your app delegate based on keys stored in the iOS keychain. Then, each view controller can have an instance of the handler itself that uses those shared credentials.

### Handler Structure

The handler class has a couple helper functions that deal with the private key hashing and UNIX timestamps. I had to do a little research, but luckily the CommonCrypto library and Stack Overflow provided what I needed. Most of my previous work was with read-only APIs, so I never had to deal with authentication before. I got a good primer in how secure hashing of parameters works.

The handler has two functions whose job is to assemble the parameters and send out the request to the server. One is for GET and DELETE requests. The other is for POST and PUT requests.

Over time, these two functions became more and more similar, but I never did end up combining them like I should have. They share quite a bit of code, but they're just different enough that I'm a little hesitant to refactor without running the full gamut of manual testing (which I don't quite have the time for right now). This is the same way the Ruby library was laid out.

The handler then has a function for each API endpoint. I made another decision to make all the functions similar in that almost all of them ask for a single NSDictionary of parameters as their input. I was very back and forth on this, because it's very un-cocoa. But after looking over all the functions, there are enough outlier functions that would require a primary NSDictionary anyway that there were two reasons for keeping this structure: consistency and future operability.

If the API user has to look up the exact parameters from the API for function X, they might as well just have the docs open for function Y even if it just asks for an :id parameter. Future operability comes into play since I don't work with the API enough to keep track of any changes that might occur in future versions. Since I'm less rigid in the function structure, I can handle extra parameters without having to change any of the code. All the user has to do is change the API version DEFINE and assemble the params dictionary differently. Still, it was a tough decision, and it was mostly a time and attention decision.

## Other Library

I mentioned earlier that I found out there was another Objective-C API wrapper already on github. I wrote my whole implementation without knowing about this, even though it should have been my first instinct to check github. In retrospect, I'm glad I did mine without having any outside influence. The author of the other library did things a little bit differently than I did, and I think both of our implementations have their places.

## Wrap Up

Overall, this was a good exercise for me. This is my first real authored open source project. Going in with a goal of open sourcing this kept me honest in my documentation and helped me cut less corners than I would have if it was just a means to an end of getting another app done. Plus, it forced me to learn some more about git and github, and authentication, and the ASIHTTPRequest library, and JSONKit, and API design in itself. I tried to follow some of Matt Gemmell's advice in [API Design](http://mattgemmell.com/2012/05/24/api-design/), and did my best to think about the design from an outside-in perspective.

I'd still like to tie up those loose ends with formatting, refactoring, and even stuff like ARC and OS X support. I was also planning on doing an example project. Hopefully my README and test fixtures are clear enough for end users to follow.

I'm not sure where I'm going to go with the library in the future. But I hope someone finds it useful.

You can view this project on github [here](https://github.com/twocentstudios/myGengo-objc).