# Set-HostnameRemediationJira.ps1

**Remediación** que escribe en el fichero `hosts` la entrada necesaria para resolver la aplicación **Jira** hacia la IP indicada, cuando la detección ha encontrado que faltaba.

## Cómo funciona
Localiza el `hosts`, y si no existe el registro del/los FQDN de la aplicación lo añade con `Set-HostsRecord` apuntando a la IP correspondiente.

## Tecnología
Fichero `hosts` de Windows · proactive remediations de Intune.

## Notas
Pareja de `Set-HostanameDetectionJira.ps1`. FQDN/IP anonimizados.
