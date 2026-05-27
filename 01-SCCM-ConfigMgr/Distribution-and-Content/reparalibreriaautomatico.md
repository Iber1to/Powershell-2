# reparalibreriaautomatico.ps1

Versión **automática** de la reparación de la librería de contenido de los DPs: hace lo mismo que `reparalibreriadp.ps1` pero sin intervención manual.

## Cómo funciona

- `ConectCAS` comprueba que el usuario sea del tipo privilegiado `ZX` y conecta a la unidad del site `CAS`.
- Obtiene por WMI los paquetes que figuran en la librería del DP (`SMS_PackagesInContLib`) y los compara con el contenido real de `PkgLib` (resolviendo la ruta de la content library y listando los `.INI`).
- Corrige las discrepancias y solicita la redistribución de lo que haga falta.

## Tecnología
SCCM / ConfigMgr (CAS) · WMI (`SMS_PackagesInContLib`) · ejecución remota sobre el DP.

## Notas
El SMS Provider se ha anonimizado (`SRV004.contoso.local`).
