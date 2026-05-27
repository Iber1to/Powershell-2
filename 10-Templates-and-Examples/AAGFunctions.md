# AAGFunctions.ps1

**Módulo de funciones propio** que sirve de base a buena parte de los scripts de SCCM del repositorio. Es la pieza que se importa con `Import-Module C:\01.Scripts\AAGFunctions.ps1` en decenas de scripts.

## Qué incluye
Entre otras, funciones de uso transversal:
- `Connect-CMSite` — conecta a un site de SCCM (con parámetros de SiteCode y SMS Provider).
- `Write-CMTracelog` — escribe logs en formato CMTrace.
- `Get-PatchTuesday` — calcula el segundo martes del mes.
- `send-MailHtml` — envía correo HTML.
- `Format-ContentTransferManager` — utilidades de gestión de contenido.

## Tecnología
SCCM / ConfigMgr · logging CMTrace · correo.

## Notas
Es la "librería de cabecera" del autor; muchos scripts dependen de ella. Mantiene la atribución del autor en sus cabeceras.
