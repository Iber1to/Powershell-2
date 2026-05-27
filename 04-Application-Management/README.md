# 04-Application-Management

Ciclo de vida de aplicaciones: control de versiones de navegadores, desinstalación de software y empaquetado (winget).

## Scripts de esta categoría

| Script | Qué hace | Tecnología principal |
|---|---|---|
| `App-Removal/Detect-Folder Worlship.ps1` | Script de **detección** que comprueba la presencia de una carpeta/aplicación concreta (UPS WorldShip, según el nombre) en el equipo. | Sistema de ficheros |
| `App-Removal/Remove-GoogleDrive.ps1` | Desinstala **cualquier versión de Google Drive** detectada en Windows y limpia sus restos. | Registro |
| `App-Removal/Remove-OneDrive_v1_1_4.ps1` | Script controlador robusto (v1.1.4, ~1.300 líneas) para **retirar OneDrive** de un equipo gestionado y limpiar todos sus restos, tanto a nivel de máquina como por cada pe | Registro |
| `App-Removal/Remove-OracleClient11G.ps1` | Desinstala **Oracle Client 11G** y limpia los restos locales de la instalación. | Desinstalador nativo de Oracle |
| `App-Removal/Remove-WPSOffice.ps1` | Retira **WPS Office** (Kingsoft) y sus evidencias residuales de endpoints gestionados. | ARP/UninstallString |
| `App-Removal/Uninstall-DockerDesktop.ps1` | Desinstala **Docker Desktop** y verifica que efectivamente ha desaparecido. | Registro de Windows (claves de desinstal |
| `Browsers/Aviso-Edge.ps1` | Muestra al usuario un **aviso gráfico** (Windows Forms) informando de la deshabilitación de Internet Explorer / cambio a Edge en una fecha dada. | WinForms (GUI) |
| `Browsers/ChromeUninstallMinimunVersion.ps1` | Comprobación de cumplimiento que marca como **no conforme (y candidato a desinstalar) a Google Chrome por debajo de una versión mínima**. | Registro / detección de versión |
| `Browsers/Delete-ChromeOldVersions.ps1` | Variante de la comprobación de Chrome orientada a **limpiar versiones antiguas** (el umbral por defecto está a 0 para forzar la evaluación de todo). | Registro / detección de versión |
| `Browsers/FirefoxUninstallMinimunVersion.ps1` | Equivalente a `ChromeUninstallMinimunVersion.ps1` para **Mozilla Firefox**: detecta versiones por debajo del mínimo permitido. | Detección de versión |
| `Browsers/chrome_Uninstall.ps1` | Localiza la **cadena de desinstalación de Chrome** recorriendo las claves de desinstalación del registro para poder retirarlo. | Registro de Windows (claves de desinstal |
| `Packaging/add-winget-package-pipeline.ps1` | **Script de terceros** (Andrew Taylor, v1.3, GPL) que **crea una aplicación en Intune a partir de un manifiesto de Winget**. | Winget |

