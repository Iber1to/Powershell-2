# Send-Mail-OAuth-Variant.ps1

Otra variante del **recordatorio de caducidad de contraseña** de Robert Pearman (v2.9), con envío por OAuth2/Graph.

## Cómo funciona
Misma base que los `PasswordChangeNotification*`: localiza en AD las contraseñas próximas a caducar y manda el aviso por correo, aquí obteniendo token OAuth2.

## Tecnología
Active Directory · Microsoft Graph · OAuth2.

## Notas
Originalmente tenía un nombre poco descriptivo (un nombre de pila); se ha renombrado. Contraseña de envío redactada. Ver los `PasswordChangeNotification*` de la carpeta de Notificaciones.
