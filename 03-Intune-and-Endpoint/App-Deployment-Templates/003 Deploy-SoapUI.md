# 003 Deploy-SoapUI.ps1

Script de despliegue **basado en PSADT** que instala/desinstala **SoapUI**.

## Cómo funciona
Es un `Deploy-Application.ps1` del PowerShell App Deployment Toolkit particularizado para SoapUI: define la fase de instalación (cierre de procesos, ejecución del instalador, configuración) y la de desinstalación, apoyándose en las funciones de `AppDeployToolkitMain.ps1`.

## Tecnología
PSADT (PowerShell App Deployment Toolkit).

## Notas
Ejemplo concreto del patrón PSADT usado en el entorno.
