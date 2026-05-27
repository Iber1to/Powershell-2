# mantenimiento_clonados_duplicados.ps1

Gestiona la **desinstalación del cliente en equipos clonados** orquestándola a través de grupos de seguridad de AD en los cuatro dominios.

## Cómo funciona

- Alimenta los grupos de seguridad (uno por dominio) que disparan, vía GPO/colección, la desinstalación del cliente de SCCM en los equipos detectados como clonados.
- A su vez recoge los resultados de los equipos que ya han ejecutado el proceso y los **saca** del grupo correspondiente para cerrar el ciclo.
- Lleva un log propio con función `Write-Log` y marca de tiempo en epoch.

## Tecnología
Active Directory (grupos de seguridad) · SCCM / ConfigMgr · logging a fichero.

## Notas
Pensado para ejecución recurrente (tarea programada). Equipos clonados = imágenes desplegadas que comparten identidad del cliente y hay que sanear.
