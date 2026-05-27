# Creaunacoleccionporcadaboundarygroup.ps1

**Script de terceros** (Jonathan Lefebvre, SystemCenterDudes) que crea **una colección por cada boundary group** existente en el entorno.

## Cómo funciona

- Carga el módulo de ConfigMgr a partir de `$Env:SMS_ADMIN_UI_PATH` y se sitúa en la unidad del site.
- Usa un prefijo configurable para las colecciones (`BG- `) y una colección limitante definible (aquí la principal de workstations).
- Recorre los boundary groups encontrados y genera la colección correspondiente para cada uno.

## Tecnología
SCCM / ConfigMgr (módulo ConfigurationManager).

## Notas
Origen externo (SystemCenterDudes); se conserva la atribución. Útil para tener cobertura operacional por boundary group.
