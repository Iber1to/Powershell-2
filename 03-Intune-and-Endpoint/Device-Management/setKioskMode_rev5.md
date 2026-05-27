# setKioskMode_rev5.ps1

Configura un equipo en **modo kiosko**. Está basado en *MultiKiosk* de Jörgen Nilsson, adaptado para el entorno.

## Cómo funciona
Crea una marca en el registro (`HKLM:\SOFTWARE\CCMEXECOSD`) para versionar la configuración y aplica los ajustes de kiosko (cuenta de kiosko, aplicación/shell permitida, restricciones). La cuenta y contraseña de kiosko se definen como variables.

## Tecnología
Registro de Windows · configuración de kiosko (shell launcher / cuenta dedicada).

## Notas
Código adaptado de un autor de la comunidad (Jörgen Nilsson). La contraseña de la cuenta de kiosko venía en claro y se ha redactado (`REDACTED_PASSWORD`).
