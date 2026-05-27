# Uninstall-DockerDesktop.ps1

Desinstala **Docker Desktop** y verifica que efectivamente ha desaparecido.

## Cómo funciona
Ejecuta el desinstalador de Docker Desktop (`Docker Desktop Installer.exe uninstall`) y luego comprueba en las claves de desinstalación del registro si queda algún rastro de "Docker": si lo hay devuelve `Exit 1` (fallo), si no, éxito.

## Tecnología
Registro de Windows (claves de desinstalación).

## Notas
Script corto de remediación con verificación posterior.
