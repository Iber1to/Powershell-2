# ConfigMgr Client TCP Port Tester.ps1

**Herramienta gráfica de terceros** (Trevor Jones, *smsagent.blog*). Es una utilidad con interfaz WPF para comprobar de forma visual la **conectividad TCP de un cliente de ConfigMgr** contra su Management Point, Distribution Point y Software Update Point.

## Cómo funciona

- Arranca desde su propia carpeta (`$PSScriptRoot`) y carga su configuración por defecto (puertos y servidores) desde XML.
- Levanta una interfaz (apoyada en las librerías `ClassLibrary.ps1`, `EventLibrary.ps1` y `FunctionLibrary.ps1` y en los ensamblados MahApps de la carpeta `bin`) donde el técnico introduce los servidores y lanza los tests de puertos.

## Tecnología
WPF (MahApps.Metro) · `Test-NetConnection` · ConfigMgr.

## Notas
Software de un tercero; se conserva su estructura (XAML, `bin`, librerías) y la atribución del autor. En el backup venía duplicado, de ahí el `_2`.
