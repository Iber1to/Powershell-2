$Today= Get-Date

#Localizando el servidor WSUS configurado
$Wsuslog= Get-Content -Path C:\Windows\CCM\Logs\WUAHandler.log | Select-String "Existing WUA Managed server was already set"
$WsusName= $Wsuslog[$Wsuslog.Count - 1].ToString().Split("//")[2].split(":")[0]
$WsusDate= [Datetime]::ParseExact(($Wsuslog[$Wsuslog.Count - 1].ToString() -split 'date="')[1].split('"')[0], 'MM-dd-yyyy', $null)
<#if ($WsusDate.AddDays(7) -lt $Today)
    {Write-Host $WsusDate demasiado antigua}
else {$WsusPort= Test-NetConnection -ComputerName $WsusName -Port 8530}
#>
$WsusPort= Test-NetConnection -ComputerName $WsusName -Port 8530
if($WsusPort.TcpTestSucceeded -eq $true){Exit 0}


#Localizando el servidor MP
$MpServerLog= Get-Content -Path C:\Windows\CCM\Logs\CcmNotificationAgent.log | Select-String "AccessMP"
$MpServerName= $MpServerLog[$MpServerLog.Count -1].ToString().Split(' ')[2].split("]")[0]
$MpServerDate= [Datetime]::ParseExact(($MpServerLog[$MpServerLog.Count -1].ToString() -split 'date="')[1].split('"')[0], 'MM-dd-yyyy', $null)