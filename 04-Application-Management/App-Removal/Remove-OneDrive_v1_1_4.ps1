#Requires -Version 5.1
#Version 1.1.4
<#
.SYNOPSIS
    Elimina OneDrive de un equipo gestionado por Ivanti.

.DESCRIPTION
    Script controlador para retirar OneDrive del equipo, limpiar restos por máquina y por perfil,
    bloquear su reactivación para nuevos usuarios y registrar toda la remediación en un log.

    Por diseño, este script no borra las carpetas de datos del usuario (`OneDrive` y
    `OneDrive - *`) salvo que se especifique `-RemoveUserDataFolders`.

.PARAMETER LogRoot
    Carpeta raíz donde se crea la subcarpeta `OneDrive-Removal`.

.PARAMETER RemoveUserDataFolders
    Elimina también las carpetas de datos OneDrive presentes en los perfiles de usuario.

.EXAMPLE
    .\Remove-OneDrive-Ivanti_v4.ps1

.EXAMPLE
    .\Remove-OneDrive-Ivanti_v4.ps1 -RemoveUserDataFolders -Verbose

.OUTPUTS
    PSCustomObject
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogRoot = 'C:\ProgramData\Ivanti\Logs',

    [Parameter()]
    [switch]$RemoveUserDataFolders
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RelaunchArgumentList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$BoundParameters,

        [Parameter()]
        [object[]]$ExtraArguments = @()
    )

    $argumentList = @(
        '-NoProfile'
        '-ExecutionPolicy'
        'Bypass'
        '-File'
        $ScriptPath
    )

    foreach ($entry in $BoundParameters.GetEnumerator() | Sort-Object -Property Key) {
        $name = [string]$entry.Key
        $value = $entry.Value

        if ($value -is [System.Management.Automation.SwitchParameter] -or $value -is [bool]) {
            $argumentList += "-${name}:$([bool]$value)"
            continue
        }

        $argumentList += "-${name}"

        if ($null -eq $value) {
            continue
        }

        if ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
            $argumentList += @($value)
        } else {
            $argumentList += [string]$value
        }
    }

    if ($ExtraArguments.Count -gt 0) {
        $argumentList += $ExtraArguments
    }

    return $argumentList
}

if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    $sysNativePowerShell = Join-Path -Path $env:WINDIR -ChildPath 'SysNative\WindowsPowerShell\v1.0\powershell.exe'

    if (-not $PSCommandPath -or -not (Test-Path -LiteralPath $sysNativePowerShell)) {
        throw 'Este script debe ejecutarse en PowerShell de 64 bits. Configure Ivanti para usar PowerShell x64 o despliegue el .ps1 desde un host de 64 bits.'
    }

    $relaunchArguments = Get-RelaunchArgumentList -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters -ExtraArguments $args
    & $sysNativePowerShell @relaunchArguments
    exit $LASTEXITCODE
}

$script:ErrorCount = 0
$script:WarningCount = 0
$script:LoadedUserHives = @()
$script:PendingDeletePaths = @()
$script:RebootRecommended = $false

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logDir = Join-Path $LogRoot 'OneDrive-Removal'
New-Item -Path $logDir -ItemType Directory -Force | Out-Null
$script:LogFile = Join-Path $logDir ("Remove-OneDrive_{0}_{1}.log" -f $env:COMPUTERNAME, $timestamp)

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
        'INFO'  { Write-Information -MessageData $line -InformationAction Continue }
        'OK'    { Write-Information -MessageData $line -InformationAction Continue }
        'WARN'  { Write-Warning -Message $line }
        'ERROR' { Write-Error -Message $line -ErrorAction Continue }
    }
}


function Get-SafePropertyValue {
    param(
        [Parameter(Mandatory = $true)]$InputObject,
        [Parameter(Mandatory = $true)][string]$Name,
        $DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        return $DefaultValue
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $property) {
        return $property.Value
    }

    return $DefaultValue
}

function Get-ComparablePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    return ([string]$Path).TrimEnd('\').ToUpperInvariant()
}

function Test-PathUnderRoot {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $comparablePath = Get-ComparablePath -Path $Path
    $comparableRoot = Get-ComparablePath -Path $Root

    return ($comparablePath -eq $comparableRoot -or $comparablePath.StartsWith($comparableRoot + '\'))
}

function Test-PathCoveredByPendingDelete {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [System.Collections.IEnumerable]$PendingRoots = @()
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }

    if ($Path -notmatch '^[A-Za-z]:\\') {
        return $false
    }

    foreach ($pendingRoot in @($PendingRoots)) {
        if ([string]::IsNullOrWhiteSpace([string]$pendingRoot)) {
            continue
        }

        if (Test-PathUnderRoot -Path $Path -Root ([string]$pendingRoot)) {
            return $true
        }
    }

    return $false
}

function Get-NativeCommandPath {
    param(
        [Parameter(Mandatory = $true)][string]$Leaf
    )

    $base = Join-Path $env:WINDIR 'System32'
    return (Join-Path $base $Leaf)
}

function Invoke-ExternalProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [switch]$IgnoreExitCode
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        Write-Log -Message ("No existe el ejecutable: {0}" -f $FilePath) -Level 'WARN'
        return $null
    }

    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()

    try {
        $argText = ''
        if ($Arguments -and $Arguments.Count -gt 0) {
            $argText = (($Arguments | ForEach-Object {
                if ($_ -match '\s') { '"' + $_ + '"' } else { $_ }
            }) -join ' ')
        }

        Write-Log -Message ("Ejecutando: {0} {1}" -f $FilePath, $argText)

        $startProcessParameters = @{
            FilePath               = $FilePath
            ArgumentList           = $Arguments
            Wait                   = $true
            PassThru               = $true
            RedirectStandardOutput = $stdoutFile
            RedirectStandardError  = $stderrFile
        }

        $p = Start-Process @startProcessParameters

        $stdout = ''
        $stderr = ''

        if (Test-Path -LiteralPath $stdoutFile) {
            $stdout = ((Get-Content -LiteralPath $stdoutFile -ErrorAction SilentlyContinue) | Out-String).Trim()
        }

        if (Test-Path -LiteralPath $stderrFile) {
            $stderr = ((Get-Content -LiteralPath $stderrFile -ErrorAction SilentlyContinue) | Out-String).Trim()
        }

        if ($stdout) {
            Write-Log -Message ("STDOUT: {0}" -f $stdout)
        }

        if ($stderr) {
            Write-Log -Message ("STDERR: {0}" -f $stderr) -Level 'WARN'
        }

        if ($p.ExitCode -ne 0) {
            if ($IgnoreExitCode) {
                Write-Log -Message ("ExitCode {0} en {1}" -f $p.ExitCode, $FilePath) -Level 'WARN'
            } else {
                Write-Log -Message ("ExitCode {0} en {1}" -f $p.ExitCode, $FilePath) -Level 'ERROR'
            }
        } else {
            Write-Log -Message ("ExitCode {0} en {1}" -f $p.ExitCode, $FilePath) -Level 'OK'
        }

        return $p.ExitCode
    }
    catch {
        Write-Log -Message ("Error ejecutando {0}: {1}" -f $FilePath, $_.Exception.Message) -Level 'ERROR'
        return $null
    }
    finally {
        Remove-Item -LiteralPath $stdoutFile -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stderrFile -Force -ErrorAction SilentlyContinue
    }
}


function Clear-FileAttributes {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $attrib = Get-NativeCommandPath -Leaf 'attrib.exe'

    try {
        if (Test-Path -LiteralPath $Path -PathType Container) {
            $mask = Join-Path $Path '*'
            Invoke-ExternalProcess -FilePath $attrib -Arguments @('-R', '-S', '-H', $mask, '/S', '/D') -IgnoreExitCode | Out-Null
            Invoke-ExternalProcess -FilePath $attrib -Arguments @('-R', '-S', '-H', $Path) -IgnoreExitCode | Out-Null
        } else {
            Invoke-ExternalProcess -FilePath $attrib -Arguments @('-R', '-S', '-H', $Path) -IgnoreExitCode | Out-Null
        }
    }
    catch {
        Write-Log -Message ("No se pudieron normalizar atributos en {0}: {1}" -f $Path, $_.Exception.Message) -Level 'WARN'
    }
}

function Add-PendingDeleteEntry {
    param(
        [Parameter(Mandatory = $true)][string]$NativePath
    )

    $sessionManagerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $valueName = 'PendingFileRenameOperations'
    $existingValues = @()
    $valueExists = $false

    try {
        $currentItem = Get-ItemProperty -Path $sessionManagerPath -Name $valueName -ErrorAction Stop
        $valueExists = $true
        $currentValue = Get-SafePropertyValue -InputObject $currentItem -Name $valueName -DefaultValue @()
        if ($null -ne $currentValue) {
            $existingValues = @($currentValue)
        }
    }
    catch {
        $valueExists = $false
        $existingValues = @()
    }

    if ($existingValues -contains $NativePath) {
        return
    }

    $updatedValues = @($existingValues + $NativePath + '')

    if ($valueExists) {
        Set-ItemProperty -Path $sessionManagerPath -Name $valueName -Value $updatedValues -Force
    } else {
        New-ItemProperty -Path $sessionManagerPath -Name $valueName -PropertyType MultiString -Value $updatedValues -Force | Out-Null
    }
}

function Add-PendingDeleteOnReboot {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $scheduledItems = @()

    if (Test-Path -LiteralPath $Path -PathType Container) {
        $files = @(Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Sort-Object -Property FullName)
        $directories = @(Get-ChildItem -LiteralPath $Path -Recurse -Force -Directory -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } -Descending)

        foreach ($fileItem in $files) {
            $scheduledItems += $fileItem.FullName
        }

        foreach ($directoryItem in $directories) {
            $scheduledItems += $directoryItem.FullName
        }
    }

    $scheduledItems += $Path

    foreach ($scheduledItem in ($scheduledItems | Select-Object -Unique)) {
        $nativePath = '\??\' + ([System.IO.Path]::GetFullPath($scheduledItem))
        Add-PendingDeleteEntry -NativePath $nativePath
    }

    $script:PendingDeletePaths += $Path
    $script:PendingDeletePaths = @($script:PendingDeletePaths | Select-Object -Unique)
    $script:RebootRecommended = $true

    Write-Log -Message ("Eliminación diferida al reinicio programada para: {0}" -f $Path) -Level 'WARN'
}

function Invoke-HiveUnload {
    param(
        [Parameter(Mandatory = $true)][string]$HiveName,
        [string]$LogLabel = $HiveName
    )

    $hiveRoot = "Registry::HKEY_USERS\$HiveName"
    if (-not (Test-Path -Path $hiveRoot)) {
        return $true
    }

    $regExe = Get-NativeCommandPath -Leaf 'reg.exe'

    for ($attempt = 1; $attempt -le 5; $attempt++) {
        try {
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
        catch {
        }

        Start-Sleep -Milliseconds (300 * $attempt)
        Invoke-ExternalProcess -FilePath $regExe -Arguments @('unload', "HKU\$HiveName") -IgnoreExitCode | Out-Null
        Start-Sleep -Milliseconds 500

        if (-not (Test-Path -Path $hiveRoot)) {
            Write-Log -Message ("Hive descargado: HKU\{0}" -f $LogLabel) -Level 'OK'
            return $true
        }
    }

    Write-Log -Message ("No se pudo descargar HKU\{0} tras varios intentos." -f $LogLabel) -Level 'WARN'
    return $false
}

function Grant-DeleteRights {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $icacls = Get-NativeCommandPath -Leaf 'icacls.exe'
    Clear-FileAttributes -Path $Path

    if (Test-Path -LiteralPath $Path -PathType Container) {
        Invoke-ExternalProcess -FilePath $icacls -Arguments @($Path, '/setowner', '*S-1-5-32-544', '/T', '/C') -IgnoreExitCode | Out-Null
        Invoke-ExternalProcess -FilePath $icacls -Arguments @($Path, '/grant', '*S-1-5-32-544:F', '/T', '/C') -IgnoreExitCode | Out-Null
    } else {
        Invoke-ExternalProcess -FilePath $icacls -Arguments @($Path, '/setowner', '*S-1-5-32-544', '/C') -IgnoreExitCode | Out-Null
        Invoke-ExternalProcess -FilePath $icacls -Arguments @($Path, '/grant', '*S-1-5-32-544:F', '/C') -IgnoreExitCode | Out-Null
    }
}

function Remove-FileSystemItem {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$ForceTakeOwnership
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Log -Message ("No existe: {0}" -f $Path)
        return
    }

    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        Write-Log -Message ("Eliminado: {0}" -f $Path) -Level 'OK'
    }
    catch {
        $firstError = $_.Exception.Message
        Write-Log -Message ("Primer intento fallido al eliminar {0}: {1}" -f $Path, $firstError) -Level 'WARN'

        if ($ForceTakeOwnership) {
            try {
                Grant-DeleteRights -Path $Path
                Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
                Write-Log -Message ("Eliminado tras tomar control: {0}" -f $Path) -Level 'OK'
                return
            }
            catch {
                $secondError = $_.Exception.Message
                Write-Log -Message ("Segundo intento fallido al eliminar {0}: {1}" -f $Path, $secondError) -Level 'WARN'

                if (Test-Path -LiteralPath $Path) {
                    try {
                        Add-PendingDeleteOnReboot -Path $Path
                        Write-Log -Message ("La eliminación de {0} queda diferida al reinicio: {1}" -f $Path, $secondError) -Level 'WARN'
                        return
                    }
                    catch {
                        Write-Log -Message ("No se pudo programar la eliminación diferida de {0}: {1}" -f $Path, $_.Exception.Message) -Level 'ERROR'
                        return
                    }
                }

                return
            }
        }

        Write-Log -Message ("No se pudo eliminar {0}" -f $Path) -Level 'ERROR'
    }
}

function Remove-RegistryKeyIfExists {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Log -Message ("Clave no presente: {0}" -f $Path)
        return
    }

    try {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
        Write-Log -Message ("Clave eliminada: {0}" -f $Path) -Level 'OK'
    }
    catch {
        Write-Log -Message ("No se pudo eliminar la clave {0}: {1}" -f $Path, $_.Exception.Message) -Level 'ERROR'
    }
}

function Remove-RegistryValuesLike {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Pattern
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Log -Message ("Ruta de registro no presente: {0}" -f $Path)
        return
    }

    try {
        $props = Get-ItemProperty -Path $Path -ErrorAction Stop
        foreach ($prop in $props.PSObject.Properties) {
            if ($prop.Name -match '^PS') {
                continue
            }

            if ($prop.Name -like $Pattern) {
                try {
                    Remove-ItemProperty -Path $Path -Name $prop.Name -Force -ErrorAction Stop
                    Write-Log -Message ("Valor eliminado: {0}\{1}" -f $Path, $prop.Name) -Level 'OK'
                }
                catch {
                    Write-Log -Message ("No se pudo eliminar el valor {0}\{1}: {2}" -f $Path, $prop.Name, $_.Exception.Message) -Level 'WARN'
                }
            }
        }
    }
    catch {
        Write-Log -Message ("No se pudieron leer valores en {0}: {1}" -f $Path, $_.Exception.Message) -Level 'WARN'
    }
}

function Remove-UninstallEntries {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath
    )

    if (-not (Test-Path -Path $BasePath)) {
        Write-Log -Message ("Ruta de desinstalación no presente: {0}" -f $BasePath)
        return
    }

    foreach ($subKey in (Get-ChildItem -Path $BasePath -ErrorAction SilentlyContinue)) {
        try {
            $item = Get-ItemProperty -Path $subKey.PSPath -ErrorAction Stop
            $displayName = [string](Get-SafePropertyValue -InputObject $item -Name 'DisplayName' -DefaultValue '')
            $publisher   = [string](Get-SafePropertyValue -InputObject $item -Name 'Publisher' -DefaultValue '')

            if ([string]::IsNullOrWhiteSpace($displayName)) {
                continue
            }

            if ($displayName -like '*OneDrive*' -and ([string]::IsNullOrWhiteSpace($publisher) -or $publisher -like '*Microsoft*')) {
                try {
                    Remove-Item -Path $subKey.PSPath -Recurse -Force -ErrorAction Stop
                    Write-Log -Message ("Clave ARP eliminada: {0} ({1})" -f $displayName, $subKey.PSChildName) -Level 'OK'
                }
                catch {
                    Write-Log -Message ("No se pudo eliminar la clave ARP {0}: {1}" -f $subKey.PSChildName, $_.Exception.Message) -Level 'WARN'
                }
            }
        }
        catch {
            Write-Log -Message ("No se pudo inspeccionar {0}: {1}" -f $subKey.PSPath, $_.Exception.Message) -Level 'WARN'
        }
    }
}

function Get-UserProfiles {
    $profiles = @()
    $profileListPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

    if (-not (Test-Path -Path $profileListPath)) {
        return @()
    }

    foreach ($key in (Get-ChildItem -Path $profileListPath -ErrorAction SilentlyContinue)) {
        try {
            $sid = $key.PSChildName
            $item = Get-ItemProperty -Path $key.PSPath -ErrorAction Stop
            $profilePath = [Environment]::ExpandEnvironmentVariables([string]$item.ProfileImagePath)

            if ([string]::IsNullOrWhiteSpace($profilePath)) { continue }
            if ($sid -in @('S-1-5-18','S-1-5-19','S-1-5-20')) { continue }
            if ($profilePath -like '*\Windows\ServiceProfiles\*') { continue }

            $leaf = Split-Path -Path $profilePath -Leaf
            if ($leaf -in @('Default','Default User','Public','All Users')) { continue }

            $profiles += [pscustomobject]@{
                SID         = $sid
                ProfilePath = $profilePath
                NtUserDat   = (Join-Path $profilePath 'NTUSER.DAT')
            }
        }
        catch {
            Write-Log -Message ("No se pudo enumerar un perfil: {0}" -f $_.Exception.Message) -Level 'WARN'
        }
    }

    return ($profiles | Sort-Object -Property ProfilePath -Unique)
}

function Test-HiveLoaded {
    param(
        [Parameter(Mandatory = $true)][string]$Sid,
        [Parameter(Mandatory = $true)][string]$NtUserDat
    )

    $hiveRoot = "Registry::HKEY_USERS\$Sid"

    if (Test-Path -Path $hiveRoot) {
        return
    }

    if (-not (Test-Path -LiteralPath $NtUserDat)) {
        Write-Log -Message ("No existe NTUSER.DAT para {0}: {1}" -f $Sid, $NtUserDat) -Level 'WARN'
        return
    }

    $regExe = Get-NativeCommandPath -Leaf 'reg.exe'
    Invoke-ExternalProcess -FilePath $regExe -Arguments @('load', "HKU\$Sid", $NtUserDat) -IgnoreExitCode | Out-Null
    Start-Sleep -Milliseconds 500

    if (Test-Path -Path $hiveRoot) {
        $script:LoadedUserHives += $Sid
        Write-Log -Message ("Hive cargado: HKU\{0}" -f $Sid) -Level 'OK'
    } else {
        Write-Log -Message ("No se pudo cargar HKU\{0}" -f $Sid) -Level 'ERROR'
    }
}

function Dismount-HiveIfNeeded {
    param(
        [Parameter(Mandatory = $true)][string]$Sid
    )

    if ($script:LoadedUserHives -notcontains $Sid) {
        return
    }

    Invoke-HiveUnload -HiveName $Sid -LogLabel $Sid | Out-Null
}

function Edit-HiveRegistry {
    param(
        [Parameter(Mandatory = $true)][string]$HiveRoot,
        [Parameter(Mandatory = $true)][string]$SidTag
    )

    Write-Log -Message ("Limpieza de registro para SID {0}" -f $SidTag)

    Remove-RegistryValuesLike -Path (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Run') -Pattern '*OneDrive*'
    Remove-RegistryValuesLike -Path (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\RunOnce') -Pattern '*OneDrive*'
    Remove-RegistryValuesLike -Path (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run') -Pattern '*OneDrive*'

    Remove-RegistryKeyIfExists -Path (Join-Path $HiveRoot 'Software\Microsoft\OneDrive')
    Remove-RegistryKeyIfExists -Path (Join-Path $HiveRoot 'Software\Policies\Microsoft\OneDrive')

    Remove-UninstallEntries -BasePath (Join-Path $HiveRoot 'Software\Microsoft\Windows\CurrentVersion\Uninstall')
    Remove-UninstallEntries -BasePath (Join-Path $HiveRoot 'Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall')
}

function Invoke-ProfileFileCleanup {
    param(
        [Parameter(Mandatory = $true)][string]$ProfilePath
    )

    Write-Log -Message ("Limpieza de archivos del perfil: {0}" -f $ProfilePath)

    $localOneDriveRoot = Join-Path $ProfilePath 'AppData\Local\Microsoft\OneDrive'

    # Caso adicional contemplado:
    # Ivanti puede detectar binarios dentro de rutas versionadas como:
    #   AppData\Local\Microsoft\OneDrive\26.035.0222.0002_1\OneDrive.Sync.Service.exe
    # Se atacan explícitamente esas carpetas y el binario antes de eliminar la raíz.
    if (Test-Path -LiteralPath $localOneDriveRoot) {
        try {
            $versionedFolders = @(Get-ChildItem -LiteralPath $localOneDriveRoot -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -match '^\d{2}\.\d{3}\.\d{4}\.\d{4}(_\d+)?$'
            })

            foreach ($versionedFolder in $versionedFolders) {
                Remove-FileSystemItem -Path $versionedFolder.FullName -ForceTakeOwnership
            }
        }
        catch {
            Write-Log -Message ("No se pudieron evaluar carpetas versionadas de OneDrive en {0}: {1}" -f $ProfilePath, $_.Exception.Message) -Level 'WARN'
        }

        try {
            $syncServiceFiles = @(Get-ChildItem -LiteralPath $localOneDriveRoot -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -ieq 'OneDrive.Sync.Service.exe'
            })

            foreach ($syncServiceFile in $syncServiceFiles) {
                Remove-FileSystemItem -Path $syncServiceFile.FullName -ForceTakeOwnership
            }
        }
        catch {
            Write-Log -Message ("No se pudieron evaluar binarios OneDrive.Sync.Service.exe en {0}: {1}" -f $ProfilePath, $_.Exception.Message) -Level 'WARN'
        }
    }

    $paths = @(
        $localOneDriveRoot,
        (Join-Path $ProfilePath 'AppData\Roaming\Microsoft\OneDrive'),
        (Join-Path $ProfilePath 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'),
        (Join-Path $ProfilePath 'AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\OneDrive.lnk'),
        (Join-Path $ProfilePath 'Desktop\OneDrive.lnk')
    )

    foreach ($path in $paths) {
        Remove-FileSystemItem -Path $path -ForceTakeOwnership
    }

    if ($RemoveUserDataFolders) {
        try {
            $userDataFolders = Get-ChildItem -LiteralPath $ProfilePath -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.PSIsContainer -and ($_.Name -eq 'OneDrive' -or $_.Name -like 'OneDrive - *')
            }

            foreach ($folder in $userDataFolders) {
                Remove-FileSystemItem -Path $folder.FullName -ForceTakeOwnership
            }
        }
        catch {
            Write-Log -Message ("No se pudieron evaluar carpetas de datos OneDrive en {0}: {1}" -f $ProfilePath, $_.Exception.Message) -Level 'WARN'
        }
    }
}

function Stop-OneDriveProcesses {
    Write-Log -Message 'Deteniendo procesos de OneDrive...'

    $targetNames = @(
        'OneDrive',
        'OneDriveSetup',
        'FileCoAuth',
        'FileSyncConfig',
        'OneDriveStandaloneUpdater',
        'OneDrive.Sync.Service'
    )

    # Enumerar procesos con Get-Process. ProcessName no incluye la extensión .exe.
    $processes = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
        $targetNames -contains ([string]$_.ProcessName)
    } | Sort-Object -Property Id -Unique)

    if ($processes.Count -eq 0) {
        Write-Log -Message 'No hay procesos OneDrive en ejecución.' -Level 'INFO'
        return
    }

    foreach ($proc in $processes) {
        $procName = [string]$proc.ProcessName

        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Write-Log -Message ("Proceso detenido: {0} - PID {1}" -f $procName, $proc.Id) -Level 'OK'
        }
        catch {
            Write-Log -Message ("No se pudo detener PID {0} ({1}): {2}" -f $proc.Id, $procName, $_.Exception.Message) -Level 'WARN'
        }
    }
}

function Get-TaskActionText {
    param(
        [object[]]$Actions
    )

    $actionParts = @()

    foreach ($action in @($Actions)) {
        if ($null -eq $action) {
            continue
        }

        $values = @()

        foreach ($propertyName in @('Execute', 'Arguments', 'ClassId', 'ComHandlerClassId', 'WorkingDirectory')) {
            $propertyValue = Get-SafePropertyValue -InputObject $action -Name $propertyName -DefaultValue $null
            if (-not [string]::IsNullOrWhiteSpace([string]$propertyValue)) {
                $values += [string]$propertyValue
            }
        }

        if ($values.Count -eq 0) {
            try {
                $renderedAction = (($action | Out-String).Trim())
                if (-not [string]::IsNullOrWhiteSpace($renderedAction)) {
                    $values += $renderedAction
                }
            }
            catch {
            }
        }

        if ($values.Count -gt 0) {
            $actionParts += ($values -join ' ')
        }
    }

    return ($actionParts -join ' ')
}

function Remove-OneDriveScheduledTasks {
    Write-Log -Message 'Buscando tareas programadas de OneDrive...'

    if (-not (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        Write-Log -Message 'Get-ScheduledTask no está disponible en este sistema.' -Level 'WARN'
        return
    }

    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
            $actionText = Get-TaskActionText -Actions $_.Actions
            ($_.TaskName -match 'OneDrive') -or
            ($_.TaskPath -match 'OneDrive') -or
            ($actionText -match 'OneDrive|FileCoAuth|FileSyncConfig|OneDrive\.Sync\.Service')
        }

        foreach ($task in $tasks) {
            try {
                Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue | Out-Null
            }
            catch {
            }

            try {
                Unregister-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -Confirm:$false -ErrorAction Stop
                Write-Log -Message ("Tarea eliminada: {0}{1}" -f $task.TaskPath, $task.TaskName) -Level 'OK'
            }
            catch {
                Write-Log -Message ("No se pudo eliminar la tarea {0}{1}: {2}" -f $task.TaskPath, $task.TaskName, $_.Exception.Message) -Level 'WARN'
            }
        }
    }
    catch {
        Write-Log -Message ("Error buscando tareas programadas: {0}" -f $_.Exception.Message) -Level 'WARN'
    }
}

function Remove-OneDriveServices {
    Write-Log -Message 'Buscando servicios relacionados con OneDrive...'

    try {
        $services = Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue | Where-Object {
            ($_.Name -match 'OneDrive') -or
            ($_.DisplayName -match 'OneDrive') -or
            ($_.PathName -match 'OneDrive')
        }

        $sc = Get-NativeCommandPath -Leaf 'sc.exe'

        foreach ($svc in $services) {
            try {
                if ($svc.State -ne 'Stopped') {
                    Invoke-CimMethod -InputObject $svc -MethodName StopService -ErrorAction SilentlyContinue | Out-Null
                    Start-Sleep -Milliseconds 500
                }
            }
            catch {
                Write-Log -Message ("No se pudo detener el servicio {0}: {1}" -f $svc.Name, $_.Exception.Message) -Level 'WARN'
            }

            Invoke-ExternalProcess -FilePath $sc -Arguments @('delete', $svc.Name) -IgnoreExitCode | Out-Null
            Write-Log -Message ("Intento de eliminación del servicio: {0}" -f $svc.Name)
        }
    }
    catch {
        Write-Log -Message ("Error buscando servicios: {0}" -f $_.Exception.Message) -Level 'WARN'
    }
}

function Set-OneDriveBlockPolicy {
    $policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'

    try {
        if (-not (Test-Path -Path $policyPath)) {
            New-Item -Path $policyPath -Force | Out-Null
        }

        New-ItemProperty -Path $policyPath -Name 'DisableFileSyncNGSC' -Value 1 -PropertyType DWord -Force | Out-Null
        Write-Log -Message 'Aplicada política de bloqueo: HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive\DisableFileSyncNGSC = 1' -Level 'OK'
    }
    catch {
        Write-Log -Message ("No se pudo aplicar la política de bloqueo: {0}" -f $_.Exception.Message) -Level 'ERROR'
    }
}

function Invoke-OneDriveMachineUninstall {
    Write-Log -Message 'Intentando desinstalación a nivel de máquina con OneDriveSetup.exe...'

    $programFiles = [Environment]::GetFolderPath('ProgramFiles')
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')

    $candidates = @(
        (Join-Path $env:WINDIR 'System32\OneDriveSetup.exe'),
        (Join-Path $env:WINDIR 'SysWOW64\OneDriveSetup.exe'),
        (Join-Path $programFiles 'Microsoft OneDrive\OneDriveSetup.exe')
    )

    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $candidates += (Join-Path $programFilesX86 'Microsoft OneDrive\OneDriveSetup.exe')
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $candidate) {
            Write-Log -Message ("Ejecutando uninstall: {0}" -f $candidate)
            $exitCode = Invoke-ExternalProcess -FilePath $candidate -Arguments @('/uninstall') -IgnoreExitCode

            if ($null -ne $exitCode -and $exitCode -ne 0) {
                Write-Log -Message ("OneDriveSetup.exe devolvió {0}; se continuará con la limpieza forzada." -f $exitCode) -Level 'WARN'
            }
        }
    }
}

function Remove-MachineRegistry {
    Write-Log -Message 'Limpiando registro a nivel de máquina...'

    Remove-RegistryValuesLike -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Pattern '*OneDrive*'
    Remove-RegistryValuesLike -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' -Pattern '*OneDrive*'
    Remove-RegistryValuesLike -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' -Pattern '*OneDrive*'
    Remove-RegistryValuesLike -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce' -Pattern '*OneDrive*'

    Remove-UninstallEntries -BasePath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    Remove-UninstallEntries -BasePath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

    Remove-RegistryKeyIfExists -Path 'HKLM:\SOFTWARE\Microsoft\OneDrive'
    Remove-RegistryKeyIfExists -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive'
}

function Invoke-DefaultProfileTemplate {
    $defaultProfilePath = Join-Path $env:SystemDrive 'Users\Default'
    $defaultNtUserDat = Join-Path $defaultProfilePath 'NTUSER.DAT'
    $tempHiveName = 'ODR_Default_Template'
    $tempHiveRoot = "Registry::HKEY_USERS\$tempHiveName"

    Write-Log -Message 'Procesando perfil Default...'

    if (Test-Path -LiteralPath $defaultNtUserDat) {
        if (-not (Test-Path -Path $tempHiveRoot)) {
            $regExe = Get-NativeCommandPath -Leaf 'reg.exe'
            Invoke-ExternalProcess -FilePath $regExe -Arguments @('load', "HKU\$tempHiveName", $defaultNtUserDat) -IgnoreExitCode | Out-Null
            Start-Sleep -Milliseconds 500
        }

        if (Test-Path -Path $tempHiveRoot) {
            try {
                Edit-HiveRegistry -HiveRoot $tempHiveRoot -SidTag 'DefaultTemplate'
            }
            finally {
                Invoke-HiveUnload -HiveName $tempHiveName -LogLabel $tempHiveName | Out-Null
            }
        } else {
            Write-Log -Message 'No se pudo cargar el hive del perfil Default.' -Level 'WARN'
        }
    } else {
        Write-Log -Message ("No existe NTUSER.DAT en perfil Default: {0}" -f $defaultNtUserDat) -Level 'WARN'
    }

    if (Test-Path -LiteralPath $defaultProfilePath) {
        Invoke-ProfileFileCleanup -ProfilePath $defaultProfilePath
    }
}

function Remove-MachineFiles {
    Write-Log -Message 'Eliminando archivos y carpetas a nivel de máquina...'

    $programFiles = [Environment]::GetFolderPath('ProgramFiles')
    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    $commonAppData = [Environment]::GetFolderPath('CommonApplicationData')

    $paths = @(
        (Join-Path $programFiles 'Microsoft OneDrive'),
        (Join-Path $commonAppData 'Microsoft OneDrive'),
        (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\OneDrive.lnk'),
        (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs\Startup\OneDrive.lnk'),
        (Join-Path $env:PUBLIC 'Desktop\OneDrive.lnk'),
        (Join-Path $env:WINDIR 'System32\OneDriveSetup.exe'),
        (Join-Path $env:WINDIR 'SysWOW64\OneDriveSetup.exe')
    )

    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $paths += (Join-Path $programFilesX86 'Microsoft OneDrive')
    }

    foreach ($path in ($paths | Select-Object -Unique)) {
        Remove-FileSystemItem -Path $path -ForceTakeOwnership
    }
}

function Test-RemainingOneDriveEvidence {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Profiles
    )

    #  Nunca devolverá null
    $remaining = @()

    try {
        $programFiles = [Environment]::GetFolderPath('ProgramFiles')
        $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
        $commonAppData = [Environment]::GetFolderPath('CommonApplicationData')
    }
    catch {
        # Esto nunca debería fallar, pero protege ante casos extremos
        return @("Error obteniendo rutas de sistema: $($_.Exception.Message)")
    }

    #
    #  Verificación de política OneDrive bloqueado
    #
    try {
        $policyParameters = @{
            Path        = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'
            Name        = 'DisableFileSyncNGSC'
            ErrorAction = 'Stop'
        }
        $policy = Get-ItemProperty @policyParameters

        if ($policy.DisableFileSyncNGSC -ne 1) {
            $remaining += 'Policy HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive\DisableFileSyncNGSC != 1'
        }
    }
    catch {
        $remaining += 'Policy HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive\DisableFileSyncNGSC no legible'
    }

    #
    #  Construcción segura de rutas
    #
    $checkPaths = @(
        (Join-Path $programFiles 'Microsoft OneDrive'),
        (Join-Path $commonAppData 'Microsoft OneDrive'),
        (Join-Path $env:WINDIR 'System32\OneDriveSetup.exe'),
        (Join-Path $env:WINDIR 'SysWOW64\OneDriveSetup.exe')
    )

    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $checkPaths += (Join-Path $programFilesX86 'Microsoft OneDrive')
    }

    #
    #  Rutas por usuario (siempre protegido)
    #
    foreach ($userProfile in $Profiles) {
        try {
            if ($userProfile.ProfilePath) {
                $checkPaths += (Join-Path $userProfile.ProfilePath 'AppData\Local\Microsoft\OneDrive')
            }
        }
        catch {
            $remaining += "Error generando rutas para perfil $($userProfile.SID): $($_.Exception.Message)"
        }
    }

    #
    #  Default Profile
    #
    $defaultProfileOneDrive = 'C:\Users\Default\AppData\Local\Microsoft\OneDrive'
    $checkPaths += $defaultProfileOneDrive

    #
    #  Comprobación segura de rutas
    #
    foreach ($checkPath in ($checkPaths | Select-Object -Unique)) {
        try {
            if ($checkPath -and (Test-Path -LiteralPath $checkPath)) {
                $remaining += $checkPath
            }
        }
        catch {
            $remaining += "Error evaluando ruta: $checkPath"
        }
    }

    #
    #  Caso adicional: evidencias concretas de OneDrive.Sync.Service.exe
    #  en carpetas versionadas por usuario: ...\AppData\Local\Microsoft\OneDrive\<version>_n\
    #
    foreach ($userProfile in $Profiles) {
        try {
            if (-not $userProfile.ProfilePath) {
                continue
            }

            $localOneDriveRoot = Join-Path $userProfile.ProfilePath 'AppData\Local\Microsoft\OneDrive'
            if (-not (Test-Path -LiteralPath $localOneDriveRoot)) {
                continue
            }

            $syncServiceFiles = @(Get-ChildItem -LiteralPath $localOneDriveRoot -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -ieq 'OneDrive.Sync.Service.exe'
            })

            foreach ($syncServiceFile in $syncServiceFiles) {
                $remaining += $syncServiceFile.FullName
            }
        }
        catch {
            $remaining += "Error buscando OneDrive.Sync.Service.exe en $($userProfile.ProfilePath): $($_.Exception.Message)"
        }
    }

    try {
        if (Test-Path -LiteralPath $defaultProfileOneDrive) {
            $defaultSyncServiceFiles = @(Get-ChildItem -LiteralPath $defaultProfileOneDrive -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -ieq 'OneDrive.Sync.Service.exe'
            })

            foreach ($defaultSyncServiceFile in $defaultSyncServiceFiles) {
                $remaining += $defaultSyncServiceFile.FullName
            }
        }
    }
    catch {
        $remaining += "Error buscando OneDrive.Sync.Service.exe en perfil Default: $($_.Exception.Message)"
    }

    #
    #  Resto de claves de registro de OneDrive
    #
    foreach ($path in @(
        'HKLM:\SOFTWARE\Microsoft\OneDrive',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive'
    )) {
        try {
            if (Test-Path -Path $path) {
                $remaining += "Registry::$path"
            }
        }
        catch {
            $remaining += "Error leyendo clave: $path"
        }
    }

    #
    #  Resto de ARP
    #
    foreach ($base in @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )) {
        try {
            if (Test-Path -Path $base) {
                foreach ($sub in (Get-ChildItem -Path $base -ErrorAction SilentlyContinue)) {
                    try {
                        $item = Get-ItemProperty -Path $sub.PSPath -ErrorAction Stop
                        $displayName = [string](Get-SafePropertyValue -InputObject $item -Name 'DisplayName' -DefaultValue '')

                        if ($displayName -like '*OneDrive*') {
                            $remaining += "ARP::$displayName::$($sub.PSChildName)"
                        }
                    }
                    catch {
                        # Error normal al leer subclaves incompletas
                        continue
                    }
                }
            }
        }
        catch {
            $remaining += "Error recorriendo ARP en $base"
        }
    }

    #
    #  SIEMPRE devolver un array, aunque esté vacío
    #
    return @($remaining | Sort-Object -Unique)
}

# -----------------------------
# Main
# -----------------------------
try {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $currentPrincipal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)

    if (-not ($currentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -or $currentIdentity.Name -eq 'NT AUTHORITY\SYSTEM')) {
        throw 'Este script necesita privilegios de administrador o SYSTEM.'
    }

    Write-Log -Message ('Inicio de ejecución en {0} - Usuario={1} - PowerShell={2}' -f $env:COMPUTERNAME, $currentIdentity.Name, $PSVersionTable.PSVersion.ToString()) -Level 'OK'
    Write-Log -Message ('Log: {0}' -f $script:LogFile) -Level 'OK'

    if (-not $RemoveUserDataFolders) {
        Write-Log -Message 'No se eliminarán carpetas de datos OneDrive de los perfiles de usuario (OneDrive / OneDrive - *). Solo binarios, setup, cache, ARP y registro.'
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Aplicar política de bloqueo de OneDrive')) {
        Set-OneDriveBlockPolicy
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Detener procesos de OneDrive')) {
        Stop-OneDriveProcesses
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Eliminar tareas programadas de OneDrive')) {
        Remove-OneDriveScheduledTasks
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Eliminar servicios relacionados con OneDrive')) {
        Remove-OneDriveServices
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Ejecutar desinstalación de OneDrive a nivel de máquina')) {
        Invoke-OneDriveMachineUninstall
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Reintentar parada de procesos OneDrive')) {
        Start-Sleep -Seconds 2
        Stop-OneDriveProcesses
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Limpiar registro a nivel de máquina')) {
        Remove-MachineRegistry
    }

    $profiles = Get-UserProfiles
    Write-Log -Message ("Perfiles detectados para limpieza: {0}" -f ($profiles.Count))

    foreach ($userProfile in $profiles) {
        Write-Log -Message ("Procesando perfil {0} - SID {1}" -f $userProfile.ProfilePath, $userProfile.SID)

        if ($PSCmdlet.ShouldProcess($userProfile.ProfilePath, 'Limpiar registro del perfil')) {
            try {
                Test-HiveLoaded -Sid $userProfile.SID -NtUserDat $userProfile.NtUserDat
                $hiveRoot = "Registry::HKEY_USERS\$($userProfile.SID)"
                if (Test-Path -Path $hiveRoot) {
                    Edit-HiveRegistry -HiveRoot $hiveRoot -SidTag $userProfile.SID
                } else {
                    Write-Log -Message ("No se pudo acceder al hive HKU\{0}" -f $userProfile.SID) -Level 'WARN'
                }
            }
            catch {
                Write-Log -Message ("Error limpiando registro del perfil {0}: {1}" -f $userProfile.ProfilePath, $_.Exception.Message) -Level 'WARN'
            }
        }

        if ($PSCmdlet.ShouldProcess($userProfile.ProfilePath, 'Limpiar archivos del perfil')) {
            try {
                Invoke-ProfileFileCleanup -ProfilePath $userProfile.ProfilePath
            }
            catch {
                Write-Log -Message ("Error limpiando archivos del perfil {0}: {1}" -f $userProfile.ProfilePath, $_.Exception.Message) -Level 'WARN'
            }
        }
    }

    if ($PSCmdlet.ShouldProcess('C:\Users\Default', 'Limpiar perfil Default')) {
        Invoke-DefaultProfileTemplate
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Eliminar archivos y accesos directos a nivel de máquina')) {
        Remove-MachineFiles
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Parada final de procesos OneDrive')) {
        Stop-OneDriveProcesses
    }

    if ($WhatIfPreference) {
        Write-Log -Message 'Modo WhatIf: se omite la validación final de evidencias porque no se aplicaron cambios.' -Level 'INFO'
    } else {
        $remaining = @(Test-RemainingOneDriveEvidence -Profiles $profiles)
        $hardRemaining = @()
        $pendingRemaining = @()

        foreach ($item in $remaining) {
            if (Test-PathCoveredByPendingDelete -Path $item -PendingRoots $script:PendingDeletePaths) {
                $pendingRemaining += $item
            } else {
                $hardRemaining += $item
            }
        }

        if ($hardRemaining.Count -gt 0) {
            Write-Log -Message 'Quedan restos de OneDrive tras la remediación.' -Level 'WARN'
            foreach ($item in $hardRemaining) {
                Write-Log -Message ("Resto detectado: {0}" -f $item) -Level 'WARN'
            }

            if ($script:ErrorCount -eq 0) {
                $script:ErrorCount = 1
            }
        } elseif ($pendingRemaining.Count -gt 0) {
            Write-Log -Message 'Solo quedan restos bloqueados cuya eliminación se ha diferido al reinicio.' -Level 'WARN'
            foreach ($item in $pendingRemaining) {
                Write-Log -Message ("Resto diferido a reinicio: {0}" -f $item) -Level 'WARN'
            }
        } else {
            Write-Log -Message 'No se detectan restos principales de OneDrive en archivos ni ARP. La política de bloqueo está aplicada.' -Level 'OK'
        }
    }
}
catch {
    Write-Log -Message ("Fallo no controlado: {0}" -f $_.Exception.Message) -Level 'ERROR'
}
finally {
    foreach ($sid in ($script:LoadedUserHives | Select-Object -Unique)) {
        try {
            Dismount-HiveIfNeeded -Sid $sid
        }
        catch {
            Write-Log -Message ("Error al descargar HKU\{0}: {1}" -f $sid, $_.Exception.Message) -Level 'WARN'
        }
    }

    if ($script:RebootRecommended) {
        Write-Log -Message 'Se recomienda reiniciar el equipo para completar la eliminación de archivos OneDrive que estaban bloqueados.' -Level 'WARN'
    }

    Write-Log -Message ("Fin de ejecución. Errores={0}; Advertencias={1}; Log={2}" -f $script:ErrorCount, $script:WarningCount, $script:LogFile) -Level 'OK'
}

$result = [pscustomobject]@{
    ComputerName       = $env:COMPUTERNAME
    Success            = ($script:ErrorCount -eq 0)
    WhatIf             = [bool]$WhatIfPreference
    ErrorCount         = $script:ErrorCount
    WarningCount       = $script:WarningCount
    RebootRecommended  = $script:RebootRecommended
    PendingDeletePaths = @($script:PendingDeletePaths | Select-Object -Unique)
    LogFile            = $script:LogFile
}

$result

if ($script:ErrorCount -gt 0) {
    exit 1
}

exit 0
