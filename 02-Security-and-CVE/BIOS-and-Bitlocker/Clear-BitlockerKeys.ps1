# Agregar la referencia a ensamblado de Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Función para mostrar un cuadro de diálogo de confirmación
function ConfirmWindow($message) {
    $result = [System.Windows.Forms.MessageBox]::Show($message, "Confirmación", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    return $result -eq "Yes"
}

function InforWindow($message) {
    $result = [System.Windows.Forms.MessageBox]::Show($message, "Información", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    return $result -eq "OK"
}

# Check if running with Administrative privileges if required
if ($GlobalAndAllUsers -or $AllUsers) {
    $RunningAsAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($RunningAsAdmin -eq $false) {
        [System.Windows.Forms.MessageBox]::Show($message, "Confirmación", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
        exit 1
    }
}

# Verificar si el módulo Active Directory está instalado
$StatRsat = Get-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -Online
$StatRsat
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    if (ConfirmWindow "El módulo Active Directory no está instalado. ¿Desea instalarlo?") {
        # Instalar el módulo Active Directory
        Install-Module -Name ActiveDirectory -Force
        Import-Module ActiveDirectory
        Update-Module -Name ActiveDirectory

    } else {
        Write-Host "No se puede continuar sin el módulo Active Directory." -ForegroundColor Red
        exit
    }
}
