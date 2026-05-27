# Test-Servers-SCCM.ps1

Comprueba la **conectividad hacia los Distribution Points** del entorno en los puertos clave (135 RPC y 445 SMB) y deja el resultado en un log.

## Cómo funciona

- Conecta al proveedor de SCCM (`AAGFunctions.ps1`) y obtiene la lista de DPs con `Get-CMDistributionPoint`.
- Para cada DP prueba los puertos 135 y 445, acumulando los que fallan en sendas listas de error, y registra todo con `Write-CMTracelog`.

## Tecnología
SCCM / ConfigMgr · `Test-NetConnection` · módulo `AAGFunctions`.

## Notas
`Test-Servers-SCCM_v0.ps1` es una versión anterior del mismo chequeo.
