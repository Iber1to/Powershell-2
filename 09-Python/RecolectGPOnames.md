# RecolectGPOnames.py

Recorre un **backup de GPOs** y extrae, de cada `bkupInfo.xml`, el **GUID y el nombre de la GPO**, volcándolo a un CSV.

## Cómo funciona
Con `xml.etree.ElementTree` localiza los ficheros `bkupInfo.xml` del backup, lee los elementos `GPOGuid` y `GPODisplayName` (en el namespace de GroupPolicy) y escribe el inventario a CSV.

## Tecnología
Parsing XML (`ElementTree`) · CSV.

## Notas
Forma parte de un trabajo de consolidación de GPOs (cliente anonimizado). Se acompaña de `compare registry.py` para detectar duplicados.
