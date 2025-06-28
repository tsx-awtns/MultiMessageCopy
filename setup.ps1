# MultiMessageCopy Setup Script v1.8 - Final Fixed Version
# Author: tsx-awtns

param([switch]$SkipNodeInstall, [switch]$SkipGitInstall, [string]$VencordPath = "", [switch]$Help)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Success($Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning($Message) { Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Error($Message) { Write-Host "[X] $Message" -ForegroundColor Red }
function Write-Info($Message) { Write-Host "[i] $Message" -ForegroundColor Cyan }
function Write-Step($Message) { Write-Host ""; Write-Host ">> $Message" -ForegroundColor Magenta; Write-Host ("=" * 60) -ForegroundColor Gray }

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "  __  __ _   _ _   _____ ___ __  __ _____ ____ ____    _    ____ _____" -ForegroundColor Cyan
    Write-Host " |  \/  | | | | | |_   _|_ _|  \/  | ____/ ___/ ___|  / \  / ___| ____|" -ForegroundColor Cyan  
    Write-Host " | |\/| | | | | | | | |  | || |\/| |  _| \___ \___ \ / _ \| |  _|  _|" -ForegroundColor Cyan
    Write-Host " | |  | | |_| | |_| | | |  | || |  | | |___ ___) |__) / ___ \ |_| | |___" -ForegroundColor Cyan
    Write-Host " |_|  |_|\___/ \___/  |_| |___|_|  |_|_____|____/____/_/   \_\____|_____|" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "                        COPY PLUGIN SETUP" -ForegroundColor White
    Write-Host ""
    Write-Host "    +----------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "    |                MultiMessageCopy Setup Script v1.8                  |" -ForegroundColor White
    Write-Host "    |                            by tsx-awtns                            |" -ForegroundColor Gray
    Write-Host "    +----------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

if ($Help) {
    Write-Banner
    Write-Host "USAGE: .\setup.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -SkipNodeInstall    Skip Node.js installation" -ForegroundColor Gray
    Write-Host "  -SkipGitInstall     Skip Git installation" -ForegroundColor Gray
    Write-Host "  -VencordPath        Custom Vencord path" -ForegroundColor Gray
    Write-Host "  -Help               Show this help" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

function Test-Administrator {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { 
        return $false 
    }
}

function Test-Command($Command) {
    try { 
        $null = Get-Command $Command -ErrorAction Stop
        return $true 
    } catch { 
        return $false 
    }
}

function Update-SessionPath {
    try {
        $machinePath = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $userPath = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $machinePath = [System.Environment]::ExpandEnvironmentVariables($machinePath)
        $userPath = [System.Environment]::ExpandEnvironmentVariables($userPath)
        $env:PATH = $machinePath + ";" + $userPath
        $commonPaths = @("${env:ProgramFiles}\nodejs", "${env:ProgramFiles(x86)}\nodejs", "$env:APPDATA\npm")
        foreach ($path in $commonPaths) {
            if ((Test-Path $path) -and ($env:PATH -notlike "*$path*")) { 
                $env:PATH += ";$path" 
            }
        }
    } catch {
        # Ignore errors
    }
}

function Get-UserChoice($Prompt, $DefaultChoice = "Y") {
    do {
        Write-Host ""
        Write-Host "QUESTION: $Prompt" -ForegroundColor Yellow
        Write-Host "Valid options: [$DefaultChoice]/ N" -ForegroundColor Gray
        Write-Host "Your choice (press Enter for default): " -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        if ([string]::IsNullOrWhiteSpace($choice)) { 
            $choice = $DefaultChoice 
        }
        $choice = $choice.ToUpper()
        if ($choice -eq "Y" -or $choice -eq "N") { 
            return $choice 
        }
        Write-Warning "Invalid choice. Try again."
    } while ($true)
}

function Get-UserPath($Prompt, $DefaultPath) {
    Write-Host ""
    Write-Host "PATH SELECTION: $Prompt" -ForegroundColor Yellow
    Write-Host "Default location: $DefaultPath" -ForegroundColor Green
    Write-Host "Example: C:\MyFolder\Vencord" -ForegroundColor White
    Write-Host "Enter custom path or press Enter for default: " -NoNewline -ForegroundColor Cyan
    $userInput = Read-Host
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        Write-Info "Using default path: $DefaultPath"
        return $DefaultPath
    }
    $userInput = $userInput.Trim('"').Trim("'").Trim()
    Write-Info "Using custom path: $userInput"
    return $userInput
}

Write-Banner

try {
    # Administrator check
    if (!(Test-Administrator)) {
        Write-Warning "Script is not running as Administrator"
        Write-Info "Some installations might fail without administrator privileges"
        $continue = Get-UserChoice "Do you want to continue anyway" "Y"
        if ($continue -eq "N") { 
            Write-Info "Setup cancelled by user"
            exit 0 
        }
    }

    # Check Node.js
    $nodeInstalled = $false
    if (!$SkipNodeInstall) {
        Write-Step "Node.js Installation"
        Write-Host "Refreshing environment variables..." -ForegroundColor Gray
        Update-SessionPath
        
        if (Test-Command "node") {
            $version = node --version
            Write-Success "Node.js is already installed: $version"
            $nodeInstalled = $true
        } else {
            Write-Info "Installing Node.js..."
            $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
            $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
            try {
                Write-Host "Downloading..." -ForegroundColor Gray
                Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
                Write-Host "Installing..." -ForegroundColor Gray
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
                if ($process.ExitCode -eq 0) {
                    Start-Sleep -Seconds 3
                    Update-SessionPath
                    if (Test-Command "node") {
                        Write-Success "Node.js installed successfully"
                        $nodeInstalled = $true
                    }
                }
                Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Error "Node.js installation failed"
                Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            }
        }
        
        if (!$nodeInstalled) {
            Write-Error "Node.js is required. Please install manually and restart."
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        $nodeInstalled = Test-Command "node"
    }

    # Check Git
    $gitInstalled = $false
    if (!$SkipGitInstall) {
        Write-Step "Git Installation"
        Write-Host "Refreshing environment variables..." -ForegroundColor Gray
        Update-SessionPath
        
        if (Test-Command "git") {
            $version = git --version
            Write-Success "Git is already installed: $version"
            $gitInstalled = $true
        } else {
            Write-Info "Installing Git..."
            $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
            $gitInstaller = "$env:TEMP\git-installer.exe"
            try {
                Write-Host "Downloading..." -ForegroundColor Gray
                Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
                Write-Host "Installing..." -ForegroundColor Gray
                Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
                Update-SessionPath
                if (Test-Command "git") {
                    Write-Success "Git installed successfully"
                    $gitInstalled = $true
                }
                Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Git installation failed"
                Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        $gitInstalled = Test-Command "git"
    }

    # Check pnpm
    Write-Step "pnpm Package Manager Installation"
    Write-Host "Refreshing environment variables..." -ForegroundColor Gray
    Update-SessionPath
    
    $pnpmInstalled = $false
    if (Test-Command "pnpm") {
        $version = pnpm --version
        Write-Success "pnpm is already installed: $version"
        $pnpmInstalled = $true
    } else {
        if (Test-Command "npm") {
            Write-Info "Installing pnpm..."
            try {
                $npmProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
                if ($npmProcess.ExitCode -eq 0) {
                    Update-SessionPath
                    Start-Sleep -Seconds 2
                    if (Test-Command "pnpm") {
                        $version = pnpm --version
                        Write-Success "pnpm installed successfully: $version"
                        $pnpmInstalled = $true
                    }
                }
            } catch {
                Write-Error "pnpm installation failed"
            }
        } else {
            Write-Error "npm not available"
        }
    }
    
    if (!$pnpmInstalled) {
        Write-Error "pnpm is required. Please restart PowerShell and try again."
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Get Vencord path
    if ([string]::IsNullOrEmpty($VencordPath)) {
        $defaultPath = Join-Path $env:USERPROFILE "Desktop\Vencord"
        $VencordPath = Get-UserPath "Where should Vencord be installed" $defaultPath
    }

    # Show summary
    Write-Host ""
    Write-Host "INSTALLATION SUMMARY" -ForegroundColor Magenta -BackgroundColor Black
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    if ($nodeInstalled) { Write-Success "Node.js - Ready" } else { Write-Error "Node.js - Failed" }
    if ($gitInstalled) { Write-Success "Git - Ready" } else { Write-Warning "Git - Skipped or Failed" }
    if ($pnpmInstalled) { Write-Success "pnpm - Ready" } else { Write-Error "pnpm - Failed" }
    Write-Info "Vencord Path: $VencordPath"
    Write-Host ""

    # Install Vencord
    Write-Step "Vencord Setup"
    $vencordDir = $null
    try {
        if (Test-Path "$VencordPath\package.json") {
            $packageContent = Get-Content "$VencordPath\package.json" -Raw | ConvertFrom-Json
            if ($packageContent.name -eq "vencord") {
                Write-Success "Found existing Vencord installation"
                $vencordDir = $VencordPath
            }
        }
        
        if (!$vencordDir) {
            Write-Info "Cloning Vencord repository..."
            $parentDir = Split-Path $VencordPath -Parent
            if (!(Test-Path $parentDir)) { 
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null 
            }
            if (Test-Path $VencordPath) { 
                Remove-Item $VencordPath -Recurse -Force 
            }
            
            $currentLocation = Get-Location
            Set-Location $parentDir
            $targetDirName = Split-Path $VencordPath -Leaf
            git clone https://github.com/Vendicated/Vencord.git $targetDirName
            Set-Location $currentLocation
            
            if (Test-Path "$VencordPath\package.json") {
                Write-Success "Vencord cloned successfully"
                $vencordDir = $VencordPath
            }
        }
    } catch {
        Write-Error "Vencord setup failed: $($_.Exception.Message)"
    }
    
    if (!$vencordDir) {
        Write-Error "Cannot continue without Vencord"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Install dependencies
    Write-Step "Installing Dependencies"
    try {
        $currentLocation = Get-Location
        Set-Location $vencordDir
        Write-Info "Running pnpm install..."
        pnpm install
        Set-Location $currentLocation
        Write-Success "Dependencies installed"
    } catch {
        Write-Error "Dependencies installation failed"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Install plugin
    Write-Step "Installing Plugin"
    try {
        $userPluginsPath = Join-Path $vencordDir "src\userplugins"
        $pluginPath = Join-Path $userPluginsPath "MultiMessageCopy"
        
        if (!(Test-Path $userPluginsPath)) { 
            New-Item -ItemType Directory -Path $userPluginsPath -Force | Out-Null 
        }
        if (Test-Path $pluginPath) { 
            Remove-Item $pluginPath -Recurse -Force 
        }
        
        Write-Info "Downloading plugin..."
        $currentLocation = Get-Location
        Set-Location $userPluginsPath
        git clone https://github.com/tsx-awtns/MultiMessageCopy.git temp-plugin
        
        if (Test-Path "temp-plugin\MultiMessageCopyFiles") {
            Move-Item "temp-plugin\MultiMessageCopyFiles" "MultiMessageCopy"
            Remove-Item "temp-plugin" -Recurse -Force
            Write-Success "Plugin installed successfully"
        } else {
            throw "Plugin files not found"
        }
        Set-Location $currentLocation
    } catch {
        Write-Error "Plugin installation failed"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Build Vencord
    Write-Step "Building Vencord"
    try {
        $currentLocation = Get-Location
        Set-Location $vencordDir
        Write-Info "Building..."
        pnpm build
        Set-Location $currentLocation
        Write-Success "Build completed"
    } catch {
        Write-Error "Build failed"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Ask about injection
    $inject = Get-UserChoice "Do you want to inject Vencord into Discord now" "Y"
    if ($inject -eq "Y") {
        Write-Step "Injecting Vencord"
        try {
            $currentLocation = Get-Location
            Set-Location $vencordDir
            Write-Info "Injecting..."
            pnpm inject
            Set-Location $currentLocation
            Write-Success "Injection completed"
        } catch {
            Write-Warning "Injection failed - you can run 'pnpm inject' manually"
        }
    }

    # Success message
    Write-Host ""
    Write-Host "SETUP COMPLETED SUCCESSFULLY!" -ForegroundColor Green -BackgroundColor Black
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host ""
    Write-Success "MultiMessageCopy plugin installed successfully"
    Write-Info "Installation: $vencordDir"
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Restart Discord" -ForegroundColor White
    Write-Host "2. Settings > Vencord > Plugins" -ForegroundColor White
    Write-Host "3. Enable 'MultiMessageCopy'" -ForegroundColor White
    Write-Host ""
    Write-Host "Repository: https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor Blue
    Write-Host ""
    Read-Host "Press Enter to exit"

} catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    Read-Host "Press Enter to exit"
    exit 1
}
