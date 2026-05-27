# Set-NombreBoundary.ps1

Utilidad para **renombrar boundaries en bloque** mediante búsqueda y reemplazo de una cadena en su nombre (por ejemplo, migrar el prefijo `PA1-` a `PE1-`).

## Cómo funciona

- Define el patrón de búsqueda (con comodín `*`) y las cadenas origen/destino.
- Carga las boundaries que cumplen el patrón con `Get-CMBoundary`, muestra un ejemplo de cómo quedaría el nombre y cuántas se verán afectadas, y **espera confirmación por teclado** antes de actuar.
- Aplica `Set-CMBoundary -NewName` a cada una sustituyendo la cadena.

## Tecnología
SCCM / ConfigMgr (`Get-CMBoundary` / `Set-CMBoundary`) · módulo `AAGFunctions`.

## Notas
Incluye una pausa de confirmación a propósito: es una operación masiva sobre nombres de boundaries y conviene revisar el ejemplo antes de lanzarla.
