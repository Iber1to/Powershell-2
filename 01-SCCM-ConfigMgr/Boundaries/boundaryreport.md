# boundaryreport.ps1

**Cmdlet de terceros** (`Get-BoundaryReport`, de Dani Schädler / Thomas Kurth) que recorre los dispositivos de ConfigMgr y sus boundaries de tipo *IP range* y calcula **qué subredes faltan** por dar de alta.

## Cómo funciona

- Requiere tener cargado el módulo de PowerShell de ConfigMgr.
- Devuelve el informe como objetos (`-PSOutput`) o lo exporta a CSV (`-CSV -Path`).
- La cabecera incluye un ejemplo para **crear automáticamente** las boundaries que faltan: filtra las entradas sin boundary asignada y lanza `New-CMBoundary -Type IPRange` para cada subred nueva.

## Tecnología
SCCM / ConfigMgr · sólo aplica a boundaries IP Range (no Subnet ni AD Site).

## Notas
Código de origen externo; se mantiene la atribución de los autores en la cabecera.
