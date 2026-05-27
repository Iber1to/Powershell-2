# SCCMuninstall_client.ps1

**Desinstala por completo el cliente de ConfigMgr** y limpia los rastros que suelen impedir una reinstalación limpia.

## Cómo funciona

1. Ejecuta `ccmsetup.exe /uninstall`.
2. Borra `smscfg.ini` (que guarda el GUID de cliente y de certificado con el que estaba registrado).
3. Elimina los certificados SMS del almacén del equipo.
4. Borra los namespaces WMI del cliente (`CCM`, `CCMVDI`, `SmsDm` en `root`, y `sms` en `root\cimv2`). Incluye comentadas las equivalencias con `Get-WmiObject`/`Remove-WmiObject` por si `CimInstance` falla.

## Tecnología
ccmsetup · certificados · WMI/CIM.

## Notas
Es la base de las variantes regionales (`_APAC`, `_EMEA`, `_Latam1`), que añaden particularidades de cada dominio.
