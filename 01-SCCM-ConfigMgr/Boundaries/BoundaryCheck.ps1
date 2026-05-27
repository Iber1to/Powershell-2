<#
.AUTHOR
       Powered by an external team to CONTOSO 

.SYNOPSIS
        Comprueba si una IP cae en una boundary.

.DESCRIPTION
        El script testea todos los equipos de una colección dada. Comprueba si el equipo ha reportado una IP a SCCM y en caso afirmativo si esta cae en una boundary
        o pertenece a una subnet desconocida que habria que dar de alta.
        El script deja 2 archivos. Uno con los equipos que no caen en ninguna boundary. Otro con los equipos que o bien no tienen IP o tienen IP que cae en una boundary.
        El script esta pensando inicialmente para una colección de equipos que no muestran boundary group por lo que si cae en una boundary pero no muestra boundary group
        o la boundary esta mal configurada y no esta asociada a una boundary group o el cliente esta dañado.
        Deja el archivo con los resultados en C:\temp. Si el directorio no existe lo crea.   

#>
<#     
VERSION HISTORY
        V1.0   23 Marzo 2021 -  Temporalmente en esta versión se pide el site. Esto hay que eliminarlo cuando PL1 tenga todas sus boundaries en el tipo IP range.
        

#>


#Cambiar el valor de $TargetCollection por el ID de la colección con los dispositivos que se quieren comprobar.
$TargetCollection= Read-Host "Introduce el CollectionID de la colección a escanear"
#Esta variable es temporal hasta que LATAM1 este pasado a BoundaryIP
$SiteCode= Read-Host "Introduce el site al que limitar la busqueda. !!! PL1 !!!! No esta disponible"

#La funcion se encarga de comprobar si una IP se encuentra dentro de un rango. Necesita 3 parametros. IP a checkear, Ip inicial del rango, IP final del rango.
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

$ListadoFinal= @()
$ListResourceID= @()
$Listboundaries= @()
$ListadoClientesRepairs= @()

#Cargo los dispositivos de la coleccion indicada en $TargetCollection
$ListResourceID= Get-CMDevice -CollectionId $TargetCollection -fast |where {$_.sitecode -eq $SiteCode} |select name, resourceid
#Cargo todas las boundaries del Site
$Listboundaries= Get-CMBoundary | where {$_.displayname -like "$SiteCode-*"}

foreach($ResourceID in $ListResourceID)
    {
     #Comprueba si la IP esta en el rango devuelve 'True' si esta y 'False' si no esta     
     $ResourceDevice= Get-CMResource -ResourceId $ResourceId.resourceid -Fast |select name, IPAddresses
     #Contador para las boundaries en las que no ha habido correspondencia
     $FalseCount=0
     #Variables de la fase Debug porque era incapaz de recordar que con esto $($ResourceDevice.IPAddresses[0]) consigues lo mismo y no iba a estar cambiandolo despues de terminado.
     $boundaryName= $boundary.DisplayName
     $ResourceIp= $ResourceDevice.IPAddresses[0]
     $ResourceName= $ResourceDevice.name
     #Solo proceso equipos con IP's. Si el equipo tiene la IP en blanco la función de checkeo falla al pasarle un parametro $null
     If($ResourceIp)
        {
         foreach($boundary in $Listboundaries)
            {
             #Mandamos a la funcion para comprobar IP.
             $BoundResult= IsIpAddressInRange $ResourceDevice.IPAddresses[0] $boundary.Value.Split('-')[0] $boundary.Value.Split('-')[1]
             #Si la IP esta asociada a una boundary corto el loop.       
             if($BoundResult -eq $true)
                {
                 Write-Host "$ResourceIp en $boundaryName es: $BoundResult" -ForegroundColor Green
                 $MyUsuario = New-Object System.Object
                 $MyUsuario | Add-Member -type NoteProperty -name 'Nombre maquina' -value $ResourceName
                 $MyUsuario | Add-Member -type NoteProperty -name 'Ip maquina' -value $ResourceIp
                 $MyUsuario | Add-Member -type NoteProperty -name 'Boundarie asignada' -value $boundary.DisplayName       
                 $ListadoClientesRepairs += $MyUsuario
                 Break    
                }
             else
                {
                Write-Host "$ResourceIp en $boundaryName es: $BoundResult"
                $FalseCount ++
                }
            }
        }
     #Los equipos que no tienen IP los reporto. Son buenos candidatos a reparar el cliente 
     else
        {
         Write-Host " no tiene IP asociada" -ForegroundColor Red
         $MyUsuario = New-Object System.Object
         $MyUsuario | Add-Member -type NoteProperty -name 'Nombre maquina' -value $ResourceName
         $MyUsuario | Add-Member -type NoteProperty -name 'Ip maquina' -value 'sin IP asignada'         
         $MyUsuario | Add-Member -type NoteProperty -name 'Boundarie asignada' -value 'sin Boundary asociada'       
         $ListadoClientesRepairs += $MyUsuario
        }
     #Comparamos las boundaries revisadas con fallo vs el numero de boundaries si son iguales la IP no cae en ninguna boundary y se reporta.
     If($FalseCount -eq $Listboundaries.Count)
        {
         Write-Host "$ResourceIp no tiene boundary asociada" -ForegroundColor Red
         $MyUsuario = New-Object System.Object
         $MyUsuario | Add-Member -type NoteProperty -name 'Nombre maquina' -value $ResourceName
         $MyUsuario | Add-Member -type NoteProperty -name 'Ip maquina' -value $ResourceIp         
         $ListadoFinal += $MyUsuario
        }
             
    }

#Salvamos el listado de los equipos sin boundary o IP
$TestPath= Test-Path -Path C:\Temp
if($TestPath -eq $false){md C:\temp}
$Date= Get-Date -Format "dd_MM_yyyy"
$CsvName= $TargetCollection+'_equiposSINboundaries_'+$Date+'.csv'
$CsvName2= $TargetCollection+'_clientesAreparar_'+$Date+'.csv'
$ListadoFinal | Export-Csv -Path C:\temp\$CsvName -Append -NoTypeInformationping
$ListadoClientesRepairs | Export-Csv -Path C:\temp\$CsvName2 -Append -NoTypeInformation
