# 07-Notifications-and-Email

Notificaciones por correo (SMTP y Microsoft Graph/OAuth2), incluyendo recordatorios de caducidad de contraseña.

## Scripts de esta categoría

| Script | Qué hace | Tecnología principal |
|---|---|---|
| `EnvíoCC.ps1` | Variante del recordatorio de caducidad de contraseña (base de Robert Pearman) ajustada para **enviar también copia (CC)** a un buzón de control además de al usuario. | Active Directory |
| `Merged-Password.ps1` | Pequeña **utilidad gráfica** (WinForms/WPF) para lanzar operaciones de contraseña de las **cuentas de servicio de CMDB** eligiendo la región en una lista. | WinForms / WPF (GUI) |
| `PasswordChangeNotification.ps1` | **Script de terceros muy conocido** (Robert Pearman, *WindowsServerEssentials.com*, v2.9): envía a los usuarios **recordatorios por correo de caducidad de contraseña** de | Active Directory |
| `PasswordChangeNotification_oauth2.ps1` | Variante del recordatorio de caducidad de contraseña de Robert Pearman que **envía el correo vía Microsoft Graph (OAuth2)** en lugar de SMTP básico. | Active Directory |
| `Send-mail-Outha.ps1` | Ejemplo de **envío de correo a través de Microsoft 365 / Graph con autenticación OAuth2** (client credentials), sin depender de SMTP. | Microsoft Graph (sendMail) |
| `sendmail.py` | Snippet de Python de cuatro líneas que, pese al nombre, **no envía correo**: lista los paquetes pip instalados en el entorno. |  |

