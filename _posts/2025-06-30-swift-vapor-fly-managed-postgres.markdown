---
layout: post
title: "How to Configure Fly.io Managed Postgres with a Swift Vapor App"
date: 2025-06-30 20:00:00
image: /images/fly-managed-postgres-connection-urls.png
tags: vapor debugging apple
---

I migrated my Swift Vapor app from Fly.io's regular Postgres to their new Managed Postgres service. As could be expected, this did not go smoothly, so below is a quick guide and the associated debugging story.

## TL;DR: Quick Setup Guide

This assumes you've already got a working Docker file and you've had no issue deploying your Vapor App to Fly.io. (This is not a full Vapor + Fly.io setup walkthrough).

(There's also a chance the below setup is required for other app runtimes as well beyond Vapor, so if you found this via post in anger via search engine, give it a try and see if it fixes your problem.)

Assuming that, here is how you create a Managed Postgres instance and connect it to your App:

### 1. Fly.io setup (admin panel)

- Open your organization page.
- In the left sidebar, click "Managed Postgres".
- In the main content window, click "Create new cluster".
- Configure it as necessary.

### 2. Find the DATABASE_URL

{% caption_img /images/fly-managed-postgres-connection-urls.png Redacted Managed Postgres Connect page %}

- In the Managed Postgres cluster you just created, click "Connect" in the sidebar.
- Use the **Connection URL** under the "Connect to your database" header (not the Pooled Connection URL). Pooled Connection URL ignores SSL parameters.
- Ensure you **manually add** `?ssl=false` at the end.

```bash
# ✅ Working: Direct Connection URL
# Note: `direct` subdomain AND MANUALLY ADD `?ssl=false`
DATABASE_URL=postgres://user:pass@direct.abc123.flympg.net/dbname?ssl=false

# ❌ Failed: Pooled Connection URL (ignores ssl=false)
# Note: `pgbouncer` subdomain is incorrect
DATABASE_URL=postgres://user:pass@pgbouncer.abc123.flympg.net/dbname?ssl=false
```

### 3. Add the DATABASE_URL you modified in (2) to your App Secrets

Via CLI (`fly secrets`) or the Fly.io admin panel.

```bash
fly secrets set DATABASE_URL="postgres://user:pass@direct.abc123.flympg.net/dbname?ssl=false"
```

### 4. Vapor `configure.swift` Setup

Update your Vapor configuration to prefer `DATABASE_URL`:

```swift
// Configure database - prefer DATABASE_URL if available
if let databaseURL = Environment.get("DATABASE_URL") {
    try app.databases.use(.postgres(url: databaseURL), as: .psql)
} else {
    // Fallback to individual environment variables
    try app.databases.use(.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        // ... other config
    )), as: .psql)
}
```

### 5. Deploy

```bash
fly deploy
```

## The Debugging Story

My project is a Swift Vapor (Swift on server) app plus iOS app client called Technicolor. I've been working on it on and off for a few years, which means each time I come back to it I have to spent hours or days upgrading all the disparate parts.

This time, after 2 years, I came back to the Fly.io deployment. At first, I just wanted to add a migration to the production server to prepare for the TestFlight beta release.

Trying out the deployment, everything seemed to be working at first. But I noticed that the Postgres App that ran alongside the main App in Fly.io "Apps" was now deprecated. Doing some basic reading up on the new offering called Managed Postgres, it seemed like a decent idea to migrate to it while it was on my mind.

I'm still learning the ropes with Claude Code. I [wrote about](/2025/06/22/vinylogue-swift-rewrite/) my experience about using Claude Code while rewriting an iOS project. But this is the first time I've used it for doing server side work, specifically using the `fly` CLI.

I think the first issue I ran into was that, after deployment, it _seemed_ like the new Managed Postgres instance was up and running fine since the API calls I made were successful. However, it was only after deleting the now obsoleted Postgres App instance that I realized the ENV vars were still pointing the server to the old database.

Claude Code was happy enough trying to debug the issue by tweaking random values and doing lots of 5+ minute deploys (I kept it on a long leash for a while to see how it handled the debugging). It did seem to get lucky a couple times and read the server logs at just the right time to discover the above problem (old database URL). It also eventually discovered there was an SSL error with the new database URL.

But from there it had no chance. I had to consult a bunch of other sources, many outdated, and take the reins back. I looked through the Vapor/Fluent source code to see which SSL parameters were now valid. I made a checklist of database URL variations I needed to try, updated the ENV var, waited for the deploy, and checked the logs.

Luckily I did discover a URL that worked.

Real talk: I honestly feel like Vapor was fun as a learning experience. You get to sling Swift. You get to share the model transport layer with server and client. You get to get into the weeds a bit more than a fully scaffolded solution with a plethora of drop in frameworks that solve every imaginable  problem and use case. But the community required to support a vibrant developer ecosystem has never showed up after all these years. That means that all the [DenverCoder9](https://xkcd.com/979/) problems I'm normally fine debugging myself in iOS land because it's my main focus, I'm a hopeless case in server-land. Using some JS framework or Rails is playing the much better odds that someone will have already found and solved your bug and wrote a post like this one before you did. Does that mean I'm going to rewrite the backend of this project? Not yet, but maybe one or two more of these heisenbugs and I'm going to have to cut my losses.