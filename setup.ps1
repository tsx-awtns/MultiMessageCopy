# PowerShell 

# MultiMessageCopy Setup Script v1.2 (Windows)
# Author: tsx-awtns
# Fixed PATH and installation issues

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
MultiMessageCopy Plugin Automated Setup Script v1.2

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
    try { 
        $null = Get-Command $Command -ErrorAction Stop
        return $true 
    }
    catch { 
        return $false 
    }
}

function Update-SessionPath {
    Write-Info "Updating PowerShell session PATH..."
    try {
        # Get the latest PATH from registry
        $machinePath = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $userPath = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        
        # Expand environment variables
        $machinePath = [System.Environment]::ExpandEnvironmentVariables($machinePath)
        $userPath = [System.Environment]::ExpandEnvironmentVariables($userPath)
        
        # Update current session
        $env:PATH = $machinePath + ";" + $userPath
        
        # Also try common Node.js paths
        $commonPaths = @(
            "${env:ProgramFiles}\nodejs",
            "${env:ProgramFiles(x86)}\nodejs",
            "$env:APPDATA\npm"
        )
        
        foreach ($path in $commonPaths) {
            if ((Test-Path $path) -and ($env:PATH -notlike "*$path*")) {
                $env:PATH += ";$path"
                Write-Info "Added to PATH: $path"
            }
        }
        
        Write-Success "PATH updated successfully"
        return $true
    }
    catch {
        Write-Warning "Failed to update PATH: $($_.Exception.Message)"
        return $false
    }
}

function Install-NodeJS {
    Write-Step "Installing Node.js"
    
    # First check if node is available after PATH update
    Update-SessionPath
    
    if (Test-Command "node") {
        Write-Success "Node.js is already installed: $(node --version)"
        return $true
    }
    
    Write-Info "Node.js not found. Installing..."
    
    # Use Chocolatey if available, otherwise MSI
    if (Test-Command "choco") {
        Write-Info "Installing Node.js via Chocolatey..."
        try {
            Start-Process -FilePath "choco" -ArgumentList "install", "nodejs", "-y" -Wait -NoNewWindow
            Update-SessionPath
            
            if (Test-Command "node") {
                Write-Success "Node.js installed successfully via Chocolatey: $(node --version)"
                return $true
            }
        }
        catch {
            Write-Warning "Chocolatey installation failed, trying MSI..."
        }
    }
    
    # Fallback to MSI installation
    $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
    $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
    
    try {
        Write-Info "Downloading Node.js installer..."
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
        
        Write-Info "Installing Node.js (this may take a few minutes)..."
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "MSI installation failed with exit code: $($process.ExitCode)"
        }
        
        # Wait for installation to complete
        Start-Sleep -Seconds 5
        
        # Update PATH multiple times to ensure it's refreshed
        Update-SessionPath
        Start-Sleep -Seconds 2
        Update-SessionPath
        
        # Test if node is now available
        if (Test-Command "node") {
            Write-Success "Node.js installed successfully: $(node --version)"
            Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Error "Node.js installation completed but command not found."
            Write-Info "Please restart PowerShell and run the script again."
            Write-Info "Or install Node.js manually from https://nodejs.org/"
            Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            return $false
        }
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
    
    Update-SessionPath
    
    if (Test-Command "git") {
        Write-Success "Git is already installed: $(git --version)"
        return $true
    }
    
    # Try Chocolatey first
    if (Test-Command "choco") {
        Write-Info "Installing Git via Chocolatey..."
        try {
            Start-Process -FilePath "choco" -ArgumentList "install", "git", "-y" -Wait -NoNewWindow
            Update-SessionPath
            
            if (Test-Command "git") {
                Write-Success "Git installed successfully via Chocolatey"
                return $true
            }
        }
        catch {
            Write-Warning "Chocolatey installation failed, trying direct download..."
        }
    }
    
    # Fallback to direct download
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
    $gitInstaller = "$env:TEMP\git-installer.exe"
    
    try {
        Write-Info "Downloading and installing Git..."
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
        
        Update-SessionPath
        
        if (Test-Command "git") {
            Write-Success "Git installed successfully!"
            Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Warning "Git installed, but command not found. May require restart."
            Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            return $false
        }
    }
    catch {
        Write-Error "Failed to install Git: $($_.Exception.Message)"
        Write-Info "Install manually from https://git-scm.com/"
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Install-Pnpm {
    Write-Step "Installing pnpm"
    
    Update-SessionPath
    
    if (Test-Command "pnpm") {
        Write-Success "pnpm is already installed: $(pnpm --version)"
        return $true
    }
    
    if (!(Test-Command "npm")) {
        Write-Error "npm is not available. Node.js installation may have failed."
        Write-Info "Please restart PowerShell and try again."
        return $false
    }
    
    try {
        Write-Info "Installing pnpm globally..."
        
        # Use cmd to run npm to avoid PowerShell execution policy issues
        $npmProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
        
        if ($npmProcess.ExitCode -eq 0) {
            Update-SessionPath
            Start-Sleep -Seconds 2
            
            if (Test-Command "pnpm") {
                Write-Success "pnpm installed successfully: $(pnpm --version)"
                return $true
            } else {
                Write-Warning "pnpm installed but command not found. Trying to locate..."
                
                # Try to find pnpm in npm global directory
                $npmPrefix = cmd /c "npm config get prefix" 2>$null
                if ($npmPrefix -and (Test-Path "$npmPrefix\pnpm.cmd")) {
                    $env:PATH += ";$npmPrefix"
                    if (Test-Command "pnpm") {
                        Write-Success "pnpm is now available: $(pnpm --version)"
                        return $true
                    }
                }
                
                Write-Error "pnpm installation completed but command not available."
                return $false
            }
        } else {
            throw "npm install failed with exit code: $($npmProcess.ExitCode)"
        }
    }
    catch {
        Write-Error "Failed to install pnpm: $($_.Exception.Message)"
        Write-Info "You can try installing manually with: npm install -g pnpm"
        return $false
    }
}

function Get-VencordPath {
    $defaultPath = Join-Path $env:USERPROFILE "Desktop\Vencord"
    
    Write-Info "Enter the path where Vencord should be installed:"
    Write-Info "Default: $defaultPath"
    Write-Info "Press ENTER for default, or type custom path:"
    
    $userInput = Read-Host "Path"
    
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        Write-Info "Using default path: $defaultPath"
        return $defaultPath
    }
    
    $userInput = $userInput.Trim('"').Trim("'").Trim()
    Write-Info "Using custom path: $userInput"
    return $userInput
}

function Install-Vencord {
    param($InstallPath)
    
    Write-Step "Setting up Vencord"
    
    try {
        # Check if Vencord already exists
        if (Test-Path "$InstallPath\package.json") {
            $packageContent = Get-Content "$InstallPath\package.json" -Raw | ConvertFrom-Json
            if ($packageContent.name -eq "vencord") {
                Write-Success "Found existing Vencord installation at: $InstallPath"
                return $InstallPath
            }
        }
        
        Write-Info "Cloning Vencord repository..."
        
        $parentDir = Split-Path $InstallPath -Parent
        if (!(Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        if (Test-Path $InstallPath) {
            Write-Warning "Removing existing directory: $InstallPath"
            Remove-Item $InstallPath -Recurse -Force
        }
        
        $currentLocation = Get-Location
        Set-Location $parentDir
        
        $targetDirName = Split-Path $InstallPath -Leaf
        git clone https://github.com/Vendicated/Vencord.git $targetDirName
        
        Set-Location $currentLocation
        
        if (Test-Path "$InstallPath\package.json") {
            Write-Success "Vencord cloned successfully to: $InstallPath"
            return $InstallPath
        } else {
            throw "Vencord clone failed - package.json not found"
        }
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
    
    Write-Step "Installing MultiMessageCopy Plugin"
    
    try {
        $userPluginsPath = Join-Path $VencordPath "src\userplugins"
        $pluginPath = Join-Path $userPluginsPath "MultiMessageCopy"
        
        if (!(Test-Path $userPluginsPath)) {
            New-Item -ItemType Directory -Path $userPluginsPath -Force | Out-Null
            Write-Info "Created userplugins directory"
        }
        
        if (Test-Path $pluginPath) {
            Write-Info "Removing existing MultiMessageCopy directory..."
            Remove-Item $pluginPath -Recurse -Force
        }
        
        Write-Info "Cloning MultiMessageCopy plugin repository..."
        $currentLocation = Get-Location
        Set-Location $userPluginsPath
        
        git clone https://github.com/tsx-awtns/MultiMessageCopy.git temp-plugin
        
        if (Test-Path "temp-plugin\MultiMessageCopyFiles") {
            Move-Item "temp-plugin\MultiMessageCopyFiles" "MultiMessageCopy"
            Remove-Item "temp-plugin" -Recurse -Force
            Write-Success "MultiMessageCopy plugin installed successfully!"
        } else {
            throw "MultiMessageCopyFiles folder not found in repository"
        }
        
        Set-Location $currentLocation
        return $true
    }
    catch {
        Write-Error "Failed to install MultiMessageCopy plugin: $($_.Exception.Message)"
        Write-Info "You can clone manually: https://github.com/tsx-awtns/MultiMessageCopy.git"
        return $false
    }
}

function Build-Vencord {
    param($VencordPath)
    
    Write-Step "Building Vencord"
    
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
        pnpm inject
        
        Set-Location $currentLocation
        Write-Success "Vencord injection completed!"
        return $true
    }
    catch {
        Write-Error "Failed to inject Vencord: $($_.Exception.Message)"
        Write-Info "You can run 'pnpm inject' manually in the Vencord directory."
        return $false
    }
}

function Main {
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║                MultiMessageCopy Setup Script                ║
║                        Version 1.2                          ║
║                     by tsx-awtns                             ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    try {
        if (!(Test-Administrator)) {
            Write-Warning "Not running as Administrator. Some installations might fail."
            $continue = Read-Host "Continue anyway? (y/N)"
            if ($continue -ne "y" -and $continue -ne "Y") { 
                Write-Info "Exiting..."
                exit 0 
            }
        }

        # Install Node.js
        if (!$SkipNodeInstall) { 
            if (!(Install-NodeJS)) {
                Write-Error "Node.js installation failed. Cannot continue."
                Write-Info "Please install Node.js manually and restart PowerShell."
                Read-Host "Press Enter to exit"
                exit 1
            }
        }
        
        # Install Git
        if (!$SkipGitInstall) { 
            if (!(Install-Git)) {
                Write-Warning "Git installation failed. You may need to install it manually."
            }
        }
        
        # Install pnpm
        if (!(Install-Pnpm)) {
            Write-Error "pnpm installation failed. Cannot continue."
            Write-Info "Please restart PowerShell and try again."
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Get Vencord installation path
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
        
        # Install dependencies
        if (!(Install-VencordDependencies -VencordPath $vencordDir)) {
            Write-Error "Failed to install Vencord dependencies."
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Install plugin
        if (!(Install-MultiMessageCopy -VencordPath $vencordDir)) {
            Write-Error "Failed to install MultiMessageCopy plugin."
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Build Vencord
        if (!(Build-Vencord -VencordPath $vencordDir)) {
            Write-Error "Failed to build Vencord."
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Ask about injection
        Write-Info "`nSetup completed successfully!"
        $inject = Read-Host "Inject Vencord into Discord now? (Y/n)"
        if ($inject -ne "n" -and $inject -ne "N") {
            Inject-Vencord -VencordPath $vencordDir
        }
        
        Write-Step "Setup Complete!"
        Write-Success @"
✅ MultiMessageCopy plugin installed successfully!

NEXT STEPS:
1. Restart Discord
2. Go to Settings > Vencord > Plugins
3. Enable 'MultiMessageCopy'
4. Use the plugin features in Discord

INSTALLATION PATH: $vencordDir
REPOSITORY: https://github.com/tsx-awtns/MultiMessageCopy
"@

        if ($inject -eq "n" -or $inject -eq "N") {
            Write-Warning "`nTo inject Vencord later, run 'pnpm inject' in: $vencordDir"
        }
        
        Read-Host "`nPress Enter to exit"
    }
    catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        Write-Info "Check the error messages above and try again."
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Run the main function
Main
