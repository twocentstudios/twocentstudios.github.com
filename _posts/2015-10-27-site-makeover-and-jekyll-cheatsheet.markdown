---
layout: post
title: Site Makeover and Jekyll Cheatsheet
date: 2015-10-27 21:56:36
---

I took a few days to migrate my blog from [Octopress](http://octopress.org/) to [Jekyll](https://jekyllrb.com/). Octopress is an opinionated fork based on Jekyll so it wasn't too crazy. There were a couple hangups though, mostly due to the fact that I never bothered to learn how a lot of the magic of Octopress worked.

The major changes are:

* The blog root is no longer at `/blog`. I had to add redirect pages with the jekyll-redirect-from plugin.
* The root isn't a single page site like the previous version.
* I ditched the heavy green background for a cleaner white.
* I removed the special Octopress syntax highlighting in favor of Jekyll's default.
* The only plugin I've kept is caption_image_tag, which unfortunately makes it so I can't have github generate the site for me.
* I had to write my own simple deploy script to handle pushing the rendered site to the master branch and the source to the source branch on each change.
* I modified the CSS from the base Jekyll config, bringing over a few styles from the previous blog.

I'm hoping getting a streamlined workflow will encourage me to blog about topics both large and small in scope.

### Creating and deploying

```
> $ cd twocentstudios
> $ ./new.sh Why I've Decided To Blog More About Blogging
> $ git add .
> $ git commit -m "Add post"
> $ ./deploy.sh
```

### Jekyll basics

```
> $ jekyll build
> $ jekyll serve
```
