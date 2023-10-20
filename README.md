# README

## Background

I wrote a post when I first converted from Octopress to Jekyll, but it assumes that I'll never need to fix anything. Therefore, this readme.

## Making a new post

There's a new post script `./new.sh`, but it doesn't correctly format the post.

Posts should go in the `_posts` folder.

Post titles should have hyphens instead of spaces and be all lowercase. This is due to the GitHub pages server mangling the file names.

Example: `2018-02-18-testing-reducers-and-interactors.markdown`

## Making a new page

Check out `about.md` at the root for how to make a new markdown-processed page.

Check out the `apps` folder for how to include random non-processed files.

For pages that should be included in the header, add `header: true` to the front matter.

Add an image to open graph tag by adding to the front matter `image: /images/my-image.png`.

### Layouts

In the page front matter, a layout can be specified.

Use `standalone` for a page that shouldn't include the header or footer.

Use `page` for a page that includes the header and footer.

HTML pages can be processed, have a layout, and include front matter and templating. See `blog.html`.

## Post formatting

Images go in the `images` folder. Raw references are like `![An image](/images/some-image.jpg)`. Captioned variant uses a plugin and special syntax like `{% caption_img /images/photophono-screens.png w200 h200 Walkthrough %}`.

Links to posts in this blog look like `[Timehop: A Retrospective](/2015/11/03/timehop-a-retrospective/)`.

## Development

```zsh
bundle exec jekyll build
bundle exec jekyll serve --livereload
```

## Deployment

```zsh
./deploy.sh
```

## How this blog works

Every file and folder that's not in `_site` folder or the `excludes` list in `_config.yml` is processed and overwritten into `_site`.

The outer directory and inner `_site` directory have separate git repos that each have their origin set to the same GitHub repo, but each remains on a different branch.

The outer directory's branch is `source`. `_site` directory's branch is `master`. **These branches should never switch.** Only the directory should be changed (and even then

`_site`'s git repo is not overwritten when the folder's contents are replaced by Jekyll's build function. This allows git to track the changes, create commits, and push to `origin/master`, which is the branch that is served to the live site on GitHub pages.

### The deploy script

The deploy script has a few assumptions:

1. You're in the outer directory.
2. You're on the `source` branch.
3. The `source` branch is allowed to have uncommitted changes.

Then the following happens:

1. The site is regenerated into the `_site` directory.
2. The terminal is automatically switched the `_site` directory. Again, the separate git repo within this folder should be pointing to its `master` branch.
3. A new commit is created with all the changes since the last deploy, with the current timestamp as the message.
4. This commit is pushed to master, kicking off a job on GitHub pages.
5. The terminal is automatically switched back to the root directory.

## Analytics

Google Analytics pre v4 was sunsetted in August 2023 and did not record page visits between then and when I upgraded the tracking code in October 2023.

At some point it'd be nice to update to a more privacy-centered analytics provider, but for my current low traffic numbers I think GA is okay.
