# MultiMessageCopy Setup Script v2.2 - Fixed Admin Handling
# Author: tsx-awtns (Enhanced by axolotle024)

param([switch]$SkipNodeInstall, [switch]$SkipGitInstall, [string]$VencordPath = "", [switch]$Help, [switch]$UseChocolatey)

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
    Write-Host "                        COPY PLUGIN SETUP v2.2" -ForegroundColor White
    Write-Host ""
    Write-Host "    +----------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "    |                MultiMessageCopy Setup Script v2.2                  |" -ForegroundColor White
    Write-Host "    |                    Fixed Admin Handling                            |" -ForegroundColor Gray
    Write-Host "    +----------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

if ($Help) {
    Write-Banner
    Write-Host "USAGE: .\setup-enhanced-fixed.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -SkipNodeInstall    Skip Node.js installation" -ForegroundColor Gray
    Write-Host "  -SkipGitInstall     Skip Git installation" -ForegroundColor Gray
    Write-Host "  -VencordPath        Custom Vencord path" -ForegroundColor Gray
    Write-Host "  -UseChocolatey      Use Chocolatey for installations (recommended)" -ForegroundColor Gray
    Write-Host "  -Help               Show this help" -ForegroundColor Gray
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\setup-enhanced-fixed.ps1 -UseChocolatey" -ForegroundColor Gray
    Write-Host "  .\setup-enhanced-fixed.ps1 -VencordPath 'C:\MyVencord'" -ForegroundColor Gray
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

function Get-AdminChoice {
    do {
        Write-Host ""
        Write-Host "ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Red -BackgroundColor Black
        Write-Host ("=" * 60) -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "This script works best with Administrator privileges for:" -ForegroundColor Yellow
        Write-Host "• Installing Node.js and Git" -ForegroundColor White
        Write-Host "• Installing Chocolatey package manager" -ForegroundColor White
        Write-Host "• Modifying system PATH variables" -ForegroundColor White
        Write-Host ""
        Write-Host "AVAILABLE OPTIONS:" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "[1] Exit - Close this script" -ForegroundColor Gray
        Write-Host "[2] Continue - Proceed without admin rights (may fail)" -ForegroundColor Gray
        Write-Host "[3] Restart as Administrator - Recommended" -ForegroundColor Green
        Write-Host ""
        Write-Host "Enter your choice (1-3): " -NoNewline -ForegroundColor Cyan
        
        $choice = Read-Host
        
        switch ($choice) {
            "1" { return "EXIT" }
            "2" { return "CONTINUE" }
            "3" { return "ADMIN" }
            default { 
                Write-Warning "Invalid choice. Please enter 1, 2, or 3."
                continue
            }
        }
    } while ($true)
}

function Start-AdminPowerShell {
    Write-Info "Restarting script with Administrator privileges..."
    Write-Host ""
    
    try {
        # Try to get the current script path
        $scriptPath = $null
        
        # Method 1: Try PSCommandPath (works when script is saved as file)
        if (![string]::IsNullOrEmpty($PSCommandPath)) {
            $scriptPath = $PSCommandPath
        }
        # Method 2: Try MyInvocation.MyCommand.Path
        elseif ($MyInvocation.MyCommand.Path) {
            $scriptPath = $MyInvocation.MyCommand.Path
        }
        # Method 3: Try MyInvocation.ScriptName
        elseif (![string]::IsNullOrEmpty($MyInvocation.ScriptName)) {
            $scriptPath = $MyInvocation.ScriptName
        }
        
        # Build arguments to pass to the new instance
        $arguments = @()
        if ($SkipNodeInstall) { $arguments += "-SkipNodeInstall" }
        if ($SkipGitInstall) { $arguments += "-SkipGitInstall" }
        if ($UseChocolatey) { $arguments += "-UseChocolatey" }
        if (![string]::IsNullOrEmpty($VencordPath)) { $arguments += "-VencordPath '$VencordPath'" }
        
        $argumentString = $arguments -join " "
        
        if (![string]::IsNullOrEmpty($scriptPath) -and (Test-Path $scriptPath)) {
            # Script file exists, restart it directly
            Write-Info "Restarting from file: $scriptPath"
            $processArgs = "-NoExit -ExecutionPolicy Bypass -File `"$scriptPath`" $argumentString"
        } else {
            # Script was run from web or no file path available - use download method
            Write-Info "Script was run from web, using download method..."
            
            # Create a temporary script file with current parameters
            $tempScript = "$env:TEMP\MultiMessageCopy-Setup.ps1"
            
            # Download the script to temp file first
            try {
                Write-Host "Downloading script to temporary file..." -ForegroundColor Gray
                Invoke-WebRequest -Uri "https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/setup.ps1" -OutFile $tempScript -UseBasicParsing
                
                if (Test-Path $tempScript) {
                    Write-Success "Script downloaded successfully"
                    $processArgs = "-NoExit -ExecutionPolicy Bypass -File `"$tempScript`" $argumentString"
                } else {
                    throw "Failed to download script to temporary file"
                }
            } catch {
                # Final fallback - direct execution
                Write-Warning "Download to temp file failed, using direct execution..."
                $downloadCommand = "iwr 'https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/setup.ps1' -UseBasicParsing | iex"
                $processArgs = "-NoExit -ExecutionPolicy Bypass -Command `"$downloadCommand`""
            }
        }
        
        Write-Host "Starting new PowerShell window as Administrator..." -ForegroundColor Gray
        if (![string]::IsNullOrEmpty($argumentString)) {
            Write-Host "Arguments: $argumentString" -ForegroundColor Gray
        }
        
        # Start new PowerShell as Administrator
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "powershell.exe"
        $processInfo.Arguments = $processArgs
        $processInfo.Verb = "runas"
        $processInfo.UseShellExecute = $true
        $processInfo.WorkingDirectory = (Get-Location).Path
        
        $process = [System.Diagnostics.Process]::Start($processInfo)
        
        if ($process) {
            Write-Success "New PowerShell window started as Administrator"
            Write-Info "You can close this window now"
            Write-Host ""
            Write-Host "If the new window didn't open:" -ForegroundColor Yellow
            Write-Host "1. Click 'Yes' on the UAC prompt" -ForegroundColor White
            Write-Host "2. Or manually run PowerShell as Administrator and paste:" -ForegroundColor White
            Write-Host "   iwr 'https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/setup.ps1' -UseBasicParsing | iex" -ForegroundColor Gray
            Write-Host ""
        } else {
            throw "Failed to start new process"
        }
        
    } catch {
        Write-Error "Failed to restart as Administrator: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "MANUAL STEPS:" -ForegroundColor Yellow
        Write-Host "1. Right-click on PowerShell icon" -ForegroundColor White
        Write-Host "2. Select 'Run as Administrator'" -ForegroundColor White
        Write-Host "3. Copy and paste this command:" -ForegroundColor White
        Write-Host "   iwr 'https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/setup.ps1' -UseBasicParsing | iex" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Or if you have the script file saved locally:" -ForegroundColor White
        Write-Host "   .\setup-enhanced-fixed.ps1" -ForegroundColor Gray
        Write-Host ""
    }
    
    Read-Host "Press Enter to exit this window"
    exit 0
}

function Update-SessionPath {
    try {
        # Refresh environment variables from registry
        $machinePath = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $userPath = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        
        $machinePath = [System.Environment]::ExpandEnvironmentVariables($machinePath)
        $userPath = [System.Environment]::ExpandEnvironmentVariables($userPath)
        
        $env:PATH = $machinePath + ";" + $userPath
        
        # Add common installation paths
        $commonPaths = @(
            "${env:ProgramFiles}\nodejs",
            "${env:ProgramFiles(x86)}\nodejs",
            "$env:APPDATA\npm",
            "${env:ProgramFiles}\Git\cmd",
            "${env:ProgramFiles(x86)}\Git\cmd",
            "$env:LOCALAPPDATA\Programs\Git\cmd"
        )
        
        foreach ($path in $commonPaths) {
            if ((Test-Path $path) -and ($env:PATH -notlike "*$path*")) { 
                $env:PATH += ";$path" 
            }
        }
        
        Write-Info "Environment PATH updated"
    } catch {
        Write-Warning "Failed to update PATH: $($_.Exception.Message)"
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

function Install-Chocolatey {
    Write-Info "Installing Chocolatey package manager..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh PATH to include chocolatey
        $env:PATH += ";$env:ALLUSERSPROFILE\chocolatey\bin"
        
        # Wait a moment for installation to complete
        Start-Sleep -Seconds 3
        
        if (Test-Command "choco") {
            Write-Success "Chocolatey installed successfully"
            return $true
        }
    } catch {
        Write-Error "Chocolatey installation failed: $($_.Exception.Message)"
    }
    return $false
}

function Install-NodeJS {
    param([bool]$UseChoco = $false)
    
    Write-Info "Installing Node.js..."
    
    if ($UseChoco -and (Test-Command "choco")) {
        try {
            Write-Host "Using Chocolatey to install Node.js..." -ForegroundColor Gray
            $process = Start-Process -FilePath "choco" -ArgumentList "install", "nodejs", "-y" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Update-SessionPath
                Start-Sleep -Seconds 5
                if (Test-Command "node") {
                    Write-Success "Node.js installed via Chocolatey"
                    return $true
                }
            }
        } catch {
            Write-Warning "Chocolatey installation failed, trying direct download..."
        }
    }
    
    # Fallback to direct download
    try {
        Write-Host "Downloading Node.js installer..." -ForegroundColor Gray
        $nodeUrl = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
        $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
        
        # Download with progress
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
        
        Write-Host "Installing Node.js..." -ForegroundColor Gray
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Start-Sleep -Seconds 10
            Update-SessionPath
            
            # Try multiple times to detect Node.js
            for ($i = 1; $i -le 5; $i++) {
                if (Test-Command "node") {
                    Write-Success "Node.js installed successfully"
                    Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
                    return $true
                }
                Write-Host "Attempt $i/5: Waiting for Node.js to be available..." -ForegroundColor Gray
                Start-Sleep -Seconds 3
                Update-SessionPath
            }
        }
        
        Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Error "Node.js installation failed: $($_.Exception.Message)"
        Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
    }
    
    return $false
}

function Install-Git {
    param([bool]$UseChoco = $false)
    
    Write-Info "Installing Git..."
    
    if ($UseChoco -and (Test-Command "choco")) {
        try {
            Write-Host "Using Chocolatey to install Git..." -ForegroundColor Gray
            $process = Start-Process -FilePath "choco" -ArgumentList "install", "git", "-y" -Wait -PassThru -NoNewWindow
            if ($process.ExitCode -eq 0) {
                Update-SessionPath
                Start-Sleep -Seconds 5
                if (Test-Command "git") {
                    Write-Success "Git installed via Chocolatey"
                    return $true
                }
            }
        } catch {
            Write-Warning "Chocolatey installation failed, trying direct download..."
        }
    }
    
    # Fallback to direct download
    try {
        Write-Host "Downloading Git installer..." -ForegroundColor Gray
        $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
        $gitInstaller = "$env:TEMP\git-installer.exe"
        
        # Download with progress
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        
        Write-Host "Installing Git..." -ForegroundColor Gray
        $process = Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Start-Sleep -Seconds 10
            Update-SessionPath
            
            # Try multiple times to detect Git
            for ($i = 1; $i -le 5; $i++) {
                if (Test-Command "git") {
                    Write-Success "Git installed successfully"
                    Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
                    return $true
                }
                Write-Host "Attempt $i/5: Waiting for Git to be available..." -ForegroundColor Gray
                Start-Sleep -Seconds 3
                Update-SessionPath
            }
        }
        
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Error "Git installation failed: $($_.Exception.Message)"
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
    }
    
    return $false
}

# Main execution starts here
Write-Banner

try {
    # Enhanced Administrator check with better restart handling
    if (!(Test-Administrator)) {
        $adminChoice = Get-AdminChoice
        
        switch ($adminChoice) {
            "EXIT" {
                Write-Info "Setup cancelled by user"
                exit 0
            }
            "CONTINUE" {
                Write-Warning "Continuing without Administrator privileges"
                Write-Info "Some installations may fail or require manual intervention"
            }
            "ADMIN" {
                Start-AdminPowerShell
                # This function will exit the script
            }
        }
    } else {
        Write-Success "Running with Administrator privileges"
    }

    # Check if Chocolatey should be used
    $useChocolatey = $UseChocolatey
    if (!$useChocolatey -and !(Test-Command "choco")) {
        $installChoco = Get-UserChoice "Install Chocolatey for easier package management" "Y"
        if ($installChoco -eq "Y") {
            if (Install-Chocolatey) {
                $useChocolatey = $true
            }
        }
    } elseif (Test-Command "choco") {
        $useChocolatey = $true
        Write-Success "Chocolatey is already available"
    }

    # Check Node.js
    $nodeInstalled = $false
    if (!$SkipNodeInstall) {
        Write-Step "Node.js Installation"
        Update-SessionPath
        
        if (Test-Command "node") {
            $version = node --version
            Write-Success "Node.js is already installed: $version"
            $nodeInstalled = $true
        } else {
            $nodeInstalled = Install-NodeJS -UseChoco $useChocolatey
        }
        
        if (!$nodeInstalled) {
            Write-Error "Node.js installation failed"
            Write-Info "Please install Node.js manually from https://nodejs.org/"
            $continue = Get-UserChoice "Continue without Node.js" "N"
            if ($continue -eq "N") {
                exit 1
            }
        }
    } else {
        $nodeInstalled = Test-Command "node"
    }

    # Check Git
    $gitInstalled = $false
    if (!$SkipGitInstall) {
        Write-Step "Git Installation"
        Update-SessionPath
        
        if (Test-Command "git") {
            $version = git --version
            Write-Success "Git is already installed: $version"
            $gitInstalled = $true
        } else {
            $gitInstalled = Install-Git -UseChoco $useChocolatey
        }
        
        if (!$gitInstalled) {
            Write-Warning "Git installation failed"
            Write-Info "Please install Git manually from https://git-scm.com/"
            $continue = Get-UserChoice "Continue without Git" "Y"
            if ($continue -eq "N") {
                exit 1
            }
        }
    } else {
        $gitInstalled = Test-Command "git"
    }

    # Check pnpm
    Write-Step "pnpm Package Manager Installation"
    Update-SessionPath
    
    $pnpmInstalled = $false
    if (Test-Command "pnpm") {
        $version = pnpm --version
        Write-Success "pnpm is already installed: $version"
        $pnpmInstalled = $true
    } else {
        if ($useChocolatey -and (Test-Command "choco")) {
            try {
                Write-Info "Installing pnpm via Chocolatey..."
                $process = Start-Process -FilePath "choco" -ArgumentList "install", "pnpm", "-y" -Wait -PassThru -NoNewWindow
                if ($process.ExitCode -eq 0) {
                    Update-SessionPath
                    Start-Sleep -Seconds 3
                    if (Test-Command "pnpm") {
                        Write-Success "pnpm installed via Chocolatey"
                        $pnpmInstalled = $true
                    }
                }
            } catch {
                Write-Warning "Chocolatey pnpm installation failed, trying npm..."
            }
        }
        
        if (!$pnpmInstalled -and (Test-Command "npm")) {
            Write-Info "Installing pnpm via npm..."
            try {
                $npmProcess = Start-Process -FilePath "npm" -ArgumentList "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
                if ($npmProcess.ExitCode -eq 0) {
                    Update-SessionPath
                    Start-Sleep -Seconds 3
                    if (Test-Command "pnpm") {
                        $version = pnpm --version
                        Write-Success "pnpm installed successfully: $version"
                        $pnpmInstalled = $true
                    }
                }
            } catch {
                Write-Error "pnpm installation failed: $($_.Exception.Message)"
            }
        }
    }
    
    if (!$pnpmInstalled) {
        Write-Error "pnpm is required but could not be installed"
        Write-Info "Please install pnpm manually: npm install -g pnpm"
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
    if ($nodeInstalled) { Write-Success "Node.js - Ready" } else { Write-Warning "Node.js - Not Available" }
    if ($gitInstalled) { Write-Success "Git - Ready" } else { Write-Warning "Git - Not Available" }
    if ($pnpmInstalled) { Write-Success "pnpm - Ready" } else { Write-Error "pnpm - Failed" }
    if ($useChocolatey) { Write-Success "Chocolatey - Available" }
    Write-Info "Vencord Path: $VencordPath"
    Write-Host ""

    # Continue with Vencord installation
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
            if (!$gitInstalled) {
                Write-Error "Git is required to clone Vencord repository"
                Read-Host "Press Enter to exit"
                exit 1
            }
            
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
            
            $gitProcess = Start-Process -FilePath "git" -ArgumentList "clone", "https://github.com/Vendicated/Vencord.git", $targetDirName -Wait -PassThru -NoNewWindow
            Set-Location $currentLocation
            
            if ($gitProcess.ExitCode -eq 0 -and (Test-Path "$VencordPath\package.json")) {
                Write-Success "Vencord cloned successfully"
                $vencordDir = $VencordPath
            } else {
                throw "Git clone failed or package.json not found"
            }
        }
    } catch {
        Write-Error "Vencord setup failed: $($_.Exception.Message)"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Install dependencies
    Write-Step "Installing Dependencies"
    try {
        $currentLocation = Get-Location
        Set-Location $vencordDir
        Write-Info "Running pnpm install..."
        
        $pnpmProcess = Start-Process -FilePath "pnpm" -ArgumentList "install" -Wait -PassThru -NoNewWindow
        Set-Location $currentLocation
        
        if ($pnpmProcess.ExitCode -eq 0) {
            Write-Success "Dependencies installed"
        } else {
            throw "pnpm install failed with exit code $($pnpmProcess.ExitCode)"
        }
    } catch {
        Write-Error "Dependencies installation failed: $($_.Exception.Message)"
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
        
        $gitProcess = Start-Process -FilePath "git" -ArgumentList "clone", "https://github.com/tsx-awtns/MultiMessageCopy.git", "temp-plugin" -Wait -PassThru -NoNewWindow
        
        if ($gitProcess.ExitCode -eq 0 -and (Test-Path "temp-plugin\MultiMessageCopyFiles")) {
            Move-Item "temp-plugin\MultiMessageCopyFiles" "MultiMessageCopy"
            Remove-Item "temp-plugin" -Recurse -Force
            Write-Success "Plugin installed successfully"
        } else {
            throw "Plugin download failed or files not found"
        }
        Set-Location $currentLocation
    } catch {
        Write-Error "Plugin installation failed: $($_.Exception.Message)"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Build Vencord
    Write-Step "Building Vencord"
    try {
        $currentLocation = Get-Location
        Set-Location $vencordDir
        Write-Info "Building..."
        
        $buildProcess = Start-Process -FilePath "pnpm" -ArgumentList "build" -Wait -PassThru -NoNewWindow
        Set-Location $currentLocation
        
        if ($buildProcess.ExitCode -eq 0) {
            Write-Success "Build completed"
        } else {
            throw "Build failed with exit code $($buildProcess.ExitCode)"
        }
    } catch {
        Write-Error "Build failed: $($_.Exception.Message)"
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
            
            $injectProcess = Start-Process -FilePath "pnpm" -ArgumentList "inject" -Wait -PassThru -NoNewWindow
            Set-Location $currentLocation
            
            if ($injectProcess.ExitCode -eq 0) {
                Write-Success "Injection completed"
            } else {
                Write-Warning "Injection failed - you can run 'pnpm inject' manually later"
            }
        } catch {
            Write-Warning "Injection failed - you can run 'pnpm inject' manually later"
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
    Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
    Write-Host "- If Discord doesn't start, run: pnpm uninject" -ForegroundColor White
    Write-Host "- To reinstall: pnpm inject" -ForegroundColor White
    Write-Host "- Manual build: pnpm build" -ForegroundColor White
    Write-Host ""
    Write-Host "Repository: https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor Blue
    Write-Host ""

    Read-Host "Press Enter to exit"

} catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "TROUBLESHOOTING TIPS:" -ForegroundColor Yellow
    Write-Host "1. Run PowerShell as Administrator" -ForegroundColor White
    Write-Host "2. Check your internet connection" -ForegroundColor White
    Write-Host "3. Temporarily disable antivirus" -ForegroundColor White
    Write-Host "4. Try using -UseChocolatey parameter" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
