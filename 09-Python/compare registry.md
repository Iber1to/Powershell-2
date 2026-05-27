# compare registry.py

Compara ficheros por su **hash SHA-256** para detectar duplicados o cambios (por ejemplo, entre backups de GPO).

## Cómo funciona
`calculate_file_hash()` calcula el SHA-256 de cada fichero leyéndolo por bloques (e ignora los vacíos); el script recorre los directorios y agrupa/compara por hash, volcando el resultado a CSV.

## Tecnología
`hashlib` (SHA-256) · CSV.

## Notas
Complementa a `RecolectGPOnames.py` en el proyecto de consolidación de GPOs.
