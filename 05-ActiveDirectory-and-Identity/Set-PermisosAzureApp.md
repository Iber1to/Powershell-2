# Set-PermisosAzureApp.ps1

Configura el acceso de un **proveedor externo a un único site de SharePoint Online** usando el permiso de Graph `Sites.Selected` (en lugar de los permisos amplios `Sites.Read.All`/`Files.Read.All`).

## Cómo funciona
Parte de dos apps registradas en Azure: la que se entrega al proveedor y otra con permisos para **asignar** acceso sobre el site concreto a la del proveedor. El script obtiene token (client credentials), localiza el site y concede a la app del proveedor permiso únicamente sobre ese site collection.

## Tecnología
Microsoft Graph (`Sites.Selected`) · MSAL/OAuth2 · SharePoint Online.

## Notas
Los `client secret` y los IDs de tenant/app venían en el código y se han redactado. Es un buen ejemplo de acceso de mínimo privilegio para terceros.
