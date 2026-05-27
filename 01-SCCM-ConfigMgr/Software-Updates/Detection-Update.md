# Detection-Update.ps1

Script de **detección de nivel de parcheo** que decide si un equipo está al día traduciendo su *OS Build* a la fecha del parche correspondiente.

## Cómo funciona

- `get-WindowsVersion` obtiene el build del SO del equipo.
- Cruza ese build contra una tabla build→fecha de parche para deducir el mes/año de la última actualización acumulativa instalada.
- Si la fecha es más reciente que el umbral válido, devuelve `Exit 0` (conforme); si no, `Exit 1`.

## Tecnología
WMI/registro (versión de SO) · modelo de detección.

## Notas
Aproxima el nivel de parcheo por build, evitando depender del historial de Windows Update.
