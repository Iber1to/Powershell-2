#Eliminamos directamente las maquinas con 'Unknown', 'x86 Unknown Computer (x86 Unknown Computer)' y 'x64 Unknown Computer (x64 Unknown Computer)'
Remove-CMDevice -Name 'Unknown' -Force
#Remove-CMDevice -Name 'x86 Unknown Computer (x86 Unknown Computer)' -Force
#Remove-CMDevice -Name 'x64 Unknown Computer (x64 Unknown Computer)' -Force

#Cargamos los equipos de la colección de duplicados
$Coleccion= 'Nombres duplicados'
$DuplicateNames=Get-CMDevice -CollectionName $Coleccion | select name

foreach($Device in $DuplicateNames)
    {
    #Cargamos los dispositivos con el mismo nombre e inicializo el contador de repeticiones
    $ListDevice= Get-CMDevice -Name $ConsultName.Name
    $ContardorDuplicados= $ListDevice.Count
    foreach($Maquina in $ListDevice)
        {
        if(!$Maquina.ClientType)
            #{Remove-CMDevice -ResourceId $Maquina.ResourceID}
            {
            $Maquina.ResourceID
            $ContardorDuplicados--
            }
        }
    }