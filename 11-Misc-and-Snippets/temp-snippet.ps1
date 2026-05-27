$PathScriptDestino = "C:\01.Scripts"
$PathScriptOrigen = "\\SRV002.emea.contoso.local\Deploy_logs$\Reparalibreria\reparalibreriadp.ps1"
$CheckPath = Test-Path $PathScriptDestino
If(!$CheckPath){New-Item -ItemType Directory -Path $PathScriptDestino}
Copy-Item -Path $PathScriptOrigen -Destination $PathScriptDestino -Force
if($(Test-Path $PathScriptDestino\reparalibreriadp.ps1 )){exit 0}
else{exit 1}

$PathScript = "C:\01.Scripts\reparalibreriadp.ps1"
$actions = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy ByPass -file $PathScript"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Friday -At "23:00 PM"
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun
$task = New-ScheduledTask -Action $actions -Principal $principal -Trigger $trigger -Settings $settings
Register-ScheduledTask 'ReparalibreriaDP' -InputObject $task