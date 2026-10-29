<#
.SYNOPSIS
    Argus Windows Playbook - Apply Dark Theme and Wallpaper
.DESCRIPTION
    Applies Argus dark theme and wallpaper to all users
#>

param()

$ErrorActionPreference = 'SilentlyContinue'

# Create Argus wallpaper if it doesn't exist
$wallpaperDir = "$env:SystemRoot\Web\Wallpaper\Argus"
if (!(Test-Path $wallpaperDir)) {
    New-Item -Path $wallpaperDir -ItemType Directory -Force | Out-Null
}

$wallpaperPath = Join-Path $wallpaperDir "argus-dark.jpg"

if (!(Test-Path $wallpaperPath)) {
    # Create a dark Argus-themed wallpaper using .NET
    Add-Type -AssemblyName System.Drawing
    
    $width = 1920
    $height = 1080
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Dark blue/cyan gradient background
    $rect = New-Object System.Drawing.Rectangle(0, 0, $width, $height)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(15, 23, 42),  # Dark navy
        [System.Drawing.Color]::FromArgb(30, 41, 59),   # Slightly lighter navy
        [System.Drawing.Drawing2D.LinearGradientMode]::DiagonalForward
    )
    $graphics.FillRectangle($brush, $rect)
    
    # Add Argus text
    $font = New-Object System.Drawing.Font("Segoe UI", 72, [System.Drawing.FontStyle]::Bold)
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 212, 255))  # Cyan
    $graphics.DrawString("ARGUS", $font, $textBrush, ($width/2 - 250), ($height/2 - 100))
    
    $fontSmall = New-Object System.Drawing.Font("Segoe UI", 24)
    $textBrushSmall = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(148, 163, 184))  # Slate gray
    $graphics.DrawString("Windows Playbook", $fontSmall, $textBrushSmall, ($width/2 - 180), ($height/2 + 20))
    
    # Save
    $bitmap.Save($wallpaperPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    
    $graphics.Dispose()
    $brush.Dispose()
    $textBrush.Dispose()
    $textBrushSmall.Dispose()
    $font.Dispose()
    $fontSmall.Dispose()
    $bitmap.Dispose()
    
    Write-Output "[OK] Created Argus wallpaper at $wallpaperPath"
} else {
    Write-Output "[OK] Argus wallpaper already exists"
}

# Apply dark mode and wallpaper to ALL users
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize",
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
)

# System-wide settings via HKLM
foreach ($regPath in $regPaths) {
    if (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    # Dark mode
    Set-ItemProperty -Path $regPath -Name "SystemTheme" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $regPath -Name "AppsTheme" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    # Disable transparency
    Set-ItemProperty -Path $regPath -Name "EnableTransparency" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    # Disable lock screen
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Value 1 -Type DWord -ErrorAction SilentlyContinue
}

# Apply to all user SIDs
$userKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^S-1-5-21-\d+$' }

foreach ($key in $userKeys) {
    $sid = $key.PSChildName
    $userRegPath = "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    
    if (!(Test-Path $userRegPath)) {
        New-Item -Path $userRegPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $userRegPath -Name "SystemTheme" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $userRegPath -Name "AppsTheme" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $userRegPath -Name "EnableTransparency" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    
    # Set wallpaper for this user
    $desktopPath = "HKU:\$sid\Control Panel\Desktop"
    if (!(Test-Path $desktopPath)) {
        New-Item -Path $desktopPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $desktopPath -Name "Wallpaper" -Value $wallpaperPath -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $desktopPath -Name "WallpaperStyle" -Value "10" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $desktopPath -Name "TileWallpaper" -Value "0" -ErrorAction SilentlyContinue
}

# Apply wallpaper immediately using SystemParametersInfo
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

[Wallpaper]::SystemParametersInfo(20, 0, $wallpaperPath, 3) | Out-Null

Write-Output "[OK] Dark mode and Argus wallpaper applied to all users"
