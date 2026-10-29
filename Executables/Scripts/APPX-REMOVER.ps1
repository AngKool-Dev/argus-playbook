<#
.SYNOPSIS
    Argus Windows Playbook - AppX Remover
.DESCRIPTION
    Removes specified AppX packages and deprovisions them
#>

param(
    [string[]]$Packages
)

$ErrorActionPreference = 'Stop'

foreach ($pkg in $Packages) {
    try {
        $found = Get-AppxPackage -Name $pkg -AllUsers -ErrorAction SilentlyContinue
        if ($found) {
            $found | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Output "[OK] Removed $pkg"
        }
    } catch {
        Write-Output "[WARN] Failed to remove $pkg : $_"
    }
}

try {
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    foreach ($pkg in $Packages) {
        $match = $provisioned | Where-Object { $_.DisplayName -like $pkg -or $_.PackageName -like $pkg }
        if ($match) {
            Remove-AppxProvisionedPackage -Online -PackageName $match.PackageName -ErrorAction SilentlyContinue
            Write-Output "[OK] Deprovisioned $($match.DisplayName)"
        }
    }
} catch {
    Write-Output "[WARN] Deprovisioning failed: $_"
}
