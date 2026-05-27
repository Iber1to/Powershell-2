# 002 Uninstall-Exe.ps1

Plantilla de **desinstalación** de aplicaciones `.exe` basada en PSADT, complementaria de `001 Deploy-Exe.ps1`.

## Cómo funciona
Estructura `Deploy-Application.ps1` de PSADT en modo *Uninstall*: localiza la aplicación, cierra procesos y ejecuta la desinstalación silenciosa usando las funciones del toolkit.

## Notas
Ver `004 AppDeployToolkitMain.ps1` para el motor subyacente.
