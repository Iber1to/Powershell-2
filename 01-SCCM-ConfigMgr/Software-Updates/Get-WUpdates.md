# Get-WUpdates.ps1

**Función de terceros** (`Get-WindowsUpdatesInstall`) para **buscar, descargar e instalar actualizaciones de Windows** desde PowerShell, con filtrado fino.

## Cómo funciona

Trabaja en cuatro fases (buscar, elegir, descargar, instalar) y permite filtrar tanto del lado servidor (pre-search: `IsInstalled=0`, categorías, etc.) como del lado cliente (post-search por `KBArticleID`). Expone parámetros como `-UpdateType` para acotar qué se instala.

## Tecnología
API COM de Windows Update (Microsoft.Update.*).

## Notas
Es una utilidad genérica de WU de la comunidad (886 líneas). Los GUID de categoría de ejemplo de la cabecera han quedado alterados por la anonimización.
