# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                    MultiMessageCopy Setup Script v2.0                       ║
# ║                          Enhanced Professional Edition                       ║
# ║                              Author: tsx-awtns                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

param(
    [switch]$SkipNodeInstall,
    [switch]$SkipGitInstall, 
    [string]$VencordPath = "",
    [switch]$Help,
    [switch]$Verbose,
    [switch]$NoPrompts
)

# ═══════════════════════════════════════════════════════════════════════════════
#                              CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "MultiMessageCopy Setup - Enhanced Edition"

$global:ScriptVersion = "2.0"
$global:StepCounter = 0
$global:TotalSteps = 8
$global:StartTime = Get-Date

# ═══════════════════════════════════════════════════════════════════════════════
#                              STYLING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Write-ColoredText($Text, $Color = "White", $BackgroundColor = $null, $NoNewline = $false) {
    $params = @{
        Object = $Text
        ForegroundColor = $Color
        NoNewline = $NoNewline
    }
    if ($BackgroundColor) { $params.BackgroundColor = $BackgroundColor }
    Write-Host @params
}

function Write-Success($Message) { 
    Write-ColoredText "    ✓ " "Green" -NoNewline
    Write-ColoredText "$Message" "Green"
}

function Write-Warning($Message) { 
    Write-ColoredText "    ⚠ " "Yellow" -NoNewline
    Write-ColoredText "$Message" "Yellow"
}

function Write-Error($Message) { 
    Write-ColoredText "    ✗ " "Red" -NoNewline
    Write-ColoredText "$Message" "Red"
}

function Write-Info($Message) { 
    Write-ColoredText "    ℹ " "Cyan" -NoNewline
    Write-ColoredText "$Message" "White"
}

function Write-Debug($Message) {
    if ($Verbose) {
        Write-ColoredText "    🔍 " "Magenta" -NoNewline
        Write-ColoredText "[DEBUG] $Message" "DarkGray"
    }
}

function Write-Progress($Activity, $Status, $PercentComplete) {
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
}

function Write-StepHeader($Title, $Description = "") {
    $global:StepCounter++
    $progressPercent = [math]::Round(($global:StepCounter / $global:TotalSteps) * 100)
    
    Write-Host ""
    Write-ColoredText "╔═══════════════════════════════════════════════════════════════════════════════╗" "DarkCyan"
    Write-ColoredText "║" "DarkCyan" -NoNewline
    Write-ColoredText " STEP $global:StepCounter/$global:TotalSteps: " "White" -NoNewline
    Write-ColoredText "$Title" "Cyan" -NoNewline
    $padding = 77 - $Title.Length - " STEP $global:StepCounter/$global:TotalSteps: ".Length
    Write-ColoredText (" " * $padding) "White" -NoNewline
    Write-ColoredText "║" "DarkCyan"
    
    if ($Description) {
        Write-ColoredText "║" "DarkCyan" -NoNewline
        Write-ColoredText " $Description" "Gray" -NoNewline
        $descPadding = 77 - $Description.Length
        Write-ColoredText (" " * $descPadding) "Gray" -NoNewline
        Write-ColoredText "║" "DarkCyan"
    }
    
    Write-ColoredText "╚═══════════════════════════════════════════════════════════════════════════════╝" "DarkCyan"
    
    Write-Progress -Activity "MultiMessageCopy Setup" -Status "Step $global:StepCounter/$global:TotalSteps - $Title" -PercentComplete $progressPercent
    Write-Host ""
}

function Write-Banner {
    Clear-Host
    Write-Host ""
    
    # ASCII Art Banner
    Write-ColoredText "    ███╗   ███╗██╗   ██╗██╗  ████████╗██╗    ███╗   ███╗███████╗███████╗███████╗ █████╗  ██████╗ ███████╗" "Cyan"
    Write-ColoredText "    ████╗ ████║██║   ██║██║  ╚══██╔══╝██║    ████╗ ████║██╔════╝██╔════╝██╔════╝██╔══██╗██╔════╝ ██╔════╝" "Cyan"
    Write-ColoredText "    ██╔████╔██║██║   ██║██║     ██║   ██║    ██╔████╔██║█████╗  ███████╗███████╗███████║██║  ███╗█████╗  " "Cyan"
    Write-ColoredText "    ██║╚██╔╝██║██║   ██║██║     ██║   ██║    ██║╚██╔╝██║██╔══╝  ╚════██║╚════██║██╔══██║██║   ██║██╔══╝  " "Cyan"
    Write-ColoredText "    ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ██║    ██║ ╚═╝ ██║███████╗███████║███████║██║  ██║╚██████╔╝███████╗" "Cyan"
    Write-ColoredText "    ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝   ╚═╝    ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝" "Cyan"
    Write-Host ""
    
    # Title Box
    Write-ColoredText "╔══════════════════════════════════════════════════════════════════════════════════════════════════════════╗" "DarkCyan"
    Write-ColoredText "║                                                                                                          ║" "DarkCyan"
    Write-ColoredText "║" "DarkCyan" -NoNewline
    Write-ColoredText "                      🚀 MULTIMESSAGECOPY SETUP WIZARD v$global:ScriptVersion 🚀                      " "White" -NoNewline
    Write-ColoredText "║" "DarkCyan"
    Write-ColoredText "║                                                                                                          ║" "DarkCyan"
    Write-ColoredText "║" "DarkCyan" -NoNewline
    Write-ColoredText "              Advanced Discord Plugin Installation & Configuration Tool              " "Gray" -NoNewline
    Write-ColoredText "║" "DarkCyan"
    Write-ColoredText "║                                                                                                          ║" "DarkCyan"
    Write-ColoredText "║" "DarkCyan" -NoNewline
    Write-ColoredText "                           Created by tsx-awtns | Enhanced Edition                           " "DarkGray" -NoNewline
    Write-ColoredText "║" "DarkCyan"
    Write-ColoredText "║                                                                                                          ║" "DarkCyan"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════╝" "DarkCyan"
    Write-Host ""
    
    # Quick Info
    Write-ColoredText "📋 WHAT THIS SCRIPT DOES:" "Yellow"
    Write-ColoredText "   • Installs Node.js, Git, and pnpm (if needed)" "White"
    Write-ColoredText "   • Downloads and sets up Vencord Discord client modification" "White"
    Write-ColoredText "   • Installs the MultiMessageCopy plugin for enhanced Discord functionality" "White"
    Write-ColoredText "   • Builds and optionally injects Vencord into your Discord client" "White"
    Write-Host ""
    
    Write-ColoredText "⚠️  IMPORTANT NOTES:" "Red"
    Write-ColoredText "   • This modifies your Discord client - use at your own risk" "Yellow"
    Write-ColoredText "   • Make sure Discord is closed before injection" "Yellow"
    Write-ColoredText "   • Administrator privileges recommended for smooth installation" "Yellow"
    Write-Host ""
}

function Show-Help {
    Write-Banner
    Write-ColoredText "╔══════════════════════════════════════════════════════════════════════════════════════════════════════════╗" "DarkCyan"
    Write-ColoredText "║                                          USAGE GUIDE                                                   ║" "White"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════╝" "DarkCyan"
    Write-Host ""
    
    Write-ColoredText "📝 BASIC USAGE:" "Green"
    Write-ColoredText "   .\setup.ps1                    " "White" -NoNewline
    Write-ColoredText "# Run with default settings" "Gray"
    Write-Host ""
    
    Write-ColoredText "🔧 AVAILABLE OPTIONS:" "Green"
    Write-Host ""
    Write-ColoredText "   -SkipNodeInstall               " "Cyan" -NoNewline
    Write-ColoredText "Skip Node.js installation (if already installed)" "Gray"
    Write-ColoredText "   -SkipGitInstall                " "Cyan" -NoNewline  
    Write-ColoredText "Skip Git installation (if already installed)" "Gray"
    Write-ColoredText "   -VencordPath <path>            " "Cyan" -NoNewline
    Write-ColoredText "Custom installation directory for Vencord" "Gray"
    Write-ColoredText "   -Verbose                       " "Cyan" -NoNewline
    Write-ColoredText "Enable detailed debug output" "Gray"
    Write-ColoredText "   -NoPrompts                     " "Cyan" -NoNewline
    Write-ColoredText "Run in unattended mode (use defaults)" "Gray"
    Write-ColoredText "   -Help                          " "Cyan" -NoNewline
    Write-ColoredText "Show this help message" "Gray"
    Write-Host ""
    
    Write-ColoredText "💡 EXAMPLES:" "Green"
    Write-Host ""
    Write-ColoredText "   .\setup.ps1 -VencordPath C:\MyApps\Vencord -Verbose" "Yellow"
    Write-ColoredText "   .\setup.ps1 -SkipNodeInstall -SkipGitInstall" "Yellow"
    Write-ColoredText "   .\setup.ps1 -NoPrompts" "Yellow"
    Write-Host ""
    
    Write-ColoredText "🌐 LINKS:" "Green"
    Write-ColoredText "   Plugin Repository: " "White" -NoNewline
    Write-ColoredText "https://github.com/tsx-awtns/MultiMessageCopy" "Blue"
    Write-ColoredText "   Vencord Project:   " "White" -NoNewline
    Write-ColoredText "https://github.com/Vendicated/Vencord" "Blue"
    Write-ColoredText "   Report Issues:     " "White" -NoNewline
    Write-ColoredText "https://github.com/tsx-awtns/MultiMessageCopy/issues" "Blue"
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════════
#                              UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

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

function Get-CommandVersion($Command) {
    try {
        switch ($Command.ToLower()) {
            "node" { return (node --version) }
            "git" { return (git --version) }
            "npm" { return (npm --version) }
            "pnpm" { return (pnpm --version) }
            default { return "Unknown" }
        }
    } catch {
        return "Not Found"
    }
}

function Update-SessionPath {
    Write-Debug "Refreshing environment variables..."
    try {
        $machinePath = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Control\Session Manager\Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $userPath = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Environment").GetValue("PATH", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $machinePath = [System.Environment]::ExpandEnvironmentVariables($machinePath)
        $userPath = [System.Environment]::ExpandEnvironmentVariables($userPath)
        $env:PATH = $machinePath + ";" + $userPath
        
        $commonPaths = @(
            "${env:ProgramFiles}\nodejs", 
            "${env:ProgramFiles(x86)}\nodejs", 
            "$env:APPDATA\npm",
            "${env:ProgramFiles}\Git\bin",
            "${env:ProgramFiles(x86)}\Git\bin"
        )
        
        foreach ($path in $commonPaths) {
            if ((Test-Path $path) -and ($env:PATH -notlike "*$path*")) { 
                $env:PATH += ";$path"
                Write-Debug "Added to PATH: $path"
            }
        }
        Write-Debug "PATH refresh completed successfully"
    } catch {
        Write-Debug "PATH refresh failed: $($_.Exception.Message)"
    }
}

function Get-UserChoice($Prompt, $DefaultChoice = "Y", $ValidChoices = @("Y", "N")) {
    if ($NoPrompts) {
        Write-Info "Auto-selecting: $DefaultChoice (NoPrompts mode)"
        return $DefaultChoice
    }
    
    do {
        Write-Host ""
        Write-ColoredText "❓ QUESTION: " "Yellow" -NoNewline
        Write-ColoredText "$Prompt" "White"
        
        Write-ColoredText "   Available options: " "Gray" -NoNewline
        for ($i = 0; $i -lt $ValidChoices.Length; $i++) {
            if ($ValidChoices[$i] -eq $DefaultChoice) {
                Write-ColoredText "[$($ValidChoices[$i])]" "Green" -NoNewline
            } else {
                Write-ColoredText " $($ValidChoices[$i]) " "White" -NoNewline
            }
            if ($i -lt $ValidChoices.Length - 1) { 
                Write-ColoredText "/" "Gray" -NoNewline 
            }
        }
        Write-Host ""
        Write-ColoredText "   Your choice (Enter for default): " "Cyan" -NoNewline
        
        $choice = Read-Host
        if ([string]::IsNullOrWhiteSpace($choice)) { 
            $choice = $DefaultChoice 
        }
        $choice = $choice.ToUpper()
        
        if ($ValidChoices -contains $choice) { 
            return $choice 
        }
        Write-Warning "Invalid choice '$choice'. Please try again."
    } while ($true)
}

function Get-UserPath($Prompt, $DefaultPath, $Example = "") {
    if ($NoPrompts) {
        Write-Info "Using default path: $DefaultPath (NoPrompts mode)"
        return $DefaultPath
    }
    
    Write-Host ""
    Write-ColoredText "📁 PATH SELECTION: " "Yellow" -NoNewline
    Write-ColoredText "$Prompt" "White"
    Write-Host ""
    Write-ColoredText "   Default location: " "Gray" -NoNewline
    Write-ColoredText "$DefaultPath" "Green"
    
    if ($Example) {
        Write-ColoredText "   Example:          " "Gray" -NoNewline
        Write-ColoredText "$Example" "Yellow"
    }
    
    Write-Host ""
    Write-ColoredText "   Enter custom path or press Enter for default: " "Cyan" -NoNewline
    $userInput = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        Write-Info "Using default path: $DefaultPath"
        return $DefaultPath
    }
    
    $userInput = $userInput.Trim('"').Trim("'").Trim()
    Write-Info "Using custom path: $userInput"
    return $userInput
}

function Show-SystemInfo {
    Write-ColoredText "🖥️  SYSTEM INFORMATION:" "Magenta"
    Write-ColoredText "   OS Version:        $([System.Environment]::OSVersion.VersionString)" "Gray"
    Write-ColoredText "   PowerShell:        $($PSVersionTable.PSVersion)" "Gray"
    Write-ColoredText "   Architecture:      $([System.Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE'))" "Gray"
    Write-ColoredText "   User:              $([System.Environment]::UserName)" "Gray"
    Write-ColoredText "   Admin Rights:      $(if (Test-Administrator) { 'Yes ✓' } else { 'No ✗' })" "Gray"
    Write-Host ""
}

function Show-PreInstallationSummary($NodeStatus, $GitStatus, $PnpmStatus, $VencordPath) {
    Write-Host ""
    Write-ColoredText "╔══════════════════════════════════════════════════════════════════════════════════════════════════════════╗" "DarkCyan"
    Write-ColoredText "║                                    PRE-INSTALLATION SUMMARY                                             ║" "White"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════╝" "DarkCyan"
    Write-Host ""
    
    Write-ColoredText "📦 DEPENDENCY STATUS:" "Yellow"
    if ($NodeStatus.Installed) { 
        Write-Success "Node.js - Already installed ($($NodeStatus.Version))"
    } else { 
        Write-Warning "Node.js - Will be installed"
    }
    
    if ($GitStatus.Installed) { 
        Write-Success "Git - Already installed ($($GitStatus.Version))"
    } else { 
        Write-Warning "Git - Will be installed"
    }
    
    if ($PnpmStatus.Installed) { 
        Write-Success "pnpm - Already installed ($($PnpmStatus.Version))"
    } else { 
        Write-Warning "pnpm - Will be installed"
    }
    
    Write-Host ""
    Write-ColoredText "📍 INSTALLATION TARGET:" "Yellow"
    Write-Info "Vencord will be installed to: $VencordPath"
    
    $requiredSpace = 500 # MB
    try {
        $drive = [System.IO.Path]::GetPathRoot($VencordPath)
        $freeSpace = [math]::Round((Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $drive.TrimEnd('\') }).FreeSpace / 1MB)
        Write-Info "Available disk space: $freeSpace MB (Required: $requiredSpace MB)"
        
        if ($freeSpace -lt $requiredSpace) {
            Write-Warning "Low disk space detected! Installation may fail."
        }
    } catch {
        Write-Debug "Could not check disk space"
    }
    
    Write-Host ""
}

function Show-InstallationProgress($Activity, $Status, $Percent) {
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $Percent
    Write-ColoredText "    ⏳ " "Yellow" -NoNewline
    Write-ColoredText "$Status" "White"
}

function Show-CompletionSummary($VencordPath, $ElapsedTime, $InjectionCompleted) {
    Write-Host ""
    Write-ColoredText "╔══════════════════════════════════════════════════════════════════════════════════════════════════════════╗" "Green"
    Write-ColoredText "║                                    🎉 INSTALLATION COMPLETE! 🎉                                       ║" "White"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════╝" "Green"
    Write-Host ""
    
    Write-ColoredText "✅ SUCCESS SUMMARY:" "Green"
    Write-Success "MultiMessageCopy plugin has been installed successfully"
    Write-Success "Vencord has been built with the plugin integrated"
    if ($InjectionCompleted) {
        Write-Success "Vencord has been injected into Discord"
    } else {
        Write-Warning "Vencord injection was skipped - you can inject manually later"
    }
    
    Write-Host ""
    Write-ColoredText "📊 STATISTICS:" "Cyan"
    Write-Info "Installation completed in: $ElapsedTime"
    Write-Info "Installation location: $VencordPath"
    Write-Info "Plugin files: $(Join-Path $VencordPath 'src\userplugins\MultiMessageCopy')"
    
    Write-Host ""
    Write-ColoredText "🚀 NEXT STEPS - IMPORTANT!" "Yellow"
    Write-ColoredText "   1. " "White" -NoNewline
    Write-ColoredText "RESTART DISCORD COMPLETELY" "Red"
    Write-ColoredText "      • Close Discord from system tray" "Gray"
    Write-ColoredText "      • Wait 5 seconds, then reopen Discord" "Gray"
    Write-Host ""
    Write-ColoredText "   2. " "White" -NoNewline
    Write-ColoredText "ENABLE THE PLUGIN" "Yellow"
    Write-ColoredText "      • Go to: Settings → Vencord → Plugins" "Gray"
    Write-ColoredText "      • Find 'MultiMessageCopy' in the list" "Gray"
    Write-ColoredText "      • Toggle it ON (green switch)" "Gray"
    Write-Host ""
    Write-ColoredText "   3. " "White" -NoNewline
    Write-ColoredText "START USING THE PLUGIN" "Green"
    Write-ColoredText "      • Select multiple messages in any Discord channel" "Gray"
    Write-ColoredText "      • Right-click and look for copy options" "Gray"
    Write-ColoredText "      • Enjoy enhanced message copying features!" "Gray"
    
    Write-Host ""
    Write-ColoredText "🔗 USEFUL LINKS:" "Cyan"
    Write-ColoredText "   📚 Plugin Documentation: " "White" -NoNewline
    Write-ColoredText "https://github.com/tsx-awtns/MultiMessageCopy" "Blue"
    Write-ColoredText "   🐛 Report Issues:         " "White" -NoNewline
    Write-ColoredText "https://github.com/tsx-awtns/MultiMessageCopy/issues" "Blue"
    Write-ColoredText "   💬 Discord Support:       " "White" -NoNewline
    Write-ColoredText "https://discord.gg/vencord" "Blue"
    
    if (!$InjectionCompleted) {
        Write-Host ""
        Write-ColoredText "⚙️  MANUAL INJECTION (if needed):" "Yellow"
        Write-ColoredText "   If Discord doesn't show Vencord settings:" "Gray"
        Write-ColoredText "   1. Open PowerShell as Administrator" "Gray"
        Write-ColoredText "   2. Navigate to: $VencordPath" "Gray"
        Write-ColoredText "   3. Run: pnpm inject" "Gray"
    }
    
    Write-Host ""
    Write-ColoredText "Thank you for using MultiMessageCopy! 🙏" "Green"
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════════
#                              MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

if ($Help) { 
    Show-Help
    exit 0 
}

Write-Banner
Show-SystemInfo

try {
    # ═══════════════════════════════════════════════════════════════════════════
    #                              STEP 1: PREREQUISITES CHECK
    # ═══════════════════════════════════════════════════════════════════════════
    
    Write-StepHeader "Prerequisites Check" "Verifying system requirements and permissions"
    
    if (!(Test-Administrator)) {
        Write-Warning "Script is not running with Administrator privileges"
        Write-Info "Some installations might require elevated permissions"
        Write-Info "Consider running PowerShell as Administrator for best results"
        
        $continue = Get-UserChoice "Do you want to continue anyway?" "Y" @("Y", "N")
        if ($continue -eq "N") { 
            Write-Info "Setup cancelled by user. Restart as Administrator for optimal experience."
            exit 0 
        }
    } else {
        Write-Success "Running with Administrator privileges"
    }
    
    Write-Info "Checking PowerShell execution policy..."
    $executionPolicy = Get-ExecutionPolicy
    Write-Debug "Current execution policy: $executionPolicy"
    
    if ($executionPolicy -eq "Restricted") {
        Write-Warning "PowerShell execution policy is restricted"
        Write-Info "You may need to run: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    } else {
        Write-Success "PowerShell execution policy allows script execution"
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #                              STEP 2: DEPENDENCY ANALYSIS
    # ═══════════════════════════════════════════════════════════════════════════
    
    Write-StepHeader "Dependency Analysis" "Scanning for required tools and versions"
    
    Write-Info "Scanning system for existing installations..."
    Update-SessionPath
    
    # Check Node.js
    $nodeStatus = @{
        Installed = Test-Command "node"
        Version = if (Test-Command "node") { Get-CommandVersion "node" } else { "Not Installed" }
        Required = !$SkipNodeInstall
    }
    
    # Check Git  
    $gitStatus = @{
        Installed = Test-Command "git"
        Version = if (Test-Command "git") { Get-CommandVersion "git" } else { "Not Installed" }
        Required = !$SkipGitInstall
    }
    
    # Check pnpm
    $pnpmStatus = @{
        Installed = Test-Command "pnpm"
        Version = if (Test-Command "pnpm") { Get-CommandVersion "pnpm" } else { "Not Installed" }
        Required = $true
    }
    
    # Get installation path
    if ([string]::IsNullOrEmpty($VencordPath)) {
        $defaultPath = Join-Path $env:USERPROFILE "Desktop\Vencord"
        $VencordPath = Get-UserPath "Where should Vencord be installed?" $defaultPath "C:\MyPrograms\Vencord"
    }
    
    Show-PreInstallationSummary $nodeStatus $gitStatus $pnpmStatus $VencordPath
    
    if (!$NoPrompts) {
        $proceed = Get-UserChoice "Proceed with installation?" "Y" @("Y", "N")
        if ($proceed -eq "N") {
            Write-Info "Installation cancelled by user"
            exit 0
        }
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #                              STEP 3: NODE.JS INSTALLATION
    # ═══════════════════════════════════════════════════════════════════════════
    
    $nodeInstalled = $false
    if (!$SkipNodeInstall) {
        Write-StepHeader "Node.js Installation" "Installing JavaScript runtime environment"
        
        Update-SessionPath
        
        if ($nodeStatus.Installed) {
            Write-Success "Node.js is already installed: $($nodeStatus.Version)"
            $nodeInstalled = $true
        } else {
            Write-Info "Downloading and installing Node.js LTS version..."
            $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
            $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
            
            try {
                Show-InstallationProgress "Node.js Installation" "Downloading installer..." 20
                Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
                
                Show-InstallationProgress "Node.js Installation" "Installing Node.js..." 60
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
                
                if ($process.ExitCode -eq 0) {
                    Show-InstallationProgress "Node.js Installation" "Verifying installation..." 90
                    Start-Sleep -Seconds 3
                    Update-SessionPath
                    
                    if (Test-Command "node") {
                        $version = Get-CommandVersion "node"
                        Write-Success "Node.js installed successfully: $version"
                        $nodeInstalled = $true
                    } else {
                        Write-Error "Node.js installation completed but command not found in PATH"
                    }
                } else {
                    Write-Error "Node.js installer returned error code: $($process.ExitCode)"
                }
                
                Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Error "Node.js installation failed: $($_.Exception.Message)"
                Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            }
        }
        
        if (!$nodeInstalled) {
            Write-Error "Node.js is required for this installation"
            Write-Info "Please install Node.js manually from: https://nodejs.org/"
            Write-Info "Then restart PowerShell and run this script again"
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        $nodeInstalled = Test-Command "node"
        Write-Info "Node.js installation skipped (SkipNodeInstall flag)"
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #                              STEP 4: GIT INSTALLATION
    # ═══════════════════════════════════════════════════════════════════════════
    
    $gitInstalled = $false
    if (!$SkipGitInstall) {
        Write-StepHeader "Git Installation" "Installing version control system"
        
        Update-SessionPath
        
        if ($gitStatus.Installed) {
            Write-Success "Git is already installed: $($gitStatus.Version)"
            $gitInstalled = $true
        } else {
            Write-Info "Downloading and installing Git for Windows..."
            $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
            $gitInstaller = "$env:TEMP\git-installer.exe"
            
            try {
                Show-InstallationProgress "Git Installation" "Downloading installer..." 20
                Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
                
                Show-InstallationProgress "Git Installation" "Installing Git..." 60
                Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
                
                Show-InstallationProgress "Git Installation" "Verifying installation..." 90
                Update-SessionPath
                
                if (Test-Command "git") {
                    $version = Get-CommandVersion "git"
                    Write-Success "Git installed successfully: $version"
                    $gitInstalled = $true
                } else {
                    Write-Warning "Git installation completed but command not found in PATH"
                    Write-Info "You may need to restart PowerShell for Git to be available"
                }
                
                Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Git installation failed: $($_.Exception.Message)"
                Write-Info "Git is recommended but not strictly required"
                Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        $gitInstalled = Test-Command "git"
        Write-Info "Git installation skipped (SkipGitInstall flag)"
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #                              STEP 5: PNPM INSTALLATION
    # ═══════════════════════════════════════════════════════════════════════════
    
    Write-StepHeader "Package Manager Setup" "Installing pnpm package manager"
    
    Update-SessionPath
    
    $pnpmInstalled = $false
    if ($pnpmStatus.Installed) {
        Write-Success "pnpm is already installed: $($pnpmStatus.Version)"
        $pnpmInstalled = $true
    } else {
        if (Test-Command "npm") {
            Write-Info "Installing pnpm via npm..."
            try {
                Show-InstallationProgress "pnpm Installation" "Installing pnpm globally..." 50
                $npmProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
                
                if ($npmProcess.ExitCode -eq 0) {
                    Show-InstallationProgress "pnpm Installation" "Verifying installation..." 90
                    Update-SessionPath
                    Start-Sleep -Seconds 2
                    
                    if (Test-Command "pnpm") {
                        $version = Get-CommandVersion "pnpm"
                        Write-Success "pnpm installed successfully: $version"
                        $pnpmInstalled = $true
                    } else {
                        Write-Error "pnpm installation completed but command not found"
                    }
                } else {
                    Write-Error "npm returned error code: $($npmProcess.ExitCode)"
                }
            } catch {
                Write-Error "pnpm installation failed: $($_.Exception.Message)"
            }
        } else {
            Write-Error "npm is not available - Node.js installation may have failed"
        }
    }
    
    if (!$pnpmInstalled) {
        Write-Error "pnpm is required for building Vencord"
        Write-Info "Please restart PowerShell and try again"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #                              STEP 6: VENCORD SETUP
    # ═══════════════════════════════════════════════════════════════════════════
    
    Write-StepHeader "Vencord Repository Setup" "Cloning and preparing Vencord source code"
    
    $vencordDir = $null
    try {
        if (Test-Path "$VencordPath\package.json") {
            $packageContent = Get-Content "$VencordPath\package.json" -Raw | ConvertFrom-Json
            if ($packageContent.name -eq "vencord") {
                Write-Success "Found existing Vencord installation at: $VencordPath"
                $vencordDir = $VencordPath
            }
        }
        
        if (!$vencordDir) {
            Write-Info "Cloning Vencord repository from GitHub..."
            $parentDir = Split-Path $VencordPath -Parent
            
            Show-InstallationProgress "Vencord Setup" "Preparing directories..." 20
            if (!(Test-Path $parentDir)) { 
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null 
                Write-Debug "Created parent directory: $parentDir"
            }
            
            if (Test-Path $VencordPath) { 
                Write-Warning "Existing directory found - removing: $VencordPath"
                Remove-Item $VencordPath -Recurse -Force 
            }
            
            Show-InstallationProgress "Vencord Setup" "Cloning repository (this may take a moment)..." 60
            $currentLocation = Get-Location
            Set-Location $parentDir
            $targetDirName = Split-Path $VencordPath -Leaf
            
            Write-Debug "Cloning to: $targetDirName"
            git clone https://github.com/Vendicated/Vencord.git $targetDirName
            Set-Location $currentLocation
            
            Show-InstallationProgress "Vencord Setup" "Verifying installation..." 90
            if (Test-Path "$VencordPath\package.json") {
                Write-Success "Vencord repository cloned successfully"
                $vencordDir = $VencordPath
            } else {
                throw "Repository clone failed - package.json not found"
            }
        }
    } catch {
        Write-Error "Vencord setup failed: $($_.Exception.Message)"
        Write-Info "Please check your internet connection and Git installation"
    }
    
    if (!$vencordDir) {
        Write-Error "Cannot continue without Vencord source code"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #                              STEP 7: PLUGIN INSTALLATION
    # ═══════════════════════════════════════════════════════════════════════════
    
    Write-StepHeader "Plugin Installation" "Installing MultiMessageCopy plugin"
    
    try {
        $userPluginsPath = Join-Path $vencordDir "src\userplugins"
        $pluginPath = Join-Path $userPluginsPath "MultiMessageCopy"
        
        Show-InstallationProgress "Plugin Installation" "Preparing plugin directory..." 20
        if (!(Test-Path $userPluginsPath)) { 
            New-Item -ItemType Directory -Path $userPluginsPath -Force | Out-Null 
            Write-Info "Created userplugins directory"
        }
        
        if (Test-Path $pluginPath) { 
            Write-Info "Removing existing MultiMessageCopy installation..."
            Remove-Item $pluginPath -Recurse -Force 
        }
        
        Show-InstallationProgress "Plugin Installation" "Downloading plugin from GitHub..." 50
        Write-Info "Cloning MultiMessageCopy plugin repository..."
        
        $currentLocation = Get-Location
        Set-Location $userPluginsPath
        
        Write-Debug "Cloning plugin repository..."
        git clone https://github.com/tsx-awtns/MultiMessageCopy.git temp-plugin
        
        Show-InstallationProgress "Plugin Installation" "Installing plugin files..." 80
        if (Test-Path "temp-plugin\MultiMessageCopyFiles") {
            Move-Item "temp-plugin\MultiMessageCopyFiles" "MultiMessageCopy"
            Remove-Item "temp-plugin" -Recurse -Force
            Write-Success "MultiMessageCopy plugin installed successfully"
            Write-Info "Plugin location: $pluginPath"
        } else {
            throw "Plugin files not found in repository (MultiMessageCopyFiles folder missing)"
        }
        
        Set-Location $currentLocation
    } catch {
        Write-Error "Plugin installation failed: $($_.Exception.Message)"
        Write-Info "You can try cloning manually: https://github.com/tsx-awtns/MultiMessageCopy.git"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #                              STEP 8: BUILD AND FINALIZATION
    # ═══════════════════════════════════════════════════════════════════════════
    
    Write-StepHeader "Build Process" "Building Vencord with MultiMessageCopy plugin"
    
    try {
        $currentLocation = Get-Location
        Set-Location $vencordDir
        
        Write-Info "Installing Vencord dependencies (this may take several minutes)..."
        Show-InstallationProgress "Build Process" "Installing dependencies..." 20
        pnpm install
        
        Write-Info "Building Vencord with integrated MultiMessageCopy plugin..."
        Show-InstallationProgress "Build Process" "Compiling project..." 70
        pnpm build
        
        Set-Location $currentLocation
        Write-Success "Vencord build completed successfully"
    } catch {
        Write-Error "Build process failed: $($_.Exception.Message)"
        Write-Info "Check the error messages above for more details"
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Discord injection
    $injectionCompleted = $false
    $inject = Get-UserChoice "Do you want to inject Vencord into Discord now?" "Y" @("Y", "N")
    
    if ($inject -eq "Y") {
        Write-Info "Injecting Vencord into Discord..."
        Write-Warning "Make sure Discord is completely closed before proceeding!"
        
        try {
            $currentLocation = Get-Location
            Set-Location $vencordDir
            
            Show-InstallationProgress "Discord Integration" "Injecting Vencord..." 50
            pnpm inject
            
            Set-Location $currentLocation
            Write-Success "Vencord injection completed successfully"
            $injectionCompleted = $true
        } catch {
            Write-Warning "Injection failed: $($_.Exception.Message)"
            Write-Info "You can inject manually later by running 'pnpm inject' in: $vencordDir"
        }
    } else {
        Write-Info "Vencord injection skipped - you can inject manually later"
    }

    # ═══════════════════════════════════════════════════════════════════════════
    #                              COMPLETION
    # ═══════════════════════════════════════════════════════════════════════════
    
    $endTime = Get-Date
    $elapsedTime = $endTime - $global:StartTime
    $formattedTime = "{0:mm\:ss}" -f $elapsedTime
    
    Show-CompletionSummary $vencordDir $formattedTime $injectionCompleted
    
    Read-Host "Press Enter to exit"

} catch {
    Write-Host ""
    Write-ColoredText "╔══════════════════════════════════════════════════════════════════════════════════════════════════════════╗" "Red"
    Write-ColoredText "║                                    ❌ INSTALLATION FAILED ❌                                            ║" "White"
    Write-ColoredText "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════╝" "Red"
    Write-Host ""
    
    Write-Error "Setup failed with error: $($_.Exception.Message)"
    Write-Host ""
    Write-ColoredText "🔍 TROUBLESHOOTING TIPS:" "Yellow"
    Write-ColoredText "   • Make sure you have a stable internet connection" "Gray"
    Write-ColoredText "   • Try running PowerShell as Administrator" "Gray"
    Write-ColoredText "   • Ensure Discord is completely closed" "Gray"
    Write-ColoredText "   • Check Windows Defender/Antivirus isn't blocking the installation" "Gray"
    Write-ColoredText "   • Verify you have enough disk space" "Gray"
    Write-Host ""
    Write-ColoredText "📞 GET HELP:" "Cyan"
    Write-ColoredText "   Report issues: https://github.com/tsx-awtns/MultiMessageCopy/issues" "Blue"
    Write-Host ""
    
    Read-Host "Press Enter to exit"
    exit 1
}
