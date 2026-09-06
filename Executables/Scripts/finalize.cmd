@echo off
:: Argus Windows Playbook - Finalize
:: Runs final cleanup and verification steps

echo [INFO] Finalizing Argus Windows Playbook...

:: Force group policy update
gpupdate.exe /force >nul 2>&1

:: Refresh Explorer
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe

echo [OK] Finalization complete
