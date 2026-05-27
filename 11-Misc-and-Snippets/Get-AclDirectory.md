# Get-AclDirectory.ps1

Audita los **permisos NTFS (ACL) de un conjunto de directorios** indicados en un CSV, hasta una profundidad de subcarpetas configurable.

## Cómo funciona
Lee la lista de directorios desde un CSV, recorre cada uno hasta `$profundidadBusqueda` niveles, obtiene sus ACL y exporta el resultado a un fichero, registrando aparte las rutas a las que no se ha podido acceder.

## Tecnología
ACL / permisos NTFS (`Get-Acl`).

## Notas
Las rutas de entrada/salida se configuran al principio del script. Útil para revisiones de permisos de carpetas compartidas.
