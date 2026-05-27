# AutopilotRegisterDevices.ps1

Script de **3 líneas** para registrar un equipo en **Windows Autopilot** y apagarlo, pensado para ejecutarse durante la preparación del dispositivo.

## Cómo funciona
Instala el proveedor NuGet y el script `Get-WindowsAutopilotInfo` desde la PowerShell Gallery, lo ejecuta con `-Online` (sube el hardware hash al tenant indicado por `TenantId`/`AppId`/`AppSecret`) y a continuación lanza `shutdown /s`.

## Tecnología
Windows Autopilot · `Get-WindowsAutopilotInfo` (PowerShell Gallery) · OAuth2 app.

## Notas
El `AppSecret`, el `TenantId` y el `AppId` estaban en claro; se han redactado. Pensado para grabarse en una imagen/USB de aprovisionamiento.
