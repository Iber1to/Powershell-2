# CompleteScriptWithGUI.ps1

Herramienta con **interfaz gráfica que envuelve PortQry** para comprobar conectividad de puertos de forma cómoda. Se desarrolló originalmente como entregable para un cliente (anonimizado).

## Cómo funciona
Sobre la utilidad `PortQry.exe` (incluida en la carpeta), ofrece un formulario para lanzar comprobaciones de puertos contra los destinos definidos en sus ficheros XML de dominios. La cabecera documenta su evolución mediante modificaciones numeradas (`MOD001`, `MOD002`, …): por ejemplo, fijar la ruta del ejecutable de PortQry y añadir un botón para testear el controlador de dominio del equipo actual.

## Tecnología
PortQry · WinForms (GUI) · configuración por XML.

## Notas
Marca y dominios del cliente anonimizados; el logo de marca original no se incluye. Acompaña a `PortQry.exe`, el `.cpp` `RemoveDeviceSCCM` y las plantillas HTML/XML de esta carpeta.
