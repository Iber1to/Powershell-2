# main_2.py

Proyecto **"Alert New Apps"**: consulta Microsoft Graph para detectar **aplicaciones Win32 nuevas en Intune** y envía un aviso por correo.

## Cómo funciona
- Obtiene token con MSAL (client credentials) mediante el helper `ms_auth.py`.
- Llama a Graph (`/beta/deviceAppManagement/mobileApps`, filtrando `win32LobApp`, seleccionando `displayName` y `createdDateTime`) para listar las apps por fecha de creación.
- Compone y envía por SMTP (`smtplib`) un correo con las novedades.

## Tecnología
Microsoft Graph (Intune) · MSAL/OAuth2 · `smtplib`.

## Notas
Credenciales redactadas. Pensado para ejecutarse de forma periódica como vigilancia de altas de aplicaciones.
