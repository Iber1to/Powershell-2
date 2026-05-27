# Aviso-Edge.ps1

Muestra al usuario un **aviso gráfico** (Windows Forms) informando de la deshabilitación de Internet Explorer / cambio a Edge en una fecha dada.

## Cómo funciona
Crea un formulario con título "IExplorer Disabled 15 June" y deja una marca (`DeleteToForceChange.txt`) bajo la carpeta de scripts de Intune para controlar cuándo se ha mostrado/forzado el cambio.

## Tecnología
WinForms (GUI) · marca en sistema de ficheros.

## Notas
Es un comunicado al usuario, no una acción técnica sobre el navegador.
