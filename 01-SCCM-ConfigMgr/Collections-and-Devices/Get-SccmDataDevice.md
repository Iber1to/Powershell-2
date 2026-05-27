# Get-SccmDataDevice.ps1

Recopila un **dossier por dispositivo** combinando varias fuentes de inventario de SCCM en un único objeto, y lo exporta a CSV.

## Cómo funciona

Para los equipos de una colección, junta datos de `Get-CMDevice`, `Get-CMResource` y de varias clases de inventario hardware por WMI: `SMS_G_System_PC_BIOS`, `SMS_G_System_BATTERY`, `SMS_G_System_OPERATING_SYSTEM` y `SMS_G_System_ENCRYPTABLE_VOLUME` (estado de cifrado). El resultado es una fila por dispositivo con BIOS, batería, SO y estado de BitLocker.

## Parámetros
`-TargetCollection` (por defecto la colección principal de workstations) y `-PathCSV` (ruta del CSV de salida).

## Tecnología
SCCM / ConfigMgr (cmdlets + clases `SMS_G_System_*` por WMI) · export CSV.

## Notas
Su pareja `Get-SccmDataDevice-Troubleshooting.ps1` es una versión instrumentada para depurar la recolección.
