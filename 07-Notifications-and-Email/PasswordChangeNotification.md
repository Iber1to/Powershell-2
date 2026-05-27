# PasswordChangeNotification.ps1

**Script de terceros muy conocido** (Robert Pearman, *WindowsServerEssentials.com*, v2.9): envía a los usuarios **recordatorios por correo de caducidad de contraseña** de Active Directory.

## Cómo funciona
Consulta en AD los usuarios habilitados con contraseña a punto de caducar (según la política de dominio y unos umbrales de días), compone un correo HTML personalizado por usuario y lo envía. Requiere el módulo de Active Directory.

## Tecnología
Active Directory · correo (SMTP) · plantilla HTML.

## Notas
Código de la comunidad adaptado. Tenía una contraseña de cuenta de envío en claro que se ha redactado. `PasswordChangeNotification_oauth2.ps1` y `EnvíoCC.ps1` son variantes (envío por Graph/OAuth2 y con copia).
