<#
.Synopsis
    Gets data for audit ConfigMgr.
.DESCRIPTION
    The script recollect all data necesary for infrastructure audit. That include:
    - Device properties: Name, ResourceID, IsClient, SiteCode, ClientVersion, DeviceOS, DeviceOSBuild, EPEnabled, EPEngineVersion, EPClientVersion,EPAntivirusEnabled,EPAntivirusSignatureLastVersion, IsVirtualMachine, LastActiveTime
    - Site Data: Servername,SiteCode,BuildNumber,Version
    - Discovery Methods
    - Software Update Point Components
    - ClientSettings defined by ClientInsurance
    - Administrative Users list & roles
.EXAMPLE
    .\ClientInsurance_V1.3.1.ps1
.VERSION
    1.3.2   
.NOTES
    Author - Alejandro Aguado
    Developed in www.VendorIT.com for ClientInsurance
#>

Clear-Host
Write-Output "Starting data collection.....wait please"
# Path to output file.
$csvPathOutput = "C:\OutputPowershell\"
if((Test-Path $csvPathOutput) -eq $false){New-Item -Path $csvPathOutput -ItemType Directory |Out-Null}


##Block Site Data
# Collect Site Data
$siteData = Get-CmSite | Select-Object Servername,SiteCode,BuildNumber,Version
#Export to CSV
$siteData | Export-Csv -Path $csvPathOutput"reportSite.csv" -NoTypeInformation
##End Block

##Block Devices data.
# Collect devices data.
$collectDevices = Get-CMDevice -Fast | Select-Object Name, ResourceID, IsClient, SiteCode, ClientVersion, DeviceOS, DeviceOSBuild, EPEnabled, EPEngineVersion, EPClientVersion,EPAntivirusEnabled,EPAntivirusSignatureLastVersion, IsVirtualMachine, LastActiveTime
#Export to CSV
$collectDevices | Export-Csv -Path $csvPathOutput"reportDevices.csv" -NoTypeInformation
##EndBlock

Clear-Host
Write-Output "Continue data collection.....Please be patient"
##Block Discovery Methods
# Collect discovery methods
$SystemDiscovery = Get-CMDiscoveryMethod -Name ActiveDirectorySystemDiscovery
$GroupDiscovery = Get-CMDiscoveryMethod -Name ActiveDirectoryGroupDiscovery
$DiscoveryMethodResults = @()
Foreach($ItemSystem in $SystemDiscovery){
# Create System method Objc.
    $DiscoveryMethodObjc = New-Object -TypeName PSobject
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "DiscoveryMethod" -Value "Active Directory System Discovery"
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "Enable" -Value $ItemSystem.Flag
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "SiteCode" -Value $ItemSystem.SiteCode
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "EnableFilteringExpiredPassword" -Value $($ItemSystem.props | Where-Object {$_.PropertyName -eq 'Enable Filtering Expired Password'}).value
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "DaysSinceLastPasswordSet" -Value $($ItemSystem.props | Where-Object {$_.PropertyName -eq 'Days Since Last Password Set'}).value
    $DiscoveryMethodResults += $DiscoveryMethodObjc
}
Foreach($ItemGroup in $GroupDiscovery){
# Create Group method Objc.
    $DiscoveryMethodObjc = New-Object -TypeName PSobject
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "DiscoveryMethod" -Value "Active Directory Group Discovery"
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "Enable" -Value $ItemGroup.Flag
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "SiteCode" -Value $ItemGroup.SiteCode
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "EnableFilteringExpiredPassword" -Value $($ItemGroup.props | Where-Object {$_.PropertyName -eq 'Enable Filtering Expired Password'}).value
    $DiscoveryMethodObjc | Add-Member -MemberType NoteProperty -Name "DaysSinceLastPasswordSet" -Value $($ItemGroup.props | Where-Object {$_.PropertyName -eq 'Days Since Last Password Set'}).value
    $DiscoveryMethodResults += $DiscoveryMethodObjc
}
# Export CSV
$DiscoveryMethodResults | Export-Csv -Path $csvPathOutput"reportDiscoveryMethods.csv" -NoTypeInformation
##EndBlock

##Block Software Update Point Components
# Collect Data
$supComponent = Get-CMSoftwareUpdatePointComponent
$supComponentObjectList = @()
foreach ($site in $supComponent){
$supSyncComponent = Get-CMSoftwareUpdatePointComponent -WsusSyncManager -SiteCode $site.Sitecode
# Create Object

$supComponentObject = New-Object -TypeName PSobject
if ($supSyncComponent.props[-2].Value1 -eq ""){$supComponentObject | Add-Member -MemberType NoteProperty -Name "Sync Scheduled" -Value "Disabled"}
else {
    $supSchedule = Convert-CMSchedule -ScheduleString $supSyncComponent.props[-2].Value1
    $supComponentObject | Add-Member -MemberType NoteProperty -Name "Sync Scheduled" -Value "Enabled"
    $supComponentObject | Add-Member -MemberType NoteProperty -Name "Sync Scheduled Type" -Value $supSchedule.SmsProviderObjectPath
    switch($supSchedule.SmsProviderObjectPath){
        'SMS_ST_NonRecurring' {$supComponentObject | Add-Member -MemberType NoteProperty -Name SyncValue -Value "Only one"}
        'SMS_ST_RecurInterval' {$supComponentObject | Add-Member -MemberType NoteProperty -Name SyncValue -Value $supSchedule.DaySpan}
        'SMS_ST_RecurMonthlyByDate' {$supComponentObject | Add-Member -MemberType NoteProperty -Name SyncValue -Value $supSchedule.MonthDay}
        'SMS_ST_RecurMonthlyByWeekday' {$supComponentObject | Add-Member -MemberType NoteProperty -Name SyncValue -Value $supSchedule.WeekOrder}
        'SMS_ST_RecurWeekly' {$supComponentObject | Add-Member -MemberType NoteProperty -Name SyncValue -Value $supSchedule.Day}
        }
}
$supComponentObject | Add-Member -MemberType NoteProperty -Name "SiteCode" -Value $site.Sitecode
$supComponentObject | Add-Member -MemberType NoteProperty -Name "Decline expired updates" -Value $($site.Props | Where-Object {$_.PropertyName -eq 'Call WSUS Cleanup'}).Value
$supComponentObject | Add-Member -MemberType NoteProperty -Name "Add non-clustered indexes" -Value $($site.Props | Where-Object {$_.PropertyName -eq 'Call WSUS Delete Obselete Updates'}).Value
$supComponentObject | Add-Member -MemberType NoteProperty -Name "Remove obsolete updates" -Value $($site.Props | Where-Object {$_.PropertyName -eq 'Call WSUS Indexing'}).Value
$supComponentObject | Add-Member -MemberType NoteProperty -Name "Supersedence Mode For NonFeature" -Value $($site.Props | Where-Object {$_.PropertyName -eq 'Sync Supersedence Mode For NonFeature'}).Value
$supComponentObject | Add-Member -MemberType NoteProperty -Name "Months For NonFeature Expire" -Value $($site.Props | Where-Object {$_.PropertyName -eq 'Sync Supersedence Age For NonFeature'}).Value
$supComponentObject | Add-Member -MemberType NoteProperty -Name "Supersedence Mode For Feature" -Value $($site.Props | Where-Object {$_.PropertyName -eq 'Sync Supersedence Mode For Feature'}).Value
$supComponentObject | Add-Member -MemberType NoteProperty -Name "Months For Feature Expire" -Value $($site.Props | Where-Object {$_.PropertyName -eq 'Sync Supersedence Age For Feature'}).Value
$supComponentObjectList += $supComponentObject
}

#Export to CSV
$supComponentObjectList | Export-Csv -Path $csvPathOutput"reportSUPcomponents.csv" -NoTypeInformation
##EndBlock

##Block ClientSettings
# Load all ClientSetting.
$allClientSetting = Get-CMClientSetting
# Selecting only the clientsettings that have SoftwareUpdates settings
$SUClientSetting = @() 
foreach($itemSetting in $allClientSetting){
    if($itemSetting.Name -match "Default"){ $SUClientSetting += $itemSetting } #Add default client setting
    foreach($itemAgentId in $itemSetting.AgentConfigurations){
        if(($itemAgentId.agentid -eq 9) -or ($itemAgentId.agentid -eq 2) -or ($itemAgentId.agentid -eq 15)){ $SUClientSetting += $itemSetting }        
    } 
}
$SUClientSetting = $SUClientSetting | Sort-Object -Unique
$deployListObj = @()
foreach ($iSetting in $SUClientSetting){
    if ($iSetting.AssignmentCount -gt 0){
        $deploy = Get-CMClientSettingDeployment -Name $iSetting.name
        foreach ($iDeploy in $deploy){
            $deployCollection = Get-CMCollection -Name $iDeploy.CollectionName
            $deployObject = New-Object -TypeName PSobject
            $deployObject | Add-Member -MemberType NoteProperty -Name "ClientSettingName" -Value $iSetting.Name
            $deployObject | Add-Member -MemberType NoteProperty -Name "CollectionDeploy" -Value $iDeploy.CollectionName
            $deployObject | Add-Member -MemberType NoteProperty -Name "DevicesInCollection" -Value $deployCollection.MemberCount
            $deployListObj += $deployObject
            }
    }
    elseif ($iSetting.AssignmentCount -eq 0){
        $deploy = Get-CMCollection -Name $iSetting.name
        $deployObject = New-Object -TypeName PSobject
        $deployObject | Add-Member -MemberType NoteProperty -Name "ClientSettingName" -Value $iSetting.Name
        $deployObject | Add-Member -MemberType NoteProperty -Name "CollectionDeploy" -Value "No Deploy"
        $deployObject | Add-Member -MemberType NoteProperty -Name "DevicesInCollection" -Value 0
        $deployListObj += $deployObject
        }
    
}
# Generating list with configuration data for each client setting.
$reportClientSettingSoftwareUpdates = @()
$reportClientSettingHarwareInventory = @()
$reportClientSettingSoftwareInventory = @()
$maxCollectionDeploySoftwareUpdates = 0
$maxCollectionDeployHarwareInventory = 0
$maxCollectionDeploySoftwareInventory = 0
foreach ($item in $SUClientSetting ){
    #Data for SoftwareUpdates
    $ClientSettingSoftwareUpdates = Get-CMClientSetting -Setting SoftwareUpdates -Name $item.Name
    if((($null -ne $ClientSettingSoftwareUpdates) -and ($item.AssignmentCount -gt 0)) -or ($item.Name -eq 'Default Client Agent Settings') ){
        $ClientSettingObj = New-Object -TypeName PSobject
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "ClientSetting" -Value $item.Name
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "Type" -Value "SoftwareUpdates"
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value $ClientSettingSoftwareUpdates.Enabled
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "SoftwareUpdateScanSchedule" -Value $(Convert-CMSchedule $ClientSettingSoftwareUpdates.ScanSchedule).DaySpan
        $count = 0
        $listTemp = $deployListObj | Where-Object {$_.ClientSettingName -eq $item.name}
        if($listTemp.Count -gt $maxCollectionDeploySoftwareUpdates){$maxCollectionDeploySoftwareUpdates = $listTemp.Count}
        foreach ($itemlistTemp in $listTemp){
            $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "CollectionDeploy$count" -Value $itemlistTemp.CollectionDeploy
            $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "DevicesInCollection$count" -Value $itemlistTemp.DevicesInCollection
            $count += 1}
        $reportClientSettingSoftwareUpdates += $ClientSettingObj
        }
    #Data for Hardware Inventory
    $ClientSettingHarwareInventory = Get-CMClientSetting -Setting HardwareInventory -Name $item.Name
    if((($null -ne $ClientSettingHarwareInventory) -and ($item.AssignmentCount -gt 0)) -or ($item.Name -eq 'Default Client Agent Settings') ){
        $ClientSettingObj = New-Object -TypeName PSobject
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "ClientSetting" -Value $item.Name
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "Type" -Value "HardwareInventory"
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value $ClientSettingHarwareInventory.Enabled
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "HardwareInventorySchedule" -Value $(Convert-CMSchedule $ClientSettingHarwareInventory.Schedule).DaySpan
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "MaxRandomDelayMinutes" -Value $ClientSettingHarwareInventory.MaxRandomDelayMinutes
        $count = 0
        $listTemp = $deployListObj | Where-Object {$_.ClientSettingName -eq $item.name}
        if($listTemp.Count -gt $maxCollectionDeployHarwareInventory){$maxCollectionDeployHarwareInventory = $listTemp.Count}
        foreach ($itemlistTemp in $listTemp){
            $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "CollectionDeploy$count" -Value $itemlistTemp.CollectionDeploy
            $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "DevicesInCollection$count" -Value $itemlistTemp.DevicesInCollection
            $count += 1}
        $reportClientSettingHarwareInventory += $ClientSettingObj
        }
    #Data for Software Inventory
    $ClientSettingSoftwareInventory = Get-CMClientSetting -Setting SoftwareInventory -Name $item.Name
    if((($null -ne $ClientSettingSoftwareInventory) -and ($item.AssignmentCount -gt 0)) -or ($item.Name -eq 'Default Client Agent Settings') ){
        $ClientSettingObj = New-Object -TypeName PSobject
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "ClientSetting" -Value $item.Name
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "Type" -Value "SoftwareInventory"
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "Enabled" -Value $ClientSettingSoftwareInventory.Enabled
        $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "HardwareInventorySchedule" -Value $(Convert-CMSchedule $ClientSettingSoftwareInventory.Schedule).DaySpan
        $count = 0
        $listTemp = $deployListObj | Where-Object {$_.ClientSettingName -eq $item.name}
        if($listTemp.Count -gt $maxCollectionDeploySoftwareInventory){$maxCollectionDeploySoftwareInventory = $listTemp.Count}
        foreach ($itemlistTemp in $listTemp){
            $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "CollectionDeploy$count" -Value $itemlistTemp.CollectionDeploy
            $ClientSettingObj | Add-Member -MemberType NoteProperty -Name "DevicesInCollection$count" -Value $itemlistTemp.DevicesInCollection
            $count += 1}
        $reportClientSettingSoftwareInventory += $ClientSettingObj
        }  
    }
$maxCollectionDeploySoftwareUpdates = $maxCollectionDeploySoftwareUpdates-1
$maxCollectionDeployHarwareInventory = $maxCollectionDeployHarwareInventory-1
$maxCollectionDeploySoftwareInventory = $maxCollectionDeploySoftwareInventory-1  
# Export to CSV
$reportClientSettingSoftwareUpdates | Sort-Object -Property "CollectionDeploy$maxCollectionDeploySoftwareUpdates" | Export-Csv -Path $csvPathOutput"reportClientSettingSoftwareUpdates.csv" -NoTypeInformation
$reportClientSettingHarwareInventory |Sort-Object -Property "CollectionDeploy$maxCollectionDeployHarwareInventory" | Export-Csv -Path $csvPathOutput"reportClientSettingHarwareInventory.csv" -NoTypeInformation
$reportClientSettingSoftwareInventory |Sort-Object -Property "CollectionDeploy$maxCollectionDeploySoftwareInventory" | Export-Csv -Path $csvPathOutput"reportClientSettingSoftwareInventory.csv" -NoTypeInformation
##EndBlock

##Block Administrative Users
$reportAdministrativeUsers = @()
$administrativeUsersList = Get-CMAdministrativeUser | Select-Object LogonName, RoleNames
foreach ($iUser in $administrativeUsersList){
    foreach($iRoleName in $iUser.RoleNames){
        $iUserobjc = New-Object -TypeName PSobject
        $iUserobjc | Add-Member -MemberType NoteProperty -Name "LogonName" -Value $iUser.LogonName
        $iUserobjc | Add-Member -MemberType NoteProperty -Name "RoleName" -Value $iRoleName
        $reportAdministrativeUsers += $iUserobjc
        }
    }
# Export to CSV
$reportAdministrativeUsers | Export-Csv -Path $csvPathOutput"reportAdministrativeUsers.csv" -NoTypeInformation


#Create file errors
$error | Out-File $csvPathOutput"reportErrors.txt" 

# Report to console
Clear-Host
Write-Host "Data collection has been completed."
Write-Host "You can found results in: " -NoNewline
Write-Host $csvPathOutput$csvFileOutput -ForegroundColor DarkMagenta
Write-Host "Please zip the folder and send for e-mail"