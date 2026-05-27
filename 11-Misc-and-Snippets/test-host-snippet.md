# test-host-snippet.ps1

Comprueba, para una lista de IPs, si están en el **fichero `hosts`** y revisa la **configuración de proxy** (detección de proxy Bluecoat).

## Cómo funciona
Recorre una lista de IPs y, para cada una, busca coincidencias en `C:\windows\system32\drivers\etc\hosts` y en la salida de `netsh winhttp show proxy`, contabilizando los aciertos.

## Tecnología
Fichero `hosts` · `netsh winhttp`.

## Notas
IPs anonimizadas a rango de documentación. Diagnóstico puntual de resolución/proxy.
