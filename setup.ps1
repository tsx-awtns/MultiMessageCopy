# MultiMessageCopy Setup Script v1.7 - Final Version
# Author: tsx-awtns

param([switch]$SkipNodeInstall, [switch]$SkipGitInstall, [string]$VencordPath = "", [switch]$Help)

# Set UTF-8 encoding
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
    Write-Host "    |                MultiMessageCopy Setup Script v1.7                  |" -ForegroundColor White
    Write-Host "    |                            by tsx-awtns                            |" -ForegroundColor Gray
    Write-Host "    +----------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Help {
    Write-Banner
    Write-Host "USAGE: .\setup.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -SkipNodeInstall    Skip Node.js installation" -ForegroundColor Gray
    Write-Host "  -SkipGitInstall     Skip Git installation" -ForegroundColor Gray
    Write-Host "  -VencordPath        Custom Vencord path" -ForegroundColor Gray
    Write-Host "  -Help               Show this help" -ForegroundColor Gray
    Write-Host ""
}

if ($Help) { Show-Help; exit 0 }

function Test-Administrator {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Test-Command($Command) {
    try { $null = Get-Command $Command -ErrorAction Stop; return $true } catch { return $false }
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
            if ((Test-Path $path) -and ($env:PATH -notlike "*$path*")) { $env:PATH += ";$path" }
        }
        return $true
    } catch { return $false }
}

function Get-UserChoice($Prompt, $DefaultChoice = "Y", $ValidChoices = @("Y", "N")) {
    do {
        Write-Host ""
        Write-Host "QUESTION: $Prompt" -ForegroundColor Yellow
        Write-Host "Valid options: " -NoNewline -ForegroundColor Gray
        for ($i = 0; $i -lt $ValidChoices.Length; $i++) {
            if ($ValidChoices[$i] -eq $DefaultChoice) {
                Write-Host "[$($ValidChoices[$i])]" -NoNewline -ForegroundColor Green
            } else {
                Write-Host " $($ValidChoices[$i]) " -NoNewline -ForegroundColor White
            }
            if ($i -lt $ValidChoices.Length - 1) { Write-Host "/" -NoNewline -ForegroundColor Gray }
        }
        Write-Host ""
        Write-Host "Your choice (press Enter for default): " -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = $DefaultChoice }
        $choice = $choice.ToUpper()
        if ($ValidChoices -contains $choice) { return $choice }
        Write-Warning "Invalid choice. Try again."
    } while ($true)
}

function Get-UserPath($Prompt, $DefaultPath, $Example = "") {
    Write-Host ""
    Write-Host "PATH SELECTION: $Prompt" -ForegroundColor Yellow
    Write-Host "Default location: " -NoNewline -ForegroundColor Gray
    Write-Host "$DefaultPath" -ForegroundColor Green
    if ($Example) {
        Write-Host "Example: " -NoNewline -ForegroundColor Gray
        Write-Host "$Example" -ForegroundColor White
    }
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

function Show-InstallationSummary($NodeInstalled, $GitInstalled, $PnpmInstalled, $VencordPath) {
    Write-Host ""
    Write-Host "INSTALLATION SUMMARY" -ForegroundColor Magenta -BackgroundColor Black
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    if ($NodeInstalled) { Write-Success "Node.js - Ready" } else { Write-Error "Node.js - Failed" }
    if ($GitInstalled) { Write-Success "Git - Ready" } else { Write-Warning "Git - Skipped or Failed" }
    if ($PnpmInstalled) { Write-Success "pnpm - Ready" } else { Write-Error "pnpm - Failed" }
    Write-Info "Vencord Path: $VencordPath"
    Write-Host ""
}

function Install-NodeJS {
    Write-Step "Node.js Installation"
    Write-Host "Refreshing environment variables..." -ForegroundColor Gray
    Update-SessionPath
    if (Test-Command "node") {
        $version = node --version
        Write-Success "Node.js is already installed: $version"
        return $true
    }
    Write-Info "Installing Node.js..."
    $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
    $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
    try {
        Write-Host "Downloading..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
        Write-Host "Installing..." -ForegroundColor Gray
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
        if ($process.ExitCode -ne 0) { throw "Installation failed" }
        Start-Sleep -Seconds 3
        Update-SessionPath
        if (Test-Command "node") {
            Write-Success "Node.js installed successfully"
            Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Error "Installation completed but command not found"
            return $false
        }
    } catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Install-Git {
    Write-Step "Git Installation"
    Write-Host "Refreshing environment variables..." -ForegroundColor Gray
    Update-SessionPath
    if (Test-Command "git") {
        $version = git --version
        Write-Success "Git is already installed: $version"
        return $true
    }
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
            Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Warning "Git installed but command not found"
            return $false
        }
    } catch {
        Write-Error "Git installation failed"
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Install-Pnpm {
    Write-Step "pnpm Package Manager Installation"
    Write-Host "Refreshing environment variables..." -ForegroundColor Gray
    Update-SessionPath
    if (Test-Command "pnpm") {
        $version = pnpm --version
        Write-Success "pnpm is already installed: $version"
        return $true
    }
    if (!(Test-Command "npm")) {
        Write-Error "npm not available"
        return $false
    }
    Write-Info "Installing pnpm..."
    try {
        $npmProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
        if ($npmProcess.ExitCode -eq 0) {
            Update-SessionPath
            Start-Sleep -Seconds 2
            if (Test-Command "pnpm") {
                $version = pnpm --version
                Write-Success "pnpm installed successfully: $version"
                return $true
            }
        }
        Write-Error "pnpm installation failed"
        return $false
    } catch {
        Write-Error "pnpm installation failed"
        return $false
    }
}

function Install-Vencord($InstallPath) {
    Write-Step "Vencord Setup"
    try {
        if (Test-Path "$InstallPath\package.json") {
            $packageContent = Get-Content "$InstallPath\package.json" -Raw | ConvertFrom-Json
            if ($packageContent.name -eq "vencord") {
                Write-Success "Found existing Vencord installation at: $InstallPath"
                return $InstallPath
            }
        }
        Write-Info "Cloning Vencord repository from GitHub..."
        Write-Host "Preparing directories..." -ForegroundColor Gray
        $parentDir = Split-Path $InstallPath -Parent
        if (!(Test-Path $parentDir)) { New-Item -ItemType Directory -Path $parentDir -Force | Out-Null }
        if (Test-Path $InstallPath) { 
            Write-Warning "Removing existing directory: $InstallPath"
            Remove-Item $InstallPath -Recurse -Force 
        }
        Write-Host "Cloning repository..." -ForegroundColor Gray
        $currentLocation = Get-Location
        Set-Location $parentDir
        $targetDirName = Split-Path $InstallPath -Leaf
        git clone https://github.com/Vendicated/Vencord.git $targetDirName
        Set-Location $currentLocation
        Write-Host "Verifying installation..." -ForegroundColor Gray
        if (Test-Path "$InstallPath\package.json") {
            Write-Success "Vencord cloned successfully to: $InstallPath"
            return $InstallPath
        } else {
            throw "Vencord clone failed - package.json not found"
        }
    } catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        return $null
    }
}

function Install-VencordDependencies($VencordPath) {
    Write-Step "Vencord Dependencies Installation"
    try {
        $currentLocation = Get-Location
        Set-Location $VencordPath
        Write-Info "Installing project dependencies (this may take a few minutes)..."
        Write-Host "Running pnpm install..." -ForegroundColor Gray
        pnpm install
        Set-Location $currentLocation
        Write-Success "Vencord dependencies installed successfully"
        return $true
    } catch {
        Write-Error "Dependencies installation failed: $($_.Exception.Message)"
        return $false
    }
}

function Install-MultiMessageCopy($VencordPath) {
    Write-Step "MultiMessageCopy Plugin Installation"
    try {
        $userPluginsPath = Join-Path $VencordPath "src\userplugins"
        $pluginPath = Join-Path $userPluginsPath "MultiMessageCopy"
        Write-Host "Preparing plugin directory..." -ForegroundColor Gray
        if (!(Test-Path $userPluginsPath)) { 
            New-Item -ItemType Directory -Path $userPluginsPath -Force | Out-Null 
            Write-Info "Created userplugins directory"
        }
        if (Test-Path $pluginPath) { 
            Write-Info "Removing existing MultiMessageCopy directory..."
            Remove-Item $pluginPath -Recurse -Force 
        }
        Write-Host "Cloning plugin repository..." -ForegroundColor Gray
        Write-Info "Downloading MultiMessageCopy plugin from GitHub..."
        $currentLocation = Get-Location
        Set-Location $userPluginsPath
        git clone https://github.com/tsx-awtns/MultiMessageCopy.git temp-plugin
        Write-Host "Installing plugin files..." -ForegroundColor Gray
        if (Test-Path "temp-plugin\MultiMessageCopyFiles") {
            Move-Item "temp-plugin\MultiMessageCopyFiles" "MultiMessageCopy"
            Remove-Item "temp-plugin" -Recurse -Force
            Write-Success "MultiMessageCopy plugin installed successfully"
        } else {
            throw "MultiMessageCopyFiles folder not found in repository"
        }
        Set-Location $currentLocation
        return $true
    } catch {
        Write-Error "Plugin installation failed: $($_.Exception.Message)"
        Write-Info "You can clone manually: https://github.com/tsx-awtns/MultiMessageCopy.git"
        return $false
    }
}

function Build-Vencord($VencordPath) {
    Write-Step "Vencord Build Process"
    try {
        $currentLocation = Get-Location
        Set-Location $VencordPath
        Write-Info "Building Vencord with MultiMessageCopy plugin (this may take a few minutes)..."
        Write-Host "Compiling project..." -ForegroundColor Gray
        pnpm build
        Set-Location $currentLocation
        Write-Success "Vencord built successfully"
        return $true
    } catch {
        Write-Error "Build failed: $($_.Exception.Message)"
        return $false
    }
}

function Inject-Vencord($VencordPath) {
    Write-Step "Vencord Discord Integration"
    try {
        $currentLocation = Get-Location
        Set-Location $VencordPath
        Write-Info "Injecting Vencord into Discord..."
        Write-Host "Injecting Vencord..." -ForegroundColor Gray
        pnpm inject
        Set-Location $currentLocation
        Write-Success "Vencord injection completed successfully"
        return $true
    } catch {
        Write-Error "Injection failed: $($_.Exception.Message)"
        Write-Info "You can run 'pnpm inject' manually in the Vencord directory"
        return $false
    }
}

# Main execution
Write-Banner

try {
    # Administrator check
    if (!(Test-Administrator)) {
        Write-Warning "Script is not running as Administrator"
        Write-Info "Some installations might fail without administrator privileges"
        $continue = Get-UserChoice "Do you want to continue anyway" "Y" @("Y", "N")
        if ($continue -eq "N") { 
            Write-Info "Setup cancelled by user"
            exit 0 
        }
    }

    # Install Node.js
    $nodeInstalled = $true
    if (!$SkipNodeInstall) {
        $nodeInstalled = Install-NodeJS
        if (!$nodeInstalled) {
            Write-Error "Node.js installation failed. Cannot continue without Node.js"
            Write-Info "Please install Node.js manually from https://nodejs.org/ and restart PowerShell"
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        $nodeInstalled = Test-Command "node"
    }

    # Install Git
    $gitInstalled = $true
    if (!$SkipGitInstall) {
        $gitInstalled = Install-Git
        if (!$gitInstalled) {
            Write-Warning "Git installation failed or was skipped"
            Write-Info "Git is required for cloning repositories. You may need to install it manually"
        }
    } else {
        $gitInstalled = Test-Command "git"
    }

    # Install pnpm
    $pnpmInstalled = Install-Pnpm
    if (!$pnpmInstalled) {
        Write-Error "pnpm installation failed. Cannot continue without pnpm"
        Write-Info "Please restart PowerShell and try again"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Get Vencord installation path
    if ([string]::IsNullOrEmpty($VencordPath)) {
        $defaultPath = Join-Path $env:USERPROFILE "Desktop\Vencord"
        $VencordPath = Get-UserPath "Where should Vencord be installed" $defaultPath "C:\MyFolder\Vencord"
    }

    # Show installation summary
    Show-InstallationSummary $nodeInstalled $gitInstalled $pnpmInstalled $VencordPath

    # Install Vencord
    $vencordDir = Install-Vencord $VencordPath
    if (!$vencordDir) {
        Write-Error "Vencord setup failed. Cannot continue"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Install dependencies
    if (!(Install-VencordDependencies $vencordDir)) {
        Write-Error "Failed to install Vencord dependencies"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Install plugin
    if (!(Install-MultiMessageCopy $vencordDir)) {
        Write-Error "Failed to install MultiMessageCopy plugin"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Build Vencord
    if (!(Build-Vencord $vencordDir)) {
        Write-Error "Failed to build Vencord"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Ask about injection
    $inject = Get-UserChoice "Do you want to inject Vencord into Discord now" "Y" @("Y", "N")
    $injectionSkipped = $false
    if ($inject -eq "Y") {
        if (!(Inject-Vencord $vencordDir)) {
            $injectionSkipped = $true
        }
    } else {
        $injectionSkipped = $true
    }

    # Show completion message
    Write-Host ""
    Write-Host "SETUP COMPLETED SUCCESSFULLY!" -ForegroundColor Green -BackgroundColor Black
    Write-Host ("=" * 60) -ForegroundColor DarkGray
    Write-Host ""
    Write-Success "MultiMessageCopy plugin has been installed successfully"
    Write-Info "Installation location: $vencordDir"
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "   1. Restart Discord completely" -ForegroundColor White
    Write-Host "   2. Go to Discord Settings > Vencord > Plugins" -ForegroundColor White
    Write-Host "   3. Enable 'MultiMessageCopy' plugin" -ForegroundColor White
    Write-Host "   4. Start using the plugin features in Discord" -ForegroundColor White
    
    if ($injectionSkipped) {
        Write-Host ""
        Write-Warning "Manual injection required:"
        Write-Host "   Run 'pnpm inject' in: $vencordDir" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "USEFUL LINKS:" -ForegroundColor Cyan
    Write-Host "   Repository: https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor Blue
    Write-Host "   Issues: https://github.com/tsx-awtns/MultiMessageCopy/issues" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Thank you for using MultiMessageCopy!" -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to exit"

} catch {
    Write-Error "Setup failed with error: $($_.Exception.Message)"
    Write-Info "Please check the error messages above and try again"
    Read-Host "Press Enter to exit"
    exit 1
}
