$BluecoatHost=0
$BlucoatProxy=0
$IPs= '192.0.2.1','192.0.2.2','192.0.2.3','192.0.2.4'
$textproxy= netsh winhttp show proxy

foreach($ip in $IPs){
$Search1= Select-String -Path C:\windows\system32\drivers\etc\hosts -Pattern $ip
If($Search1){Write-Host "Proxy $ip localizado"}
else {Write-Host "Proxy $ip failed"}
$Search2= Select-String  -InputObject $textproxy -Pattern $IP
If($Search2){Write-Host "Proxy $ip localizado en netsh"}
else {Write-Host "Proxy $ip failed en netsh"}
}

