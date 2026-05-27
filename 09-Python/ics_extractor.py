import re
from datetime import datetime

# Función para parsear el contenido de un archivo .ics
def parse_ics(content):
    event = {}
    # Expresiones regulares para encontrar las diferentes partes del evento
    summary_match = re.search(r'SUMMARY:(.+)', content)
    dtstart_match = re.search(r'DTSTART:(\d+T\d+)', content)
    dtend_match = re.search(r'DTEND:(\d+T\d+)', content)
    location_match = re.search(r'LOCATION:(.+)', content)
    description_match = re.search(r'DESCRIPTION:(.+)', content)
    attendees_matches = re.finditer(r'ATTENDEE[^:]+:(.+)', content)

    if summary_match:
        event['subject'] = summary_match.group(1)
    if dtstart_match:
        event['start'] = {
            'dateTime': datetime.strptime(dtstart_match.group(1), '%Y%m%dT%H%M%S').isoformat(),
            'timeZone': 'UTC'
        }
    if dtend_match:
        event['end'] = {
            'dateTime': datetime.strptime(dtend_match.group(1), '%Y%m%dT%H%M%S').isoformat(),
            'timeZone': 'UTC'
        }
    if location_match:
        event['location'] = {
            'displayName': location_match.group(1)
        }
    if description_match:
        event['body'] = {
            'contentType': 'HTML',
            'content': description_match.group(1).replace("\\N", "<br>").replace("\\n", "<br>")
        }
    if attendees_matches:
        event['attendees'] = []
        for match in attendees_matches:
            email = re.search(r'MAILTO:(.+)', match.group(1))
            if email:
                event['attendees'].append({
                    'emailAddress': {
                        'address': email.group(1),
                        'name': email.group(1).split('@')[0]
                    },
                    'type': 'required'
                })

    return event

def process_ics_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
    return parse_ics(content)