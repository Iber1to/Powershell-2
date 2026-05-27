# uninstall_client.ps1

Desinstala el **cliente de ConfigMgr** y limpia sus rastros (variante/duplicado de `SCCMuninstall_client.ps1`).

## Cómo funciona
Ejecuta `ccmsetup.exe /uninstall`, borra `smscfg.ini`, los certificados SMS y los namespaces WMI del cliente.

## Tecnología
ccmsetup · certificados · WMI.

## Notas
Es el mismo procedimiento que `01-SCCM-ConfigMgr/Client-Health/SCCMuninstall_client.ps1`.
