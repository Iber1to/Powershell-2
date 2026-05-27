Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Confirm:$false -Force:$true
Install-Script get-windowsautopilotinfo -Confirm:$false -Force:$true
get-windowsautopilotinfo -Online -TenantId "11111111-1111-1111-1111-000000008761" -AppId "11111111-1111-1111-1111-000000008762" -AppSecret "REDACTED_CLIENT_SECRET"
shutdown.exe /s /t 10