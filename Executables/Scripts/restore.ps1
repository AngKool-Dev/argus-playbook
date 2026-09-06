<#
.SYNOPSIS
    Argus Windows Playbook - Restore System State
.DESCRIPTION
    Restores system state from the most recent backup
#>

param(
    [string]$BackupPath
)

$ErrorActionPreference = 'Stop'
$logDir = "$env:ProgramData\ArgusPlaybook"

if (!(BackupPath)) {
    $backups = Get-ChildItem $logDir -Directory -Filter "backup-*" | Sort-Object LastWriteTime -Descending
    if ($backups.Count -eq 0) {
        Write-Host "[ERROR] No backups found in $logDir"
        exit 1
    }
    $BackupPath = $backups[0].FullName
    Write-Host "[INFO] Using most recent backup: $BackupPath"
}

if (!(Test-Path $BackupPath)) {
    Write-Host "[ERROR] Backup path not found: $BackupPath"
    exit 1
}

Write-Host "[INFO] Restoring from $BackupPath"

# Restore registry keys
$regFiles = Get-ChildItem $BackupPath -Filter "*.reg"
foreach ($file in $regFiles) {
    try {
        reg.exe import $file.FullName 2>&1 | Out-Null
        Write-Host "[OK] Restored $($file.Name)"
    } catch {
        Write-Host "[WARN] Failed to restore $($file.Name) : $_"
    }
}

# Restore services
$serviceFile = Join-Path $BackupPath "services.txt"
if (Test-Path $serviceFile) {
    Get-Content $serviceFile | ForEach-Object {
        $parts = $_ -split '='
        if ($parts.Count -eq 2) {
            $svcName = $parts[0]
            $startType = $parts[1]
            try {
                Set-Service -Name $svcName -StartupType $startType -ErrorAction SilentlyContinue
                Write-Host "[OK] Restored service $svcName to $startType"
            } catch {
                Write-Host "[WARN] Could not restore service $svcName"
            }
        }
    }
}

# Restore scheduled tasks
$taskFile = Join-Path $BackupPath "tasks.txt"
if (Test-Path $taskFile) {
    Get-Content $taskFile | ForEach-Object {
        $parts = $_ -split '='
        if ($parts.Count -eq 2) {
            $taskName = $parts[0]
            $state = $parts[1]
            try {
                if ($state -eq 'Disabled') {
                    Disable-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                } else {
                    Enable-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                }
                Write-Host "[OK] Restored task $taskName to $state"
            } catch {
                Write-Host "[WARN] Could not restore task $taskName"
            }
        }
    }
}

# Restore AppX packages
$appxFile = Join-Path $BackupPath "appx.txt"
if (Test-Path $appxFile) {
    $currentAppx = Get-AppxPackage -AllUsers | Select-Object -ExpandProperty PackageFamilyName
    $backupAppx = Get-Content $appxFile
    $missing = $backupAppx | Where-Object { $_ -notin $currentAppx }
    
    foreach ($pkg in $missing) {
        try {
            Add-AppxPackage -Name $pkg -ErrorAction SilentlyContinue
            Write-Host "[OK] Restored AppX $pkg"
        } catch {
            Write-Host "[WARN] Could not restore AppX $pkg"
        }
    }
}

# Restore power plan
$powerFile = Join-Path $BackupPath "power.txt"
if (Test-Path $powerFile) {
    $powerScheme = Get-Content $powerFile | Select-String -Pattern 'GUID' | Select-Object -First 1
    if ($powerScheme) {
        $guid = [regex]::Match($powerScheme, '[a-f0-9\-]{36}').Value
        if ($guid) {
            powercfg /setactive $guid
            Write-Host "[OK] Restored power plan"
        }
    }
}

Write-Host "[OK] Restore complete from $BackupPath"
