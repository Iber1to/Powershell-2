# get-adcomputer brasil.ps1

Localiza los **equipos inactivos (más de 90 días sin logon) en las OUs de Brasil** del dominio LATAM2.

## Cómo funciona
Define las OUs de workstations de Brasil y, para cada una, consulta `Get-ADComputer` filtrando por `lastLogonTimestamp` anterior a hace 90 días, acumulando los equipos candidatos a depuración.

## Tecnología
Active Directory.

## Notas
Dominio y OUs anonimizados (`latam2.contoso.local`). Útil como base para limpieza de cuentas de equipo obsoletas.
