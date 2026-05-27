# 09-Python

Utilidades en Python: Microsoft Graph (MSAL), registro de dispositivos en Google Cloud, calendarios ICS, GPOs y ejemplos.

## Scripts de esta categoría

| Script | Qué hace | Tecnología principal |
|---|---|---|
| `Dax40.py` | Script **personal** de análisis técnico bursátil: descarga la cotización del **DAX 40** y calcula indicadores como el RSI. | `yfinance` |
| `RecolectGPOnames.py` | Recorre un **backup de GPOs** y extrae, de cada `bkupInfo.xml`, el **GUID y el nombre de la GPO**, volcándolo a un CSV. | Parsing XML (`ElementTree`) |
| `compare registry.py` | Compara ficheros por su **hash SHA-256** para detectar duplicados o cambios (por ejemplo, entre backups de GPO). | `hashlib` (SHA-256) |
| `example.py` | Mini **servidor HTTP** de ejemplo que sirve un fichero XML con el `Content-Type` correcto. | `http.server` / `socketserver` |
| `funcion_registro_dispositivos.py` | Versión **documentada paso a paso** del registro de dispositivos Android (Cloud Identity) pensada como material de referencia/manual. | Google Cloud (Cloud Identity |
| `ics_extractor.py` | Parser de ficheros **iCalendar (.ics)**: extrae los campos de cada evento mediante expresiones regulares. | Parsing de iCalendar con `re` |
| `main.py` | **Google Cloud Function** que inscribe dispositivos **Android** en el inventario de propiedad de la empresa usando la API de **Cloud Identity**, leyendo los números de se | Google Cloud (Cloud Functions |
| `main_2.py` | Proyecto **"Alert New Apps"**: consulta Microsoft Graph para detectar **aplicaciones Win32 nuevas en Intune** y envía un aviso por correo. | Microsoft Graph (Intune) |
| `main_3.py` | Proyecto **"CalendarEvents"**: parsea un fichero **ICS** y crea los eventos correspondientes en **Outlook/Microsoft 365** vía Graph. | Microsoft Graph (Calendar) |
| `ms_auth.py` | Helper de **autenticación contra Microsoft Graph con MSAL** (client credentials) reutilizado por los proyectos de Python. | MSAL |
| `ms_auth_2.py` | Segundo helper de autenticación (proyecto *CalendarEvents*). En el backup quedó prácticamente vacío (apenas un par de líneas), probablemente un stub pendiente de completa |  |
| `test.py` | Función de **ejercicio/pruebas** que procesa un diccionario clave→valor numérico. |  |
| `testregistrodispositivos.py` | Versión de **pruebas** del registro de dispositivos Android: el mismo flujo de Cloud Identity + Google Sheets pero usado para validar el alta antes de desplegarlo como Cl |  |

