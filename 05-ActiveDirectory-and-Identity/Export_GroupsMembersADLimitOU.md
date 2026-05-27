# Export_GroupsMembersADLimitOU.ps1

Variante de `Export_GroupsMembersAD.ps1` que calcula la **pertenencia a grupos de forma recursiva** y **limitada a una OU**.

## Cómo funciona
La función `Get-ADUserGroupsRecursive` recorre la pertenencia anidada de cada usuario (usando un `HashSet` para no repetir grupos ya procesados) restringiendo el análisis al DN/OU indicado.

## Tecnología
Active Directory · resolución recursiva de grupos.

## Notas
Útil cuando importa la pertenencia efectiva (incluida la anidada) dentro de una rama concreta del directorio.
