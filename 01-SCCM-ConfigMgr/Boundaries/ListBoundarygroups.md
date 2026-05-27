# ListBoundarygroups.ps1

Pequeño script de auditoría que lista los **boundary groups** y señala los que parecen **mal nombrados o mal asignados**.

## Cómo funciona

Recorre `Get-CMBoundaryGroup` y, para cada uno, compara el prefijo del nombre (lo que va antes del primer guion, que debería ser el site code) con su `DefaultSiteCode`. Si no coinciden —y salvo la excepción del grupo de VPN del CAS— lo acumula en una lista de errores.

## Tecnología
SCCM / ConfigMgr (`Get-CMBoundaryGroup`) · módulo `AAGFunctions`.

## Notas
Sirve para detectar incoherencias de nomenclatura entre boundary groups y sus site codes.
