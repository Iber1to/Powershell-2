# Get-UserLogon.ps1

Función para averiguar **qué usuario está/estuvo conectado** en un equipo o en todos los equipos de una OU.

## Cómo funciona

Acepta `-Computer`, `-OU` o `-All` y consulta las sesiones de los equipos (típicamente vía `quser`/WMI), devolviendo el usuario y el estado de sesión por máquina. Acumula resultados en una colección.

## Tecnología
Consulta de sesiones de Windows · Active Directory (para resolver equipos de una OU).

## Notas
Útil para localizar quién usa un equipo concreto o hacer un barrido por OU.
