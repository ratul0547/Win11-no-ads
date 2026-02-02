# ===== Windows 11 Ad & Suggestion Blocker (Final Hardened) =====
# Creates registry backups and disables Windows 11 advertisements, suggestions, and feature experiments
# Run as Administrator

# ===== ADMIN CHECK =====
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    Read-Host "Press Enter to exit"
    exit 1
}

# ===== CONFIG =====
$Timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$BackupDir = "$env:USERPROFILE\Desktop\Win11-Reg-Backup-$Timestamp"

try {
    New-Item -ItemType Directory -Force -Path $BackupDir -ErrorAction Stop | Out-Null
} catch {
    Write-Error "Failed to create backup directory: $_"
    Read-Host "Press Enter to exit"
    exit 1
}

# Keys to back up
$Keys = @(
    "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
    "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
)

# ===== BACKUP =====
Write-Host "`n=== Creating Registry Backups ===" -ForegroundColor Cyan

foreach ($key in $Keys) {
    $safeName = ($key -replace "[\\:/\s]", "_")
    $outputFile = "$BackupDir\$safeName.reg"

    reg query $key 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        reg export $key $outputFile /y 2>&1 | Out-Null
        if ((Test-Path $outputFile) -and ((Get-Item $outputFile).Length -gt 0)) {
            Write-Host "✓ Backed up: $key" -ForegroundColor Green
        } else {
            Write-Warning "Export produced empty file: $key"
        }
    } else {
        Write-Host "⊗ Key doesn't exist (will be created): $key" -ForegroundColor Yellow
    }
}

# ===== RESTORE FILES =====
$RestoreInfo = @"
# RESTORE INSTRUCTIONS

Option 1 (Easy):
Run RESTORE.ps1 as Administrator.

Option 2:
Double-click each .reg file in this folder.

Option 3 (Manual):
Open PowerShell in this folder and run:
Get-ChildItem *.reg | ForEach-Object { reg import `$_.FullName }

Reboot after restoring.
"@
$RestoreInfo | Out-File "$BackupDir\RESTORE_INSTRUCTIONS.txt" -Encoding UTF8

# Create restore script
$RestoreScript = @"
# Registry Restore Script
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Run as Administrator."
    Read-Host "Press Enter to exit"
    exit 1
}

`$ScriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
Write-Host "`n=== Restoring Registry Settings ===" -ForegroundColor Cyan
Write-Host "Location: `$ScriptDir`n"

`$RegFiles = Get-ChildItem "`$ScriptDir\*.reg" -ErrorAction SilentlyContinue

if (`$null -eq `$RegFiles -or `$RegFiles.Count -eq 0) {
    Write-Warning "No .reg files found in `$ScriptDir"
    Read-Host "Press Enter to exit"
    exit 1
}

`$Success = 0
`$Failed = 0

foreach (`$file in `$RegFiles) {
    reg import `$file.FullName 2>&1 | Out-Null
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "✓ Restored: `$(`$file.Name)" -ForegroundColor Green
        `$Success++
    } else {
        Write-Warning "✗ Failed: `$(`$file.Name)"
        `$Failed++
    }
}

Write-Host "`nRestored: `$Success" -ForegroundColor Green
if (`$Failed -gt 0) {
    Write-Host "Failed: `$Failed" -ForegroundColor Red
}
Write-Host "Reboot required."
Read-Host "Press Enter to exit"
"@
$RestoreScript | Out-File "$BackupDir\RESTORE.ps1" -Encoding UTF8

Write-Host "`nBackup saved to: $BackupDir" -ForegroundColor Green

# ===== APPLY POLICIES =====
Write-Host "`n=== Applying Ad-Blocking Policies ===" -ForegroundColor Cyan

# System-wide policy
$CloudContentPath = "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
reg add $CloudContentPath /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Disabled consumer features (system-wide)" -ForegroundColor Green
} else {
    Write-Warning "Failed to apply system-wide policy"
}

# Per-user ad engine
$CDM = "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
reg query $CDM 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating ContentDeliveryManager registry key..." -ForegroundColor Gray
    reg add $CDM /f 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create ContentDeliveryManager key!"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

$Settings = @{
    # Core switches
    "ContentDeliveryAllowed" = 0
    "SubscribedContentEnabled" = 0
    "SilentInstalledAppsEnabled" = 0
    "PreInstalledAppsEnabled" = 0
    "OemPreInstalledAppsEnabled" = 0
    "SystemPaneSuggestionsEnabled" = 0
    "SoftLandingEnabled" = 0
    "FeatureManagementEnabled" = 0    # Disables feature experiments/rollouts

    # Campaign channels
    "SubscribedContent-310093Enabled" = 0
    "SubscribedContent-314559Enabled" = 0
    "SubscribedContent-338387Enabled" = 0
    "SubscribedContent-338388Enabled" = 0
    "SubscribedContent-338389Enabled" = 0
    "SubscribedContent-353694Enabled" = 0
    "SubscribedContent-353696Enabled" = 0

    # Lock screen
    "RotatingLockScreenEnabled" = 0
    "RotatingLockScreenOverlayEnabled" = 0
}

$Failed = 0
foreach ($setting in $Settings.GetEnumerator()) {
    reg add $CDM /v $setting.Key /t REG_DWORD /d $setting.Value /f 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to set: $($setting.Key)"
        $Failed++
    }
}

# ===== SUMMARY =====
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "✓ Registry backup created" -ForegroundColor Green
if ($Failed -eq 0) {
    Write-Host "✓ All ad-blocking policies applied successfully" -ForegroundColor Green
} else {
    Write-Host "⚠ $Failed settings failed to apply" -ForegroundColor Yellow
}
Write-Host "`nReboot required for full effect." -ForegroundColor Yellow
Write-Host "Backup location: $BackupDir" -ForegroundColor Gray
Write-Host "Restore via: RESTORE.ps1" -ForegroundColor Gray
