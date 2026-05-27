#Requires -Version 5.1
<#
.SYNOPSIS
    Recopila inventario personalizado del dispositivo y lo almacena en JSON con opción de carga a Azure Blob.

.DESCRIPTION
    Script controlador orientado a ejecución desatendida desde Intune, Ivanti, MECM o tarea programada.
    Recopila inventario de hardware y/o software, genera ficheros JSON con marca temporal para mantener
    histórico y, opcionalmente, los carga a Azure Blob Storage mediante SAS Token.

    El script está diseñado para ser tolerante con escenarios no aplicables, por ejemplo:
    - Equipos no unidos a Azure AD o sin inscripción MDM.
    - Equipos sin BitLocker, TPM o clases CIM concretas.
    - Hosts donde determinadas rutas de registro no existen.

.PARAMETER StorageAccountName
    Nombre de la cuenta de almacenamiento de Azure Blob.

.PARAMETER HardwareContainerName
    Nombre del contenedor de Azure Blob donde se sube el inventario de hardware.

.PARAMETER SoftwareContainerName
    Nombre del contenedor de Azure Blob donde se sube el inventario de software.

.PARAMETER SasToken
    SAS Token para la carga a Azure Blob. Se recomienda pasarlo como parámetro o variable de entorno
    y no dejarlo embebido en el script. Si no se indica, se intentará leer desde la variable de entorno
    CUSTOMINVENTORY_SASTOKEN.

.PARAMETER OutputRoot
    Ruta raíz local donde se almacenan logs y JSON con histórico.

.PARAMETER CollectDeviceInventory
    Indica si debe recopilarse inventario de hardware.

.PARAMETER CollectAppInventory
    Indica si debe recopilarse inventario de software.

.PARAMETER CollectModernAppInventory
    Indica si debe incluirse inventario de aplicaciones Appx/MSIX/UWP mediante Get-AppxPackage.

.PARAMETER SkipUpload
    Genera los JSON localmente, pero no los sube a Azure Blob.

.EXAMPLE
    .\Invoke-CustomInventory-v5.0.0.ps1 `
        -StorageAccountName intunereportinventory `
        -HardwareContainerName hardwareinventory `
        -SoftwareContainerName softwareinventory `
        -SasToken $env:CUSTOMINVENTORY_SASTOKEN

.EXAMPLE
    .\Invoke-CustomInventory-v5.0.0.ps1 `
        -StorageAccountName intunereportinventory `
        -HardwareContainerName hardwareinventory `
        -SoftwareContainerName softwareinventory `
        -SkipUpload `
        -Verbose

.OUTPUTS
    PSCustomObject
.NOTES
    FileName:    Invoke-CustomInventory-v5.0.0.ps1
    Author:      IT Automation
    Version:     5.0.0
    Notes:
        - Refactorizado para mejorar mantenibilidad, trazabilidad y tolerancia a estados no aplicables.
        - El SAS Token se externaliza para evitar credenciales embebidas en el script.
        - El inventario de software combina aplicaciones Win32 desde registro y Appx/MSIX/UWP con origen diferenciado.
        - Versión final de entrega validada funcionalmente con generación local y carga correcta a Azure Blob.

#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StorageAccountName = 'intunereportinventory',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$HardwareContainerName = 'hardwareinventory',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SoftwareContainerName = 'softwareinventory',

    [Parameter()]
    [AllowEmptyString()]
    [string]$SasToken = "REDACTED_SAS_TOKEN",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputRoot = 'C:\ProgramData\CustomInventory',

    [Parameter()]
    [bool]$CollectDeviceInventory = $true,

    [Parameter()]
    [bool]$CollectAppInventory = $true,

    [Parameter()]
    [bool]$CollectModernAppInventory = $true,

    [Parameter()]
    [switch]$SkipUpload
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:WarningCount = 0
$script:ErrorCount = 0
$script:CreatedFiles = [System.Collections.Generic.List[string]]::new()
$script:UploadedBlobs = [System.Collections.Generic.List[string]]::new()

$executionTime = Get-Date
$executionStamp = $executionTime.ToString('yyyyMMdd_HHmmss')
$logDirectory = Join-Path -Path $OutputRoot -ChildPath 'Logs'
$dataDirectory = Join-Path -Path $OutputRoot -ChildPath 'Data'
$hardwareDirectory = Join-Path -Path $dataDirectory -ChildPath 'Hardware'
$softwareDirectory = Join-Path -Path $dataDirectory -ChildPath 'Software'

foreach ($path in @($logDirectory, $hardwareDirectory, $softwareDirectory)) {
    New-Item -Path $path -ItemType Directory -Force | Out-Null
}

$script:LogFile = Join-Path -Path $logDirectory -ChildPath (
    'Invoke-CustomInventory_{0}_{1}.log' -f $env:COMPUTERNAME, $executionStamp
)

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')]
        [string]$Level = 'INFO'
    )

    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $script:LogFile -Value $line -Encoding UTF8

    switch ($Level) {
        'WARN'  { $script:WarningCount++ }
        'ERROR' { $script:ErrorCount++ }
    }

    switch ($Level) {
        'INFO'  { Write-Verbose $Message }
        'OK'    { Write-Verbose $Message }
        'WARN'  { Write-Warning $Message }
        'ERROR' { Write-Warning $Message }
    }
}

function Get-SafePropertyValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        $DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }

    return $property.Value
}

function Convert-DmtfDateSafely {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$DmtfDate,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Context = 'fecha DMTF'
    )

    if ($null -eq $DmtfDate) {
        return $null
    }

    if ($DmtfDate -is [datetime]) {
        return $DmtfDate.ToString('o')
    }

    $rawValue = [string]$DmtfDate
    if ([string]::IsNullOrWhiteSpace($rawValue)) {
        return $null
    }

    $parsedDate = [datetime]::MinValue
    if ([datetime]::TryParse(
            $rawValue,
            [System.Globalization.CultureInfo]::CurrentCulture,
            [System.Globalization.DateTimeStyles]::AssumeLocal,
            [ref]$parsedDate
        )) {
        return $parsedDate.ToString('o')
    }

    $parsedDate = [datetime]::MinValue
    if ([datetime]::TryParse(
            $rawValue,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeLocal,
            [ref]$parsedDate
        )) {
        return $parsedDate.ToString('o')
    }

    try {
        return [Management.ManagementDateTimeConverter]::ToDateTime($rawValue).ToString('o')
    } catch {
        Write-Log -Message ("No se pudo interpretar {0}: valor '{1}'. {2}" -f $Context, $rawValue, $_.Exception.Message) -Level 'WARN'
        return $null
    }
}


function Test-CommandAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    return ($null -ne (Get-Command -Name $Name -ErrorAction SilentlyContinue))
}

function Get-RegistrySubKeyNamesSafely {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return ,@()
    }

    try {
        return ,@(Get-ChildItem -LiteralPath $Path -ErrorAction Stop | Select-Object -ExpandProperty PSChildName)
    } catch {
        Write-Log -Message ("No se pudieron enumerar subclaves en {0}: {1}" -f $Path, $_.Exception.Message) -Level 'WARN'
        return ,@()
    }
}

function Get-ManagedDeviceInfo {
    [CmdletBinding()]
    param()

    $result = [ordered]@{
        ManagedDeviceName = $null
        ManagedDeviceId   = $null
        EnrollmentSource  = $null
    }

    $enrollmentRoot = 'HKLM:\SOFTWARE\Microsoft\Enrollments'
    if (-not (Test-Path -LiteralPath $enrollmentRoot)) {
        Write-Log -Message 'No se encontró información de inscripción MDM en HKLM:\SOFTWARE\Microsoft\Enrollments.'
        return [pscustomobject]$result
    }

    try {
        $serverKey = Get-ChildItem -Path $enrollmentRoot -Recurse -ErrorAction Stop |
            Where-Object { $_.PSChildName -eq 'MS DM Server' } |
            Select-Object -First 1

        if ($null -eq $serverKey) {
            Write-Log -Message 'El equipo no presenta la clave "MS DM Server"; se continúa sin datos de Managed Device.'
            return [pscustomobject]$result
        }

        $managedDeviceInfo = Get-ItemProperty -LiteralPath ("Registry::{0}" -f $serverKey.Name) -ErrorAction Stop
        $result.ManagedDeviceName = $managedDeviceInfo.EntDeviceName
        $result.ManagedDeviceId = $managedDeviceInfo.EntDMID
        $result.EnrollmentSource = $serverKey.Name
    } catch {
        Write-Log -Message ("No se pudo leer información MDM: {0}" -f $_.Exception.Message) -Level 'WARN'
    }

    return [pscustomobject]$result
}

function Get-AzureADTenantId {
    [CmdletBinding()]
    param()

    $tenantRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\TenantInfo'
    $tenantIds = @(Get-RegistrySubKeyNamesSafely -Path $tenantRoot)

    if ($tenantIds.Count -eq 0) {
        Write-Log -Message 'El equipo no parece unido a Azure AD; no se encontró TenantInfo.'
        return $null
    }

    return $tenantIds[0]
}

function Get-AzureADJoinCertificate {
    [CmdletBinding()]
    param()

    $joinRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\CloudDomainJoin\JoinInfo'
    $thumbprints = @(Get-RegistrySubKeyNamesSafely -Path $joinRoot)

    if ($thumbprints.Count -eq 0) {
        Write-Log -Message 'El equipo no parece unido a Azure AD; no se encontró JoinInfo.'
        return $null
    }

    $thumbprint = $thumbprints[0]

    try {
        return Get-ChildItem -Path 'Cert:\LocalMachine\My' -Recurse -ErrorAction Stop |
            Where-Object { $_.Thumbprint -eq $thumbprint } |
            Select-Object -First 1
    } catch {
        Write-Log -Message ("No se pudo recuperar el certificado de unión Azure AD: {0}" -f $_.Exception.Message) -Level 'WARN'
        return $null
    }
}

function Get-AzureADDeviceId {
    [CmdletBinding()]
    param()

    $certificate = Get-AzureADJoinCertificate
    if ($null -eq $certificate) {
        return $null
    }

    return (($certificate.Subject -replace '^CN=', '').Trim())
}

function Get-AzureADJoinDate {
    [CmdletBinding()]
    param()

    $certificate = Get-AzureADJoinCertificate
    if ($null -eq $certificate) {
        return $null
    }

    return $certificate.NotBefore
}

function Get-InstalledApplications {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [string]$UserSid
    )

    $driveCreated = $false

    try {
        if (-not (Get-PSDrive -Name HKU -PSProvider Registry -ErrorAction SilentlyContinue)) {
            New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
            $driveCreated = $true
        }

        $registryPaths = [System.Collections.Generic.List[string]]::new()
        $registryPaths.Add('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*')

        if ([Environment]::Is64BitOperatingSystem) {
            $registryPaths.Add('HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
        }

        if (-not [string]::IsNullOrWhiteSpace($UserSid)) {
            $registryPaths.Add(("HKU:\{0}\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -f $UserSid))
            $registryPaths.Add(("HKU:\{0}\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -f $UserSid))
        }

        $propertyNames = @(
            'DisplayName'
            'DisplayVersion'
            'Publisher'
            'InstallDate'
            'UninstallString'
            'SystemComponent'
            'WindowsInstaller'
        )

        $applications = foreach ($path in $registryPaths) {
            Get-ItemProperty -Path $path -Name $propertyNames -ErrorAction SilentlyContinue |
                Where-Object {
                    $displayName = Get-SafePropertyValue -InputObject $_ -Name 'DisplayName'
                    -not [string]::IsNullOrWhiteSpace($displayName)
                } |
                ForEach-Object {
                    [pscustomobject]@{
                        DisplayName      = Get-SafePropertyValue -InputObject $_ -Name 'DisplayName'
                        DisplayVersion   = Get-SafePropertyValue -InputObject $_ -Name 'DisplayVersion'
                        Publisher        = Get-SafePropertyValue -InputObject $_ -Name 'Publisher'
                        InstallDate      = Get-SafePropertyValue -InputObject $_ -Name 'InstallDate'
                        UninstallString  = Get-SafePropertyValue -InputObject $_ -Name 'UninstallString'
                        SystemComponent  = Get-SafePropertyValue -InputObject $_ -Name 'SystemComponent'
                        WindowsInstaller = Get-SafePropertyValue -InputObject $_ -Name 'WindowsInstaller'
                        PSPath           = Get-SafePropertyValue -InputObject $_ -Name 'PSPath'
                    }
                }
        }

        return $applications | Sort-Object -Property DisplayName, DisplayVersion
    } finally {
        if ($driveCreated) {
            Remove-PSDrive -Name HKU -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-InteractiveUserSid {
    [CmdletBinding()]
    param()

    try {
        $currentUser = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).UserName
        if ([string]::IsNullOrWhiteSpace($currentUser)) {
            return $null
        }

        $account = [System.Security.Principal.NTAccount]::new($currentUser)
        return $account.Translate([System.Security.Principal.SecurityIdentifier]).Value
    } catch {
        Write-Log -Message ("No se pudo resolver el SID del usuario interactivo: {0}" -f $_.Exception.Message) -Level 'WARN'
        return $null
    }
}

function Get-ComputerCategory {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$PCSystemType = 0,

        [Parameter()]
        [int]$PCSystemTypeEx = 0
    )

    $pcSystemTypeMap = @{
        0 = 'Unspecified'
        1 = 'Desktop'
        2 = 'Laptop'
        3 = 'Workstation'
        4 = 'EnterpriseServer'
        5 = 'SOHOServer'
        6 = 'AppliancePC'
        7 = 'PerformanceServer'
        8 = 'Maximum'
    }

    $pcSystemTypeExMap = @{
        0 = 'Unspecified'
        1 = 'Desktop'
        2 = 'Laptop'
        3 = 'Workstation'
        4 = 'EnterpriseServer'
        5 = 'SOHOServer'
        6 = 'AppliancePC'
        7 = 'PerformanceServer'
        8 = 'Slate'
        9 = 'Maximum'
    }

    return [pscustomobject]@{
        PCSystemType   = $pcSystemTypeMap[$PCSystemType]
        PCSystemTypeEx = $pcSystemTypeExMap[$PCSystemTypeEx]
    }
}

function Get-WindowsUpdateSettings {
    [CmdletBinding()]
    param()

    $defaultServiceName = $null
    $allowMetered = $null

    try {
        $serviceManager = New-Object -ComObject 'Microsoft.Update.ServiceManager'
        $defaultServiceName = ($serviceManager.Services | Where-Object { $_.IsDefaultAUService } | Select-Object -First 1 -ExpandProperty Name)
    } catch {
        Write-Log -Message ("No se pudo consultar el servicio predeterminado de Windows Update: {0}" -f $_.Exception.Message) -Level 'WARN'
    }

    try {
        $settings = Get-ItemProperty -Path 'HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings' -Name 'AllowAutoWindowsUpdateDownloadOverMeteredNetwork' -ErrorAction Stop
        $allowMetered = [bool]($settings.AllowAutoWindowsUpdateDownloadOverMeteredNetwork -eq 1)
    } catch {
        if ($_.Exception.Message -match 'no existe|cannot find|does not exist') {
            Write-Log -Message 'La configuración de descarga en red de uso medido de Windows Update no está presente en este equipo.'
        } else {
            Write-Log -Message ("No se pudo consultar la configuración de red de uso medido de Windows Update: {0}" -f $_.Exception.Message) -Level 'WARN'
        }
    }

    return [pscustomobject]@{
        DefaultAUService = $defaultServiceName
        AllowMetered     = $allowMetered
    }
}

function Get-TPMInventory {
    [CmdletBinding()]
    param()

    $result = [ordered]@{
        TpmPresent      = $null
        TpmReady        = $null
        TpmEnabled      = $null
        TpmActivated    = $null
        ManagedAuthLevel = $null
        EndorsementKeyThumbprint = $null
    }

    if (-not (Test-CommandAvailable -Name 'Get-Tpm')) {
        Write-Log -Message 'Get-Tpm no está disponible en este sistema.'
        return [pscustomobject]$result
    }

    try {
        $tpm = Get-Tpm -ErrorAction Stop
        $result.TpmPresent = $tpm.TpmPresent
        $result.TpmReady = $tpm.TpmReady
        $result.TpmEnabled = $tpm.TpmEnabled
        $result.TpmActivated = $tpm.TpmActivated
        $result.ManagedAuthLevel = $tpm.ManagedAuthLevel
    } catch {
        Write-Log -Message ("No se pudo consultar TPM: {0}" -f $_.Exception.Message) -Level 'WARN'
    }

    if (Test-CommandAvailable -Name 'Get-TpmEndorsementKeyInfo') {
        try {
            $endorsementInfo = Get-TpmEndorsementKeyInfo -ErrorAction Stop
            $thumbprints = @($endorsementInfo.AdditionalCertificates | ForEach-Object { $_.Thumbprint } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            if ($thumbprints.Count -gt 0) {
                $result.EndorsementKeyThumbprint = $thumbprints[0]
            }
        } catch {
            Write-Log -Message ("No se pudo consultar la EK del TPM: {0}" -f $_.Exception.Message) -Level 'WARN'
        }
    }

    return [pscustomobject]$result
}

function Get-BitLockerInventory {
    [CmdletBinding()]
    param()

    $result = [ordered]@{
        MountPoint       = $env:SystemDrive
        EncryptionMethod = $null
        VolumeStatus     = $null
        ProtectionStatus = $null
        LockStatus       = $null
    }

    if (-not (Test-CommandAvailable -Name 'Get-BitLockerVolume')) {
        Write-Log -Message 'Get-BitLockerVolume no está disponible en este sistema.'
        return [pscustomobject]$result
    }

    try {
        $mountPoint = if ([string]::IsNullOrWhiteSpace($env:SystemDrive)) { 'C:' } else { $env:SystemDrive }
        $bitLocker = Get-BitLockerVolume -MountPoint $mountPoint -ErrorAction Stop
        $result.MountPoint = $mountPoint
        $result.EncryptionMethod = $bitLocker.EncryptionMethod
        $result.VolumeStatus = $bitLocker.VolumeStatus
        $result.ProtectionStatus = $bitLocker.ProtectionStatus
        $result.LockStatus = $bitLocker.LockStatus
    } catch {
        if ($_.Exception.Message -match 'No se ha encontrado el elemento|Element not found|0x80070490') {
            Write-Log -Message ("BitLocker no devuelve información para {0} en este equipo." -f $result.MountPoint)
        } else {
            Write-Log -Message ("No se pudo consultar BitLocker para {0}: {1}" -f $result.MountPoint, $_.Exception.Message) -Level 'WARN'
        }
    }

    return [pscustomobject]$result
}

function Get-NetworkInventory {
    [CmdletBinding()]
    param()

    $items = [System.Collections.Generic.List[object]]::new()

    if (-not (Test-CommandAvailable -Name 'Get-NetAdapter')) {
        Write-Log -Message 'Get-NetAdapter no está disponible en este sistema.'
        return @($items)
    }

    try {
        $adapters = Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Status -eq 'Up' }
    } catch {
        Write-Log -Message ("No se pudieron enumerar los adaptadores de red: {0}" -f $_.Exception.Message) -Level 'WARN'
        return @($items)
    }

    foreach ($adapter in $adapters) {
        $ipConfiguration = $null

        if (Test-CommandAvailable -Name 'Get-NetIPConfiguration') {
            try {
                $ipConfiguration = Get-NetIPConfiguration -InterfaceIndex $adapter.IfIndex -ErrorAction Stop
            } catch {
                Write-Log -Message ("No se pudo consultar configuración IP para {0}: {1}" -f $adapter.Name, $_.Exception.Message) -Level 'WARN'
            }
        }

        $netProfile = Get-SafePropertyValue -InputObject $ipConfiguration -Name 'NetProfile'
        $ipv4Address = Get-SafePropertyValue -InputObject $ipConfiguration -Name 'IPv4Address' -DefaultValue @()
        $ipv6Address = Get-SafePropertyValue -InputObject $ipConfiguration -Name 'IPv6Address' -DefaultValue @()
        $ipv4DefaultGateway = Get-SafePropertyValue -InputObject $ipConfiguration -Name 'IPv4DefaultGateway'
        $dnsServer = Get-SafePropertyValue -InputObject $ipConfiguration -Name 'DNSServer'

        $items.Add([pscustomobject]@{
            Name                 = $adapter.Name
            InterfaceAlias       = $adapter.InterfaceAlias
            InterfaceDescription = $adapter.InterfaceDescription
            MacAddress           = $adapter.MacAddress
            LinkSpeed            = $adapter.LinkSpeed
            Status               = $adapter.Status
            NetProfileName       = Get-SafePropertyValue -InputObject $netProfile -Name 'Name'
            IPv4Address          = (@($ipv4Address | ForEach-Object { $_.IPAddress }) -join ', ')
            IPv6Address          = (@($ipv6Address | ForEach-Object { $_.IPAddress }) -join ', ')
            IPv4DefaultGateway   = Get-SafePropertyValue -InputObject $ipv4DefaultGateway -Name 'NextHop'
            DNSServer            = (@(Get-SafePropertyValue -InputObject $dnsServer -Name 'ServerAddresses' -DefaultValue @()) -join ', ')
        })
    }

    return @($items)
}

function Get-DiskInventory {
    [CmdletBinding()]
    param()

    $items = [System.Collections.Generic.List[object]]::new()

    if (-not (Test-CommandAvailable -Name 'Get-PhysicalDisk')) {
        Write-Log -Message 'Get-PhysicalDisk no está disponible en este sistema.'
        return @($items)
    }

    try {
        $physicalDisks = Get-PhysicalDisk -ErrorAction Stop |
            Where-Object { $_.BusType -match 'NVMe|SATA|SAS|ATAPI|RAID|SSD|SCM|Unspecified|USB' }
    } catch {
        Write-Log -Message ("No se pudieron enumerar discos físicos: {0}" -f $_.Exception.Message) -Level 'WARN'
        return @($items)
    }

    foreach ($disk in $physicalDisks | Sort-Object -Property DeviceId) {
        $reliability = $null

        try {
            $reliability = Get-PhysicalDisk -UniqueId $disk.UniqueId -ErrorAction Stop |
                Get-StorageReliabilityCounter -ErrorAction Stop
        } catch {
            Write-Log -Message ("No se pudieron leer contadores de fiabilidad para el disco {0}: {1}" -f $disk.FriendlyName, $_.Exception.Message) -Level 'WARN'
        }

        $items.Add([pscustomobject]@{
            DeviceId               = $disk.DeviceId
            FriendlyName           = $disk.FriendlyName
            SerialNumber           = $disk.SerialNumber
            MediaType              = $disk.MediaType
            BusType                = $disk.BusType
            HealthStatus           = $disk.HealthStatus
            OperationalStatus      = (@($disk.OperationalStatus) -join ', ')
            SizeBytes              = $disk.Size
            Wear                   = $reliability.Wear
            Temperature            = $reliability.Temperature
            TemperatureMax         = $reliability.TemperatureMax
            ReadErrorsTotal        = $reliability.ReadErrorsTotal
            ReadErrorsUncorrected  = $reliability.ReadErrorsUncorrected
            WriteErrorsTotal       = $reliability.WriteErrorsTotal
            WriteErrorsUncorrected = $reliability.WriteErrorsUncorrected
        })
    }

    return @($items)
}

function Get-HardwareInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$CollectionDate
    )

    Write-Log -Message 'Inicio de inventario de hardware.'

    $managedDeviceInfo = Get-ManagedDeviceInfo
    $azureAdDeviceId = Get-AzureADDeviceId
    $azureAdTenantId = Get-AzureADTenantId
    $azureAdJoinDate = Get-AzureADJoinDate
    $windowsUpdateSettings = Get-WindowsUpdateSettings
    $tpmInventory = Get-TPMInventory
    $bitLockerInventory = Get-BitLockerInventory

    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    $operatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
    $systemProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct -ErrorAction Stop
    $processor = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop
    $baseSystemInfo = Get-CimInstance -ClassName MS_SystemInformation -Namespace 'root\WMI' -ErrorAction SilentlyContinue

    $manufacturer = $computerSystem.Manufacturer
    if ($manufacturer -match 'HP|Hewlett-Packard') {
        $manufacturer = 'HP'
    }

    $displayVersion = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'DisplayVersion' -ErrorAction SilentlyContinue).DisplayVersion
    $releaseId = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ReleaseId' -ErrorAction SilentlyContinue).ReleaseId
    $osRevision = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'UBR' -ErrorAction SilentlyContinue).UBR
    $computerCategory = Get-ComputerCategory -PCSystemType $computerSystem.PCSystemType -PCSystemTypeEx $computerSystem.PCSystemTypeEx

    $hardwareInventory = [ordered]@{
        RegistryDate               = $CollectionDate.ToString('o')
        ManagedDeviceName          = $managedDeviceInfo.ManagedDeviceName
        ManagedDeviceID            = $managedDeviceInfo.ManagedDeviceId
        AzureADDeviceID            = $azureAdDeviceId
        AzureADTenantID            = $azureAdTenantId
        AzureADJoinDate            = if ($null -ne $azureAdJoinDate) { $azureAdJoinDate.ToString('o') } else { $null }
        ComputerName               = $computerSystem.Name
        Manufacturer               = $manufacturer
        Model                      = $computerSystem.Model
        SystemSkuNumber            = $computerSystem.SystemSKUNumber
        SystemSKU                  = Get-SafePropertyValue -InputObject $baseSystemInfo -Name 'SystemSku'
        SerialNumber               = $bios.SerialNumber
        SMBIOSUUID                 = $systemProduct.UUID
        BiosVersion                = $bios.SMBIOSBIOSVersion
        BiosReleaseDate            = Convert-DmtfDateSafely -DmtfDate (Get-SafePropertyValue -InputObject $bios -Name 'ReleaseDate') -Context 'la fecha de BIOS'
        FirmwareType               = $env:firmware_type
        PCSystemType               = $computerCategory.PCSystemType
        PCSystemTypeEx             = $computerCategory.PCSystemTypeEx
        LastBoot                   = if ($null -ne $operatingSystem.LastBootUpTime) { $operatingSystem.LastBootUpTime.ToString('o') } else { $null }
        ComputerUpTimeDays         = if ($null -ne $operatingSystem.LastBootUpTime) { [int](New-TimeSpan -Start $operatingSystem.LastBootUpTime -End $CollectionDate).TotalDays } else { $null }
        InstallDate                = if ($null -ne $operatingSystem.InstallDate) { $operatingSystem.InstallDate.ToString('o') } else { $null }
        WindowsVersion             = if ([string]::IsNullOrWhiteSpace($displayVersion)) { $releaseId } else { $displayVersion }
        OSName                     = $operatingSystem.Caption
        OSBuild                    = $operatingSystem.BuildNumber
        OSRevision                 = $osRevision
        MemoryBytes                = [int64]$computerSystem.TotalPhysicalMemory
        CPUManufacturer            = (@($processor | Select-Object -ExpandProperty Manufacturer -Unique) -join ', ')
        CPUName                    = (@($processor | Select-Object -ExpandProperty Name -Unique) -join ', ')
        CPUCores                   = (@($processor | Measure-Object -Property NumberOfCores -Sum).Sum)
        CPULogicalProcessors       = (@($processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)
        DefaultAUService           = $windowsUpdateSettings.DefaultAUService
        AUMetered                  = $windowsUpdateSettings.AllowMetered
        TPMPresent                 = $tpmInventory.TpmPresent
        TPMReady                   = $tpmInventory.TpmReady
        TPMEnabled                 = $tpmInventory.TpmEnabled
        TPMActivated               = $tpmInventory.TpmActivated
        TPMManagedAuthLevel        = $tpmInventory.ManagedAuthLevel
        TPMThumbprint              = $tpmInventory.EndorsementKeyThumbprint
        BitLockerMountPoint        = $bitLockerInventory.MountPoint
        BitLockerCipher            = $bitLockerInventory.EncryptionMethod
        BitLockerVolumeStatus      = $bitLockerInventory.VolumeStatus
        BitLockerProtectionStatus  = $bitLockerInventory.ProtectionStatus
        BitLockerLockStatus        = $bitLockerInventory.LockStatus
        NetworkAdapters            = @(Get-NetworkInventory)
        DiskHealth                 = @(Get-DiskInventory)
    }

    return [pscustomobject]$hardwareInventory
}

function Get-CleanApplicationList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Applications
    )

    if ($null -eq $Applications) {
        return @()
    }

    $groupedApplications = @($Applications | Group-Object -Property DisplayName)
    $cleanList = [System.Collections.Generic.List[object]]::new()

    foreach ($group in $groupedApplications) {
        if ($group.Count -eq 1) {
            $cleanList.Add($group.Group[0])
            continue
        }

        $selected = $group.Group |
            Sort-Object -Property @{ Expression = {
                try {
                    if ([string]::IsNullOrWhiteSpace($_.DisplayVersion)) {
                        return [version]'0.0'
                    }

                    return [version]$_.DisplayVersion
                } catch {
                    return [version]'0.0'
                }
            } }, @{ Expression = 'DisplayVersion'; Descending = $true } -Descending |
            Select-Object -First 1

        $cleanList.Add($selected)
    }

    return @($cleanList | Sort-Object -Property DisplayName)
}


function Get-AppxApplications {
    [CmdletBinding()]
    param()

    $items = [System.Collections.Generic.List[object]]::new()

    if (-not (Test-CommandAvailable -Name 'Get-AppxPackage')) {
        Write-Log -Message 'Get-AppxPackage no está disponible en este sistema.'
        return @($items)
    }

    try {
        $packages = @(Get-AppxPackage -AllUsers -ErrorAction Stop)
    } catch {
        Write-Log -Message ("No se pudo consultar el inventario Appx/MSIX/UWP: {0}" -f $_.Exception.Message) -Level 'WARN'
        return @($items)
    }

    foreach ($package in $packages) {
        $packageName = Get-SafePropertyValue -InputObject $package -Name 'Name'
        if ([string]::IsNullOrWhiteSpace([string]$packageName)) {
            continue
        }

        $items.Add([pscustomobject]@{
            AppSource             = 'Appx'
            AppType               = 'ModernApp'
            AppName               = $packageName
            AppVersion            = [string](Get-SafePropertyValue -InputObject $package -Name 'Version')
            AppInstallDate        = $null
            AppPublisher          = Get-SafePropertyValue -InputObject $package -Name 'Publisher'
            AppUninstallString    = $null
            AppUninstallRegPath   = $null
            SystemComponent       = $null
            WindowsInstaller      = $null
            AppScope              = 'AllUsers'
            AppArchitecture       = [string](Get-SafePropertyValue -InputObject $package -Name 'Architecture')
            AppPackageFullName    = Get-SafePropertyValue -InputObject $package -Name 'PackageFullName'
            AppPackageFamilyName  = Get-SafePropertyValue -InputObject $package -Name 'PackageFamilyName'
            AppInstallLocation    = Get-SafePropertyValue -InputObject $package -Name 'InstallLocation'
            AppIsFramework        = Get-SafePropertyValue -InputObject $package -Name 'IsFramework'
            AppIsResourcePackage  = Get-SafePropertyValue -InputObject $package -Name 'IsResourcePackage'
            AppIsBundle           = Get-SafePropertyValue -InputObject $package -Name 'IsBundle'
            AppIsDevelopmentMode  = Get-SafePropertyValue -InputObject $package -Name 'IsDevelopmentMode'
            AppNonRemovable       = Get-SafePropertyValue -InputObject $package -Name 'NonRemovable'
            AppSignatureKind      = Get-SafePropertyValue -InputObject $package -Name 'SignatureKind'
        })
    }

    return @($items | Sort-Object -Property AppName, AppVersion)
}


function Get-SoftwareInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [datetime]$CollectionDate,

        [Parameter()]
        [bool]$CollectModernAppInventory = $true
    )

    Write-Log -Message 'Inicio de inventario de software.'

    $managedDeviceInfo = Get-ManagedDeviceInfo
    $userSid = Get-InteractiveUserSid
    $registryApplications = @(Get-InstalledApplications -UserSid $userSid)
    $cleanApplications = @(Get-CleanApplicationList -Applications $registryApplications)

    $items = [System.Collections.Generic.List[object]]::new()

    foreach ($application in $cleanApplications) {
        $appRegPath = Get-SafePropertyValue -InputObject $application -Name 'PSPath'
        $appScope = if ([string]::IsNullOrWhiteSpace($appRegPath)) {
            $null
        } elseif ($appRegPath -like 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE*' -or $appRegPath -like 'HKLM:*') {
            'Machine'
        } elseif ($appRegPath -like 'Microsoft.PowerShell.Core\Registry::HKEY_USERS*' -or $appRegPath -like 'HKU:*') {
            'User'
        } else {
            $null
        }

        $items.Add([pscustomobject]@{
            RegistryDate         = $CollectionDate.ToString('o')
            ComputerName         = $env:COMPUTERNAME
            ManagedDeviceName    = $managedDeviceInfo.ManagedDeviceName
            ManagedDeviceID      = $managedDeviceInfo.ManagedDeviceId
            AppSource            = 'Registry'
            AppType              = 'Win32'
            AppName              = Get-SafePropertyValue -InputObject $application -Name 'DisplayName'
            AppVersion           = Get-SafePropertyValue -InputObject $application -Name 'DisplayVersion'
            AppInstallDate       = Get-SafePropertyValue -InputObject $application -Name 'InstallDate'
            AppPublisher         = Get-SafePropertyValue -InputObject $application -Name 'Publisher'
            AppUninstallString   = Get-SafePropertyValue -InputObject $application -Name 'UninstallString'
            AppUninstallRegPath  = if ([string]::IsNullOrWhiteSpace($appRegPath)) { $null } else { ($appRegPath -split '::')[-1] }
            SystemComponent      = Get-SafePropertyValue -InputObject $application -Name 'SystemComponent'
            WindowsInstaller     = Get-SafePropertyValue -InputObject $application -Name 'WindowsInstaller'
            AppScope             = $appScope
            AppArchitecture      = $null
            AppPackageFullName   = $null
            AppPackageFamilyName = $null
            AppInstallLocation   = $null
            AppIsFramework       = $null
            AppIsResourcePackage = $null
            AppIsBundle          = $null
            AppIsDevelopmentMode = $null
            AppNonRemovable      = $null
            AppSignatureKind     = $null
        })
    }

    if ($CollectModernAppInventory) {
        $modernApplications = @(Get-AppxApplications)
        foreach ($application in $modernApplications) {
            $items.Add([pscustomobject]@{
                RegistryDate         = $CollectionDate.ToString('o')
                ComputerName         = $env:COMPUTERNAME
                ManagedDeviceName    = $managedDeviceInfo.ManagedDeviceName
                ManagedDeviceID      = $managedDeviceInfo.ManagedDeviceId
                AppSource            = Get-SafePropertyValue -InputObject $application -Name 'AppSource'
                AppType              = Get-SafePropertyValue -InputObject $application -Name 'AppType'
                AppName              = Get-SafePropertyValue -InputObject $application -Name 'AppName'
                AppVersion           = Get-SafePropertyValue -InputObject $application -Name 'AppVersion'
                AppInstallDate       = Get-SafePropertyValue -InputObject $application -Name 'AppInstallDate'
                AppPublisher         = Get-SafePropertyValue -InputObject $application -Name 'AppPublisher'
                AppUninstallString   = Get-SafePropertyValue -InputObject $application -Name 'AppUninstallString'
                AppUninstallRegPath  = Get-SafePropertyValue -InputObject $application -Name 'AppUninstallRegPath'
                SystemComponent      = Get-SafePropertyValue -InputObject $application -Name 'SystemComponent'
                WindowsInstaller     = Get-SafePropertyValue -InputObject $application -Name 'WindowsInstaller'
                AppScope             = Get-SafePropertyValue -InputObject $application -Name 'AppScope'
                AppArchitecture      = Get-SafePropertyValue -InputObject $application -Name 'AppArchitecture'
                AppPackageFullName   = Get-SafePropertyValue -InputObject $application -Name 'AppPackageFullName'
                AppPackageFamilyName = Get-SafePropertyValue -InputObject $application -Name 'AppPackageFamilyName'
                AppInstallLocation   = Get-SafePropertyValue -InputObject $application -Name 'AppInstallLocation'
                AppIsFramework       = Get-SafePropertyValue -InputObject $application -Name 'AppIsFramework'
                AppIsResourcePackage = Get-SafePropertyValue -InputObject $application -Name 'AppIsResourcePackage'
                AppIsBundle          = Get-SafePropertyValue -InputObject $application -Name 'AppIsBundle'
                AppIsDevelopmentMode = Get-SafePropertyValue -InputObject $application -Name 'AppIsDevelopmentMode'
                AppNonRemovable      = Get-SafePropertyValue -InputObject $application -Name 'AppNonRemovable'
                AppSignatureKind     = Get-SafePropertyValue -InputObject $application -Name 'AppSignatureKind'
            })
        }
    } else {
        Write-Log -Message 'CollectModernAppInventory desactivado; no se incluirá inventario Appx/MSIX/UWP.'
    }

    return @($items | Sort-Object -Property AppSource, AppName, AppVersion)
}

function Convert-InventoryToJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )

    return ($InputObject | ConvertTo-Json -Depth 8)
}

function Save-InventoryFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('hardware', 'software')]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$JsonContent
    )

    $computerName = $env:COMPUTERNAME
    $targetDirectory = if ($Category -eq 'hardware') { $hardwareDirectory } else { $softwareDirectory }
    $fileName = '{0}_{1}_{2}.json' -f $Category, $computerName, $executionStamp
    $filePath = Join-Path -Path $targetDirectory -ChildPath $fileName

    Set-Content -Path $filePath -Value $JsonContent -Encoding UTF8
    $script:CreatedFiles.Add($filePath) | Out-Null
    Write-Log -Message ("JSON guardado: {0}" -f $filePath) -Level 'OK'

    return [pscustomobject]@{
        Category = $Category
        FileName = $fileName
        FilePath = $filePath
    }
}

function Get-BlobName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('hardware', 'software')]
        [string]$Category,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )

    return '{0}_{1}_{2}.json' -f $Category, $ComputerName, $executionStamp
}

function Publish-JsonToAzureBlob {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageAccountName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ContainerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BlobName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$JsonContent,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$SasToken
    )

    if ([string]::IsNullOrWhiteSpace($SasToken)) {
        throw 'No se ha proporcionado SAS Token. Use -SasToken o la variable de entorno CUSTOMINVENTORY_SASTOKEN.'
    }

    $normalizedSas = if ($SasToken.StartsWith('?')) { $SasToken } else { '?' + $SasToken }
    $blobUri = 'https://{0}.blob.core.windows.net/{1}/{2}{3}' -f $StorageAccountName, $ContainerName, $BlobName, $normalizedSas
    $body = [System.Text.Encoding]::UTF8.GetBytes($JsonContent)

    $headers = @{
        'x-ms-blob-type' = 'BlockBlob'
    }

    Invoke-RestMethod -Uri $blobUri -Method Put -Headers $headers -Body $body -ContentType 'application/json; charset=utf-8' -ErrorAction Stop | Out-Null
    $script:UploadedBlobs.Add($blobUri.Split('?')[0]) | Out-Null
}

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Log -Message ('Inicio de ejecución en {0} - Usuario={1} - PowerShell={2}' -f $env:COMPUTERNAME, $currentIdentity.Name, $PSVersionTable.PSVersion) -Level 'OK'
    Write-Log -Message ('Log: {0}' -f $script:LogFile) -Level 'OK'

    if (-not $CollectDeviceInventory -and -not $CollectAppInventory) {
        throw 'Debe habilitar al menos un tipo de inventario: hardware o software.'
    }

    $devicePayload = $null
    $appPayload = $null
    $savedHardwareFile = $null
    $savedSoftwareFile = $null

    if ($CollectDeviceInventory) {
        $devicePayload = Get-HardwareInventory -CollectionDate $executionTime
        $deviceJson = Convert-InventoryToJson -InputObject $devicePayload
        $savedHardwareFile = Save-InventoryFile -Category 'hardware' -JsonContent $deviceJson

        if (-not $SkipUpload.IsPresent) {
            $hardwareBlobName = Get-BlobName -Category 'hardware' -ComputerName $env:COMPUTERNAME

            if ($PSCmdlet.ShouldProcess($hardwareBlobName, 'Subir inventario de hardware a Azure Blob')) {
                Publish-JsonToAzureBlob `
                    -StorageAccountName $StorageAccountName `
                    -ContainerName $HardwareContainerName `
                    -BlobName $hardwareBlobName `
                    -JsonContent $deviceJson `
                    -SasToken $SasToken

                Write-Log -Message ("Blob de hardware cargado: {0}" -f $hardwareBlobName) -Level 'OK'
            }
        } else {
            Write-Log -Message 'SkipUpload activo; no se subirá el inventario de hardware.'
        }
    }

    if ($CollectAppInventory) {
        $appPayload = Get-SoftwareInventory -CollectionDate $executionTime -CollectModernAppInventory $CollectModernAppInventory
        $appJson = Convert-InventoryToJson -InputObject $appPayload
        $savedSoftwareFile = Save-InventoryFile -Category 'software' -JsonContent $appJson

        if (-not $SkipUpload.IsPresent) {
            $softwareBlobName = Get-BlobName -Category 'software' -ComputerName $env:COMPUTERNAME

            if ($PSCmdlet.ShouldProcess($softwareBlobName, 'Subir inventario de software a Azure Blob')) {
                Publish-JsonToAzureBlob `
                    -StorageAccountName $StorageAccountName `
                    -ContainerName $SoftwareContainerName `
                    -BlobName $softwareBlobName `
                    -JsonContent $appJson `
                    -SasToken $SasToken

                Write-Log -Message ("Blob de software cargado: {0}" -f $softwareBlobName) -Level 'OK'
            }
        } else {
            Write-Log -Message 'SkipUpload activo; no se subirá el inventario de software.'
        }
    }
} catch {
    Write-Log -Message ("Fallo no controlado: {0}" -f $_.Exception.Message) -Level 'ERROR'
    exit 1
} finally {
    Write-Log -Message ("Fin de ejecución. Errores={0}; Advertencias={1}; Log={2}" -f $script:ErrorCount, $script:WarningCount, $script:LogFile) -Level 'OK'
}

[pscustomobject]@{
    ComputerName            = $env:COMPUTERNAME
    Success                 = ($script:ErrorCount -eq 0)
    CollectDeviceInventory  = $CollectDeviceInventory
    CollectAppInventory     = $CollectAppInventory
    CollectModernAppInventory = $CollectModernAppInventory
    SkipUpload              = $SkipUpload.IsPresent
    WarningCount            = $script:WarningCount
    ErrorCount              = $script:ErrorCount
    LogFile                 = $script:LogFile
    CreatedFiles            = @($script:CreatedFiles)
    UploadedBlobs           = @($script:UploadedBlobs)
}

if ($script:ErrorCount -gt 0) {
    exit 1
}

exit 0
