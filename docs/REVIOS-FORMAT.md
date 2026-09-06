# ReviOS Playbook Format Analysis

**Source:** `C:\Users\Era\Downloads\Revi-PB-26.04.apbx`
**Extracted:** 2026-09-05
**Archive format:** 7z (LZMA2:21 7zAES), password: `malte`

## Critical Finding: Archive Format

ReviOS uses **7z format**, not ZIP:
```
Type = 7z
Method = LZMA2:21 7zAES
Solid = +
Blocks = 1
```

Our playbook uses ZIP format. This is likely the root cause of AME Wizard loading failures.

## Directory Structure

```
playbook.conf          # XML metadata at root
playbook.png           # Thumbnail at root
Configuration/
└── Tasks/             # ALL YAML files under Tasks/
    ├── main.yml       # Entry point
    ├── start.yml      # Initialization
    ├── services.yml   # Service configuration
    ├── registry.yml   # Registry orchestrator
    ├── revert.yml     # Upgrade rollback
    ├── final.yml      # Finalization
    ├── software.yml   # Software installation
    ├── packages/
    │   ├── appx.yml
    │   ├── app-win32.yml
    │   ├── optional-features.yml
    │   └── win-sxs.yml
    └── registry/
        ├── explorer/
        │   ├── context-menu.yml
        │   ├── control-panel.yml
        │   ├── explorer.yml
        │   ├── notifications.yml
        │   ├── search.yml
        │   ├── start-menu.yml
        │   ├── taskbar.yml
        │   ├── view.yml
        │   └── win-settings.yml
        ├── misc/
        │   ├── classic-photo-viewer.yml
        │   ├── deprovisioned-apps.yml
        │   ├── disable-logging.yml
        │   ├── fixes.yml
        │   └── ...
        ├── privacy/
        │   ├── app-compat.yml
        │   ├── cdm.yml
        │   ├── ceip.yml
        │   ├── cloud-content.yml
        │   ├── privacy.yml
        │   ├── telemetry.yml
        │   └── wer.yml
        ├── security/
        │   ├── bitlocker.yml
        │   ├── security.yml
        │   └── vbs.yml
        ├── system/
        │   ├── boot.yml
        │   ├── bypass-requirements.yml
        │   ├── crash-control.yml
        │   ├── disable-automatic-maintenance.yml
        │   ├── ifeo.yml
        │   ├── kernel.yml
        │   ├── logon.yml
        │   ├── multimedia.yml
        │   ├── oobe.yml
        │   ├── power.yml
        │   └── win32ps.yml
        └── updates/
            ├── drivers.yml
            ├── ms-store.yml
            └── updates.yml
Executables/
├── *.ps1               # PowerShell scripts
├── *.cmd               # CMD scripts
├── *.xml               # Layout/association files
├── *.json              # Settings files
├── BraveSoftware/      # Browser preferences
├── Licenses/           # License files
└── Wallpapers/         # Wallpaper images
Images/
└── *.png               # Browser icons for RadioImagePage
```

## playbook.conf Schema (Actual)

```xml
<?xml version="1.0" encoding="utf-8"?>
<Playbook>
    <Name>ReviOS</Name>
    <Username>Revision</Username>
    <Title>ReviOS Playbook</Title>
    <ShortDescription>Playbook for Windows 10 and 11</ShortDescription>
    <Description>This Playbook will help you quickly deploy ReviOS on your current system.</Description>
    <Details>Experience an ideal, lightweight and stable system...</Details>
    <Version>26.04</Version>
    <UniqueId>6a93ec26-284d-4943-9fc4-c9616def55c6</UniqueId>
    <UpgradableFrom>any</UpgradableFrom>
    <SupportedBuilds>
        <string>19044</string>
        <string>19045</string>
        <string>22631</string>
        <string>26100</string>
        <string>26200</string>
    </SupportedBuilds>
    <Requirements>
        <Requirement>DefenderToggled</Requirement>
        <Requirement>NoPendingUpdates</Requirement>
        <Requirement>NoAntivirus</Requirement>
        <Requirement>Internet</Requirement>
        <Requirement>PluggedIn</Requirement>
    </Requirements>
    <UseKernelDriver>false</UseKernelDriver>
    <ProductCode>32</ProductCode>
    <Git>https://github.com/meetrevision/playbook</Git>
    <Website>https://revi.cc</Website>
    <DonateLink>https://revi.cc/donate</DonateLink>
    <SupportsISO>true</SupportsISO>
    <ISO>
        <DisableBitLocker>true</DisableBitLocker>
        <DisableHardwareRequirements>true</DisableHardwareRequirements>
    </ISO>
    <OOBE>
        <BulletPoints>
            <BulletPoint Icon="Rocket" Title="Performance Boost" Description="..."/>
            <BulletPoint Icon="Privacy" Title="Enhanced Privacy" Description="..."/>
            <BulletPoint Icon="Lock" Title="Revision Tool" Description="..."/>
        </BulletPoints>
        <Internet>Force</Internet>
    </OOBE>
    <Software>
        <Package Option="browser-brave" DefaultWebBrowser="true">
            <Name>brave</Name>
            <Title>Brave</Title>
            <Description>...</Description>
            <Icon>brave.png</Icon>
        </Package>
    </Software>
    <FeaturePages>
        <!-- RadioImagePage for browser selection -->
        <RadioImagePage CheckDefaultBrowser="true" DependsOn="software"
            DefaultOption="browser-brave" IsRequired="true"
            Description="Please select a preferred browser...">
            <Options>
                <RadioImageOption None="true" />
                <RadioImageOption>
                    <Text>Brave</Text>
                    <Name>browser-brave</Name>
                    <FileName>brave</FileName>
                    <GradientTopColor>#392DD1</GradientTopColor>
                    <GradientBottomColor>#A91B78</GradientBottomColor>
                </RadioImageOption>
            </Options>
            <BottomLine Text="Privacy comparison" Link="https://privacytests.org/" />
        </RadioImagePage>
        
        <!-- RadioPage with TopLine + BottomLine + 2 options = VALID -->
        <RadioPage DefaultOption="disable-hibernate" Description="...">
            <TopLine Text="This includes Fast Startup"/>
            <Options>
                <RadioOption>
                    <Text>Disable Hibernate (Default)</Text>
                    <Name>disable-hibernate</Name>
                </RadioOption>
                <RadioOption>
                    <Text>Enable Hibernate</Text>
                    <Name>enable-hibernate</Name>
                </RadioOption>
            </Options>
            <BottomLine Text="⚠ Disabling may overheat laptops in sleep mode"/>
        </RadioPage>
        
        <!-- CheckboxPage with IsChecked attribute -->
        <CheckboxPage IsRequired="true" Description="...">
            <Options>
                <CheckboxOption IsChecked="true">
                    <Text>Remove Microsoft Edge</Text>
                    <Name>remove-edge</Name>
                </CheckboxOption>
                <CheckboxOption IsChecked="false">
                    <Text>Remove Xbox apps</Text>
                    <Name>remove-appx-xbox</Name>
                </CheckboxOption>
            </Options>
        </CheckboxPage>
    </FeaturePages>
</Playbook>
```

## YAML Configuration Schema (Actual)

### Entry Point (main.yml)
```yaml
---
title: Custom
description: Custom Revision configuration
privilege: Admin
actions:
  - !task: {path: 'Tasks\start.yml'}
  - !task: {path: 'Tasks\packages\app-win32.yml'}
  - !taskKill: {name: "explorer", errorAction: Ignore}
  - !task: {path: 'Tasks\registry.yml'}
  - !task: {path: 'Tasks\revert.yml'}
  - !task: {path: 'Tasks\final.yml'}
```

### Task File Structure
```yaml
---
title: Initialization
description: Copies Revision folders/files
privilege: TrustedInstaller
actions:
  - !writeStatus: {status: "Initializing"}
  
  - !registryValue:
    path: 'HKCU\SOFTWARE\...'
    value: 'Enabled'
    type: REG_DWORD
    data: '0'
  
  - !cmd:
    exeDir: true
    command: 'robocopy "Licenses" "%SystemDrive%\Licenses" /E /PURGE'
    ignoreErrors: true
    weight: 30
  
  - !download:
    url: 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
    destination: "vc_redist.x64.exe"
    overwrite: true
  
  - !run:
    exeDir: true
    exe: "vc_redist.x64.exe"
    args: '/quiet /norestart'
  
  - !powerShell:
    wait: true
    exeDir: true
    errorAction: Ignore
    weight: 48
    command: >-
      .\APPX-REMOVER.ps1 -Packages @(...)
  
  - !registryValue:
    path: 'HKLM\SOFTWARE\...'
    value: '...'
    type: REG_DWORD
    data: '0'
    option: "remove-appx-photos"
    weight: 10
```

### Key Syntax Patterns

| Pattern | Example |
|---------|---------|
| Task path with backslash | `!task: {path: 'Tasks\registry\explorer\taskbar.yml'}` |
| File-level privilege | `privilege: TrustedInstaller` |
| Run with path+exe | `!run: {path: "%ProgramFiles%\\Revision Tool", exe: "revitool.exe", args: "..."}` |
| exeDir working directory | `exeDir: true` |
| OOBE-only | `oobe: only` |
| Weight for progress | `weight: 150` |
| Multiple options | `options: ["configure-darkmode", "configure-wallpaper"]` |
| Option negation | `option: "!configure-darkmode"` |
| Error handling | `errorAction: Ignore` |
| Ignore errors | `ignoreErrors: true` |
| Multi-line command | `command: >-` followed by indented lines |
| Show output | `showOutput: false, showError: false` |
| Overwrite download | `overwrite: true` |
| Clear Appx cache | `!appx: {operation: clearCache, name: '*Client.CBS*'}` |

### Registry Value Action
```yaml
- !registryValue: 
  path: 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
  value: 'RevisionWallpaperStartup'
  type: REG_SZ
  oobe: only
  data: 'cmd /c "...'
  option: "configure-wallpaper"
```

### Service Action
```yaml
- !service: {name: 'dam', operation: change, startup: 4}
# startup: 2=Auto, 3=Manual, 4=Disabled
```

### Appx Action
```yaml
- !appx: {operation: clearCache, name: '*Client.CBS*'}
- !appx: {operation: clearCache, name: '*StartMenuExperienceHost*', option: "remove-pinned-items-startmenu"}
```

### Registry Key Action
```yaml
- !registryKey: {path: 'HKCR\ms-gamebar\shell\open\command', operation: add, option: "remove-appx-xbox"}
```

## User Hive Handling

ReviOS uses **both** `HKCU\...` and `HKU\.DEFAULT\...` for user-specific settings:
```yaml
- !registryValue: {path: 'HKCU\Software\Microsoft\...', value: '...', type: REG_DWORD, data: '0'}
- !registryValue: {path: 'HKU\.DEFAULT\Software\Microsoft\...', value: '...', type: REG_DWORD, data: '0'}
```

They do NOT use `AME_UserHive_Default` or load hives manually.

## Upgrade/Rollback Pattern

```yaml
# revert.yml
---
title: Rollback Tweaks
description: Rollback tweaks for previous versions
privilege: TrustedInstaller
onUpgrade: true
actions:
  - !registryValue: {path: '...', value: '...', operation: delete}
  - !service: {name: '...', operation: change, startup: 1}
```

## Browser Selection Pattern

```xml
<RadioImagePage CheckDefaultBrowser="true" DependsOn="software"
    DefaultOption="browser-brave" IsRequired="true"
    Description="...">
    <Options>
        <RadioImageOption None="true" />
        <RadioImageOption>
            <Text>Brave</Text>
            <Name>browser-brave</Name>
            <FileName>brave</FileName>
            <GradientTopColor>#392DD1</GradientTopColor>
            <GradientBottomColor>#A91B78</GradientBottomColor>
        </RadioImageOption>
    </Options>
    <BottomLine Text="Privacy comparison" Link="https://privacytests.org/" />
</RadioImagePage>
```

## What Needs to Change in Our Playbook

1. **Archive format**: Switch from ZIP to 7z with 7zAES encryption
2. **Directory structure**: Move all YAML under `Configuration/Tasks/`
3. **Task paths**: Use backslashes (`Tasks\registry\...`) not forward slashes
4. **playbook.conf**: Remove CDATA, add `<Software>` section, fix RadioPage constraints
5. **YAML syntax**: Add `privilege:` at file level, use `exeDir: true`, `weight:`, `oobe:`, `errorAction:`
6. **User hive**: Use `HKU\.DEFAULT\...` instead of `AME_UserHive_Default`
7. **Remove manual hive loading/unloading**: ReviOS doesn't do this
8. **Add revert.yml**: For upgrade rollback scenarios
9. **Add download/run patterns**: For tools and dependencies
10. **Add weight attributes**: For progress indication
