# HumanLayer Windows Quick Start Guide

**Get up and running in 10 minutes!**

---

## 🚀 Fastest Path to Running

### Option 1: Automated Setup (Recommended)

```powershell
# 1. Clone repository
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer

# 2. Run automated setup (installs everything)
powershell -ExecutionPolicy Bypass -File .\scripts\windows-setup.ps1

# 3. Start development environment
.\scripts\windows-start-dev.bat
```

**That's it!** The UI will open automatically.

---

### Option 2: Manual Quick Setup

**Prerequisites** (install these first):
- Git: https://git-scm.com/download/win
- Node.js v20: https://nodejs.org/
- Bun: `powershell -c "irm bun.sh/install.ps1|iex"`
- Go 1.24: https://go.dev/dl/
- Rust: https://rustup.rs/

**Setup commands:**
```cmd
# Clone and setup
git clone https://github.com/humanlayer/humanlayer.git
cd humanlayer
bun install

# Build daemon
cd hld
go build -o hld.exe
cd ..

# Build CLI
cd hlyr
npm install && npm run build
cd ..

# Install UI dependencies
cd humanlayer-wui
bun install
cd ..
```

**Run:**
```cmd
# Terminal 1 - Start daemon
cd hld
hld.exe

# Terminal 2 - Start UI
cd humanlayer-wui
npm run tauri dev

# Terminal 3 - Launch Claude session
npx humanlayer launch "your task"
```

---

## 🎯 What is HumanLayer?

**CodeLayer** - An open-source IDE for orchestrating AI coding agents.

**Key Features:**
- 🤖 Run multiple Claude Code sessions in parallel
- ✋ Human-in-the-loop approval system
- ⚡ Keyboard-first Superhuman-style UI
- 📝 30+ specialized commands
- 🧠 6 specialized sub-agents
- 🔄 Git worktree integration

---

## 📁 Quick Command Reference

### Development Scripts (Windows)

```cmd
# Automated setup
.\scripts\windows-setup.ps1

# Start development environment
.\scripts\windows-start-dev.bat

# Build everything for production
.\scripts\windows-build-all.bat

# Clean build artifacts
.\scripts\windows-clean.bat
```

### Make Commands (if Make installed)

```cmd
# Setup
make setup              # Full repository setup

# Development
make daemon-dev         # Start daemon (dev mode)
make wui-dev           # Start UI (dev mode)

# Testing
make check             # Run linting
make test              # Run tests
make check-test        # Run all checks and tests

# Production
make daemon-nightly    # Build production daemon
make wui-nightly      # Build and install production UI
```

### Manual Commands

```cmd
# Build daemon
cd hld && go build -o hld.exe && cd ..

# Build CLI
cd hlyr && npm run build && cd ..

# Build UI (development)
cd humanlayer-wui && npm run tauri dev && cd ..

# Build UI (production)
cd humanlayer-wui && npm run tauri build && cd ..
```

---

## 🔧 Common Tasks

### Launch a Claude Code Session

```cmd
# Basic
npx humanlayer launch "implement user authentication"

# With custom prompt
npx humanlayer launch "fix the login bug" --prompt "You are a security expert..."

# Using dev daemon
set HUMANLAYER_DAEMON_SOCKET=%USERPROFILE%\.humanlayer\daemon-dev.sock
npx humanlayer launch "your task"
```

### Check Logs

```cmd
# Daemon logs
type %USERPROFILE%\.humanlayer\logs\daemon-dev-*.log

# UI logs
type %USERPROFILE%\.humanlayer\logs\wui-dev\codelayer.log
```

### Query Database

```cmd
# Install SQLite (via Chocolatey)
choco install sqlite

# View recent sessions
sqlite3 %USERPROFILE%\.humanlayer\daemon-dev.db "SELECT id, prompt, status, created_at FROM sessions ORDER BY created_at DESC LIMIT 5;"
```

---

## 📚 Project Structure

```
humanlayer/
├── hld/                    # Go daemon (core)
│   └── hld.exe            # Built daemon
├── hlyr/                   # CLI tool
├── humanlayer-wui/         # Desktop UI (Tauri + React)
├── scripts/
│   ├── windows-setup.ps1        # Automated setup
│   ├── windows-start-dev.bat    # Development starter
│   ├── windows-build-all.bat    # Build script
│   └── windows-clean.bat        # Cleanup script
├── WINDOWS_DEPLOYMENT.md   # Full documentation (you are here!)
└── WINDOWS_QUICKSTART.md   # This file
```

---

## ⚠️ Common Issues & Quick Fixes

### "make: command not found"
```powershell
choco install make
```
Or use native commands (see scripts above)

### "Bun not found"
```powershell
# Reinstall
powershell -c "irm bun.sh/install.ps1|iex"

# Add to PATH
$env:Path += ";$env:USERPROFILE\.bun\bin"
```

### "Go build fails"
```cmd
# Install mockgen
go install go.uber.org/mock/mockgen@latest
```

### "Tauri build errors"
Install Visual Studio Build Tools:
```
https://visualstudio.microsoft.com/downloads/
Select: "Desktop development with C++"
```

### "Database locked"
```cmd
# Stop daemon
taskkill /F /IM hld.exe

# Remove socket
del %USERPROFILE%\.humanlayer\daemon.sock
del %USERPROFILE%\.humanlayer\daemon-dev.sock
```

---

## 🆘 Need Help?

1. **Full Documentation**: `WINDOWS_DEPLOYMENT.md`
2. **GitHub Issues**: https://github.com/humanlayer/humanlayer/issues
3. **Discord**: https://humanlayer.dev/discord
4. **Email**: contact@humanlayer.dev

---

## 📦 What Gets Installed?

**Development Mode:**
- HLD Daemon at: `hld\hld.exe`
- HLYR CLI at: `hlyr\dist\`
- WUI runs in dev mode (no installation)

**Production Build:**
- HLD Daemon: `hld\hld-nightly.exe`
- WUI Installer: `humanlayer-wui\src-tauri\target\release\bundle\nsis\HumanLayer_<version>_x64-setup.exe`

**Data Directory:**
- Location: `%USERPROFILE%\.humanlayer\`
- Contents: databases, logs, sockets, config

---

## 🎓 Next Steps

1. **Read the full guide**: `WINDOWS_DEPLOYMENT.md`
2. **Join Discord**: https://humanlayer.dev/discord
3. **Watch tutorials**: https://humanlayer.dev/youtube
4. **Contribute**: `CONTRIBUTING.md`

---

## 🚀 Ready to Build?

```powershell
# One-liner to get started:
git clone https://github.com/humanlayer/humanlayer.git && cd humanlayer && powershell -ExecutionPolicy Bypass -File .\scripts\windows-setup.ps1
```

**Happy Coding! 🎉**

---

**Version**: 1.0.0  
**Platform**: Windows 10/11 (x64)  
**License**: Apache 2.0

