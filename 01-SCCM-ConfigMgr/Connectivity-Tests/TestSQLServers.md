# TestSQLServers.ps1

Comprueba la **conectividad a una lista de servidores SQL** usando autenticación SQL (no Windows).

## Cómo funciona

- Importa el módulo `SqlServer` y lee la lista de servidores de un CSV (`;` como separador).
- Construye una credencial SQL (`SqlCredential`) y, para cada servidor, intenta abrir conexión y reporta si responde.

## Tecnología
SQL Server (`System.Data.SqlClient`, módulo `SqlServer`).

## Notas
El usuario y la contraseña SQL venían **en claro** en el script; aquí aparecen como `sqladmin` / `REDACTED_PASSWORD`. En producción deberían venir de un almacén seguro.
