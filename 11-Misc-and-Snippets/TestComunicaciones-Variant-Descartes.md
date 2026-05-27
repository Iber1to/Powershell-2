# TestComunicaciones-Variant-Descartes.ps1

A pesar del nombre heredado, el contenido es un snippet de **detección/remediación de la contraseña de BIOS en equipos HP** (sección "Detection").

## Cómo funciona
Consulta WMI de HP (`HP_BIOSSetting` / `HP_BIOSSettingInterface`) para ver si el equipo es HP y si tiene puesta la contraseña de Setup, devolviendo el estado correspondiente.

## Tecnología
WMI propietario de HP (`root\hp\InstrumentedBIOS`).

## Notas
Es un fragmento de trabajo emparentado con los scripts de BIOS de `02-Security-and-CVE/BIOS-and-Bitlocker`. El nombre de fichero es un resto de una iteración previa.
