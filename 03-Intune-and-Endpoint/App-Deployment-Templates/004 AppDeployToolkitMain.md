# 004 AppDeployToolkitMain.ps1

**Motor del PowerShell App Deployment Toolkit (PSADT)** — software de terceros (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian), bajo licencia LGPL.

## Qué es

`AppDeployToolkitMain.ps1` es el corazón de PSADT: proporciona el conjunto de funciones (instalación/desinstalación silenciosa, interacción con el usuario, cierre de aplicaciones, gestión de reinicios, logging, etc.) que consumen los scripts `Deploy-Application.ps1`. No se ejecuta solo: lo cargan los scripts de despliegue (`001 Deploy-Exe`, `003 Deploy-SoapUI`…).

## Notas
Código de terceros íntegro; se conserva su licencia y autoría. Aquí se incluye como referencia de los despliegues construidos sobre PSADT.
