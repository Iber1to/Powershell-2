# Test-SCCM_Conectivty_ports.ps1

Comprueba la **conectividad TCP necesaria para ConfigMgr** tanto desde el punto de vista de un cliente como de un servidor, sobre los puertos por defecto.

## Cómo funciona

- Se ejecuta indicando el FQDN/IP de la máquina a comprobar y una opción: `S` (servidor) o `C` (cliente).
- Para comprobar un **servidor** se lanza desde un cliente; para comprobar un **cliente** se lanza desde un servidor de SCCM.
- Recorre el conjunto de puertos relevantes (los del cliente; en servidores no entra a validar los puertos contra otros servidores de SCCM/SQL/AD/Microsoft) y reporta el resultado.

## Tecnología
`Test-NetConnection` · ConfigMgr.

## Notas
De origen externo, adaptado al entorno. Útil como diagnóstico rápido de firewall cuando un cliente no comunica.
