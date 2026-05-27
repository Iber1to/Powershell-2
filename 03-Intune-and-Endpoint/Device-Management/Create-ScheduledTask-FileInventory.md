# Create-ScheduledTask-FileInventory.ps1

Crea la **tarea programada** que ejecuta periódicamente el inventario de ficheros y lo sube a Azure Storage.

## Cómo funciona
Registra una tarea en el Programador de Windows que lanza el script de inventario personalizado; la configuración de subida usa un SAS Token de la cuenta de Azure Storage.

## Tecnología
Programador de tareas · Azure Storage (SAS).

## Notas
Forma pareja con los scripts de `06-Azure-Inventory`. El SAS Token se ha redactado (`REDACTED_SAS_TOKEN`).
