# PowerShell 

# MultiMessageCopy Setup Script v1.1 (Windows)
# Author: tsx-awtns

param(
    [switch]$SkipNodeInstall,
    [switch]$SkipGitInstall,
    [string]$VencordPath = "",
    [switch]$Help
)

function Write-Success { param($Message) Write-Host $Message -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host $Message -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host $Message -ForegroundColor Red }
function Write-Info { param($Message) Write-Host $Message -ForegroundColor Cyan }
function Write-Step { param($Message) Write-Host "`n=== $Message ===" -ForegroundColor Magenta }

function Show-Help {
    Write-Host @"
MultiMessageCopy Plugin Automated Setup Script v1.1

USAGE:
    .\setup.ps1 [OPTIONS]

OPTIONS:
    -SkipNodeInstall    Skip Node.js installation check
    -SkipGitInstall     Skip Git installation check  
    -VencordPath        Specify custom Vencord installation path
    -Help               Show this help message

EXAMPLES:
    .\setup.ps1
    .\setup.ps1 -SkipNodeInstall -SkipGitInstall
    .\setup.ps1 -VencordPath "C:\MyVencord"

"@ -ForegroundColor White
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
    try { Get-Command $Command -ErrorAction Stop | Out-Null; return $true }
    catch { return $false }
}

function Refresh-EnvironmentPath {
    Write-Info "Refreshing environment PATH..."
    try {
        # Get system and user PATH variables
        $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        # Combine them
        $newPath = $machinePath + ";" + $userPath
        
        # Update current session PATH
        $env:Path = $newPath
        
        Write-Info "Environment PATH refreshed successfully"
        return $true
    }
    catch {
        Write-Warning "Failed to refresh PATH: $($_.Exception.Message)"
        return $false
    }
}

function Test-ValidPath {
    param($Path)
    try {
        if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
        $Path = $Path.Trim('"').Trim("'").Trim()
        if ($Path.Length -eq 0) { return $false }
        $invalidChars = [System.IO.Path]::GetInvalidPathChars()
        foreach ($char in $invalidChars) {
            if ($Path.Contains($char)) { return $false }
        }
        return $true
    }
    catch {
        return $false
    }
}

function Find-VencordDirectory {
    param($BasePath)
    
    Write-Info "Searching for Vencord files in: $BasePath"
    
    if (Test-Path "$BasePath\package.json") {
        $packageContent = Get-Content "$BasePath\package.json" -Raw | ConvertFrom-Json
        if ($packageContent.name -eq "vencord") {
            Write-Success "Found Vencord in: $BasePath"
            return $BasePath
        }
    }
    
    $possiblePaths = @(
        "$BasePath\Vencord",
        "$BasePath\vencord",
        "$BasePath\Vencord-main",
        "$BasePath\vencord-main"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path "$path\package.json") {
            try {
                $packageContent = Get-Content "$path\package.json" -Raw | ConvertFrom-Json
                if ($packageContent.name -eq "vencord") {
                    Write-Success "Found Vencord in: $path"
                    return $path
                }
            }
            catch {
                continue
            }
        }
    }
    
    try {
        $foundPaths = Get-ChildItem -Path $BasePath -Recurse -Depth 2 -Name "package.json" -ErrorAction SilentlyContinue
        foreach ($packagePath in $foundPaths) {
            $fullPath = Join-Path $BasePath $packagePath
            $dirPath = Split-Path $fullPath -Parent
            try {
                $packageContent = Get-Content $fullPath -Raw | ConvertFrom-Json
                if ($packageContent.name -eq "vencord") {
                    Write-Success "Found Vencord in: $dirPath"
                    return $dirPath
                }
            }
            catch {
                continue
            }
        }
    }
    catch {
        Write-Warning "Could not search recursively in $BasePath"
    }
    
    return $null
}

function Install-NodeJS {
    Write-Step "Installing Node.js"
    
    if (Test-Command "node") {
        Write-Success "Node.js is already installed: $(node --version)"
        return $true
    }
    
    $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
    $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
    
    try {
        Write-Info "Downloading Node.js installer..."
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
        
        Write-Info "Installing Node.js (this may take a few minutes)..."
        $installProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $nodeInstaller, "/quiet", "/norestart" -Wait -PassThru
        
        if ($installProcess.ExitCode -ne 0) {
            throw "Node.js installation failed with exit code: $($installProcess.ExitCode)"
        }
        
        # Refresh PATH after installation
        Refresh-EnvironmentPath
        
        # Wait a moment for the installation to complete
        Start-Sleep -Seconds 3
        
        # Test if node is now available
        if (Test-Command "node") {
            Write-Success "Node.js installed successfully: $(node --version)"
            return $true
        } else {
            Write-Warning "Node.js installed but command not found. Trying manual PATH refresh..."
            
            # Try adding common Node.js paths manually
            $commonNodePaths = @(
                "${env:ProgramFiles}\nodejs",
                "${env:ProgramFiles(x86)}\nodejs",
                "$env:APPDATA\npm"
            )
            
            foreach ($nodePath in $commonNodePaths) {
                if (Test-Path $nodePath) {
                    $env:Path += ";$nodePath"
                    Write-Info "Added to PATH: $nodePath"
                }
            }
            
            if (Test-Command "node") {
                Write-Success "Node.js is now available: $(node --version)"
                return $true
            } else {
                Write-Error "Node.js installation completed but command still not available."
                Write-Info "Please restart PowerShell and run the script again, or install Node.js manually from https://nodejs.org/"
                return $false
            }
        }
        
        Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Failed to install Node.js: $($_.Exception.Message)"
        Write-Info "Please install Node.js manually from https://nodejs.org/"
        Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Install-Git {
    Write-Step "Installing Git"
    
    if (Test-Command "git") {
        Write-Success "Git is already installed: $(git --version)"
        return $true
    }
    
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
    $gitInstaller = "$env:TEMP\git-installer.exe"
    
    try {
        Write-Info "Downloading and installing Git..."
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
        
        Refresh-EnvironmentPath
        
        if (Test-Command "git") {
            Write-Success "Git installed successfully!"
            return $true
        } else {
            Write-Warning "Git installed, but 'git' command not found. Restart terminal may be required."
            return $false
        }
        
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Failed to install Git: $($_.Exception.Message)"
        Write-Info "Install manually from https://git-scm.com/"
        return $false
    }
}

function Install-Pnpm {
    Write-Step "Installing pnpm"
    
    if (Test-Command "pnpm") {
        Write-Success "pnpm is already installed: $(pnpm --version)"
        return $true
    }
    
    if (!(Test-Command "npm")) {
        Write-Error "npm is not available. Node.js installation may have failed."
        Write-Info "Please restart PowerShell and try again, or install Node.js manually."
        return $false
    }
    
    try {
        Write-Info "Installing pnpm globally..."
        $pnpmProcess = Start-Process -FilePath "npm" -ArgumentList "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
        
        if ($pnpmProcess.ExitCode -eq 0) {
            Refresh-EnvironmentPath
            
            if (Test-Command "pnpm") {
                Write-Success "pnpm installed successfully: $(pnpm --version)"
                return $true
            } else {
                Write-Warning "pnpm installed but command not found. Adding npm global path..."
                $npmGlobalPath = npm config get prefix 2>$null
                if ($npmGlobalPath) {
                    $env:Path += ";$npmGlobalPath"
                    if (Test-Command "pnpm") {
                        Write-Success "pnpm is now available: $(pnpm --version)"
                        return $true
                    }
                }
                Write-Error "pnpm installation completed but command not available."
                return $false
            }
        } else {
            throw "pnpm installation failed with exit code: $($pnpmProcess.ExitCode)"
        }
    }
    catch {
        Write-Error "Failed to install pnpm: $($_.Exception.Message)"
        Write-Info "You can install pnpm manually with: npm install -g pnpm"
        return $false
    }
}

function Get-VencordPath {
    $defaultPath = Join-Path $env:USERPROFILE "Desktop\Vencord"
    
    while ($true) {
        try {
            Write-Info "Enter the path where Vencord is located (or should be installed):"
            Write-Info "This should be the directory containing package.json or where you want to clone Vencord"
            Write-Info "Default: $defaultPath"
            Write-Info "Press ENTER for default, or type custom path:"
            
            $userInput = Read-Host "Path"
            
            if ([string]::IsNullOrWhiteSpace($userInput)) {
                Write-Info "Using default path: $defaultPath"
                return $defaultPath
            }
            
            $userInput = $userInput.Trim('"').Trim("'").Trim()
            
            if (Test-ValidPath $userInput) {
                Write-Info "Using custom path: $userInput"
                return $userInput
            } else {
                Write-Warning "Invalid path format. Please try again."
                Write-Info "Example: C:\MyFolder\Vencord"
                continue
            }
        }
        catch {
            Write-Warning "Error reading path. Using default: $defaultPath"
            return $defaultPath
        }
    }
}

function Install-Vencord {
    param($InstallPath)
    
    Write-Step "Setting up Vencord"
    
    try {
        $vencordDir = Find-VencordDirectory -BasePath $InstallPath
        
        if ($vencordDir) {
            Write-Success "Found existing Vencord installation at: $vencordDir"
            return $vencordDir
        }
        
        Write-Info "Vencord not found. Cloning Vencord repository..."
        
        $parentDir = Split-Path $InstallPath -Parent
        if (!(Test-Path $parentDir)) {
            Write-Info "Creating directory: $parentDir"
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        $currentLocation = Get-Location
        Set-Location $parentDir
        
        $targetDirName = Split-Path $InstallPath -Leaf
        if (Test-Path $InstallPath) {
            Write-Warning "Directory $InstallPath already exists. Removing..."
            Remove-Item $InstallPath -Recurse -Force
        }
        
        git clone https://github.com/Vendicated/Vencord.git $targetDirName
        Set-Location $currentLocation
        
        if (Test-Path "$InstallPath\package.json") {
            $packageContent = Get-Content "$InstallPath\package.json" -Raw | ConvertFrom-Json
            if ($packageContent.name -eq "vencord") {
                Write-Success "Vencord cloned successfully to: $InstallPath"
                return $InstallPath
            }
        }
        
        throw "Vencord clone verification failed - package.json not found or invalid"
    }
    catch {
        Write-Error "Failed to setup Vencord: $($_.Exception.Message)"
        return $null
    }
}

function Install-VencordDependencies {
    param($VencordPath)
    
    Write-Step "Installing Vencord dependencies"
    
    try {
        $currentLocation = Get-Location
        Set-Location $VencordPath
        Write-Info "Installing dependencies with pnpm..."
        pnpm install
        Set-Location $currentLocation
        Write-Success "Vencord dependencies installed successfully!"
        return $true
    }
    catch {
        Write-Error "Failed to install Vencord dependencies: $($_.Exception.Message)"
        return $false
    }
}

function Install-MultiMessageCopy {
    param($VencordPath)
    
    Write-Step "Installing MultiMessageCopy Plugin v1.1"
    
    try {
        $userPluginsPath = Join-Path $VencordPath "src\userplugins"
        $multiMessageCopyPath = Join-Path $userPluginsPath "MultiMessageCopy"
        
        if (Test-Path "$multiMessageCopyPath\index.tsx") {
            Write-Success "MultiMessageCopy plugin already exists!"
            return $true
        }
        
        if (!(Test-Path $userPluginsPath)) {
            New-Item -ItemType Directory -Path $userPluginsPath -Force | Out-Null
            Write-Info "Created userplugins directory"
        }
        
        Write-Info "Cloning MultiMessageCopy plugin repository..."
        $currentLocation = Get-Location
        Set-Location $userPluginsPath
        
        if (Test-Path $multiMessageCopyPath) {
            Write-Info "Removing existing MultiMessageCopy directory..."
            Remove-Item $multiMessageCopyPath -Recurse -Force
        }
        
        git clone https://github.com/tsx-awtns/MultiMessageCopy.git temp-multimessagecopy
        
        if (Test-Path "temp-multimessagecopy\MultiMessageCopyFiles") {
            Copy-Item "temp-multimessagecopy\MultiMessageCopyFiles" -Destination "MultiMessageCopy" -Recurse -Force
            Remove-Item "temp-multimessagecopy" -Recurse -Force
        } else {
            throw "MultiMessageCopyFiles subfolder not found in repository"
        }
        
        Set-Location $currentLocation
        
        if (Test-Path "$multiMessageCopyPath\index.tsx") {
            Write-Success "MultiMessageCopy plugin v1.1 cloned successfully!"
            return $true
        } else {
            throw "MultiMessageCopy plugin files not found after cloning"
        }
    }
    catch {
        Write-Error "Failed to clone MultiMessageCopy plugin: $($_.Exception.Message)"
        Write-Info "Manual clone: https://github.com/tsx-awtns/MultiMessageCopy.git (files are in MultiMessageCopyFiles/ subfolder)"
        return $false
    }
}

function Build-Vencord {
    param($VencordPath)
    
    Write-Step "Building Vencord with MultiMessageCopy v1.1"
    
    try {
        $currentLocation = Get-Location
        Set-Location $VencordPath
        Write-Info "Building Vencord with MultiMessageCopy plugin..."
        pnpm build
        Set-Location $currentLocation
        Write-Success "Vencord built successfully!"
        return $true
    }
    catch {
        Write-Error "Failed to build Vencord: $($_.Exception.Message)"
        return $false
    }
}

function Inject-Vencord {
    param($VencordPath)
    
    Write-Step "Injecting Vencord into Discord"
    
    try {
        $currentLocation = Get-Location
        Set-Location $VencordPath
        Write-Info "Injecting Vencord into Discord..."
        Write-Warning "Press ENTER for default Discord path, or enter custom path."
        pnpm inject
        Set-Location $currentLocation
        Write-Success "Vencord injection completed!"
        return $true
    }
    catch {
        Write-Error "Failed to inject Vencord: $($_.Exception.Message)"
        Write-Info "Run 'pnpm inject' manually in the Vencord directory later."
        return $false
    }
}

function Main {
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                MultiMessageCopy Setup Script                ║
║                        Version 1.1                          ║
║                     by tsx-awtns                             ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    $setupFailed = $false

    try {
        if (!(Test-Administrator)) {
            Write-Warning "Not running as Administrator. Some installations might fail."
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne "y" -and $continue -ne "Y") { 
                Write-Info "Exiting..."
                Read-Host "Press Enter to exit"
                exit 0 
            }
        }

        # Install Node.js
        if (!$SkipNodeInstall) { 
            if (!(Install-NodeJS)) {
                Write-Error "Node.js installation failed. Cannot continue."
                Read-Host "Press Enter to exit"
                exit 1
            }
        }
        
        # Install Git
        if (!$SkipGitInstall) { 
            if (!(Install-Git)) {
                Write-Warning "Git installation failed, but continuing..."
            }
        }
        
        # Install pnpm
        if (!(Install-Pnpm)) {
            Write-Error "pnpm installation failed. Cannot continue."
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Get Vencord path
        if ([string]::IsNullOrEmpty($VencordPath)) {
            $VencordPath = Get-VencordPath
        }
        
        # Install Vencord
        $vencordDir = Install-Vencord -InstallPath $VencordPath
        if (!$vencordDir) {
            Write-Error "Vencord setup failed. Cannot continue."
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Install Vencord dependencies
        if (!(Install-VencordDependencies -VencordPath $vencordDir)) {
            Write-Error "Vencord dependencies installation failed. Cannot continue."
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Install MultiMessageCopy plugin
        if (!(Install-MultiMessageCopy -VencordPath $vencordDir)) {
            Write-Error "MultiMessageCopy plugin installation failed. Cannot continue."
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Build Vencord
        if (!(Build-Vencord -VencordPath $vencordDir)) {
            Write-Error "Vencord build failed. Cannot continue."
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        Write-Info "`nVencord and MultiMessageCopy v1.1 are ready!"
        $inject = Read-Host "Inject Vencord into Discord now? (Y/n)"
        if ($inject -ne "n" -and $inject -ne "N") {
            Inject-Vencord -VencordPath $vencordDir
        }
        
        Write-Step "Setup Complete!"
        Write-Success @"
✅ MultiMessageCopy v1.1 plugin installed successfully!

NEXT STEPS:
1. Restart Discord
2. Settings > Vencord > Plugins > Enable 'MultiMessageCopy'
3. Use the plugin features in Discord

REPOSITORY: https://github.com/tsx-awtns/MultiMessageCopy

SUPPORT: Check the repository for issues and documentation
"@

        Write-Info "`nInstallation: $vencordDir"
        if ($inject -eq "n" -or $inject -eq "N") {
            Write-Warning "Run 'pnpm inject' in Vencord directory to inject into Discord!"
        }
        
        Write-Info "`nSetup completed successfully!"
        Read-Host "Press Enter to exit"
    }
    catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        Write-Info "Try manual installation or check README.md"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

try {
    Main
}
catch {
    Write-Error "Critical error: $($_.Exception.Message)"
    Read-Host "Press Enter to exit"
    exit 1
}
finally {
    try {
        if ($PWD.Path -ne $PSScriptRoot -and $PSScriptRoot) { 
            Set-Location $PSScriptRoot 
        }
    }
    catch {
    }
}
