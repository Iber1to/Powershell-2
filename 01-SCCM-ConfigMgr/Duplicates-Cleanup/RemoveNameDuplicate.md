# RemoveNameDuplicate.ps1

Limpia **duplicados por nombre** y los registros "Unknown" de SCCM.

## Cómo funciona

- Borra directamente los dispositivos `Unknown` (y deja comentadas las variantes x86/x64 "Unknown Computer").
- Carga los equipos de la colección de nombres duplicados y, para cada nombre, recupera todos los dispositivos que lo comparten y cuenta las repeticiones para depurarlos.

## Tecnología
SCCM / ConfigMgr (`Get-CMDevice`, `Remove-CMDevice`).

## Notas
Pensado para ejecutarse sobre una colección que agrupa los nombres repetidos.
