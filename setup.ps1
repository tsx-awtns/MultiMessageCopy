# PowerShell 

# MultiMessageCopy Setup Script v1.3 (Windows)
# Author: tsx-awtns
# Enhanced UI/UX Version

param(
    [switch]$SkipNodeInstall,
    [switch]$SkipGitInstall,
    [string]$VencordPath = "",
    [switch]$Help
)

# Enhanced UI Functions
function Write-Success { 
    param($Message) 
    Write-Host "✅ $Message" -ForegroundColor Green 
}

function Write-Warning { 
    param($Message) 
    Write-Host "⚠️  $Message" -ForegroundColor Yellow 
}

function Write-Error { 
    param($Message) 
    Write-Host "❌ $Message" -ForegroundColor Red 
}

function Write-Info { 
    param($Message) 
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan 
}

function Write-Step { 
    param($Message) 
    Write-Host "`n" -NoNewline
    Write-Host "🔄 $Message" -ForegroundColor Magenta -BackgroundColor Black
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
}

function Write-Progress {
    param($Activity, $Status, $PercentComplete)
    Write-Progress -Activity "🚀 $Activity" -Status $Status -PercentComplete $PercentComplete
}

function Write-Banner {
    Clear-Host
    Write-Host @"

    ███╗   ███╗██╗   ██╗██╗  ████████╗██╗    ███╗   ███╗███████╗███████╗███████╗ █████╗  ██████╗ ███████╗
    ████╗ ████║██║   ██║██║  ╚══██╔══╝██║    ████╗ ████║██╔════╝██╔════╝██╔════╝██╔══██╗██╔════╝ ██╔════╝
    ██╔████╔██║██║   ██║██║     ██║   ██║    ██╔████╔██║█████╗  ███████╗███████╗███████║██║  ███╗█████╗  
    ██║╚██╔╝██║██║   ██║██║     ██║   ██║    ██║╚██╔╝██║██╔══╝  ╚════██║╚════██║██╔══██║██║   ██║██╔══╝  
    ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║    ██║ ╚═╝ ██║███████╗███████║███████║██║  ██║╚██████╔╝███████╗
    ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝    ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
                                                                                                           
                                    ██████╗ ██████╗ ██████╗ ██╗   ██╗                                    
                                   ██╔════╝██╔═══██╗██╔══██╗╚██╗ ██╔╝                                    
                                   ██║     ██║   ██║██████╔╝ ╚████╔╝                                     
                                   ██║     ██║   ██║██╔═══╝   ╚██╔╝                                      
                                   ╚██████╗╚██████╔╝██║        ██║                                       
                                    ╚═════╝ ╚═════╝ ╚═╝        ╚═╝                                       

"@ -ForegroundColor Cyan

    Write-Host "    ╔══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "    ║                          MultiMessageCopy Setup Script v1.3                         ║" -ForegroundColor White
    Write-Host "    ║                                   by tsx-awtns                                       ║" -ForegroundColor Gray
    Write-Host "    ╚══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Help {
    Write-Banner
    Write-Host @"
📖 USAGE GUIDE

COMMAND:
    .\setup.ps1 [OPTIONS]

OPTIONS:
    -SkipNodeInstall    Skip Node.js installation check
    -SkipGitInstall     Skip Git installation check  
    -VencordPath        Specify custom Vencord installation path
    -Help               Show this help message

EXAMPLES:
    .\setup.ps1                                    # Full automatic setup
    .\setup.ps1 -SkipNodeInstall -SkipGitInstall   # Skip dependency installs
    .\setup.ps1 -VencordPath "C:\MyVencord"        # Custom Vencord path

"@ -ForegroundColor White
}

function Get-UserChoice {
    param(
        [string]$Prompt,
        [string]$DefaultChoice = "Y",
        [string[]]$ValidChoices = @("Y", "N")
    )
    
    do {
        Write-Host ""
        Write-Host "💭 $Prompt" -ForegroundColor Yellow
        Write-Host "   Valid options: " -NoNewline -ForegroundColor Gray
        
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
        Write-Host "👉 Your choice" -NoNewline -ForegroundColor Cyan
        Write-Host " (press Enter for default): " -NoNewline -ForegroundColor Gray
        
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
    Write-Host "📁 $Prompt" -ForegroundColor Yellow
    Write-Host "   Default location: " -NoNewline -ForegroundColor Gray
    Write-Host "$DefaultPath" -ForegroundColor Green
    
    if ($Example) {
        Write-Host "   Example: " -NoNewline -ForegroundColor Gray
        Write-Host "$Example" -ForegroundColor White
    }
    
    Write-Host "👉 Enter custom path or press Enter for default: " -NoNewline -ForegroundColor Cyan
    
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
    Write-Host "📋 INSTALLATION SUMMARY" -ForegroundColor Magenta -BackgroundColor Black
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
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
    Write-Progress -Activity "System Setup" -Status "Refreshing environment variables..." -PercentComplete 50
    
    try {
        $machinePath = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $userPath = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        
        $machinePath = [System.Environment]::ExpandEnvironmentVariables($machinePath)
        $userPath = [System.Environment]::ExpandEnvironmentVariables($userPath)
        
        $env:PATH = $machinePath + ";" + $userPath
        
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
        
        Write-Progress -Activity "System Setup" -Status "Environment updated successfully" -PercentComplete 100
        Start-Sleep -Milliseconds 500
        Write-Progress -Activity "System Setup" -Completed
        return $true
    }
    catch {
        Write-Progress -Activity "System Setup" -Completed
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
    
    if (Test-Command "choco") {
        Write-Info "Using Chocolatey package manager for installation"
        Write-Progress -Activity "Installing Node.js" -Status "Installing via Chocolatey..." -PercentComplete 25
        
        try {
            Start-Process -FilePath "choco" -ArgumentList "install", "nodejs", "-y" -Wait -NoNewWindow
            Update-SessionPath
            
            if (Test-Command "node") {
                $version = node --version
                Write-Success "Node.js installed successfully via Chocolatey: $version"
                Write-Progress -Activity "Installing Node.js" -Completed
                return $true
            }
        }
        catch {
            Write-Warning "Chocolatey installation failed. Trying direct download..."
        }
    }
    
    Write-Info "Downloading Node.js installer from official website"
    $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
    $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
    
    try {
        Write-Progress -Activity "Installing Node.js" -Status "Downloading installer..." -PercentComplete 30
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
        
        Write-Progress -Activity "Installing Node.js" -Status "Running installer (this may take a few minutes)..." -PercentComplete 60
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
        
        if ($process.ExitCode -ne 0) {
            throw "Installation failed with exit code: $($process.ExitCode)"
        }
        
        Write-Progress -Activity "Installing Node.js" -Status "Finalizing installation..." -PercentComplete 90
        Start-Sleep -Seconds 3
        Update-SessionPath
        
        if (Test-Command "node") {
            $version = node --version
            Write-Success "Node.js installed successfully: $version"
            Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            Write-Progress -Activity "Installing Node.js" -Completed
            return $true
        } else {
            Write-Error "Installation completed but Node.js command not found"
            Write-Info "Please restart PowerShell and run the script again"
            Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            Write-Progress -Activity "Installing Node.js" -Completed
            return $false
        }
    }
    catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        Write-Info "Please install Node.js manually from https://nodejs.org/"
        Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
        Write-Progress -Activity "Installing Node.js" -Completed
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
    
    if (Test-Command "choco") {
        Write-Info "Using Chocolatey package manager for installation"
        Write-Progress -Activity "Installing Git" -Status "Installing via Chocolatey..." -PercentComplete 25
        
        try {
            Start-Process -FilePath "choco" -ArgumentList "install", "git", "-y" -Wait -NoNewWindow
            Update-SessionPath
            
            if (Test-Command "git") {
                Write-Success "Git installed successfully via Chocolatey"
                Write-Progress -Activity "Installing Git" -Completed
                return $true
            }
        }
        catch {
            Write-Warning "Chocolatey installation failed. Trying direct download..."
        }
    }
    
    Write-Info "Downloading Git installer from official website"
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
    $gitInstaller = "$env:TEMP\git-installer.exe"
    
    try {
        Write-Progress -Activity "Installing Git" -Status "Downloading installer..." -PercentComplete 30
        Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
        
        Write-Progress -Activity "Installing Git" -Status "Running installer..." -PercentComplete 60
        Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
        
        Write-Progress -Activity "Installing Git" -Status "Finalizing installation..." -PercentComplete 90
        Update-SessionPath
        
        if (Test-Command "git") {
            Write-Success "Git installed successfully"
            Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            Write-Progress -Activity "Installing Git" -Completed
            return $true
        } else {
            Write-Warning "Git installed but command not found. May require restart"
            Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            Write-Progress -Activity "Installing Git" -Completed
            return $false
        }
    }
    catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        Write-Info "Please install Git manually from https://git-scm.com/"
        Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
        Write-Progress -Activity "Installing Git" -Completed
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
        Write-Progress -Activity "Installing pnpm" -Status "Installing via npm..." -PercentComplete 50
        
        $npmProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
        
        if ($npmProcess.ExitCode -eq 0) {
            Write-Progress -Activity "Installing pnpm" -Status "Finalizing installation..." -PercentComplete 90
            Update-SessionPath
            Start-Sleep -Seconds 2
            
            if (Test-Command "pnpm") {
                $version = pnpm --version
                Write-Success "pnpm installed successfully: $version"
                Write-Progress -Activity "Installing pnpm" -Completed
                return $true
            } else {
                $npmPrefix = cmd /c "npm config get prefix" 2>$null
                if ($npmPrefix -and (Test-Path "$npmPrefix\pnpm.cmd")) {
                    $env:PATH += ";$npmPrefix"
                    if (Test-Command "pnpm") {
                        $version = pnpm --version
                        Write-Success "pnpm is now available: $version"
                        Write-Progress -Activity "Installing pnpm" -Completed
                        return $true
                    }
                }
                
                Write-Error "pnpm installation completed but command not available"
                Write-Progress -Activity "Installing pnpm" -Completed
                return $false
            }
        } else {
            throw "npm install failed with exit code: $($npmProcess.ExitCode)"
        }
    }
    catch {
        Write-Error "Installation failed: $($_.Exception.Message)"
        Write-Info "You can try installing manually with: npm install -g pnpm"
        Write-Progress -Activity "Installing pnpm" -Completed
        return $false
    }
}

function Install-Vencord {
    param($InstallPath)
    
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
        Write-Progress -Activity "Setting up Vencord" -Status "Preparing directories..." -PercentComplete 20
        
        $parentDir = Split-Path $InstallPath -Parent
        if (!(Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        if (Test-Path $InstallPath) {
            Write-Warning "Removing existing directory: $InstallPath"
            Remove-Item $InstallPath -Recurse -Force
        }
        
        Write-Progress -Activity "Setting up Vencord" -Status "Cloning repository..." -PercentComplete 50
        
        $currentLocation = Get-Location
        Set-Location $parentDir
        
        $targetDirName = Split-Path $InstallPath -Leaf
        git clone https://github.com/Vendicated/Vencord.git $targetDirName
        
        Set-Location $currentLocation
        
        Write-Progress -Activity "Setting up Vencord" -Status "Verifying installation..." -PercentComplete 90
        
        if (Test-Path "$InstallPath\package.json") {
            Write-Success "Vencord cloned successfully to: $InstallPath"
            Write-Progress -Activity "Setting up Vencord" -Completed
            return $InstallPath
        } else {
            throw "Vencord clone failed - package.json not found"
        }
    }
    catch {
        Write-Error "Setup failed: $($_.Exception.Message)"
        Write-Progress -Activity "Setting up Vencord" -Completed
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
        Write-Progress -Activity "Installing Dependencies" -Status "Running pnpm install..." -PercentComplete 50
        
        pnpm install
        
        Set-Location $currentLocation
        Write-Success "Vencord dependencies installed successfully"
        Write-Progress -Activity "Installing Dependencies" -Completed
        return $true
    }
    catch {
        Write-Error "Dependencies installation failed: $($_.Exception.Message)"
        Write-Progress -Activity "Installing Dependencies" -Completed
        return $false
    }
}

function Install-MultiMessageCopy {
    param($VencordPath)
    
    Write-Step "MultiMessageCopy Plugin Installation"
    
    try {
        $userPluginsPath = Join-Path $VencordPath "src\userplugins"
        $pluginPath = Join-Path $userPluginsPath "MultiMessageCopy"
        
        Write-Progress -Activity "Installing Plugin" -Status "Preparing plugin directory..." -PercentComplete 20
        
        if (!(Test-Path $userPluginsPath)) {
            New-Item -ItemType Directory -Path $userPluginsPath -Force | Out-Null
            Write-Info "Created userplugins directory"
        }
        
        if (Test-Path $pluginPath) {
            Write-Info "Removing existing MultiMessageCopy directory..."
            Remove-Item $pluginPath -Recurse -Force
        }
        
        Write-Progress -Activity "Installing Plugin" -Status "Cloning plugin repository..." -PercentComplete 50
        Write-Info "Downloading MultiMessageCopy plugin from GitHub..."
        
        $currentLocation = Get-Location
        Set-Location $userPluginsPath
        
        git clone https://github.com/tsx-awtns/MultiMessageCopy.git temp-plugin
        
        Write-Progress -Activity "Installing Plugin" -Status "Installing plugin files..." -PercentComplete 80
        
        if (Test-Path "temp-plugin\MultiMessageCopyFiles") {
            Move-Item "temp-plugin\MultiMessageCopyFiles" "MultiMessageCopy"
            Remove-Item "temp-plugin" -Recurse -Force
            Write-Success "MultiMessageCopy plugin installed successfully"
        } else {
            throw "MultiMessageCopyFiles folder not found in repository"
        }
        
        Set-Location $currentLocation
        Write-Progress -Activity "Installing Plugin" -Completed
        return $true
    }
    catch {
        Write-Error "Plugin installation failed: $($_.Exception.Message)"
        Write-Info "You can clone manually: https://github.com/tsx-awtns/MultiMessageCopy.git"
        Write-Progress -Activity "Installing Plugin" -Completed
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
        Write-Progress -Activity "Building Vencord" -Status "Compiling project..." -PercentComplete 50
        
        pnpm build
        
        Set-Location $currentLocation
        Write-Success "Vencord built successfully"
        Write-Progress -Activity "Building Vencord" -Completed
        return $true
    }
    catch {
        Write-Error "Build failed: $($_.Exception.Message)"
        Write-Progress -Activity "Building Vencord" -Completed
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
        Write-Progress -Activity "Discord Integration" -Status "Injecting Vencord..." -PercentComplete 50
        
        pnpm inject
        
        Set-Location $currentLocation
        Write-Success "Vencord injection completed successfully"
        Write-Progress -Activity "Discord Integration" -Completed
        return $true
    }
    catch {
        Write-Error "Injection failed: $($_.Exception.Message)"
        Write-Info "You can run 'pnpm inject' manually in the Vencord directory"
        Write-Progress -Activity "Discord Integration" -Completed
        return $false
    }
}

function Show-CompletionMessage {
    param($VencordPath, $InjectionSkipped)
    
    Write-Host ""
    Write-Host "🎉 SETUP COMPLETED SUCCESSFULLY!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Success "MultiMessageCopy plugin has been installed successfully"
    Write-Info "Installation location: $VencordPath"
    
    Write-Host ""
    Write-Host "📋 NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "   1. 🔄 Restart Discord completely" -ForegroundColor White
    Write-Host "   2. ⚙️  Go to Discord Settings > Vencord > Plugins" -ForegroundColor White
    Write-Host "   3. ✅ Enable 'MultiMessageCopy' plugin" -ForegroundColor White
    Write-Host "   4. 🚀 Start using the plugin features in Discord" -ForegroundColor White
    
    if ($InjectionSkipped) {
        Write-Host ""
        Write-Warning "Manual injection required:"
        Write-Host "   Run 'pnpm inject' in: $VencordPath" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "🔗 USEFUL LINKS:" -ForegroundColor Cyan
    Write-Host "   Repository: https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor Blue
    Write-Host "   Issues: https://github.com/tsx-awtns/MultiMessageCopy/issues" -ForegroundColor Blue
    
    Write-Host ""
    Write-Host "Thank you for using MultiMessageCopy! 🙏" -ForegroundColor Green
    Write-Host ""
}

function Main {
    Write-Banner
    
    $nodeInstalled = $false
    $gitInstalled = $false
    $pnpmInstalled = $false
    
    try {
        # Administrator check
        if (!(Test-Administrator)) {
            Write-Warning "Script is not running as Administrator"
            Write-Info "Some installations might fail without administrator privileges"
            
            $continue = Get-UserChoice -Prompt "Do you want to continue anyway" -DefaultChoice "Y" -ValidChoices @("Y", "N")
            if ($continue -eq "N") { 
                Write-Info "Setup cancelled by user"
                exit 0 
            }
        }

        # Node.js Installation
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
        
        # Git Installation
        if (!$SkipGitInstall) { 
            $gitInstalled = Install-Git
            if (!$gitInstalled) {
                Write-Warning "Git installation failed or was skipped"
                Write-Info "Git is required for cloning repositories. You may need to install it manually"
            }
        } else {
            $gitInstalled = Test-Command "git"
        }
        
        # pnpm Installation
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
            $VencordPath = Get-UserPath -Prompt "Where should Vencord be installed" -DefaultPath $defaultPath -Example "C:\MyFolder\Vencord"
        }
        
        # Show installation summary
        Show-InstallationSummary -NodeInstalled $nodeInstalled -GitInstalled $gitInstalled -PnpmInstalled $pnpmInstalled -VencordPath $VencordPath
        
        # Install Vencord
        $vencordDir = Install-Vencord -InstallPath $VencordPath
        if (!$vencordDir) {
            Write-Error "Vencord setup failed. Cannot continue"
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Install dependencies
        if (!(Install-VencordDependencies -VencordPath $vencordDir)) {
            Write-Error "Failed to install Vencord dependencies"
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Install plugin
        if (!(Install-MultiMessageCopy -VencordPath $vencordDir)) {
            Write-Error "Failed to install MultiMessageCopy plugin"
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Build Vencord
        if (!(Build-Vencord -VencordPath $vencordDir)) {
            Write-Error "Failed to build Vencord"
            Read-Host "Press Enter to exit"
            exit 1
        }
        
        # Ask about injection
        $inject = Get-UserChoice -Prompt "Do you want to inject Vencord into Discord now" -DefaultChoice "Y" -ValidChoices @("Y", "N")
        
        $injectionSkipped = $false
        if ($inject -eq "Y") {
            if (!(Inject-Vencord -VencordPath $vencordDir)) {
                $injectionSkipped = $true
            }
        } else {
            $injectionSkipped = $true
        }
        
        # Show completion message
        Show-CompletionMessage -VencordPath $vencordDir -InjectionSkipped $injectionSkipped
        
        Read-Host "Press Enter to exit"
    }
    catch {
        Write-Error "Setup failed with error: $($_.Exception.Message)"
        Write-Info "Please check the error messages above and try again"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Run the main function
Main
