# Deploy-Exe.ps1

Plantilla **ligera y propia** para empaquetar la instalación de una aplicación basada en `.exe` y desplegarla con Intune (o cualquier ESM).

## Cómo funciona

Incluye una función `Write-SimpleLog` que genera el nombre del log a partir del nombre del script y la fecha, y **elige la ruta del log según privilegios**: si se ejecuta como administrador escribe en `C:\Windows\Logs\Software`, y si no, en la carpeta de documentos del usuario. A partir de ahí lanza el instalador con sus argumentos silenciosos.

## Tecnología
PowerShell · detección de elevación · logging propio.

## Notas
Es la alternativa "casera" y minimalista al PowerShell App Deployment Toolkit (que también está en esta carpeta). `Deploy-MSI.ps1`, `Uninstall-Exe.ps1` y `Uninstall-MSI.ps1` son las plantillas hermanas para los demás casos.
