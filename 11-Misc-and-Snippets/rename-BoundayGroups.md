# rename-BoundayGroups.ps1

Renombra en bloque **boundaries** mediante búsqueda y reemplazo de una cadena en su nombre (mismo enfoque que `Set-NombreBoundary.ps1`).

## Cómo funciona
Conecta a SCCM (`AAGFunctions.ps1`), localiza las boundaries que cumplen el patrón de búsqueda (con comodín) y sustituye la cadena indicada en su nombre.

## Tecnología
SCCM / ConfigMgr (`Get-CMBoundary` / `Set-CMBoundary`).

## Notas
El nombre del fichero conserva la errata original ("Bounday"). Equivalente a `Boundaries/Set-NombreBoundary.ps1`.
