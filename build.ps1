<#
.SYNOPSIS
    Builds the Argus Windows Playbook .apbx package
.DESCRIPTION
    Creates a password-protected 7z archive (.apbx) containing all playbook files
#>

param(
    [switch]$ReplaceOld,
    [switch]$AddLiveLog,
    [string]$FileName = "ArgusWindowsPlaybook",
    [switch]$NoPassword,
    [switch]$DontOpenLocation
)

$ErrorActionPreference = 'Stop'

# Check for 7-Zip
$7zPath = $null
if (Get-Command '7z' -ErrorAction SilentlyContinue) {
    $7zPath = '7z'
} elseif (Get-Command '7zz' -ErrorAction SilentlyContinue) {
    $7zPath = '7zz'
} elseif (Test-Path "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe") {
    $7zPath = "$([Environment]::GetFolderPath('ProgramFiles'))\7-Zip\7z.exe"
} else {
    throw "7-Zip or NanaZip is required to build the playbook."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = $scriptDir
$apbxFileName = "$FileName.apbx"
$apbxPath = Join-Path $projectDir $apbxFileName

# Handle existing file
if ($ReplaceOld -and (Test-Path $apbxPath)) {
    try {
        $stream = [System.IO.File]::Open($apbxPath, 'Open', 'ReadWrite')
        $stream.Close()
        Remove-Item $apbxPath -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Warning "Couldn't replace '$apbxFileName', it's in use."
    }
}

# Create temp directory
$tempDir = Join-Path $env:TEMP "argus-playbook-build-$(New-Guid)"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

try {
    # Copy playbook files
    $playbookTemp = Join-Path $tempDir "playbook"
    New-Item -Path $playbookTemp -ItemType Directory -Force | Out-Null

    # Copy all files except build artifacts and development files
    Get-ChildItem $projectDir -File | Where-Object { $_.Name -notmatch '^build\.ps1$|^validate\.ps1$|^audit\.ps1$|^AUDIT\.md$|^migrate\.ps1$|^update-yaml\.ps1$|^fix-yaml\.ps1$|^fix-all\.ps1$|\.apbx$' } | ForEach-Object {
        Copy-Item $_.FullName $playbookTemp -Force
    }

    Get-ChildItem $projectDir -Directory | Where-Object { $_.Name -notin @('dist', 'Tests', 'docs', 'research', 'test-minimal', 'test-radio') } | ForEach-Object {
        Copy-Item $_.FullName $playbookTemp -Recurse -Force
    }

    # Remove any accidentally copied .apbx from temp
    Get-ChildItem $playbookTemp -Filter "*.apbx" -Recurse | Remove-Item -Force

    # Add live log if requested
    if ($AddLiveLog) {
        $customYmlPath = Join-Path $projectDir "Configuration\main.yml"
        $tempCustomYmlPath = Join-Path $playbookTemp "Configuration\main.yml"
        
        if (Test-Path $customYmlPath) {
            $customYml = Get-Content $customYmlPath
            $liveLogScript = {
                $a = Join-Path (Get-ChildItem (Join-Path $([Environment]::GetFolderPath('CommonApplicationData')) '\AME\Logs') -Directory |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1).FullName '\OutputBuffer.txt';
                while ($true) { Get-Content -Wait -LiteralPath $a -EA 0 | Write-Output; Start-Sleep 1 }
            }
            [string]$liveLogText = ($liveLogScript -replace '"','"""' -replace "'","''").Trim() -replace "`r?`n", " "
            $actionsIndex = $customYml.IndexOf('actions:')
            $newCustomYml = $customYml[0..$actionsIndex] + 
                "  - !cmd: {command: 'start `"AME Wizard Live Log`" PowerShell -NoP -C `"$liveLogText`"'}" + 
                $customYml[($actionsIndex + 1)..($customYml.Count)]
            Set-Content -Path $tempCustomYmlPath -Value $newCustomYml
        }
    }

    # Create file list
    $filesList = Join-Path $tempDir "files.txt"
    Get-ChildItem $playbookTemp -File -Recurse | ForEach-Object {
        $_.FullName.Substring($playbookTemp.Length + 1)
    } | Out-File $filesList -Encoding utf8

    # Build archive from temp directory so relative paths work
    $password = if ($NoPassword) { '' } else { '-pmalte' }
    Push-Location $playbookTemp
    & $7zPath a -spf -y -mx1 $password -t7z $apbxPath "@$filesList" | Out-Null
    Pop-Location

    Write-Host "[OK] Built successfully: $apbxPath" -ForegroundColor Green

    # Open location
    if (!$DontOpenLocation) {
        if ($IsLinux -or $IsMacOS) {
            Write-Warning "Can't open APBX directory on non-Windows."
        } else {
            explorer /select,"$apbxPath"
        }
    }
} finally {
    Remove-Item $tempDir -Force -Recurse -ErrorAction SilentlyContinue
}
