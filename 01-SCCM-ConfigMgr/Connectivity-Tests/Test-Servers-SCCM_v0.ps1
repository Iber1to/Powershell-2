Import-Module "C:\01.Scripts\AAGFunctions.ps1"

Connect-CMSite -SiteCode PE1 -ProviderMachineName SRV002.emea.contoso.local

#Ruta para el path
$PathCMTracelog= 'C:\Scripts de Mantenimiento\TestServidores\TestServidores.log'
if( $(Test-Path -Path $PathCMTracelog)){Remove-Item -Path $PathCMTracelog -Force}

Write-CMTracelog 'Iniciando Test sobre DPs'
#Comprobando conectividad de los DP´s 
$Dp_List= Get-CMDistributionPoint | Select-Object NetworkOsPath
$Dp_list_Com_error135= @()
$Dp_list_Com_error445= @()
foreach($Item in $Dp_List)
{
    $DpName= $Item.NetworkOsPath.Split('\\')[2]
    if($DpName -ne 'cmgcontoso.contoso.com')
    {
        $TestCom_135= Test-NetConnection $DpName -Port 135 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        $TestCom_445= Test-NetConnection $DpName -Port 445 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if($TestCom_135.TcpTestSucceeded -eq $false){$Dp_list_Com_error135 += $DpName}
        else{Write-CMTracelog "Puerto 135 en $DpName Succes"}
        if($TestCom_445.TcpTestSucceeded -eq $false){$Dp_list_Com_error445 += $DpName}
        else{Write-CMTracelog "Puerto 445 en $DpName Succes"}
    }
}

$Error135= $Dp_list_Com_error135 |Out-String
$Error445= $Dp_list_Com_error445 |Out-String
Write-CMTracelog 'Test sobre DPs finalizado'

Write-CMTracelog 'Iniciando Test sobre MPs'
#Comprobando conectividad de los MP´s
$Mp_list= Get-CMManagementPoint -AllSite | Select-Object NetworkOSPath
$Mp_list_Com_error= @()
foreach($Item in $Mp_list)
    {
    $MpName= $Item.NetworkOsPath.Split('\\')[2]
    $MPListURL= @()
    $MPListURL+= "http://"+$MpName+"/SMS_MP/.sms_aut?mplist"
    $MPListURL+= "http://"+$MpName+"/SMS_MP/.sms_aut?mpcert"
    $MPListURL+= "http://"+$MpName+"/SMS_MP/.sms_pol?COMGMT00.SHA256:7384DAF9584877D5D0C40497F4008CAB6FB3074BFB911E55F3C5350B2D246F0C"
    
  if($MpName -ne 'SRV019.emea.contoso.local')
    {  
      foreach($item in $MPListURL)
            {
            $HTTP_Request = New-Object -ComObject Msxml2.XMLHTTP
            $HTTP_Request.open('GET',$Item,$false)
            $HTTP_Request.send()
            if($HTTP_Request.status -ne '200'){$Mp_list_Com_error+= $MpName}
            else{Write-CMTracelog "Test web contra $MpName Succes"}            
            }
    }
}

$MpError= $Mp_list_Com_error |Select-Object -Unique |Out-String
Write-CMTracelog 'Finalizando Test sobre MPs'

Write-CMTracelog 'Iniciando envio de correos'
#Opciones de configuración para el envio de correos.

$htmlDP = Get-Content -Path 'C:\Scripts de Mantenimiento\TestServidores\Send-MailMessage\DPerror.htm' -Raw
$htmlMP = Get-Content -Path 'C:\Scripts de Mantenimiento\TestServidores\Send-MailMessage\MPerror.htm' -Raw
$MailSender = " Monitorizacion SCCM <automation@contoso.com>"
[string[]]$ListAdress= "IT Automation <user@contoso.com>", "Manuel Becerra Saavedra <user@contoso.com>", "Ariel Martin Calderon De La Barca <user@contoso.com>", "Eduardo Lhoukite Takahashi <user@contoso.com>"     


if(($Error135) -or ($Error445)){
Send-MailMessage  -From $MailSender -to $ListAdress -SmtpServer mail.contoso.com -Subject 'Servidores DP con errores' -BodyAsHtml ($htmlDP -f $Error135,$Error445,$(get-date))    
}

if($MpError){
Send-MailMessage  -From $MailSender -to $ListAdress -SmtpServer mail.contoso.com -Subject 'Servidores MP con errores' -BodyAsHtml ($htmlMP -f $MpError,$(get-date))    
}
Write-CMTracelog 'Script Finalizado'
