# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MultiMessageCopy Setup Script v2.1 - Fixed Edition
# 📧 Author: tsx-awtns
# 🌐 Repository: https://github.com/tsx-awtns/MultiMessageCopy
# ═══════════════════════════════════════════════════════════════════════════════

param(
    [switch]$SkipNodeInstall,
    [switch]$SkipGitInstall, 
    [string]$VencordPath = "",
    [switch]$Help,
    [switch]$Verbose
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 STYLING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Write-Success($Message) { 
    Write-Host " [OK] " -ForegroundColor Green -NoNewline
    Write-Host "$Message" -ForegroundColor White 
}

function Write-Warning($Message) { 
    Write-Host " [!] " -ForegroundColor Yellow -NoNewline
    Write-Host "$Message" -ForegroundColor Yellow 
}

function Write-Error($Message) { 
    Write-Host " [X] " -ForegroundColor Red -NoNewline
    Write-Host "$Message" -ForegroundColor Red 
}

function Write-Info($Message) { 
    Write-Host " [i] " -ForegroundColor Cyan -NoNewline
    Write-Host "$Message" -ForegroundColor White 
}

function Write-Progress($Message) { 
    Write-Host " [~] " -ForegroundColor Blue -NoNewline
    Write-Host "$Message" -ForegroundColor Blue 
}

function Write-Download($Message) { 
    Write-Host " [↓] " -ForegroundColor Magenta -NoNewline
    Write-Host "$Message" -ForegroundColor White 
}

function Write-Install($Message) { 
    Write-Host " [+] " -ForegroundColor Green -NoNewline
    Write-Host "$Message" -ForegroundColor White 
}

function Write-Build($Message) { 
    Write-Host " [#] " -ForegroundColor Yellow -NoNewline
    Write-Host "$Message" -ForegroundColor White 
}

function Write-StepHeader($StepNumber, $TotalSteps, $Title, $Description) {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ STEP $StepNumber/$TotalSteps: $Title" -ForegroundColor White
    Write-Host "║ $Description" -ForegroundColor Gray
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "║                                                                               ║" -ForegroundColor DarkCyan
    Write-Host "║  __  __ _   _ _   _____ ___ __  __ _____ ____ ____    _    ____ _____         ║" -ForegroundColor Cyan
    Write-Host "║ |  \/  | | | | | |_   _|_ _|  \/  | ____/ ___/ ___|  / \  / ___| ____|        ║" -ForegroundColor Cyan
    Write-Host "║ | |\/| | | | | | | | |  | || |\/| |  _| \___ \___ \ / _ \| |  _|  _|        ║" -ForegroundColor Cyan
    Write-Host "║ | |  | | |_| | |_| | | |  | || |  | | |___ ___) |__) / ___ \ |_| | |___       ║" -ForegroundColor Cyan
    Write-Host "║ |_|  |_|\___/ \___/  |_| |___|_|  |_|_____|____/____/_/   \_\____|_____|       ║" -ForegroundColor Cyan
    Write-Host "║                                                                               ║" -ForegroundColor DarkCyan
    Write-Host "║                        COPY PLUGIN SETUP                                     ║" -ForegroundColor White
    Write-Host "║                                                                               ║" -ForegroundColor DarkCyan
    Write-Host "║                   Ultimate Installation Script v2.1                         ║" -ForegroundColor Yellow
    Write-Host "║                            by tsx-awtns                                      ║" -ForegroundColor Gray
    Write-Host "║                                                                               ║" -ForegroundColor DarkCyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host " [*] " -ForegroundColor Green -NoNewline
    Write-Host "This script will automatically install and configure MultiMessageCopy for Vencord" -ForegroundColor White
    Write-Host " [*] " -ForegroundColor Blue -NoNewline
    Write-Host "Features: Auto-download dependencies, Clone repositories, Build & inject Vencord" -ForegroundColor Gray
    Write-Host ""
}

function Show-Help {
    Write-Banner
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║                                 HELP & USAGE                                 ║" -ForegroundColor White
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "SYNTAX:" -ForegroundColor Cyan
    Write-Host "  .\setup.ps1 [PARAMETERS]" -ForegroundColor White
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Cyan
    Write-Host "  -SkipNodeInstall    Skip automatic Node.js installation" -ForegroundColor Gray
    Write-Host "  -SkipGitInstall     Skip automatic Git installation" -ForegroundColor Gray
    Write-Host "  -VencordPath        Specify custom installation directory" -ForegroundColor Gray
    Write-Host "  -Verbose            Enable detailed logging output" -ForegroundColor Gray
    Write-Host "  -Help               Display this help information" -ForegroundColor Gray
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  .\setup.ps1                                    # Standard installation" -ForegroundColor White
    Write-Host "  .\setup.ps1 -VencordPath C:\MyApps\Vencord    # Custom path" -ForegroundColor White
    Write-Host "  .\setup.ps1 -SkipNodeInstall -Verbose         # Skip Node.js, verbose mode" -ForegroundColor White
    Write-Host ""
    Write-Host "MORE INFO:" -ForegroundColor Cyan
    Write-Host "  GitHub: https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor Blue
    Write-Host "  Issues: https://github.com/tsx-awtns/MultiMessageCopy/issues" -ForegroundColor Blue
    Write-Host ""
}

if ($Help) { 
    Show-Help
    Read-Host "Press Enter to exit"
    exit 0 
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔧 UTILITY FUNCTIONS
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
        if ($Verbose) {
            Write-Info "Environment PATH updated successfully"
        }
    } catch {
        if ($Verbose) {
            Write-Warning "Failed to update environment PATH: $($_.Exception.Message)"
        }
    }
}

function Get-UserChoice($Prompt, $DefaultChoice = "Y", $Options = @("Y", "N")) {
    do {
        Write-Host ""
        Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Yellow
        Write-Host "│ USER INPUT REQUIRED                                                         │" -ForegroundColor White
        Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Yellow
        Write-Host "│ $Prompt" -ForegroundColor White
        Write-Host "│ Available options: " -ForegroundColor Gray -NoNewline
        
        for ($i = 0; $i -lt $Options.Length; $i++) {
            if ($Options[$i] -eq $DefaultChoice) {
                Write-Host "[$($Options[$i])]" -ForegroundColor Green -NoNewline
            } else {
                Write-Host " $($Options[$i]) " -ForegroundColor White -NoNewline
            }
            if ($i -lt $Options.Length - 1) { 
                Write-Host "/" -ForegroundColor Gray -NoNewline 
            }
        }
        Write-Host ""
        Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Yellow
        Write-Host ""
        Write-Host " >> " -ForegroundColor Cyan -NoNewline
        Write-Host "Your choice (press Enter for default [$DefaultChoice]): " -ForegroundColor White -NoNewline
        
        $choice = Read-Host
        if ([string]::IsNullOrWhiteSpace($choice)) { 
            $choice = $DefaultChoice 
        }
        $choice = $choice.ToUpper()
        
        if ($Options -contains $choice) { 
            Write-Host " [*] " -ForegroundColor Green -NoNewline
            Write-Host "Selection confirmed: $choice" -ForegroundColor Green
            return $choice 
        }
        
        Write-Warning "Invalid choice '$choice'. Please select from: $($Options -join ', ')"
        Start-Sleep -Seconds 1
    } while ($true)
}

function Get-UserPath($Prompt, $DefaultPath) {
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor Magenta
    Write-Host "│ PATH CONFIGURATION                                                          │" -ForegroundColor White
    Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor Magenta
    Write-Host "│ $Prompt" -ForegroundColor White
    Write-Host "│ Default: $DefaultPath" -ForegroundColor Green
    Write-Host "│ Example: C:\MyApps\Vencord" -ForegroundColor Yellow
    Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor Magenta
    Write-Host ""
    Write-Host " >> " -ForegroundColor Cyan -NoNewline
    Write-Host "Enter custom path or press Enter for default: " -ForegroundColor White -NoNewline
    
    $userInput = Read-Host
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        Write-Info "Using default installation path: $DefaultPath"
        return $DefaultPath
    }
    
    $userInput = $userInput.Trim('"').Trim("'").Trim()
    Write-Success "Custom installation path selected: $userInput"
    return $userInput
}

function Show-SystemInfo {
    Write-Host ""
    Write-Host "┌─────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
    Write-Host "│ SYSTEM INFORMATION                                                          │" -ForegroundColor White
    Write-Host "├─────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkGray
    
    # OS Info
    $os = Get-CimInstance Win32_OperatingSystem
    Write-Host "│ OS: $($os.Caption) ($($os.Version))" -ForegroundColor White
    Write-Host "│ PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor White
    Write-Host "│ Architecture: $($os.OSArchitecture)" -ForegroundColor White
    Write-Host "│ User: $env:USERNAME" -ForegroundColor White
    
    if (Test-Administrator) {
        Write-Host "│ Admin Rights: Yes [OK]" -ForegroundColor Green
    } else {
        Write-Host "│ Admin Rights: No [!]" -ForegroundColor Yellow
    }
    
    Write-Host "└─────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-ProgressBar($Current, $Total, $Activity) {
    $percent = [math]::Round(($Current / $Total) * 100, 1)
    $barLength = 30
    $filledLength = [math]::Round(($percent / 100) * $barLength)
    $emptyLength = $barLength - $filledLength
    
    $bar = "#" * $filledLength + "-" * $emptyLength
    
    Write-Host " [~] " -ForegroundColor Blue -NoNewline
    Write-Host "Progress: " -ForegroundColor White -NoNewline
    Write-Host "[$bar]" -ForegroundColor Green -NoNewline
    Write-Host " $percent%" -ForegroundColor Yellow -NoNewline
    Write-Host " - $Activity" -ForegroundColor Gray
}

function Show-InstallationSummary($NodeStatus, $GitStatus, $PnpmStatus, $VencordPath) {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║                           INSTALLATION SUMMARY                               ║" -ForegroundColor White
    Write-Host "╠═══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Blue
    
    # Node.js Status
    if ($NodeStatus) { 
        Write-Host "║ [OK] Node.js: Ready and functional                                           ║" -ForegroundColor Green
    } else { 
        Write-Host "║ [X] Node.js: Installation failed or skipped                                  ║" -ForegroundColor Red
    }
    
    # Git Status
    if ($GitStatus) { 
        Write-Host "║ [OK] Git: Ready and functional                                               ║" -ForegroundColor Green
    } else { 
        Write-Host "║ [!] Git: Installation failed or skipped                                     ║" -ForegroundColor Yellow
    }
    
    # pnpm Status
    if ($PnpmStatus) { 
        Write-Host "║ [OK] pnpm: Ready and functional                                             ║" -ForegroundColor Green
    } else { 
        Write-Host "║ [X] pnpm: Installation failed                                               ║" -ForegroundColor Red
    }
    
    # Installation Path
    $pathDisplay = if ($VencordPath.Length -gt 60) { "..." + $VencordPath.Substring($VencordPath.Length - 57) } else { $VencordPath }
    Write-Host "║ [i] Installation Path: $pathDisplay" -ForegroundColor White
    
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════════

Write-Banner
Show-SystemInfo

Write-Host "WHAT THIS SCRIPT DOES:" -ForegroundColor Cyan
Write-Host "   [*] Installs Node.js, Git, and pnpm (if needed)" -ForegroundColor White
Write-Host "   [*] Downloads and sets up Vencord Discord client modification" -ForegroundColor White
Write-Host "   [*] Installs the MultiMessageCopy plugin for enhanced Discord functionality" -ForegroundColor White
Write-Host "   [*] Builds and optionally injects Vencord into your Discord client" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT NOTES:" -ForegroundColor Yellow
Write-Host "   [!] This modifies your Discord client - use at your own risk" -ForegroundColor Yellow
Write-Host "   [!] Make sure Discord is closed before injection" -ForegroundColor Yellow
Write-Host "   [!] Administrator privileges recommended for smooth installation" -ForegroundColor Yellow
Write-Host ""

try {
    $totalSteps = 8
    $currentStep = 0
    
    # Step 1: Administrator Check
    $currentStep++
    Write-StepHeader $currentStep $totalSteps "Administrator Privileges Check" "Verifying user permissions and system access rights"
    
    if (Test-Administrator) {
        Write-Success "Running with Administrator privileges - Full system access available"
        Write-Info "All installations and system modifications will work properly"
    } else {
        Write-Warning "Not running as Administrator - Limited system access"
        Write-Info "Some installations might require manual intervention"
        $continue = Get-UserChoice "Continue with limited privileges?" "Y" @("Y", "N")
        if ($continue -eq "N") { 
            Write-Info "Installation cancelled by user"
            Write-Host ""
            Write-Host " [*] " -ForegroundColor Yellow -NoNewline
            Write-Host "Thank you for using MultiMessageCopy Setup!" -ForegroundColor White
            Write-Host " [*] " -ForegroundColor Blue -NoNewline
            Write-Host "Tip: Run as Administrator for best results" -ForegroundColor Gray
            Read-Host "Press Enter to exit"
            exit 0 
        }
    }

    # Step 2: Node.js Installation
    $currentStep++
    Write-StepHeader $currentStep $totalSteps "Node.js Runtime Environment" "Installing JavaScript runtime required for Vencord development"
    
    $nodeInstalled = $false
    if (!$SkipNodeInstall) {
        Write-Progress "Checking environment variables..." 
        Update-SessionPath
        
        if (Test-Command "node") {
            $version = node --version 2>$null
            Write-Success "Node.js is already installed and working"
            Write-Info "Current version: $version"
            $nodeInstalled = $true
        } else {
            Write-Info "Node.js not found - Starting automatic installation"
            $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
            $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
            
            try {
                Write-Download "Downloading Node.js v20.10.0 from nodejs.org..."
                Show-ProgressBar 1 4 "Downloading installer..."
                Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
                
                Write-Install "Running Node.js installer (silent mode)..."
                Show-ProgressBar 2 4 "Installing Node.js..."
                $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
                
                if ($process.ExitCode -eq 0) {
                    Show-ProgressBar 3 4 "Updating environment..."
                    Start-Sleep -Seconds 3
                    Update-SessionPath
                    
                    Show-ProgressBar 4 4 "Verifying installation..."
                    if (Test-Command "node") {
                        $version = node --version 2>$null
                        Write-Success "Node.js installed successfully!"
                        Write-Info "Installed version: $version"
                        $nodeInstalled = $true
                    } else {
                        Write-Warning "Installation completed but Node.js command not found"
                        Write-Info "You may need to restart PowerShell or add Node.js to PATH manually"
                    }
                } else {
                    Write-Error "Node.js installation failed with exit code: $($process.ExitCode)"
                }
                
                Write-Progress "Cleaning up temporary files..."
                Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
                
            } catch {
                Write-Error "Node.js installation failed: $($_.Exception.Message)"
                Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
            }
        }
        
        if (!$nodeInstalled) {
            Write-Error "Node.js is required for Vencord development and building"
            Write-Info "Please install Node.js manually from: https://nodejs.org/"
            Write-Info "After installation, restart PowerShell and run this script again"
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        Write-Info "Node.js installation skipped by user parameter"
        $nodeInstalled = Test-Command "node"
        if ($nodeInstalled) {
            $version = node --version 2>$null
            Write-Success "Node.js found: $version"
        } else {
            Write-Warning "Node.js not found and installation was skipped"
        }
    }

    # Step 3: Git Installation
    $currentStep++
    Write-StepHeader $currentStep $totalSteps "Git Version Control System" "Installing Git for repository cloning and version management"
    
    $gitInstalled = $false
    if (!$SkipGitInstall) {
        Write-Progress "Refreshing environment variables..."
        Update-SessionPath
        
        if (Test-Command "git") {
            $version = (git --version 2>$null) -replace 'git version ', ''
            Write-Success "Git is already installed and working"
            Write-Info "Current version: $version"
            $gitInstalled = $true
        } else {
            Write-Info "Git not found - Starting automatic installation"
            $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
            $gitInstaller = "$env:TEMP\git-installer.exe"
            
            try {
                Write-Download "Downloading Git for Windows from GitHub..."
                Show-ProgressBar 1 4 "Downloading installer..."
                Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
                
                Write-Install "Running Git installer (silent mode)..."
                Show-ProgressBar 2 4 "Installing Git..."
                Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
                
                Show-ProgressBar 3 4 "Updating environment..."
                Update-SessionPath
                
                Show-ProgressBar 4 4 "Verifying installation..."
                if (Test-Command "git") {
                    $version = (git --version 2>$null) -replace 'git version ', ''
                    Write-Success "Git installed successfully!"
                    Write-Info "Installed version: $version"
                    $gitInstalled = $true
                } else {
                    Write-Warning "Git installation completed but command not found"
                    Write-Info "You may need to restart PowerShell for Git to be available"
                }
                
                Write-Progress "Cleaning up temporary files..."
                Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
                
            } catch {
                Write-Warning "Git installation failed: $($_.Exception.Message)"
                Write-Info "Git is recommended but not strictly required for basic usage"
                Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        Write-Info "Git installation skipped by user parameter"
        $gitInstalled = Test-Command "git"
        if ($gitInstalled) {
            $version = (git --version 2>$null) -replace 'git version ', ''
            Write-Success "Git found: $version"
        } else {
            Write-Warning "Git not found and installation was skipped"
        }
    }

    # Step 4: pnpm Installation
    $currentStep++
    Write-StepHeader $currentStep $totalSteps "pnpm Package Manager" "Installing fast and efficient package manager for JavaScript projects"
    
    Write-Progress "Refreshing environment variables..."
    Update-SessionPath
    
    $pnpmInstalled = $false
    if (Test-Command "pnpm") {
        $version = pnpm --version 2>$null
        Write-Success "pnpm is already installed and working"
        Write-Info "Current version: $version"
        $pnpmInstalled = $true
    } else {
        if (Test-Command "npm") {
            Write-Info "pnpm not found - Installing via npm package manager"
            
            try {
                Show-ProgressBar 1 3 "Installing pnpm via npm..."
                $npmProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "npm", "install", "-g", "pnpm" -Wait -PassThru -NoNewWindow
                
                if ($npmProcess.ExitCode -eq 0) {
                    Show-ProgressBar 2 3 "Updating environment..."
                    Update-SessionPath
                    Start-Sleep -Seconds 2
                    
                    Show-ProgressBar 3 3 "Verifying installation..."
                    if (Test-Command "pnpm") {
                        $version = pnpm --version 2>$null
                        Write-Success "pnpm installed successfully!"
                        Write-Info "Installed version: $version"
                        $pnpmInstalled = $true
                    } else {
                        Write-Warning "pnpm installation completed but command not found"
                    }
                } else {
                    Write-Error "pnpm installation failed with npm exit code: $($npmProcess.ExitCode)"
                }
            } catch {
                Write-Error "pnpm installation failed: $($_.Exception.Message)"
            }
        } else {
            Write-Error "npm package manager not available"
            Write-Info "npm should be included with Node.js installation"
        }
    }
    
    if (!$pnpmInstalled) {
        Write-Error "pnpm package manager is required for Vencord development"
        Write-Info "Please restart PowerShell and try again, or install pnpm manually"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Step 5: Path Configuration
    $currentStep++
    Write-StepHeader $currentStep $totalSteps "Installation Path Configuration" "Selecting destination directory for Vencord installation"
    
    if ([string]::IsNullOrEmpty($VencordPath)) {
        $defaultPath = Join-Path $env:USERPROFILE "Desktop\Vencord"
        Write-Info "No custom path specified - prompting user for installation location"
        $VencordPath = Get-UserPath "Where should Vencord be installed?" $defaultPath
    } else {
        Write-Info "Using path specified in command line parameter: $VencordPath"
    }
    
    Write-Info "Final installation path: $VencordPath"

    # Show Summary
    Show-InstallationSummary $nodeInstalled $gitInstalled $pnpmInstalled $VencordPath

    # Step 6: Vencord Repository Setup
    $currentStep++
    Write-StepHeader $currentStep $totalSteps "Vencord Repository Setup" "Cloning Vencord source code from GitHub and preparing workspace"
    
    $vencordDir = $null
    try {
        if (Test-Path "$VencordPath\package.json") {
            Write-Info "Checking existing directory for Vencord installation..."
            $packageContent = Get-Content "$VencordPath\package.json" -Raw | ConvertFrom-Json
            if ($packageContent.name -eq "vencord") {
                Write-Success "Found existing Vencord installation!"
                Write-Info "Package name: $($packageContent.name)"
                Write-Info "Version: $($packageContent.version)"
                $vencordDir = $VencordPath
            }
        }
        
        if (!$vencordDir) {
            Write-Info "No existing Vencord installation found - cloning fresh repository"
            $parentDir = Split-Path $VencordPath -Parent
            
            Write-Progress "Preparing installation directory..."
            if (!(Test-Path $parentDir)) { 
                Write-Info "Creating parent directory: $parentDir"
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null 
            }
            
            if (Test-Path $VencordPath) { 
                Write-Warning "Removing existing directory: $VencordPath"
                Remove-Item $VencordPath -Recurse -Force 
            }
            
            Write-Download "Cloning Vencord repository from GitHub..."
            Write-Info "Repository URL: https://github.com/Vendicated/Vencord.git"
            
            $currentLocation = Get-Location
            Set-Location $parentDir
            $targetDirName = Split-Path $VencordPath -Leaf
            
            Show-ProgressBar 1 2 "Cloning repository..."
            git clone https://github.com/Vendicated/Vencord.git $targetDirName
            Set-Location $currentLocation
            
            Show-ProgressBar 2 2 "Verifying clone..."
            if (Test-Path "$VencordPath\package.json") {
                $packageContent = Get-Content "$VencordPath\package.json" -Raw | ConvertFrom-Json
                Write-Success "Vencord repository cloned successfully!"
                Write-Info "Package name: $($packageContent.name)"
                Write-Info "Version: $($packageContent.version)"
                $vencordDir = $VencordPath
            } else {
                throw "Repository clone verification failed - package.json not found"
            }
        }
    } catch {
        Write-Error "Vencord repository setup failed: $($_.Exception.Message)"
        Write-Info "Please check your internet connection and Git installation"
    }
    
    if (!$vencordDir) {
        Write-Error "Cannot continue without Vencord source code"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Step 7: Dependencies and Plugin Installation
    $currentStep++
    Write-StepHeader $currentStep $totalSteps "Dependencies & Plugin Installation" "Installing project dependencies and MultiMessageCopy plugin"
    
    # Install Vencord dependencies
    Write-Build "Installing Vencord project dependencies..."
    try {
        $currentLocation = Get-Location
        Set-Location $vencordDir
        
        Show-ProgressBar 1 4 "Running pnpm install..."
        pnpm install
        
        Set-Location $currentLocation
        Write-Success "Vencord dependencies installed successfully"
    } catch {
        Write-Error "Dependencies installation failed: $($_.Exception.Message)"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Install MultiMessageCopy plugin
    Write-Install "Installing MultiMessageCopy plugin..."
    try {
        $userPluginsPath = Join-Path $vencordDir "src\userplugins"
        $pluginPath = Join-Path $userPluginsPath "MultiMessageCopy"
        
        Show-ProgressBar 2 4 "Preparing plugin directory..."
        if (!(Test-Path $userPluginsPath)) { 
            Write-Info "Creating userplugins directory"
            New-Item -ItemType Directory -Path $userPluginsPath -Force | Out-Null 
        }
        
        if (Test-Path $pluginPath) { 
            Write-Info "Removing existing MultiMessageCopy directory"
            Remove-Item $pluginPath -Recurse -Force 
        }
        
        Show-ProgressBar 3 4 "Cloning plugin repository..."
        Write-Download "Downloading MultiMessageCopy plugin from GitHub..."
        
        $currentLocation = Get-Location
        Set-Location $userPluginsPath
        git clone https://github.com/tsx-awtns/MultiMessageCopy.git temp-plugin
        
        Show-ProgressBar 4 4 "Installing plugin files..."
        if (Test-Path "temp-plugin\MultiMessageCopyFiles") {
            Move-Item "temp-plugin\MultiMessageCopyFiles" "MultiMessageCopy"
            Remove-Item "temp-plugin" -Recurse -Force
            Write-Success "MultiMessageCopy plugin installed successfully!"
        } else {
            throw "MultiMessageCopyFiles folder not found in repository"
        }
        Set-Location $currentLocation
    } catch {
        Write-Error "Plugin installation failed: $($_.Exception.Message)"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Step 8: Build and Injection
    $currentStep++
    Write-StepHeader $currentStep $totalSteps "Build & Injection Process" "Compiling Vencord with plugin and injecting into Discord"
    
    # Build Vencord
    Write-Build "Building Vencord with MultiMessageCopy plugin..."
    try {
        $currentLocation = Get-Location
        Set-Location $vencordDir
        
        Show-ProgressBar 1 2 "Compiling project..."
        pnpm build
        
        Set-Location $currentLocation
        Write-Success "Vencord build completed successfully!"
    } catch {
        Write-Error "Build process failed: $($_.Exception.Message)"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Discord Injection
    Show-ProgressBar 2 2 "Preparing injection..."
    $inject = Get-UserChoice "Inject Vencord into Discord now?" "Y" @("Y", "N")
    if ($inject -eq "Y") {
        Write-Install "Injecting Vencord into Discord..."
        Write-Warning "Make sure Discord is closed before injection!"
        
        try {
            $currentLocation = Get-Location
            Set-Location $vencordDir
            pnpm inject
            Set-Location $currentLocation
            Write-Success "Vencord injection completed successfully!"
        } catch {
            Write-Warning "Injection failed - you can run it manually later"
            Write-Info "Navigate to $vencordDir and run: pnpm inject"
        }
    } else {
        Write-Info "Injection skipped - you can run it later with: pnpm inject"
    }

    # Success Screen
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                        INSTALLATION COMPLETED!                               ║" -ForegroundColor White
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Success "MultiMessageCopy plugin has been successfully installed and configured!"
    Write-Host ""
    Write-Host "INSTALLATION DETAILS:" -ForegroundColor Cyan
    Write-Host "   Installation Path: $vencordDir" -ForegroundColor White
    Write-Host "   Plugin Location: $(Join-Path $vencordDir 'src\userplugins\MultiMessageCopy')" -ForegroundColor White
    Write-Host "   Dependencies: All required packages installed" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "   1. Restart Discord completely (close from system tray)" -ForegroundColor White
    Write-Host "   2. Open Discord Settings (User Settings gear icon)" -ForegroundColor White
    Write-Host "   3. Navigate to: Settings > Vencord > Plugins" -ForegroundColor White
    Write-Host "   4. Find and enable 'MultiMessageCopy' plugin" -ForegroundColor White
    Write-Host "   5. Start using the plugin features in Discord!" -ForegroundColor White
    Write-Host ""
    
    if ($inject -eq "N") {
        Write-Host "MANUAL INJECTION REQUIRED:" -ForegroundColor Yellow
        Write-Host "   Navigate to: $vencordDir" -ForegroundColor White
        Write-Host "   Run command: pnpm inject" -ForegroundColor Cyan
        Write-Host ""
    }
    
    Write-Host "USEFUL LINKS:" -ForegroundColor Cyan
    Write-Host "   Repository: https://github.com/tsx-awtns/MultiMessageCopy" -ForegroundColor Blue
    Write-Host "   Report Issues: https://github.com/tsx-awtns/MultiMessageCopy/issues" -ForegroundColor Blue
    Write-Host "   Documentation: https://github.com/tsx-awtns/MultiMessageCopy#readme" -ForegroundColor Blue
    Write-Host ""
    Write-Host "PLUGIN FEATURES:" -ForegroundColor Cyan
    Write-Host "   [*] Copy multiple messages at once" -ForegroundColor White
    Write-Host "   [*] Advanced clipboard management" -ForegroundColor White
    Write-Host "   [*] Easy-to-use interface" -ForegroundColor White
    Write-Host "   [*] Customizable settings" -ForegroundColor White
    Write-Host ""
    Write-Host " [*] " -ForegroundColor Green -NoNewline
    Write-Host "Thank you for using MultiMessageCopy! If you find it useful, consider starring the repository." -ForegroundColor White
    Write-Host ""
    Write-Host " [*] " -ForegroundColor Blue -NoNewline
    Write-Host "Created with love by tsx-awtns" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to exit"

} catch {
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                           INSTALLATION FAILED                                ║" -ForegroundColor White
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Error "Setup failed with error: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "TROUBLESHOOTING:" -ForegroundColor Yellow
    Write-Host "   1. Check your internet connection" -ForegroundColor White
    Write-Host "   2. Verify PowerShell execution policy" -ForegroundColor White
    Write-Host "   3. Run as Administrator if possible" -ForegroundColor White
    Write-Host "   4. Check antivirus software interference" -ForegroundColor White
    Write-Host ""
    Write-Host "SUPPORT:" -ForegroundColor Cyan
    Write-Host "   Report this error: https://github.com/tsx-awtns/MultiMessageCopy/issues" -ForegroundColor Blue
    Write-Host "   Include the error message above in your report" -ForegroundColor Gray
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
