# test - AzureFile - Upload.ps1

Prueba de concepto para **subir un fichero a Azure Blob Storage mediante SAS Token**.

## Cómo funciona
Define la cuenta de almacenamiento, el contenedor y el nombre de blob destino, lee el fichero local como bytes y lo sube a la URI del blob (`https://<cuenta>.blob.core.windows.net/<contenedor>/<blob><sas>`).

## Tecnología
Azure Blob Storage (REST + SAS).

## Notas
El SAS Token se ha redactado y la ruta local de ejemplo (que contenía nombre de usuario y de cliente) se ha anonimizado. Es el banco de pruebas de la subida que luego usa `Device-CustomInventory.ps1`.
