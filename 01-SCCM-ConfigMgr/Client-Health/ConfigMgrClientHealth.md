# ConfigMgrClientHealth.ps1

**Herramienta de terceros muy conocida** (ConfigMgr Client Health, de Anders Rødland). Valida y **repara automáticamente** multitud de problemas del cliente de Configuration Manager en equipos Windows.

## Cómo funciona

- Se ejecuta con un fichero de configuración XML (`-Config .\Config.Xml`) y, opcionalmente, contra un webservice (`-Webservice`) que centraliza los resultados en una base de datos.
- Comprueba y corrige aspectos como el servicio del cliente, WMI, BITS, Windows Update, el estado del propio cliente CM, tareas pendientes, espacio en disco, etc.
- Está pensada para desplegarse como tarea programada en cada endpoint.

## Tecnología
SCCM / ConfigMgr · WMI · Windows Update · SQL (vía webservice opcional).

## Notas
Es software de un tercero (open source); se mantiene su cabecera y autoría. En el repositorio original venía dos veces, de ahí el `_2`. Las rutas de laboratorio del ejemplo (`cm01.rodland.lab`) son del propio autor.
