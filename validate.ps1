<#
.SYNOPSIS
    Validates Argus Windows Playbook structure and syntax
.DESCRIPTION
    Checks playbook.conf, YAML files, PowerShell scripts, and package structure
#>

param()

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = $scriptDir

function Test-PlaybookConf {
    param([string]$Path)
    
    if (!(Test-Path $Path)) {
        Write-Host "[ERROR] playbook.conf not found" -ForegroundColor Red
        return $false
    }

    $content = Get-Content $Path -Raw
    
    # Basic validation
    if ($content -notmatch '<Playbook>') {
        Write-Host "[ERROR] playbook.conf missing <Playbook> root element" -ForegroundColor Red
        return $false
    }
    
    if ($content -notmatch '<Name>') {
        Write-Host "[ERROR] playbook.conf missing <Name>" -ForegroundColor Red
        return $false
    }
    
    if ($content -notmatch '<Version>') {
        Write-Host "[ERROR] playbook.conf missing <Version>" -ForegroundColor Red
        return $false
    }
    
    if ($content -notmatch '<UniqueId>') {
        Write-Host "[ERROR] playbook.conf missing <UniqueId>" -ForegroundColor Red
        return $false
    }

    Write-Host "[OK] playbook.conf valid" -ForegroundColor Green
    return $true
}

function Test-YamlFiles {
    param([string]$Path)
    
    $yamlFiles = Get-ChildItem $Path -Filter "*.yml" -Recurse
    $valid = $true
    
    foreach ($file in $yamlFiles) {
        $content = Get-Content $file.FullName -Raw
        
        # Check for front matter
        if ($content -notmatch '^---') {
            Write-Host "[WARN] $($file.Name) missing YAML front matter" -ForegroundColor Yellow
            continue
        }
        
        # Check for title
        if ($content -notmatch '^title:') {
            Write-Host "[WARN] $($file.Name) missing title" -ForegroundColor Yellow
        }
        
        # Check for actions
        if ($content -notmatch 'actions:') {
            Write-Host "[WARN] $($file.Name) missing actions section" -ForegroundColor Yellow
        }
        
        Write-Host "[OK] $($file.Name)" -ForegroundColor Green
    }
    
    return $valid
}

function Test-PowerShellScripts {
    param([string]$Path)
    
    $ps1Files = Get-ChildItem $Path -Filter "*.ps1" -Recurse
    $valid = $true
    
    foreach ($file in $ps1Files) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $file.FullName -Raw), [ref]$null)
            Write-Host "[OK] $($file.Name) parses" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] $($file.Name) parse error: $_" -ForegroundColor Red
            $valid = $false
        }
    }
    
    return $valid
}

function Test-Structure {
    param([string]$Path)
    
    $required = @(
        'playbook.conf',
        'Configuration\main.yml',
        'Configuration\Tasks\core',
        'Configuration\Tasks\privacy',
        'Configuration\Tasks\performance',
        'Configuration\Tasks\gaming',
        'Configuration\Tasks\services',
        'Configuration\Tasks\packages',
        'Configuration\Tasks\registry',
        'Configuration\Tasks\developer',
        'Configuration\Tasks\networking',
        'Configuration\Tasks\security',
        'Configuration\Tasks\optional',
        'Configuration\Tasks\revert.yml',
        'Executables\Scripts\backup.ps1',
        'Executables\Scripts\restore.ps1'
    )
    
    $valid = $true
    foreach ($item in $required) {
        $fullPath = Join-Path $Path $item
        if (!(Test-Path $fullPath)) {
            Write-Host "[ERROR] Missing required file/directory: $item" -ForegroundColor Red
            $valid = $false
        } else {
            Write-Host "[OK] $item" -ForegroundColor Green
        }
    }
    
    return $valid
}

Write-Host "`n=== Validating Argus Windows Playbook ===" -ForegroundColor Cyan

$results = @(
    @{ Name = "Structure"; Result = Test-Structure -Path $projectDir }
    @{ Name = "playbook.conf"; Result = Test-PlaybookConf -Path (Join-Path $projectDir "playbook.conf") }
    @{ Name = "YAML files"; Result = Test-YamlFiles -Path (Join-Path $projectDir "Configuration") }
    @{ Name = "PowerShell scripts"; Result = Test-PowerShellScripts -Path (Join-Path $projectDir "Executables") }
)

$allValid = $results | ForEach-Object { $_.Result } | Where-Object { $_ -eq $false } | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
foreach ($result in $results) {
    $status = if ($result.Result) { "PASS" } else { "FAIL" }
    $color = if ($result.Result) { "Green" } else { "Red" }
    Write-Host "$($result.Name): " -NoNewline
    Write-Host $status -ForegroundColor $color
}

if ($allValid -eq 0) {
    Write-Host "`n[OK] All validations passed" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[ERROR] $allValid validation(s) failed" -ForegroundColor Red
    exit 1
}
