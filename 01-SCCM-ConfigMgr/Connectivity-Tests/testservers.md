# testservers.ps1

Averigua **contra qué WSUS está configurado un cliente** (leyéndolo de su propio log) y comprueba que ese servidor responda en el puerto de WSUS.

## Cómo funciona

- Busca en `WUAHandler.log` la última línea "Existing WUA Managed server was already set" para extraer el nombre del WSUS y la fecha.
- Lanza `Test-NetConnection` contra ese WSUS en el puerto 8530 y devuelve `Exit 0` si responde. (Incluye comentada una comprobación adicional de antigüedad de la configuración.)

## Tecnología
Parsing de `WUAHandler.log` · `Test-NetConnection` (WSUS 8530).

## Notas
Pensado como detección: confirma que el cliente apunta a un WSUS alcanzable.
