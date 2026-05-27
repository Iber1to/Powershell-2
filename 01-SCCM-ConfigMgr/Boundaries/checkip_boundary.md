# checkip_boundary.ps1

Snippet que dice **a qué boundary pertenece un dispositivo concreto**, comparando su IP contra una boundary dada por nombre.

## Cómo funciona

Define la función `IsIpAddressInRange` (conversión de IPs a enteros de 32 bits y comparación de rango), recupera la IP de un recurso por su `ResourceId` con `Get-CMResource` y la contrasta con el rango de una boundary obtenida por `Get-CMBoundary -BoundaryName`.

## Tecnología
SCCM / ConfigMgr (`Get-CMResource`, `Get-CMBoundary`) · cálculo de rangos IP.

## Notas
Ejemplo de uso puntual; el `ResourceId` y el nombre de boundary del código son valores de prueba.
