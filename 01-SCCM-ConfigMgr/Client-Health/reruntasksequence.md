# reruntasksequence.ps1

Fuerza que un equipo **vuelva a ejecutar una task sequence** que ya había corrido, borrando su historial de planificación local.

## Cómo funciona

- A partir del `PackageID` de la task sequence (`$TSID`), localiza las entradas correspondientes en `ccm_scheduler_history` (namespace `root\ccm\scheduler`) por WMI.
- Las elimina (con eso ConfigMgr deja de considerarla "ya ejecutada") y reinicia el servicio `CCMExec` para que se reevalúe.

## Tecnología
SCCM / ConfigMgr (cliente) · WMI (`ccm_scheduler_history`).

## Notas
Requiere conocer el PackageID de la TS y permisos de admin local en el equipo. Probado en SCCM 2012 R2.
