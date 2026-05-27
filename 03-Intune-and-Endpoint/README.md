# 03-Intune-and-Endpoint

Gestión de dispositivos con Microsoft Intune: plantillas de despliegue de apps (PSADT), scripts de detección/remediación y administración de dispositivos.

## Scripts de esta categoría

| Script | Qué hace | Tecnología principal |
|---|---|---|
| `App-Deployment-Templates/001 Deploy-Exe copy.ps1` | Copia de trabajo de `001 Deploy-Exe.ps1` (plantilla de despliegue PSADT). Se conserva tal cual estaba en el backup. |  |
| `App-Deployment-Templates/001 Deploy-Exe.ps1` | Plantilla de despliegue de aplicaciones `.exe` **basada en PSADT** (incluye/!carga el motor del PowerShell App Deployment Toolkit), numerada como parte de un kit de ejemp |  |
| `App-Deployment-Templates/002 Uninstall-Exe.ps1` | Plantilla de **desinstalación** de aplicaciones `.exe` basada en PSADT, complementaria de `001 Deploy-Exe.ps1`. |  |
| `App-Deployment-Templates/003 Deploy-SoapUI.ps1` | Script de despliegue **basado en PSADT** que instala/desinstala **SoapUI**. | PSADT (PowerShell App Deployment Toolkit |
| `App-Deployment-Templates/004 AppDeployToolkitMain.ps1` | **Motor del PowerShell App Deployment Toolkit (PSADT)** — software de terceros (Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian), bajo licencia LGPL. |  |
| `App-Deployment-Templates/Deploy-Exe.ps1` | Plantilla **ligera y propia** para empaquetar la instalación de una aplicación basada en `.exe` y desplegarla con Intune (o cualquier ESM). | PowerShell |
| `App-Deployment-Templates/Deploy-MSI.ps1` | Plantilla propia para **instalar paquetes MSI** de forma desatendida desde Intune, con el mismo esqueleto de logging y comprobación de privilegios que `Deploy-Exe.ps1`. |  |
| `App-Deployment-Templates/Uninstall-Exe.ps1` | Plantilla propia para **desinstalar** aplicaciones basadas en `.exe` desde Intune. |  |
| `App-Deployment-Templates/Uninstall-MSI.ps1` | Plantilla propia para **desinstalar paquetes MSI** vía `msiexec /x` desde Intune, con el mismo patrón de logging y comprobación de privilegios del resto de plantillas. |  |
| `Detection-and-Remediation/Set-HostanameDetectionCPMS.ps1` | Script de **detección** (proactive remediation de Intune) que comprueba si el fichero `hosts` del equipo tiene la entrada necesaria para resolver la aplicación **CPMS** h | Fichero `hosts` de Windows |
| `Detection-and-Remediation/Set-HostanameDetectionFiori.ps1` | Script de **detección** (proactive remediation de Intune) que comprueba si el fichero `hosts` del equipo tiene la entrada necesaria para resolver la aplicación **Fiori**  | Fichero `hosts` de Windows |
| `Detection-and-Remediation/Set-HostanameDetectionJira.ps1` | Script de **detección** (proactive remediation de Intune) que comprueba si el fichero `hosts` del equipo tiene la entrada necesaria para resolver la aplicación **Jira** h | Fichero `hosts` de Windows |
| `Detection-and-Remediation/Set-HostnameRemediationCPMS.ps1` | **Remediación** que escribe en el fichero `hosts` la entrada necesaria para resolver la aplicación **CPMS** hacia la IP indicada, cuando la detección ha encontrado que fa | Fichero `hosts` de Windows |
| `Detection-and-Remediation/Set-HostnameRemediationFiori.ps1` | **Remediación** que escribe en el fichero `hosts` la entrada necesaria para resolver la aplicación **Fiori** hacia la IP indicada, cuando la detección ha encontrado que f | Fichero `hosts` de Windows |
| `Detection-and-Remediation/Set-HostnameRemediationJira.ps1` | **Remediación** que escribe en el fichero `hosts` la entrada necesaria para resolver la aplicación **Jira** hacia la IP indicada, cuando la detección ha encontrado que fa | Fichero `hosts` de Windows |
| `Detection-and-Remediation/Uninstall-TeamsHomeDetection.ps1` | Detección que comprueba si está instalada la versión de consumo **"Teams Home"** (el paquete AppX `MicrosoftTeams` que Windows preinstala), de cara a retirarla en equipos | Paquetes AppX/MSIX (`Get-AppPackage`) |
| `Detection-and-Remediation/Uninstall-TeamsHomeRemediation.ps1` | **Remediación** que elimina el paquete de consumo "Teams Home" (`MicrosoftTeams` AppX) de los equipos donde la detección lo ha encontrado. | Paquetes AppX/MSIX |
| `Device-Management/Add-ScheduledTask.ps1` | Importa una **tarea programada definida en XML** que ejecuta, al iniciar sesión el usuario, el script del "Mensaje de Seguridad de la Información (SGSI)". | Programador de tareas de Windows (XML de |
| `Device-Management/AutopilotRegisterDevices.ps1` | Script de **3 líneas** para registrar un equipo en **Windows Autopilot** y apagarlo, pensado para ejecutarse durante la preparación del dispositivo. | Windows Autopilot |
| `Device-Management/ConectWifiAutoConnect.ps1` | Garantiza que un equipo se **conecte automáticamente a la red Wi-Fi corporativa** si su perfil ya existe. | `netsh wlan` |
| `Device-Management/Create-ScheduledTask-FileInventory.ps1` | Crea la **tarea programada** que ejecuta periódicamente el inventario de ficheros y lo sube a Azure Storage. | Programador de tareas |
| `Device-Management/Get-WindowsVersionIntune.ps1` | Función `get-WindowsVersion` que traduce el **build del sistema operativo a un nombre de versión legible** (21H2, 22H2, etc.), pensada para usarse en scripts de Intune. | Registro/WMI (build del SO) |
| `Device-Management/Set-IntuneUserAdminLocal.ps1` | Otorga **permisos de administrador local** a un usuario sobre **los dispositivos de los que es propietario en Intune**, de forma automatizada vía Microsoft Graph. | Microsoft Graph |
| `Device-Management/check-IntuneAcces.ps1` | Comprueba la **conectividad de red hacia los endpoints necesarios para Intune/MDM** desde un equipo. | Pruebas de puertos TCP (`System.Net.Sock |
| `Device-Management/oneDriveLimitRatePolicy.ps1` | Aplica, **en el contexto del usuario que ha iniciado sesión**, una política de registro para **limitar la velocidad de subida de OneDrive**. | Registro de Windows (HKU del usuario) |
| `Device-Management/setKioskMode_rev5.ps1` | Configura un equipo en **modo kiosko**. Está basado en *MultiKiosk* de Jörgen Nilsson, adaptado para el entorno. | Registro de Windows |
| `Device-Management/test_tareas_programadas.ps1` | Script de **pruebas** alrededor de la creación/registro de tareas programadas, usado para validar el enfoque antes de integrarlo en los scripts definitivos de inventario. | Programador de tareas de Windows |

