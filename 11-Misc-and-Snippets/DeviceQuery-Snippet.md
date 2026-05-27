# DeviceQuery-Snippet.ps1

Snippet que **recoge la configuración de proxy WinHTTP de un equipo** y la deja en un recurso de red con el nombre del host.

## Cómo funciona
Ejecuta `netsh winhttp show proxy` y vuelca la salida a `\\<servidor>\Reporte_proxy\<hostname>.txt`, útil para inventariar de un vistazo cómo está configurado el proxy en muchos equipos.

## Tecnología
`netsh winhttp` · recurso de red.

## Notas
Originalmente tenía un nombre poco descriptivo; se ha renombrado a algo legible. Ruta de red anonimizada.
