# check-IntuneAcces.ps1

Comprueba la **conectividad de red hacia los endpoints necesarios para Intune/MDM** desde un equipo.

## Cómo funciona
Define una función `TestPort` (acepta host y uno o varios puertos por pipeline) que prueba cada puerto y, con ella, valida el acceso a los servicios/puertos que necesita el cliente de Intune.

## Tecnología
Pruebas de puertos TCP (`System.Net.Sockets` / `Test-NetConnection`).

## Notas
Diagnóstico de firewall/proxy cuando un equipo no inscribe o no recibe políticas de Intune.
