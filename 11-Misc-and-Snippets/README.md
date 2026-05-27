# 11-Misc-and-Snippets

Snippets, pruebas y scripts varios sin categoría fija.

## Scripts de esta categoría

| Script | Qué hace | Tecnología principal |
|---|---|---|
| `ClientInsurance_V1.3.2.ps1` | Recopila **todos los datos necesarios para una auditoría de infraestructura de ConfigMgr** y los consolida (originalmente una auditoría hecha para un cliente del sector s | SCCM / ConfigMgr |
| `CopiaConfigMgrClienteHealthasusitio.ps1` | Utilidad de despliegue que **distribuye el script ConfigMgr Client Health a su ubicación/sitio** correspondiente. | SCCM / ConfigMgr |
| `DeviceQuery-Snippet.ps1` | Snippet que **recoge la configuración de proxy WinHTTP de un equipo** y la deja en un recurso de red con el nombre del host. | `netsh winhttp` |
| `Get-AclDirectory.ps1` | Audita los **permisos NTFS (ACL) de un conjunto de directorios** indicados en un CSV, hasta una profundidad de subcarpetas configurable. | ACL / permisos NTFS (`Get-Acl`) |
| `MensajeTaskSequence.ps1` | Muestra al usuario un **cuadro de diálogo** durante una task sequence preguntando si desea instalar ahora o posponer. | `WScript.Shell` (COM) |
| `PsexecRemoteConsole.ps1` | Permite **abrir una consola o ejecutar un script en un equipo remoto** apoyándose en PsExec. | PsExec (Sysinternals) |
| `Send-Mail-OAuth-Variant.ps1` | Otra variante del **recordatorio de caducidad de contraseña** de Robert Pearman (v2.9), con envío por OAuth2/Graph. | Active Directory |
| `TestComunicaciones-Variant-Descartes.ps1` | A pesar del nombre heredado, el contenido es un snippet de **detección/remediación de la contraseña de BIOS en equipos HP** (sección "Detection"). | WMI propietario de HP (`root\hp\Instrume |
| `Untitled-Snippet.ps1` | Fragmento suelto con la función `UltimaFecha` (devuelve la fecha más reciente de un conjunto) y la lógica de localizar el último parche, reutilizada en los scripts de cum | PowerShell (funciones auxiliares de fech |
| `check-WindowsFeatures.ps1` | Detección que comprueba el **estado de una característica opcional de Windows** (en este caso *Print to PDF*). | `Get-WindowsOptionalFeature` (DISM) |
| `crucedatos.ps1` | Cruza el **inventario de dispositivos de Intune contra unas listas de exclusión** para construir el conjunto final de equipos a remediar (trabajo hecho para un cliente, a | `System.Collections.ArrayList` |
| `pruebas_Servers_parcheo.ps1` | Versión de **pruebas** del informe de cumplimiento de parcheo de servidores (baseline 'Informe parcheo Servidores'). | SCCM / ConfigMgr |
| `remoteconsole.ps1` | Variante de `PsexecRemoteConsole.ps1`: abre una consola o ejecuta un script en un equipo remoto vía PsExec, generando una contraseña temporal. |  |
| `rename-BoundayGroups.ps1` | Renombra en bloque **boundaries** mediante búsqueda y reemplazo de una cadena en su nombre (mismo enfoque que `Set-NombreBoundary.ps1`). | SCCM / ConfigMgr (`Get-CMBoundary` / `Se |
| `temp-snippet-1.ps1` | Copia de trabajo de gran tamaño (~800 líneas) guardada como temporal. Por el contenido (cabecera de copyright/licencia) parece un volcado de un toolkit de despliegue. |  |
| `temp-snippet-2.ps1` | Snippet temporal con una **interfaz WinForms** y una función `Get-ComputerNameFromUser` (resolver el equipo a partir del usuario). | WinForms (GUI) |
| `temp-snippet-3.ps1` | Snippet que registra una **tarea programada para respaldar la clave de BitLocker en Azure AD** (`BackupKeyToAAD`). | Programador de tareas |
| `temp-snippet.ps1` | Snippet de **bootstrap**: copia el script `reparalibreriadp.ps1` desde un recurso de red a la carpeta local de scripts y verifica que ha quedado. | Copia de ficheros |
| `test-host-snippet.ps1` | Comprueba, para una lista de IPs, si están en el **fichero `hosts`** y revisa la **configuración de proxy** (detección de proxy Bluecoat). | Fichero `hosts` |
| `test-snippet-002.ps1` | Fichero **vacío** en el backup original (0 líneas). |  |
| `test-snippet-002b.ps1` | Compara los miembros de un **grupo de AD de administradores locales** (escenario LAPS) con los del **grupo local de Administradores** del equipo. | Active Directory |
| `testSignScripts.ps1` | Prueba de **firma de scripts** y subida a SharePoint. | Firma de código (Authenticode) |
| `uninstall_client.ps1` | Desinstala el **cliente de ConfigMgr** y limpia sus rastros (variante/duplicado de `SCCMuninstall_client.ps1`). | ccmsetup |
| `webrequest.ps1` | Automatiza con **Selenium** el inicio de sesión en un portal web (un servicio SaaS de fichaje horario). | Selenium WebDriver (Chrome) |

