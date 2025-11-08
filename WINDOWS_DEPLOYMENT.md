# HumanLayer Windows Deployment Guide

**Complete setup and deployment instructions for Windows environments**

---

## 📋 Table of Contents

1. [System Requirements](#system-requirements)
2. [Prerequisites Installation](#prerequisites-installation)
3. [Automated Setup (Recommended)](#automated-setup-recommended)
4. [Manual Setup](#manual-setup)
5. [Project Structure](#project-structure)
6. [Core Features](#core-features)
7. [Running the Application](#running-the-application)
8. [Development Workflow](#development-workflow)
9. [Troubleshooting](#troubleshooting)
10. [Uninstallation](#uninstallation)

---

## System Requirements

### Minimum Requirements
- **OS**: Windows 10 (version 1903 or higher) or Windows 11
- **CPU**: 64-bit processor (x86_64/AMD64 architecture)
- **RAM**: 8 GB minimum, 16 GB recommended
- **Disk Space**: 5 GB free space minimum
- **Internet**: Broadband connection for installation and API calls

### Supported Architectures
- ✅ x86_64 (64-bit Intel/AMD)
- ⚠️ ARM64 (via emulation, not officially supported yet)

---

## Prerequisites Installation

### Required Software

#### 1. Git for Windows
Download and install from: https://git-scm.com/download/win

**Installation options:**
```
- Use Git from Git Bash only (recommended)
- Checkout Windows-style, commit Unix-style line endings
- Use MinTTY (default terminal of Git Bash)
```

**Verify installation:**
```cmd
git --version
```

#### 2. Node.js (v18 or higher)
Download from: https://nodejs.org/

**Recommended version**: v20 LTS

**Verify installation:**
```cmd
node --version
npm --version
```

#### 3. Bun (Package Manager & Runtime)
**PowerShell installation (Administrator):**
```powershell
powershell -c "irm bun.sh/install.ps1|iex"
```

**Verify installation:**
```cmd
bun --version
```

**Add to PATH** (if not automatic):
```
C:\Users\<YourUsername>\.bun\bin
```

#### 4. Go (v1.21 or higher)
Download from: https://go.dev/dl/

**Recommended version**: Latest stable (1.24+)

**Verify installation:**
```cmd
go version
```

#### 5. Rust & Cargo (for Tauri desktop app)
Download rustup from: https://rustup.rs/

**Installation:**
```cmd
rustup-init.exe
```

**Select default installation**

**Verify installation:**
```cmd
rustc --version
cargo --version
```

#### 6. Visual Studio Build Tools (Required for Rust)
Download from: https://visualstudio.microsoft.com/downloads/

**Required workload:**
- "Desktop development with C++"

**Or use VS Code with:**
- C/C++ extension
- Rust-analyzer extension

#### 7. Make for Windows (GNU Make)
**Option 1: Via Chocolatey (Recommended)**
```powershell
# Install Chocolatey first
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Make
choco install make
```

**Option 2: Manual (GnuWin32)**
Download from: http://gnuwin32.sourceforge.net/packages/make.htm

Add to PATH:
```
C:\Program Files (x86)\GnuWin32\bin
```

**Verify installation:**
```cmd
make --version
```

---

## Automated Setup (Recommended)

### Using PowerShell Script

Download and run the automated setup script:

```powershell
# Clone repository
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer

# Run Windows setup script
powershell -ExecutionPolicy Bypass -File .\scripts\windows-setup.ps1
```

The script will:
1. ✅ Check all prerequisites
2. ✅ Install missing dependencies (with permission)
3. ✅ Set up development environment
4. ✅ Build all components
5. ✅ Configure daemon and UI
6. ✅ Verify installation

---

## Manual Setup

### Step 1: Clone Repository

```cmd
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer
```

### Step 2: Install Dependencies

**Root dependencies:**
```cmd
bun install
```

**Install mockgen (for Go mocks):**
```cmd
go install go.uber.org/mock/mockgen@latest
```

**Add Go bin to PATH** (if not already):
```
%USERPROFILE%\go\bin
```

### Step 3: Generate HLD Mocks

```cmd
cd hld
go generate ./...
cd ..
```

Or use Make:
```cmd
make -C hld mocks
```

### Step 4: Build HLD TypeScript SDK

```cmd
cd hld\sdk\typescript
bun install
bun run build
cd ..\..\..
```

### Step 5: Install and Build HLYR (CLI)

```cmd
cd hlyr
npm install
npm run build
cd ..
```

### Step 6: Install WUI Dependencies

```cmd
cd humanlayer-wui
bun install
cd ..
```

### Step 7: Create Tauri Placeholder Binaries

```cmd
mkdir humanlayer-wui\src-tauri\bin
type nul > humanlayer-wui\src-tauri\bin\hld
type nul > humanlayer-wui\src-tauri\bin\humanlayer
```

### Step 8: Build Go Daemon (HLD)

```cmd
cd hld
go build -o hld.exe
cd ..
```

### Step 9: Build Desktop UI (Optional - Development Mode Only)

**For development:**
```cmd
cd humanlayer-wui
npm run tauri dev
```

**For production build:**
```cmd
cd humanlayer-wui
npm run tauri build
```

---

## Project Structure

```
humanlayer/
├── hld/                        # Go daemon (core orchestration)
│   ├── main.go                # Daemon entry point
│   ├── rpc/                   # JSON-RPC server
│   ├── db/                    # SQLite database
│   └── sdk/typescript/        # TypeScript SDK
├── hlyr/                       # TypeScript CLI
│   ├── src/
│   │   ├── cli.ts            # CLI entry point
│   │   └── mcp.ts            # MCP server implementation
│   └── package.json
├── humanlayer-wui/            # Desktop UI (Tauri + React)
│   ├── src/                   # React frontend
│   ├── src-tauri/            # Tauri backend (Rust)
│   └── package.json
├── claudecode-go/             # Claude Code Go SDK
├── Makefile                   # Build automation
├── hack/                      # Setup scripts
│   └── setup_repo.sh         # Linux/macOS setup
└── scripts/                   # Additional scripts
    └── windows-setup.ps1     # Windows setup (NEW)
```

---

## Core Features

### What HumanLayer Does

**HumanLayer (CodeLayer)** is an open-source IDE for orchestrating AI coding agents built on Claude Code.

#### Key Capabilities:

1. **Session Management**
   - Launch multiple Claude Code sessions in parallel
   - Track session lifecycle (starting/running/completed/failed)
   - Session continuation for multi-turn conversations
   - Custom system prompts and model selection

2. **Human-in-the-Loop Approvals**
   - Approval workflows for AI agent actions
   - Approve/deny with comments
   - Real-time approval requests via desktop UI
   - MCP server integration

3. **Multi-Claude Orchestration**
   - Run parallel sessions with different contexts
   - Git worktree support for isolated development
   - Remote cloud worker support

4. **Advanced Context Engineering**
   - 30+ specialized Claude commands
   - 6 specialized sub-agents (codebase analyzer, locator, etc.)
   - Research workflows with multi-agent coordination

5. **Desktop & CLI Interface**
   - Keyboard-first workflows (Superhuman-style)
   - Session visualization and monitoring
   - Conversation history with full search
   - Dark/light theme support

---

## Running the Application

### Development Mode

#### 1. Start the Daemon (HLD)

**Terminal 1 - Development Daemon:**
```cmd
cd hld
go run . --socket "%USERPROFILE%\.humanlayer\daemon-dev.sock" --db "%USERPROFILE%\.humanlayer\daemon-dev.db"
```

**Or use Make (if available):**
```cmd
make daemon-dev
```

#### 2. Start the Desktop UI

**Terminal 2 - WUI Development Mode:**
```cmd
cd humanlayer-wui
npm run tauri dev
```

**Or use Make:**
```cmd
make wui-dev
```

#### 3. Launch Claude Code Session

**Terminal 3 - CLI:**
```cmd
npx humanlayer launch "implement user authentication"
```

**With custom daemon socket:**
```cmd
set HUMANLAYER_DAEMON_SOCKET=%USERPROFILE%\.humanlayer\daemon-dev.sock
npx humanlayer launch "fix login bug"
```

### Production Mode

#### 1. Build Production Binaries

**Build daemon:**
```cmd
cd hld
go build -o hld-nightly.exe
```

**Build desktop UI:**
```cmd
cd humanlayer-wui
npm run tauri build
```

**Installer location:**
```
humanlayer-wui\src-tauri\target\release\bundle\nsis\
```

#### 2. Install Desktop Application

Run the NSIS installer:
```
HumanLayer_<version>_x64-setup.exe
```

#### 3. Start Daemon

**Option 1: As Windows Service (Recommended)**
```cmd
# TODO: Service installation script
```

**Option 2: Manual Start**
```cmd
hld-nightly.exe
```

#### 4. Launch Desktop UI

From Start Menu:
```
Start → HumanLayer CodeLayer
```

---

## Development Workflow

### Typical Development Day

**Morning Setup:**
```cmd
# Terminal 1 - Stable environment
make daemon-nightly
make wui-nightly

# Terminal 2 - Development environment
make daemon-dev
make wui-dev
```

**Work on feature:**
```cmd
# Edit code in hld/ or humanlayer-wui/
# Hot reload happens automatically

# Test with dev daemon
npx humanlayer launch "test my new feature" --daemon-socket %USERPROFILE%\.humanlayer\daemon-dev.sock
```

**Check logs:**
```cmd
# Daemon logs
type %USERPROFILE%\.humanlayer\logs\daemon-dev-*.log

# WUI logs
type %USERPROFILE%\.humanlayer\logs\wui-dev\codelayer.log
```

**Inspect database:**
```cmd
# Install SQLite (via Chocolatey)
choco install sqlite

# Query sessions
sqlite3 %USERPROFILE%\.humanlayer\daemon-dev.db "SELECT * FROM sessions ORDER BY created_at DESC LIMIT 5;"
```

### Available Make Commands

**Setup:**
```cmd
make setup              # Full repository setup
make check             # Run linting and type checking
make test              # Run all test suites
make check-test        # Run checks and tests
```

**Development:**
```cmd
make daemon-dev        # Build and run dev daemon
make daemon-nightly    # Build and run nightly daemon
make wui-dev          # Run WUI in dev mode
make wui-nightly      # Build, install, and open nightly WUI
```

**Utilities:**
```cmd
make generate-sdks     # Regenerate TypeScript SDK from OpenAPI
make dev-status        # Show current dev environment status
make cleanup-dev       # Clean up old dev databases and logs
```

---

## Configuration

### Configuration File

Create `%USERPROFILE%\.humanlayer\humanlayer.json`:

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

Create `.env` file in project root:

```env
# HumanLayer API
HUMANLAYER_API_KEY=your-api-key-here

# Daemon Configuration
HUMANLAYER_DAEMON_SOCKET=%USERPROFILE%\.humanlayer\daemon.sock
HUMANLAYER_DB_PATH=%USERPROFILE%\.humanlayer\daemon.db

# Development Settings
DEV_MODE=true
LOG_LEVEL=debug
```

### MCP Configuration

Create `.claude\mcp-config.json`:

```json
{
  "mcpServers": {
    "approvals": {
      "command": "npx",
      "args": ["-y", "humanlayer", "mcp", "claude_approvals"],
      "env": {
        "HUMANLAYER_DAEMON_SOCKET": "%USERPROFILE%\\.humanlayer\\daemon.sock"
      }
    }
  }
}
```

---

## Troubleshooting

### Common Issues

#### 1. "make: command not found"
**Solution:**
```powershell
choco install make
```

Or use native commands instead of Make.

#### 2. "Bun not found"
**Solution:**
```powershell
# Reinstall Bun
powershell -c "irm bun.sh/install.ps1|iex"

# Add to PATH manually
$env:Path += ";$env:USERPROFILE\.bun\bin"
```

#### 3. "Go build fails - 'mockgen' not found"
**Solution:**
```cmd
go install go.uber.org/mock/mockgen@latest

# Verify
mockgen -version
```

#### 4. Tauri Build Errors
**Solution:**
```cmd
# Install Visual Studio Build Tools
# Download from: https://visualstudio.microsoft.com/downloads/

# Or install via winget
winget install Microsoft.VisualStudio.2022.BuildTools
```

#### 5. SQLite Database Locked
**Solution:**
```cmd
# Stop all daemon processes
taskkill /F /IM hld.exe

# Remove socket file
del %USERPROFILE%\.humanlayer\daemon.sock
del %USERPROFILE%\.humanlayer\daemon-dev.sock

# Restart daemon
```

#### 6. Port Already in Use
**Solution:**
```cmd
# Check what's using port 3000
netstat -ano | findstr :3000

# Kill process
taskkill /PID <PID> /F
```

#### 7. Permission Denied Errors
**Solution:**
Run PowerShell/CMD as Administrator:
```
Right-click PowerShell → Run as Administrator
```

### Debug Mode

**Enable verbose logging:**
```cmd
set LOG_LEVEL=debug
set VERBOSE=1

# Run with debug output
make daemon-dev VERBOSE=1
```

**Check daemon logs:**
```cmd
type %USERPROFILE%\.humanlayer\logs\daemon-dev-*.log | more
```

**Check WUI logs:**
```cmd
type %USERPROFILE%\.humanlayer\logs\wui-dev\codelayer.log | more
```

### Getting Help

1. **Check documentation**: `DEVELOPMENT.md`, `CONTRIBUTING.md`
2. **Search issues**: https://github.com/humanlayer/humanlayer/issues
3. **Discord community**: https://humanlayer.dev/discord
4. **Email support**: contact@humanlayer.dev

---

## Uninstallation

### Remove Application

**1. Uninstall Desktop UI:**
```
Settings → Apps → HumanLayer CodeLayer → Uninstall
```

**2. Remove data directory:**
```cmd
rmdir /S /Q %USERPROFILE%\.humanlayer
```

**3. Remove global npm packages:**
```cmd
npm uninstall -g humanlayer @anthropic-ai/claude-code
```

**4. Remove repository:**
```cmd
cd ..
rmdir /S /Q humanlayer
```

### Clean Uninstall

**Remove all traces:**
```powershell
# Stop processes
taskkill /F /IM hld.exe
taskkill /F /IM humanlayer.exe

# Remove data
Remove-Item -Recurse -Force $env:USERPROFILE\.humanlayer

# Remove config
Remove-Item -Recurse -Force $env:USERPROFILE\.claude

# Remove application
# Use Windows Settings → Apps → Uninstall

# Clean registry (optional)
# HKEY_CURRENT_USER\Software\HumanLayer
# HKEY_LOCAL_MACHINE\SOFTWARE\HumanLayer
```

---

## Additional Resources

### Documentation
- **Main README**: `README.md`
- **Contributing Guide**: `CONTRIBUTING.md`
- **Development Guide**: `DEVELOPMENT.md`
- **Claude Integration**: `CLAUDE.md`

### External Links
- **Website**: https://humanlayer.dev/code
- **GitHub**: https://github.com/humanlayer/humanlayer
- **Discord**: https://humanlayer.dev/discord
- **YouTube**: https://humanlayer.dev/youtube

### Technology Stack
- **Backend**: Go 1.24, SQLite, JSON-RPC
- **CLI**: TypeScript, Bun runtime, Commander.js
- **Frontend**: React 19, Tauri 2.x, Radix UI, Tailwind CSS 4
- **Build**: Turbo (monorepo), Biome (linting), Make

---

## Package Features Summary

### Core Features
✅ **Session Management** - Launch, track, and manage Claude Code sessions  
✅ **Approval System** - Human-in-the-loop approval workflows  
✅ **MCP Integration** - Model Context Protocol for AI agent communication  
✅ **Desktop UI** - Keyboard-first interface with dark/light themes  
✅ **CLI Tools** - Command-line interface for session control  
✅ **Multi-Claude** - Parallel session execution  
✅ **Context Engineering** - 30+ commands, 6 specialized agents  
✅ **Conversation History** - Full event tracking and replay  
✅ **Git Integration** - Worktree support for isolated development  
✅ **Cloud Workers** - Remote execution support  

### Technology Highlights
🔧 **Go 1.24** - High-performance daemon  
🎨 **React 19** - Modern UI framework  
🖥️ **Tauri 2.x** - Native desktop application  
⚡ **Bun** - Fast JavaScript runtime  
🗄️ **SQLite** - Embedded database  
🔌 **MCP Protocol** - AI agent interop  

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-08  
**Platform**: Windows 10/11 (x64)  
**License**: Apache 2.0

---

For questions or support, reach out:
- 📧 Email: contact@humanlayer.dev
- 💬 Discord: https://humanlayer.dev/discord
- 🐛 Issues: https://github.com/humanlayer/humanlayer/issues

