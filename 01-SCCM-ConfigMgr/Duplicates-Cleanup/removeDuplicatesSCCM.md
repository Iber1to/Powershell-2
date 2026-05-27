# removeDuplicatesSCCM.ps1

Casi idéntico a `Remove-Duplicates.ps1`: vía SQL localiza los equipos con instalación de cliente fallida (`ClientVersion` nulo y error 120) en una colección y los elimina de SCCM con `Remove-CMDevice`.

## Notas
Ver `Remove-Duplicates.ps1` para el detalle; son dos copias del mismo procedimiento.
