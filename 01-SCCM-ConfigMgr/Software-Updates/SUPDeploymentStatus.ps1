Import-Module C:\01.Scripts\AAGFunctions.ps1

Connect-CMSite

#Consigue el mes para los deployment
$PatchTuesday= Get-PatchTuesday
$FechaActual= Get-Date
if($FechaActual.DayOfYear -le $PatchTuesday.DayOfYear){$Month= $FechaActual.Month-1}else{$Month= $FechaActual.Month}Switch($Month){
    1 {$MonthString= 'Enero'}
    2 {$MonthString= 'Febrero'}
    3 {$MonthString= 'Marzo'}
    4 {$MonthString= 'Abril'}
    5 {$MonthString= 'Mayo'}
    6 {$MonthString= 'Junio'}
    7 {$MonthString= 'Julio'}
    8 {$MonthString= 'Agosto'}
    9 {$MonthString= 'Septiembre'}
    10 {$MonthString= 'Octubre'}
    11 {$MonthString= 'Noviembre'}
    12 {$MonthString= 'Diciembre'}
    }


$Win10Deploys= Get-CMSoftwareUpdateDeployment -Name ADR_GLOBAL_SUP_Windows_10_2021_M$Month | select AssignmentName, AssignmentID
$Win7Deploys= Get-CMSoftwareUpdateDeployment -Name ADR_GLOBAL_SUP_Windows_7_2021_M$Month |where -Property AssignmentName -Like ADR_GLOBAL_SUP_Windows_7_2021_M* | select AssignmentName, AssignmentID 
$AllWinDeployments= $Win7Deploys+$Win10Deploys
$StatusTypeList= 1,2,5,4
$TotalDevices=$TotalDevicesSucces=$TotalDevicesInPro=$TotalDevicesError=$TotalDevicesUnknown=@()

if($AllWinDeployments.count -ne 12){Write-Output "El numero de deployments a calcular no es correcto y el script se detendra";Exit}
foreach($deploy in $AllWinDeployments.AssignmentID)
    {
    foreach($StatusItem in $StatusTypeList)
        {
        $Output = Get-WMIObject  -Namespace root\sms\site_CAS -class SMS_SUMDeploymentAssetDetails -Filter "AssignmentID = $deploy and StatusType = $StatusItem" | select DeviceName, CollectionName, @{Name = 'StatusTime'; Expression = {$_.ConvertToDateTime($_.StatusTime) }}, @{Name = 'Status' ; Expression = {if ($_.StatusType -eq 1) {'Success'} elseif ($_.StatusType -eq 2) {'InProgress'} elseif ($_.StatusType -eq 5) {'Error'} elseif ($_.StatusType -eq 4) {'Unknown'}  }}
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
$MailSender = " IT Automation <user@contoso.com>"     
Send-MailMessage  -From $MailSender -to user@contoso.com -bcc user@contoso.com -SmtpServer mail.contoso.com -Subject "Datos actualizacion $MonthString" -BodyAsHtml ($html -f $Deploy_Update.'Total Devices',$Deploy_Update.'Total Succes',$Deploy_Update.'Total In Progress',$Deploy_Update.'Total Error',$Deploy_Update.'Total Unknown',$(get-date -Format dd-MM),$MonthString)    