# TraeDatosdeDispositivosdeunaColeccion_IP_Nombre_Usuario.ps1

Extrae, para los equipos de una colección, una tabla con **nombre de máquina, usuario principal e IPs**.

## Cómo funciona

Recorre los dispositivos de la colección (`Get-CMDevice`, con `UserName`, `Name`, `ResourceID`) y, por cada uno, recupera sus direcciones IP con `Get-CMResource -Fast`, montando un objeto con el nombre, el usuario y hasta tres IPs.

## Tecnología
SCCM / ConfigMgr (`Get-CMDevice`, `Get-CMResource`).

## Notas
El nombre de la colección del ejemplo es real del entorno (una ubicación); el listado final se puede exportar a CSV.
