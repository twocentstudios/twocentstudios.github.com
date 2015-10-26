---
layout: post
title: "My Jekyll/Octopress Cheatsheet"
date: 2011-12-27 21:26
comments: true
categories: 
---

This is my first Jekyll post. And as such, it seems fitting to cram all these new commands into a cheat sheet post so I can take my time learning them (and I don't have to search through just a few pages of documentation).

### Pushing Changes to the Blog Source

		cd octopress
		git add .
		git commit -m 'modded blog source'
		git push origin source

### Creating New Posts

New posts are created it in the source/_posts directory.

		rake new_post["title"]

### Adding Categories 

Categories are defined in the yaml header.

		# One category
		categories: one

		# Multiple categories
		categories: [one, two, three]

### Draft Posts

Add the following to the yaml header.

		published: false

### Images

{% raw %}
		{% caption_img /images/image_name.jpg Caption for the image %}
{% endraw %}
		
### Syntax Highlightling

Surround normal code blocks with:

{% raw %}
		{% codeblock Title or something (FileName.m) lang:objc %}
			code here
		{% endcodeblock %}
{% endraw %}

### Generate & Preview

		rake generate   # Generates posts and pages into the public directory
		rake watch      # Watches source/ and sass/ for changes and regenerates
		rake preview    # Watches, and mounts a webserver at http://localhost:4000

### Generate & Deploy

		rake generate
		rake deploy