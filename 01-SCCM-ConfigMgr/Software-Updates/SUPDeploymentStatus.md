# SUPDeploymentStatus.ps1

Calcula el **estado del despliegue mensual de actualizaciones** sobre el parque de workstations.

## Cómo funciona

- Con `Get-PatchTuesday` y la fecha actual decide de qué mes hay que informar (si aún no se ha pasado el Patch Tuesday, toma el mes anterior) y traduce el número de mes a su nombre en español.
- A partir de ahí recopila el estado del despliegue de ese mes (éxito / en progreso / error / desconocido).

## Tecnología
SCCM / ConfigMgr (Software Update Point) · módulo `AAGFunctions`.

## Notas
`SUPDeploymentStatusServers.ps1` es la versión equivalente para servidores.
