#Detection Section

$computerModel = Get-WMIObject -Class Win32_ComputerSystem
$Interface = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSettingInterface -ErrorAction SilentlyContinue
$HPBiosSetting = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSetting -ErrorAction SilentlyContinue
$SetupPasswordCheck = ($HPBiosSetting | Where-Object Name -eq "Setup Password").IsSet
if (($computerModel.Manufacturer -eq 'HP') -and ($SetupPasswordCheck -eq '0')){Write-Output 'No password active'}
    elseif(($computerModel.Manufacturer -ne 'HP')){Write-Output 'Manufacturer not supported'}
        elseif(($computerModel.Manufacturer -eq 'HP') -and ($SetupPasswordCheck -eq '1')){Write-Output 'Password Enable'}    # Hay que elegir este string como compliance de la Base Line "Password Enable"   
else{Write-Output 'Unknown'}

#################################################################

#Remediation Section 
$computerModel = Get-WMIObject -Class Win32_ComputerSystem
$Interface = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSettingInterface -ErrorAction SilentlyContinue
$HPBiosSetting = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSetting -ErrorAction SilentlyContinue
$SetupPasswordCheck = ($HPBiosSetting | Where-Object Name -eq "Setup Password").IsSet
if(($computerModel.Manufacturer -ne 'HP')){Write-Output 'Manufacturer not supported'; Exit 1}

$Interface = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSettingInterface
$HPBiosSetting = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSetting
$Password = "Ib3rc4j4$"
$codeOperation00 = $Interface.SetBIOSSetting("Setup Password","<utf-16/>" + $Password,"<utf-16/>").return
$codeOperation01 = $Interface.SetBIOSSetting("Prompt for Admin password on F9 (Boot Menu)","Enable","<utf-16/>" + $Password).return
$codeOperation02 = $Interface.SetBIOSSetting("Prompt for Admin password on F11 (System Recovery)","Enable","<utf-16/>" + $Password).return
$codeOperation03 = $Interface.SetBIOSSetting("Prompt for Admin password on F12 (Network Boot)","Enable","<utf-16/>" + $Password).return
    
$codeOperation =  $codeOperation00 ,$codeOperation01, $codeOperation02, $codeOperation03

foreach($item in $codeOperation){
    switch ($item) {
        0 { $resultado += "OK" }
        1 { $resultado += "Not Supported" }
        2 { $resultado += "Unspecified error" }
        3 { $resultado += "Operation timed out" }
        4 { $resultado += "Operation failed or setting name is invalid" }
        5 { $resultado += "Invalid parameter" }
        6 { $resultado += "Access denied or incorrect password" }
        7 { $resultado += "Bios user already exists" }
        8 { $resultado += "Bios user not present" }
        9 { $resultado += "Bios user name too long" }
        10 { $resultado += "Password policy not met" }
        11 { $resultado += "Invalid keyboard layout" }
        12 { $resultado += "Too many users" }
        32768 { $resultado += "Security or password policy not met" }
        default { $resultado += "Unknown error: $item" }
        }
    }
    return $resultado
    exit $item


    # Verificar versión de Windows instalada
Write-Host "---- Versión actual de Windows ----"
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion") | Select-Object ProductName, DisplayVersion, CurrentBuild, ReleaseId

# Verificar si el equipo está en el canal Insider
Write-Host "`n---- Canal Insider (si aplica) ----"
$insider = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Selection" -ErrorAction SilentlyContinue
if ($insider) {
    $insider | Select-Object UIBranch, UIContentType, UIRing
} else {
    Write-Host "El equipo no está inscrito en ningún canal Insider."
}

# Ver políticas aplicadas por MDM para Windows Update

<#
.Synopsis
   Get the Windows Update policy on local or remote computers via the registry.
.DESCRIPTION
   Get the Windows Update policy on local or remote computers via the registry.
   A Windows system can be configured to communicate with a managed update
   environment such as WSUS, SCCM, or Intune. Get-WindowsUpdatePolicy will
   query the registry keys that store the current Windows Update policy for a
   system. The function will also display if no policy is configured.
.NOTES
    Created by: Jason Wasser @wasserja
    Modified: 2/7/2017 01:40:26 PM
.PARAMETER ComputerName
    Enter one or more computer names.
.PARAMETER Key
    The Windows Update policy registry key path is already specified.
.PARAMETER Credential
    Enter alternate credentials for accessing remote computers.
.EXAMPLE
   Get-WindowsUpdatePolicy
 
   Shows the current Windows Update policy of the local computer if it is configured.
.EXAMPLE
   Get-WindowsUpdatePolicy -ComputerName SERVER01,CLIENT02
 
   Shows the current Windows Update policy of server01 and client02 if it is configured.
.LINK
    https://gallery.technet.microsoft.com/scriptcenter/Get-WindowsUpdatePolicy-317c83d3
#>
function Get-WindowsUpdatePolicy
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([Microsoft.Win32.RegistryKey])]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string[]]$ComputerName=$env:COMPUTERNAME,

        # Windows Update policy registry key path
        [string]$Key='HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate',
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    Begin
    {
        # Helper function to get the registry keys and values
        function Get-RegistryKey ($Key, $Computer) {
            Write-Verbose "$Computer"
            if (Test-Path $Key) {
                # Get the WindowsUpdate policy information
                Get-ItemProperty $Key
                
                # Get the WindowsUpdate AU sub key values
                if (Test-Path $Key\AU) {
                    Get-ItemProperty $Key\AU
                    }
                
                }
            else {
                Write-Host "No Windows Update policy set for $Computer."
                }
            }

    }
    Process
    {
        foreach ($Computer in $ComputerName) {
            if ($Computer -eq $env:COMPUTERNAME) {
                Write-Verbose "Getting Windows Update policy registry settings from $Computer."
                Get-RegistryKey -Key $Key
                }
            else {
                Write-Verbose "Getting remote Windows Update policy registry settings from $Computer."
                Invoke-Command -ScriptBlock ${function:Get-RegistryKey} -ComputerName $Computer -ArgumentList $Key,$Computer -Credential $Credential
                }
            }
    }
    End
    {
    }
}
Write-Host "`n---- Políticas de Windows Update aplicadas por MDM ----"
try {
    Get-WindowsUpdatePolicy
} catch {
    Write-Host "El módulo no está disponible. Intenta con Get-CimInstance si es necesario."
}

# Consultar eventos recientes relacionados con políticas de actualización
Write-Host "`n---- Eventos MDM recientes sobre actualizaciones ----"
Get-WinEvent -LogName Microsoft-Windows-DeviceManagement-Enterprise-Diagnostics-Provider/Admin | Where-Object { $_.Message -like "*FeatureUpdate*" -or $_.Message -like "*Update*" } | Select-Object TimeCreated, Id, LevelDisplayName, Message | Sort-Object TimeCreated -Descending | Select-Object -First 20


# Cargar los ensamblados necesarios
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

function IsValidComputerName {
    param ([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }
    if ($Name.Length -gt 15) { return $false }
    if ($Name.StartsWith('-') -or $Name.EndsWith('-')) { return $false }
    $invalidChars = '[\\/:*?"<>|,+=;\[\]@ ]'
    if ($Name -match $invalidChars) { return $false }
    if ($Name -match '^\d+$') { return $false }
    return $true
}

function IsRunningAsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Verificar privilegios de administrador
if (-not (IsRunningAsAdmin)) {
    [System.Windows.Forms.MessageBox]::Show("Este script requiere privilegios de administrador para renombrar el equipo.", "Permiso denegado", "OK", "Error")
    return
}

# Bucle para pedir nombre válido
do {
    $NewName = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Ingresa el nombre deseado para este dispositivo:`n(Máx. 15 caracteres, sin caracteres especiales ni solo números)",
        "Renombrar Dispositivo", 
        $env:COMPUTERNAME
    )

    if ([string]::IsNullOrWhiteSpace($NewName)) {
        [System.Windows.Forms.MessageBox]::Show("No se ingresó un nuevo nombre. El dispositivo no será renombrado.", "Operación Cancelada", "OK", "Warning")
        return
    }

    if (-not (IsValidComputerName $NewName)) {
        [System.Windows.Forms.MessageBox]::Show("Nombre inválido. Asegúrate de que:`n- No exceda 15 caracteres`n- No tenga caracteres especiales`n- No sea solo números`n- No comience ni termine con '-'", "Nombre Inválido", "OK", "Error")
        $NewName = $null
    }

} until ($NewName)

# Intentar renombrar con mejor control de errores
try {
    Rename-Computer -NewName $NewName -Force -ErrorAction Stop
    [System.Windows.Forms.MessageBox]::Show("El dispositivo ha sido renombrado a: $NewName", "Éxito", "OK", "Information")
}
catch {
    $errorMsg = $_.Exception.Message

    # Manejo de errores específicos
    if ($errorMsg -like "*Access is denied*") {
        $friendlyMessage = "Acceso denegado. Ejecuta el script como administrador."
    }
    elseif ($errorMsg -like "*The computer name could not be changed*") {
        $friendlyMessage = "No se pudo cambiar el nombre. Verifica si el nombre ya está en uso en la red."
    }
    else {
        $friendlyMessage = "Error desconocido: $errorMsg"
    }

    # Mostrar el mensaje
    [System.Windows.Forms.MessageBox]::Show($friendlyMessage, "Error al Renombrar", "OK", "Error")

    # Registrar en archivo de log opcional
    $logPath = "$env:USERPROFILE\rename-computer-error.log"
    "[$(Get-Date)] Error al renombrar a '$NewName': $errorMsg" | Out-File -FilePath $logPath -Append -Encoding UTF8
}
