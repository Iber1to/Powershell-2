# test_connect_SQL.ps1

Lanza una **consulta directa a la base de datos de ConfigMgr** (autenticación integrada de Windows) para detectar equipos cuyo nombre difiere entre el inventario actual y el histórico.

## Cómo funciona

Abre una conexión `trusted_connection=true` contra la base de datos del sitio y ejecuta una consulta que une `v_GS_System` con `v_HS_System` y devuelve los registros donde `Name0` no coincide (síntoma de renombrados o duplicados).

## Tecnología
SQL Server (`System.Data.SqlClient`) · vistas de ConfigMgr `v_GS_System` / `v_HS_System`.

## Notas
Servidor y base de datos anonimizados (`SRV002`, `CM_PE1`). Usa autenticación Windows, así que no lleva credenciales en el código.
