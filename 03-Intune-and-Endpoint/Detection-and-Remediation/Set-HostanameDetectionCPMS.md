# Set-HostanameDetectionCPMS.ps1

Script de **detección** (proactive remediation de Intune) que comprueba si el fichero `hosts` del equipo tiene la entrada necesaria para resolver la aplicación **CPMS** hacia la IP correcta.

## Cómo funciona

- Abre transcripción a `C:\Windows\Temp\Set-HostanameDetection.log`.
- Una función auxiliar localiza la ruta del fichero `hosts` según la plataforma (`Get-HostsFile`) y se comprueba si ya existe el registro esperado para el/los FQDN de la aplicación.
- Si la entrada existe devuelve conforme; si falta, marca no conforme para que se ejecute la remediación.

## Tecnología
Fichero `hosts` de Windows · proactive remediations de Intune.

## Notas
Pareja: `Set-HostnameRemediationCPMS.ps1`. Forma parte de un conjunto de scripts que fuerzan por `hosts` la resolución de aplicaciones de un proyecto (CPMS, Fiori, Jira). Los FQDN/IP reales se han anonimizado.
