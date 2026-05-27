# detection-BiosPassword.ps1

Script de **detección** pensado para una "proactive remediation" de Intune. Comprueba si un equipo HP tiene establecida la contraseña de Setup de la BIOS y deja el equipo "en verde" sólo cuando esa contraseña ya está puesta.

## Cómo funciona

Consulta `Win32_ComputerSystem` para identificar el fabricante y, en máquinas HP, lee el espacio de nombres WMI propietario `root\hp\InstrumentedBIOS` (clases `HP_BIOSSetting` / `HP_BIOSSettingInterface`) para ver el flag `IsSet` del ajuste *Setup Password*. La lógica de salida es la habitual de Intune:

- Fabricante distinto de HP → `Exit 1` ("Manufacturer not supported"), no aplica.
- HP sin contraseña → `Exit 1` ("No password active"): se considera no conforme y dispara la remediación.
- HP con contraseña → `Exit 0` ("Password Enable"): conforme.

Se empareja con `Set-BiosPassword.ps1`, que es el script de remediación.

## Tecnología
WMI/CIM · WMI propietario de HP (`root\hp\InstrumentedBIOS`) · modelo de detección/remediación de Intune.

## Notas
Sólo cubre hardware HP; en otros fabricantes simplemente se marca como no soportado para no forzar remediaciones imposibles.
