<#
.SYNOPSIS
    Replaces Windows.ApplicationModel.Store.dll files with custom versions
.DESCRIPTION
    This script:
    1. Temporarily sets execution policy to Unrestricted
    2. Takes ownership of system DLLs
    3. Creates backups
    4. Replaces with custom DLLs
    5. Restores original execution policy
.NOTES
    Requires administrator privileges
#>

#Requires -RunAsAdministrator

# Store original execution policy
$originalPolicy = Get-ExecutionPolicy -Scope LocalMachine
$processPolicy = Get-ExecutionPolicy -Scope Process

try {
    # Temporarily set execution policy to Unrestricted
    Write-Host "Temporarily setting execution policy to Unrestricted..."
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force

    # Define paths
    $sys32_dll = "C:\Windows\System32\Windows.ApplicationModel.Store.dll"
    $syswow64_dll = "C:\Windows\SysWOW64\Windows.ApplicationModel.Store.dll"
    $backup_sys32 = "$PSScriptRoot\dll\backup\system32\Windows.ApplicationModel.Store.dll"
    $backup_syswow64 = "$PSScriptRoot\dll\backup\syswow64\Windows.ApplicationModel.Store.dll"
    $new_sys32 = "$PSScriptRoot\dll\new\system32\Windows.ApplicationModel.Store.dll"
    $new_syswow64 = "$PSScriptRoot\dll\new\syswow64\Windows.ApplicationModel.Store.dll"

    function Process-File {
        param (
            [string]$sourceFile,
            [string]$backupFile,
            [string]$newFile
        )

        Write-Host "`nProcessing $sourceFile" -ForegroundColor Cyan

        # Check if source file exists
        if (-not (Test-Path $sourceFile)) {
            Write-Error "Source file not found: $sourceFile"
            return $false
        }

        # Create backup directory if it doesn't exist
        $backupDir = [System.IO.Path]::GetDirectoryName($backupFile)
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }

        # Take ownership
        try {
            Write-Host "Taking ownership of $sourceFile"
            takeown /f $sourceFile | Out-Null
            icacls $sourceFile /grant administrators:F | Out-Null
        }
        catch {
            Write-Error "Failed to take ownership of $sourceFile : $_"
            return $false
        }

        # Backup file
        try {
            Write-Host "Backing up to $backupFile"
            Copy-Item -Path $sourceFile -Destination $backupFile -Force
        }
        catch {
            Write-Error "Failed to backup $sourceFile : $_"
            return $false
        }

        # Replace file
        if (-not (Test-Path $newFile)) {
            Write-Error "New file not found: $newFile"
            return $false
        }

        try {
            Write-Host "Replacing with $newFile"
            Copy-Item -Path $newFile -Destination $sourceFile -Force
            Write-Host "Successfully replaced file" -ForegroundColor Green
            return $true
        }
        catch {
            Write-Error "Failed to replace $sourceFile : $_"
            return $false
        }
    }

    # Main execution
    try {
        Write-Host "`nStarting DLL replacement process..." -ForegroundColor Yellow

        # Process both files
        $success1 = Process-File -sourceFile $sys32_dll -backupFile $backup_sys32 -newFile $new_sys32
        $success2 = Process-File -sourceFile $syswow64_dll -backupFile $backup_syswow64 -newFile $new_syswow64

        if ($success1 -and $success2) {
            Write-Host "`nOperation completed successfully.`n" -ForegroundColor Green
        }
        else {
            Write-Host "`nOperation completed with errors.`n" -ForegroundColor Red
        }
    }
    catch {
        Write-Error "An unexpected error occurred during file operations: $_"
    }
}
finally {
    # Always restore original execution policy
    Write-Host "`nRestoring original execution policy..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy -ExecutionPolicy $originalPolicy -Scope LocalMachine -Force -ErrorAction Stop
        Set-ExecutionPolicy -ExecutionPolicy $processPolicy -Scope Process -Force -ErrorAction Stop
        Write-Host "Execution policy restored to $originalPolicy" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to restore execution policy: $_"
        Write-Warning "Please manually check your execution policy with: Get-ExecutionPolicy -List"
    }

    # Keep console open if not running in ISE
    if ($Host.Name -notmatch "ISE") {
        Write-Host "`nPress any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}