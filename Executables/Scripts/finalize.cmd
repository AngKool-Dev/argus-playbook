@echo off
:: Argus Windows Playbook - Finalization
:: Runs after all optimizations are applied

:: Force group policy update
gpupdate.exe /force >nul 2>&1

echo [OK] Finalization complete
