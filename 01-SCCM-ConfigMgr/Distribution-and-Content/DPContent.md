# DPContent.ps1

Permite **distribuir o eliminar paquetes en un Distribution Point remoto** a partir de una lista en fichero de texto.

## Cómo funciona

- Se conecta al CAS para disponer de los cmdlets de ConfigMgr (requiere una cuenta del tipo privilegiado `ZX` con permisos).
- Recibe dos parámetros obligatorios (si no se pasan, los pide por consola): `$DistributionPoint` (se recomienda el FQDN) y `$Path` (ruta de un `.txt` con los PackageID a procesar, tal y como aparecen en la pestaña *Content* del DP).
- Distribuye o retira esos paquetes del DP indicado.

## Tecnología
SCCM / ConfigMgr (CAS) · cmdlets de distribución de contenido.

## Notas
De origen externo, adaptado al entorno. Es prácticamente el mismo script que `DistribuyeListaPktsToDP.ps1`.
