# Fail-DistributedContent.ps1

Localiza los **paquetes que han fallado al distribuirse** a los DPs y fuerza su redistribución, dejando constancia en un log diario.

## Cómo funciona

- Consulta por WMI `SMS_PackageStatusDistPointsSummarizer` filtrando por los estados de error (State 2, 3 u 8 — instalación incorrecta o fallo de validación de contenido).
- Si hay paquetes en ese estado, los redistribuye y registra cada acción en `..._pkgredistributed.log`.

## Tecnología
SCCM / ConfigMgr vía WMI (`SMS_PackageStatusDistPointsSummarizer`).

## Notas
`Fail-Distributed-Content.ps1` es una variante con su propia función de logging CMTrace. Los códigos de estado se documentan en la referencia de MSDN citada en el propio script.
