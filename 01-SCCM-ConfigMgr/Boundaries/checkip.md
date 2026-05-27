# checkip.ps1

Comprueba si **una IP concreta cae en alguna boundary** de tipo *IP range* del entorno. Pensado para una consulta puntual, no para recorrer colecciones.

## Cómo funciona

- Recibe dos parámetros obligatorios: `SiteServer` e `IPAddress`.
- Resuelve el site code consultando `SMS_ProviderLocation` por WMI en el site server.
- Lee las boundaries (`SMS_Boundary`, `BoundaryType = 3` = IP range) y, convirtiendo IPs a enteros de 32 bits, comprueba si la IP dada queda dentro de algún rango, devolviendo 1/0.

## Tecnología
SCCM / ConfigMgr vía WMI (`SMS_ProviderLocation`, `SMS_Boundary`) · cálculo de rangos IP.

## Notas
Es la versión "de línea de comandos" del chequeo que `BoundaryCheck.ps1` hace en lote.
