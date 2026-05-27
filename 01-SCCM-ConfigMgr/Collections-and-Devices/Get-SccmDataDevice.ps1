

<#
.SYNOPSIS
    Recopila datos de los dispositivos en una coleccion SCCM y los exporta a un archivo.

.DESCRIPTION
    Trae datos de distintos sitios de SCCM para crear un objeto unico por dispositivo.
    Los origenes de datos son:
        Get-CMDevice
        Get-CMResource
        SMS_G_System_PC_BIOS
        SMS_G_System_BATTERY
        SMS_G_System_OPERATING_SYSTEM
        SMS_G_System_ENCRYPTABLE_VOLUME

.PARAMETER TargetCollection
    La coleccion con los dispositivos que vamos a procesar. Por defecto 'CAS0003A' llamada '00-GLOBAL_MGM_WS_(Principal_Coll)'

.PARAMETER PathCSV
    Ruta completa para el archivo donde exportar los resultados 
    Example: 'C:\temp\archivo.csv'



.NOTES
    Author:  IT Automation
    Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Twitter: @Alejand94399487
#> 

function Connect-CMSite
{ 


[CmdletBinding()] 
    param (
        [ValidateNotNullOrEmpty()]
        [string]$SiteCode = "CAS",
        [string]$ProviderMachineName = "SRV004.contoso.local"               
          )

# Importando el ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}

# Monta la unidad del sitio si no existe todavia
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
}

# Cambia la localización al codigo de sitio
Set-Location "$($SiteCode):\" 
}

Function Get-PatchTuesday {
  [CmdletBinding()]
  Param
  (
    [Parameter(position = 0)]
    [ValidateSet("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
    [String]$weekDay = 'Tuesday',
    [ValidateRange(0, 5)]
    [Parameter(position = 1)]
    [int]$findNthDay = 2
  )
  # Get the date and find the first day of the month
  # Find the first instance of the given weekday
  [datetime]$today = [datetime]::NOW
  $todayM = $today.Month.ToString()
  $todayY = $today.Year.ToString()
  [datetime]$strtMonth = $todayM + '/1/' + $todayY
  while ($strtMonth.DayofWeek -ine $weekDay ) { $strtMonth = $StrtMonth.AddDays(1) }
  $firstWeekDay = $strtMonth

  # Identify and calculate the day offset
  if ($findNthDay -eq 1) {
    $dayOffset = 0
  }
  else {
    $dayOffset = ($findNthDay - 1) * 7
  }
  
  # Return date of the day/instance specified
  $patchTuesday = $firstWeekDay.AddDays($dayOffset) 
  return $patchTuesday
}

Connect-CMSite

#Coleccion Principal MGM.
$TargetCollection= 'CAS0003A'

#Path para el export a CSV.
$PathCSV= 'C:\temp\sccmdata.csv'

#Consigue el mes para los deployment. El 2 miercoles de cada mes cambia el mes de deployment. 
$PatchTuesday= Get-PatchTuesday
$FechaActual= Get-Date
if($FechaActual.DayOfYear -le $PatchTuesday.DayOfYear){$Month= $FechaActual.Month-1}else{$Month= $FechaActual.Month}


#Cargando datos de dispositivos
$GetCMdeviceData= Get-CMDevice -CollectionId CAS0003A
$GetCMResourceData= Get-CMResource  -ResourceType System  -Fast |Select-Object Active,Build,BuildExt,Client,CPUType,CreationDate,ESUValue,FullDomainName,@{Name = 'IPAddresses';Expression = {$_.IPAddresses[0]}},@{Name = 'IPSubnets';Expression = {$_.IPSubnets[0]}},LastLogonTimestamp,LastLogonUserName,Obsolete,operatingSystem,operatingSystemServicePack,operatingSystemVersion,ResourceId, @{Name = 'MACAddresses';Expression = {$_.MACAddresses[0]}} |Group ResourceId -AsHashTable
$GetSerialNumberData= Get-WmiObject -Namespace root\sms\site_CAS -Class SMS_G_System_PC_BIOS |Select-Object ResourceId, SerialNumber |Group ResourceId -AsHashTable
$GetBatteryData= Get-WmiObject -Namespace root\sms\site_CAS -Class SMS_G_System_BATTERY |Select-Object ResourceId,BatteryStatus |Group ResourceId -AsHashTable
$GetOperatinSytemData = Get-WmiObject -Namespace root\sms\site_CAS -Class SMS_G_System_OPERATING_SYSTEM | Select-Object ResourceId, caption, Version |Group ResourceId -AsHashTable
$GetBitlockerStatusData= Get-WMIObject  -Namespace root\sms\site_CAS -class SMS_G_System_ENCRYPTABLE_VOLUME -Filter "DriveLetter= 'C:'"  |Select-Object ProtectionStatus, ResourceID |Group ResourceId -AsHashTable

#Cargando Datos deploy Updates (Esta copiado a capon de otro script).
$Win10Deploys= Get-CMSoftwareUpdateDeployment -Name ADR_GLOBAL_SUP_Windows_10_2021_M$Month | select AssignmentName, AssignmentID
$Win7Deploys= Get-CMSoftwareUpdateDeployment -Name ADR_GLOBAL_SUP_Windows_7_2021_M$Month |where -Property AssignmentName -Like ADR_GLOBAL_SUP_Windows_7_2021_M* | select AssignmentName, AssignmentID 
$AllWinPatchs= $Win7Deploys+$Win10Deploys
$StatusTypeList= 1,2,5,4
$TotalDevicesPatch=$TotalDevicesPatchSucces=$TotalDevicesPatchInPro=$TotalDevicesPatchError=$TotalDevicesPatchUnknown=@()

#Aqui puede fallar el script si el numero de deploys es distinto de 12. 6 por cada anillo de distribucion y por SO (W10 y W7).
if($AllWinPatchs.count -ne 12){Write-Output "El numero de Patchs a calcular no es correcto y el script se detendra";Exit}
foreach($deploy in $AllWinPatchs.AssignmentID)
    {
    foreach($StatusItem in $StatusTypeList)
        {
        $Output = Get-WMIObject  -Namespace root\sms\site_CAS -class SMS_SUMDeploymentAssetDetails -Filter "AssignmentID = $deploy and StatusType = $StatusItem" | select ResourceId, @{Name = 'PatchStatusTime'; Expression = {$_.ConvertToDateTime($_.StatusTime) }}, @{Name = 'PatchStatus' ; Expression = {if ($_.StatusType -eq 1) {'Success'} elseif ($_.StatusType -eq 2) {'InProgress'} elseif ($_.StatusType -eq 5) {'Error'} elseif ($_.StatusType -eq 4) {'Unknown'}  }}
        $TotalDevicesPatch+=$Output
        switch($StatusItem)
            {
            1 {$TotalDevicesPatchSucces+=$Output}
            2 {$TotalDevicesPatchInPro+=$Output}
            5 {$TotalDevicesPatchError+=$Output}
            4 {$TotalDevicesPatchUnknown+=$Output}
            }
        }
        
        
    }

$TotalDevicesPatch= $TotalDevicesPatch |Group ResourceId -AsHashTable


#Creando el objeto final

#Listado de Propiedades que se van a crear en el objeto.
$GetCMdeviceProperties= 'AADDeviceID','AADTenantID','ADSiteName','ATPLastConnected','ATPOnboardingState','ATPSenseIsRunning','ClientActiveStatus','ClientCheckPass','ClientState','ClientVersion','CoManaged','DeviceOS','DeviceOSBuild','EPAntispywareEnabled','EPAntispywareSignatureLastUpdateDateTime','EPAntispywareSignatureLastVersion','EPAntivirusEnabled','EPAntivirusSignatureLastUpdateDateTime','EPAntivirusSignatureLastVersion','EPClientVersion','EPEnabled','EPEngineVersion','EPInfectionStatus','EPLastFullScanDateTimeEnd','EPLastFullScanDateTimeStart','EPLastInfectionTime','EPLastQuickScanDateTimeEnd','EPLastQuickScanDateTimeStart','EPLastThreatName','EPPendingFullScan','EPPendingManualSteps','EPPendingOfflineScan','EPPendingReboot','EPPolicyApplicationDescription','EPPolicyApplicationErrorCode','EPPolicyApplicationState','EPProductStatus','IsActive','IsAlwaysInternet','IsAOACCapable','IsApproved','IsAssigned','IsBlocked','IsClient','IsDecommissioned','IsDirect','IsInternetEnabled','IsMDMActive','IsObsolete','IsVirtualMachine','LastActiveTime','LastHardwareScan','LastLogonUser','Name','ResourceID','SiteCode'
$GetCMResourceProperties= 'Active','Build','BuildExt','Client','CPUType','CreationDate','ESUValue','FullDomainName','IPAddresses','IPSubnets','LastLogonTimestamp','LastLogonUserName','MACAddresses','operatingSystemServicePack'
$GetBitlockerStatusProperties= 'ProtectionStatus'
$PatchProperties= 'PatchStatusTime','PatchStatus'
$GetSerialNumberProperties= 'SerialNumber'
$GetBatteryProperties= 'BatteryStatus'
$GetOperatinSytemProperties= 'caption','Version'
$BlankProperties= 'FreeData00','FreeData01','FreeData02','FreeData03','FreeData04','FreeData05','FreeData06','FreeData07','FreeData08','FreeData09'
$MountFinal= New-Object System.Collections.ArrayList

#Cargando los valores de las propiedades en los objetos.
Foreach($data in $GetCMdeviceData){
    $DeviceMount= New-Object -TypeName PSObject
    foreach($prop in $GetCMdeviceProperties){$DeviceMount | Add-Member -MemberType NoteProperty  -Name $prop -Value $data.$prop}
    foreach($prop in $GetCMResourceProperties){$DeviceMount | Add-Member -MemberType NoteProperty  -Name $prop -Value $GetCMResourceData[$Data.ResourceId].$prop}
    foreach($prop in $GetBitlockerStatusProperties){$DeviceMount | Add-Member -MemberType NoteProperty  -Name $prop -Value $GetBitlockerStatusData[$Data.ResourceId].$prop}
    foreach($prop in $PatchProperties){$DeviceMount | Add-Member -MemberType NoteProperty  -Name $prop -Value $TotalDevicesPatch[$Data.ResourceId].$prop}
    foreach($prop in $GetSerialNumberProperties){$DeviceMount | Add-Member -MemberType NoteProperty  -Name $prop -Value $GetSerialNumberData[$Data.ResourceId].$prop}
    foreach($prop in $GetBatteryProperties){$DeviceMount | Add-Member -MemberType NoteProperty  -Name $prop -Value $GetBatteryData[$Data.ResourceId].$prop}
    foreach($prop in $GetOperatinSytemProperties){$DeviceMount | Add-Member -MemberType NoteProperty  -Name $prop -Value $GetOperatinSytemData[$Data.ResourceId].$prop}
    foreach($prop in $BlankProperties){$DeviceMount | Add-Member -MemberType NoteProperty  -Name $prop -Value ''}


    $MountFinal.add($DeviceMount) |Out-Null
}


#Exportando a archivo CSV

$TestPathCSV= Test-Path -Path $PathCSV
if($TestPathCSV){
    Remove-Item -Path $PathCSV -Force
    $MountFinal | Export-Csv -NoTypeInformation -Path $PathCSV}
else{$MountFinal | Export-Csv -NoTypeInformation -Path $PathCSV}

