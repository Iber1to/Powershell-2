# reparalibreriadp.ps1

**Repara la librería de contenido de un Distribution Point** cuando WMI y el sistema de ficheros (PkgLib) se han desincronizado.

## Cómo funciona

- Compara el listado de paquetes que WMI cree que están en el DP contra el contenido real de `PkgLib`.
- Detecta las discrepancias entre ambos listados y las elimina, y finalmente **pide la redistribución** de los paquetes problemáticos.
- Informa por pantalla de qué se ha eliminado en WMI/PkgLib y qué se ha mandado redistribuir.

## Tecnología
SCCM / ConfigMgr · WMI (`SMS_PackagesInContLib`) · sistema de ficheros del DP (`PkgLib`).

## Notas
De origen externo. `reparalibreriaautomatico.ps1` es la versión que automatiza todo el proceso (conexión al CAS + guard de cuenta `ZX`).
