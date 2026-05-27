Function IsIpAddressInRange {
param(
        [string] $ipAddress,
        [string] $fromAddress,
        [string] $toAddress
    )
 
    $ip = [system.net.ipaddress]::Parse($ipAddress).GetAddressBytes()
    [array]::Reverse($ip)
    $ip = [system.BitConverter]::ToUInt32($ip, 0)
 
    $from = [system.net.ipaddress]::Parse($fromAddress).GetAddressBytes()
    [array]::Reverse($from)
    $from = [system.BitConverter]::ToUInt32($from, 0)
 
    $to = [system.net.ipaddress]::Parse($toAddress).GetAddressBytes()
    [array]::Reverse($to)
    $to = [system.BitConverter]::ToUInt32($to, 0)
 
    $from -le $ip -and $ip -le $to
}

$IP=Get-CMResource -ResourceId 16822049 -Fast |select name, IPAddresses
$bound=Get-CMBoundary -BoundaryName PE1-EMEA-ES-VPN-198.51.100.806
$name= $bound.DisplayName


if (IsIpAddressInRange $ip.IPAddresses[0] $bound.Value.Split('-')[0] $bound.Value.Split('-')[1])
{
Write-Host "Su boundary es $name"
}
else
{
Write-Host "No tiene boundary"
}