#Uninstall SCCMclient
Invoke-Command -ScriptBlock {Start-Process -FilePath 'C:\Windows\ccmsetup\ccmsetup.exe' -ArgumentList '/uninstall'}

# Delete the file with the certificate GUID and SMS GUID that current Client was registered with
Remove-Item -Path "$($Env:WinDir)\smscfg.ini" -Force -Confirm:$false -Verbose

# Delete the certificate itself
Remove-Item -Path 'HKLM:\Software\Microsoft\SystemCertificates\SMS\Certificates\*' -Force -Confirm:$false -Verbose

# Remove the Namespaces from the WMI repository
Get-CimInstance -query "Select * From __Namespace Where Name='CCM'" -Namespace "root" | Remove-CimInstance -Verbose -Confirm:$false
Get-CimInstance -query "Select * From __Namespace Where Name='CCMVDI'" -Namespace "root" | Remove-CimInstance -Verbose -Confirm:$false
Get-CimInstance -query "Select * From __Namespace Where Name='SmsDm'" -Namespace "root" | Remove-CimInstance -Verbose -Confirm:$false
Get-CimInstance -query "Select * From __Namespace Where Name='sms'" -Namespace "root\cimv2" | Remove-CimInstance -Verbose -Confirm:$false

# Alternative command for WMI Removal in case of something goes wrong with the above.
# Get-WmiObject -query "Select * From __Namespace Where Name='CCM'" -Namespace "root" | Remove-WmiObject -Verbose | Out-Host
# Get-WmiObject -query "Select * From __Namespace Where Name='CCMVDI'" -Namespace "root" | Remove-WmiObject -Verbose | Out-Host
# Get-WmiObject -query "Select * From __Namespace Where Name='SmsDm'" -Namespace "root" | Remove-WmiObject -Verbose | Out-Host
# Get-WmiObject -query "Select * From __Namespace Where Name='sms'" -Namespace "root\cimv2" | Remove-WmiObject -Verbose | Out-Host

$DeviceName= $env:COMPUTERNAME
$DeviceDomain= $env:USERDNSDOMAIN
$MyDevice = New-Object System.Object
$MyDevice | Add-Member -Type NoteProperty -Name 'Name' -Value $env:COMPUTERNAME
$MyDevice |Export-Csv -Path \\SRV002\client\Duplicados\eliminar_Duplicados_Latam1.csv -NoTypeInformation -Append