$scriptPath = "C:\Pack Intune Apps\bitlocker.ps1"
$taskName = "BackupKeyToAAD"
$taskFolder = "BitLockerTasks"

# Detectar usuario con sesión interactiva (consola)
$session = (Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty UserName)

if (-not $session) {
    Write-Output "No hay usuario interactivo actualmente. Cancelando."
    exit 1
}

# Crear acción de tarea
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`""

# Crear trigger al iniciar sesión
$trigger = New-ScheduledTaskTrigger -AtLogOn

# Crear principal con usuario detectado
$principal = New-ScheduledTaskPrincipal -UserId $session -LogonType Interactive -RunLevel Highest

# Crear folder si no existe
try {
    $null = New-ScheduledTaskFolder -TaskPath "\$taskFolder\" -ErrorAction Stop
} catch {}

# Registrar tarea
Register-ScheduledTask -TaskName $taskName -TaskPath "\$taskFolder\" -Action $action -Trigger $trigger -Principal $principal -Force

Write-Output "Tarea '$taskName' creada para $session con privilegios elevados."