# add-winget-package-pipeline.ps1

**Script de terceros** (Andrew Taylor, v1.3, GPL) que **crea una aplicación en Intune a partir de un manifiesto de Winget**.

## Cómo funciona
Toma un paquete de Winget, descarga/empaqueta el instalador, lo convierte al formato `.intunewin` y lo publica como aplicación Win32 en Intune vía Microsoft Graph, rellenando metadatos, reglas de detección, etc. Está pensado para encadenarse en un pipeline de empaquetado.

## Tecnología
Winget · Microsoft Graph (Intune Win32 apps) · OAuth2 app.

## Notas
Código de la comunidad; se conserva la cabecera `PSScriptInfo` y la autoría. El `client_secret`/IDs de la app de ejemplo se han redactado.
