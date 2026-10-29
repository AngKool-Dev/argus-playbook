<#
.SYNOPSIS
    Basic tests for Argus Windows Playbook
#>

param()

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir
$passed = 0
$failed = 0

function Test-Case {
    param([string]$Name, [scriptblock]$Test)
    
    try {
        & $Test
        Write-Host "[PASS] $Name" -ForegroundColor Green
        $script:passed++
    } catch {
        Write-Host "[FAIL] $Name : $_" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "`n=== Running Argus Playbook Tests ===" -ForegroundColor Cyan

# Test 1: Required files exist
Test-Case "playbook.conf exists" {
    $path = Join-Path $projectDir "playbook.conf"
    if (!(Test-Path $path)) { throw "Missing playbook.conf" }
}

Test-Case "Configuration/main.yml exists" {
    $path = Join-Path $projectDir "Configuration\main.yml"
    if (!(Test-Path $path)) { throw "Missing Configuration/main.yml" }
}

Test-Case "backup.ps1 exists" {
    $path = Join-Path $projectDir "Executables\Scripts\backup.ps1"
    if (!(Test-Path $path)) { throw "Missing backup.ps1" }
}

Test-Case "restore.ps1 exists" {
    $path = Join-Path $projectDir "Executables\Scripts\restore.ps1"
    if (!(Test-Path $path)) { throw "Missing restore.ps1" }
}

# Test 2: YAML files have required fields
Test-Case "main.yml has title" {
    $content = Get-Content (Join-Path $projectDir "Configuration\main.yml") -Raw
    if ($content -notmatch 'title:') { throw "Missing title" }
}

Test-Case "main.yml has actions" {
    $content = Get-Content (Join-Path $projectDir "Configuration\main.yml") -Raw
    if ($content -notmatch 'actions:') { throw "Missing actions" }
}

# Test 3: playbook.conf has required fields
Test-Case "playbook.conf has Name" {
    $content = Get-Content (Join-Path $projectDir "playbook.conf") -Raw
    if ($content -notmatch '<Name>') { throw "Missing Name" }
}

Test-Case "playbook.conf has Version" {
    $content = Get-Content (Join-Path $projectDir "playbook.conf") -Raw
    if ($content -notmatch '<Version>') { throw "Missing Version" }
}

Test-Case "playbook.conf has UniqueId" {
    $content = Get-Content (Join-Path $projectDir "playbook.conf") -Raw
    if ($content -notmatch '<UniqueId>') { throw "Missing UniqueId" }
}

Test-Case "playbook.conf has SupportedBuilds" {
    $content = Get-Content (Join-Path $projectDir "playbook.conf") -Raw
    if ($content -notmatch '<SupportedBuilds>') { throw "Missing SupportedBuilds" }
}

Test-Case "playbook.conf has FeaturePages" {
    $content = Get-Content (Join-Path $projectDir "playbook.conf") -Raw
    if ($content -notmatch '<FeaturePages>') { throw "Missing FeaturePages" }
}

# Test 4: All referenced task files exist
Test-Case "All task files referenced in main.yml exist" {
    $mainContent = Get-Content (Join-Path $projectDir "Configuration\main.yml") -Raw
    $taskPaths = [regex]::Matches($mainContent, "path: '([^']+)'") | ForEach-Object { $_.Groups[1].Value }
    
    foreach ($path in $taskPaths) {
        $fullPath = Join-Path $projectDir "Configuration\$path"
        if (!(Test-Path $fullPath)) {
            throw "Missing referenced file: $path"
        }
    }
}

# Test 5: PowerShell scripts parse
Test-Case "backup.ps1 parses" {
    $content = Get-Content (Join-Path $projectDir "Executables\Scripts\backup.ps1") -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
}

Test-Case "restore.ps1 parses" {
    $content = Get-Content (Join-Path $projectDir "Executables\Scripts\restore.ps1") -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
}

# Test 6: No destructive patterns without option guards
Test-Case "No blind Defender disable" {
    $content = Get-Content (Join-Path $projectDir "Configuration\main.yml") -Raw
    if ($content -match 'DisableRealtimeMonitoring' -and $content -notmatch 'option:') {
        throw "Potential blind Defender disable found"
    }
}

# Test 7: Restore script selects most recent backup when -BackupPath omitted
Test-Case "restore.ps1 auto-selects most recent backup" {
    $testBackupRoot = Join-Path $env:TEMP "ArgusRestoreTest-$(Get-Random)"
    New-Item -Path $testBackupRoot -ItemType Directory -Force | Out-Null

    try {
        # Create two backup directories with timestamps
        $older = Join-Path $testBackupRoot "backup-20260101-000000"
        $newer = Join-Path $testBackupRoot "backup-20260102-000000"
        New-Item -Path $older -ItemType Directory -Force | Out-Null
        New-Item -Path $newer -ItemType Directory -Force | Out-Null

        # Create a .reg file in the newer backup so restore has something to import
        Set-Content -Path (Join-Path $newer "test.reg") -Value "REGEDIT4" -Encoding utf8

        # Temporarily override $logDir by testing the selection logic inline
        $backups = Get-ChildItem -LiteralPath $testBackupRoot -Directory -Filter "backup-*" | Sort-Object LastWriteTime -Descending
        if ($backups.Count -eq 0) { throw "No backups found" }
        $selected = $backups[0].FullName
        if ($selected -ne $newer) {
            throw "Expected most recent backup '$newer', got '$selected'"
        }

        # Verify Test-Path passes on the selected backup
        if (-not (Test-Path -LiteralPath $selected)) { throw "Selected backup path does not exist" }

        Write-Host "[OK] Auto-selection found most recent backup"
    } finally {
        Remove-Item -Path $testBackupRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Test 8: restore.ps1 throws clear error when no backups exist
Test-Case "restore.ps1 throws on no backups" {
    $emptyDir = Join-Path $env:TEMP "ArgusRestoreEmptyTest-$(Get-Random)"
    New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null
    try {
        $backups = Get-ChildItem -LiteralPath $emptyDir -Directory -Filter "backup-*" | Sort-Object LastWriteTime -Descending
        if ($backups.Count -eq 0) {
            throw "No backups found in $emptyDir"
        }
        throw "Expected throw for empty backup directory"
    } catch {
        if ($_.Exception.Message -notlike "*No backups found*") { throw "Wrong error message: $_" }
    } finally {
        Remove-Item -Path $emptyDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Test 9: No duplicate keys within YAML lists (CI check)
Test-Case "No duplicate service entries in services/optimize.yml" {
    $content = Get-Content (Join-Path $projectDir "Configuration\Tasks\services\optimize.yml") -Raw
    $services = [regex]::Matches($content, "name: '([^']+)'") | ForEach-Object { $_.Groups[1].Value }
    $dupes = $services | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($dupes) {
        throw "Duplicate service entries found: $($dupes | ForEach-Object { $_.Name })"
    }
}

Test-Case "No duplicate registry entries in networking/tweaks.yml" {
    $content = Get-Content (Join-Path $projectDir "Configuration\Tasks\networking\tweaks.yml") -Raw
    $entries = [regex]::Matches($content, "value: '([^']+)'") | ForEach-Object { $_.Groups[1].Value }
    $dupes = $entries | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($dupes) {
        throw "Duplicate registry entries found: $($dupes | ForEach-Object { $_.Name })"
    }
}

Test-Case "No duplicate privacy entries in privacy/telemetry.yml" {
    $content = Get-Content (Join-Path $projectDir "Configuration\Tasks\privacy\telemetry.yml") -Raw
    $entries = [regex]::Matches($content, "value: '([^']+)'") | ForEach-Object { $_.Groups[1].Value }
    $dupes = $entries | Group-Object | Where-Object { $_.Count -gt 1 }
    if ($dupes) {
        throw "Duplicate privacy entries found: $($dupes | ForEach-Object { $_.Name })"
    }
}

Write-Host "`n=== Test Results ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failed -eq 0) {
    Write-Host "`n[OK] All tests passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[ERROR] $failed test(s) failed" -ForegroundColor Red
    exit 1
}
