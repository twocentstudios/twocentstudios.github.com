---
layout: post
title: "Configuring Swift Vapor on Fly.io with SQLite"
date: 2025-07-02 14:00:00
image: /images/
tags: vapor sqlite flyio apple
---

Deploying a Swift Vapor app with SQLite on Fly.io is simpler than using PostgreSQL, but there are several specific configuration steps that aren't immediately obvious. This guide walks through the complete setup for Swift developers who are new to server deployment.

## Why SQLite on Fly.io?

For many apps, SQLite offers significant advantages:
- **No external database service** to manage or pay for
- **Single-file database** that's easy to backup and inspect
- **Excellent performance** for read-heavy workloads
- **Simplified deployment** with fewer moving parts

## Prerequisites

This guide assumes you have:
- A working Vapor app (we'll use "myapp" as an example)
- Basic familiarity with the `fly` CLI
- Your app already builds and runs locally

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
├── Tests/
└── Public/
```

## Step 2: Configure Package Dependencies

First, update your `Package.swift` to use SQLite instead of PostgreSQL:

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
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"), // ← SQLite driver
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"), // ← SQLite driver
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

Your Dockerfile needs to include SQLite3 client tools and create the data directory:

```dockerfile
# Dockerfile
FROM swift:5.10-jammy as build

# Install OS updates
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# Copy package files and resolve dependencies
COPY ./Package.* ./
RUN swift package resolve

# Copy source code and build
COPY . .
RUN swift build -c release --static-swift-stdlib

# Switch to staging area and copy executable
WORKDIR /staging
RUN cp "$(swift build -c release --show-bin-path)/Run" ./

# ================================
# Runtime image
# ================================
FROM ubuntu:jammy

# Install system packages including sqlite3 for database access
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt-get -q update && apt-get -q dist-upgrade -y && \
    apt-get -q install -y ca-certificates tzdata sqlite3 && \
    rm -r /var/lib/apt/lists/*

# Create vapor user and app directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

WORKDIR /app

# Copy built executable
COPY --from=build --chown=vapor:vapor /staging /app

# Create data directory for SQLite database with proper ownership
RUN mkdir -p /data && chown -R vapor:vapor /data

USER vapor:vapor

EXPOSE 8080

ENTRYPOINT ["./Run"]
CMD ["serve", "--auto-migrate", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
```

**SQLite-specific additions:**
- `sqlite3` package for database inspection tools
- `/data` directory creation with proper ownership
- `--auto-migrate` flag runs database migrations on startup

## Step 5: Configure fly.toml

Create or update your `fly.toml` configuration:

```toml
# fly.toml
app = "myapp"
primary_region = "ord"
kill_signal = "SIGINT"
kill_timeout = "5s"

[[vm]]
  memory = "256mb"
  cpus = 1

[build]

[deploy]
  release_command = "migrate --auto-migrate --env production"  # ← Runs migrations before deployment

[env]

[mounts]  # ← Volume configuration for persistent SQLite storage
  source = "myapp_db"
  destination = "/data"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = "stop"   # ← Automatically stops machines when idle
  auto_start_machines = true    # ← Automatically starts machines on first request
  min_machines_running = 0      # ← Allow zero running machines when idle

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

**Key Fly.io concepts:**
- **App**: Your deployed application instance
- **VM**: Virtual machine specifications (RAM, CPU)
- **Volume**: Persistent disk storage that survives deployments
- **Machine**: The actual running instance of your app
- **Auto-scaling**: Automatically stops/starts machines based on traffic

## Step 6: Create Fly.io App

Initialize your Fly.io app:

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
- **Persistent storage**: Data survives app deployments and restarts  
- **Region-specific**: Must be in same region as your machines
- **Size**: Start small (1GB) - you can expand later if needed

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

{% caption_img TODO "Fly.io deployment logs showing successful SQLite migration" %}

During deployment, watch for these key log messages:
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

## Backup Strategy

**Important**: Unlike managed databases, you're responsible for SQLite backups.

**Quick manual backup:**
```bash
# Download production database
curl https://myapp.fly.dev/  # wake machine
fly ssh sftp get /data/db.sqlite ./backup-$(date +%Y%m%d).sqlite -a myapp
```

**Fly.io volume snapshots:**
Fly.io automatically creates volume snapshots with 5-day retention, but these aren't easily accessible for restore.

## Troubleshooting

**Machine won't start:**
```bash
# Check machine status
fly machine list -a myapp

# View detailed logs
fly logs -a myapp
```

**Database connection errors:**
- Verify volume is mounted: `fly ssh console -a myapp` then `ls -la /data/`
- Check file permissions: SQLite file should be owned by `vapor:vapor`

**Volume not attaching:**
- Ensure volume and machine are in the same region
- Volume names in `fly.toml` must match created volume name exactly

## Summary

This setup gives you:
- ✅ **SQLite database** with persistent storage
- ✅ **Auto-scaling** machines that stop when idle
- ✅ **Automatic migrations** on deployment  
- ✅ **Database access tools** for debugging
- ✅ **Simple architecture** with fewer dependencies

The key insight is that SQLite on Fly.io requires a **Volume** for persistence and careful **environment-based configuration** to work both locally and in production. Once configured, it's significantly simpler to manage than external database services.

