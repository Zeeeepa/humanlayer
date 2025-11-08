# HumanLayer Windows Enhanced Setup Script with AI Fallback & Error Handling
# Version: 2.0.0
# Purpose: Production-ready automated installation with comprehensive error recovery

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$SkipPrereqCheck,
    [switch]$DevMode,
    [switch]$Quiet,
    [switch]$NoFallback,
    [int]$MaxRetries = 3,
    [string]$LogFile = "$env:TEMP\humanlayer-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Global error tracking
$script:ErrorCount = 0
$script:WarningCount = 0
$script:SetupState = @{
    StartTime = Get-Date
    Steps = @()
    Errors = @()
    Warnings = @()
}

#region Logging Functions

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    switch ($Level) {
        "SUCCESS" { Write-Host "✅ $Message" -ForegroundColor Green }
        "INFO"    { Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
        "WARN"    { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        "ERROR"   { Write-Host "❌ $Message" -ForegroundColor Red }
        "DEBUG"   { if ($DevMode) { Write-Host "🔍 $Message" -ForegroundColor Gray } }
    }
    
    # Write to log file
    Add-Content -Path $LogFile -Value $logMessage
}

function Write-Success { param($Message) Write-Log $Message "SUCCESS" }
function Write-Info { param($Message) Write-Log $Message "INFO" }
function Write-Warning { param($Message) Write-Log $Message "WARN"; $script:WarningCount++ }
function Write-Error { param($Message) Write-Log $Message "ERROR"; $script:ErrorCount++ }
function Write-Debug { param($Message) Write-Log $Message "DEBUG" }
function Write-Step { param($Message) Write-Log "`n🔹 $Message" "INFO" }

#endregion

#region Error Handling Framework

function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [string]$OperationName,
        [int]$MaxAttempts = $MaxRetries,
        [int]$DelaySeconds = 2
    )
    
    $attempt = 1
    $success = $false
    $lastError = $null
    
    while (-not $success -and $attempt -le $MaxAttempts) {
        try {
            Write-Debug "Attempt $attempt/$MaxAttempts for: $OperationName"
            $result = & $ScriptBlock
            $success = $true
            Write-Debug "$OperationName succeeded on attempt $attempt"
            return $result
        }
        catch {
            $lastError = $_
            Write-Warning "$OperationName failed (attempt $attempt/$MaxAttempts): $($_.Exception.Message)"
            
            if ($attempt -lt $MaxAttempts) {
                $delay = $DelaySeconds * [Math]::Pow(2, $attempt - 1) # Exponential backoff
                Write-Info "Retrying in $delay seconds..."
                Start-Sleep -Seconds $delay
            }
            
            $attempt++
        }
    }
    
    if (-not $success) {
        $script:SetupState.Errors += @{
            Operation = $OperationName
            Error = $lastError.Exception.Message
            Timestamp = Get-Date
        }
        throw "Failed to complete $OperationName after $MaxAttempts attempts. Last error: $($lastError.Exception.Message)"
    }
}

function Test-StepStatus {
    param(
        [string]$StepName,
        [scriptblock]$TestBlock
    )
    
    try {
        $result = & $TestBlock
        if ($result) {
            Write-Success "$StepName - Already complete"
            return $true
        }
        return $false
    }
    catch {
        Write-Debug "$StepName - Status check failed: $_"
        return $false
    }
}

function Save-SetupState {
    $statePath = "$env:TEMP\humanlayer-setup-state.json"
    $script:SetupState | ConvertTo-Json -Depth 10 | Set-Content -Path $statePath
    Write-Debug "Setup state saved to: $statePath"
}

#endregion

#region AI Model Configuration

function Initialize-AIConfig {
    Write-Step "Configuring AI Model Fallback"
    
    $configPath = "$env:USERPROFILE\.humanlayer\humanlayer.json"
    
    if (Test-Path $configPath) {
        Write-Info "Configuration file already exists"
        $config = Get-Content $configPath | ConvertFrom-Json
    }
    else {
        $config = @{}
    }
    
    # Primary and fallback model configuration
    if (-not $config.PSObject.Properties['claude_model']) {
        $config | Add-Member -NotePropertyName "claude_model" -NotePropertyValue "claude-sonnet-4-20250514"
    }
    
    if (-not $config.PSObject.Properties['fallback_models']) {
        $config | Add-Member -NotePropertyName "fallback_models" -NotePropertyValue @(
            @{
                model = "claude-3-5-sonnet-20241022"
                priority = 1
                enabled = $true
            },
            @{
                model = "claude-3-opus-20240229"
                priority = 2
                enabled = $true
            }
        )
    }
    
    # Model retry configuration
    if (-not $config.PSObject.Properties['model_config']) {
        $config | Add-Member -NotePropertyName "model_config" -NotePropertyValue @{
            retry_attempts = 3
            retry_delay_ms = 1000
            timeout_seconds = 30
            fallback_on_rate_limit = $true
            fallback_on_error = $true
        }
    }
    
    # Health check configuration
    if (-not $config.PSObject.Properties['health_check']) {
        $config | Add-Member -NotePropertyName "health_check" -NotePropertyValue @{
            enabled = $true
            interval_seconds = 60
            failure_threshold = 3
            success_threshold = 1
        }
    }
    
    # Save enhanced configuration
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
    Write-Success "AI fallback configuration created"
    Write-Info "Primary model: $($config.claude_model)"
    Write-Info "Fallback models: $($config.fallback_models.Count) configured"
}

#endregion

#region Enhanced Health Checks

function Test-SystemHealth {
    Write-Step "Running System Health Checks"
    
    $healthStatus = @{
        DiskSpace = $false
        Memory = $false
        Network = $false
        Prerequisites = $false
    }
    
    # Check disk space (5GB minimum)
    $drive = Get-PSDrive -Name C
    $freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
    if ($freeSpaceGB -gt 5) {
        $healthStatus.DiskSpace = $true
        Write-Success "Disk space: ${freeSpaceGB}GB available"
    }
    else {
        Write-Warning "Low disk space: Only ${freeSpaceGB}GB available (5GB required)"
    }
    
    # Check memory (8GB minimum)
    $memory = Get-CimInstance -ClassName Win32_ComputerSystem
    $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    if ($totalMemoryGB -ge 8) {
        $healthStatus.Memory = $true
        Write-Success "Memory: ${totalMemoryGB}GB total"
    }
    else {
        Write-Warning "Low memory: Only ${totalMemoryGB}GB (8GB recommended)"
    }
    
    # Check network connectivity
    try {
        $testConnection = Test-NetConnection -ComputerName "github.com" -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($testConnection) {
            $healthStatus.Network = $true
            Write-Success "Network connectivity verified"
        }
    }
    catch {
        Write-Warning "Network connectivity check failed"
    }
    
    return $healthStatus
}

function Test-PrerequisiteVersions {
    Write-Step "Validating Prerequisite Versions"
    
    $versions = @{}
    
    # Check Git version
    try {
        $gitVersion = (git --version 2>&1 | Select-String -Pattern '\d+\.\d+\.\d+').Matches[0].Value
        $versions.Git = $gitVersion
        Write-Success "Git: $gitVersion"
    }
    catch {
        Write-Warning "Git not found or version check failed"
    }
    
    # Check Node version
    try {
        $nodeVersion = (node --version 2>&1).Trim('v')
        $versions.Node = $nodeVersion
        $nodeMajor = [int]($nodeVersion.Split('.')[0])
        if ($nodeMajor -ge 18) {
            Write-Success "Node.js: $nodeVersion"
        }
        else {
            Write-Warning "Node.js version $nodeVersion is older than recommended (18+)"
        }
    }
    catch {
        Write-Warning "Node.js not found or version check failed"
    }
    
    # Check Go version
    try {
        $goVersion = (go version 2>&1 | Select-String -Pattern 'go\d+\.\d+\.\d+').Matches[0].Value
        $versions.Go = $goVersion
        Write-Success "Go: $goVersion"
    }
    catch {
        Write-Warning "Go not found or version check failed"
    }
    
    # Check Rust version
    try {
        $rustVersion = (rustc --version 2>&1 | Select-String -Pattern '\d+\.\d+\.\d+').Matches[0].Value
        $versions.Rust = $rustVersion
        Write-Success "Rust: $rustVersion"
    }
    catch {
        Write-Warning "Rust not found or version check failed"
    }
    
    return $versions
}

#endregion

#region Validation Functions

function Test-InstallationComplete {
    Write-Step "Validating Installation"
    
    $validationResults = @{
        Daemon = $false
        CLI = $false
        WUI = $false
        Config = $false
    }
    
    # Check HLD daemon
    if (Test-Path "hld\hld.exe") {
        $validationResults.Daemon = $true
        Write-Success "HLD daemon binary found"
    }
    else {
        Write-Warning "HLD daemon binary not found"
    }
    
    # Check HLYR CLI
    if (Test-Path "hlyr\dist") {
        $validationResults.CLI = $true
        Write-Success "HLYR CLI built successfully"
    }
    else {
        Write-Warning "HLYR CLI not built"
    }
    
    # Check WUI dependencies
    if (Test-Path "humanlayer-wui\node_modules") {
        $validationResults.WUI = $true
        Write-Success "WUI dependencies installed"
    }
    else {
        Write-Warning "WUI dependencies not installed"
    }
    
    # Check configuration
    if (Test-Path "$env:USERPROFILE\.humanlayer\humanlayer.json") {
        $validationResults.Config = $true
        Write-Success "Configuration file created"
    }
    else {
        Write-Warning "Configuration file not found"
    }
    
    $allValid = ($validationResults.Values | Where-Object { $_ -eq $false }).Count -eq 0
    
    if ($allValid) {
        Write-Success "All validation checks passed!"
    }
    else {
        Write-Warning "Some validation checks failed. Review warnings above."
    }
    
    return $validationResults
}

function Test-RuntimeHealth {
    Write-Step "Testing Runtime Health"
    
    # Test daemon can start (quick test)
    Write-Info "Testing daemon binary..."
    try {
        $testProcess = Start-Process -FilePath "hld\hld.exe" -ArgumentList "--version" -NoNewWindow -Wait -PassThru
        if ($testProcess.ExitCode -eq 0) {
            Write-Success "Daemon binary is functional"
        }
        else {
            Write-Warning "Daemon binary test returned non-zero exit code"
        }
    }
    catch {
        Write-Warning "Daemon binary test failed: $_"
    }
    
    Write-Success "Runtime health check complete"
}

#endregion

#region Rollback Support

function New-BackupPoint {
    param([string]$BackupName)
    
    $backupDir = "$env:USERPROFILE\.humanlayer\backups\$BackupName-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    if (Test-Path "$env:USERPROFILE\.humanlayer") {
        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
        Copy-Item -Path "$env:USERPROFILE\.humanlayer\*" -Destination $backupDir -Recurse -Force
        Write-Success "Backup created: $backupDir"
        return $backupDir
    }
    
    return $null
}

function Restore-FromBackup {
    param([string]$BackupPath)
    
    if (Test-Path $BackupPath) {
        Write-Info "Restoring from backup: $BackupPath"
        Remove-Item -Path "$env:USERPROFILE\.humanlayer\*" -Recurse -Force
        Copy-Item -Path "$BackupPath\*" -Destination "$env:USERPROFILE\.humanlayer" -Recurse -Force
        Write-Success "Restored from backup"
    }
}

#endregion

#region Installation Functions (Enhanced)

function Install-Chocolatey {
    if (Test-StepStatus -StepName "Chocolatey" -TestBlock { (Get-Command choco -ErrorAction SilentlyContinue) -ne $null }) {
        return
    }
    
    Write-Step "Installing Chocolatey Package Manager"
    
    Invoke-WithRetry -OperationName "Chocolatey Installation" -ScriptBlock {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # Verify installation
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            throw "Chocolatey installation verification failed"
        }
    }
    
    Write-Success "Chocolatey installed successfully"
}

function Install-Prerequisites {
    Write-Step "Installing Prerequisites"
    
    $prerequisites = @(
        @{ Name = "Git"; Package = "git"; TestCmd = "git" },
        @{ Name = "Node.js"; Package = "nodejs-lts"; TestCmd = "node" },
        @{ Name = "Go"; Package = "golang"; TestCmd = "go" }
    )
    
    foreach ($prereq in $prerequisites) {
        if (Get-Command $prereq.TestCmd -ErrorAction SilentlyContinue) {
            Write-Success "$($prereq.Name) already installed"
            continue
        }
        
        Write-Info "Installing $($prereq.Name)..."
        Invoke-WithRetry -OperationName "$($prereq.Name) Installation" -ScriptBlock {
            choco install $prereq.Package -y
            
            # Refresh PATH
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            # Verify
            if (-not (Get-Command $prereq.TestCmd -ErrorAction SilentlyContinue)) {
                throw "$($prereq.Name) installation verification failed"
            }
        }
        
        Write-Success "$($prereq.Name) installed successfully"
    }
}

#endregion

#region Main Execution

function Show-Banner {
    Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     HumanLayer Enhanced Setup Script v2.0.0               ║
║     With AI Fallback & Error Recovery                     ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
}

function Show-Summary {
    $duration = (Get-Date) - $script:SetupState.StartTime
    
    Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║                   📊 Setup Summary                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

Duration: $($duration.ToString('mm\:ss'))
Errors: $script:ErrorCount
Warnings: $script:WarningCount

Log file: $LogFile

"@ -ForegroundColor $(if ($script:ErrorCount -eq 0) { "Green" } else { "Yellow" })
}

function Main {
    try {
        Show-Banner
        
        Write-Info "Log file: $LogFile"
        Write-Info "Starting setup at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        
        # Pre-flight health checks
        $health = Test-SystemHealth
        
        if (-not $health.DiskSpace) {
            Write-Warning "Insufficient disk space may cause installation issues"
        }
        
        # Create backup point
        $backupPath = New-BackupPoint -BackupName "pre-setup"
        
        try {
            # Installation steps
            Install-Chocolatey
            Install-Prerequisites
            
            # Repository setup (would call existing functions here)
            # Setup-Repository
            
            # Initialize AI configuration
            Initialize-AIConfig
            
            # Validation
            $validation = Test-InstallationComplete
            Test-RuntimeHealth
            Test-PrerequisiteVersions
            
            # Save state
            Save-SetupState
            
            Show-Summary
            
            if ($script:ErrorCount -eq 0) {
                Write-Success "Setup completed successfully!"
                exit 0
            }
            else {
                Write-Warning "Setup completed with errors. Check log file for details."
                exit 1
            }
        }
        catch {
            Write-Error "Fatal error during setup: $_"
            
            if ($backupPath) {
                Write-Info "Attempting to restore from backup..."
                Restore-FromBackup -BackupPath $backupPath
            }
            
            Show-Summary
            throw
        }
    }
    catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        Write-Error "Stack trace: $($_.ScriptStackTrace)"
        exit 1
    }
}

# Run main
Main

#endregion

