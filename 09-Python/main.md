# main.py

**Google Cloud Function** que inscribe dispositivos **Android** en el inventario de propiedad de la empresa usando la API de **Cloud Identity**, leyendo los números de serie de una hoja de Google Sheets.

## Cómo funciona
- Se autentica con una cuenta de servicio de GCP (delegación a nivel de dominio) para obtener token con los scopes de `cloud-identity.devices` y de Sheets.
- Lee de la hoja los dispositivos pendientes y, para cada serial no procesado, llama a Cloud Identity para crear el registro del dispositivo corporativo.

## Tecnología
Google Cloud (Cloud Functions, Cloud Identity, Sheets API) · `gspread` · cuenta de servicio.

## Notas
Es la versión "de producción" del registro de dispositivos del cliente de retail. `funcion_registro_dispositivos.py` es la versión documentada paso a paso y `testregistrodispositivos.py` la de pruebas. La clave de la cuenta de servicio (`service-account.json`) se ha redactado.
