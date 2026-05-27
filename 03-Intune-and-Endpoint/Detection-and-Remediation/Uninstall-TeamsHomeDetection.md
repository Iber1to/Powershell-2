# Uninstall-TeamsHomeDetection.ps1

Detección que comprueba si está instalada la versión de consumo **"Teams Home"** (el paquete AppX `MicrosoftTeams` que Windows preinstala), de cara a retirarla en equipos corporativos.

## Cómo funciona
Busca con `Get-AppPackage` un paquete cuyo nombre contenga `MicrosoftTeams`; si lo encuentra devuelve `Exit 1` (detectado, hay que remediar), y si no, `Exit 0`.

## Tecnología
Paquetes AppX/MSIX (`Get-AppPackage`).

## Notas
Pareja de `Uninstall-TeamsHomeRemediation.ps1`.
