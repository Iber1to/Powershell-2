# RepairDeviceWSUSConfig.ps1

Repara la configuración de **Windows Update / WSUS** de un cliente cuando ha quedado "pegada" por políticas o registro corrupto.

## Cómo funciona

1. Borra del registro las entradas `WUServer` y `WUStatusServer` bajo `...\WindowsUpdate`.
2. Elimina las carpetas de política local de máquina y de usuario (`System32\GroupPolicy\Machine` y `\User`).
3. Lanza `gpupdate /force` para reaplicar GPOs limpias.
4. Reinicia el servicio `CCMExec` (el agente de ConfigMgr).

## Tecnología
Registro de Windows · GPO local · servicio CCMExec.

## Notas
Operación de saneamiento típica cuando un equipo apunta a un WSUS incorrecto o no escanea actualizaciones.
