# temp-snippet.ps1

Snippet de **bootstrap**: copia el script `reparalibreriadp.ps1` desde un recurso de red a la carpeta local de scripts y verifica que ha quedado.

## Cómo funciona
Comprueba/crea la carpeta destino `C:\01.Scripts`, copia el script desde la ruta de red y devuelve `Exit 0/1` según exista al final.

## Tecnología
Copia de ficheros · recurso de red.

## Notas
Patrón típico de "descargar el script a local antes de ejecutarlo". Ruta UNC anonimizada.
