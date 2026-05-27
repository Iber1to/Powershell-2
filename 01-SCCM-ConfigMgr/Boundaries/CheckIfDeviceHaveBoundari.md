# CheckIfDeviceHaveBoundari.ps1

Evolución de `BoundaryCheck` (v1.1): comprueba para los equipos de una colección si su IP cae en una boundary, pero ya **abarca las boundaries de todos los sites** en lugar de pedir uno concreto.

## Cómo funciona

- Carga el módulo de funciones `AAGFunctions.ps1` (logging `Write-CMTracelog`, `Connect-CMSite`) y se conecta al proveedor de SCCM.
- Recorre los equipos de la colección por defecto, recupera su IP y la valida contra el conjunto de boundaries de todos los sites.
- Deja un log de traza y los ficheros de equipos dentro/fuera de boundary.

## Tecnología
SCCM / ConfigMgr · módulo propio `AAGFunctions` · cálculo de rangos IP.

## Notas
Servidor de SCCM y site code anonimizados (`SRVxxx`, `PE1`).
