#La finalidad del Script es procesar los logs generados por la TaskSecuence de activación de ESU.
#Lee los logs generados y actualiza los equipos en la colección correspondiente
#Las colecciones son 'ESU_Procesados_NOPrerequisites' y 'ESU_Procesados_activado'
Import-Module C:\01.Scripts\AAGFunctions.ps1

$PathCMTracelog='C:\Scripts de Mantenimiento\logs\ProcesaEquiposEsu7.log'
Write-CMTracelog '*** Iniciando Script ***'

#Cargo los logs con los resultados
$ListCompletedDevices= Get-Content -Path \\SRV002.emea.contoso.local\client\Esu\ListCompletedDevices.log
$ListFailedDevices= Get-Content -Path \\SRV002.emea.contoso.local\client\Esu\ListFailedDevices.log
#Cargamos el modulo de SCCM para poder usar us CMDLETS
Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1')
Set-Location CAS:

foreach($device in $ListCompletedDevices)
    {
    $deviceName= $device.split("`t")[1].split(" ")[1]
    $TestAreMemeber= Get-CMCollectionMember -CollectionId CAS00998 -Name $deviceName
    if($TestAreMemeber)
        {$TestAreMemeber} else {Add-CMDeviceCollectionDirectMembershipRule -CollectionId CAS00998 -ResourceId (Get-CMDevice -Name $deviceName).ResourceID;Write-CMTracelog "$deviceName incluido en la coleccion"}
    }
Invoke-CMCollectionUpdate -CollectionId CAS00998


foreach($device in $ListFailedDevices)
    {
    $deviceName= $device.split("`t")[1].split(" ")[1]
    $TestAreMemeber= Get-CMCollectionMember -CollectionId CAS00999 -Name $deviceName
    if($TestAreMemeber)
        {$TestAreMemeber} else {Add-CMDeviceCollectionDirectMembershipRule -CollectionId CAS00999 -ResourceId (Get-CMDevice -Name $deviceName).ResourceID}
    }
Invoke-CMCollectionUpdate -CollectionId CAS00999

Write-CMTracelog '*** Script Finalizado ***'