# Uninstall-Exe.ps1

Plantilla propia para **desinstalar** aplicaciones basadas en `.exe` desde Intune.

## Cómo funciona
Ejecuta el desinstalador (normalmente localizado por su `UninstallString` o ruta conocida) con argumentos silenciosos y registra el resultado con `Write-SimpleLog`.

## Notas
Contrapartida de `Deploy-Exe.ps1`.
