# AzureGroups.ps1

Vía **Microsoft Graph**, anida automáticamente todos los grupos de un país dentro del grupo "paraguas" de su región.

## Cómo funciona
Conecta a Graph, lista los grupos cuyo nombre empieza por el prefijo del país (`MX-`, etc.), excluye el propio grupo de región y va anidando cada grupo de país como miembro del grupo de región.

## Tecnología
Microsoft Graph (`Connect-MgGraph`, `Get-MgGroup`) · grupos de Entra ID.

## Notas
El ID del grupo de región se ha sustituido por un GUID ficticio.
