# Get-DataDevice.ps1

Cruza los equipos de una colección de SCCM con los **logs de ConfigMgr Client Health** depositados en un recurso de red, para saber qué equipos han ejecutado alguna vez la herramienta de salud.

## Cómo funciona

- Conecta al proveedor de SCCM (`AAGFunctions.ps1`) y obtiene los nombres de los dispositivos de una colección.
- Lista los ficheros de log de Client Health en la ruta de red y, por cada equipo, comprueba si tiene log (y por tanto si ha pasado por la herramienta).
- Va construyendo objetos por dispositivo con esa información.

## Tecnología
SCCM / ConfigMgr · lectura de logs en recurso de red.

## Notas
Servidores y rutas UNC anonimizados (`SRVxxx`, `*.contoso.local`).
