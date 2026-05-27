# Device-CustomInventory.ps1

Versión adaptada del inventario personalizado: recopila datos del dispositivo y los guarda en **JSON**, con opción de **subirlos a Azure Blob Storage** mediante SAS Token.

## Cómo funciona
Controlador pensado para ejecución desatendida (Intune, Ivanti, MECM o tarea programada). Recopila inventario de hardware y/o software, genera ficheros JSON con marca temporal (para mantener histórico) y, opcionalmente, los sube a Azure Blob. Es tolerante con escenarios no aplicables (equipos no unidos a Azure AD o sin inscripción MDM).

## Tecnología
Azure Blob Storage (SAS) · JSON · pensado para Intune/Ivanti/MECM.

## Notas
El SAS Token se ha redactado. Es la evolución "propia" de `Invoke-CustomInventory.ps1`.
