# ChromeUninstallMinimunVersion.ps1

Comprobación de cumplimiento que marca como **no conforme (y candidato a desinstalar) a Google Chrome por debajo de una versión mínima**.

## Cómo funciona
Define la versión principal mínima admitida (variable `$versionprincipal`) y compara contra la versión instalada de Chrome, devolviendo el estado de cumplimiento.

## Tecnología
Registro / detección de versión · modelo de cumplimiento.

## Notas
`FirefoxUninstallMinimunVersion.ps1` es el equivalente para Firefox; `Delete-ChromeOldVersions.ps1` y `chrome_Uninstall.ps1` abordan la limpieza.
