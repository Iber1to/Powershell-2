import os
import json
import datetime
import pytz
import urllib.request
import urllib.error
import google.auth.transport.requests
from google.oauth2 import service_account
import gspread

# Configuración global
SCOPES_IDENTITY = ['https://www.googleapis.com/auth/cloud-identity.devices']
SCOPES_SHEETS = [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive'
]
# Ruta al fichero de la cuenta de servicio dentro del código fuente.
# Puedes subir tu JSON junto al script y referenciarlo así.
SA_FILE = 'service-account.json'
ADMIN_EMAIL = 'user@contoso.com'
TIMEZONE = pytz.timezone('Europe/Madrid')

def obtener_token(sa_file: str, admin_email: str) -> str:
    creds = service_account.Credentials.from_service_account_file(sa_file, scopes=SCOPES_IDENTITY)
    delegated = creds.with_subject(admin_email)
    req = google.auth.transport.requests.Request()
    delegated.refresh(req)
    return delegated.token

def crear_dispositivo(serial_number: str, token: str, asset_tag: str | None = None) -> dict:
    BASE_URL = 'https://cloudidentity.googleapis.com/v1/'
    headers = {
        'authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    body = {
        'serialNumber': serial_number,
        'deviceType': 'ANDROID'
    }
    if asset_tag:
        body['assetTag'] = asset_tag

    data = json.dumps(body, separators=(',', ':')).encode('utf-8')
    req = urllib.request.Request(BASE_URL + 'devices', data=data, headers=headers, method='POST')
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read())
        return result.get('response', {})

def procesar_dispositivos(spreadsheet_id: str) -> None:
    creds_sheets = service_account.Credentials.from_service_account_file(
        SA_FILE, scopes=SCOPES_SHEETS)
    gc = gspread.authorize(creds_sheets)
    sh = gc.open_by_key(spreadsheet_id)

    ws_pendiente = sh.worksheet('Pendiente')
    ws_procesado = sh.worksheet('Procesado')
    ws_error = sh.worksheet('Error')

    filas = ws_pendiente.get_all_values()
    fila_actual = 2  # Comenzamos en la segunda fila (la primera es cabecera)
    for fila in filas[1:]:
        serial = fila[0].strip()
        asset_tag = fila[1].strip() if len(fila) > 1 else ""
        if not serial:
            fila_actual += 1
            continue

        fecha_registro = datetime.datetime.now(TIMEZONE).isoformat()
        try:
            token = obtener_token(SA_FILE, ADMIN_EMAIL)
            resp = crear_dispositivo(serial, token, asset_tag=asset_tag or None)
            ws_procesado.append_row([
                serial,
                fecha_registro,
                asset_tag,
                resp.get('deviceType', ''),
                resp.get('createTime', ''),
                resp.get('ownerType', ''),
                resp.get('name', '')
            ])
        except Exception as e:
            ws_error.append_row([serial, fecha_registro, str(e)])
        ws_pendiente.delete_rows(fila_actual)

def registrar_dispositivos(request):
    """
    Función de entrada para Cloud Function (trigger HTTP).
    Lee el ID de la hoja de cálculo desde la variable de entorno SPREADSHEET_ID,
    procesa los dispositivos y devuelve una respuesta.
    """
    spreadsheet_id = os.environ.get('SPREADSHEET_ID')
    if not spreadsheet_id:
        return ('SPREADSHEET_ID no está definido en variables de entorno', 500)
    procesar_dispositivos(spreadsheet_id)
    return ('Procesado completo', 200)
