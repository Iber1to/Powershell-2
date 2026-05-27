# Obtencion-Usuarios-Existe-INT-v3.ps1

Versión 3 del script de descubrimiento de la migración: comprueba qué **usuarios** del dominio origen ya existen en el dominio destino ("INT").

## Cómo funciona
A partir de los DN base de usuarios (y sus exclusiones), recorre las cuentas del origen y verifica su presencia en el dominio destino, dejando un CSV con el cruce y ficheros de no encontrados/exclusiones.

## Tecnología
Active Directory (multi-dominio).

## Notas
Junto con `ProcesadoUsuariosyGrupos-v4.ps1` forma el núcleo del cruce de usuarios de la migración.
