# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this playbook, please report it responsibly.

**Do not** open a public issue for security vulnerabilities.

Instead, please email security concerns to the project maintainers or open a private advisory on GitHub.

## Security Model

### Transparency
- All modifications are documented in public YAML and PowerShell files
- No encrypted binaries or obfuscated scripts
- Every registry change, service modification, and AppX removal is explicitly listed

### No Remote Code Execution
- This playbook does not download executables from the internet
- No `Invoke-WebRequest | iex` or equivalent patterns
- No URL shorteners or redirect chains
- All scripts are locally stored and auditable

### Backup First
- A complete system state backup is created before any modifications
- Backup includes registry keys, service states, scheduled tasks, AppX packages, and power plans
- Restoration script is provided and tested

### Least Privilege
- Scripts request only the privileges they need
- No unnecessary TrustedInstaller escalation
- User-hive modifications are properly isolated

### Reversibility
- Every modification is reversible where technically possible
- Registry changes can be undone via `.reg` files
- Service changes can be reverted via `Set-Service`
- Scheduled tasks are disabled, not deleted

## Known Limitations

1. **No standard uninstall**: AME Wizard playbooks do not have a standardized uninstall mechanism. Use the provided restore script.
2. **Some changes require reinstall**: Deep Windows component removal may require a Windows reinstall to fully revert.
3. **AppX reinstallation**: Removed AppX packages can be reinstalled from the Microsoft Store, but some may not be available.

## Supply Chain

### Dependencies
- **AME Wizard**: Download from https://amelabs.net/
- **7-Zip**: Required for packaging. Download from https://7-zip.org/
- **PowerShell 5.1+**: Built into Windows 10/11

### No Third-Party Binaries
This playbook does not include or require any third-party binaries.
