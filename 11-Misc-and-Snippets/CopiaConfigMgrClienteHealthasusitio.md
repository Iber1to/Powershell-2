# CopiaConfigMgrClienteHealthasusitio.ps1

Utilidad de despliegue que **distribuye el script ConfigMgr Client Health a su ubicación/sitio** correspondiente.

## Cómo funciona
Carga `AAGFunctions.ps1`, registra el progreso en log y copia `ConfigMgrClientHealth.ps1` desde el origen al destino esperado para que cada sitio disponga de la versión vigente de la herramienta de salud.

## Tecnología
SCCM / ConfigMgr · copia de ficheros · logging.

## Notas
Acompaña a la herramienta de terceros `ConfigMgrClientHealth.ps1` (carpeta Client-Health).
