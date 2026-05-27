
# Intune: Windows - Devices - Settings catalog - Start - Search - Start Layout W11

## Identificación de la Política
- **ID de la política:** 11111111-1111-1111-1111-000000000061  
- **Nombre:** Windows - Devices - Settings catalog - Start - Search - Start Layout W11  
- **Plataforma:** Windows 10/11 (MDM)  
- **Plantilla:** Settings catalog  
- **Número de ajustes:** 9  
- **Creación:** 2025-11-26 14:00:18Z  
- **Última modificación:** 2025-11-27 09:07:51Z  

## Objetivo
Estandarizar el menú Inicio de Windows 11, restringir elementos de búsqueda y privacidad reciente, y fijar un conjunto de accesos anclados para mejorar la experiencia controlada del usuario... minimizando ruido visual y evitando cambios no deseados.

## Resumen Ejecutivo de Configuración
| Área         | Ajuste                                         | Estado    |
|-------------|-------------------------------------------------|-----------|
| Búsqueda    | Deshabilitar la búsqueda del sistema            | Activado  |
| Inicio      | Configurar elementos anclados (Start pins)      | Activado  |
| Inicio      | Ocultar lista “Todas las aplicaciones”          | Activado  |
| Inicio      | Ocultar vista por categorías                    | Activado  |
| Inicio      | Ocultar “Cambiar configuración de cuenta”       | Activado  |
| Inicio      | Ocultar “Aplicaciones más usadas”               | Activado  |
| Inicio      | Ocultar “Listas de salto” recientes             | Activado  |
| Inicio      | Ocultar “Aplicaciones agregadas recientemente”  | Activado  |
| Barra tareas| Impedir anclado a la barra de tareas            | Activado  |

## Correspondencia Técnica con Catálogo de Configuración
- `device_vendor_msft_policy_config_search_disablesearch` = Disable Search  
- `device_vendor_msft_policy_config_start_configurestartpins` = Configure Start pins  
- `device_vendor_msft_policy_config_start_hideapplist` = Hide app list in Start  
- `device_vendor_msft_policy_config_start_hidecategoryview` = Hide category view  
- `device_vendor_msft_policy_config_start_hidechangeaccountsettings` = Hide "Change account settings"  
- `device_vendor_msft_policy_config_start_hidefrequentlyusedapps` = Hide "Most used apps"  
- `device_vendor_msft_policy_config_start_hiderecentjumplists` = Hide recent Jump Lists  
- `device_vendor_msft_policy_config_start_hiderecentlyaddedapps` = Hide "Recently added apps"  
- `device_vendor_msft_policy_config_start_nopinningtotaskbar` = No pinning to taskbar  

## Diseño del Start: Elementos Anclados  
**Política:** Configure Start pins  

### JSON Aplicado
```json
{
  "applyOnce": false,
  "pinnedList": [
    { "packagedAppId": "Microsoft.WindowsCamera_8wekyb3d8bbwe!App" },
    { "desktopAppLink": "%APPDATA%\Microsoft\Windows\Start Menu\Programs\File Explorer.lnk" },
    { "packagedAppId": "Microsoft.ScreenSketch_8wekyb3d8bbwe!App" },
    { "desktopAppLink": "%APPDATA%\Microsoft\Windows\Start Menu\Programs\YUNBIT.url" },
    { "desktopAppLink": "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Entorno BTREN.url" },
    { "desktopAppLink": "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" }
  ]
}
```

### Interpretación Funcional
- Cámara de Windows (UWP)  
- Explorador de archivos  
- Recortes y anotaciones (ScreenSketch)  
- Enlace YUNBIT (.url)  
- Enlace "Entorno BTREN" (.url)  
- Microsoft Edge  

`applyOnce: false` ⇒ la política re‑aplica los pines cada vez que el usuario se loguea.

## Impacto en el Usuario
- Inicio más limpio y simplificado... sin aplicaciones más usadas, agregadas recientemente ni vista por categorías.  
- Mayor privacidad: listas de salto recientes ocultas.  
- No se permite anclar a la barra de tareas.  
- Productividad dirigida mediante pines predefinidos.  
- Búsqueda del sistema deshabilitada (cuadro y experiencia de búsqueda no disponibles).  

## Requisitos y Dependencias
- Dispositivos gestionados por MDM con soporte CSP Start/Search.  
- Los archivos `.lnk` y `.url` deben existir en las rutas indicadas.  
- Deshabilitar búsqueda impacta funciones dependientes de Windows Search.  

## Consideraciones de Compatibilidad
- Rutas per-user (`%APPDATA%`) requieren que el archivo exista en el perfil.  
- Para pines más estables, usar `%ALLUSERSPROFILE%`.  
- Si se requiere búsqueda o lista de apps para usuarios avanzados, crear perfiles alternativos.  

## Asignaciones y Ámbito
- Tablets Taller con Windows 11.
- Azure Group: "Intune - Windows - Devices - Policy - Deploy- Start - Search - Start Layout W11"

## Riesgos y Mitigaciones
- No se esperan
- Incluir equipos en el grupo de exclusiones. Group Name: "Intune - Windows - Devices - Policy - Exclusiones - Start - Search - Start Layout W11"

## Plan de Reversión
- Desasignar la política actual y asignar política de rollback.  

## Trazabilidad Técnica
- Search: DisableSearch = Enabled  
- Start: ConfigureStartPins = JSON aplicado  
- Start: HideAppList = Enabled  
- Start: HideCategoryView = Enabled  
- Start: HideChangeAccountSettings = Enabled  
- Start: HideFrequentlyUsedApps = Enabled  
- Start: HideRecentJumpLists = Enabled  
- Start: HideRecentlyAddedApps = Enabled  
- Taskbar: NoPinningToTaskbar = Enabled  

## Historial de Cambios
- **2025-11-27:** Última modificación.  
- **2025-11-26:** Creación.
