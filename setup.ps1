# PowerShell Setup Script with UTF-8 encoding fix
# MultiMessageCopy Setup Script v1.5 (Windows)
# Author: tsx-awtns

# Set console to UTF-8 encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Set PowerShell to use UTF-8
if ($PSVersionTable.PSVersion.Major -ge 6) {
    $PSDefaultParameterValues['*:Encoding'] = 'utf8'
} else {
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
}

param(
    [switch]$SkipNodeInstall,
    [switch]$SkipGitInstall,
    [string]$VencordPath = "",
    [switch]$Help
)

# Safe UI Functions - only ASCII characters
function Write-Success { 
    param($Message) 
    Write-Host "[OK] $Message" -ForegroundColor Green 
}

function Write-Warning { 
    param($Message) 
    Write-Host "[!] $Message" -ForegroundColor Yellow 
}

function Write-Error { 
    param($Message) 
    Write-Host "[X] $Message" -ForegroundColor Red 
}

function Write-Info { 
    param($Message) 
    Write-Host "[i] $Message" -ForegroundColor Cyan 
}

function Write-Step { 
    param($Message) 
    Write-Host ""
    Write-Host ">> $Message" -ForegroundColor Magenta -BackgroundColor Black
    Write-Host ("=" * 70) -ForegroundColor DarkGray
}

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
    Write-Host "    |                MultiMessageCopy Setup Script v1.5                  |" -ForegroundColor White
    Write-Host "    |                            by tsx-awtns                            |" -ForegroundColor Gray
    Write-Host "    +----------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Help {
    Write-Banner
    Write-Host "USAGE GUIDE" -ForegroundColor Yellow
    Write-Host ("-" * 50) -ForegroundColor Gray
    Write-Host ""
    Write-Host "COMMAND:" -ForegroundColor White
    Write-Host "    .\setup.ps1 [OPTIONS]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor White
    Write-Host "    -SkipNodeInstall    Skip Node.js installation check" -ForegroundColor Gray
    Write-Host "    -SkipGitInstall     Skip Git installation check" -ForegroundColor Gray
    Write-Host "    -VencordPath        Specify custom Vencord installation path" -ForegroundColor Gray
    Write-Host "    -Help               Show this help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor White
    Write-Host "    .\setup.ps1                                    # Full automatic setup" -ForegroundColor Gray
    Write-Host "    .\setup.ps1 -SkipNodeInstall -SkipGitInstall   # Skip dependency installs" -ForegroundColor Gray
    Write-Host "    .\setup.ps1 -VencordPath `"C:\MyVencord`"        # Custom Vencord path" -ForegroundColor Gray
    Write-Host ""
}

function Get-UserChoice {
    param(
        [string]$Prompt,
        [string]$DefaultChoice = "Y",
        [string[]]$ValidChoices = @("Y", "N")
    )
    
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
            if ($i -lt $ValidChoices.Length - 1) {
                Write-Host "/" -NoNewline -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        Write-Host "Your choice (press Enter for default): " -NoNewline -ForegroundColor Cyan
        
        $choice = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($choice)) {
            $choice = $DefaultChoice
        }
        
        $choice = $choice.ToUpper()
        
        if ($ValidChoices -contains $choice) {
            return $choice
        } else {
            Write-Warning "Invalid choice. Please select from the available options."
        }
    } while ($true)
}

function Get-UserPath {
    param(
        [string]$Prompt,
        [string]$DefaultPath,
        [string]$Example = ""
    )
    
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

function Show-InstallationSummary {
    param(
        [bool]$NodeInstalled,
        [bool]$GitInstalled,
        [bool]$PnpmInstalled,
        [string]$VencordPath
    )
    
    Write-Host ""
    Write-Host "INSTALLATION SUMMARY" -ForegroundColor Magenta -BackgroundColor Black
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    
    if ($NodeInstalled) { Write-Success "Node.js - Ready" } else { Write-Error "Node.js - Failed" }
    if ($GitInstalled) { Write-Success "Git - Ready" } else { Write-Warning "Git - Skipped or Failed" }
    if ($PnpmInstalled) { Write-Success "pnpm - Ready" } else { Write-Error "pnpm - Failed" }
    Write-Info "Vencord Path: $VencordPath"
    
    Write-Host ""
}

if ($Help) { Show-Help; exit 0 }

function Test-Administrator {
    try {
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Test-Command {
    param($Command)
    try { 
        $null = Get-Command $Command -ErrorAction Stop
        return $true 
    }
    catch { 
        return $false 
    }
}

function Update-SessionPath {
    Write-Host "Refreshing environment variables..." -ForegroundColor Gray
    
    try {
        # Get PATH from registry
        $machinePath = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $userPath = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        
        # Expand environment variables
        $machinePath = [System.Environment]::ExpandEnvironmentVariables($machinePath)
        $userPath = [System.Environment]::ExpandEnvironmentVariables($userPath)
        
        # Update current session PATH
        $env:PATH = $machinePath + ";" + $userPath
        
        # Add common Node.js paths
        $commonPaths = @(
            "${env:ProgramFiles}\nodejs",
            "${env:ProgramFiles(x86)}\nodejs",
            "$env:APPDATA\npm"
        )
        
        foreach ($path in $commonPaths) {
            if ((Test-Path $path) -and ($env:PATH -notlike "*$path*")) {
                $env:PATH += ";$path"
            }
        }
        
        return $true
    }
    catch {
        return $false
    }
}

function Install-NodeJS {
    Write-Step "Node.js Installation"
    
    Update-SessionPath
    
    if (Test-Command "node") {
        $version = node --version
        Write-Success "Node.js is already installed: $version"
        return $true
    }
    
    Write-Info "Node.js not detected. Starting installation..."
    
    # Try Chocolatey first
    if (Test-Command "choco") {
        Write-Info "Using Chocolatey package manager for installation"
        
        try {
            Start-Process -FilePath "choco" -ArgumentList "install", "nodejs", "-y" -Wait -NoNewWindow
            Update-SessionPath
            
            if (Test-Command "node") {
                $version = node --version
                Write-Success "Node.js installed successfully via Chocolatey: $version"
                return $true
            }
        }
        catch {
            Write-Warning "Chocolatey installation failed. Trying direct download..."
        }
    }
    
    # Direct MSI installation
    Write-Info "Downloading Node.js installer from official website"
    $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
    $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
    
    try {
        Write-Host "Downloading installer..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
        
        Write-Host "Running installer (this may take a few minutes)..." -ForegroundColor Gray
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Installation failed with exit code: $($process.ExitCode)"
        }
        
        Write-Host "Finalizing installation..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        Update-SessionPath
        
        if (Test-Command "node") {
            $version = node --version
            Write-Success "Node.js installed successfully: $version"
            Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Error "Installation completed but Node.js command not found"
            Write-Info "Please restart PowerShell and run the script again"
            Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            return $false
        }
    }
    catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        Write-Info "Please install Node.js manually from https://nodejs.org/"
        Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Install-Git {
    Write-Step "Git Installation"
    
    Update-SessionPath
    
    if (Test-Command "git") {
        $version = git --version
        Write-Success "Git is already installed: $version"
        return $true
    }
    
    Write-Info "Git not detected. Starting installation..."
    
    # Try Chocolatey first
    if (Test-Command "choco") {
        Write-Info "Using Chocolatey package manager for installation"
        
        try {
            Start-Process -FilePath "choco" -ArgumentList "install", "git", "-y" -Wait -NoNewWindow
            Update-SessionPath
            
            if (Test-Command "git") {
                Write-Success "Git installed successfully via Chocolatey"
                return $true
            }
        }
        catch {
            Write-Warning "Chocolatey installation failed. Trying direct download..."
        }
    }
    
    # Direct installer download
    Write-Info "Downloading Git installer from official website"
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
    $gitInstaller = "$env:TEMP\git-installer.exe"
    
    try {
        Write-Host "Downloading installer..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        
        Write-Host "Running installer..." -ForegroundColor Gray
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
        
        Write-Host "Finalizing installation..." -ForegroundColor Gray
        Update-SessionPath
        
        if (Test-Command "git") {
            Write-Success "Git installed successfully"
            Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Warning "Git installed but command not found. May require restart"
            Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            return $false
        }
    }
    catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        Write-Info "Please install Git manually from https://git-scm.com/"
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Install-Pnpm {
    Write-Step "pnpm Package Manager Installation"
    
    Update-SessionPath
    
    if (Test-Command "pnpm") {
        $version = pnpm --version
        Write-Success "pnpm is already installed: $version"
        return $true
    }
    
    if (!(Test-Command "npm")) {
        Write-Error "npm is not available. Node.js installation may have failed"
        Write-Info "Please restart PowerShell and try again"
        return $false
    }
    
    Write-Info "Installing pnpm package manager globally..."
    
    try {
        Write-Host "Installing via npm..." -ForegroundColor Gray
        
        $npmProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
        
        if ($npmProcess.ExitCode -eq 0) {
            Write-Host "Finalizing installation..." -ForegroundColor Gray
            Update-SessionPath
            Start-Sleep -Seconds 2
            
            if (Test-Command "pnpm") {
                $version = pnpm --version
                Write-Success "pnpm installed successfully: $version"
                return $true
            } else {
                # Try to find pnpm in npm global directory
                $npmPrefix = cmd /c "npm config get prefix" 2>$null
                if ($npmPrefix -and (Test-Path "$npmPrefix\pnpm.cmd")) {
                    $env:PATH += ";$npmPrefix"
                    if (Test-Command "pnpm") {
                        $version = pnpm --version
                        Write-Success "pnpm is now available: $version"
                        return $true
                    }
                }
                
                Write-Error "pnpm installation completed but command not available"
                return $false
            }
        } else {
            throw "npm install failed with exit code: $($npmProcess.ExitCode)"
        }
    }
    catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        Write-Info "You can try installing manually with: npm install -g pnpm"
        return $false
    }
}

function Install-Vencord {
    param($InstallPath)
    
    Write-Step "Vencord Setup"
    
    try {
        # Check if Vencord already exists
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
        if (!(Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
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
    }
    catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        return $null
    }
}

function Install-VencordDependencies {
    param($VencordPath)
    
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
    }
    catch {
        Write-Error "Dependencies installation failed: $($_.Exception.Message)"
        return $false
    }
}

function Install-MultiMessageCopy {
    param($VencordPath)
    
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
    }
    catch {
        Write-Error "Plugin installation failed: $($_.Exception.Message)"
        Write-Info "You can clone manually: https://github.com/tsx-awtns/MultiMessageCopy.git"
        return $false
    }
}

function Build-Vencord {
    param($VencordPath)
    
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
    }
    catch {
        Write-Error "Build failed: $($_.Exception.Message)"
        return $false
    }
}

function Inject-Vencord {
    param($VencordPath)
    
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
    }
    catch {
        Write-Error "Injection failed: $($_.Exception.Message)"
        Write-Info "You can run 'pnpm inject' manually in the Vencord directory"
        return $false
    }
}

function Show-CompletionMessage {
    param($VencordPath, $InjectionSkipped)
    
    Write-Host ""
    Write-Host "SETUP COMPLETED SUCCESSFULLY!" -ForegroundColor Green -BackgroundColor Black
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Success "MultiMessageCopy plugin has been installed successfully"
    Write-Info "Installation location: $VencordPath"
    
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "   1. Restart Discord completely" -ForegroundColor White
    Write-Host "   2. Go to Discord Settings > Vencord > Plugins" -ForegroundColor White
    Write-Host "   3. Enable 'MultiMessageCopy' plugin" -ForegroundColor White
    Write-Host "   4. Start using the plugin features in Discord" -ForegroundColor White
    
    if ($InjectionSkipped) {
        Write-Host ""
        Write-
