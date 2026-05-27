# BoundaryCheck.ps1

Comprueba, para todos los equipos de una colección, si la **IP que reportan a SCCM cae dentro de alguna boundary** de tipo *IP range* o si pertenece a una subred desconocida que habría que dar de alta.

## Cómo funciona

- Pide por consola el `CollectionID` a escanear y (de forma temporal, mientras un sitio no estaba migrado a boundaries IP) el site code.
- Para cada equipo recupera su IP en SCCM y la compara contra los rangos de las boundaries usando aritmética de enteros de 32 bits (convierte cada IP a `UInt32` y comprueba `inicio ≤ ip ≤ fin`).
- Genera **dos ficheros** en `C:\temp` (que crea si no existe): uno con los equipos que no caen en ninguna boundary y otro con los que no tienen IP o sí caen en una.

Es útil para detectar clientes con boundary mal asociada a su boundary group, subredes sin dar de alta o clientes dañados.

## Tecnología
SCCM / ConfigMgr · cálculo de rangos IP con `System.Net.IPAddress` + `BitConverter`.

## Notas
Script de origen externo adaptado para el entorno. Conviven tres versiones (`BoundaryCheck`, `_2`, `_3`) con pequeñas diferencias evolutivas; ésta es la base interactiva que pide site y colección.
