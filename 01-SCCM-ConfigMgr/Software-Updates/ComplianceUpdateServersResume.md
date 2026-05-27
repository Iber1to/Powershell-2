# ComplianceUpdateServersResume.ps1

Recopila los resultados de la baseline de cumplimiento **'Informe parcheo Servidores'** y los exporta a CSV para su explotación (Power BI).

## Cómo funciona

Lee por WMI el estado del despliegue de la baseline en el proveedor del sitio y, por cada dispositivo, construye un objeto con `DeviceName`, `ResourceID`, `ComplianceState` (traducido), `Domain`, `Build` y una traducción del build a un nombre de SO legible. Exporta el conjunto a CSV en una ruta de red.

## Tecnología
SCCM / ConfigMgr (estado de baseline por WMI) · export CSV.

## Notas
Comparte estructura con `EsuY3Report.ps1` y `Spooler_Disable.ps1` (mismo patrón de informe de baseline → CSV).
