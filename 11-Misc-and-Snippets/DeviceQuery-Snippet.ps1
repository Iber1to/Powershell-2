$NameFile= hostname
 
#Paso1
$netshShow=  netsh winhttp show proxy | Out-File "\\198.51.100.807\Reporte_proxy\$NameFile.txt" -Append

 
#Paso2
$netshSet= netsh winhttp set proxy proxy-server="proxy.emea.contoso.local:8080" bypass-list="*.contoso.es;*.contoso.com;*.contoso.local;*.contosoactiva.com;*.contosoalarmas.es;*.intranet.contoso.*;*.contoso.net.br;sqllisboa*;10.*.*.*;172.1.*.*;172.16.*.*;192.6.*.*;192.168.*.*;217.14.40.*;" | Out-File "\\198.51.100.807\Reporte_proxy\$NameFile.txt" -Append


#Paso3 
$TestCloudConnectionInfo = New-Object System.Diagnostics.ProcessStartInfo
$TestCloudConnectionInfo.FileName = "C:\Program Files\Microsoft Monitoring Agent\Agent\TestCloudConnection.exe"
$TestCloudConnectionInfo.RedirectStandardError = $true
$TestCloudConnectionInfo.RedirectStandardOutput = $true
$TestCloudConnectionInfo.UseShellExecute = $false
$TestCloudConnection = New-Object System.Diagnostics.Process
$TestCloudConnection.StartInfo = $TestCloudConnectionInfo
$TestCloudConnection.Start() | Out-Null
$TestCloudConnection.WaitForExit()
$stdout = $TestCloudConnection.StandardOutput.ReadToEnd() | Out-File "\\198.51.100.807\Reporte_proxy\$NameFile.txt" -Append
$stderr = $TestCloudConnection.StandardError.ReadToEnd()  | Out-File "\\198.51.100.807\Reporte_proxy\$NameFile.txt" -Append


#Paso4
$PingTest= Test-NetConnection proxy.emea.contoso.local
$PingResult= 'Ping Proxy: '+$PingTest.PingSucceeded | Out-File "\\198.51.100.807\Reporte_proxy\$NameFile.txt" -Append

#Paso5
$healthServiceSettings = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'


#Paso6
$healthServiceSettings.SetProxyInfo('proxy.emea.contoso.local:8080', '', '')

#Resultado Paso 5 y Paso 6
$healthServiceSettings | Out-File "\\198.51.100.807\Reporte_proxy\$NameFile.txt" -Append