# Remove-WPSOffice.ps1

Retira **WPS Office** (Kingsoft) y sus evidencias residuales de endpoints gestionados.

## Cómo funciona
Intenta primero la desinstalación limpia vía entradas ARP/`UninstallString` y `uninst.exe`; después limpia evidencias en el sistema de ficheros y en el registro (por máquina y por perfil).

## Tecnología
ARP/UninstallString · registro · sistema de ficheros.

## Notas
Remediación pensada para entornos gestionados; mismo patrón que el resto de removers.
