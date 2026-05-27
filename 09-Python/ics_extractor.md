# ics_extractor.py

Parser de ficheros **iCalendar (.ics)**: extrae los campos de cada evento mediante expresiones regulares.

## Cómo funciona
`parse_ics(content)` busca con regex `SUMMARY`, `DTSTART`, `DTEND`, `LOCATION`, `DESCRIPTION` y los `ATTENDEE`, y devuelve un diccionario con los datos del evento listo para crearlo en otro sistema.

## Tecnología
Parsing de iCalendar con `re`.

## Notas
Es la dependencia que usa `main_3.py` (CalendarEvents) para leer los `.ics` antes de volcarlos a Outlook.
