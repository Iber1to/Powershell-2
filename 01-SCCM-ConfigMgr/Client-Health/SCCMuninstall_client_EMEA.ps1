
$TimeStamp= Get-Date

#Compruebo si el script se ejecuto en las ultimas 72 horas, si lo ha hecho, se interrumpe el script.
$TestLastRun= Test-Path 'HKLM:\SOFTWARE\SccmUninstall\'
If($TestLastRun)
    {
    $RunInterval= ([DateTime]((Get-ItemProperty -Path 'HKLM:\SOFTWARE\SccmUninstall' -Name LastRun).LastRun)).AddHours(72)
    if ($RunInterval -gt $TimeStamp ){EXIT}
    }
#Si no se ha ejecutado nunca creo las entradas de registro para marcarlo como ejecutado
else{
        New-Item -Path 'HKLM:\SOFTWARE\' -Name 'SccmUninstall' -Force
        New-ItemProperty -Path 'HKLM:\SOFTWARE\SccmUninstall\' -Name 'LastRun' -Value $TimeStamp
    }

#Si el script no se ha ejecutado nunca, o lo hizo hace más de 72 horas,la desinstalación se ejecuta.

#Uninstall SCCMclient
Invoke-Command -ScriptBlock {Start-Process -FilePath 'C:\Windows\ccmsetup\ccmsetup.exe' -ArgumentList '/uninstall' -Wait}

# Delete the file with the certificate GUID and SMS GUID that current Client was registered with
Remove-Item -Path "$($Env:WinDir)\smscfg.ini" -Force -Confirm:$false -Verbose

# Delete the certificate itself
Remove-Item -Path 'HKLM:\Software\Microsoft\SystemCertificates\SMS\Certificates\*' -Force -Confirm:$false -Verbose

# Remove the Namespaces from the WMI repository
Get-CimInstance -query "Select * From __Namespace Where Name='CCM'" -Namespace "root" | Remove-CimInstance -Verbose -Confirm:$false
Get-CimInstance -query "Select * From __Namespace Where Name='CCMVDI'" -Namespace "root" | Remove-CimInstance -Verbose -Confirm:$false
Get-CimInstance -query "Select * From __Namespace Where Name='SmsDm'" -Namespace "root" | Remove-CimInstance -Verbose -Confirm:$false
Get-CimInstance -query "Select * From __Namespace Where Name='sms'" -Namespace "root\cimv2" | Remove-CimInstance -Verbose -Confirm:$false

#Marcamos la fecha de ejecución         
Set-ItemProperty -Path 'HKLM:\SOFTWARE\SccmUninstall\' -Name 'LastRun' -Value $TimeStamp

#Añadimos el equipo al csv para sacarlo del grupo de AD
$DeviceName= $env:COMPUTERNAME
$DeviceDomain= $env:USERDNSDOMAIN
$MyDevice = New-Object System.Object
$MyDevice | Add-Member -Type NoteProperty -Name 'Name' -Value $env:COMPUTERNAME
$MyDevice |Export-Csv -Path \\SRV002\client\Duplicados\eliminar_Duplicados_EMEA.csv -NoTypeInformation -Append    

    

   
