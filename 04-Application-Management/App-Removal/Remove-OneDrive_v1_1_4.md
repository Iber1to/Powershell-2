# Remove-OneDrive_v1_1_4.ps1

Script controlador robusto (v1.1.4, ~1.300 líneas) para **retirar OneDrive** de un equipo gestionado y limpiar todos sus restos, tanto a nivel de máquina como por cada perfil de usuario.

## Cómo funciona
Detiene OneDrive, ejecuta el desinstalador, y a continuación limpia restos por máquina y recorriendo los perfiles (carpetas, claves de registro, accesos directos, integración con el Explorador). Está escrito de forma defensiva, con logging y tolerancia a equipos donde algo no aplique.

## Tecnología
Registro · sistema de ficheros · gestión de perfiles · pensado para Intune/Ivanti.

## Notas
Forma parte de una familia de "removers" del repositorio (Google Drive, Oracle Client, WPS Office) escritos con el mismo patrón de controlador + limpieza exhaustiva.
