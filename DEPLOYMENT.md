# HumanLayer Deployment Guide

**Complete setup and deployment instructions for all platforms**

---

## 📋 Platform-Specific Guides

Choose your platform for detailed instructions:

- **[Windows Deployment](WINDOWS_DEPLOYMENT.md)** - Complete Windows 10/11 setup guide
- **[Linux/macOS Deployment](#linuxmacos-deployment)** - Unix-based systems (below)

---

## Linux/macOS Deployment

### Quick Start

```bash
# One-command setup
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer
make setup
```

That's it! The setup script handles everything automatically.

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Running the Application](#running-the-application)
5. [Development Workflow](#development-workflow)
6. [Configuration](#configuration)
7. [Troubleshooting](#troubleshooting)
8. [Uninstallation](#uninstallation)

---

## System Requirements

### Linux
- **OS**: Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch Linux, or similar
- **CPU**: 64-bit x86_64 or ARM64
- **RAM**: 8 GB minimum, 16 GB recommended
- **Disk**: 5 GB free space

### macOS
- **OS**: macOS 12 (Monterey) or later
- **CPU**: Intel (x86_64) or Apple Silicon (ARM64)
- **RAM**: 8 GB minimum, 16 GB recommended
- **Disk**: 5 GB free space

---

## Prerequisites

### Required Tools

#### 1. Git
**Linux (Debian/Ubuntu):**
```bash
sudo apt-get update
sudo apt-get install git
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install git
```

**macOS:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Or use Homebrew
brew install git
```

**Verify:**
```bash
git --version
```

#### 2. Node.js (v18+)
**Using nvm (Recommended):**
```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell
source ~/.bashrc  # or ~/.zshrc for zsh

# Install Node.js
nvm install 20
nvm use 20
```

**Linux (Ubuntu/Debian):**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**macOS:**
```bash
brew install node@20
```

**Verify:**
```bash
node --version
npm --version
```

#### 3. Bun
```bash
curl -fsSL https://bun.sh/install | bash

# Reload shell to update PATH
source ~/.bashrc  # or ~/.zshrc
```

**Verify:**
```bash
bun --version
```

#### 4. Go (v1.21+)
**Linux:**
```bash
# Download and install
wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$(go env GOPATH)/bin
```

**macOS:**
```bash
brew install go
```

**Verify:**
```bash
go version
```

#### 5. Rust & Cargo
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Reload shell
source ~/.bashrc  # or ~/.zshrc
```

**Verify:**
```bash
rustc --version
cargo --version
```

#### 6. Build Tools

**Linux (Debian/Ubuntu):**
```bash
sudo apt-get install build-essential pkg-config libssl-dev
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf groupinstall "Development Tools"
sudo dnf install openssl-devel
```

**macOS:**
```bash
xcode-select --install
```

#### 7. Make
**Should be pre-installed on most systems. Verify:**
```bash
make --version
```

---

## Installation

### Automated Setup (Recommended)

```bash
# Clone repository
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer

# Run setup
make setup
```

The setup script will:
1. ✅ Check all prerequisites
2. ✅ Install mockgen (if needed)
3. ✅ Generate HLD mocks
4. ✅ Build HLD TypeScript SDK
5. ✅ Install and build HLYR CLI
6. ✅ Install WUI dependencies
7. ✅ Create Tauri placeholders
8. ✅ Verify installation

### Manual Setup

If you prefer manual control:

```bash
# 1. Clone repository
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer

# 2. Install mockgen
go install go.uber.org/mock/mockgen@latest

# 3. Generate HLD mocks
cd hld
go generate ./...
cd ..

# 4. Build HLD TypeScript SDK
cd hld/sdk/typescript
bun install
bun run build
cd ../../..

# 5. Install and build HLYR CLI
cd hlyr
npm install
npm run build
cd ..

# 6. Install WUI dependencies
bun install --cwd=humanlayer-wui

# 7. Create Tauri placeholders
mkdir -p humanlayer-wui/src-tauri/bin
touch humanlayer-wui/src-tauri/bin/hld
touch humanlayer-wui/src-tauri/bin/humanlayer

# 8. Build HLD daemon
cd hld
go build -o hld
cd ..
```

---

## Running the Application

### Development Mode

#### Using Make (Recommended)

**Terminal 1 - Start Daemon:**
```bash
make daemon-dev
```

**Terminal 2 - Start UI:**
```bash
make wui-dev
```

**Terminal 3 - Launch Claude Session:**
```bash
npx humanlayer launch "implement user authentication"
```

#### Manual Start

**Terminal 1 - Daemon:**
```bash
cd hld
go run . --socket ~/.humanlayer/daemon-dev.sock --db ~/.humanlayer/daemon-dev.db
```

**Terminal 2 - UI:**
```bash
cd humanlayer-wui
npm run tauri dev
```

**Terminal 3 - CLI:**
```bash
npx humanlayer launch "your task here"
```

### Production Mode

#### Build Production Binaries

```bash
# Build daemon
cd hld
go build -o hld-nightly
cd ..

# Build UI
cd humanlayer-wui
npm run tauri build
cd ..
```

#### macOS Installation

```bash
# Install from DMG
open humanlayer-wui/src-tauri/target/release/bundle/dmg/HumanLayer_*.dmg

# Or copy to Applications
cp -r humanlayer-wui/src-tauri/target/release/bundle/macos/HumanLayer.app /Applications/
```

#### Linux Installation

```bash
# Debian/Ubuntu - Install .deb package
sudo dpkg -i humanlayer-wui/src-tauri/target/release/bundle/deb/humanlayer_*.deb

# Or use AppImage
chmod +x humanlayer-wui/src-tauri/target/release/bundle/appimage/humanlayer_*.AppImage
./humanlayer-wui/src-tauri/target/release/bundle/appimage/humanlayer_*.AppImage
```

#### Start Production Daemon

```bash
# Foreground
./hld/hld-nightly

# Background with nohup
nohup ./hld/hld-nightly > ~/.humanlayer/logs/daemon.log 2>&1 &

# Or use systemd (see Configuration section)
```

---

## Development Workflow

### Parallel Development Environments

Run stable (nightly) and development (dev) environments simultaneously:

```bash
# Terminal 1: Stable environment
make daemon-nightly
make wui-nightly

# Terminal 2: Development environment
make daemon-dev
make wui-dev

# Terminal 3: Test with dev daemon
npx humanlayer launch "test feature" --daemon-socket ~/.humanlayer/daemon-dev.sock
```

### Available Make Commands

**Setup:**
```bash
make setup              # Full repository setup
make check             # Run linting and type checking
make test              # Run all test suites
make check-test        # Run checks and tests
```

**Development:**
```bash
make daemon-dev        # Build and run dev daemon
make daemon-nightly    # Build and run nightly daemon
make wui-dev          # Run WUI in dev mode
make wui-nightly      # Build, install, and open nightly WUI
```

**Utilities:**
```bash
make generate-sdks     # Regenerate TypeScript SDK from OpenAPI
make dev-status        # Show current dev environment status
make cleanup-dev       # Clean up old dev databases and logs
make mocks            # Regenerate Go mocks
```

### Check Logs

```bash
# Daemon logs
tail -f ~/.humanlayer/logs/daemon-dev-*.log

# WUI logs
tail -f ~/.humanlayer/logs/wui-dev/codelayer.log
```

### Inspect Database

```bash
# Query recent sessions
sqlite3 ~/.humanlayer/daemon-dev.db "SELECT id, prompt, status, created_at FROM sessions ORDER BY created_at DESC LIMIT 5;"

# View schema
sqlite3 ~/.humanlayer/daemon-dev.db ".schema"
```

---

## Configuration

### Configuration File

Create `~/.humanlayer/humanlayer.json`:

```json
{
  "daemon_socket": "~/.humanlayer/daemon.sock",
  "api_key": "your-humanlayer-api-key",
  "contact_channel": "email",
  "contact_email": "you@example.com",
  "claude_model": "claude-sonnet-4-20250514",
  "max_turns": 30,
  "custom_system_prompt": "You are an expert software engineer..."
}
```

### Environment Variables

Create `.env` in project root:

```bash
# HumanLayer API
HUMANLAYER_API_KEY=your-api-key-here

# Daemon Configuration
HUMANLAYER_DAEMON_SOCKET=~/.humanlayer/daemon.sock
HUMANLAYER_DB_PATH=~/.humanlayer/daemon.db

# Development
DEV_MODE=true
LOG_LEVEL=debug
```

### MCP Configuration

Create `~/.claude/mcp-config.json`:

```json
{
  "mcpServers": {
    "approvals": {
      "command": "npx",
      "args": ["-y", "humanlayer", "mcp", "claude_approvals"],
      "env": {
        "HUMANLAYER_DAEMON_SOCKET": "~/.humanlayer/daemon.sock"
      }
    }
  }
}
```

### systemd Service (Linux)

Create `/etc/systemd/system/humanlayer.service`:

```ini
[Unit]
Description=HumanLayer Daemon
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/home/your-username/humanlayer
ExecStart=/home/your-username/humanlayer/hld/hld-nightly
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Enable and start:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable humanlayer
sudo systemctl start humanlayer
sudo systemctl status humanlayer
```

### launchd Service (macOS)

Create `~/Library/LaunchAgents/dev.humanlayer.daemon.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dev.humanlayer.daemon</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/your-username/humanlayer/hld/hld-nightly</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/your-username/.humanlayer/logs/daemon.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/your-username/.humanlayer/logs/daemon-error.log</string>
</dict>
</plist>
```

**Load and start:**
```bash
launchctl load ~/Library/LaunchAgents/dev.humanlayer.daemon.plist
launchctl start dev.humanlayer.daemon
launchctl list | grep humanlayer
```

---

## Troubleshooting

### Common Issues

#### 1. "mockgen: command not found"
```bash
go install go.uber.org/mock/mockgen@latest
export PATH=$PATH:$(go env GOPATH)/bin
```

#### 2. "Bun not found"
```bash
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc  # or ~/.zshrc
```

#### 3. Port Already in Use
```bash
# Find process using port
lsof -i :3000  # or whatever port

# Kill process
kill -9 <PID>
```

#### 4. Database Locked
```bash
# Stop all daemons
pkill hld

# Remove socket files
rm ~/.humanlayer/daemon*.sock

# Restart daemon
make daemon-dev
```

#### 5. Permission Errors
```bash
# Fix ownership of .humanlayer directory
sudo chown -R $USER:$USER ~/.humanlayer

# Fix permissions
chmod 755 ~/.humanlayer
chmod 644 ~/.humanlayer/*.json
```

#### 6. Tauri Build Fails (Linux)
```bash
# Install required dependencies
sudo apt-get install libwebkit2gtk-4.0-dev \
    build-essential \
    curl \
    wget \
    file \
    libssl-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev
```

#### 7. "go.sum" Errors
```bash
cd hld
go mod tidy
go mod download
```

### Enable Debug Logging

```bash
# Set environment variable
export LOG_LEVEL=debug
export VERBOSE=1

# Run with debug output
make daemon-dev VERBOSE=1
```

### Check System Info

```bash
# Check versions
echo "Node: $(node --version)"
echo "npm: $(npm --version)"
echo "Bun: $(bun --version)"
echo "Go: $(go version)"
echo "Rust: $(rustc --version)"
echo "Cargo: $(cargo --version)"

# Check running processes
ps aux | grep hld
lsof -i :3000  # Check WUI port
```

---

## Uninstallation

### Remove Application

```bash
# Stop daemons
pkill hld

# Remove data directory
rm -rf ~/.humanlayer

# Remove global npm packages
npm uninstall -g humanlayer @anthropic-ai/claude-code

# Remove application (macOS)
rm -rf /Applications/HumanLayer.app

# Remove application (Linux - if installed via package)
sudo dpkg -r humanlayer  # Debian/Ubuntu
sudo rpm -e humanlayer   # Fedora/RHEL

# Remove repository
cd ..
rm -rf humanlayer
```

### Remove systemd Service (Linux)

```bash
sudo systemctl stop humanlayer
sudo systemctl disable humanlayer
sudo rm /etc/systemd/system/humanlayer.service
sudo systemctl daemon-reload
```

### Remove launchd Service (macOS)

```bash
launchctl stop dev.humanlayer.daemon
launchctl unload ~/Library/LaunchAgents/dev.humanlayer.daemon.plist
rm ~/Library/LaunchAgents/dev.humanlayer.daemon.plist
```

---

## Additional Resources

### Documentation
- **Main README**: [README.md](README.md)
- **Windows Guide**: [WINDOWS_DEPLOYMENT.md](WINDOWS_DEPLOYMENT.md)
- **Development Guide**: [DEVELOPMENT.md](DEVELOPMENT.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

### External Links
- **Website**: https://humanlayer.dev/code
- **GitHub**: https://github.com/humanlayer/humanlayer
- **Discord**: https://humanlayer.dev/discord
- **YouTube**: https://humanlayer.dev/youtube
- **Email**: contact@humanlayer.dev

### Technology Stack
- **Backend**: Go 1.24, SQLite, JSON-RPC
- **CLI**: TypeScript, Bun, Commander.js
- **Frontend**: React 19, Tauri 2.x, Radix UI, Tailwind CSS 4
- **Build**: Turbo, Biome, Make

---

## Platform-Specific Notes

### Linux Notes
- Use your distribution's package manager for system dependencies
- AppImage provides portable installation without root access
- systemd service provides automatic daemon management

### macOS Notes
- Xcode Command Line Tools required for compilation
- Homebrew recommended for package management
- launchd provides daemon management
- Gatekeeper may require allowing unsigned applications
- Apple Silicon (M1/M2) fully supported

### ARM64 Support
- Both Linux and macOS ARM64 are supported
- Cross-compilation supported via cargo and Go
- Some npm packages may need native compilation

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-08  
**Platforms**: Linux, macOS (x86_64, ARM64)  
**License**: Apache 2.0

---

For questions or support:
- 📧 Email: contact@humanlayer.dev
- 💬 Discord: https://humanlayer.dev/discord
- 🐛 Issues: https://github.com/humanlayer/humanlayer/issues

