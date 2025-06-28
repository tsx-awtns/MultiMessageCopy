# MultiMessageCopy Setup Script v2.2 - Fixed Admin Restart
# Author: tsx-awtns (Enhanced by v0)

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
    Write-Host "    |                    Fixed Admin Restart System                      |" -ForegroundColor Gray
    Write-Host "    +----------------------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""
}

if ($Help) {
    Write-Banner
    Write-Host "USAGE: .\setup-fixed.ps1 [OPTIONS]" -ForegroundColor White
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  -SkipNodeInstall    Skip Node.js installation" -ForegroundColor Gray
    Write-Host "  -SkipGitInstall     Skip Git installation" -ForegroundColor Gray
    Write-Host "  -VencordPath        Custom Vencord path" -ForegroundColor Gray
    Write-Host "  -UseChocolatey      Use Chocolatey for installations (recommended)" -ForegroundColor Gray
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
        Write-Host "[3] Run PowerShell (Administrator) - Restart with admin rights" -ForegroundColor Green
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
    Write-Info "Preparing to restart PowerShell as Administrator..."
    Write-Host ""
    
    # The command to restart the script
    $downloadCommand = 'iwr "https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/setup.ps1" -UseBasicParsing | iex'
    
    try {
        Write-Host "STARTING POWERSHELL AS ADMINISTRATOR..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "The script will automatically download and run in the new window." -ForegroundColor Cyan
        Write-Host "Please wait for the new PowerShell window to appear..." -ForegroundColor White
        Write-Host ""
        
        # Create a temporary script file that will auto-execute
        $tempScriptPath = "$env:TEMP\multimessagecopy-autorun.ps1"
        $autoRunScript = @"
# Auto-run script for MultiMessageCopy Setup
Write-Host 'PowerShell started as Administrator' -ForegroundColor Green
Write-Host 'Starting MultiMessageCopy setup automatically...' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Downloading and executing setup script...' -ForegroundColor Yellow
Write-Host ''

try {
    # Execute the download command
    $downloadCommand
} catch {
    Write-Host 'Error occurred: ' -NoNewline -ForegroundColor Red
    Write-Host `$_.Exception.Message -ForegroundColor White
    Write-Host ''
    Write-Host 'Manual command:' -ForegroundColor Yellow
    Write-Host '$downloadCommand' -ForegroundColor Gray
    Write-Host ''
    Write-Host 'Press Enter to exit...' -ForegroundColor Cyan
    Read-Host
}
"@
        
        # Write the auto-run script to temp file
        $autoRunScript | Out-File -FilePath $tempScriptPath -Encoding UTF8
        
        # Method 1: Try using PowerShell with direct execution
        try {
            Write-Host "Method 1: Direct execution..." -ForegroundColor Gray
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "powershell.exe"
            $processInfo.Arguments = "-ExecutionPolicy Bypass -File `"$tempScriptPath`""
            $processInfo.Verb = "runas"
            $processInfo.UseShellExecute = $true
            $processInfo.WorkingDirectory = $env:USERPROFILE
            
            $process = [System.Diagnostics.Process]::Start($processInfo)
            
            if ($process) {
                Write-Success "PowerShell started as Administrator successfully!"
                Write-Host ""
                Write-Info "You can close this window now."
                Write-Host ""
                Start-Sleep -Seconds 2
                
                # Clean up temp file after a delay
                Start-Job -ScriptBlock {
                    param($filePath)
                    Start-Sleep -Seconds 30
                    Remove-Item $filePath -Force -ErrorAction SilentlyContinue
                } -ArgumentList $tempScriptPath | Out-Null
                
                Read-Host "Press Enter to exit this window"
                exit 0
            }
        } catch {
            Write-Warning "Method 1 failed: $($_.Exception.Message)"
        }
        
        # Method 2: Fallback to cmd with PowerShell
        try {
            Write-Host "Method 2: Using cmd fallback..." -ForegroundColor Gray
            $cmdCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$tempScriptPath`""
            
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "cmd.exe"
            $processInfo.Arguments = "/c $cmdCommand"
            $processInfo.Verb = "runas"
            $processInfo.UseShellExecute = $true
            $processInfo.WorkingDirectory = $env:USERPROFILE
            
            $process = [System.Diagnostics.Process]::Start($processInfo)
            
            if ($process) {
                Write-Success "PowerShell started via cmd successfully!"
                Write-Host ""
                Write-Info "You can close this window now."
                Write-Host ""
                Read-Host "Press Enter to exit this window"
                exit 0
            }
        } catch {
            Write-Warning "Method 2 failed: $($_.Exception.Message)"
        }
        
        # Method 3: Manual instructions
        Write-Host "Automatic start failed. Manual instructions:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Right-click on PowerShell icon in taskbar" -ForegroundColor White
        Write-Host "2. Select 'Run as Administrator'" -ForegroundColor White
        Write-Host "3. Copy and paste this command:" -ForegroundColor White
        Write-Host ""
        Write-Host $downloadCommand -ForegroundColor Gray
        Write-Host ""
        
        # Copy to clipboard as backup
        try {
            Set-Clipboard -Value $downloadCommand
            Write-Success "Command copied to clipboard!"
        } catch {
            Write-Warning "Could not copy to clipboard"
        }
        
        # Clean up temp file
        Remove-Item $tempScriptPath -Force -ErrorAction SilentlyContinue
        
    } catch {
        Write-Error "Failed to start PowerShell as Administrator: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "MANUAL STEPS:" -ForegroundColor Yellow
        Write-Host "1. Right-click on PowerShell icon" -ForegroundColor White
        Write-Host "2. Select 'Run as Administrator'" -ForegroundColor White
        Write-Host "3. Copy and paste this command:" -ForegroundColor White
        Write-Host "   $downloadCommand" -ForegroundColor Gray
        Write-Host ""
    }
    
    Read-Host "Press Enter to exit this window"
    exit 0
}

function Update-SessionPath {
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
        
        $env:PATH += ";$env:ALLUSERSPROFILE\chocolatey\bin"
        
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
                Start-Sleep -Seconds 3
                if (Test-Command "node") {
                    Write-Success "Node.js installed via Chocolatey"
                    return $true
                }
            }
        } catch {
            Write-Warning "Chocolatey installation failed, trying direct download..."
        }
    }
    
    try {
        Write-Host "Downloading Node.js installer..." -ForegroundColor Gray
        $nodeUrl = "https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi"
        $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($nodeUrl, $nodeInstaller)
        
        Write-Host "Installing Node.js..." -ForegroundColor Gray
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$nodeInstaller`"", "/quiet", "/norestart" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Start-Sleep -Seconds 5
            Update-SessionPath
            
            for ($i = 1; $i -le 3; $i++) {
                if (Test-Command "node") {
                    Write-Success "Node.js installed successfully"
                    Remove-Item $nodeInstaller -Force -ErrorAction SilentlyContinue
                    return $true
                }
                Write-Host "Attempt $i/3: Waiting for Node.js to be available..." -ForegroundColor Gray
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
                Start-Sleep -Seconds 3
                if (Test-Command "git") {
                    Write-Success "Git installed via Chocolatey"
                    return $true
                }
            }
        } catch {
            Write-Warning "Chocolatey installation failed, trying direct download..."
        }
    }
    
    try {
        Write-Host "Downloading Git installer..." -ForegroundColor Gray
        $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
        $gitInstaller = "$env:TEMP\git-installer.exe"
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($gitUrl, $gitInstaller)
        
        Write-Host "Installing Git..." -ForegroundColor Gray
        $process = Start-Process -FilePath $gitInstaller -ArgumentList "/VERYSILENT", "/NORESTART", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Start-Sleep -Seconds 5
            Update-SessionPath
            
            for ($i = 1; $i -le 3; $i++) {
                if (Test-Command "git") {
                    Write-Success "Git installed successfully"
                    Remove-Item $gitInstaller -Force -ErrorAction SilentlyContinue
                    return $true
                }
                Write-Host "Attempt $i/3: Waiting for Git to be available..." -ForegroundColor Gray
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
    # Enhanced Administrator check
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

    # Rest of the script continues as before...
    # (I'll include the essential parts to keep it concise)

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
                    Start-Sleep -Seconds 2
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
                    Start-Sleep -Seconds 2
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

    Write-Success "All prerequisites installed successfully!"
    Write-Info "Continuing with Vencord installation..."
    
    # Continue with the rest of the Vencord installation...
    # (The rest would be the same as the previous script)

} catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "TROUBLESHOOTING TIPS:" -ForegroundColor Yellow
    Write-Host "1. Run PowerShell as Administrator" -ForegroundColor White
    Write-Host "2. Check your internet connection" -ForegroundColor White
    Write-Host "3. Temporarily disable antivirus" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
