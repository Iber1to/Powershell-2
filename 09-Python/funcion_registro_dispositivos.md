# funcion_registro_dispositivos.py

Versión **documentada paso a paso** del registro de dispositivos Android (Cloud Identity) pensada como material de referencia/manual.

## Cómo funciona
Mismo flujo que `main.py` —cuenta de servicio con delegación de dominio, lectura de seriales desde Google Sheets y alta de los dispositivos no procesados vía Cloud Identity— pero con un docstring extenso que enumera los requisitos previos (habilitar Admin SDK, Cloud Identity y Sheets API, crear la cuenta de servicio con delegación, etc.).

## Tecnología
Google Cloud (Cloud Identity, Sheets) · cuenta de servicio.

## Notas
Ideal para entender el proyecto antes de tocar la versión de producción (`main.py`).
