# Colección de scripts (anonimizada y documentada)

Reorganización, anonimización y documentación de una colección histórica de scripts de administración de sistemas (PowerShell y Python), pensada para poder revisarse o compartirse sin exponer datos corporativos, credenciales ni información de clientes.

Cada carpeta de primer nivel es una categoría funcional con su propio `README.md` índice, y **junto a cada script hay un `.md` con su documentación técnica** (qué hace, cómo funciona, tecnología, parámetros y notas de anonimización).

## Categorías

| # | Categoría | Descripción |
|---|---|---|
| 01 | [`01-SCCM-ConfigMgr`](./01-SCCM-ConfigMgr/) | Automatización y mantenimiento de Microsoft Endpoint Configuration Manager (SCCM/ConfigMgr): boundaries, colecciones, salud de cliente, distribución de contenido, limpieza de duplicados, pruebas de conectividad y actualizaciones. |
| 02 | [`02-Security-and-CVE`](./02-Security-and-CVE/) | Detección/remediación de vulnerabilidades (PrintNightmare, Follina, HiveNightmare) y hardening de endpoints (contraseña de BIOS y BitLocker). |
| 03 | [`03-Intune-and-Endpoint`](./03-Intune-and-Endpoint/) | Gestión de dispositivos con Microsoft Intune: plantillas de despliegue de apps (PSADT), scripts de detección/remediación y administración de dispositivos. |
| 04 | [`04-Application-Management`](./04-Application-Management/) | Ciclo de vida de aplicaciones: control de versiones de navegadores, desinstalación de software y empaquetado (winget). |
| 05 | [`05-ActiveDirectory-and-Identity`](./05-ActiveDirectory-and-Identity/) | Identidades en Active Directory y Entra ID: consultas, exportaciones, permisos de aplicaciones, admin local y migraciones de directorio. |
| 06 | [`06-Azure-Inventory`](./06-Azure-Inventory/) | Inventario personalizado de dispositivos hacia Azure Storage / Log Analytics mediante SAS y tareas programadas. |
| 07 | [`07-Notifications-and-Email`](./07-Notifications-and-Email/) | Notificaciones por correo (SMTP y Microsoft Graph/OAuth2), incluyendo recordatorios de caducidad de contraseña. |
| 08 | [`08-Networking-and-PortTesting`](./08-Networking-and-PortTesting/) | Pruebas de conectividad y de puertos (PortQry) con interfaz gráfica e informes. |
| 09 | [`09-Python`](./09-Python/) | Utilidades en Python: Microsoft Graph (MSAL), registro de dispositivos en Google Cloud, calendarios ICS, GPOs y ejemplos. |
| 10 | [`10-Templates-and-Examples`](./10-Templates-and-Examples/) | Módulo de funciones propio, plantillas de cabecera y ejemplos de referencia (WinForms, XML). |
| 11 | [`11-Misc-and-Snippets`](./11-Misc-and-Snippets/) | Snippets, pruebas y scripts varios sin categoría fija. |

## Anonimización aplicada

Todo el contenido textual ha pasado por un proceso de anonimización:

| Dato original | Reemplazo |
|---|---|
| Dominio corporativo real (`*.empresa.*`) | `contoso.com` / `contoso.local` |
| Servidores internos (FQDN/hostnames) | `SRVxxx`, `DCSRV01` |
| IPs privadas (10/172/192.168) | Rangos de documentación `192.0.2.x` / `198.51.100.x` |
| GUIDs de tenant / app / objeto | `11111111-1111-1111-1111-…` |
| Client secrets · SAS · claves privadas · contraseñas | `REDACTED_*` |
| Direcciones de correo | `user@contoso.com` / `automation@contoso.com` |
| Nombres de cliente reales | Alias por sector (`ClientBank`, `ClientInsurance`, `ClientRetail`, `ClientUtility`, `ClientStone`, `ClientCourier`, `ClientAero`, `ClientFuneral`, `ClientMSP`, `ClientInsuranceMT`) |
| Proveedores / operadores | `VendorIT`, `VendorMSP`, `CarrierTelco` |

> Los alias de cliente y servidor son ficticios y no mantienen un mapa público hacia los valores reales.

> Parte del código es de terceros (PSADT, ConfigMgr Client Health de Anders Rødland, ConfigMgr Client TCP Port Tester de Trevor Jones, recordatorio de contraseñas de Robert Pearman, pipeline de winget de Andrew Taylor, etc.); en esos casos se conserva la atribución original en la cabecera del propio script.

