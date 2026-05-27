# main_3.py

Proyecto **"CalendarEvents"**: parsea un fichero **ICS** y crea los eventos correspondientes en **Outlook/Microsoft 365** vía Graph.

## Cómo funciona
- Usa `ics_parser.ics_extractor.process_ics_file` para extraer los eventos del `.ics`.
- Por cada evento construye el cuerpo y hace `POST` a `https://graph.microsoft.com/v1.0/users/<buzón>/events` para crearlo en el calendario.

## Tecnología
Microsoft Graph (Calendar) · parsing de iCalendar.

## Notas
Ruta local de ejemplo y buzón anonimizados. Depende de `ics_extractor.py` y del helper de autenticación.
