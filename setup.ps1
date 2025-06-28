# MultiMessageCopy Setup Script v2.0 - Enhanced Pro Version
# Author: tsx-awtns
# Enhanced with better UI/UX, detailed information, and improved layout

param([switch]$SkipNodeInstall, [switch]$SkipGitInstall, [string]$VencordPath = "", [switch]$Help, [switch]$Verbose)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Enhanced color functions with more variety
function Write-Success($Message) { Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Warning($Message) { Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error($Message) { Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Info($Message) { Write-Host "ℹ $Message" -ForegroundColor Cyan }
function Write-Debug($Message) { if ($Verbose) { Write-Host "🔍 $Message" -ForegroundColor DarkGray } }
function Write-Progress($Message) { Write-Host "⏳ $Message" -ForegroundColor Magenta }
function Write-Highlight($Message) { Write-Host "★ $Message" -ForegroundColor Yellow -BackgroundColor DarkBlue }

function Write-Step($Message, $StepNumber = 0, $TotalSteps = 0) { 
    Write-Host ""
    if ($StepNumber -gt 0 -and $TotalSteps -gt 0) {
        Write-Host "┌─ STEP $StepNumber/$TotalSteps: $Message" -ForegroundColor Magenta -BackgroundColor Black
    } else {
        Write-Host "┌─ $Message" -ForegroundColor Magenta -BackgroundColor Black
    }
    Write-Host "├" + ("─" * 70) -ForegroundColor DarkMagenta
}

function Write-SubStep($Message) {
    Write-Host "│ → $Message" -ForegroundColor Gray
}

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "║  ███╗   ███╗██╗   ██╗██╗  ████████╗██╗███╗   ███╗███████╗███████╗███████╗   ║" -ForegroundColor Cyan
    Write-Host "║  ████╗ ████║██║   ██║██║  ╚══██╔══╝██║████╗ ████║██╔════╝██╔════╝██╔════╝   ║" -ForegroundColor Cyan
    Write-Host "║  ██╔████╔██║██║   ██║██║     ██║   ██║██╔████╔██║█████╗  ███████╗███████╗   ║" -ForegroundColor Cyan
    Write-Host "║  ██║╚██╔╝██║██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔══╝  ╚════██║╚════██║   ║" -ForegroundColor Cyan
    Write-Host "║  ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║██║ ╚═╝ ██║███████╗███████║███████║   ║" -ForegroundColor Cyan
    Write-Host "║  ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝   ║" -ForegroundColor Cyan
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "║                        📋 COPY PLUGIN SETUP WIZARD 📋                       ║" -ForegroundColor White
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
    Write-Host "║                    MultiMessageCopy Setup Script v2.0                       ║" -ForegroundColor White
    Write-Host "║                              by tsx-awtns                                    ║" -ForegroundColor Gray
    Write-Host "║                                                                              ║" -ForegroundColor DarkCyan
    Write-Host "║  🎯 Purpose: Automated installation of MultiMessageCopy plugin for Vencord  ║" -ForegroundColor Yellow
    Write-Host "║  🔧 Features: Node.js, Git, pnpm, Vencord, Plugin installation             ║" -ForegroundColor Yellow
    Write-Host "║  💡 Enhanced: Better UI, detailed progress, error handling                  ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
}

function Show-Help {
    Write-Banner
    Write-Host "📖 COMMAND LINE USAGE" -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host ""
    Write-Host "SYNTAX:" -ForegroundColor White
    Write-Host "  .\setup.ps1 [OPTIONS]" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "AVAILABLE OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -SkipNodeInstall    Skip Node.js installation (if already installed)" -ForegroundColor Gray
    Write-Host "  -SkipGitInstall     Skip Git installation (if already installed)" -ForegroundColor Gray
    Write-Host "  -VencordPath        Specify custom Vencord installation path" -ForegroundColor Gray
    Write-Host "  -Verbose            Enable detailed debug output" -ForegroundColor Gray
    Write-Host "  -Help               Display this help information" -ForegroundColor Gray
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Yellow
    Write-Host "  .\setup.ps1                                    # Standard installation" -ForegroundColor White
    Write-Host "  .\setup.ps1 -SkipNodeInstall                   # Skip Node.js if installed" -ForegroundColor White
    Write-Host "  .\setup.ps1 -VencordPath 'C:\MyVencord'        # Custom path" -ForegroundColor White
    Write-Host "  .\setup.ps1 -Verbose                           # Detailed output" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 TIP: Run as Administrator for best results!" -ForegroundColor Green
    Write-Host ""
}

if ($Help) { Show-Help; exit 0 }

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
    Write-Debug "Refreshing environment PATH variables..."
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
                Write-Debug "Added to PATH: $path"
            }
        }
    } catch {
        Write-Debug "PATH refresh failed: $($_.Exception.Message)"
    }
}

function Get-UserChoice($Prompt, $DefaultChoice = "Y", $Description = "") {
    do {
        Write-Host ""
        Write-Host "┌─ USER INPUT REQUIRED" -ForegroundColor Yellow -BackgroundColor DarkBlue
        Write-Host "│"
        Write-Host "│ 🤔 QUESTION: $Prompt" -ForegroundColor White
        if ($Description) {
            Write-Host "│ 💡 INFO: $Description" -ForegroundColor Gray
        }
        Write-Host "│"
        Write-Host "│ 📋 OPTIONS: " -NoNewline -ForegroundColor Gray
        if ($DefaultChoice -eq "Y") {
            Write-Host "[Y]es" -NoNewline -ForegroundColor Green
            Write-Host " / " -NoNewline -ForegroundColor Gray
            Write-Host "N" -NoNewline -ForegroundColor White
            Write-Host "o" -ForegroundColor White
        } else {
            Write-Host "Y" -NoNewline -ForegroundColor White
            Write-Host "es / " -NoNewline -ForegroundColor White
            Write-Host "[N]" -NoNewline -ForegroundColor Green
            Write-Host "o" -ForegroundColor Green
        }
        Write-Host "│"
        Write-Host "└─ Your choice (Enter for default): " -NoNewline -ForegroundColor Cyan
        $choice = Read-Host
        if ([string]::IsNullOrWhiteSpace($choice)) { 
            $choice = $DefaultChoice 
        }
        $choice = $choice.ToUpper()
        if ($choice -eq "Y" -or $choice -eq "N") { 
            Write-Host "   ✓ Selected: $choice" -ForegroundColor Green
            return $choice 
        }
        Write-Warning "Invalid choice '$choice'. Please enter Y or N."
    } while ($true)
}

function Get-UserPath($Prompt, $DefaultPath, $Description = "") {
    Write-Host ""
    Write-Host "┌─ PATH CONFIGURATION" -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host "│"
    Write-Host "│ 📁 $Prompt" -ForegroundColor White
    if ($Description) {
        Write-Host "│ 💡 $Description" -ForegroundColor Gray
    }
    Write-Host "│"
    Write-Host "│ 🎯 Default location:" -ForegroundColor Gray
    Write-Host "│    $DefaultPath" -ForegroundColor Green
    Write-Host "│"
    Write-Host "│ 📝 Example custom path:" -ForegroundColor Gray
    Write-Host "│    C:\MyProjects\Vencord" -ForegroundColor White
    Write-Host "│    D:\Development\Discord\Vencord" -ForegroundColor White
    Write-Host "│"
    Write-Host "└─ Enter custom path or press Enter for default: " -NoNewline -ForegroundColor Cyan
    $userInput = Read-Host
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        Write-Host "   ✓ Using default: $DefaultPath" -ForegroundColor Green
        return $DefaultPath
    }
    $userInput = $userInput.Trim('"').Trim("'").Trim()
    Write-Host "   ✓ Using custom: $userInput" -ForegroundColor Green
    return $userInput
}

function Show-SystemInfo {
    Write-Step "SYSTEM INFORMATION" 1 8
    Write-SubStep "Gathering system details..."
    
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
    
    Write-Host "│"
    Write-Host "│ 🖥️  SYSTEM DETAILS:" -ForegroundColor Cyan
    Write-Host "│    OS: $($osInfo.Caption) ($($osInfo.Version))" -ForegroundColor White
    Write-Host "│    Computer: $($computerInfo.Name)" -ForegroundColor White
    Write-Host "│    User: $env:USERNAME" -ForegroundColor White
    Write-Host "│    PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor White
    Write-Host "│    Admin Rights: $(if (Test-Administrator) { '✓ Yes' } else { '✗ No' })" -ForegroundColor $(if (Test-Administrator) { 'Green' } else { 'Red' })
    Write-Host "│"
    
    Write-Debug "System scan completed"
}

function Show-PreInstallationSummary($NodeSkip, $GitSkip, $VencordPath) {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║                           📋 INSTALLATION PLAN                              ║" -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkYellow
    Write-Host "║                                                                              ║" -ForegroundColor Yellow
    Write-Host "║  The following components will be installed/configured:                     ║" -ForegroundColor White
    Write-Host "║                                                                              ║" -ForegroundColor Yellow
    Write-Host "║  🔧 Node.js (JavaScript Runtime)        $(if (!$NodeSkip) { '✓ Install' } else { '⏭ Skip' })" -ForegroundColor $(if (!$NodeSkip) { 'Green' } else { 'Yellow' })
    Write-Host "║  📦 Git (Version Control)               $(if (!$GitSkip) { '✓ Install' } else { '⏭ Skip' })" -ForegroundColor $(if (!$GitSkip) { 'Green' } else { 'Yellow' })
    Write-Host "║  ⚡ pnpm (Package Manager)               ✓ Install" -ForegroundColor Green
    Write-Host "║  🎮 Vencord (Discord Client Mod)        ✓ Clone & Setup" -ForegroundColor Green
    Write-Host "║  🔌 MultiMessageCopy Plugin             ✓ Install & Configure" -ForegroundColor Green
    Write-Host "║                                                                              ║" -ForegroundColor Yellow
    Write-Host "║  📁 Installation Directory:                                                 ║" -ForegroundColor White
    Write-Host "║     $VencordPath" -ForegroundColor Cyan
    Write-Host "║                                                                              ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkYellow
    Write-Host ""
}

function Show-InstallationProgress($Current, $Total, $ComponentName, $Status) {
    $percentage = [math]::Round(($Current / $Total) * 100)
    $progressBar = "█" * [math]::Round($percentage / 5) + "░" * (20 - [math]::Round($percentage / 5))
    
    Write-Host ""
    Write-Host "┌─ INSTALLATION PROGRESS" -ForegroundColor Magenta -BackgroundColor Black
    Write-Host "│"
    Write-Host "│ 📊 Overall: [$progressBar] $percentage%" -ForegroundColor Cyan
    Write-Host "│ 🔄 Current: $ComponentName" -ForegroundColor White
    Write-Host "│ 📋 Status: $Status" -ForegroundColor Yellow
    Write-Host "│ 📈 Step: $Current of $Total" -ForegroundColor Gray
    Write-Host "│"
}

function Show-ComponentStatus($ComponentName, $Version = "", $Status = "Unknown", $Path = "") {
    $statusColor = switch ($Status) {
        "Installed" { "Green" }
        "Available" { "Green" }
        "Missing" { "Red" }
        "Failed" { "Red" }
        "Skipped" { "Yellow" }
        default { "Gray" }
    }
    
    $statusIcon = switch ($Status) {
        "Installed" { "✓" }
        "Available" { "✓" }
        "Missing" { "✗" }
        "Failed" { "✗" }
        "Skipped" { "⏭" }
        default { "?" }
    }
    
    Write-Host "│ $statusIcon $ComponentName" -NoNewline -ForegroundColor $statusColor
    if ($Version) {
        Write-Host " ($Version)" -NoNewline -ForegroundColor Gray
    }
    Write-Host " - $Status" -ForegroundColor $statusColor
    if ($Path) {
        Write-Host "│   📁 $Path" -ForegroundColor DarkGray
    }
}

function Show-FinalSummary($Success, $VencordPath, $ComponentsInstalled) {
    Write-Host ""
    if ($Success) {
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                            🎉 INSTALLATION COMPLETE! 🎉                     ║" -ForegroundColor Green
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkGreen
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "║  ✅ MultiMessageCopy plugin has been successfully installed!                ║" -ForegroundColor White
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "║  📁 Installation Location:                                                  ║" -ForegroundColor White
        Write-Host "║     $VencordPath" -ForegroundColor Cyan
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "║  🔧 Components Installed:                                                   ║" -ForegroundColor White
        foreach ($component in $ComponentsInstalled) {
            Write-Host "║     ✓ $component" -ForegroundColor Green
        }
        Write-Host "║                                                                              ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGreen
    } else {
        Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║                            ❌ INSTALLATION FAILED ❌                        ║" -ForegroundColor Red
        Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkRed
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "║  The installation encountered errors and could not complete successfully.   ║" -ForegroundColor White
        Write-Host "║  Please check the error messages above and try again.                       ║" -ForegroundColor White
        Write-Host "║                                                                              ║" -ForegroundColor Red
        Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkRed
    }
    
    Write-Host ""
    Write-Host "📋 NEXT STEPS:" -ForegroundColor Yellow -BackgroundColor DarkBlue
    Write-Host ""
    if ($Success) {
        Write-Host "   1️⃣  Restart Discord completely (close all Discord processes)" -ForegroundColor White
        Write-Host "   2️⃣  Open Discord Settings (⚙️ gear icon)" -ForegroundColor White
        Write-Host "   3️⃣  Navigate to: Vencord → Plugins" -ForegroundColor White
        Write-Host "   4️⃣  Find 'MultiMessageCopy' in the plugin list" -ForegroundColor White
        Write-Host "   5️⃣  Toggle the plugin ON (enable it)" -ForegroundColor White
        Write-Host "   6️⃣  Start using the multi-message copy features!" -ForegroundColor White
        Write-Host ""
        Write-Host "🎯 PLUGIN FEATURES:" -ForegroundColor Cyan
        Write-Host "   • Copy multiple messages at once" -ForegroundColor Gray
        Write-Host "   • Batch message operations" -ForegroundColor Gray
        Write-Host "   • Enhanced clipboard functionality" -ForegroundColor Gray
    } else {
        Write-Host "   1️⃣  Check the error messages above" -ForegroundColor White
        Write-Host "   2️⃣  Ensure you have internet connection" -ForegroundColor White
        Write-Host "   3️⃣  Try running as Administrator" -ForegroundColor White
        Write-Host "   4️⃣  Restart PowerShell and try again" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "🔗 USEFUL LINKS:" -ForegroundColor Cyan
    Write-Host "   📦 Plugin Repository: https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor Blue
    Write-Host "   🐛 Report Issues: https://github.com/tsx-awtns/MultiMessageCopy/issues" -ForegroundColor Blue
    Write-Host "   📖 Vencord Documentation: https://docs.vencord.dev/" -ForegroundColor Blue
    Write-Host ""
    Write-Host "💝 Thank you for using MultiMessageCopy! Enjoy your enhanced Discord experience!" -ForegroundColor Green
    Write-Host ""
}

# Main execution starts here
Write-Banner

$componentsInstalled = @()
$totalSteps = 8

try {
    # Step 1: System Information
    Show-SystemInfo
    
    # Step 2: Administrator check
    Write-Step "PRIVILEGE CHECK" 2 $totalSteps
    if (!(Test-Administrator)) {
        Write-Warning "Script is not running with Administrator privileges"
        Write-SubStep "Some installations might require elevated permissions"
        Write-SubStep "You can continue, but some features might fail"
        $continue = Get-UserChoice "Do you want to continue anyway?" "Y" "Recommended: Restart as Administrator for best results"
        if ($continue -eq "N") { 
            Write-Info "Setup cancelled by user. Restart as Administrator and try again."
            exit 0 
        }
    } else {
        Write-Success "Running with Administrator privileges"
        Write-SubStep "All installation features will be available"
    }

    # Step 3: Get installation preferences
    Write-Step "CONFIGURATION" 3 $totalSteps
    if ([string]::IsNullOrEmpty($VencordPath)) {
        $defaultPath = Join-Path $env:USERPROFILE "Desktop\Vencord"
        $VencordPath = Get-UserPath "Where should Vencord be installed?" $defaultPath "This will be the main directory for Vencord and the plugin"
    }
    
    Show-PreInstallationSummary $SkipNodeInstall $SkipGitInstall $VencordPath
    
    $proceed = Get-UserChoice "Proceed with installation?" "Y" "This will download and install the required components"
    if ($proceed -eq "N") {
        Write-Info "Installation cancelled by user"
        exit 0
    }

    # Step 4: Node.js Installation
    Show-InstallationProgress 4 $totalSteps "Node.js" "Checking and installing..."
    Write-Step "NODE.JS SETUP" 4 $totalSteps
    $nodeInstalled = $false
    if (!$SkipNodeInstall) {
        Write-SubStep "Refreshing environment variables..."
        Update-SessionPath
        
        if (Test-Command "node") {
            $version = node --version
            Write-Success "Node.js is already installed: $version"
            Show-ComponentStatus "Node.js" $version "Available"
            $nodeInstalled = $true
            $componentsInstalled += "Node.js $version"
        } else {
            Write-Progress "Downloading and installing Node.js..."
            Write-SubStep "This may take a few minutes depending on your internet connection"
            $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
            $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
            try {
                Write-SubStep "Downloading Node.js installer..."
                Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
                Write-SubStep "Running Node.js installer (silent mode)..."
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
                if ($process.ExitCode -eq 0) {
                    Write-SubStep "Installation completed, refreshing environment..."
                    Start-Sleep -Seconds 3
                    Update-SessionPath
                    if (Test-Command "node") {
                        $version = node --version
                        Write-Success "Node.js installed successfully: $version"
                        Show-ComponentStatus "Node.js" $version "Installed"
                        $nodeInstalled = $true
                        $componentsInstalled += "Node.js $version"
                    }
                }
                Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Error "Node.js installation failed: $($_.Exception.Message)"
                Show-ComponentStatus "Node.js" "" "Failed"
                Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            }
        }
        
        if (!$nodeInstalled) {
            Write-Error "Node.js is required for this installation"
            Write-SubStep "Please install Node.js manually from https://nodejs.org/ and restart PowerShell"
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        $nodeInstalled = Test-Command "node"
        if ($nodeInstalled) {
            $version = node --version
            Show-ComponentStatus "Node.js" $version "Skipped"
        } else {
            Show-ComponentStatus "Node.js" "" "Missing"
        }
    }

    # Step 5: Git Installation
    Show-InstallationProgress 5 $totalSteps "Git" "Checking and installing..."
    Write-Step "GIT SETUP" 5 $totalSteps
    $gitInstalled = $false
    if (!$SkipGitInstall) {
        Write-SubStep "Refreshing environment variables..."
        Update-SessionPath
        
        if (Test-Command "git") {
            $version = git --version
            Write-Success "Git is already installed: $version"
            Show-ComponentStatus "Git" $version "Available"
            $gitInstalled = $true
            $componentsInstalled += "Git"
        } else {
            Write-Progress "Downloading and installing Git..."
            Write-SubStep "Installing Git for Windows with optimal settings"
            $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
            $gitInstaller = "$env:TEMP\git-installer.exe"
            try {
                Write-SubStep "Downloading Git installer..."
                Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
                Write-SubStep "Running Git installer (silent mode)..."
                Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
                Write-SubStep "Installation completed, refreshing environment..."
                Update-SessionPath
                if (Test-Command "git") {
                    $version = git --version
                    Write-Success "Git installed successfully: $version"
                    Show-ComponentStatus "Git" $version "Installed"
                    $gitInstalled = $true
                    $componentsInstalled += "Git"
                }
                Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Git installation failed: $($_.Exception.Message)"
                Show-ComponentStatus "Git" "" "Failed"
                Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        $gitInstalled = Test-Command "git"
        if ($gitInstalled) {
            $version = git --version
            Show-ComponentStatus "Git" $version "Skipped"
        } else {
            Show-ComponentStatus "Git" "" "Missing"
        }
    }

    # Step 6: pnpm Installation
    Show-InstallationProgress 6 $totalSteps "pnpm" "Installing package manager..."
    Write-Step "PNPM SETUP" 6 $totalSteps
    Write-SubStep "pnpm is a fast, disk space efficient package manager"
    Update-SessionPath
    
    $pnpmInstalled = $false
    if (Test-Command "pnpm") {
        $version = pnpm --version
        Write-Success "pnpm is already installed: $version"
        Show-ComponentStatus "pnpm" $version "Available"
        $pnpmInstalled = $true
        $componentsInstalled += "pnpm $version"
    } else {
        if (Test-Command "npm") {
            Write-Progress "Installing pnpm via npm..."
            Write-SubStep "This will install pnpm globally using npm"
            try {
                $npmProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
                if ($npmProcess.ExitCode -eq 0) {
                    Write-SubStep "Installation completed, refreshing environment..."
                    Update-SessionPath
                    Start-Sleep -Seconds 2
                    if (Test-Command "pnpm") {
                        $version = pnpm --version
                        Write-Success "pnpm installed successfully: $version"
                        Show-ComponentStatus "pnpm" $version "Installed"
                        $pnpmInstalled = $true
                        $componentsInstalled += "pnpm $version"
                    }
                }
            } catch {
                Write-Error "pnpm installation failed: $($_.Exception.Message)"
                Show-ComponentStatus "pnpm" "" "Failed"
            }
        } else {
            Write-Error "npm is not available (Node.js installation may have failed)"
            Show-ComponentStatus "pnpm" "" "Failed"
        }
    }
    
    if (!$pnpmInstalled) {
        Write-Error "pnpm is required for Vencord development"
        Write-SubStep "Please restart PowerShell and try again, or install pnpm manually"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Step 7: Vencord Installation
    Show-InstallationProgress 7 $totalSteps "Vencord" "Cloning and setting up..."
    Write-Step "VENCORD SETUP" 7 $totalSteps
    Write-SubStep "Vencord is a Discord client modification with plugin support"
    $vencordDir = $null
    try {
        if (Test-Path "$VencordPath\package.json") {
            $packageContent = Get-Content "$VencordPath\package.json" -Raw | ConvertFrom-Json
            if ($packageContent.name -eq "vencord") {
                Write-Success "Found existing Vencord installation"
                Show-ComponentStatus "Vencord" $packageContent.version "Available" $VencordPath
                $vencordDir = $VencordPath
                $componentsInstalled += "Vencord (existing)"
            }
        }
        
        if (!$vencordDir) {
            Write-Progress "Cloning Vencord repository from GitHub..."
            Write-SubStep "This will download the latest Vencord source code"
            $parentDir = Split-Path $VencordPath -Parent
            if (!(Test-Path $parentDir)) { 
                Write-SubStep "Creating parent directory: $parentDir"
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null 
            }
            if (Test-Path $VencordPath) { 
                Write-SubStep "Removing existing directory: $VencordPath"
                Remove-Item $VencordPath -Recurse -Force 
            }
            
            Write-SubStep "Cloning repository (this may take a few minutes)..."
            $currentLocation = Get-Location
            Set-Location $parentDir
            $targetDirName = Split-Path $VencordPath -Leaf
            git clone https://github.com/Vendicated/Vencord.git $targetDirName
            Set-Location $currentLocation
            
            if (Test-Path "$VencordPath\package.json") {
                Write-Success "Vencord cloned successfully"
                Show-ComponentStatus "Vencord" "latest" "Installed" $VencordPath
                $vencordDir = $VencordPath
                $componentsInstalled += "Vencord (cloned)"
            }
        }
    } catch {
        Write-Error "Vencord setup failed: $($_.Exception.Message)"
        Show-ComponentStatus "Vencord" "" "Failed"
    }
    
    if (!$vencordDir) {
        Write-Error "Cannot continue without Vencord"
        Write-SubStep "Please check your internet connection and Git installation"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Install dependencies
    Write-SubStep "Installing Vencord dependencies..."
    Write-Progress "This may take several minutes depending on your internet speed"
    try {
        $currentLocation = Get-Location
        Set-Location $vencordDir
        Write-SubStep "Running 'pnpm install' in Vencord directory..."
        pnpm install
        Set-Location $currentLocation
        Write-Success "Vencord dependencies installed successfully"
        $componentsInstalled += "Vencord Dependencies"
    } catch {
        Write-Error "Dependencies installation failed: $($_.Exception.Message)"
        Write-SubStep "You may need to run 'pnpm install' manually in the Vencord directory"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Step 8: Plugin Installation
    Show-InstallationProgress 8 $totalSteps "MultiMessageCopy Plugin" "Installing plugin..."
    Write-Step "PLUGIN INSTALLATION" 8 $totalSteps
    Write-SubStep "Installing MultiMessageCopy plugin into Vencord"
    try {
        $userPluginsPath = Join-Path $vencordDir "src\userplugins"
        $pluginPath = Join-Path $userPluginsPath "MultiMessageCopy"
        
        Write-SubStep "Preparing plugin directory structure..."
        if (!(Test-Path $userPluginsPath)) { 
            New-Item -ItemType Directory -Path $userPluginsPath -Force | Out-Null 
            Write-Debug "Created userplugins directory"
        }
        if (Test-Path $pluginPath) { 
            Write-SubStep "Removing existing plugin installation..."
            Remove-Item $pluginPath -Recurse -Force 
        }
        
        Write-Progress "Downloading MultiMessageCopy plugin from GitHub..."
        Write-SubStep "Cloning plugin repository..."
        $currentLocation = Get-Location
        Set-Location $userPluginsPath
        git clone https://github.com/tsx-awtns/MultiMessageCopy.git temp-plugin
        
        Write-SubStep "Installing plugin files..."
        if (Test-Path "temp-plugin\MultiMessageCopyFiles") {
            Move-Item "temp-plugin\MultiMessageCopyFiles" "MultiMessageCopy"
            Remove-Item "temp-plugin" -Recurse -Force
            Write-Success "MultiMessageCopy plugin installed successfully"
            Show-ComponentStatus "MultiMessageCopy Plugin" "latest" "Installed" $pluginPath
            $componentsInstalled += "MultiMessageCopy Plugin"
        } else {
            throw "MultiMessageCopyFiles folder not found in repository"
        }
        Set-Location $currentLocation
    } catch {
        Write-Error "Plugin installation failed: $($_.Exception.Message)"
        Write-SubStep "You can try cloning manually: https://github.com/tsx-awtns/MultiMessageCopy.git"
        Show-ComponentStatus "MultiMessageCopy Plugin" "" "Failed"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Build Vencord
    Write-Progress "Building Vencord with MultiMessageCopy plugin..."
    Write-SubStep "This compiles Vencord with all plugins including MultiMessageCopy"
    try {
        $currentLocation = Get-Location
        Set-Location $vencordDir
        Write-SubStep "Running 'pnpm build' (this may take a few minutes)..."
        pnpm build
        Set-Location $currentLocation
        Write-Success "Vencord built successfully with MultiMessageCopy plugin"
        $componentsInstalled += "Vencord Build"
    } catch {
        Write-Error "Build failed: $($_.Exception.Message)"
        Write-SubStep "You may need to run 'pnpm build' manually in the Vencord directory"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Ask about injection
    $inject = Get-UserChoice "Do you want to inject Vencord into Discord now?" "Y" "This will modify your Discord installation to use Vencord"
    if ($inject -eq "Y") {
        Write-Progress "Injecting Vencord into Discord..."
        Write-SubStep "This modifies Discord to load Vencord on startup"
        try {
            $currentLocation = Get-Location
            Set-Location $vencordDir
            Write-SubStep "Running 'pnpm inject'..."
            pnpm inject
            Set-Location $currentLocation
            Write-Success "Vencord injection completed successfully"
            $componentsInstalled += "Discord Injection"
        } catch {
            Write-Warning "Injection failed: $($_.Exception.Message)"
            Write-SubStep "You can run 'pnpm inject' manually in the Vencord directory later"
        }
    } else {
        Write-Info "Injection skipped - you can run 'pnpm inject' manually later"
    }

    # Show final summary
    Show-FinalSummary $true $vencordDir $componentsInstalled
    Read-Host "Press Enter to exit"

} catch {
    Write-Error "Setup failed with unexpected error: $($_.Exception.Message)"
    Write-Debug "Full error details: $($_.Exception)"
    Show-FinalSummary $false "" @()
    Read-Host "Press Enter to exit"
    exit 1
}
