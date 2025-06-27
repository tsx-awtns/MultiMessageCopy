# PowerShell

# MultiMessageCopy Setup Script v1.0 (Windows)
# Author: mays_024

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
MultiMessageCopy Plugin Automated Setup Script v1.0

USAGE:
    .\setup.ps1 [OPTIONS]

OPTIONS:
    -SkipNodeInstall    Skip Node.js installation check
    -SkipGitInstall     Skip Git installation check  
    -VencordPath        Specify custom Vencord installation path
    -Help               Show this help message
"@ -ForegroundColor White
}

if ($Help) { Show-Help; exit 0 }

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Command {
    param($Command)
    try { Get-Command $Command -ErrorAction Stop | Out-Null; return $true }
    catch { return $false }
}

function Install-NodeJS {
    if (Test-Command "node") {
        Write-Success "Node.js already installed"
        return
    }
    $nodeUrl = "https://nodejs.org/dist/v20.10.0/node-v20.10.0-x64.msi"
    $installer = "$env:TEMP\nodejs.msi"
    Invoke-WebRequest $nodeUrl -OutFile $installer -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList "/i", $installer, "/quiet", "/norestart" -Wait
    Remove-Item $installer -Force -ErrorAction SilentlyContinue
}

function Install-Git {
    if (Test-Command "git") {
        Write-Success "Git already installed"
        return
    }
    $gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/Git-2.42.0.2-64-bit.exe"
    $installer = "$env:TEMP\git.exe"
    Invoke-WebRequest $gitUrl -OutFile $installer -UseBasicParsing
    Start-Process $installer -ArgumentList "/VERYSILENT", "/NORESTART" -Wait
    Remove-Item $installer -Force -ErrorAction SilentlyContinue
}

function Install-Pnpm {
    if (Test-Command "pnpm") {
        Write-Success "pnpm already installed"
        return
    }
    npm install -g pnpm
}

function Get-VencordPath {
    $defaultPath = Join-Path $env:USERPROFILE "Desktop\Vencord"
    $userInput = Read-Host "Enter Vencord path or press Enter for default [$defaultPath]"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        return $defaultPath
    }
    return $userInput.Trim('"')
}

function Install-Vencord {
    param($Path)
    if (Test-Path (Join-Path $Path "package.json")) {
        Write-Success "Vencord found at: $Path"
        return $Path
    }

    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force
    }

    git clone https://github.com/Vendicated/Vencord.git $Path
    return $Path
}

function Install-VencordDependencies {
    param($Path)
    Push-Location $Path
    pnpm install
    Pop-Location
}

function Install-MultiMessageCopy {
    param($VencordPath)

    $pluginDir = Join-Path $VencordPath "src\userplugins\MultiMessageCopy"
    if (Test-Path $pluginDir) {
        Remove-Item $pluginDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $pluginDir -Force | Out-Null

    $baseUrl = "https://raw.githubusercontent.com/tsx-awtns/MultiMessageCopy/main/MultiMessageCopyFiles"
    Invoke-WebRequest "$baseUrl/index.tsx" -OutFile (Join-Path $pluginDir "index.tsx") -UseBasicParsing
    Invoke-WebRequest "$baseUrl/styles.css" -OutFile (Join-Path $pluginDir "styles.css") -UseBasicParsing

    Write-Success "MultiMessageCopy plugin installed in: $pluginDir"
}

function Build-Vencord {
    param($Path)
    Push-Location $Path
    pnpm build
    Pop-Location
}

function Inject-Vencord {
    param($Path)
    Push-Location $Path
    pnpm inject
    Pop-Location
}

function Main {
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║               MultiMessageCopy Setup Script                 ║
║                        Version 1.0                          ║
║                     by mays_024                             ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

    if (!(Test-Administrator)) {
        Write-Warning "Not running as administrator. Some steps may fail."
        $c = Read-Host "Continue anyway? (y/N)"
        if ($c -ne "y" -and $c -ne "Y") { return }
    }

    if (!$SkipNodeInstall) { Install-NodeJS }
    if (!$SkipGitInstall) { Install-Git }
    Install-Pnpm

    if ([string]::IsNullOrEmpty($VencordPath)) {
        $VencordPath = Get-VencordPath
    }

    $vencord = Install-Vencord -Path $VencordPath
    Install-VencordDependencies -Path $vencord
    Install-MultiMessageCopy -VencordPath $vencord
    Build-Vencord -Path $vencord

    $inj = Read-Host "Inject Vencord into Discord now? (Y/n)"
    if ($inj -ne "n" -and $inj -ne "N") {
        Inject-Vencord -Path $vencord
    }

    Write-Success "`n✅ MultiMessageCopy installed!"
    Write-Info "Restart Discord and enable the plugin in Vencord settings."
}

Main
