# Irivalocaladmins.ps1

Misma herramienta que `Set-IntuneUserAdminLocal.ps1` (admin local sobre los dispositivos de los que un usuario es propietario en Intune), aquí instanciada para el tenant de un cliente gestionado.

## Cómo funciona
Crea un grupo con los dispositivos del usuario, genera una política de Account Protection que lo añade como administrador local y se la asigna, todo vía Microsoft Graph.

## Tecnología
Microsoft Graph · Intune (Account Protection) · OAuth2.

## Notas
El `client secret` y los IDs de tenant/app se han redactado. Ver `Set-IntuneUserAdminLocal.ps1`, del que es prácticamente un gemelo para otro tenant.
