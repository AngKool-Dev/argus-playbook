<#
.SYNOPSIS
    Argus Windows Playbook - Backup System State
.DESCRIPTION
    Records system state before modifications for audit and restore purposes
#>

param()

$ErrorActionPreference = 'Stop'
$logDir = "$env:ProgramData\ArgusPlaybook"

if (!(Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $logDir "backup-$timestamp"

New-Item -Path $backupDir -ItemType Directory -Force | Out-Null

# Export registry keys
$regKeys = @(
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced',
    'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System',
    'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
    'HKLM\SOFTWARE\Policies\Microsoft\Windows\System',
    'HKLM\SOFTWARE\Policies\Microsoft\Dsh',
    'HKLM\SYSTEM\CurrentControlSet\Control\Power',
    'HKLM\SYSTEM\CurrentControlSet\Control\FileSystem',
    'HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers',
    'HKLM\SYSTEM\CurrentControlSet\Services\SysMain',
    'HKLM\SYSTEM\CurrentControlSet\Services\WSearch',
    'HKLM\SYSTEM\CurrentControlSet\Services\DoSvc',
    'HKLM\SYSTEM\CurrentControlSet\Services\DiagTrack',
    'HKLM\SYSTEM\CurrentControlSet\Services\BITS'
)

foreach ($key in $regKeys) {
    $fileName = $key -replace '[\\/:]', '_'
    $path = Join-Path $backupDir "$fileName.reg"
    try {
        reg.exe export $key $path /y 2>&1 | Out-Null
        Write-Host "[OK] Exported $key"
    } catch {
        Write-Host "[WARN] Failed to export $key : $_"
    }
}

# Export service states
$services = @('SysMain', 'WSearch', 'DoSvc', 'DiagTrack', 'BITS', 'TrkWks', 'OneSyncSvc', 'PcaSvc', 'WerSvc', 'Spooler')
$serviceStates = @()

foreach ($svc in $services) {
    try {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            $serviceStates += "$svc=$($s.StartType)"
        }
    } catch {
        Write-Host "[WARN] Could not query service $svc"
    }
}

$serviceStates | Out-File (Join-Path $backupDir "services.txt") -Encoding utf8

# Export scheduled tasks
$tasks = Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\Windows\*' }
$taskStates = @()

foreach ($task in $tasks) {
    $taskStates += "$($task.TaskName)=$($task.State)"
}

$taskStates | Out-File (Join-Path $backupDir "tasks.txt") -Encoding utf8

# Export AppX packages
$appx = Get-AppxPackage -AllUsers | Select-Object -ExpandProperty PackageFamilyName
$appx | Out-File (Join-Path $backupDir "appx.txt") -Encoding utf8

# Export power plan
powercfg /getactivescheme | Out-File (Join-Path $backupDir "power.txt") -Encoding utf8

Write-Host "[OK] Backup complete: $backupDir"
