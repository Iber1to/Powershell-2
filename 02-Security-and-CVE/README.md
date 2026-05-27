# 02-Security-and-CVE

Detección/remediación de vulnerabilidades (PrintNightmare, Follina, HiveNightmare) y hardening de endpoints (contraseña de BIOS y BitLocker).

## Scripts de esta categoría

| Script | Qué hace | Tecnología principal |
|---|---|---|
| `BIOS-and-Bitlocker/Clear-BitlockerKeys.ps1` | Herramienta **interactiva** (con cuadros de diálogo de Windows Forms) para limpiar/gestionar claves de BitLocker, pensada para ejecutarse a mano por un técnico y no de fo | WinForms (GUI) |
| `BIOS-and-Bitlocker/Set-BiosPassword.ps1` | Remediación que **establece la contraseña de Setup de la BIOS en equipos HP** y, de paso, obliga a pedirla en los menús de arranque (F9, F11, F12). Es la pareja de `detec | WMI propietario de HP |
| `BIOS-and-Bitlocker/Set-BitlockerOtherUnits.ps1` | Activa **BitLocker en las unidades fijas secundarias** (típicamente `D:`) de un equipo que ya tiene cifrado el sistema, y se encarga de poner a salvo las claves de recupe | Módulo `BitLocker` |
| `BIOS-and-Bitlocker/detection-BiosPassword.ps1` | Script de **detección** pensado para una "proactive remediation" de Intune. Comprueba si un equipo HP tiene establecida la contraseña de Setup de la BIOS y deja el equipo | WMI/CIM |
| `Follina-CVE-2022-30190/detection-follina.ps1` | Detección de la mitigación de **Follina (CVE-2022-30190)**, la vulnerabilidad del manejador de protocolo `ms-msdt` de MSDT explotable desde documentos de Office. | Registro de Windows (`HKCR`) |
| `Follina-CVE-2022-30190/remedy-follina.ps1` | Remediación de **Follina (CVE-2022-30190)**: hace una copia de seguridad de la clave de registro vulnerable y la elimina. | `reg export` / `reg delete` |
| `HiveNightmare-CVE-2021-36934/HiveNightmare.ps1` | **Prueba de concepto de terceros** (autor original *@WiredPulse*, basada en el hallazgo de *@jonasLyk*) para **HiveNightmare / SeriousSAM (CVE-2021-36934)**. Demuestra qu | Volume Shadow Copy (VSS) |
| `PrintNightmare-CVE-2021-34527/Baselline_Spooler.ps1` | Regla de **baseline de cumplimiento** (Configuration Item de SCCM) para mitigar **PrintNightmare (CVE-2021-34527)**: decide si el servicio Spooler debe estar activo o apa | API COM de Windows Update (`Microsoft.Up |
| `PrintNightmare-CVE-2021-34527/CVE-2021-34527_Cumplimiento.ps1` | Genera un **informe de cumplimiento por correo** del despliegue de la mitigación de PrintNightmare, descontando además los equipos con exclusión autorizada. | SCCM / ConfigMgr (`Get-CMPackageDeployme |
| `PrintNightmare-CVE-2021-34527/CargaExclusioneSpoolerEmea.ps1` | Sincroniza las **exclusiones** de la política de deshabilitar el Spooler en EMEA: lee un grupo de seguridad de AD y carga sus miembros en una colección de SCCM, donde una | Active Directory (grupo de seguridad) |
| `PrintNightmare-CVE-2021-34527/Disable_SpoolerService.ps1` | Variante evolucionada de `Baselline_Spooler.ps1` para **PrintNightmare**. Misma mecánica —decidir el estado del Spooler según el último parche— pero con la ventana de fec | API COM de Windows Update |
| `PrintNightmare-CVE-2021-34527/Spooler_Disable.ps1` | Script de **reporting**: recopila el resultado de la baseline `bl_Spooler_Disable` desde el servidor de SCCM y genera un CSV que después alimenta a Power BI. | SCCM / ConfigMgr (WMI `SMS_G_System_DCMD |

