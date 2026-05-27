# 05-ActiveDirectory-and-Identity

Identidades en Active Directory y Entra ID: consultas, exportaciones, permisos de aplicaciones, admin local y migraciones de directorio.

## Scripts de esta categoría

| Script | Qué hace | Tecnología principal |
|---|---|---|
| `AzureGroups.ps1` | Vía **Microsoft Graph**, anida automáticamente todos los grupos de un país dentro del grupo "paraguas" de su región. | Microsoft Graph (`Connect-MgGraph` |
| `Check_ADUsers.ps1` | Parte de un proyecto de **migración de Active Directory**: contiene la función `CrearUsuario`, que da de alta en el dominio destino los usuarios a partir de un mapeo orig | Active Directory (`ActiveDirectory` modu |
| `Export_GroupsMembersAD.ps1` | Exporta a CSV **todos los grupos de un dominio y sus miembros**. | Active Directory |
| `Export_GroupsMembersADLimitOU.ps1` | Variante de `Export_GroupsMembersAD.ps1` que calcula la **pertenencia a grupos de forma recursiva** y **limitada a una OU**. | Active Directory |
| `Irivalocaladmins.ps1` | Misma herramienta que `Set-IntuneUserAdminLocal.ps1` (admin local sobre los dispositivos de los que un usuario es propietario en Intune), aquí instanciada para el tenant  | Microsoft Graph |
| `Obtencion-APPs-Existe-INT-v2.ps1` | Script de **descubrimiento para una migración de AD/Exchange**: comprueba qué cuentas/aplicaciones del dominio origen **ya existen** en el dominio destino ("INT"). | Active Directory (consultas multi-domini |
| `Obtencion-Buzones-Existe-INT-v2.ps1` | Script de **descubrimiento para una migración de AD/Exchange**: comprueba qué buzones del dominio origen **ya existen** en el dominio destino ("INT"). | Active Directory (consultas multi-domini |
| `Obtencion-ListasDistribucion-Existe-INT-v2.ps1` | Script de **descubrimiento para una migración de AD/Exchange**: comprueba qué listas de distribución del dominio origen **ya existen** en el dominio destino ("INT"). | Active Directory (consultas multi-domini |
| `Obtencion-Usuarios-Existe-INT-v3.ps1` | Versión 3 del script de descubrimiento de la migración: comprueba qué **usuarios** del dominio origen ya existen en el dominio destino ("INT"). | Active Directory (multi-dominio) |
| `ProcesadoUsuariosyGrupos-v4.ps1` | Núcleo del **procesado de usuarios y grupos** de la migración de directorio: cruza usuarios y su pertenencia a grupos entre el dominio origen y el destino ("INT"). | Active Directory (multi-dominio) |
| `Set-PermisosAzureApp.ps1` | Configura el acceso de un **proveedor externo a un único site de SharePoint Online** usando el permiso de Graph `Sites.Selected` (en lugar de los permisos amplios `Sites. | Microsoft Graph (`Sites.Selected`) |
| `get-adcomputer brasil.ps1` | Localiza los **equipos inactivos (más de 90 días sin logon) en las OUs de Brasil** del dominio LATAM2. | Active Directory |

