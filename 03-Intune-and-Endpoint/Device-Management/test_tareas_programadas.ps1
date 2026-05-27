# Create Files to correct paths
if(-not (Test-Path "$($env:windir)\Temp\VendorIT")){
	New-Item -ItemType Directory -Path "$($env:windir)\Temp\VendorIT" -Force
}

$file= @"
"@
        
$file | Out-File "$($env:windir)\Temp\VendorIT\InventoryDevice.ps1" -Encoding utf8

# Create Scheduled task
$listTasks1 = get-scheduledtask -TaskName "InventoryDevice" -ErrorAction SilentlyContinue
if(-not $listTasks1){

    $ScheduleXMl = '<?xml version="1.0" encoding="UTF-16"?>
	<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
	  <RegistrationInfo>
		<Date>2024-02-22T21:10:49.696205</Date>
		<Author>VendorIT Intelligence Workplace</Author>
		<URI>\InventoryDevice</URI>
	  </RegistrationInfo>
	  <Principals>
		<Principal id="Author">
		  <UserId>S-1-5-18</UserId>
		  <RunLevel>HighestAvailable</RunLevel>
		</Principal>
	  </Principals>
	  <Settings>
		<DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
		<StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
		<ExecutionTimeLimit>P1D</ExecutionTimeLimit>
		<Hidden>true</Hidden>
		<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
		<RestartOnFailure>
		  <Count>3</Count>
		  <Interval>PT2H</Interval>
		</RestartOnFailure>
		<StartWhenAvailable>true</StartWhenAvailable>
		<IdleSettings>
		  <StopOnIdleEnd>true</StopOnIdleEnd>
		  <RestartOnIdle>false</RestartOnIdle>
		</IdleSettings>
	  </Settings>
	  <Triggers>
		<CalendarTrigger>
		  <StartBoundary>2024-02-22T15:00:00+01:00</StartBoundary>
		  <ExecutionTimeLimit>PT30M</ExecutionTimeLimit>
		  <RandomDelay>PT30M</RandomDelay>
		  <ScheduleByDay>
			<DaysInterval>1</DaysInterval>
		  </ScheduleByDay>
		</CalendarTrigger>
	  </Triggers>
	  <Actions Context="Author">
		<Exec>
		  <Command>powershell.exe</Command>
		  <Arguments>-file "C:\Windows\Temp\VendorIT\InventoryDevice.ps1" -executionpolicy bypass</Arguments>
		</Exec>
	  </Actions>
	</Task>'

    $taskName = "InventoryDevice"
    register-ScheduledTask -TaskName $taskName -Xml $ScheduleXMl -Force
}


# Nombre de la tarea programada que deseas exportar
$taskName = "InventoryDevice"

# Ruta del archivo XML de salida
$outputPath = "C:\temp\exportedTask.xml"

# Exportar la tarea programada a un archivo XML
Export-ScheduledTask -TaskName $taskName | Out-File $outputPath
