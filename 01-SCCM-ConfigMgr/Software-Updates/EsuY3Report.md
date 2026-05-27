# EsuY3Report.ps1

Informe de la baseline **'ESU Year3'** (Extended Security Updates, año 3) exportado a CSV.

## Cómo funciona

Mismo patrón que los demás informes de baseline: lee el estado del despliegue por WMI y genera una fila por dispositivo con `DeviceName`, `ResourceID`, `ComplianceState`, `Domain`, `Build` y nombre de SO, volcándolo a CSV.

## Tecnología
SCCM / ConfigMgr · export CSV.

## Notas
Relacionado con `ProcesaEquiposEsu7.ps1` (procesado de la activación de ESU). Ver también `ComplianceUpdateServersResume.ps1`.
