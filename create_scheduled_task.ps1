# Define variables
$taskName = "CleanEpicGamesFolder"
$taskDescription = "Deletes contents of C:\Program Files\Epic Games at each system startup."
$scriptPath = "C:\Program Files\Windows1\run.bat"

# Check if the task already exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask -ne $null) {
    Write-Output "Scheduled task '$taskName' already exists."
    exit 0
}

# Define actions, triggers, and principal with elevated privileges
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "System" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden

# Register the scheduled task
try {
    $task = Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force -ErrorAction Stop
    Write-Output "Scheduled task '$taskName' created successfully."
}
catch {
    Write-Error "Failed to create scheduled task '$taskName': $_"
    exit 1
}
