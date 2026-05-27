import requests
import json
from auth.ms_auth import get_access_token
from ics_parser.ics_extractor import process_ics_file


# Ruta al archivo ICS
file_path = 'C:/Users/user/OneDrive - VendorIT/Scripts/Python/CalendarEvents/filesCalendar/prueba1'

def create_outlook_event(event_details):
    access_token = get_access_token()
    if not access_token:
        print("Error al obtener el token de acceso. Verifique las credenciales y la configuración.")
        return

    headers = {
        'Authorization': 'Bearer ' + access_token,
        'Content-Type': 'application/json'
    }
    response = requests.post(
        # 'https://graph.microsoft.com/v1.0/users/user@contoso.com/events',
        'https://graph.microsoft.com/v1.0/users/user@contoso.com/events',
        headers=headers,
        json=event_details
    )

    if response.status_code == 201:
        print("Evento creado con éxito en el calendario de Outlook.")
        return response.json()
    else:
        print("Error al crear evento:", response.json())


def confirm_and_create_event(event_data):
    print("Detalles del evento a crear:")
    print(json.dumps(event_data, indent=4))

    confirm = input("¿Deseas crear este evento? (sí/no): ").lower()
    if confirm == 'sí' or confirm == 'si':
        user_email = "user@example.com"  # Reemplaza con el email del usuario del calendario
        create_outlook_event(event_data)
        print("Evento creado.")
    else:
        print("Creación de evento cancelada.")
# Procesamiento del archivo ICS
event_data = process_ics_file(file_path)

# Confirmación y creación del evento
confirm_and_create_event(event_data)

'''
# Ejemplo de datos del evento
event_data = {
    "subject": "Reunión Importante",
    "body": {
        "contentType": "HTML",
        "content": "Reunion Con IsaaC muy importante."
    },
    "start": {
        "dateTime": "2024-01-25T14:00:00",
        "timeZone": "America/New_York"
    },
    "end": {
        "dateTime": "2024-01-25T15:00:00",
        "timeZone": "America/New_York"
    },
    "location": {
        "displayName": "Sala de Conferencias 1"
    },
    "attendees": [
        {
            "emailAddress": {
                "address": "user@example.com",
                "name": "Persona Ejemplo"
            },
            "type": "required"
        }
    ]
}
'''

