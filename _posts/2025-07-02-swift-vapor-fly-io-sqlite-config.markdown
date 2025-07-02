---
layout: post
title: "Configuring Swift Vapor on Fly.io with SQLite"
date: 2025-07-02 14:00:00
image: /images/
tags: vapor sqlite hosting flyio apple
---

This post is a guide for getting a [Swift Vapor](TODO) server-side app up and running on [Fly.io](TODO) with SQLite as the database provider. The target audience is Swift developers who are inexperienced with servers and deployment.

I'm assuming you've already chosen Vapor, Fly.io, and SQL as your tools of choice and will not discuss any of their tradeoffs.

The below setup using SQLite avoids the operational complexity of maintaining a full Postgres server. Especially as a beginner that does not need the full breadth of functionality Postgres offers beyond SQLite. This is a worthwhile tradeoff for:

- Toy apps that still need 24/7 network access
- Prototypes and proof-of-concepts intended for a limited audience
- Bespoke apps for you and your friends

Fly.io's [pricing](https://fly.io/docs/about/pricing) is pay-as-you-go so it's hard predict exactly how much you, the reader, will be on the hook for. As of this writing, provisioning a system described in this post _that is stopped, serving zero requests_ would be $0.30 USD per month ($0.15/GB for the Machine and $0.15/GB for the Volume). You should monitor your usage closely. Going along with the intended use cases, this post will assume you want the absolute cheapest of everything.

If you're looking for a more robust database solution in the same vein, my [previous post](TODO) discusses [Fly.io Managed Postgres Service](TODO) but is not as thorough a walkthrough as this post.

Strategies for automated backups, automatic failovers, high availability, or basically anything you need for a production deployment are mentioned briefly at the end of the post. Note also that the particular setup described in this post specifically disallows multiple machines; you are locked into one machine running in one region (great for limiting complexity, awful for production-quality customer service).

On successful deployment, you'll have an app accessible via the public interface at `myapp.fly.dev`.

## Prerequisites

This guide assumes you have:

- A working Vapor app (we'll use "myapp" as an example)
- Basic familiarity with the [`fly` CLI](TODO)
- Your app already builds and runs locally with or without an existing Postgres integration

We will not cover any sort of data migration.

## Step 1: Project Structure

Your Vapor project should look like this:

```
myapp/
├── Package.swift
├── Dockerfile
├── fly.toml
├── Sources/
│   └── App/
│       ├── configure.swift
│       ├── routes.swift
│       └── ...
```

## Step 2: Configure Package Dependencies

First, update your `Package.swift` to use SQLite (instead of PostgreSQL):

```swift
// Package.swift
let package = Package(
    name: "myapp",
    platforms: [
        .macOS(.v12),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"), // <- SQLite driver
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"), // <- SQLite driver
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
    ]
)
```

## Step 3: Configure Database in Vapor

Update your `configure.swift` to use environment-based database paths:

```swift
// Sources/App/configure.swift
import Fluent
import FluentSQLiteDriver // ← Import SQLite driver
import Vapor

public func configure(_ app: Application) throws {
    // Configure SQLite database with environment-based paths
    let databasePath: String
    if app.environment == .production {
        // Production: Use volume-mounted path
        databasePath = "/data/db.sqlite"
    } else {
        // Local development: Use project root
        databasePath = "./db.sqlite"
    }
    
    app.databases.use(.sqlite(.file(databasePath)), as: .sqlite)
    
    // Add your migrations here
    // app.migrations.add(CreateTodo())
    
    try routes(app)
}
```

**Key concepts:**
- **Environment detection**: Vapor automatically sets `app.environment` based on deployment context
- **Volume mount**: Production SQLite files live on persistent storage at `/data/`
- **Local development**: Database file created in your project directory

## Step 4: Update Dockerfile

If you do not know what you're doing, you should use the latest [Vapor Dockerfile template](https://github.com/vapor/template/blob/0330dd9f4d1314ea122c90f3f3db3a24a2d97761/Dockerfile). Then make the following modifications to include SQLite3 client tools and create the data directory:

```dockerfile
# ...

# Install system packages including sqlite3 for database access
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt-get -q update && apt-get -q dist-upgrade -y && \
    apt-get -q install -y ca-certificates tzdata sqlite3 && \
    rm -r /var/lib/apt/lists/*

# ...

# Copy built executable
# ...

# Create data directory for SQLite database with proper ownership
RUN mkdir -p /data && chown -R vapor:vapor /data

# Start the Vapor service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./{{name}}"]
CMD ["serve", "--auto-migrate", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
```

**SQLite-specific additions:**
- `sqlite3` (optional) inspect your db via the remote server console
- `/data` directory creation with proper ownership
- `--auto-migrate` flag runs database migrations on startup

## Step 5: Configure fly.toml

Create (via `fly launch`) or update your `fly.toml` configuration selectively:

```toml
# fly.toml
app = "myapp"
primary_region = "ord"  # <- Choose a single region close to your users
kill_signal = "SIGINT"
kill_timeout = "5s"

[[vm]]
  memory = "256mb"  # <- Lowest available memory & cpus
  cpus = 1

[build]

[deploy]
  release_command = "migrate --auto-migrate --env production"  # <- Runs migrations before deployment

[env]

[mounts]  # <- Volume configuration for persistent SQLite storage
  source = "myapp_db"  # <- Matches the volume name you create next
  destination = "/data"  # <- Matches the directory you created in Dockerfile

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"   # <- Automatically stops machines when idle
  auto_start_machines = true    # <- Automatically starts machines on first request
  min_machines_running = 0      # <- Allow zero running machines when idle

  [http_service.concurrency]
    type = "requests"
    hard_limit = 200
    soft_limit = 100

  [[http_service.checks]]
    interval = "10s"
    timeout = "2s"
    grace_period = "5s"
    method = "get"
    path = "/"
    protocol = "http"
```

### Fly.io concepts

- **App**: Holistic settings describing your application. If you had a production and staging, you'd have two Apps total with similar `Dockerfile`/`fly.toml` files. In our setup, one **App** will _always_ contain one **Machine** and one **Volume**.
- **VM**: Virtual machine specifications (RAM, CPU).
- **Machine**: The actual running instance of your app. Pairs 1-to-1 with a **Volume**. Is recreated fresh on each deploy.
- **Volume**: Persistent disk storage that survives deployments. This is where you can keep your `sqlite.db` file.
- **Auto-scaling**: Automatically stops/starts machines based on traffic. We set `auto_stop_machines = "stop"` to save money assuming that our app has significant idle periods. `auto_start_machines = true` automatically boots a machine when a request comes in. It takes about ~2s.

## Step 6: Create Fly.io App

Initialize your Fly.io app. Do it from the web interface or the CLI instructions below:

```bash
# Create new Fly.io app
fly apps create myapp

# Or if app already exists, verify it
fly status -a myapp
```

{% caption_img TODO "Fly.io Apps dashboard showing your newly created app" %}

The Fly.io dashboard will show your app in the "Apps" section with a status indicator.

## Step 7: Create Storage Volume

SQLite needs persistent storage that survives deployments. Create a **Volume**:

```bash
# Create 1GB volume for SQLite database
fly volume create myapp_db --region ord --size 1 -a myapp -y
```

**Volume concepts:**

- **Persistent storage**: Data survives app deployments and restarts.
- **Region-specific**: Must be in same region as your machines.
- **Size**: Start small with 1GB (you can expand later if needed).

{% caption_img TODO "Fly.io Volumes dashboard showing the newly created volume" %}

Verify the volume was created:

```bash
fly volumes list -a myapp
```

You should see output like:
```
ID                      STATE   NAME     SIZE REGION ZONE ENCRYPTED ATTACHED VM CREATED AT     
vol_abc123xyz           created myapp_db 1GB  ord    df19 true                  2 minutes ago
```

## Step 8: Deploy to Fly.io

Deploy your app:

```bash
# Deploy from your project root directory
fly deploy . -a myapp
```

This will:

1. Build your Docker image
2. Create a **release command machine** to run migrations
3. Create/update your **app machine** with the new image
4. Mount the volume to `/data`

For a small app, the whole process can take about 5 minutes. If you're redeploying with no code changes, it's less than 30 seconds.

{% caption_img TODO "Fly.io deployment logs showing successful SQLite migration" %}

During deployment, watch for these log messages:

- `Running myapp release_command: migrate --auto-migrate --env production`
- `Starting prepare [database-id: sqlite, migration: ...]`
- `Machine ... update succeeded`

## Step 9: Verify Deployment

Check that everything is working:

```bash
# Check app status
fly status -a myapp

# Test your app
curl https://myapp.fly.dev/

# View recent logs
fly logs -a myapp
```

{% caption_img TODO "Fly.io app status showing running machine with mounted volume" %}

The status should show:

- **State**: `started`
- **Health Checks**: Passing
- **Volume**: Attached to your machine

## Step 10: Access Your Database

To inspect your SQLite database in production:

```bash
# Wake up your machine (if auto-stopped)
curl https://myapp.fly.dev/

# SSH into the machine
fly ssh console -a myapp

# Access SQLite database (sqlite3 is pre-installed)
sqlite3 /data/db.sqlite
```

Inside SQLite:
```sql
.tables          -- List all tables
.schema users    -- Show table structure  
SELECT * FROM users LIMIT 5;  -- Query your data
.quit            -- Exit
```

{% caption_img TODO "Terminal showing SQLite3 session inside Fly.io machine" %}

## Local Development

For local development, your SQLite database will be created as `./db.sqlite` in your project root:

```bash
# Run locally
swift run Run serve --hostname 0.0.0.0 --port 8080

# Access local database
sqlite3 db.sqlite
```


## Troubleshooting

#### Machine won't start

```bash
# Check machine status
fly machine list -a myapp

# View detailed logs
fly logs -a myapp
```

#### Database connection errors

- Verify volume is mounted: `fly ssh console -a myapp` then `ls -la /data/`
- Check file permissions: SQLite file should be owned by `vapor:vapor`

#### Volume not attaching

- Ensure volume and machine are in the same region: `fly volumes list` and `fly machine list`.
- Volume names in `fly.toml` must match created volume name exactly.

## Backups, and where to go from here

**Important**: Unlike managed databases, you're responsible for SQLite backups. 

Fly.io automatically creates Volume snapshots with 5-day retention, but these aren't easily accessible for restore.

In approximate order of complexity/reliability:

#### Irregular manual backup

The most low tech backup solution: copy the database from the server to your local machine whenever you remember to do so.

```bash
# Download production database
curl https://myapp.fly.dev/  # wake machine
fly ssh sftp get /data/db.sqlite ./backup-$(date +%Y%m%d).sqlite -a myapp
```

#### Regular manual backup

Set a repeating calendar entry or reminder to remind you to run the `sftp` command.

#### Automated manual backup

Use a `cron` job or `launchd` on macOS to automatically run the `sftp` command,

#### S3 object storage backup

Set up an AWS S3 account (or equivalent) with a dedicated bucket to store `sqlite` backups. Then add a `cron` job to a GitHub Action to perform the backup from Fly.io to the S3 bucket.

#### Add Litestream for SQLite backups

See [litestream.io](https://litestream.io/).

#### Add LiteFS to replicate SQLite to multiple machines

See [this docs page](https://fly.io/docs/litefs/).

#### Use Postgres

Congratulations, your app is successful enough to need Postgres.

## Summary

This SQLite setup is intended for beginners and hobby projects and gives you:

- **SQLite database** with persistent storage
- **Auto-scaling** machines that stop when idle
- **Automatic migrations** on deployment  
- **Database access tools** for debugging

