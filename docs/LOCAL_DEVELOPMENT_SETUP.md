# 🚀 CodeLayer Local Development Setup - Complete Installation Guide

## Overview

This guide provides step-by-step instructions for setting up the complete CodeLayer development environment on your local machine. By the end, you'll have:

- ✅ All dependencies installed
- ✅ Repository cloned and configured
- ✅ Backend daemon (hld) built and running
- ✅ Frontend UI (humanlayer-wui) launched and connected
- ✅ CLI tools (hlyr) available
- ✅ Full development environment ready

---

## System Requirements

### Operating System Support
- **macOS** (Intel or Apple Silicon) - Primary development platform
- **Linux** (Ubuntu 22.04+, Debian 12+) - Fully supported
- **Windows 11** - Supported via WSL2 (recommended) or native

### Minimum Specifications
- **CPU:** 4 cores
- **RAM:** 8GB
- **Disk:** 10GB free space
- **Internet:** Required for dependency downloads

---

## Part 1: Install System Dependencies

### macOS Installation

#### 1.1 Install Homebrew (if not already installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 1.2 Install Core Dependencies
```bash
# Install Go (1.21 or later)
brew install go

# Install Node.js (18 or later)
brew install node

# Install Bun (JavaScript runtime)
brew install oven-sh/bun/bun

# Install Rust (for Tauri)
brew install rust

# Install additional tools
brew install git make gcc sqlite3
```

#### 1.3 Verify Installations
```bash
# Check versions
go version        # Should show go1.21 or later
node --version    # Should show v18.x or later
bun --version     # Should show 1.x or later
rustc --version   # Should show 1.70 or later
```

---

### Linux (Ubuntu/Debian) Installation

#### 1.1 Update Package Manager
```bash
sudo apt update && sudo apt upgrade -y
```

#### 1.2 Install Core Dependencies
```bash
# Install build essentials
sudo apt install -y build-essential git curl wget

# Install Go (1.21+)
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install Node.js (18+)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Bun
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install Tauri dependencies
sudo apt install -y \
    libwebkit2gtk-4.1-dev \
    libappindicator3-dev \
    librsvg2-dev \
    patchelf \
    sqlite3 \
    libsqlite3-dev
```

#### 1.3 Verify Installations
```bash
go version
node --version
bun --version
rustc --version
```

---

### Windows (WSL2) Installation

#### 1.1 Install WSL2
```powershell
# Run in PowerShell as Administrator
wsl --install Ubuntu-22.04
wsl --set-default-version 2
```

#### 1.2 Restart and Enter WSL
```powershell
wsl
```

#### 1.3 Follow Linux Installation Steps
Once inside WSL, follow the **Linux (Ubuntu/Debian) Installation** steps above.

---

## Part 2: Clone Repository

### 2.1 Clone the Repository
```bash
# Create workspace directory
mkdir -p ~/projects
cd ~/projects

# Clone repository
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer
```

### 2.2 Verify Repository Structure
```bash
ls -la
# You should see:
# - hld/              (Go daemon)
# - humanlayer-wui/   (Tauri frontend)
# - hlyr/             (TypeScript CLI)
# - claudecode-go/    (Go SDK)
# - packages/         (Shared TypeScript packages)
# - Makefile
# - README.md
```

---

## Part 3: Install Project Dependencies

### 3.1 Run Automated Setup Script
```bash
# This installs all dependencies and builds SDKs
make setup
```

**What this does:**
- ✅ Installs Go dependencies for hld daemon
- ✅ Installs mockgen for Go mocks
- ✅ Generates hld mocks
- ✅ Installs and builds TypeScript SDK (@humanlayer/hld-sdk)
- ✅ Installs WUI dependencies
- ✅ Creates placeholder binaries for Tauri
- ✅ Builds hlyr CLI

**Expected output:**
```
🚀 Setting up HumanLayer repository...
📦 Installing mockgen...
📦 Generating HLD mocks...
📦 Installing HLD SDK dependencies...
🏗️  Building HLD TypeScript SDK...
📦 Installing WUI dependencies...
🔧 Creating placeholder binaries for Tauri...
🏗️  Building hlyr...
✅ Repository setup complete!
```

### 3.2 Verify Setup
```bash
# Check that dependencies installed correctly
ls -la hld/sdk/typescript/dist/   # Should contain compiled SDK
ls -la humanlayer-wui/node_modules/  # Should contain WUI dependencies
ls -la hlyr/dist/                  # Should contain built CLI
```

---

## Part 4: Build and Run Backend Daemon (hld)

### 4.1 Build the Daemon
```bash
cd hld

# Build the daemon binary
make build

# Verify binary was created
ls -la hld  # Should show executable file
```

### 4.2 Create Development Database Directory
```bash
# Create .humanlayer directory for development
mkdir -p ~/.humanlayer/logs
mkdir -p ~/.humanlayer/dev
```

### 4.3 Run the Daemon (Development Mode)
```bash
# Option 1: Run directly (foreground)
./hld

# You should see:
# INFO: hld daemon starting...
# INFO: HTTP server listening on 127.0.0.1:7777
# INFO: Unix socket created at /Users/you/.humanlayer/daemon.sock
# INFO: Daemon ready
```

**Daemon Features Active:**
- ✅ REST API running on http://localhost:7777
- ✅ Unix socket at `~/.humanlayer/daemon.sock`
- ✅ SQLite database at `~/.humanlayer/daemon.db`
- ✅ Logs in `~/.humanlayer/logs/`

### 4.4 Test Daemon Health (in another terminal)
```bash
# Test health endpoint
curl http://localhost:7777/api/v1/health

# Expected response:
# {"status":"ok","version":"dev"}
```

### 4.5 Alternative: Run as Background Service
```bash
# Option 2: Run in background (recommended for development)
make daemon-dev

# This runs daemon with:
# - Isolated dev database
# - Dev-specific socket
# - Auto-restarting on crashes
```

---

## Part 5: Build and Run Frontend UI (humanlayer-wui)

### 5.1 Navigate to WUI Directory
```bash
cd ~/projects/humanlayer/humanlayer-wui
```

### 5.2 Install Additional Dependencies (if needed)
```bash
# Install Bun dependencies
bun install

# Install Tauri CLI
cargo install tauri-cli --locked
```

### 5.3 Build Development Assets
```bash
# Build frontend assets
bun run build
```

### 5.4 Launch Development UI
```bash
# Option 1: Full development mode with hot reload
make codelayer-dev

# This will:
# 1. Start Vite dev server (frontend hot reload)
# 2. Launch Tauri desktop app
# 3. Auto-connect to daemon on localhost:7777
```

**Expected Behavior:**
- 🪟 Desktop window opens (Tauri app)
- 🔄 Frontend connects to daemon
- 📊 Dashboard loads with session list
- ✅ Status indicator shows "Connected"

### 5.5 Verify UI Connection

**In the UI:**
1. Click the **settings icon** (bottom-left corner)
2. Go to **Debug Panel**
3. Verify:
   - ✅ **Daemon Status:** Connected
   - ✅ **Daemon URL:** http://localhost:7777
   - ✅ **Database:** ~/.humanlayer/daemon.db

### 5.6 Alternative: Run with Custom Port
```bash
# If daemon is on a different port
export HUMANLAYER_DAEMON_HTTP_PORT=7777
make codelayer-dev
```

---

## Part 6: Install and Test CLI (hlyr)

### 6.1 Navigate to CLI Directory
```bash
cd ~/projects/humanlayer/hlyr
```

### 6.2 Install Dependencies
```bash
npm install
```

### 6.3 Build CLI
```bash
npm run build
```

### 6.4 Link CLI Globally
```bash
# Make CLI available system-wide
npm link

# Verify installation
which humanlayer
# Should show: /usr/local/bin/humanlayer (or similar)
```

### 6.5 Test CLI Commands
```bash
# Test basic commands
humanlayer --help

# Test daemon connection
humanlayer ping

# Expected output:
# ✓ Daemon is running
# ✓ Connected to http://localhost:7777

# Test contact human (optional, requires Slack/Email config)
humanlayer contact_human --message "Test message"
```

---

## Part 7: Configure Development Environment

### 7.1 Create Configuration File
```bash
# Create humanlayer config
cat > ~/.humanlayer/config.json <<EOF
{
  "daemon_socket": "~/.humanlayer/daemon.sock",
  "api_base_url": "http://localhost:7777/api/v1",
  "channel": {
    "type": "slack",
    "slack_token": "xoxb-YOUR-TOKEN-HERE",
    "slack_channel_or_user_id": "C0123456789"
  }
}
EOF
```

### 7.2 Set Environment Variables
```bash
# Add to ~/.bashrc or ~/.zshrc
cat >> ~/.bashrc <<EOF

# HumanLayer Development Environment
export HUMANLAYER_DEBUG=true
export HUMANLAYER_DAEMON_SOCKET=~/.humanlayer/daemon.sock
export HUMANLAYER_DATABASE_PATH=~/.humanlayer/daemon.db
export ANTHROPIC_API_KEY=sk-ant-YOUR-KEY-HERE

# Add Go binaries to PATH
export PATH=\$PATH:\$(go env GOPATH)/bin
EOF

# Reload shell
source ~/.bashrc
```

---

## Part 8: Verify Complete Setup

### 8.1 Run Full System Check
```bash
cd ~/projects/humanlayer

# Run all checks
make check

# Run all tests
make test
```

**Expected Output:**
```
✓ hlyr checks passed
✓ hld checks passed
✓ humanlayer-wui checks passed
✓ All tests passed
```

### 8.2 Verify All Components Running

**Open 3 terminals:**

**Terminal 1: Daemon Logs**
```bash
cd ~/projects/humanlayer/hld
./hld
# Should show: INFO: Daemon ready
```

**Terminal 2: Frontend UI**
```bash
cd ~/projects/humanlayer/humanlayer-wui
make codelayer-dev
# Desktop app should launch
```

**Terminal 3: CLI Tests**
```bash
humanlayer ping
# Should show: ✓ Daemon is running

# List sessions
curl http://localhost:7777/api/v1/sessions | jq
# Should return: {"data": []}
```

### 8.3 Create Test Session (via UI)

1. Open **CodeLayer UI** (should be running from Terminal 2)
2. Click **"+ New Session"** button
3. Enter a test query: `"Create a hello world Python script"`
4. Verify:
   - ✅ Session appears in session list
   - ✅ Status shows "starting" → "running"
   - ✅ Approvals panel shows any tool requests

---

## Part 9: Development Workflow

### 9.1 Typical Development Cycle

**Morning Startup:**
```bash
# Terminal 1: Start daemon
cd ~/projects/humanlayer/hld
make daemon-dev

# Terminal 2: Start UI with hot reload
cd ~/projects/humanlayer/humanlayer-wui
make codelayer-dev
```

**During Development:**
```bash
# Make changes to code...

# Restart daemon (if hld code changed)
# Ctrl+C in Terminal 1, then:
make build && ./hld

# Frontend auto-reloads on save (Vite)
# Just save files in humanlayer-wui/src/*

# Rebuild CLI (if hlyr code changed)
cd hlyr
npm run build
```

**End of Day:**
```bash
# Stop daemon (Ctrl+C in Terminal 1)
# Close UI (Cmd+Q or Ctrl+Q)
```

### 9.2 Parallel Development Environments

**Run stable + dev simultaneously:**
```bash
# Terminal 1: Stable daemon (port 7777)
make daemon-nightly

# Terminal 2: Dev daemon (port 7778)
make daemon-dev

# Terminal 3: Stable UI
make wui-nightly

# Terminal 4: Dev UI
make wui-dev
```

---

## Part 10: Troubleshooting Common Issues

### Issue 1: "Port 7777 already in use"
```bash
# Find and kill process
lsof -ti:7777 | xargs kill -9

# Or use a different port
export HUMANLAYER_HTTP_PORT=7778
./hld
```

### Issue 2: "Cannot find module @humanlayer/hld-sdk"
```bash
# Rebuild SDK
cd hld/sdk/typescript
bun install
bun run build

# Reinstall WUI dependencies
cd ../../humanlayer-wui
bun install
```

### Issue 3: "Daemon connection failed" in UI
```bash
# Check daemon is running
ps aux | grep hld

# Check port
lsof -i:7777

# Check logs
tail -f ~/.humanlayer/logs/daemon-*.log
```

### Issue 4: "Command not found: humanlayer"
```bash
# Re-link CLI
cd hlyr
npm link

# Verify PATH
echo $PATH | grep "$(npm bin -g)"

# If not in PATH, add to ~/.bashrc:
export PATH="$(npm bin -g):$PATH"
```

### Issue 5: Tauri Build Fails
```bash
# Install webkit dependencies (Linux)
sudo apt install -y \
    libwebkit2gtk-4.1-dev \
    libappindicator3-dev \
    librsvg2-dev

# Update Rust toolchain
rustup update stable

# Clean and rebuild
cd humanlayer-wui
rm -rf src-tauri/target
cargo clean
make codelayer-dev
```

---

## Part 11: Next Steps

### 11.1 Explore the Codebase
```bash
# Key directories:
~/projects/humanlayer/
├── hld/                  # Backend daemon (Go)
│   ├── api/             # REST API handlers
│   ├── daemon/          # Core daemon logic
│   ├── session/         # Session management
│   └── approval/        # Approval system
├── humanlayer-wui/       # Frontend UI (React + Tauri)
│   ├── src/             # React components
│   ├── src-tauri/       # Tauri Rust backend
│   └── src/hooks/       # React hooks for API
├── hlyr/                 # CLI tool (TypeScript)
│   └── src/             # CLI commands
└── claudecode-go/        # Claude Code wrapper (Go)
```

### 11.2 Read Documentation
- **Architecture:** `humanlayer-wui/docs/ARCHITECTURE.md`
- **Development:** `DEVELOPMENT.md`
- **API Reference:** `hld/api/openapi.yaml`

### 11.3 Run Tests
```bash
# Run all tests
make test

# Run specific component tests
make test-hld          # Daemon tests
make test-wui          # Frontend tests
make test-hlyr         # CLI tests
```

### 11.4 Join the Community
- **Discord:** https://humanlayer.dev/discord
- **GitHub Issues:** https://github.com/humanlayer/humanlayer/issues
- **Documentation:** https://docs.humanlayer.dev

---

## Summary Checklist

By this point, you should have:

- ✅ All dependencies installed (Go, Node, Bun, Rust)
- ✅ Repository cloned and setup completed
- ✅ Backend daemon (hld) built and running on port 7777
- ✅ Frontend UI (humanlayer-wui) launched and connected
- ✅ CLI (hlyr) installed globally and working
- ✅ Configuration files created
- ✅ Environment variables set
- ✅ Development workflow established
- ✅ All tests passing

**You're now ready to develop with CodeLayer! 🎉**

---

## Quick Reference Commands

```bash
# Start everything
make daemon-dev          # Terminal 1: Daemon
make codelayer-dev       # Terminal 2: UI

# Check status
humanlayer ping          # CLI health check
curl localhost:7777/api/v1/health  # HTTP health check

# View logs
tail -f ~/.humanlayer/logs/daemon-*.log
tail -f ~/.humanlayer/logs/wui-*/codelayer.log

# Run tests
make test                # All tests
make check               # All checks (lint, format, type)

# Clean restart
make clean               # Clean build artifacts
make setup               # Reinstall dependencies
```

---

**Need Help?** Post in Discord or create a GitHub issue with:
1. Operating system and version
2. Output of `go version`, `node --version`, `bun --version`, `rustc --version`
3. Error messages and logs
4. Steps you've already tried

