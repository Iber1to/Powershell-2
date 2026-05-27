
"""
Script de ejemplo para inscribir dispositivos Android en el inventario de propiedad de la empresa
usando Google Cloud Functions y la API de Cloud Identity. Este script lee una hoja de cálculo de
Google Sheets donde se listan los números de serie de los dispositivos y realiza el registro
automático de los dispositivos que aún no han sido procesados. Está diseñado para ejecutarse
como una Cloud Function en Google Cloud Platform.

Antes de utilizar este script, asegúrate de cumplir los requisitos descritos en el manual de
configuración:

1. Habilitar las APIs necesarias en el proyecto de Google Cloud (Admin SDK, Cloud Identity y
   Google Sheets API).
2. Crear una cuenta de servicio y habilitar la delegación de todo el dominio con los scopes
   adecuados (`cloud-identity.devices`, `admin.directory.device.mobile`, `spreadsheets`).
3. Compartir la hoja de cálculo con la cuenta de servicio o utilizar impersonación de un
   administrador autorizado.
4. Definir las variables de entorno `SERVICE_ACCOUNT_FILE`, `DELEGATED_ADMIN` y `SHEET_ID`
   en la configuración de la función (o utilizar Secret Manager para la clave JSON).  

Autor: Equipo de TI
Fecha: Octubre 2025
"""

import os
from typing import List
from typing import List, Optional
from googleapiclient.discovery import build
from google.oauth2 import service_account

# Scopes necesarios para las APIs que vamos a utilizar.  
SCOPES = [
    "https://www.googleapis.com/auth/cloud-identity.devices",
    "https://www.googleapis.com/auth/admin.directory.device.mobile",
    "https://www.googleapis.com/auth/spreadsheets",
]

os.environ["SERVICE_ACCOUNT_FILE"] = "D:/OneDriveVendorIT/OneDrive - VendorIT/Scripts/Client Retail/Client Retail-registromoviles-e6a0ba2de477.json"
os.environ["DELEGATED_ADMIN"] = "user@contoso.com"
os.environ["SHEET_ID"] = "1hM3WviVhjYSA0yIAJVJr3n_wQi00cspZsz7A6vDDaGs"
# os.environ["SHEET_RANGE"] = "Inventario!A2:E"  # Opcional


def obtener_credenciales() -> service_account.Credentials:
    """Carga las credenciales de la cuenta de servicio y aplica la delegación de dominio."""
    service_account_file = os.getenv("SERVICE_ACCOUNT_FILE")
    if not service_account_file:
        raise RuntimeError(
            "La variable SERVICE_ACCOUNT_FILE no está definida. Debes especificar la ruta al JSON de la cuenta de servicio en las variables de entorno."
        )
    delegated_admin = os.getenv("DELEGATED_ADMIN")
    if not delegated_admin:
        raise RuntimeError(
            "La variable DELEGATED_ADMIN no está definida. Debes especificar el correo del administrador que se impersonará para las llamadas a las APIs."
        )
    credentials = service_account.Credentials.from_service_account_file(
        service_account_file,
        scopes=SCOPES,
    )
    delegated_credentials = credentials.with_subject(delegated_admin)
    return delegated_credentials

def leer_hoja(
    sheets_service,
    spreadsheet_id: str,
    rango: str
) -> List[List[Optional[str]]]:
    """
    Lee un rango de celdas de Google Sheets y devuelve las filas.
    Cada fila es una lista de cadenas o None si la celda está vacía,
    lo que permite luego interpretar asset_tag opcionalmente.
    """
    result = (
        sheets_service.spreadsheets()
        .values()
        .get(
            spreadsheetId=spreadsheet_id,
            range=rango,
            majorDimension="ROWS"
        )
        .execute()
    )
    values = result.get("values", [])
    # Normaliza: convierte cada celda vacía en None para evitar error
    filas: List[List[Optional[str]]] = []
    for fila in values:
        # Asegura que al menos 2 columnas estén presentes (serial, assetTag)
        if len(fila) < 2:
            fila = fila + [None] * (2 - len(fila))
        # strip() para quitar espacios
        filas.append([celda.strip() if isinstance(celda, str) else None for celda in fila])
    return filas

def actualizar_celda(sheets_service, spreadsheet_id: str, celda: str, valor: str) -> None:
    """Actualiza una única celda en Google Sheets"""
    body = {"values": [[valor]]}
    sheets_service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range=celda,
        valueInputOption="RAW",
        body=body,
    ).execute()

def registrar_dispositivo(devices_service, serial: str, asset_tag: str, tipo: str = "android") -> None:
    body = {
        "device": {
            "serialNumber": serial,
            "deviceType": tipo,
        }
    }
    if asset_tag:
        body["device"]["assetTag"] = asset_tag
    # Usamos `customer` en lugar de `parent` según la documentación oficial:contentReference[oaicite:1]{index=1}
    devices_service.devices().create(
        customer="customers/my_customer",
        body=body,
    ).execute()

def procesar_hoja(event, context):
    """Función principal para la Cloud Function"""
    creds = obtener_credenciales()
    sheets_service = build("sheets", "v4", credentials=creds)
    devices_service = build("cloudidentity", "v1", credentials=creds)
    spreadsheet_id = os.getenv("SHEET_ID")
    if not spreadsheet_id:
        raise RuntimeError("La variable SHEET_ID no está definida.")
    rango_datos = os.getenv("SHEET_RANGE", "Inventario!A2:E")
    filas = leer_hoja(sheets_service, spreadsheet_id, rango_datos)
    for idx, fila in enumerate(filas, start=2):
        serial = fila[0] if len(fila) > 0 else ""
        asset_tag = fila[1] if len(fila) > 1 else ""
        tipo = fila[2] if len(fila) > 2 and fila[2] else "android"
        procesado = fila[3] if len(fila) > 3 else ""
        if not serial:
            continue
        if isinstance(procesado, str) and procesado.strip().lower() == 'sí':
            continue
        try:
            registrar_dispositivo(devices_service, serial, asset_tag, tipo)
            celda_procesado = f"D{idx}"
            actualizar_celda(sheets_service, spreadsheet_id, celda_procesado, "Sí")
        except Exception as e:
            error_msg = str(e)
            celda_error = f"E{idx}"
            actualizar_celda(sheets_service, spreadsheet_id, celda_error, error_msg)

if __name__ == "__main__":
    procesar_hoja(None, None)
    print("Procesamiento terminado")
