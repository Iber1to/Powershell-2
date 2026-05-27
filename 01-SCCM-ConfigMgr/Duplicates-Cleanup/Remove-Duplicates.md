# Remove-Duplicates.ps1

Elimina de SCCM los **registros de equipos cuya instalación de cliente falló** y que, por tanto, suelen quedar como duplicados "fantasma".

## Cómo funciona

- Lanza una consulta SQL directa contra la base de datos del sitio que, partiendo del nombre de una colección, localiza su tabla de resultados y selecciona los equipos con `ClientVersion IS NULL` y `CP_LastInstallationError = 120`.
- Para cada uno, recupera el dispositivo por `ResourceId` y lo borra con `Remove-CMDevice -Force`.

## Tecnología
SQL Server (`Invoke-Sqlcmd` sobre la BD de ConfigMgr) · cmdlets de ConfigMgr.

## Notas
Servidor SQL, base de datos y site code anonimizados. `removeDuplicatesSCCM.ps1` es prácticamente idéntico.
