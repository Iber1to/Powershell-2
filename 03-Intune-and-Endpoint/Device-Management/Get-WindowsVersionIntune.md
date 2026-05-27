# Get-WindowsVersionIntune.ps1

Función `get-WindowsVersion` que traduce el **build del sistema operativo a un nombre de versión legible** (21H2, 22H2, etc.), pensada para usarse en scripts de Intune.

## Cómo funciona
Acepta `-ComputerName` (por defecto el equipo local), lee el build del SO y lo mapea contra una tabla a la versión comercial de Windows 10/11.

## Tecnología
Registro/WMI (build del SO).

## Notas
Es la misma utilidad de versión que reutilizan otros scripts de detección de parcheo del repositorio.
