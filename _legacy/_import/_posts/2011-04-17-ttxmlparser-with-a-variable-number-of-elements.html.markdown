--- 
layout: post
title: TTXMLParser With a Variable Number of Elements
tags: 
- iOS
- TTURLRequestModel
- TTXMLParser
status: publish
type: post
published: true
meta: 
  _edit_last: "1"
  _syntaxhighlighter_encoded: "1"
  sfw_comment_form_password: ajOiRf9Ju8oV
---
I've probably re-solved this problem at least three times, so time to document it.

Let's say you're dealing with an XML feed response from a webservice. You're using the TTXMLParser extension. Here's an example of what we might get back from a webservice that shows a user's recently read books:

[xml]&lt;response&gt;
  &lt;book&gt;
    &lt;title&gt;The Stranger&lt;/title&gt;
    &lt;author&gt;Albert Camus&lt;/author&gt;
    &lt;completed&gt;Apr 11&lt;/completed&gt;
  &lt;/book&gt;
  &lt;book&gt;
    &lt;title&gt;Pinball 1973&lt;/title&gt;
    &lt;author&gt;Haruki Murakami&lt;/author&gt;
    &lt;completed&gt;Apr 5&lt;/completed&gt;
  &lt;/book&gt;
&lt;/response&gt;
[/xml]

The number of books is completely variable. This is the problem we're going to solve below. It could return zero, one, or more book elements.

First off, you have to tell your TTURLXMLResponse that it's an RSS feed. It doesn't actually have to be RSS, they just mean "is it going to have multiple elements with the same element name?" like we have with book elements. So we'll check that off.

```
TTURLXMLResponse* response = [[TTURLXMLResponse alloc] init];
response.isRssFeed = YES
```

Now we've got to deal with the response in requestDidFinishLoad.

```
- (void)requestDidFinishLoad:(TTURLRequest*)request {
	TTURLXMLResponse* response = request.response;

	// The root object should definitely be a dictionary
	TTDASSERT([response.rootObject isKindOfClass:[NSDictionary class]]);
	NSDictionary* feed = response.rootObject;
	
	// Use &quot;arrayForKey&quot; not &quot;objectForKey&quot; as explained below
	if ([feed objectForKey:@&quot;book&quot;] != nil])
		NSArray* entries = [feed arrayForKey:@&quot;book&quot;];

	// { Parse the feed and do whatever else you need to do}
}
```

The important part of the code is using arrayForKey instead of objectForKey. If we dig into the Three20 code:

```
@interface NSDictionary (TTXMLAdditions)
//...
/**
 * @return Performs an &quot;objectForKey&quot;, then puts the object into an array. If the
 * object is already an array, that array is returned.
 */
- (NSArray*)arrayForKey:(id)key;
```

If the service returns only a single book, the object we get back for the "book" element will still be an array, but it will be an array of <i>strings</i> and not an array of <i>dictionaries</i> like we expect. ArrayForKey solves this by giving us back an array of dictionaries even if there is only one entry.

Note that I had to check that an object existed for books before calling arrayForKey. In my experience, this method <i>will</i> crash if an object doesn't exist for the key, so be careful!
