# Win11-no-ads

Remove advertisements, suggestions, and promotional content from Windows 11.

This repository provides PowerShell scripts and individual commands to disable various advertising features in Windows 11.

---

## ⚠️ Important: Create a Registry Backup First!

Before making any changes, **always back up your registry**. If something goes wrong, you can restore it.

### Method 1: PowerShell Backup (Recommended)

Open **PowerShell as Administrator** and run these commands to back up the relevant registry keys:

```powershell
# Create a backup folder on your Desktop
$BackupDir = "$env:USERPROFILE\Desktop\Registry-Backup-$(Get-Date -Format 'yyyy-MM-dd')"
New-Item -ItemType Directory -Force -Path $BackupDir
```

```powershell
# Export the system-wide CloudContent policy key
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "$BackupDir\CloudContent-Policy.reg" /y
```

```powershell
# Export the per-user ContentDeliveryManager key (the ad engine)
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "$BackupDir\ContentDeliveryManager.reg" /y
```

### Method 2: UI Method (Using regedit)

1. Press `Win + R`, type `regedit`, and press Enter
2. Click **Yes** on the User Account Control prompt
3. Navigate to: `HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CloudContent`
4. Right-click on **CloudContent** → **Export** → Save the file
5. Navigate to: `HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager`
6. Right-click on **ContentDeliveryManager** → **Export** → Save the file
7. Keep these `.reg` files safe. Double-click them to restore if needed.

---

## 🚀 Quick Start: Run the Full Script

If you want to disable all ads at once, run the automated script:

```powershell
# Download and run (or clone the repo and run locally)
.\scripts\win11-ad-removal.ps1
```

The script will:
- Create automatic backups
- Apply all ad-blocking settings
- Generate a restore script

---

## 📋 Individual Commands

Below are individual commands you can copy and run one at a time. **Run PowerShell as Administrator** for all commands.

### Disable Windows Consumer Features (System-Wide)

This single setting disables most pre-installed promotional apps for all users:

```powershell
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f
```

---

### Disable Content Delivery Manager (Master Switches)

These settings disable the core advertising system:

**Disable Content Delivery (Master Switch)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /t REG_DWORD /d 0 /f
```

**Disable Subscribed Content (Targeted Suggestions)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContentEnabled /t REG_DWORD /d 0 /f
```

**Disable Silent App Installation**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f
```

**Disable Pre-Installed Apps**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f
```

**Disable OEM Pre-Installed Apps**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f
```

---

### Disable Start Menu Suggestions

**Disable System Pane Suggestions**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f
```

**Disable Soft Landing (Tips/Tutorials)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /t REG_DWORD /d 0 /f
```

---

### Disable Feature Experiments

Prevents Windows from testing experimental features on your PC:

```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v FeatureManagementEnabled /t REG_DWORD /d 0 /f
```

---

### Disable Specific Ad Campaign Channels

These numbered settings correspond to specific types of promotional content:

**Disable "Get Started" Suggestions (310093)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-310093Enabled /t REG_DWORD /d 0 /f
```

**Disable App Suggestions in Share Dialog (314559)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-314559Enabled /t REG_DWORD /d 0 /f
```

**Disable Start Menu App Suggestions (338387)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338387Enabled /t REG_DWORD /d 0 /f
```

**Disable Additional Start Menu Suggestions (338388)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f
```

**Disable Tips and Suggestions Notifications (338389)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f
```

**Disable Suggestions in Settings App (353694)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f
```

**Disable Windows Spotlight Recommendations (353696)**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f
```

---

### Disable Lock Screen Ads

**Disable Rotating Lock Screen Images with Suggestions**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v RotatingLockScreenEnabled /t REG_DWORD /d 0 /f
```

**Disable Lock Screen Overlay Text/Links**
```powershell
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v RotatingLockScreenOverlayEnabled /t REG_DWORD /d 0 /f
```

---

## 🔄 Run All Per-User Commands at Once

Copy this entire block to apply all per-user settings at once:

```powershell
# All per-user ad-blocking settings
$CDM = "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
reg add $CDM /v ContentDeliveryAllowed /t REG_DWORD /d 0 /f
reg add $CDM /v SubscribedContentEnabled /t REG_DWORD /d 0 /f
reg add $CDM /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f
reg add $CDM /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f
reg add $CDM /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f
reg add $CDM /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f
reg add $CDM /v SoftLandingEnabled /t REG_DWORD /d 0 /f
reg add $CDM /v FeatureManagementEnabled /t REG_DWORD /d 0 /f
reg add $CDM /v SubscribedContent-310093Enabled /t REG_DWORD /d 0 /f
reg add $CDM /v SubscribedContent-314559Enabled /t REG_DWORD /d 0 /f
reg add $CDM /v SubscribedContent-338387Enabled /t REG_DWORD /d 0 /f
reg add $CDM /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f
reg add $CDM /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f
reg add $CDM /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f
reg add $CDM /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f
reg add $CDM /v RotatingLockScreenEnabled /t REG_DWORD /d 0 /f
reg add $CDM /v RotatingLockScreenOverlayEnabled /t REG_DWORD /d 0 /f
```

---

## 🔙 Restoring Settings

### Method 1: Using Backup Files

Double-click the `.reg` files you exported earlier, or run:

```powershell
reg import "C:\path\to\your\backup\CloudContent-Policy.reg"
reg import "C:\path\to\your\backup\ContentDeliveryManager.reg"
```

### Method 2: Re-enable Individual Settings

To re-enable any setting, change the value from `0` to `1`. For example:

```powershell
# Re-enable content delivery
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /t REG_DWORD /d 1 /f
```

### Method 3: Delete Individual Settings

To remove a specific setting and return to Windows defaults:

```powershell
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /f
```

---

## 📁 Files in This Repository

| File | Description |
|------|-------------|
| `scripts/win11-ad-removal.ps1` | Main script - runs all commands with backup |
| `scripts/win11-ad-removal-explained.ps1` | Educational version with detailed comments explaining each line |
| `README.md` | This documentation file |

---

## 🔄 Reboot Required

After making changes, **restart your computer** for all settings to take effect.

---

## ⚠️ Disclaimer

Modify your registry at your own risk. Always create backups before making changes. These scripts are provided as-is without warranty.

---

## 📚 Learning PowerShell

Check out `scripts/win11-ad-removal-explained.ps1` for a heavily commented version that explains:
- What each command does
- PowerShell syntax and concepts
- How the registry modifications work
- Best practices for error handling

This is a great resource if you're learning PowerShell scripting!
