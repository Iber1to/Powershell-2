Import-Module C:\01.Scripts\AAGFunctions.ps1

Connect-CMSite -SiteCode PE1 -ProviderMachineName SRV002.emea.contoso.local

$listadoDevices= Get-CMDevice -CollectionId PE100872 | Select-Object name
$logspath = "\\SRV005.latam2.contoso.local\D$\Client_Start_Script_Install\ClientHealth\logs\"
$EquiposHealth= Get-ChildItem -Path $logspath
$hoy= Get-Date -DisplayHint Date


#Creo los objetos nuevos.
$DeviceLists = @()

foreach($item in $listadoDevices)
    {
    $DeviceUmbrella = New-Object -TypeName PSObject
    $DeviceUmbrella | Add-Member -MemberType NoteProperty  -Name 'DeviceName' -Value $item.name
    $DeviceLists += $DeviceUmbrella
    }


#Paso 1 he comprobado si han ejecutado alguna vez el Health.
foreach($item in $DeviceLists)
    {
    $healthExist= $EquiposHealth | Where-Object {$_.Name -match $item.DeviceName}
    if($healthExist)
        {
        $item | Add-Member -MemberType NoteProperty  -Name 'HealthScript' -Value 'Si' -Force
        $item | Add-Member -MemberType NoteProperty  -Name 'HS.LastWrite' -Value $healthExist.LastWriteTime -Force
        }
    else
        {
        $item | Add-Member -MemberType NoteProperty  -Name 'HealthScript' -Value 'No' -Force
        $item | Add-Member -MemberType NoteProperty  -Name 'HS.LastWrite' -Value 'No' -Force
        }
}

#Paso 2 comprobar si estan en SCCM


foreach($item in $DeviceLists)
    {
    $datosSCCM= Get-CMDevice -Name $item.DeviceName -Resource
    if($datosSCCM)
        {
        $item | Add-Member -MemberType NoteProperty  -Name 'SCCM' -Value 'Si' -Force
        if($datosSCCM.ClientVersion)
            {
            $item | Add-Member -MemberType NoteProperty  -Name 'ClientSCCM' -Value $datosSCCM.Client -Force
            $item | Add-Member -MemberType NoteProperty  -Name 'ClientVersion' -Value $datosSCCM.ClientVersion -Force
            }
        else
            {
            $item | Add-Member -MemberType NoteProperty  -Name 'ClientSCCM' -Value '0' -Force
            $item | Add-Member -MemberType NoteProperty  -Name 'ClientVersion' -Value 'No' -Force
            }
        foreach($subnet in $datosSCCM.IPSubnets)
            {
            if($subnet -match '10.')
                {
                $property= "Subnet"+[array]::indexof($datosSCCM.IPSubnets,$subnet)
                $item | Add-Member -MemberType NoteProperty  -Name $property -Value $subnet -Force               
                }
            }
        }
    else{
        $item | Add-Member -MemberType NoteProperty  -Name 'SCCM' -Value 'No' -Force
        $item | Add-Member -MemberType NoteProperty  -Name 'ClientSCCM' -Value 'No' -Force
        $item | Add-Member -MemberType NoteProperty  -Name 'ClientVersion' -Value 'No' -Force
        }
    }



#Paso 3 Comprobar la ultima vez que hizo logon en AD
#$DomainController = Get-ADDomainController -filter * | Select-Object name
$DomainController = 'latam2.contoso.local'
foreach($item in $DeviceLists){
    $DeviceListTemp= @()
    
        try{
        $Machine= (Get-ADComputer -Server $DomainController -Identity $item.DeviceName -Properties *).LastLogondate
        $Machine |Add-Member -MemberType NoteProperty -Name 'DiasUltimoLogon' -Value (New-TimeSpan -Start $Machine -End $hoy).Days -Force
        $Machine
        $DeviceListTemp +=$Machine
        }catch{}
        

    if($DeviceListTemp)
        {
        $item | Add-Member -MemberType NoteProperty  -Name 'LastLogon' -Value ($DeviceListTemp |Sort-Object lastlogon -Descending)[0].lastlogon -Force
        $item | Add-Member -MemberType NoteProperty  -Name 'DiasdesdeUltimoLogon' -Value ($DeviceListTemp |Sort-Object lastlogon -Descending)[0].DiasUltimoLogon -Force
        }
    else
        {
        $item | Add-Member -MemberType NoteProperty  -Name 'LastLogon' -Value 'NoExist' -Force
        $item | Add-Member -MemberType NoteProperty  -Name 'DiasdesdeUltimoLogon' -Value 'NoExist' -Force
        }
}   
 