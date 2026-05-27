# 06-Azure-Inventory

Inventario personalizado de dispositivos hacia Azure Storage / Log Analytics mediante SAS y tareas programadas.

## Scripts de esta categoría

| Script | Qué hace | Tecnología principal |
|---|---|---|
| `Device-CustomInventory.ps1` | Versión adaptada del inventario personalizado: recopila datos del dispositivo y los guarda en **JSON**, con opción de **subirlos a Azure Blob Storage** mediante SAS Token | Azure Blob Storage (SAS) |
| `Invoke-CustomInventory.ps1` | **Script de terceros** (estilo MSEndpointMgr / Nickolaj Andersen) que recopila **inventario personalizado del dispositivo y lo sube a Log Analytics**. | Log Analytics (Data Collector API) |
| `test - AzureFile - Upload.ps1` | Prueba de concepto para **subir un fichero a Azure Blob Storage mediante SAS Token**. | Azure Blob Storage (REST + SAS) |

