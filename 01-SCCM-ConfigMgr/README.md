# 01-SCCM-ConfigMgr

Automatización y mantenimiento de Microsoft Endpoint Configuration Manager (SCCM/ConfigMgr): boundaries, colecciones, salud de cliente, distribución de contenido, limpieza de duplicados, pruebas de conectividad y actualizaciones.

## Scripts de esta categoría

| Script | Qué hace | Tecnología principal |
|---|---|---|
| `Boundaries/BoundaryCheck.ps1` | Comprueba, para todos los equipos de una colección, si la **IP que reportan a SCCM cae dentro de alguna boundary** de tipo *IP range* o si pertenece a una subred desconoc | SCCM / ConfigMgr |
| `Boundaries/BoundaryCheck_2.ps1` | Variante de `BoundaryCheck.ps1`. Mismo objetivo —cruzar la IP reportada por cada equipo de una colección contra las boundaries de tipo *IP range* y separar los que no enc |  |
| `Boundaries/BoundaryCheck_3.ps1` | Tercera iteración de `BoundaryCheck.ps1`. Comparte la lógica de comprobar si la IP de cada equipo de una colección cae en una boundary IP range, con retoques menores fren |  |
| `Boundaries/CheckIfDeviceHaveBoundari.ps1` | Evolución de `BoundaryCheck` (v1.1): comprueba para los equipos de una colección si su IP cae en una boundary, pero ya **abarca las boundaries de todos los sites** en lug | SCCM / ConfigMgr |
| `Boundaries/Creaunacoleccionporcadaboundarygroup.ps1` | **Script de terceros** (Jonathan Lefebvre, SystemCenterDudes) que crea **una colección por cada boundary group** existente en el entorno. | SCCM / ConfigMgr (módulo ConfigurationMa |
| `Boundaries/ListBoundarygroups.ps1` | Pequeño script de auditoría que lista los **boundary groups** y señala los que parecen **mal nombrados o mal asignados**. | SCCM / ConfigMgr (`Get-CMBoundaryGroup`) |
| `Boundaries/Set-NombreBoundary.ps1` | Utilidad para **renombrar boundaries en bloque** mediante búsqueda y reemplazo de una cadena en su nombre (por ejemplo, migrar el prefijo `PA1-` a `PE1-`). | SCCM / ConfigMgr (`Get-CMBoundary` / `Se |
| `Boundaries/boundaryreport.ps1` | **Cmdlet de terceros** (`Get-BoundaryReport`, de Dani Schädler / Thomas Kurth) que recorre los dispositivos de ConfigMgr y sus boundaries de tipo *IP range* y calcula **q | SCCM / ConfigMgr |
| `Boundaries/checkip.ps1` | Comprueba si **una IP concreta cae en alguna boundary** de tipo *IP range* del entorno. Pensado para una consulta puntual, no para recorrer colecciones. | SCCM / ConfigMgr vía WMI (`SMS_ProviderL |
| `Boundaries/checkip_boundary.ps1` | Snippet que dice **a qué boundary pertenece un dispositivo concreto**, comparando su IP contra una boundary dada por nombre. | SCCM / ConfigMgr (`Get-CMResource` |
| `Boundaries/creaunacoleccionporcadaSITEboundary.ps1` | **Script de terceros** (Harry Lowton) que crea colecciones a partir de las **boundaries de sitio de Active Directory**. | SCCM / ConfigMgr |
| `Boundaries/transforma_boundaries.ps1` | Utilidad para **transformar/migrar boundaries** en el CAS (por ejemplo, normalizar nombres o convertir tipos de boundary), con un control de permisos previo. | SCCM / ConfigMgr (CAS) |
| `Client-Health/ConfigMgrClientHealth.ps1` | **Herramienta de terceros muy conocida** (ConfigMgr Client Health, de Anders Rødland). Valida y **repara automáticamente** multitud de problemas del cliente de Configurat | SCCM / ConfigMgr |
| `Client-Health/ConfigMgrClientHealth_2.ps1` | Copia duplicada de `ConfigMgrClientHealth.ps1` (la herramienta de Anders Rødland). En el backup original aparecía en dos ubicaciones distintas y se han conservado ambas. |  |
| `Client-Health/InvokeSccmActions.ps1` | Función que **dispara los ciclos de acción del cliente de ConfigMgr** de forma remota (forzar inventario, evaluación de políticas, etc.) sin tener que ir equipo por equip | SCCM / ConfigMgr (cliente) vía WMI `SMS_ |
| `Client-Health/RepairDeviceWSUSConfig.ps1` | Repara la configuración de **Windows Update / WSUS** de un cliente cuando ha quedado "pegada" por políticas o registro corrupto. | Registro de Windows |
| `Client-Health/SCCMuninstall_client.ps1` | **Desinstala por completo el cliente de ConfigMgr** y limpia los rastros que suelen impedir una reinstalación limpia. | ccmsetup |
| `Client-Health/SCCMuninstall_client_APAC.ps1` | Variante para **APAC** del script de desinstalación del cliente de ConfigMgr. Misma limpieza base (ccmsetup /uninstall, `smscfg.ini`, certificados SMS y namespaces WMI) c |  |
| `Client-Health/SCCMuninstall_client_EMEA.ps1` | Variante para **EMEA** del desinstalador del cliente de ConfigMgr, con los parámetros específicos de ese dominio sobre la misma base de limpieza (cliente, certificados y  |  |
| `Client-Health/SCCMuninstall_client_Latam1.ps1` | Variante para **LATAM1** del desinstalador del cliente de ConfigMgr. Reproduce la limpieza base adaptada a ese dominio. |  |
| `Client-Health/equipos-sincliente.ps1` | Genera y **envía por correo un informe de equipos no gestionados**: cruza el censo de Active Directory con lo que ve SCCM para destacar máquinas activas en AD que no tien | Active Directory |
| `Client-Health/reruntasksequence.ps1` | Fuerza que un equipo **vuelva a ejecutar una task sequence** que ya había corrido, borrando su historial de planificación local. | SCCM / ConfigMgr (cliente) |
| `Collections-and-Devices/Compare-LastScan-vs-LastContact.ps1` | Snippet de diagnóstico que compara, para un equipo, su **último inventario de hardware** con su **última conexión** a SCCM. | SCCM / ConfigMgr (`Get-CMDevice`) |
| `Collections-and-Devices/Fix_Unquote_OCSservice.ps1` | Corrige la vulnerabilidad **Unquoted Service Path** centrándose (desde la v1.1) en el servicio de **OCS Inventory**. | Registro de Windows |
| `Collections-and-Devices/Generar_OCS_Collection.ps1` | Carga en una **colección de SCCM** los equipos de un informe de OCS (los que están en estado `KO` o `NoData`) para poder actuar sobre ellos. | SCCM / ConfigMgr |
| `Collections-and-Devices/Get-DataDevice.ps1` | Cruza los equipos de una colección de SCCM con los **logs de ConfigMgr Client Health** depositados en un recurso de red, para saber qué equipos han ejecutado alguna vez l | SCCM / ConfigMgr |
| `Collections-and-Devices/Get-LastLoginInfo.ps1` | **Función de terceros** (theSysadminChannel) que obtiene información de los **últimos inicios de sesión** de una o varias máquinas. | Registro de eventos de Windows (auditorí |
| `Collections-and-Devices/Get-SccmDataDevice-Troubleshooting.ps1` | Versión para **diagnóstico** de `Get-SccmDataDevice.ps1`: el mismo dossier por dispositivo (BIOS, batería, SO, cifrado, etc.) pero con trazas/controles adicionales para l |  |
| `Collections-and-Devices/Get-SccmDataDevice.ps1` | Recopila un **dossier por dispositivo** combinando varias fuentes de inventario de SCCM en un único objeto, y lo exporta a CSV. | SCCM / ConfigMgr (cmdlets + clases `SMS_ |
| `Collections-and-Devices/Get-UserLogon.ps1` | Función para averiguar **qué usuario está/estuvo conectado** en un equipo o en todos los equipos de una OU. | Consulta de sesiones de Windows |
| `Collections-and-Devices/TraeDatosdeDispositivosdeunaColeccion_IP_Nombre_Usuario.ps1` | Extrae, para los equipos de una colección, una tabla con **nombre de máquina, usuario principal e IPs**. | SCCM / ConfigMgr (`Get-CMDevice` |
| `Collections-and-Devices/extraer-datos-coleccion.ps1` | Exporta los **nombres de equipo de una colección, separados por dominio**, a varios CSV. | SCCM / ConfigMgr |
| `Connectivity-Tests/ClassLibrary.ps1` | Componente del *ConfigMgr Client TCP Port Tester* (herramienta de terceros de Trevor Jones). Esta librería define las clases (p. ej. el job en segundo plano) que usa la i |  |
| `Connectivity-Tests/ClassLibrary_2.ps1` | Copia duplicada de `ClassLibrary.ps1`, componente del *ConfigMgr Client TCP Port Tester*. Ver la documentación de la versión sin sufijo. |  |
| `Connectivity-Tests/ConfigMgr Client TCP Port Tester.ps1` | **Herramienta gráfica de terceros** (Trevor Jones, *smsagent.blog*). Es una utilidad con interfaz WPF para comprobar de forma visual la **conectividad TCP de un cliente d | WPF (MahApps.Metro) |
| `Connectivity-Tests/ConfigMgr Client TCP Port Tester_2.ps1` | Copia duplicada del *ConfigMgr Client TCP Port Tester* de Trevor Jones. En el repositorio original la herramienta aparecía en dos rutas distintas y se han conservado amba |  |
| `Connectivity-Tests/EventLibrary.ps1` | Componente del *ConfigMgr Client TCP Port Tester* (herramienta de terceros de Trevor Jones). Esta librería engancha los eventos de la interfaz (botones, acciones) con las |  |
| `Connectivity-Tests/EventLibrary_2.ps1` | Copia duplicada de `EventLibrary.ps1`, componente del *ConfigMgr Client TCP Port Tester*. Ver la documentación de la versión sin sufijo. |  |
| `Connectivity-Tests/FunctionLibrary.ps1` | Componente del *ConfigMgr Client TCP Port Tester* (herramienta de terceros de Trevor Jones). Esta librería contiene las funciones de comprobación de puertos contra MP, DP |  |
| `Connectivity-Tests/FunctionLibrary_2.ps1` | Copia duplicada de `FunctionLibrary.ps1`, componente del *ConfigMgr Client TCP Port Tester*. Ver la documentación de la versión sin sufijo. |  |
| `Connectivity-Tests/Test-SCCM_Conectivty_ports.ps1` | Comprueba la **conectividad TCP necesaria para ConfigMgr** tanto desde el punto de vista de un cliente como de un servidor, sobre los puertos por defecto. | `Test-NetConnection` |
| `Connectivity-Tests/Test-Servers-SCCM.ps1` | Comprueba la **conectividad hacia los Distribution Points** del entorno en los puertos clave (135 RPC y 445 SMB) y deja el resultado en un log. | SCCM / ConfigMgr |
| `Connectivity-Tests/Test-Servers-SCCM_v0.ps1` | Versión inicial (`v0`) de `Test-Servers-SCCM.ps1`: comprueba la conectividad a los Distribution Points en los puertos de RPC/SMB. Se conserva como histórico frente a la v |  |
| `Connectivity-Tests/TestComunicacionesGlobal.ps1` | Test **integral de comunicaciones** de un cliente de ConfigMgr: comprueba en una sola pasada los puertos contra su Management Point, el WSUS/SUP, el Distribution Point y  | ConfigMgr (cliente) |
| `Connectivity-Tests/TestComunicacionesGlobal_Descartes.ps1` | Recorte/variante reducida de `TestComunicacionesGlobal.ps1` (apenas ~58 líneas): conserva una parte del test de comunicaciones, probablemente para un caso o entorno concr |  |
| `Connectivity-Tests/TestComunicacionesGlobal_resultadolimitado.ps1` | Variante de `TestComunicacionesGlobal.ps1` con **salida reducida**: las mismas comprobaciones de puertos (MP, WSUS, DP, DC) pero devolviendo un resultado más escueto, pen |  |
| `Connectivity-Tests/TestComunicacionesGlobal_revisar.ps1` | Versión de trabajo ("revisar") de `TestComunicacionesGlobal.ps1`, con ajustes en curso sobre el test de comunicaciones del cliente. Es la más larga de las variantes. |  |
| `Connectivity-Tests/TestSQLServers.ps1` | Comprueba la **conectividad a una lista de servidores SQL** usando autenticación SQL (no Windows). | SQL Server (`System.Data.SqlClient` |
| `Connectivity-Tests/convert-IPtoFQDN.ps1` | Snippet que **resuelve nombres a partir de una lista de IPs** leídas de un fichero. | Resolución DNS inversa (`ping -a`) |
| `Connectivity-Tests/test_connect_SQL.ps1` | Lanza una **consulta directa a la base de datos de ConfigMgr** (autenticación integrada de Windows) para detectar equipos cuyo nombre difiere entre el inventario actual y | SQL Server (`System.Data.SqlClient`) |
| `Connectivity-Tests/testservers.ps1` | Averigua **contra qué WSUS está configurado un cliente** (leyéndolo de su propio log) y comprueba que ese servidor responda en el puerto de WSUS. | Parsing de `WUAHandler.log` |
| `Distribution-and-Content/DPContent.ps1` | Permite **distribuir o eliminar paquetes en un Distribution Point remoto** a partir de una lista en fichero de texto. | SCCM / ConfigMgr (CAS) |
| `Distribution-and-Content/DistribuyeListaPktsToDP.ps1` | Variante de `DPContent.ps1`: distribuye (o elimina) en un **Distribution Point** la lista de paquetes indicada en un fichero de texto, conectándose al CAS con una cuenta  |  |
| `Distribution-and-Content/Fail-Distributed-Content.ps1` | Variante de `Fail-DistributedContent.ps1` que incorpora su propia función `Write-CMTracelog` para un registro más estructurado. Detecta el contenido que ha fallado de dis |  |
| `Distribution-and-Content/Fail-DistributedContent.ps1` | Localiza los **paquetes que han fallado al distribuirse** a los DPs y fuerza su redistribución, dejando constancia en un log diario. | SCCM / ConfigMgr vía WMI (`SMS_PackageSt |
| `Distribution-and-Content/reparalibreriaautomatico.ps1` | Versión **automática** de la reparación de la librería de contenido de los DPs: hace lo mismo que `reparalibreriadp.ps1` pero sin intervención manual. | SCCM / ConfigMgr (CAS) |
| `Distribution-and-Content/reparalibreriadp.ps1` | **Repara la librería de contenido de un Distribution Point** cuando WMI y el sistema de ficheros (PkgLib) se han desincronizado. | SCCM / ConfigMgr |
| `Distribution-and-Content/reparalibreriadp_2.ps1` | Copia/variante de `reparalibreriadp.ps1` (reparación de la librería de contenido de un DP comparando WMI contra PkgLib). En el backup convivía con la versión sin sufijo. |  |
| `Duplicates-Cleanup/Remove-Duplicates.ps1` | Elimina de SCCM los **registros de equipos cuya instalación de cliente falló** y que, por tanto, suelen quedar como duplicados "fantasma". | SQL Server (`Invoke-Sqlcmd` sobre la BD |
| `Duplicates-Cleanup/RemoveNameDuplicate.ps1` | Limpia **duplicados por nombre** y los registros "Unknown" de SCCM. | SCCM / ConfigMgr (`Get-CMDevice` |
| `Duplicates-Cleanup/mantenimiento_clonados_duplicados.ps1` | Gestiona la **desinstalación del cliente en equipos clonados** orquestándola a través de grupos de seguridad de AD en los cuatro dominios. | Active Directory (grupos de seguridad) |
| `Duplicates-Cleanup/removeDuplicatesSCCM.ps1` | Casi idéntico a `Remove-Duplicates.ps1`: vía SQL localiza los equipos con instalación de cliente fallida (`ClientVersion` nulo y error 120) en una colección y los elimina |  |
| `Software-Updates/ComplianceUpdateServersResume.ps1` | Recopila los resultados de la baseline de cumplimiento **'Informe parcheo Servidores'** y los exporta a CSV para su explotación (Power BI). | SCCM / ConfigMgr (estado de baseline por |
| `Software-Updates/ConfigureUpdatesDeployments_v16.ps1` | Automatiza la **configuración de los despliegues de actualizaciones (SUP/ADR)** calculando las fechas a partir del *Patch Tuesday* de cada mes. | SCCM / ConfigMgr (Software Update Point |
| `Software-Updates/Detection-Update.ps1` | Script de **detección de nivel de parcheo** que decide si un equipo está al día traduciendo su *OS Build* a la fecha del parche correspondiente. | WMI/registro (versión de SO) |
| `Software-Updates/EsuY3Report.ps1` | Informe de la baseline **'ESU Year3'** (Extended Security Updates, año 3) exportado a CSV. | SCCM / ConfigMgr |
| `Software-Updates/Get-WUpdates.ps1` | **Función de terceros** (`Get-WindowsUpdatesInstall`) para **buscar, descargar e instalar actualizaciones de Windows** desde PowerShell, con filtrado fino. | API COM de Windows Update (Microsoft.Upd |
| `Software-Updates/ProcesaEquiposEsu7.ps1` | Procesa los **logs de la task sequence de activación de ESU** y mueve los equipos a la colección que corresponda según el resultado. | SCCM / ConfigMgr |
| `Software-Updates/SUPDeploymentStatus.ps1` | Calcula el **estado del despliegue mensual de actualizaciones** sobre el parque de workstations. | SCCM / ConfigMgr (Software Update Point) |
| `Software-Updates/SUPDeploymentStatusServers.ps1` | Estado del **despliegue de actualizaciones en servidores**, agrupado por sistema operativo. | SCCM / ConfigMgr (`Get-CMSoftwareUpdateD |

