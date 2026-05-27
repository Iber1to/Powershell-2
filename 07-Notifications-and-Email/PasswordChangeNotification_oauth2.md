# PasswordChangeNotification_oauth2.ps1

Variante del recordatorio de caducidad de contraseña de Robert Pearman que **envía el correo vía Microsoft Graph (OAuth2)** en lugar de SMTP básico.

## Cómo funciona
Misma lógica de detección de contraseñas próximas a caducar en AD, pero la entrega se hace obteniendo un token OAuth2 y usando Graph para mandar el aviso a cada usuario.

## Tecnología
Active Directory · Microsoft Graph · OAuth2.

## Notas
Adaptación del script original para entornos sin SMTP autenticado. Credenciales redactadas. Ver `PasswordChangeNotification.ps1`.
