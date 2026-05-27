# FirefoxUninstallMinimunVersion.ps1

Equivalente a `ChromeUninstallMinimunVersion.ps1` para **Mozilla Firefox**: detecta versiones por debajo del mínimo permitido.

## Cómo funciona
Cierra los procesos de Firefox (`Stop-Process *firefox*`) y compara la versión instalada contra el umbral configurado para decidir el cumplimiento.

## Tecnología
Detección de versión · modelo de cumplimiento.

## Notas
Mismo patrón que la versión de Chrome.
