<#
    .NOTES
    --------------------------------------------------------------------------------
     Code by:  Harry Lowton
     Generated on: 30/06/2014
     Organization: www.harry-lowton.com
    --------------------------------------------------------------------------------
    .DESCRIPTION
        This Script will pull out the active directory site boundaries and then create
        two new folders one for site count and one for client.
        Site Count Folder will show all the devices in that site
        Site clients will show for each site how many ConfigMgr clients are present
 
        It will then create two collection for each site found and move the collection in to the relevant folder.
 
        If you want to change the folder names change these two variables:
        $SiteCount
        $SiteClients
 
#>
 
write-verbose "Importing Configuration Manager Powershell Module"
Import-Module (Join-path $(Split-path $env:sms_admin_UI_Path) Configurationmanager.psd1)
$cmsite = Get-PSProvider CMSite | select drives
$site = [string]::Concat($cmsite.Drives.sitecode,":")  | set-location
 
$sitecount = "Site Count"
$Siteclients = "Site Clients"
 
$value = Get-CMBoundary | Where-Object boundarytype -eq "1" | select value
 
Write-Verbose "Setting the Collection Schedule"
$schedule = New-CMSchedule -RecurCount 1 -RecurInterval Days
#$Schedule = New-CMSchedule -Start "01/01/2014 9:00 PM" -DayOfWeek Monday -RecurCount 1
#$Schedule = New-CMSchedule -Start "01/01/2014 9:00 PM" -DayOfWeek Tuesday -RecurCount 1
#$Schedule = New-CMSchedule -Start "01/01/2014 9:00 PM" -DayOfWeek Wednesday -RecurCount 1
#$Schedule = New-CMSchedule -Start "01/01/2014 9:00 PM" -DayOfWeek Thursday -RecurCount 1
#$Schedule = New-CMSchedule -Start "01/01/2014 9:00 PM" -DayOfWeek Friday -RecurCount 1
#$Schedule = New-CMSchedule -Start "01/01/2014 9:00 PM" -DayOfWeek Saturday -RecurCount 1
#$Schedule = New-CMSchedule -Start "01/01/2014 9:00 PM" -DayOfWeek Sunday -RecurCount 1
 
Write-Verbose "Creating Collection for System Count"
$value | ForEach-Object {New-CMDeviceCollection -Name "$($_.value) Count" -LimitingCollectionName "All Systems" -RefreshSchedule $Schedule} | out-null
 
$value | ForEach-Object {Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$($_.value) Count" -RuleName "SiteQuery" -Queryexpression "select *  from  SMS_R_System where SMS_R_System.ADSiteName = `"$($_.value)`""}
 
$coll1 = $value | ForEach-Object {Get-CMDeviceCollection -Name "$($_.value) Count"}
Write-Verbose -Message "Collections have been created"
 
$sitecountfolder = Test-Path "$site\devicecollection\$sitecount"
 
if ($sitecountfolder -eq "True")
{
     Write-Verbose "Folder exists"
     Write-Verbose "Moving Collections in to the Site Counter Folder"
 
    $coll1 | foreach-object {Move-CMObject -FolderPath "$site\devicecollection\$sitecount" -objectid "$($_.collectionid)" }
 
    Write-verbose "Collection Move Complete"
}
else
{
    new-item -ItemType Folder -Path "$site\DeviceCollection\$sitecount" 
 
    $coll1 | foreach-object {Move-CMObject -FolderPath "$site\devicecollection\$sitecount" -objectid "$($_.collectionid)"}
}
 
Write-Verbose "Creating Collection for System Count"
$value | foreach-object {New-CMDeviceCollection -Name "$($_.value) Clients" -LimitingCollectionName "All Desktop and Server Clients" -RefreshSchedule $Schedule} | out-null
$value | foreach-object {Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$($_.value) Clients" -RuleName "SiteQuery" -Queryexpression "select *  from  SMS_R_System where SMS_R_System.ADSiteName = `"$($_.value)`""}
Write-Verbose -Message "Collections have been created"
    $coll2 = $value | ForEach-Object {Get-CMDeviceCollection -Name "$($_.value) Clients"}
 
    $siteclientfolder = test-path "$site\devicecollection\$Siteclients"
 
if ($siteclientfolder -eq "True")
{
         Write-Verbose "Folder exists"
         Write-Verbose "Moving Collections in to the Site Counter Folder"
 
        $coll2 | foreach-object {Move-CMObject -FolderPath "$site\devicecollection\$Siteclients" -objectid "$($_.collectionid)"
 
         Write-verbose "Collection Move Complete"
     }
 
}
else
{
    Write-verbose "Creating New Folder $siteclients"
 
    new-item -ItemType Folder -Path "$site\DeviceCollection\$Siteclients" 
 
    Write-Verbose "New Folder Created"
 
    $coll2 | foreach-object {Move-CMObject -FolderPath "$site\devicecollection\$Siteclients" -objectid "$($_.collectionid)"
 
    Write-Verbose "Collection Move Complete"
 
    }
}