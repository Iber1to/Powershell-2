import requests
import os
import json
import datetime
import msal
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

def get_client_credential():
    return {
        'client_id': "11111111-1111-1111-1111-000000008767",
        'client_secret': "REDACTED_CLIENT_SECRET",
        'authority': "https://login.microsoftonline.com/11111111-1111-1111-1111-000000008768",
        'scope': ['https://graph.microsoft.com/.default']
    }
def get_access_token():
    credentials = get_client_credential()
    app = msal.ConfidentialClientApplication(
        credentials['client_id'], authority=credentials['authority'],
        client_credential=credentials['client_secret']
    )

    result = app.acquire_token_silent(credentials['scope'], account=None)
    if not result:
        result = app.acquire_token_for_client(scopes=credentials['scope'])
    
    return result['access_token'] if 'access_token' in result else None

def check_new_apps(token):
    # Define la URL de la API
    url = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?$filter=(isof('microsoft.graph.win32LobApp'))&$select=displayName,createdDateTime&$orderby=displayName"
    
    # Encabezados de la solicitud, incluyendo el token de autorización
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Realiza la solicitud a la API
    response = requests.get(url, headers=headers)
    apps = response.json().get('value', [])
    
    # Archivo para almacenar la última fecha de ejecución
    last_run_file = "last_run.txt"
    
    # Verifica si el archivo existe para leer la última fecha de ejecución
    if os.path.exists(last_run_file):
        with open(last_run_file, "r") as file:
            last_run_str = file.read()
            last_run = datetime.datetime.fromisoformat(last_run_str)
    else:
        # Si el archivo no existe, cargamos la fecha actual
        last_run = datetime.datetime.min
    
    # Filtra las aplicaciones publicadas después de la última ejecución
    new_apps = [app for app in apps if convert_to_naive(datetime.datetime.fromisoformat(app["createdDateTime"])) > last_run]
    
    # Actualiza la fecha de la última ejecución
    with open(last_run_file, "w") as file:
        file.write(datetime.datetime.now().isoformat())
    
    return new_apps
def convert_to_naive(dt):
    # Convierte a UTC y luego elimina la información de la zona horaria
    return dt.astimezone(datetime.timezone.utc).replace(tzinfo=None)

def send_email(subject, body):
    sender_address = 'user@contoso.com'
    sender_pass = 'aqhr jyml rtto glvb'
    receiver_address = 'user@gmail'
    
    # Configuración del mensaje
    message = MIMEMultipart()
    message['From'] = sender_address
    message['To'] = receiver_address
    message['Subject'] = subject
    message.attach(MIMEText(body, 'plain'))
    
    # Configuración del servidor SMTP
    session = smtplib.SMTP('smtp.gmail.com', 587)
    session.starttls() # Habilita seguridad
    session.login(sender_address, sender_pass) # Inicio de sesión
    text = message.as_string()
    session.sendmail(sender_address, receiver_address, text)
    session.quit()
# Ejemplo de uso
# Debes reemplazar 'your_access_token_here' con tu token de acceso real
new_apps = check_new_apps(get_access_token())
if new_apps:
    body = "Se encontraron nuevas apps:\n\n" + json.dumps(new_apps, indent=2)
    send_email("Nuevas Apps Encontradas", body)
print(json.dumps(new_apps, indent=2))
print(new_apps)
