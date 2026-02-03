# ================================================================================
# Windows 11 Ad & Suggestion Blocker - EDUCATIONAL VERSION WITH DETAILED COMMENTS
# ================================================================================
# Author: Educational version based on win11-ad-removal.ps1
# Purpose: This script disables Windows 11 advertisements, suggestions, and 
#          feature experiments by modifying registry settings
# ================================================================================
#
# HOW THIS SCRIPT WORKS (Overview):
# 1. Checks if running with Administrator privileges (required for registry changes)
# 2. Creates a backup of existing registry keys before making changes
# 3. Generates restore instructions and a restore script
# 4. Applies system-wide policies to disable consumer features
# 5. Applies per-user settings to disable various ad channels
#
# IMPORTANT: Always run this script as Administrator!
# ================================================================================

# ===== SECTION 1: ADMINISTRATOR PRIVILEGE CHECK =====
# Windows registry modifications require elevated (Administrator) privileges.
# This section checks if the script is running with those privileges.

# [Security.Principal.WindowsIdentity]::GetCurrent() - Gets the current Windows user's identity
# [Security.Principal.WindowsPrincipal] - Creates a principal object to check roles/permissions
# IsInRole() - Checks if the user has the specified Windows role (Administrator)
# The "!" or "-NOT" means we're checking if they are NOT an administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    # Write-Warning outputs yellow warning text to indicate a problem
    Write-Warning "This script requires Administrator privileges. Please run as Administrator."
    
    # Read-Host pauses the script and waits for user input (prevents window from closing)
    Read-Host "Press Enter to exit"
    
    # exit 1 - Terminates the script with error code 1 (non-zero = error)
    exit 1
}

# ===== SECTION 2: CONFIGURATION VARIABLES =====
# Variables store data that we'll use throughout the script

# Get-Date -Format "yyyy-MM-dd_HHmmss" - Gets current date/time in a specific format
# Example output: "2024-01-15_143052" (year-month-day_hourminutesecond)
# This creates a unique timestamp for our backup folder name
$Timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

# $env:USERPROFILE - This is an environment variable containing the current user's home folder
# Example: "C:\Users\JohnDoe"
# We concatenate it with a folder name to create: "C:\Users\JohnDoe\Desktop\Win11-Reg-Backup-2024-01-15_143052"
$BackupDir = "$env:USERPROFILE\Desktop\Win11-Reg-Backup-$Timestamp"

# ===== SECTION 3: CREATE BACKUP DIRECTORY =====
# We use try-catch for error handling - if something goes wrong inside "try",
# the code in "catch" runs instead of crashing the script

try {
    # New-Item - Creates a new item (file, folder, etc.)
    # -ItemType Directory - We're creating a folder
    # -Force - Creates parent directories if needed; doesn't error if folder exists
    # -Path $BackupDir - The full path where to create the folder
    # -ErrorAction Stop - If there's an error, throw an exception (triggers catch block)
    # | Out-Null - Discards the output (we don't need to see the folder object created)
    New-Item -ItemType Directory -Force -Path $BackupDir -ErrorAction Stop | Out-Null
} catch {
    # $_ contains the error message/object from the caught exception
    Write-Error "Failed to create backup directory: $_"
    Read-Host "Press Enter to exit"
    exit 1
}

# ===== SECTION 4: DEFINE REGISTRY KEYS TO BACKUP =====
# @() creates an array (a list) of items
# These are the two main registry locations where Windows stores ad-related settings

$Keys = @(
    # HKLM = HKEY_LOCAL_MACHINE (system-wide settings for all users)
    # This key controls Windows consumer features like suggested apps
    "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent",
    
    # HKCU = HKEY_CURRENT_USER (settings for the current user only)
    # ContentDeliveryManager is Windows' "ad engine" that delivers suggestions and ads
    "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
)

# ===== SECTION 5: CREATE REGISTRY BACKUPS =====
# Write-Host displays text to the console
# -ForegroundColor changes the text color (Cyan = light blue)
# `n is an escape sequence for a new line (like pressing Enter)
Write-Host "`n=== Creating Registry Backups ===" -ForegroundColor Cyan

# foreach loops through each item in the $Keys array
# $key is the variable that holds the current item in each iteration
foreach ($key in $Keys) {
    # -replace is a regex (regular expression) operator
    # "[\\:/\s]" matches backslashes, colons, forward slashes, and whitespace
    # "_" is the replacement character
    # This converts "HKLM\SOFTWARE\Policies..." to "HKLM_SOFTWARE_Policies..."
    # This is necessary because file names can't contain \ or : characters
    $safeName = ($key -replace "[\\:/\s]", "_")
    
    # Build the full path for the backup file
    # Example: "C:\Users\JohnDoe\Desktop\Win11-Reg-Backup-2024...\HKLM_SOFTWARE_Policies....reg"
    $outputFile = "$BackupDir\$safeName.reg"

    # reg query - Command to query/check if a registry key exists
    # 2>$null - Redirects error output (stream 2) to null (discards it)
    # | Out-Null - Discards standard output as well
    # We just want to check if it exists, not see the output
    reg query $key 2>$null | Out-Null
    
    # $LASTEXITCODE - Special variable containing the exit code of the last external command
    # 0 = success, non-zero = error
    # So if exit code is 0, the registry key exists
    if ($LASTEXITCODE -eq 0) {
        # reg export - Exports a registry key to a .reg file
        # $key - The registry path to export
        # $outputFile - Where to save the .reg file
        # /y - Overwrite existing file without prompting
        # 2>&1 - Redirects error output to standard output (combines them)
        # | Out-Null - Discards all output
        reg export $key $outputFile /y 2>&1 | Out-Null
        
        # Verify the export worked:
        # Test-Path - Checks if a file/folder exists (returns $true or $false)
        # Get-Item - Gets a file object, .Length is its size in bytes
        # -gt 0 means "greater than 0" (file isn't empty)
        if ((Test-Path $outputFile) -and ((Get-Item $outputFile).Length -gt 0)) {
            Write-Host "✓ Backed up: $key" -ForegroundColor Green
        } else {
            # Write-Warning outputs in yellow color automatically
            Write-Warning "Export produced empty file: $key"
        }
    } else {
        # Key doesn't exist yet - that's okay, we'll create it later
        Write-Host "⊗ Key doesn't exist (will be created): $key" -ForegroundColor Yellow
    }
}

# ===== SECTION 6: CREATE RESTORE INSTRUCTIONS FILE =====
# @"..."@ is a "here-string" - allows multi-line text with preserved formatting
# This creates a text block that will be saved to a file

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

# | Out-File - Pipes (sends) the text content to a file
# -Encoding UTF8 - Uses UTF-8 character encoding (supports special characters)
$RestoreInfo | Out-File "$BackupDir\RESTORE_INSTRUCTIONS.txt" -Encoding UTF8

# ===== SECTION 7: CREATE RESTORE SCRIPT =====
# This creates another PowerShell script that can be used to restore the backup
# Note: The backticks (`) before $ signs are escape characters
# They prevent $Variables from being expanded NOW, so they remain as text in the output file

$RestoreScript = @"
# Registry Restore Script
# This script imports all .reg files in its directory back into the registry

# Check for admin privileges (same as in the main script)
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Run as Administrator."
    Read-Host "Press Enter to exit"
    exit 1
}

# `$MyInvocation.MyCommand.Path - Gets the full path to the currently running script
# Split-Path -Parent - Gets the directory portion of that path
# This finds where the restore script is located
`$ScriptDir = Split-Path -Parent `$MyInvocation.MyCommand.Path
Write-Host "`n=== Restoring Registry Settings ===" -ForegroundColor Cyan
Write-Host "Location: `$ScriptDir`n"

# Get-ChildItem - Like 'dir' or 'ls', lists files
# *.reg - Filter to only .reg files
# -ErrorAction SilentlyContinue - Don't show errors if no files found
`$RegFiles = Get-ChildItem "`$ScriptDir\*.reg" -ErrorAction SilentlyContinue

# Check if we found any .reg files
# `$null comparison should be on left side (best practice)
if (`$null -eq `$RegFiles -or `$RegFiles.Count -eq 0) {
    Write-Warning "No .reg files found in `$ScriptDir"
    Read-Host "Press Enter to exit"
    exit 1
}

# Counter variables to track results
`$Success = 0
`$Failed = 0

# Loop through each .reg file and import it
foreach (`$file in `$RegFiles) {
    # reg import - Imports a .reg file into the registry
    reg import `$file.FullName 2>&1 | Out-Null
    
    # Check if import succeeded
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "✓ Restored: `$(`$file.Name)" -ForegroundColor Green
        `$Success++
    } else {
        Write-Warning "✗ Failed: `$(`$file.Name)"
        `$Failed++
    }
}

# Display results summary
Write-Host "`nRestored: `$Success" -ForegroundColor Green
if (`$Failed -gt 0) {
    Write-Host "Failed: `$Failed" -ForegroundColor Red
}
Write-Host "Reboot required."
Read-Host "Press Enter to exit"
"@

# Save the restore script to the backup directory
$RestoreScript | Out-File "$BackupDir\RESTORE.ps1" -Encoding UTF8

# Inform user where backup was saved
Write-Host "`nBackup saved to: $BackupDir" -ForegroundColor Green

# ===== SECTION 8: APPLY SYSTEM-WIDE AD-BLOCKING POLICY =====
Write-Host "`n=== Applying Ad-Blocking Policies ===" -ForegroundColor Cyan

# This is the local machine policy key - affects ALL users on this computer
$CloudContentPath = "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent"

# reg add - Adds or modifies a registry value
# /v DisableWindowsConsumerFeatures - The value name to create/modify
# /t REG_DWORD - The data type (DWORD = 32-bit integer)
# /d 1 - The data/value to set (1 = enabled/true, 0 = disabled/false)
# /f - Force - don't prompt for confirmation
# This single setting disables most pre-installed promotional apps
reg add $CloudContentPath /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Disabled consumer features (system-wide)" -ForegroundColor Green
} else {
    Write-Warning "Failed to apply system-wide policy"
}

# ===== SECTION 9: APPLY PER-USER AD-BLOCKING SETTINGS =====
# ContentDeliveryManager is Windows' internal name for its advertising system
# These settings are per-user (HKCU = Current User)

$CDM = "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

# First, check if the key exists
reg query $CDM 2>$null | Out-Null

if ($LASTEXITCODE -ne 0) {
    # Key doesn't exist, create it first
    Write-Host "Creating ContentDeliveryManager registry key..." -ForegroundColor Gray
    
    # reg add with just the path and /f creates the key without any values
    reg add $CDM /f 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create ContentDeliveryManager key!"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# ===== SECTION 10: DEFINE ALL AD-RELATED SETTINGS =====
# @{} creates a hashtable (dictionary) - a collection of key-value pairs
# Each setting is a registry value name, and 0 means "disabled"

$Settings = @{
    # ===== Core Advertising Switches =====
    # Master switch for the content delivery system
    "ContentDeliveryAllowed" = 0
    
    # Disables all "subscribed content" (Microsoft's term for targeted suggestions)
    "SubscribedContentEnabled" = 0
    
    # Prevents Windows from silently installing promotional apps
    "SilentInstalledAppsEnabled" = 0
    
    # Disables pre-installed apps that come with fresh Windows installations
    "PreInstalledAppsEnabled" = 0
    
    # Disables pre-installed apps from your computer manufacturer (Dell, HP, etc.)
    "OemPreInstalledAppsEnabled" = 0
    
    # Disables suggestions in the Start menu and system tray
    "SystemPaneSuggestionsEnabled" = 0
    
    # "Soft landing" shows educational tips about Windows features - disable it
    "SoftLandingEnabled" = 0
    
    # Prevents Windows from testing new experimental features on your computer
    "FeatureManagementEnabled" = 0

    # ===== Specific Content Campaign Channels =====
    # These are internal IDs for specific types of promotional content
    # Microsoft uses numbered "campaigns" to deliver different types of ads
    
    # 310093: "Get started" suggestions and welcome messages
    "SubscribedContent-310093Enabled" = 0
    
    # 314559: App suggestions in the "Share" dialog
    "SubscribedContent-314559Enabled" = 0
    
    # 338387: Start menu app suggestions and recommendations
    "SubscribedContent-338387Enabled" = 0
    
    # 338388: Additional Start menu suggestions (secondary channel)
    "SubscribedContent-338388Enabled" = 0
    
    # 338389: "Tips" and "suggestions" notifications
    "SubscribedContent-338389Enabled" = 0
    
    # 353694: Suggestions in Settings app
    "SubscribedContent-353694Enabled" = 0
    
    # 353696: "Recommended" content in Windows Spotlight
    "SubscribedContent-353696Enabled" = 0

    # ===== Lock Screen Advertising =====
    # Disables rotating images with "fun facts" and suggestions on lock screen
    "RotatingLockScreenEnabled" = 0
    
    # Disables the overlay text/links on lock screen images
    "RotatingLockScreenOverlayEnabled" = 0
}

# ===== SECTION 11: APPLY ALL SETTINGS =====
# Counter for failed settings (initializing before the loop)
$Failed = 0

# .GetEnumerator() allows us to loop through hashtable key-value pairs
# Each $setting has a .Key (the name) and .Value (the data)
foreach ($setting in $Settings.GetEnumerator()) {
    # Apply each setting to the registry
    # $setting.Key = the registry value name
    # $setting.Value = the value to set (0)
    reg add $CDM /v $setting.Key /t REG_DWORD /d $setting.Value /f 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to set: $($setting.Key)"
        # Increment the failure counter
        $Failed++
    }
}

# ===== SECTION 12: DISPLAY SUMMARY =====
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "✓ Registry backup created" -ForegroundColor Green

# -eq is "equals" comparison operator
if ($Failed -eq 0) {
    Write-Host "✓ All ad-blocking policies applied successfully" -ForegroundColor Green
} else {
    Write-Host "⚠ $Failed settings failed to apply" -ForegroundColor Yellow
}

# Final instructions for the user
Write-Host "`nReboot required for full effect." -ForegroundColor Yellow
Write-Host "Backup location: $BackupDir" -ForegroundColor Gray
Write-Host "Restore via: RESTORE.ps1" -ForegroundColor Gray

# Pause before closing (prevents window from closing immediately)
Write-Host "`n"
Read-Host "Press Enter to exit"

# ================================================================================
# END OF SCRIPT
# ================================================================================
#
# WHAT EACH SECTION DOES (QUICK REFERENCE):
# 
# Section 1: Checks for Administrator privileges
# Section 2: Sets up variables (timestamp, backup directory path)
# Section 3: Creates the backup folder on the Desktop
# Section 4: Defines which registry keys to back up
# Section 5: Exports those registry keys to .reg files
# Section 6: Creates a text file with restore instructions
# Section 7: Creates a PowerShell script for easy restoration
# Section 8: Applies the system-wide ad-blocking policy
# Section 9: Ensures the ContentDeliveryManager key exists
# Section 10: Defines all the ad-related settings to disable
# Section 11: Applies each setting to the registry
# Section 12: Shows a summary of what was done
#
# ================================================================================
# POWERSHELL CONCEPTS USED IN THIS SCRIPT:
# ================================================================================
#
# VARIABLES:
#   $VariableName = "value"  - Store data for later use
#   $env:USERPROFILE         - Environment variable (system-defined)
#
# ARRAYS:
#   @("item1", "item2")      - Create a list of items
#
# HASHTABLES:
#   @{Key = "Value"}         - Create a dictionary/map
#   .GetEnumerator()         - Loop through key-value pairs
#
# COMPARISON OPERATORS:
#   -eq  (equals)           -ne  (not equals)
#   -gt  (greater than)     -lt  (less than)
#   -and (logical AND)      -or  (logical OR)
#   -NOT (logical NOT)
#
# STRING OPERATORS:
#   -replace "pattern", "replacement"  - Regex replacement
#
# LOOPS:
#   foreach ($item in $collection) { }  - Iterate over each item
#
# CONDITIONALS:
#   if (condition) { } elseif { } else { }
#
# ERROR HANDLING:
#   try { } catch { }       - Handle exceptions gracefully
#   $_ in catch block       - The error that was caught
#
# OUTPUT CMDLETS:
#   Write-Host              - Display text to console (with colors)
#   Write-Warning           - Display warning (yellow)
#   Write-Error             - Display error (red)
#   Out-Null                - Discard output
#   Out-File                - Save to file
#
# SPECIAL VARIABLES:
#   $LASTEXITCODE           - Exit code of last external command
#   $MyInvocation           - Information about current script
#   $_                      - Current item in pipeline or error in catch
#
# CMDLETS USED:
#   Get-Date                - Get current date/time
#   New-Item                - Create files/folders
#   Test-Path               - Check if path exists
#   Get-Item                - Get file/folder properties
#   Get-ChildItem           - List files/folders (like dir/ls)
#   Split-Path              - Extract parts of a path
#   Read-Host               - Get user input (or pause)
#
# EXTERNAL COMMANDS:
#   reg query               - Check if registry key exists
#   reg add                 - Create/modify registry values
#   reg export              - Export registry to .reg file
#   reg import              - Import .reg file to registry
#
# ================================================================================
