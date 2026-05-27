# Deploy-MSI.ps1

Plantilla propia para **instalar paquetes MSI** de forma desatendida desde Intune, con el mismo esqueleto de logging y comprobación de privilegios que `Deploy-Exe.ps1`.

## Cómo funciona
Lanza `msiexec` con los parámetros silenciosos del MSI y registra el resultado mediante la función `Write-SimpleLog` (ruta de log según se ejecute o no como administrador).

## Notas
Pareja de instalación MSI dentro del juego de plantillas (`Deploy-Exe`, `Uninstall-Exe`, `Uninstall-MSI`).
