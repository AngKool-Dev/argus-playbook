<#
.SYNOPSIS
    Comprehensive build audit for Argus Windows Playbook
.DESCRIPTION
    Validates package integrity, security, and correctness
#>

param()
$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$passCount = 0
$failCount = 0
$warnCount = 0

function Write-Pass { param([string]$Msg) Write-Host "[PASS] $Msg" -ForegroundColor Green; $script:passCount++ }
function Write-Fail { param([string]$Msg) Write-Host "[FAIL] $Msg" -ForegroundColor Red; $script:failCount++ }
function Write-Warn { param([string]$Msg) Write-Host "[WARN] $Msg" -ForegroundColor Yellow; $script:warnCount++ }

Write-Host "`n=== BUILD AUDIT ===" -ForegroundColor Cyan

# 1. Verify all packaged files exist
Write-Host "`n[1] Checking packaged files..." -ForegroundColor Cyan
$packagedFiles = @(
    'playbook.conf',
    'Configuration\main.yml',
    'Configuration\Tasks\core\baseline.yml',
    'Configuration\Tasks\core\start.yml',
    'Configuration\Tasks\core\profiles.yml',
    'Configuration\Tasks\core\profiles\safe.yml',
    'Configuration\Tasks\core\profiles\balanced.yml',
    'Configuration\Tasks\core\profiles\performance.yml',
    'Configuration\Tasks\core\profiles\gaming.yml',
    'Configuration\Tasks\core\profiles\privacy.yml',
    'Configuration\Tasks\core\profiles\developer.yml',
    'Configuration\Tasks\core\profiles\custom.yml',
    'Configuration\Tasks\privacy\telemetry.yml',
    'Configuration\Tasks\performance\tweaks.yml',
    'Configuration\Tasks\gaming\tweaks.yml',
    'Configuration\Tasks\services\optimize.yml',
    'Configuration\Tasks\services\tasks.yml',
    'Configuration\Tasks\packages\appx.yml',
    'Configuration\Tasks\packages\keep.yml',
    'Configuration\Tasks\packages\balanced.yml',
    'Configuration\Tasks\packages\aggressive.yml',
    'Configuration\Tasks\registry\explorer\ui.yml',
    'Configuration\Tasks\networking\tweaks.yml',
    'Configuration\Tasks\registry\security\hardening.yml',
    'Configuration\Tasks\developer\settings.yml',
    'Configuration\Tasks\registry\misc\additional.yml',
    'Configuration\Tasks\revert.yml',
    'Executables\Scripts\backup.ps1',
    'Executables\Scripts\restore.ps1',
    'Executables\Scripts\DISABLENOTIFS.cmd',
    'Executables\Scripts\finalize.cmd',
    'README.md',
    'CHANGELOG.md',
    'SECURITY.md',
    'CONTRIBUTING.md',
    'LICENSE'
)

foreach ($file in $packagedFiles) {
    if (Test-Path (Join-Path $projectDir $file)) {
        Write-Pass "$file exists"
    } else {
        Write-Fail "Missing: $file"
    }
}

# 2. Verify !task references resolve to actual files
Write-Host "`n[2] Checking !task references..." -ForegroundColor Cyan
$yamlFiles = Get-ChildItem $projectDir -Recurse -Filter "*.yml"
$taskRefs = @{}
foreach ($f in $yamlFiles) {
    $lines = Get-Content $f.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s+- !task:\s*$') {
            $nextLine = $lines[$i + 1]
            if ($nextLine -match "path:\s*'([^']+)'") {
                $ref = $Matches[1]
                # Task paths in AME are relative to the Configuration folder
                $configDir = Join-Path $projectDir "Configuration"
                $resolved = Join-Path $configDir $ref
                if (!(Test-Path $resolved)) {
                    Write-Fail "$($f.Name) references missing task: $ref"
                } else {
                    Write-Pass "$($f.Name) -> $ref"
                }
            }
        }
    }
}

# 3. Check for hard-coded development paths
Write-Host "`n[3] Checking for hard-coded paths..." -ForegroundColor Cyan
$allFiles = Get-ChildItem $projectDir -Recurse -File | Where-Object { $_.Extension -match '\.(yml|ps1|cmd|conf|md)$' -and $_.FullName -notmatch '\\docs\\' -and $_.Name -ne 'FINAL-VALIDATION-REPORT.md' }
$badPaths = @()
foreach ($f in $allFiles) {
    $content = Get-Content $f.FullName -Raw
    # Look for developer-specific paths, not standard system paths
    if ($content -match 'C:\\Users\\[^D\\][^\\]*\\') {
        $badPaths += $f.Name
    }
}
if ($badPaths.Count -eq 0) {
    Write-Pass "No hard-coded user paths found"
} else {
    Write-Fail "Files with hard-coded user paths: $($badPaths -join ', ')"
}

# 4. Check for secrets/credentials
Write-Host "`n[4] Checking for secrets..." -ForegroundColor Cyan
$secretPatterns = @(
    'password\s*[:=]',
    'secret\s*[:=]',
    'token\s*[:=]',
    'api_key\s*[:=]',
    'apikey\s*[:=]',
    'credentials\s*[:=]'
)
$secretsFound = $false
foreach ($f in $allFiles) {
    # Skip build script - it documents the password parameter
    if ($f.Name -eq 'build.ps1') { continue }
    $content = Get-Content $f.FullName -Raw
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) {
            Write-Warn "$($f.Name) may contain secret pattern: $pattern"
            $secretsFound = $true
        }
    }
}
if (!$secretsFound) {
    Write-Pass "No obvious secrets found"
}

# 5. Check for remote code execution patterns
Write-Host "`n[5] Checking for remote code execution..." -ForegroundColor Cyan
$rcePatterns = @(
    'Invoke-Expression',
    'iex\s*\(',
    'Invoke-WebRequest\s*\|',
    'curl\s+.*\|\s*powershell',
    'wget\s+.*\|\s*powershell',
    'Start-BitsTransfer'
)
$rceFound = $false
foreach ($f in $allFiles) {
    # Skip audit script and security documentation that describes what NOT to do
    if ($f.Name -in @('audit.ps1', 'SECURITY.md')) { continue }
    $content = Get-Content $f.FullName -Raw
    foreach ($pattern in $rcePatterns) {
        if ($content -match $pattern) {
            Write-Fail "$($f.Name) contains RCE pattern: $pattern"
            $rceFound = $true
        }
    }
}
if (!$rceFound) {
    Write-Pass "No remote code execution patterns found"
}

# 6. Check for debug flags
Write-Host "`n[6] Checking for debug flags..." -ForegroundColor Cyan
$debugFound = $false
foreach ($f in $allFiles) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match 'debug|Debug|DEBUG') {
        Write-Warn "$($f.Name) contains 'debug'"
        $debugFound = $true
    }
}
if (!$debugFound) {
    Write-Pass "No debug flags found"
}

# 7. Check for unexpected executables
Write-Host "`n[7] Checking for unexpected executables..." -ForegroundColor Cyan
$exeFiles = Get-ChildItem $projectDir -Recurse -File | Where-Object { $_.Extension -match '\.(exe|dll|sys|ocx)$' }
if ($exeFiles.Count -eq 0) {
    Write-Pass "No unexpected executables found"
} else {
    Write-Warn "Executable files found: $($exeFiles | ForEach-Object { $_.FullName })"
}

# 8. Check for unexpected downloads
Write-Host "`n[8] Checking for download patterns..." -ForegroundColor Cyan
$downloadPatterns = @(
    'Invoke-WebRequest',
    'curl\s+',
    'wget\s+',
    'Start-BitsTransfer',
    'DownloadFile'
)
$dlFound = $false
foreach ($f in $allFiles) {
    # Skip documentation that describes what NOT to do
    if ($f.Name -in @('audit.ps1', 'SECURITY.md')) { continue }
    $content = Get-Content $f.FullName -Raw
    foreach ($pattern in $downloadPatterns) {
        if ($content -match $pattern) {
            Write-Warn "$($f.Name) contains download pattern: $pattern"
            $dlFound = $true
        }
    }
}
if (!$dlFound) {
    Write-Pass "No download patterns found"
}

# 9. Privilege audit
Write-Host "`n[9] Privilege audit..." -ForegroundColor Cyan
$privilegeCount = 0
$trustedInstallerCount = 0
foreach ($f in $allFiles) {
    $content = Get-Content $f.FullName -Raw
    $matches = [regex]::Matches($content, 'runas:\s*(\w+)')
    foreach ($m in $matches) {
        $privilegeCount++
        if ($m.Groups[1].Value -eq 'TrustedInstaller') {
            $trustedInstallerCount++
            Write-Warn "$($f.Name) uses TrustedInstaller privilege"
        }
    }
}
Write-Pass "Total privilege-escalated operations: $privilegeCount (TrustedInstaller: $trustedInstallerCount)"

# 10. Idempotency check
Write-Host "`n[10] Idempotency check..." -ForegroundColor Cyan
$idempotencyIssues = @()
foreach ($f in $yamlFiles) {
    $content = Get-Content $f.FullName -Raw
    # Skip revert.yml - it intentionally uses delete operations for rollback
    if ($f.Name -eq 'revert.yml') { continue }
    # Check for delete operations without guards
    if ($content -match 'operation:\s*delete' -and $content -notmatch 'option:') {
        $idempotencyIssues += $f.Name
    }
}
if ($idempotencyIssues.Count -eq 0) {
    Write-Pass "No unguarded delete operations found"
} else {
    Write-Warn "Files with delete operations: $($idempotencyIssues -join ', ')"
}

# 11. Defender/Firewall/Update protection check
Write-Host "`n[11] Security protection checks..." -ForegroundColor Cyan
$defenderDisabled = $false
$firewallDisabled = $false
$wuDisabled = $false
foreach ($f in $yamlFiles) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match 'DisableRealtimeMonitoring' -and $content -notmatch 'option:') {
        $defenderDisabled = $true
        Write-Fail "$($f.Name) has unguarded Defender disable"
    }
    if ($content -match 'DisableFirewall|FirewallEnabled.*0') {
        $firewallDisabled = $true
        Write-Fail "$($f.Name) has firewall disable"
    }
    if ($content -match 'wuauserv|WindowsUpdate.*disable') {
        $wuDisabled = $true
        Write-Fail "$($f.Name) has Windows Update disable"
    }
}
if (!$defenderDisabled) { Write-Pass "No unguarded Defender disable" }
if (!$firewallDisabled) { Write-Pass "No firewall disable found" }
if (!$wuDisabled) { Write-Pass "No Windows Update disable found" }

# 12. Verify .apbx
Write-Host "`n[12] Verifying .apbx..." -ForegroundColor Cyan
$apbxPath = Join-Path $projectDir "dist\ArgusWindowsPlaybook.apbx"
if (Test-Path $apbxPath) {
    Write-Pass ".apbx exists"
    $size = (Get-Item $apbxPath).Length
    Write-Pass "Size: $size bytes"
    
    $hash = (Get-FileHash $apbxPath -Algorithm SHA256).Hash
    Write-Pass "SHA-256: $hash"
    
    # Check if it's a valid 7z archive
    $bytes = [System.IO.File]::ReadAllBytes($apbxPath)
    if ($bytes[0] -eq 0x37 -and $bytes[1] -eq 0x7A -and $bytes[2] -eq 0xBC -and $bytes[3] -eq 0xAF) {
        Write-Pass "Valid 7z archive"
    } else {
        Write-Fail "Not a valid 7z archive"
    }
} else {
    Write-Fail ".apbx not found"
}

# Summary
Write-Host "`n=== AUDIT SUMMARY ===" -ForegroundColor Cyan
Write-Host "PASS: $passCount" -ForegroundColor Green
Write-Host "WARN: $warnCount" -ForegroundColor Yellow
Write-Host "FAIL: $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })

if ($failCount -eq 0) {
    Write-Host "`n[OK] Build audit passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[FAIL] Build audit failed" -ForegroundColor Red
    exit 1
}
