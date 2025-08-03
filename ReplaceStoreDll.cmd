@echo off
:: BatchGotAdmin
:: Check for administrator privileges
NET FILE >nul 2>&1
if '%errorlevel%' == '0' (
    goto :main
) else (
    echo Requesting administrative privileges...
    powershell -command "Start-Process -FilePath 'cmd' -ArgumentList '/c %~dpnx0 %*' -Verb RunAs"
    exit /b
)

:main
echo Running with administrative privileges...

:: Set paths
set "sys32_dll=c:\windows\system32\Windows.ApplicationModel.Store.dll"
set "syswow64_dll=c:\windows\syswow64\Windows.ApplicationModel.Store.dll"
set "backup_sys32=dll\backup\system32\Windows.ApplicationModel.Store.dll"
set "backup_syswow64=dll\backup\syswow64\Windows.ApplicationModel.Store.dll"
set "new_sys32=dll\new\system32\Windows.ApplicationModel.Store.dll"
set "new_syswow64=dll\new\syswow64\Windows.ApplicationModel.Store.dll"

:: Create backup directories if they don't exist
if not exist "dll\backup\system32\" mkdir "dll\backup\system32\"
if not exist "dll\backup\syswow64\" mkdir "dll\backup\syswow64\"

:: Function to process a file
:ProcessFile
setlocal
set "file=%~1"
set "backup=%~2"
set "new=%~3"

echo Processing %file%

:: Take ownership
echo Taking ownership of %file%
takeown /f "%file%" >nul
icacls "%file%" /grant administrators:F >nul

:: Backup file
echo Backing up %file% to %backup%
if exist "%file%" (
    copy "%file%" "%backup%" >nul
    if errorlevel 1 (
        echo Failed to backup %file%
        exit /b 1
    )
) else (
    echo File not found: %file%
    exit /b 1
)

:: Replace file
echo Replacing %file% with %new%
if exist "%new%" (
    copy /y "%new%" "%file%" >nul
    if errorlevel 1 (
        echo Failed to replace %file%
        exit /b 1
    )
    echo Successfully replaced %file%
) else (
    echo New file not found: %new%
    exit /b 1
)

endlocal
goto :eof

:: Process both files
call :ProcessFile "%sys32_dll%" "%backup_sys32%" "%new_sys32%"
call :ProcessFile "%syswow64_dll%" "%backup_syswow64%" "%new_syswow64%"

echo Operation completed successfully.
pause