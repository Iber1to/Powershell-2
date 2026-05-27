# SUPDeploymentStatusServers.ps1

Estado del **despliegue de actualizaciones en servidores**, agrupado por sistema operativo.

## Cómo funciona

- Recoge los despliegues de las ADR de servidores para Windows Server 2012/2012 R2, 2016 y 2019 (`Get-CMSoftwareUpdateDeployment`, filtrando por el nombre de asignación de cada SO).
- Verifica que existan exactamente los tres despliegues esperados (si no, se detiene) y agrega por estado (1/2/5/4 = éxito/en progreso/error/desconocido) los totales de dispositivos.

## Tecnología
SCCM / ConfigMgr (`Get-CMSoftwareUpdateDeployment`) · módulo `AAGFunctions`.

## Notas
Pareja de `SUPDeploymentStatus.ps1` (workstations). Los nombres de ADR son los del entorno.
