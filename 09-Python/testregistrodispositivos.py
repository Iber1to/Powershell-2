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
SA_FILE = 'D:/OneDriveVendorIT/OneDrive - VendorIT/Scripts/Client Retail/Client Retail-registromoviles-e6a0ba2de477.json'
ADMIN_EMAIL = 'user@contoso.com'
TIMEZONE = pytz.timezone('Europe/Madrid')

def obtener_token(sa_file: str, admin_email: str) -> str:
    """
    Obtiene un token de acceso OAuth2 impersonando al administrador.
    """
    creds = service_account.Credentials.from_service_account_file(sa_file, scopes=SCOPES_IDENTITY)
    delegated = creds.with_subject(admin_email)
    req = google.auth.transport.requests.Request()
    delegated.refresh(req)
    return delegated.token

def crear_dispositivo(serial_number: str, token: str, asset_tag: str | None = None) -> dict:
    """
    Crea un dispositivo en Cloud Identity. Puede incluir opcionalmente un assetTag.
    """
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
    """
    Procesa la pestaña 'Pendiente': registra cada dispositivo y lo mueve a 'Procesado' o 'Error'.
    Lee las columnas SerialNumber y AssetTag de la hoja Pendiente.
    """
    # Autenticación para Google Sheets con la cuenta de servicio
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
            # Añadimos la fila a la pestaña Procesado, incluyendo el AssetTag
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
            # En caso de error registramos el mensaje en la hoja Error
            ws_error.append_row([serial, fecha_registro, str(e)])
        # Eliminamos la fila de Pendiente procesada:contentReference[oaicite:0]{index=0}
        ws_pendiente.delete_rows(fila_actual)

# Ejemplo de ejecución
if __name__ == '__main__':
    # Sustituye por tu ID real de la hoja de cálculo (el código entre /d/ y /edit)
    SPREADSHEET_ID = '1hM3WviVhjYSA0yIAJVJr3n_wQi00cspZsz7A6vDDaGs'
    procesar_dispositivos(SPREADSHEET_ID)
