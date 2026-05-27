# Compare-LastScan-vs-LastContact.ps1

Snippet de diagnóstico que compara, para un equipo, su **último inventario de hardware** con su **última conexión** a SCCM.

## Cómo funciona

Recupera el dispositivo con `Get-CMDevice` y comprueba si `LastHardwareScan + 8 días` es anterior a `LastActiveTime`; si lo es, avisa de que el equipo conecta pero hace tiempo que no inventaría (señal de inventario "atascado").

## Tecnología
SCCM / ConfigMgr (`Get-CMDevice`).

## Notas
El nombre de equipo del ejemplo es un valor de prueba anonimizado.
