# Argus Windows Playbook

Professional, auditable AME Wizard playbook for Windows 11 customization.

## Philosophy

- **Stability over benchmark screenshots**
- **Reversible changes** wherever technically possible
- **Security is never destroyed** for minor performance gains
- **Every modification is documented** and auditable
- **No hidden downloads** or unverified binaries

## Supported Windows Versions

- Windows 11 24H2 (Build 26100)
- Windows 11 25H2 (Build 26200)
- Windows 11 Insider (Build 26300)

## Profiles

| Profile | Purpose | Aggression |
|---------|---------|------------|
| Safe | Minimal changes, maximum compatibility | Low |
| Balanced | Recommended everyday configuration | Medium |
| Performance | Aggressive performance optimizations | High |
| Gaming | Gaming-focused optimizations | Medium |
| Custom | User-selectable individual options | Variable |

**Note:** Privacy and Developer settings are available as individual toggles in the CheckboxPages, independent of the selected profile.

## Installation

1. Download [AME Wizard](https://amelabs.net/)
2. Extract AME Wizard to a folder
3. Run `AME Wizard.exe` as Administrator
4. Drag `Argus Windows Playbook.apbx` into AME Wizard
5. Select your profile and options
6. Click Run

## What This Playbook Does

- Optimizes system performance safely
- Reduces unnecessary background activity
- Configures privacy settings without breaking updates
- Optimizes for gaming when selected
- Prepares the system for development workflows
- Cleans up UI clutter and unnecessary features
- Manages AppX packages with user control

## What This Playbook Does NOT Do

- Remove core Windows components without explicit selection
- Blindly disable Windows Update
- Blindly disable Microsoft Defender
- Break the Microsoft Store, Settings, or networking
- Download random executables from the internet
- Hide modifications in encrypted binaries

## Restoration

A backup is created before any modifications. To restore:

```powershell
# Run from elevated PowerShell
.\Executables\Scripts\restore.ps1
```

Or specify a specific backup:

```powershell
.\Executables\Scripts\restore.ps1 -BackupPath "C:\ProgramData\ArgusPlaybook\backup-20250101-120000"
```

## Building

```powershell
.\build.ps1
```

Output: `Argus Windows Playbook.apbx`

## Validation

```powershell
.\validate.ps1
```

## Security

This playbook:
- Uses only native Windows and PowerShell functionality
- Does not download external binaries
- Does not execute remote scripts
- Creates a backup before modifications
- Logs all changes to `C:\ProgramData\ArgusPlaybook\`

See [SECURITY.md](SECURITY.md) for details.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.
