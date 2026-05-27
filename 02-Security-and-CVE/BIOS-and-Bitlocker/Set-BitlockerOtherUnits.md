# Set-BitlockerOtherUnits.ps1

Activa **BitLocker en las unidades fijas secundarias** (típicamente `D:`) de un equipo que ya tiene cifrado el sistema, y se encarga de poner a salvo las claves de recuperación tanto en Active Directory como en una carpeta de red por región.

## Cómo funciona

- Monta una unidad de red `Q:` contra el recurso `Bitlocker_Keys$` del servidor que corresponde al dominio del equipo (EMEA, LATAM1 o LATAM2), usando una credencial de servicio.
- Comprueba que `C:` ya esté cifrado y, si encuentra una unidad `D:` fija sin protector, lanza `Enable-BitLocker -UsedSpaceOnly -RecoveryPasswordProtector`.
- Hace **doble respaldo** de la clave: `Backup-BitLockerKeyProtector` hacia AD y un volcado con `manage-bde -protectors -get` a un fichero con timestamp en la carpeta de red.
- Registra el nombre de la máquina en un log de despliegue por región.

## Tecnología
Módulo `BitLocker` · `manage-bde` · WMI (`Win32_ComputerSystem`) · unidades de red con `PSCredential` · escrow de claves en AD.

## Notas
La credencial de servicio y su contraseña estaban en claro en el script (aquí `REDACTED_PASSWORD`). Los servidores y dominios reales se han sustituido por `SRVxxx` y `*.contoso.local`. Para producción, la credencial debería venir de un almacén seguro y no del propio script.
