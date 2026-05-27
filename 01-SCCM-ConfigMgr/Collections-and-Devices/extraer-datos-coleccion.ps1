#Load Configuration Manager PowerShell Module
Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
Set-Location CAS:

$ExportPath= 'C:\01.-Scripts'
#Trae la propiedad Devicename de los equipos en determinada colección y lo exporta a un CSV
$Devices= Get-CMDevice -CollectionName 'GLOBAL_MGM_WS_QR_Clients_Pending' |Select Domain, name
$Devices | where {$_.domain -like 'APAC'} |select Name|  Export-Csv -Path $ExportPath\Duplicados_APAC.csv -NoTypeInformation
$Devices | where {$_.domain -like 'EMEA'} |select Name|  Export-Csv -Path $ExportPath\Duplicados_EMEA.csv -NoTypeInformation
$Devices | where {$_.domain -like 'LATAM1'} |select Name|  Export-Csv -Path $ExportPath\Duplicados_LATAM1.csv -NoTypeInformation
$Devices | where {$_.domain -like 'LATAM2'} |select Name|  Export-Csv -Path $ExportPath\Duplicados_LATAM2.csv -NoTypeInformation


$DeviceName= $env:COMPUTERNAME
$DeviceDomain= $env:USERDNSDOMAIN

\\SRV002\client\Duplicados
