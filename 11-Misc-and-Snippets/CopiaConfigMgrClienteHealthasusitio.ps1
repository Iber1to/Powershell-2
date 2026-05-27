Import-Module "C:\01.Scripts\AAGFunctions.ps1"

$PathCMTracelog= 'C:\Scripts de Mantenimiento\CopiaHealthScript\logwork.log'
if( $(Test-Path -Path $PathCMTracelog)){Remove-Item -Path $PathCMTracelog -Force}

$PathItem = "C:\Scripts de Mantenimiento\CopiaHealthScript\ConfigMgrClientHealth.ps1"

Write-CMTracelog "Iniciando Comprobación"
Write-CMTracelog "Comprobando EMEA"
# Zona EMEA
$Emea = Test-Path "D:\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
If($Emea){Write-CMTracelog "El archivo esta en su Path. Continuando la revision."}
else
   {
    Write-CMTracelog "El archivo ha sido borrado. Iniciando restore"
    Copy-Item -Path $PathItem -Destination "D:\Client_Start_Script_Install\ClientHealth\"
    $Emea = Test-Path "D:\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
    If($Emea){Write-CMTracelog "Archivo restaurado"}
    else{Write-CMTracelog -Message "Fallo al restaurar el archivo" -Type Error}
   }


Write-CMTracelog "Comprobando APAC"
#Zona APAC
$Apac = Test-Path "\\SRV007.apac.contoso.local\L$\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
If($Apac){Write-CMTracelog "El archivo esta en su Path. Continuando la revision."}
else
    {
    Write-CMTracelog "El archivo ha sido borrado. Iniciando restore"
    Copy-Item -Path $PathItem -Destination "\\SRV007.apac.contoso.local\L$\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
    $Apac = Test-Path "\\SRV007.apac.contoso.local\L$\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
    If($Apac){Write-CMTracelog "Archivo restaurado"}
    else{Write-CMTracelog -Message "Fallo al restaurar el archivo" -Type Error}
    }

Write-CMTracelog "Comprobando Latam2"
#Zona Latam2
$Latam2 = Test-Path "\\SRV005.latam2.contoso.local\D$\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
If($Latam2){Write-CMTracelog "El archivo esta en su Path. Continuando la revision."}
else
    {
    Write-CMTracelog "El archivo ha sido borrado. Iniciando restore"
    Copy-Item -Path $PathItem -Destination "\\SRV005.latam2.contoso.local\D$\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
    $Latam2 = Test-Path "\\SRV005.latam2.contoso.local\D$\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
    If($Latam2){Write-CMTracelog "Archivo restaurado"}
    else{Write-CMTracelog -Message "Fallo al restaurar el archivo" -Type Error}
    }

Write-CMTracelog "Comprobando Latam1"
#Zona Latam1
$Latam1 = Test-Path "\\SRV008.latam1.contoso.local\G$\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
If($Latam1){Write-CMTracelog "El archivo esta en su Path. Continuando la revision."}
else
    {
    Write-CMTracelog "El archivo ha sido borrado. Iniciando restore"
    Copy-Item -Path $PathItem -Destination "\\SRV008.latam1.contoso.local\G$\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
    $Latam1 = Test-Path "\\SRV008.latam1.contoso.local\G$\Client_Start_Script_Install\ClientHealth\ConfigMgrClientHealth.ps1"
    If($Latam1){Write-CMTracelog "Archivo restaurado"}
    else{Write-CMTracelog -Message "Fallo al restaurar el archivo" -Type Error}
    }

    Write-CMTracelog "Comprobación Finalizada"