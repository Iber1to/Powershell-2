#Sirv tanto para cargar los KO como para cargar los NoData hay que comentar y descomentar las 2 lineas que correspondan
#Lineas a comentar/descomentar 19/20 y 26/27

$Ocs_Ko = Import-Csv C:\temp\OCS_Julio_FULL.csv
$contador=0
$CollectionName= 'OCS_Update_NoData_Julio'

#Cargamos el modulo de SCCM para poder usar us CMDLETS
Write-Host "--- Conectando con el servidor CAS ---"
Try
    {
    Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1') -ErrorAction SilentlyContinue
    Set-Location CAS:
    Write-Host "Conexion al CAS completada"
    }catch{}

#Evaluo el total de equipos Ko
foreach($equipo in $Ocs_Ko){
    #If($equipo.KbStatus -eq 'KO'){$contador++}}
    If($equipo.KbStatus -eq 'NoData'){$contador++}}
write-host "$contador equipos seran añadidos"


#Cargo los equipos KO a la coleccion.
foreach($equipo in $Ocs_Ko){
    #If($equipo.KbStatus -eq 'KO'){
    If($equipo.KbStatus -eq 'NoData'){
        $ResourceId= Get-CMDevice -Name $equipo.computer |Select-Object ResourceId
        Try{
            Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $ResourceId.ResourceId -ErrorAction SilentlyContinue
            $equipo.COMPUTER | Out-File -FilePath C:\Temp\OCS_Creados.log -Append
            Write-Host $equipo.COMPUTER -ForegroundColor Green
            $contador--
            write-host "Faltan $contador equipos"
            }
        catch{
            $equipo.COMPUTER | Out-File -FilePath C:\Temp\OCS_Fallados.log -Append
            $contador--
            Write-Host $equipo.COMPUTER -ForegroundColor Red            
            write-host "Faltan $contador equipos"
             }

}
}
Invoke-CMCollectionUpdate -CollectionId CAS0094E
