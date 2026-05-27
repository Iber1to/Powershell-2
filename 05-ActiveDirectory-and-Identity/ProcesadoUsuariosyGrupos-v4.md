# ProcesadoUsuariosyGrupos-v4.ps1

Núcleo del **procesado de usuarios y grupos** de la migración de directorio: cruza usuarios y su pertenencia a grupos entre el dominio origen y el destino ("INT").

## Cómo funciona
Lee los DN base de usuarios (con exclusiones), recorre las cuentas y sus grupos de origen, comprueba su existencia/equivalencia en el destino y genera varios CSV: usuarios, grupos de origen y grupos de destino, además de ficheros de exclusiones y de no encontrados.

## Tecnología
Active Directory (multi-dominio).

## Notas
Es la pieza más completa del juego de migración; los CSV que produce están redactados en `99-Datasets-Redacted`.
