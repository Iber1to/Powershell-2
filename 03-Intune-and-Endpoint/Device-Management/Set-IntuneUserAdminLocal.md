# Set-IntuneUserAdminLocal.ps1

Otorga **permisos de administrador local** a un usuario sobre **los dispositivos de los que es propietario en Intune**, de forma automatizada vía Microsoft Graph.

## Cómo funciona

1. A partir del usuario, consulta en Intune los dispositivos de los que es propietario.
2. Crea un grupo de seguridad y mete en él esos dispositivos.
3. Genera una política de **Account Protection** que añade al usuario como administrador local y la asigna a ese grupo.

## Parámetros
`-Usuario` (un correo o un fichero de texto con varios) y `-TenantId`.

## Tecnología
Microsoft Graph · Intune (Account Protection / LAPS-adjacent) · grupos de Azure AD · OAuth2.

## Notas
`Irivalocaladmins.ps1` (en la carpeta de AD/Identidad) es la misma herramienta para otro tenant. El `client secret` y los IDs de tenant/app venían en el código y se han redactado (`REDACTED_CLIENT_SECRET`, GUIDs ficticios).
