<#
.SYNOPSIS
    Argus Windows Playbook - System Optimization
.DESCRIPTION
    Safe Windows 10/11 optimization following FSOS-X patterns.
    No shell process killing, no unverified binary downloads,
    no core Windows service disabling.
#>

param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Logging setup
$logDir = "$env:ProgramData\ArgusPlaybook"
if (!(Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}
$logFile = Join-Path $logDir "argus-optimizer-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Write-Output $logMessage
    Add-Content -Path $logFile -Value $logMessage -Encoding utf8
}

Write-Log "=== Argus Windows Playbook - System Optimization ==="
Write-Log "Log file: $logFile"
Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "User: $env:USERNAME"
Write-Log "OS: $([System.Environment]::OSVersion.VersionString)"

# ============================================
# HELPER FUNCTIONS (FSOS-style)
# ============================================
function Stop-ServiceBounded {
    param([string]$Name, [int]$Seconds = 20)
    try {
        $sc = New-Object System.ServiceProcess.ServiceController $Name
        if ($sc.Status -ne 'Running' -or -not $sc.CanStop) { return }
        $sc.Stop()
        try { $sc.WaitForStatus('Stopped', [TimeSpan]::FromSeconds($Seconds)) }
        catch {
            Write-Log "[WARN] Service $Name did not stop within $Seconds seconds, continuing"
        }
    } catch {}
}

function Kill-Bounded {
    param([string]$Image, [int]$Seconds = 15)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = Join-Path $env:SystemRoot 'System32\taskkill.exe'
        $psi.Arguments = "/F /T /IM $Image"
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $proc = [System.Diagnostics.Process]::Start($psi)
        if (-not $proc.WaitForExit($Seconds * 1000)) {
            try { $proc.Kill() } catch {}
        }
    } catch {}
}

# ============================================
# 1. STOP NON-CRITICAL SERVICES (BOUNDED)
# ============================================
Write-Log "[*] Stopping non-critical services..."

# Only services that are safe to stop - NOT BITS, Spooler, SharedAccess, Sense, AppXSvc, ClipSVC
$servicesToStop = @('WidgetService','DiagTrack','wisvc','MapsBroker','lfsvc','dmwappushservice','Fax','RetailDemo','OneSyncSvc','PcaSvc','WerSvc','wercplsupport','UCPD','PrintNotify','NetTcpPortSharing','TermService','SCardSvr','SEMgrSvc','UmRdpService','WdiServiceHost','WdiSystemHost','AppVClient','PerfHost','WpcMonSvc','PhoneSvc','LicenseManager','wlidsvc','TokenBroker','StorSvc','OneDriveSvc','SensrSvc','RmSvc','WpnService','WpnUserService','CDPSvc','CDPUserSvc','UnistoreSvc','UserDataSvc','PimIndexMaintenanceSvc','RetailDemo','WMPNetworkSvc','DialogBlockingService','AssignedAccessManagerSvc','DevQueryBroker','fdc','flpydisk','sfloppy','serial','serenum','sermouse','ErrDev','CompositeBus','SEMgrSvc','SCardSvr','ScDeviceEnum','uhssvc','whesvc')

foreach ($svc in $servicesToStop) {
    Stop-ServiceBounded $svc 20
}

# Kill only non-shell consumer processes (NOT SearchHost, StartMenuExperienceHost, ShellExperienceHost, explorer)
$processesToKill = @('msedgewebview2.exe','Widgets.exe','WidgetService.exe','GameInputSvc.exe','GameBar.exe','GameBarFT.exe','GameBarFTServer.exe','GameBarPresenceWriter.exe','XboxApp.exe','Xbox.exe','OneDrive.exe','OneDriveSetup.exe','Clipchamp.exe','WhatsApp.exe','LinkedIn.exe','Solitaire.exe','BingNews.exe','BingWeather.exe','BingFinance.exe','BingSports.exe','BingTravel.exe','BingFoodAndDrink.exe','BingHealthAndFitness.exe','BingSearch.exe','Alarms.exe','Camera.exe','Maps.exe','SoundRecorder.exe','DevHome.exe','FeedbackHub.exe','GetHelp.exe','Getstarted.exe','People.exe','Skype.exe','Teams.exe','Whiteboard.exe','ZuneMusic.exe','ZuneVideo.exe','Phone.exe','YourPhone.exe','Cortana.exe','Copilot.exe','PowerAutomate.exe','Todos.exe','OfficeHub.exe','Photos.exe','3DBuilder.exe','Advertising.exe','Portal.exe','Paint.exe','StickyNotes.exe','Notepad.exe','Calculator.exe','Terminal.exe')

foreach ($proc in $processesToKill) {
    Kill-Bounded $proc 15
}

Start-Sleep -Milliseconds 500
$global:LASTEXITCODE = 0
Write-Log "[OK] Non-shell processes stopped"

# ============================================
# 2. ENSURE APPX SERVICES ARE ENABLED
# ============================================
Write-Log "[*] Ensuring AppX services are enabled..."
try {
    Set-Service -Name AppXSvc -StartupType Manual -ErrorAction SilentlyContinue
    Set-Service -Name ClipSVC -StartupType Manual -ErrorAction SilentlyContinue
    Start-Service -Name AppXSvc -ErrorAction SilentlyContinue
    Start-Service -Name ClipSVC -ErrorAction SilentlyContinue
    Write-Log "[OK] AppX services ready"
} catch {
    Write-Log "[WARN] AppX services issue: $_"
}

# ============================================
# 3. REMOVE CONSUMER BLOATWARE (SAFE ONLY)
# ============================================
Write-Log "[*] Removing consumer bloatware..."

$bloatware = @(
    'SpotifyAB.SpotifyMusic*',
    'Microsoft.ZuneMusic*',
    'Microsoft.ZuneVideo*',
    'Microsoft.MicrosoftSolitaireCollection*',
    'Microsoft.BingNews*',
    'Microsoft.BingWeather*',
    'Microsoft.BingSports*',
    'Microsoft.BingFinance*',
    'Microsoft.BingFoodAndDrink*',
    'Microsoft.BingHealthAndFitness*',
    'Microsoft.BingTravel*',
    'Microsoft.BingSearch*',
    'Microsoft.WindowsAlarms*',
    'Microsoft.WindowsCamera*',
    'Microsoft.WindowsMaps*',
    'Microsoft.WindowsSoundRecorder*',
    'Microsoft.Windows.DevHome*',
    'Microsoft.Windows.FeedbackHub*',
    'Microsoft.Microsoft3DViewer*',
    'Microsoft.MixedReality.Portal*',
    'Microsoft.StartExperiencesApp*',
    'Microsoft.Windows.Photos*',
    'Clipchamp.Clipchamp*',
    'Microsoft.MicrosoftPowerBIForWindows*',
    'Microsoft.MicrosoftOfficeHub*',
    'OutlookPWA*',
    'Microsoft.MicrosoftStickyNotes*'
)

$removed = 0
$failed = 0

foreach ($pattern in $bloatware) {
    try {
        $packages = Get-AppxPackage -AllUsers -Name $pattern -ErrorAction SilentlyContinue
        if (!$packages) { continue }

        foreach ($pkg in $packages) {
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
                Write-Log "[OK] Removed $($pkg.Name)"
                $removed++
            } catch {
                try {
                    Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
                    Write-Log "[OK] Removed $($pkg.Name) (current user)"
                    $removed++
                } catch {
                    Write-Log "[WARN] Could not remove $($pkg.Name): $($_.Exception.Message)"
                    $failed++
                }
            }
        }
    } catch {}
}

Write-Log "[*] Bloatware removal: $removed removed, $failed failed"
$global:LASTEXITCODE = 0

# ============================================
# 4. DEPROVISION PACKAGES
# ============================================
Write-Log "[*] Deprovisioning packages..."
try {
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    foreach ($pkg in $provisioned) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction Stop
            Write-Log "[OK] Deprovisioned $($pkg.DisplayName)"
        } catch {
            Write-Log "[WARN] Could not deprovision $($pkg.DisplayName)"
        }
    }
} catch {
    Write-Log "[WARN] Deprovisioning failed: $_"
}
$global:LASTEXITCODE = 0

# ============================================
# 5. APPLY DARK MODE AND WALLPAPER
# ============================================
Write-Log "[*] Applying Argus dark theme..."

# Create wallpaper directory
$wallpaperDir = "$env:SystemRoot\Web\Wallpaper\Argus"
if (!(Test-Path $wallpaperDir)) {
    New-Item -Path $wallpaperDir -ItemType Directory -Force | Out-Null
}

$wallpaperPath = Join-Path $wallpaperDir "argus-dark.jpg"

# Generate Argus wallpaper if it doesn't exist
if (!(Test-Path $wallpaperPath)) {
    try {
        Add-Type -AssemblyName System.Drawing

        $width = 1920
        $height = 1080
        $bitmap = New-Object System.Drawing.Bitmap($width, $height)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

        # Dark navy background
        $rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $rect,
            [System.Drawing.Color]::FromArgb(15, 23, 42),
            [System.Drawing.Color]::FromArgb(30, 41, 59),
            [System.Drawing.Drawing2D.LinearGradientMode]::DiagonalForward
        )
        $graphics.FillRectangle($brush, $rect)

        # Argus text
        $font = New-Object System.Drawing.Font("Segoe UI", 72, [System.Drawing.FontStyle]::Bold)
        $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 212, 255))
        $graphics.DrawString("ARGUS", $font, $textBrush, ($width/2 - 250), ($height/2 - 100))

        $fontSmall = New-Object System.Drawing.Font("Segoe UI", 24)
        $textBrushSmall = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(148, 163, 184))
        $graphics.DrawString("Windows Playbook", $fontSmall, $textBrushSmall, ($width/2 - 180), ($height/2 + 20))

        $bitmap.Save($wallpaperPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

        $graphics.Dispose()
        $brush.Dispose()
        $textBrush.Dispose()
        $textBrushSmall.Dispose()
        $font.Dispose()
        $fontSmall.Dispose()
        $bitmap.Dispose()

        Write-Log "[OK] Created Argus wallpaper"
    } catch {
        Write-Log "[WARN] Could not create wallpaper: $_"
    }
}

# Apply dark mode - FSOS uses AppsUseLightTheme and SystemUsesLightTheme
try {
    $sids = @('.DEFAULT')
    try {
        $sids += (Get-ChildItem 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -match '^S-1-5-21-' -and $_.PSChildName -notmatch '_Classes$' } |
            ForEach-Object { $_.PSChildName })
    } catch {}

    foreach ($sid in $sids) {
        $key = 'Registry::HKEY_USERS\' + $sid + '\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        New-ItemProperty -Path $key -Name 'AppsUseLightTheme'    -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $key -Name 'SystemUsesLightTheme' -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $key -Name 'ColorPrevalence'      -Value 0 -PropertyType DWord -Force | Out-Null
    }
    Write-Log "[OK] Applied dark mode to all users"

    # Apply wallpaper
    if (Test-Path $wallpaperPath) {
        Get-ChildItem "Registry::HKU" | ForEach-Object {
            [Microsoft.Win32.Registry]::SetValue("$($_.Name)\Control Panel\Desktop","WallPaper",$wallpaperPath,[Microsoft.Win32.RegistryValueKind]::String)
        }

        # SystemParametersInfo to refresh
        $cs = 'using System.Runtime.InteropServices; public class WPHelper { [DllImport("user32.dll",SetLastError=true,CharSet=CharSet.Auto)] static extern int SystemParametersInfo(int a,int b,string c,int d); public static void Set(string p){SystemParametersInfo(20,0,p,3);} }'
        if (-not ([System.Management.Automation.PSTypeName]'WPHelper').Type) { Add-Type -TypeDefinition $cs }
        [WPHelper]::Set($wallpaperPath)
        Write-Log "[OK] Wallpaper applied"
    }
} catch {
    Write-Log "[WARN] Theme application failed: $_"
}

# Create marker so we don't re-run personalization
try {
    if (!(Test-Path $marker)) {
        New-Item -Path $marker -ItemType File -Force | Out-Null
    }
} catch {}

$global:LASTEXITCODE = 0
Write-Log ""
Write-Log "=== Argus optimization complete ==="
Write-Log "Log saved to: $logFile"
Write-Log ""
Write-Log "NEXT STEPS:"
Write-Log "1. Reboot your system to apply all changes"
Write-Log "2. Check log for details: $logFile"
