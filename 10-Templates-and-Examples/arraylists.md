# arraylists.ps1

Ejemplo de uso de **ArrayLists** para hacer un **cruce a tres bandas** entre grupos de Azure AD y grupos on-prem.

## Cómo funciona
Inicializa varios `System.Collections.ArrayList` (los de Azure, los on-prem, los que están en ambos, y los que sólo están en uno u otro), carga los datos desde ficheros de texto por `userPrincipalName` y calcula las intersecciones y diferencias.

## Tecnología
`System.Collections.ArrayList` · CSV/TXT.

## Notas
Es el patrón de comparación que está detrás de la conciliación de grupos (relacionado con `AzureGroups.ps1`).
