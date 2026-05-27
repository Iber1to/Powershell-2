Import-Module C:\01.Scripts\AAGFunctions.ps1

Connect-CMSite
$Win2012Deploys=$Win2019Deploys=$Win2016Deploys=@()
$Win2012Deploys+= Get-CMSoftwareUpdateDeployment -Name 'ADR_SRV_SUP_Windows_2012_2021_M*' |where -Property AssignmentName -Contains 'Servers | Windows 2012 and 2012 R2_ALL_8' | select AssignmentName, AssignmentID
$Win2019Deploys+= Get-CMSoftwareUpdateDeployment -Name 'ADR_SRV_SUP_Windows_2019_2021_M*'|where -Property AssignmentName -Contains 'Servers | Windows 2019_ALL_M8' | select AssignmentName, AssignmentID
$Win2016Deploys+= Get-CMSoftwareUpdateDeployment -Name 'ADR_SRV_SUP_Windows_2016_2021_M*'|where -Property AssignmentName -Contains 'Servers | Windows 2016_ALL_M8' | select AssignmentName, AssignmentID  
$AllWinDeployments= $Win2012Deploys+$Win2019Deploys+$Win2016Deploys
$StatusTypeList= 1,2,5,4
$TotalDevices=$TotalDevicesSucces=$TotalDevicesInPro=$TotalDevicesError=$TotalDevicesUnknown=@()

if($AllWinDeployments.count -ne 3){Write-Output "El numero de deployments a calcular no es correcto y el script se detendra";Exit}
foreach($deploy in $AllWinDeployments.AssignmentID)
    {
    foreach($StatusItem in $StatusTypeList)
        {
        $Output = Get-WMIObject  -Namespace root\sms\site_CAS -class SMS_SUMDeploymentAssetDetails -Filter "AssignmentID = $deploy and StatusType = $StatusItem" | select DeviceName, CollectionName, @{Name = 'StatusTime'; Expression = {$_.ConvertToDateTime($_.StatusTime) }}, @{Name = 'Status' ; Expression = {if ($_.StatusType -eq 1) {'Success'} elseif ($_.StatusType -eq 2) {'InProgress'} elseif ($_.StatusType -eq 5) {'Error'} elseif ($_.StatusType -eq 4) {'Unknown'}  }}
        write-host $deploy $Output.Count Tipo $StatusItem
        $TotalDevices+=$Output
        switch($StatusItem)
            {
            1 {$TotalDevicesSucces+=$Output}
            2 {$TotalDevicesInPro+=$Output}
            5 {$TotalDevicesError+=$Output}
            4 {$TotalDevicesUnknown+=$Output}
            }
        }
        
        
    }
    $Deploy_Update= New-Object -TypeName PSObject
    $Deploy_Update | Add-Member -MemberType NoteProperty  -Name 'Total Devices' -Value $TotalDevices.Count
    $Deploy_Update | Add-Member -MemberType NoteProperty  -Name 'Total Succes' -Value $TotalDevicesSucces.Count
    $Deploy_Update | Add-Member -MemberType NoteProperty  -Name 'Total In Progress' -Value $TotalDevicesInPro.Count
    $Deploy_Update | Add-Member -MemberType NoteProperty  -Name 'Total Error' -Value $TotalDevicesError.Count
    $Deploy_Update | Add-Member -MemberType NoteProperty  -Name 'Total Unknown' -Value $TotalDevicesUnknown.Count
    $Deploy_Update
    

$html = Get-Content -Path C:\01.Scripts\Send-MailMessage\msgSupDeployResult.htm -Raw
$MailSender = " IT Operator <user@contoso.com>"     
Send-MailMessage  -From $MailSender -to user@contoso.com -bcc user@contoso.com -SmtpServer mail.contoso.com -Subject 'Datos actualizacion Agosto' -BodyAsHtml ($html -f $Deploy_Update.'Total Devices',$Deploy_Update.'Total Succes',$Deploy_Update.'Total In Progress',$Deploy_Update.'Total Error',$Deploy_Update.'Total Unknown',$(get-date -Format dd-MM))    