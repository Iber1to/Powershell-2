# Send-mail-Outha.ps1

Ejemplo de **envío de correo a través de Microsoft 365 / Graph con autenticación OAuth2** (client credentials), sin depender de SMTP.

## Cómo funciona
Con `AppId`, `AppSecret` y `TenantId` solicita un token a `login.microsoftonline.com/.../oauth2/v2.0/token` (scope `https://graph.microsoft.com/.default`) y después usa Graph para enviar el mensaje.

## Tecnología
Microsoft Graph (sendMail) · OAuth2 client credentials.

## Notas
El `AppSecret` y los IDs se han redactado. Es la plantilla de referencia para enviar correo moderno (sin SMTP básico) que reutilizan otros scripts.
