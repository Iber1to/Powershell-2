# convert-IPtoFQDN.ps1

Snippet que **resuelve nombres a partir de una lista de IPs** leídas de un fichero.

## Cómo funciona

Lee `ip.txt`, hace `ping -a` a cada dirección (resolución inversa) y se queda con el nombre corto del host de la respuesta.

## Tecnología
Resolución DNS inversa (`ping -a`).

## Notas
Utilidad rápida de cuatro líneas; para un uso más robusto convendría `Resolve-DnsName`.
