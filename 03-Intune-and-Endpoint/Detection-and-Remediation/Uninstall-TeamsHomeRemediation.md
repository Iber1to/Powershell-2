# Uninstall-TeamsHomeRemediation.ps1

**Remediación** que elimina el paquete de consumo "Teams Home" (`MicrosoftTeams` AppX) de los equipos donde la detección lo ha encontrado.

## Cómo funciona
Recupera el paquete AppX `MicrosoftTeams` y lo desinstala (`Remove-AppPackage`), evitando que la versión personal conviva con el Teams corporativo.

## Tecnología
Paquetes AppX/MSIX.

## Notas
Pareja de `Uninstall-TeamsHomeDetection.ps1`.
