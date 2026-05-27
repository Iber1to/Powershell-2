# Get-LastLoginInfo.ps1

**Función de terceros** (theSysadminChannel) que obtiene información de los **últimos inicios de sesión** de una o varias máquinas.

## Cómo funciona

Acepta `-ComputerName` y `-SamAccountName` y consulta los eventos de logon de seguridad de Windows para devolver quién y cuándo inició sesión.

## Tecnología
Registro de eventos de Windows (auditoría de logon).

## Notas
Código externo reutilizable; se mantiene la atribución y el enlace original en la cabecera.
