# HumanLayer Windows Automated Setup Script
# Version: 1.0.0
# Purpose: Automated installation and setup for Windows environments

#Requires -Version 5.1

param(
    [switch]$SkipPrereqCheck,
    [switch]$DevMode,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Color output functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Step { param($Message) Write-Host "`n🔹 $Message" -ForegroundColor Magenta }

# Banner
function Show-Banner {
    Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        HumanLayer Windows Setup Script v1.0.0             ║
║                                                           ║
║     The best way to get AI coding agents to solve        ║
║        hard problems in complex codebases                ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check prerequisite
function Test-Prerequisite {
    param(
        [string]$Name,
        [string]$Command,
        [string]$VersionArg = "--version",
        [string]$MinVersion = $null
    )
    
    Write-Info "Checking for $Name..."
    
    try {
        $result = & $Command $VersionArg 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$Name is installed: $($result | Select-Object -First 1)"
            return $true
        }
    }
    catch {
        Write-Warning "$Name not found"
        return $false
    }
    
    return $false
}

# Install Chocolatey
function Install-Chocolatey {
    Write-Step "Installing Chocolatey Package Manager"
    
    if (Test-Prerequisite -Name "Chocolatey" -Command "choco" -VersionArg "-v") {
        Write-Success "Chocolatey already installed"
        return $true
    }
    
    Write-Info "Installing Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    
    try {
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Success "Chocolatey installed successfully"
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        return $true
    }
    catch {
        Write-Error "Failed to install Chocolatey: $_"
        return $false
    }
}

# Install Git
function Install-Git {
    Write-Step "Installing Git for Windows"
    
    if (Test-Prerequisite -Name "Git" -Command "git") {
        return $true
    }
    
    Write-Info "Installing Git via Chocolatey..."
    choco install git -y
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (Test-Prerequisite -Name "Git" -Command "git") {
        Write-Success "Git installed successfully"
        return $true
    }
    else {
        Write-Error "Git installation failed"
        return $false
    }
}

# Install Node.js
function Install-NodeJS {
    Write-Step "Installing Node.js"
    
    if (Test-Prerequisite -Name "Node.js" -Command "node") {
        return $true
    }
    
    Write-Info "Installing Node.js LTS via Chocolatey..."
    choco install nodejs-lts -y
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (Test-Prerequisite -Name "Node.js" -Command "node") {
        Write-Success "Node.js installed successfully"
        return $true
    }
    else {
        Write-Error "Node.js installation failed"
        return $false
    }
}

# Install Bun
function Install-Bun {
    Write-Step "Installing Bun Runtime"
    
    if (Test-Prerequisite -Name "Bun" -Command "bun") {
        return $true
    }
    
    Write-Info "Installing Bun..."
    try {
        powershell -c "irm bun.sh/install.ps1|iex"
        
        # Add Bun to PATH
        $bunPath = "$env:USERPROFILE\.bun\bin"
        $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        if ($currentPath -notlike "*$bunPath*") {
            [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$bunPath", "User")
        }
        $env:Path += ";$bunPath"
        
        if (Test-Prerequisite -Name "Bun" -Command "bun") {
            Write-Success "Bun installed successfully"
            return $true
        }
    }
    catch {
        Write-Error "Bun installation failed: $_"
        return $false
    }
    
    return $false
}

# Install Go
function Install-Go {
    Write-Step "Installing Go"
    
    if (Test-Prerequisite -Name "Go" -Command "go" -VersionArg "version") {
        return $true
    }
    
    Write-Info "Installing Go via Chocolatey..."
    choco install golang -y
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Add GOPATH/bin to PATH
    $goPath = "$env:USERPROFILE\go\bin"
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$goPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$goPath", "User")
    }
    $env:Path += ";$goPath"
    
    if (Test-Prerequisite -Name "Go" -Command "go" -VersionArg "version") {
        Write-Success "Go installed successfully"
        return $true
    }
    else {
        Write-Error "Go installation failed"
        return $false
    }
}

# Install Rust
function Install-Rust {
    Write-Step "Installing Rust"
    
    if (Test-Prerequisite -Name "Rust" -Command "rustc") {
        return $true
    }
    
    Write-Info "Downloading Rust installer..."
    $rustupUrl = "https://win.rustup.rs/x86_64"
    $rustupInstaller = "$env:TEMP\rustup-init.exe"
    
    try {
        Invoke-WebRequest -Uri $rustupUrl -OutFile $rustupInstaller
        Write-Info "Running Rust installer (this may take a few minutes)..."
        Start-Process -FilePath $rustupInstaller -ArgumentList "-y" -Wait -NoNewWindow
        
        # Add cargo to PATH
        $cargoPath = "$env:USERPROFILE\.cargo\bin"
        $env:Path += ";$cargoPath"
        
        if (Test-Prerequisite -Name "Rust" -Command "rustc") {
            Write-Success "Rust installed successfully"
            return $true
        }
    }
    catch {
        Write-Error "Rust installation failed: $_"
        return $false
    }
    
    return $false
}

# Install Make
function Install-Make {
    Write-Step "Installing GNU Make"
    
    if (Test-Prerequisite -Name "Make" -Command "make") {
        return $true
    }
    
    Write-Info "Installing Make via Chocolatey..."
    choco install make -y
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    if (Test-Prerequisite -Name "Make" -Command "make") {
        Write-Success "Make installed successfully"
        return $true
    }
    else {
        Write-Warning "Make installation failed (optional - you can use native commands)"
        return $true  # Non-critical
    }
}

# Install Visual Studio Build Tools
function Install-VSBuildTools {
    Write-Step "Checking Visual Studio Build Tools"
    
    $vsWherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    
    if (Test-Path $vsWherePath) {
        $buildTools = & $vsWherePath -products * -requires Microsoft.VisualStudio.Workload.VCTools -property installationPath
        if ($buildTools) {
            Write-Success "Visual Studio Build Tools already installed"
            return $true
        }
    }
    
    Write-Warning "Visual Studio Build Tools not detected"
    Write-Info "This is required for Rust/Tauri compilation"
    Write-Info "Please install manually from: https://visualstudio.microsoft.com/downloads/"
    Write-Info "Select 'Desktop development with C++' workload"
    
    $response = Read-Host "Continue anyway? (y/N)"
    return ($response -eq "y" -or $response -eq "Y")
}

# Setup HumanLayer Repository
function Setup-Repository {
    Write-Step "Setting up HumanLayer repository"
    
    # Install mockgen
    Write-Info "Installing mockgen..."
    go install go.uber.org/mock/mockgen@latest
    
    # Install root dependencies
    Write-Info "Installing root dependencies..."
    bun install
    
    # Generate HLD mocks
    Write-Info "Generating HLD mocks..."
    Push-Location hld
    go generate ./...
    Pop-Location
    
    # Install and build HLD SDK
    Write-Info "Building HLD TypeScript SDK..."
    Push-Location hld\sdk\typescript
    bun install
    bun run build
    Pop-Location
    
    # Build hlyr CLI
    Write-Info "Building hlyr CLI..."
    Push-Location hlyr
    npm install
    npm run build
    Pop-Location
    
    # Install WUI dependencies
    Write-Info "Installing WUI dependencies..."
    bun install --cwd=humanlayer-wui
    
    # Create Tauri placeholder binaries
    Write-Info "Creating Tauri placeholders..."
    $tauriBinDir = "humanlayer-wui\src-tauri\bin"
    New-Item -ItemType Directory -Force -Path $tauriBinDir | Out-Null
    New-Item -ItemType File -Force -Path "$tauriBinDir\hld" | Out-Null
    New-Item -ItemType File -Force -Path "$tauriBinDir\humanlayer" | Out-Null
    
    # Build daemon
    Write-Info "Building HLD daemon..."
    Push-Location hld
    go build -o hld.exe
    Pop-Location
    
    Write-Success "Repository setup complete!"
}

# Create data directory
function Initialize-DataDirectory {
    Write-Step "Initializing data directory"
    
    $dataDir = "$env:USERPROFILE\.humanlayer"
    $logsDir = "$dataDir\logs"
    
    if (-not (Test-Path $dataDir)) {
        New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
        New-Item -ItemType Directory -Force -Path $logsDir | Out-Null
        Write-Success "Created data directory: $dataDir"
    }
    else {
        Write-Info "Data directory already exists"
    }
}

# Create default configuration
function Create-DefaultConfig {
    Write-Step "Creating default configuration"
    
    $configPath = "$env:USERPROFILE\.humanlayer\humanlayer.json"
    
    if (Test-Path $configPath) {
        Write-Info "Configuration file already exists"
        return
    }
    
    $defaultConfig = @{
        daemon_socket = "~/.humanlayer/daemon.sock"
        contact_channel = "email"
        claude_model = "claude-sonnet-4-20250514"
        max_turns = 30
    } | ConvertTo-Json -Depth 10
    
    Set-Content -Path $configPath -Value $defaultConfig
    Write-Success "Created default configuration: $configPath"
}

# Verification
function Test-Installation {
    Write-Step "Verifying installation"
    
    $checks = @(
        @{Name = "Git"; Command = "git"; Args = "--version"},
        @{Name = "Node.js"; Command = "node"; Args = "--version"},
        @{Name = "Bun"; Command = "bun"; Args = "--version"},
        @{Name = "Go"; Command = "go"; Args = "version"},
        @{Name = "Rust"; Command = "rustc"; Args = "--version"},
        @{Name = "Cargo"; Command = "cargo"; Args = "--version"}
    )
    
    $allPassed = $true
    
    foreach ($check in $checks) {
        try {
            $result = & $check.Command $check.Args 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($check.Name): OK"
            }
            else {
                Write-Error "$($check.Name): FAILED"
                $allPassed = $false
            }
        }
        catch {
            Write-Error "$($check.Name): NOT FOUND"
            $allPassed = $false
        }
    }
    
    # Check HLD binary
    if (Test-Path "hld\hld.exe") {
        Write-Success "HLD daemon: OK"
    }
    else {
        Write-Error "HLD daemon: NOT BUILT"
        $allPassed = $false
    }
    
    return $allPassed
}

# Print next steps
function Show-NextSteps {
    Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║                   🎉 Setup Complete! 🎉                   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

📝 Next Steps:

1. Start the daemon:
   cd hld
   .\hld.exe

2. Start the desktop UI (in another terminal):
   cd humanlayer-wui
   npm run tauri dev

3. Launch a Claude Code session:
   npx humanlayer launch "your task here"

📚 Documentation:
   - Full guide: .\WINDOWS_DEPLOYMENT.md
   - Development: .\DEVELOPMENT.md
   - Contributing: .\CONTRIBUTING.md

🔗 Resources:
   - Website: https://humanlayer.dev/code
   - Discord: https://humanlayer.dev/discord
   - GitHub: https://github.com/humanlayer/humanlayer

"@ -ForegroundColor Green
}

# Main execution
function Main {
    Show-Banner
    
    # Check administrator privileges
    if (-not (Test-Administrator)) {
        Write-Warning "Not running as Administrator"
        Write-Info "Some installations may require elevated privileges"
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Info "Please run as Administrator and try again"
            exit 1
        }
    }
    
    # Prerequisites check
    if (-not $SkipPrereqCheck) {
        Write-Step "Checking prerequisites"
        
        $needsInstall = $false
        
        if (-not (Install-Chocolatey)) {
            Write-Error "Failed to install Chocolatey"
            exit 1
        }
        
        if (-not (Install-Git)) { $needsInstall = $true }
        if (-not (Install-NodeJS)) { $needsInstall = $true }
        if (-not (Install-Bun)) { $needsInstall = $true }
        if (-not (Install-Go)) { $needsInstall = $true }
        if (-not (Install-Rust)) { $needsInstall = $true }
        if (-not (Install-Make)) { } # Optional
        if (-not (Install-VSBuildTools)) { } # Optional but recommended
        
        if ($needsInstall) {
            Write-Info "Refreshing environment variables..."
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        }
    }
    
    # Repository setup
    try {
        Setup-Repository
        Initialize-DataDirectory
        Create-DefaultConfig
        
        # Verification
        if (Test-Installation) {
            Show-NextSteps
            exit 0
        }
        else {
            Write-Error "Installation verification failed"
            Write-Info "Please check the errors above and try again"
            exit 1
        }
    }
    catch {
        Write-Error "Setup failed: $_"
        Write-Info "Please check WINDOWS_DEPLOYMENT.md for manual setup instructions"
        exit 1
    }
}

# Run main
Main

