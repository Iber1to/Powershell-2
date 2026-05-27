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
        V1.1   31 Julio 2021 -  Comprueba las Boundarys de todos los sites. La Coleccion principal se deja como predeterminada.

#>
Import-Module "C:\01.Scripts\AAGFunctions.ps1"

$PathCMTracelog= 'C:\Scripts de Mantenimiento\TestBoundarys\TestBoundarys.log'
if( $(Test-Path -Path $PathCMTracelog)){Remove-Item -Path $PathCMTracelog -Force}
Write-CMTracelog 'Iniciando Script'
Write-CMTracelog 'Conectando con el PE1'
Connect-CMSite -SiteCode PE1 -ProviderMachineName SRV002.emea.contoso.local


#Cambiar el valor de $TargetCollection por el ID de la colección con los dispositivos que se quieren comprobar.
$TargetCollection= 'CAS0003A' # 00-GLOBAL_MGM_WS_(Principal_Coll)

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

Write-CMTracelog 'Cargando listado de dispositivos'
$ListadoFinal= @()
$ListResourceID= @()
$Listboundaries= @()
$ListadoClientesRepairs= @()

#Cargo los dispositivos de la coleccion indicada en $TargetCollection
$ListResourceID= Get-CMDevice -CollectionId $TargetCollection -fast -Resource |Select-Object name, IPAddresses
#Cargo todas las boundaries del Site
Write-CMTracelog 'Cargando listado de boundaries'
$Listboundaries= Get-CMBoundary | Where-Object {$_.BoundaryType -eq 3}

Write-CMTracelog 'Comprobando si el dispositivo tienen boundary. Este proceso puede demorar horas. '
foreach($ResourceID in $ListResourceID)
    {
     #Comprueba si la IP esta en el rango devuelve 'True' si esta y 'False' si no esta     
     #$ResourceDevice= Get-CMResource -ResourceId $ResourceId.resourceid -Fast |Select-Object name, IPAddresses
     #Contador para las boundaries en las que no ha habido correspondencia
     $FalseCount=0   
     #Solo proceso equipos con IP's. Si el equipo tiene la IP en blanco la función de checkeo falla al pasarle un parametro $null
     If($ResourceID.IPAddresses[0])
        {
        write-host Procesando $($ResourceID.name) con IP: $($ResourceID.IPAddresses[0])
         foreach($boundary in $Listboundaries)
            {
             #Mandamos a la funcion para comprobar IP.
             $BoundResult= IsIpAddressInRange $ResourceID.IPAddresses[0] $boundary.Value.Split('-')[0] $boundary.Value.Split('-')[1]
              
             #Si la IP esta asociada a una boundary corto el loop.       
             if($BoundResult -eq $true)
                {
                 Write-Host "$($ResourceID.IPAddresses[0]) en $($boundary.DisplayName) es: $BoundResult" -ForegroundColor Green                 
                 Break    
                }
             else
                {
                #Write-Host "$ResourceIp en $boundaryName es: $BoundResult"
                $FalseCount ++
                }
            }
        }
     #Los equipos que no tienen IP los reporto. Son buenos candidatos a reparar el cliente 
     else
        {
         Write-Host " $($ResourceID.name) no tiene IP asociada" -ForegroundColor Red
         $MyUsuario = New-Object System.Object
         $MyUsuario | Add-Member -type NoteProperty -name 'Nombre maquina' -value $ResourceID.name
         $MyUsuario | Add-Member -type NoteProperty -name 'Ip maquina' -value 'sin IP asignada'         
         $MyUsuario | Add-Member -type NoteProperty -name 'Boundarie asignada' -value 'sin Boundary asociada'       
         $ListadoClientesRepairs += $MyUsuario
        }
     #Comparamos las boundaries revisadas con fallo vs el numero de boundaries si son iguales la IP no cae en ninguna boundary y se reporta.
     If($FalseCount -eq $Listboundaries.Count)
        {
         Write-Host "$($ResourceID.IPAddresses[0]) no tiene boundary asociada" -ForegroundColor Red
         $MyUsuario = New-Object System.Object
         $MyUsuario | Add-Member -type NoteProperty -name 'Nombre maquina' -value $ResourceID.name
         $MyUsuario | Add-Member -type NoteProperty -name 'Ip maquina' -value $ResourceID.IPAddresses[0]      
         $ListadoFinal += $MyUsuario
        }
             
    }

Write-CMTracelog 'Generando archivos con los resultados'
#Salvamos el listado de los equipos sin boundary o IP
$TestPath= Test-Path -Path "C:\Scripts de Mantenimiento\TestBoundarys"
if($TestPath -eq $false){mkdir "C:\Scripts de Mantenimiento\TestBoundarys"}
$Date= Get-Date -Format "dd_MM_yyyy"
$ListadoFinal | Export-Csv -Path "C:\Scripts de Mantenimiento\TestBoundarys\equiposinboundary_$TargetCollection_$Date.csv"  -Force -NoTypeInformation
$ListadoClientesRepairs | Export-Csv -Path "C:\Scripts de Mantenimiento\TestBoundarys\equiposinip_$TargetCollection_$Date.csv" -Force -NoTypeInformation

Write-CMTracelog 'Enviando correos'
[string[]]$ListAdress= "IT Automation <user@contoso.com>", "Manuel Becerra Saavedra <user@contoso.com>", "Ariel Martin Calderon De La Barca <user@contoso.com>", "Eduardo Lhoukite Takahashi <user@contoso.com>", "Juan Antonio Jabonero <user@contoso.com>", "Gustavo Aviles <user@contoso.com>"
[string[]]$attachment = "C:\Scripts de Mantenimiento\TestBoundarys\equiposinboundary_$TargetCollection_$Date.csv", "C:\Scripts de Mantenimiento\TestBoundarys\equiposinip_$TargetCollection_$Date.csv"
send-MailHtml -Subject "Ejecuccion de tareas automaticas" -Titulo "Equipos sin boundaries" -Message 'Esta tarea identifica los equipos que no tienen asignada una boundary en SCCM en la coleccion "00-GLOBAL_MGM_WS_(Principal_Coll)". Tambien identifica equipos que no han reportado IP.' -ListAdress $ListAdress -attachment $attachment