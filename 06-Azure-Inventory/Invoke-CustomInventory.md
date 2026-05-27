# Invoke-CustomInventory.ps1

**Script de terceros** (estilo MSEndpointMgr / Nickolaj Andersen) que recopila **inventario personalizado del dispositivo y lo sube a Log Analytics**.

## Cómo funciona
Recopila inventario de hardware y/o de aplicaciones instaladas y lo envía a un workspace de Log Analytics, de modo que se pueda consultar de forma centralizada. Está pensado para ejecutarse a diario, idealmente como proactive remediation de Intune (o como tarea programada), corriendo como SYSTEM.

## Tecnología
Log Analytics (Data Collector API) · Intune.

## Notas
Código base de la comunidad. `Device-CustomInventory.ps1` es la versión adaptada del entorno (vuelca a JSON y sube a Azure Blob).
