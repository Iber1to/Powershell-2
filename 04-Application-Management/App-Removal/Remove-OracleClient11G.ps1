#Requires -Version 5.1
<#
.SYNOPSIS
    Desinstala Oracle Client 11G y limpia restos locales de la instalación.

.DESCRIPTION
    Script controlador para ejecutar el desinstalador nativo localizado bajo C:\app, esperar la
    finalización real del proceso, validar evidencias mínimas de finalización y completar la limpieza
    posterior de archivos, servicios, claves de registro y bibliotecas residuales.

    El script está pensado para ejecución silenciosa con privilegios elevados o como NT AUTHORITY\SYSTEM.
    Registra todas las acciones en un archivo de log y devuelve un objeto estructurado al finalizar.

    Importante:
    - La búsqueda del desinstalador se limita a C:\app y localiza cualquier ruta que termine en
      \deinstall\deinstall.bat.
    - El código de salida del wrapper de Oracle no se usa como único criterio de éxito. El script espera
      el fin del proceso lanzado y valida evidencias antes de continuar con la limpieza dura.
    - Para la desregistración de oraociei12.dll se utiliza regsvr32.exe porque PowerShell no dispone de un
      cmdlet nativo equivalente para ese propósito.

.PARAMETER SearchRoot
    Ruta raíz donde se buscará el desinstalador de Oracle.

.PARAMETER LogRoot
    Carpeta raíz donde se creará la subcarpeta de logs.

.PARAMETER UninstallTimeoutSeconds
    Tiempo máximo de espera para la fase de desinstalación por cada Oracle Home localizado.

.PARAMETER WorldShipSearchDrives
    Lista de unidades donde se buscarán carpetas *Worldship*. Si no se especifica, se usarán las
    unidades fijas locales detectadas.

.EXAMPLE
    .\Remove-OracleClient11G.ps1

.EXAMPLE
    .\Remove-OracleClient11G.ps1 -Verbose

.EXAMPLE
    .\Remove-OracleClient11G.ps1 -WhatIf

.OUTPUTS
    PSCustomObject
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SearchRoot = 'C:\app',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogRoot = 'C:\ProgramData\OracleClientRemoval\Logs',

    [Parameter()]
    [ValidateRange(60, 7200)]
    [int]$UninstallTimeoutSeconds = 1800,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string[]]$WorldShipSearchDrives
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ConfirmPreference = 'None'

$script:ErrorCount = 0
$script:WarningCount = 0
$script:RebootRecommended = $false
$script:PendingDeletePaths = @()
$script:LogFile = $null

$script:ExceptionComputerNames = @(
    '09700OPT015',
    '09700OPT018',
    '09700OPT019',
    '09700OPT025',
    '09700OPT034',
    '09700OPT049',
    '09700OPT056',
    '09700OPT057',
    '09700OPT073',
    '09700OPT092',
    '09700OPT281',
    '09700OPT353',
    '09700OPT357',
    '09700OPT383',
    '09700OPT416',
    '09700OPT479',
    '09700OPT508',
    '09700OPT509',
    '09700OPT621',
    '09700OPT735',
    '09700OPT741',
    '09700OPT748',
    '09700OPT757',
    '09725OPT001',
    '09725OPT004',
    '09725OPT007',
    '09725OPT008',
    '09725OPT011',
    '09725OPT014',
    '09725OPT017',
    '09725OPT019',
    '09725OPT020',
    '09725OPT023',
    '09725OPT024',
    '09725OPT025',
    '09725OPT027'
)


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

    foreach ($entry in ($BoundParameters.GetEnumerator() | Sort-Object -Property Key)) {
        $name = [string]$entry.Key
        $value = $entry.Value

        if ($value -is [System.Management.Automation.SwitchParameter] -or $value -is [bool]) {
            $argumentList += "-$($name):$([bool]$value)"
            continue
        }

        $argumentList += "-$name"

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

    $argumentList
}


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
}


function Get-NativeCommandPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Leaf
    )

    Join-Path -Path (Join-Path -Path $env:WINDIR -ChildPath 'System32') -ChildPath $Leaf
}


function Get-ComparablePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    ([string]$Path).TrimEnd('\').ToUpperInvariant()
}


function Test-PathUnderRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Root
    )

    $comparablePath = Get-ComparablePath -Path $Path
    $comparableRoot = Get-ComparablePath -Path $Root

    ($comparablePath -eq $comparableRoot -or $comparablePath.StartsWith($comparableRoot + '\'))
}


function Test-PathCoveredByPendingDelete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter()]
        [System.Collections.IEnumerable]$PendingRoots = @()
    )

    foreach ($pendingRoot in @($PendingRoots)) {
        if ([string]::IsNullOrWhiteSpace([string]$pendingRoot)) {
            continue
        }

        if (Test-PathUnderRoot -Path $Path -Root ([string]$pendingRoot)) {
            $true
            return
        }
    }

    $false
}


function Get-SafePropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        $DefaultValue = $null
    )

    if ($null -eq $InputObject) {
        $DefaultValue
        return
    }

    $property = $InputObject.PSObject.Properties[$Name]
    if ($null -ne $property) {
        $property.Value
        return
    }

    $DefaultValue
}


function Invoke-ExternalProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter()]
        [string[]]$Arguments = @(),

        [Parameter()]
        [switch]$IgnoreExitCode,

        [Parameter()]
        [int]$TimeoutSeconds = 0
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        Write-Log -Message ("No existe el ejecutable: {0}" -f $FilePath) -Level 'WARN'
        $null
        return
    }

    $stdoutFile = [System.IO.Path]::GetTempFileName()
    $stderrFile = [System.IO.Path]::GetTempFileName()

    try {
        $argumentText = ''
        if ($Arguments.Count -gt 0) {
            $argumentText = (($Arguments | ForEach-Object {
                if ($_ -match '\s') {
                    '"{0}"' -f $_
                } else {
                    $_
                }
            }) -join ' ')
        }

        $displayCommand = ("Ejecutando: {0} {1}" -f $FilePath, $argumentText).TrimEnd()
        Write-Log -Message $displayCommand

        $startParameters = @{
            FilePath               = $FilePath
            ArgumentList           = $Arguments
            PassThru               = $true
            RedirectStandardOutput = $stdoutFile
            RedirectStandardError  = $stderrFile
            WindowStyle            = 'Hidden'
        }

        $processInfo = Start-Process @startParameters

        if ($TimeoutSeconds -gt 0) {
            $finished = $processInfo.WaitForExit($TimeoutSeconds * 1000)
            if (-not $finished) {
                try {
                    Stop-Process -Id $processInfo.Id -Force -ErrorAction Stop
                }
                catch {
                }

                Write-Log -Message ("Timeout agotado para {0} tras {1} segundos." -f $FilePath, $TimeoutSeconds) -Level 'ERROR'
                [pscustomobject]@{
                    ExitCode = $null
                    TimedOut = $true
                    StdOut   = ''
                    StdErr   = ''
                    Id       = $processInfo.Id
                }
                return
            }
        } else {
            $processInfo.WaitForExit()
        }

        $stdOut = ''
        $stdErr = ''

        if (Test-Path -LiteralPath $stdoutFile) {
            $stdOut = ((Get-Content -LiteralPath $stdoutFile -ErrorAction SilentlyContinue) | Out-String).Trim()
        }

        if (Test-Path -LiteralPath $stderrFile) {
            $stdErr = ((Get-Content -LiteralPath $stderrFile -ErrorAction SilentlyContinue) | Out-String).Trim()
        }

        if ($stdOut) {
            Write-Log -Message ("STDOUT: {0}" -f $stdOut)
        }

        if ($stdErr) {
            Write-Log -Message ("STDERR: {0}" -f $stdErr) -Level 'WARN'
        }

        $exitCode = $null
        try {
            $processInfo.Refresh()
            $exitCode = $processInfo.ExitCode
        }
        catch {
            $exitCode = $null
        }

        if ($null -eq $exitCode) {
            Write-Log -Message ("No se pudo recuperar el ExitCode de {0}" -f $FilePath) -Level 'WARN'
        } elseif ($exitCode -ne 0) {
            if ($IgnoreExitCode) {
                Write-Log -Message ("ExitCode {0} en {1}" -f $exitCode, $FilePath) -Level 'WARN'
            } else {
                Write-Log -Message ("ExitCode {0} en {1}" -f $exitCode, $FilePath) -Level 'ERROR'
            }
        } else {
            Write-Log -Message ("ExitCode {0} en {1}" -f $exitCode, $FilePath) -Level 'OK'
        }

        [pscustomobject]@{
            ExitCode = $exitCode
            TimedOut = $false
            StdOut   = $stdOut
            StdErr   = $stdErr
            Id       = $processInfo.Id
        }
    }
    catch {
        Write-Log -Message ("Error ejecutando {0}: {1}" -f $FilePath, $_.Exception.Message) -Level 'ERROR'
        $null
    }
    finally {
        Remove-Item -LiteralPath $stdoutFile -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stderrFile -Force -ErrorAction SilentlyContinue
    }
}


function Clear-FileAttributes {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $attribExe = Get-NativeCommandPath -Leaf 'attrib.exe'

    try {
        if (Test-Path -LiteralPath $Path -PathType Container) {
            $mask = Join-Path -Path $Path -ChildPath '*'
            Invoke-ExternalProcess -FilePath $attribExe -Arguments @('-R', '-S', '-H', $mask, '/S', '/D') -IgnoreExitCode | Out-Null
            Invoke-ExternalProcess -FilePath $attribExe -Arguments @('-R', '-S', '-H', $Path) -IgnoreExitCode | Out-Null
        } else {
            Invoke-ExternalProcess -FilePath $attribExe -Arguments @('-R', '-S', '-H', $Path) -IgnoreExitCode | Out-Null
        }
    }
    catch {
        Write-Log -Message ("No se pudieron normalizar atributos en {0}: {1}" -f $Path, $_.Exception.Message) -Level 'WARN'
    }
}


function Add-PendingDeleteEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$NativePath
    )

    $sessionManagerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $valueName = 'PendingFileRenameOperations'
    $currentValues = @()
    $valueExists = $false

    try {
        $item = Get-ItemProperty -Path $sessionManagerPath -Name $valueName -ErrorAction Stop
        $valueExists = $true
        $currentValue = Get-SafePropertyValue -InputObject $item -Name $valueName -DefaultValue @()
        if ($null -ne $currentValue) {
            $currentValues = @($currentValue)
        }
    }
    catch {
        $valueExists = $false
        $currentValues = @()
    }

    if ($currentValues -contains $NativePath) {
        return
    }

    $updatedValues = @($currentValues + $NativePath + '')

    if ($valueExists) {
        Set-ItemProperty -Path $sessionManagerPath -Name $valueName -Value $updatedValues -Force
    } else {
        New-ItemProperty -Path $sessionManagerPath -Name $valueName -PropertyType MultiString -Value $updatedValues -Force | Out-Null
    }
}


function Add-PendingDeleteOnReboot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $scheduledItems = @()

    if (Test-Path -LiteralPath $Path -PathType Container) {
        $fileItems = @(Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Sort-Object -Property FullName)
        $directoryItems = @(Get-ChildItem -LiteralPath $Path -Recurse -Force -Directory -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending)

        foreach ($fileItem in $fileItems) {
            $scheduledItems += $fileItem.FullName
        }

        foreach ($directoryItem in $directoryItems) {
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


function Grant-DeleteRights {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $icaclsExe = Get-NativeCommandPath -Leaf 'icacls.exe'
    Clear-FileAttributes -Path $Path

    if (Test-Path -LiteralPath $Path -PathType Container) {
        Invoke-ExternalProcess -FilePath $icaclsExe -Arguments @($Path, '/setowner', '*S-1-5-32-544', '/T', '/C') -IgnoreExitCode | Out-Null
        Invoke-ExternalProcess -FilePath $icaclsExe -Arguments @($Path, '/grant', '*S-1-5-32-544:F', '/T', '/C') -IgnoreExitCode | Out-Null
    } else {
        Invoke-ExternalProcess -FilePath $icaclsExe -Arguments @($Path, '/setowner', '*S-1-5-32-544', '/C') -IgnoreExitCode | Out-Null
        Invoke-ExternalProcess -FilePath $icaclsExe -Arguments @($Path, '/grant', '*S-1-5-32-544:F', '/C') -IgnoreExitCode | Out-Null
    }
}


function Remove-FileSystemItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter()]
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
        Write-Log -Message ("Primer intento fallido al eliminar {0}: {1}" -f $Path, $_.Exception.Message) -Level 'WARN'

        if ($ForceTakeOwnership) {
            try {
                Grant-DeleteRights -Path $Path
                Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
                Write-Log -Message ("Eliminado tras tomar control: {0}" -f $Path) -Level 'OK'
                return
            }
            catch {
                Write-Log -Message ("Segundo intento fallido al eliminar {0}: {1}" -f $Path, $_.Exception.Message) -Level 'WARN'

                if (Test-Path -LiteralPath $Path) {
                    try {
                        Add-PendingDeleteOnReboot -Path $Path
                        return
                    }
                    catch {
                        Write-Log -Message ("No se pudo programar la eliminación diferida de {0}: {1}" -f $Path, $_.Exception.Message) -Level 'ERROR'
                        return
                    }
                }
            }
        }

        Write-Log -Message ("No se pudo eliminar {0}" -f $Path) -Level 'ERROR'
    }
}


function Remove-RegistryKeyIfExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
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


function Get-OracleDeinstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RootPath
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        Write-Log -Message ("La raíz de búsqueda no existe: {0}" -f $RootPath) -Level 'WARN'
        @()
        return
    }

    $items = @(Get-ChildItem -LiteralPath $RootPath -Recurse -File -Filter 'deinstall.bat' -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -match '\\deinstall\\deinstall\.bat$' -and
            $_.FullName -notmatch '\\inventory\\Templates\\deinstall\\deinstall\.bat$'
        })

    $result = foreach ($item in ($items | Sort-Object -Property FullName -Unique)) {
        $deinstallRoot = Split-Path -Path $item.FullName -Parent
        $oracleHome = Split-Path -Path $deinstallRoot -Parent

        [pscustomobject]@{
            OracleHome    = $oracleHome
            DeinstallRoot = $deinstallRoot
            DeinstallBat  = $item.FullName
        }
    }

    @($result | Sort-Object -Property OracleHome -Unique)
}


function Get-OracleRelatedProcess {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$HomePaths = @(),

        [Parameter()]
        [string[]]$AdditionalRootPaths = @()
    )

    $allRoots = @($HomePaths + $AdditionalRootPaths | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
    $processItems = @(Get-CimInstance -ClassName Win32_Process -ErrorAction SilentlyContinue)

    $result = foreach ($processItem in $processItems) {
        $executablePath = [string](Get-SafePropertyValue -InputObject $processItem -Name 'ExecutablePath' -DefaultValue '')
        $commandLine = [string](Get-SafePropertyValue -InputObject $processItem -Name 'CommandLine' -DefaultValue '')
        $name = [string](Get-SafePropertyValue -InputObject $processItem -Name 'Name' -DefaultValue '')
        $isRelated = $false

        foreach ($rootPath in $allRoots) {
            if ($executablePath -and (Test-PathUnderRoot -Path $executablePath -Root $rootPath)) {
                $isRelated = $true
                break
            }

            if ($commandLine -and $commandLine.IndexOf($rootPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $isRelated = $true
                break
            }
        }

        if (-not $isRelated -and $name -match '^(oracle|sqlplus|tnsping|lsnrctl|oradim|java|perl|cmd)(\.exe)?$') {
            foreach ($rootPath in $allRoots) {
                if ($commandLine -and $commandLine.IndexOf($rootPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $isRelated = $true
                    break
                }
            }
        }

        if ($isRelated) {
            [pscustomobject]@{
                Name           = $name
                ProcessId      = $processItem.ProcessId
                ExecutablePath = $executablePath
                CommandLine    = $commandLine
            }
        }
    }

    @($result | Sort-Object -Property ProcessId -Unique)
}


function Stop-OracleRelatedProcess {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$HomePaths = @(),

        [Parameter()]
        [string[]]$AdditionalRootPaths = @()
    )

    $processItems = @(Get-OracleRelatedProcess -HomePaths $HomePaths -AdditionalRootPaths $AdditionalRootPaths)

    if ($processItems.Count -eq 0) {
        Write-Log -Message 'No hay procesos Oracle relacionados en ejecución.'
        return
    }

    foreach ($processItem in $processItems) {
        try {
            Stop-Process -Id $processItem.ProcessId -Force -ErrorAction Stop
            Write-Log -Message ("Proceso detenido: {0} (PID {1})" -f $processItem.Name, $processItem.ProcessId) -Level 'OK'
        }
        catch {
            Write-Log -Message ("No se pudo detener PID {0} ({1}): {2}" -f $processItem.ProcessId, $processItem.Name, $_.Exception.Message) -Level 'WARN'
        }
    }
}


function Wait-OracleDeinstallCompletion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OracleHome,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DeinstallRoot,

        [Parameter()]
        [ValidateRange(30, 7200)]
        [int]$TimeoutSeconds = 1800
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    do {
        $processItems = @(Get-OracleRelatedProcess -HomePaths @($OracleHome) -AdditionalRootPaths @($DeinstallRoot))

        if ($processItems.Count -eq 0) {
            Write-Log -Message ("No quedan procesos activos asociados a {0}" -f $OracleHome) -Level 'OK'
            $true
            return
        }

        $summary = ($processItems | Select-Object -First 5 | ForEach-Object {
            '{0}:{1}' -f $_.Name, $_.ProcessId
        }) -join ', '

        Write-Log -Message ("Esperando fin de procesos de desinstalación para {0}: {1}" -f $OracleHome, $summary)
        Start-Sleep -Seconds 5
    }
    while ((Get-Date) -lt $deadline)

    $remainingItems = @(Get-OracleRelatedProcess -HomePaths @($OracleHome) -AdditionalRootPaths @($DeinstallRoot))
    if ($remainingItems.Count -gt 0) {
        $summary = ($remainingItems | ForEach-Object { '{0}:{1}' -f $_.Name, $_.ProcessId }) -join ', '
        Write-Log -Message ("Timeout esperando la finalización real del desinstalador para {0}. Procesos restantes: {1}" -f $OracleHome, $summary) -Level 'WARN'
        $false
        return
    }

    $true
}


function Get-OrphanOracleService {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$RootPaths = @()
    )

    $serviceItems = @(Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue)

    $result = foreach ($serviceItem in $serviceItems) {
        $pathName = [string](Get-SafePropertyValue -InputObject $serviceItem -Name 'PathName' -DefaultValue '')
        $name = [string](Get-SafePropertyValue -InputObject $serviceItem -Name 'Name' -DefaultValue '')
        $displayName = [string](Get-SafePropertyValue -InputObject $serviceItem -Name 'DisplayName' -DefaultValue '')
        $isRelated = $false

        foreach ($rootPath in @($RootPaths | Select-Object -Unique)) {
            if ($pathName -and $pathName.IndexOf($rootPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $isRelated = $true
                break
            }
        }

        if (-not $isRelated -and $name -ieq 'Oracle') {
            $isRelated = $true
        }

        if ($isRelated) {
            [pscustomobject]@{
                Name        = $name
                DisplayName = $displayName
                State       = [string](Get-SafePropertyValue -InputObject $serviceItem -Name 'State' -DefaultValue '')
                PathName    = $pathName
            }
        }
    }

    @($result | Sort-Object -Property Name -Unique)
}


function Remove-OrphanOracleService {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$RootPaths = @()
    )

    $serviceItems = @(Get-OrphanOracleService -RootPaths $RootPaths)
    if ($serviceItems.Count -eq 0) {
        Write-Log -Message 'No se han encontrado servicios Oracle ligados a las rutas objetivo.'
        return
    }

    $scExe = Get-NativeCommandPath -Leaf 'sc.exe'

    foreach ($serviceItem in $serviceItems) {
        try {
            if ($serviceItem.State -and $serviceItem.State -ne 'Stopped') {
                Invoke-ExternalProcess -FilePath $scExe -Arguments @('stop', $serviceItem.Name) -IgnoreExitCode | Out-Null
                Start-Sleep -Milliseconds 500
            }
        }
        catch {
            Write-Log -Message ("No se pudo detener el servicio {0}: {1}" -f $serviceItem.Name, $_.Exception.Message) -Level 'WARN'
        }

        Invoke-ExternalProcess -FilePath $scExe -Arguments @('delete', $serviceItem.Name) -IgnoreExitCode | Out-Null
        Write-Log -Message ("Intento de eliminación del servicio: {0}" -f $serviceItem.Name)
    }
}


function Test-OracleDeinstallLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputDirectory
    )

    if (-not (Test-Path -LiteralPath $OutputDirectory)) {
        Write-Log -Message ("No se encontró el directorio de salida del desinstalador: {0}" -f $OutputDirectory) -Level 'WARN'
        return
    }

    try {
        $logItems = @(Get-ChildItem -LiteralPath $OutputDirectory -Recurse -File -ErrorAction SilentlyContinue)
        if ($logItems.Count -eq 0) {
            Write-Log -Message ("El desinstalador no generó archivos en {0}" -f $OutputDirectory) -Level 'WARN'
            return
        }

        Write-Log -Message ("Archivos generados por el desinstalador en {0}: {1}" -f $OutputDirectory, $logItems.Count)

        $suspiciousItems = @(
            $logItems | Select-String -Pattern 'ERROR|FATAL|SEVERE|Exception|failed' -SimpleMatch:$false -ErrorAction SilentlyContinue
        )

        if ($suspiciousItems.Count -gt 0) {
            $firstHit = $suspiciousItems | Select-Object -First 1
            Write-Log -Message ("Se detectaron mensajes a revisar en logs Oracle. Ejemplo: {0} (línea {1}) {2}" -f $firstHit.Path, $firstHit.LineNumber, $firstHit.Line.Trim()) -Level 'WARN'
        } else {
            Write-Log -Message 'No se detectaron patrones de error evidentes en los logs del desinstalador.' -Level 'OK'
        }
    }
    catch {
        Write-Log -Message ("No se pudieron revisar los logs Oracle en {0}: {1}" -f $OutputDirectory, $_.Exception.Message) -Level 'WARN'
    }
}


function Test-OracleDeinstallCompletionMarker {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$StdOut = '',

        [Parameter()]
        [AllowEmptyString()]
        [string]$StdErr = ''
    )

    $completionMarker = '############# ORACLE DEINSTALL & DECONFIG TOOL END #############'
    $combinedOutput = @($StdOut, $StdErr) -join [Environment]::NewLine

    if ([string]::IsNullOrWhiteSpace($combinedOutput)) {
        return $false
    }

    ($combinedOutput.IndexOf($completionMarker, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
}


function Invoke-OracleClientUninstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $OracleItem,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputDirectory,

        [Parameter(Mandatory = $true)]
        [ValidateRange(60, 7200)]
        [int]$TimeoutSeconds
    )

    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

    Write-Log -Message ("Desinstalador localizado: {0}" -f $OracleItem.DeinstallBat) -Level 'OK'
    Write-Log -Message ("Oracle Home objetivo: {0}" -f $OracleItem.OracleHome)

    Stop-OracleRelatedProcess -HomePaths @($OracleItem.OracleHome) -AdditionalRootPaths @($OracleItem.DeinstallRoot)

    $cmdExe = Get-NativeCommandPath -Leaf 'cmd.exe'
    $commandLine = 'call ""{0}"" -silent -o ""{1}""' -f $OracleItem.DeinstallBat, $OutputDirectory

    $processResult = Invoke-ExternalProcess -FilePath $cmdExe -Arguments @('/d', '/c', $commandLine) -TimeoutSeconds $TimeoutSeconds

    if ($null -eq $processResult) {
        Write-Log -Message ("No se pudo lanzar el desinstalador para {0}" -f $OracleItem.OracleHome) -Level 'ERROR'

        return [pscustomobject]@{
            Success            = $false
            WrapperExitCode    = $null
            WrapperTimedOut    = $false
            OracleHome         = $OracleItem.OracleHome
            OutputDirectory    = $OutputDirectory
            ProcessesCompleted = $false
        }
    }

    if ($processResult.TimedOut) {
        Write-Log -Message ("El wrapper del desinstalador agotó el tiempo de espera para {0}" -f $OracleItem.OracleHome) -Level 'ERROR'

        return [pscustomobject]@{
            Success            = $false
            WrapperExitCode    = $processResult.ExitCode
            WrapperTimedOut    = $true
            OracleHome         = $OracleItem.OracleHome
            OutputDirectory    = $OutputDirectory
            ProcessesCompleted = $false
        }
    }

    $completionMarkerFound = Test-OracleDeinstallCompletionMarker -StdOut $processResult.StdOut -StdErr $processResult.StdErr

    if ($completionMarkerFound) {
        Write-Log -Message ("Se detectó la marca de fin del deinstall en la salida capturada para {0}." -f $OracleItem.OracleHome) -Level 'OK'
    } else {
        Write-Log -Message ("No se detectó la marca de fin del deinstall en la salida capturada para {0}. Se cancela la limpieza posterior." -f $OracleItem.OracleHome) -Level 'ERROR'

        return [pscustomobject]@{
            Success               = $false
            WrapperExitCode       = $processResult.ExitCode
            WrapperTimedOut       = $false
            OracleHome            = $OracleItem.OracleHome
            OutputDirectory       = $OutputDirectory
            ProcessesCompleted    = $false
            CompletionMarkerFound = $false
        }
    }

    if ($null -eq $processResult.ExitCode) {
        Write-Log -Message ("No se pudo recuperar el ExitCode del wrapper para {0}. Se continuará porque la marca de fin sí fue detectada." -f $OracleItem.OracleHome) -Level 'WARN'
    } else {
        Write-Log -Message ("ExitCode del wrapper para {0}: {1}" -f $OracleItem.OracleHome, $processResult.ExitCode)
    }

    $processesCompleted = Wait-OracleDeinstallCompletion -OracleHome $OracleItem.OracleHome -DeinstallRoot $OracleItem.DeinstallRoot -TimeoutSeconds $TimeoutSeconds
    Test-OracleDeinstallLog -OutputDirectory $OutputDirectory

    if (-not $processesCompleted) {
        Write-Log -Message ("No se confirmó el fin real de los procesos del desinstalador para {0}. Se cancela la limpieza posterior." -f $OracleItem.OracleHome) -Level 'ERROR'
    }

    [pscustomobject]@{
        Success               = [bool]$processesCompleted
        WrapperExitCode       = $processResult.ExitCode
        WrapperTimedOut       = $false
        OracleHome            = $OracleItem.OracleHome
        OutputDirectory       = $OutputDirectory
        ProcessesCompleted    = [bool]$processesCompleted
        CompletionMarkerFound = $completionMarkerFound
    }
}


function Get-TargetOraclePath {
    [CmdletBinding()]
    param()

    $pathItems = @('C:\app')

    $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
        $pathItems += (Join-Path -Path $programFilesX86 -ChildPath 'Oracle')
    }

    $pathItems += 'C:\Archivos de programa (x86)\Oracle'

    @($pathItems | Select-Object -Unique)
}


function Remove-OracleRegistryArtifacts {
    [CmdletBinding()]
    param()

    Write-Log -Message 'Limpiando claves de registro Oracle...'

    foreach ($registryPath in @(
        'HKLM:\SOFTWARE\Oracle',
        'HKLM:\SYSTEM\CurrentControlSet\Services\Oracle',
        'HKLM:\SOFTWARE\WOW6432Node\Oracle'
    )) {
        Remove-RegistryKeyIfExists -Path $registryPath
    }
}


function Get-WorldShipFolder {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string[]]$DriveRoots
    )

    $effectiveRoots = @()

    if ($DriveRoots -and $DriveRoots.Count -gt 0) {
        $effectiveRoots = @($DriveRoots)
    } else {
        $effectiveRoots = @(
            Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction SilentlyContinue |
                ForEach-Object { '{0}\' -f $_.DeviceID }
        )
    }

    $excludedRoots = @(
        'C:\Windows',
        'C:\Users',
        'C:\ProgramData',
        'C:\Documents and Settings'
    ) | Where-Object {
        Test-Path -LiteralPath $_
    }

    $foundFolders = New-Object System.Collections.Generic.List[string]

    foreach ($driveRoot in ($effectiveRoots | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $driveRoot)) {
            Write-Log -Message ("Unidad no accesible para búsqueda WorldShip: {0}" -f $driveRoot) -Level 'WARN'
            continue
        }

        Write-Log -Message ("Buscando carpetas *Worldship* en {0}" -f $driveRoot)

        $pendingPaths = New-Object System.Collections.Generic.Queue[string]
        $pendingPaths.Enqueue($driveRoot)

        while ($pendingPaths.Count -gt 0) {
            $currentPath = $pendingPaths.Dequeue()

            $skipCurrentPath = $false
            foreach ($excludedRoot in $excludedRoots) {
                if (Test-PathUnderRoot -Path $currentPath -Root $excludedRoot) {
                    $skipCurrentPath = $true
                    break
                }
            }

            if ($skipCurrentPath) {
                continue
            }

            try {
                $childDirectories = @(
                    Get-ChildItem -LiteralPath $currentPath -Directory -Force -ErrorAction Stop
                )
            }
            catch [System.UnauthorizedAccessException] {
                Write-Log -Message ("Acceso denegado durante búsqueda WorldShip en {0}" -f $currentPath) -Level 'WARN'
                continue
            }
            catch [System.IO.IOException] {
                Write-Log -Message ("Error de E/S durante búsqueda WorldShip en {0}: {1}" -f $currentPath, $_.Exception.Message) -Level 'WARN'
                continue
            }
            catch {
                Write-Log -Message ("No se pudo enumerar {0}: {1}" -f $currentPath, $_.Exception.Message) -Level 'WARN'
                continue
            }

            foreach ($childDirectory in $childDirectories) {
                $childFullName = $childDirectory.FullName

                $isReparsePoint = (($childDirectory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
                if ($isReparsePoint) {
                    continue
                }

                $skipChildPath = $false
                foreach ($excludedRoot in $excludedRoots) {
                    if (Test-PathUnderRoot -Path $childFullName -Root $excludedRoot) {
                        $skipChildPath = $true
                        break
                    }
                }

                if ($skipChildPath) {
                    continue
                }

                if ($childDirectory.Name -like '*Worldship*') {
                    $foundFolders.Add($childFullName) | Out-Null
                    Write-Log -Message ("Carpeta WorldShip detectada: {0}" -f $childFullName) -Level 'OK'
                }

                $pendingPaths.Enqueue($childFullName)
            }
        }
    }

    @($foundFolders | Sort-Object -Unique)
}


function Remove-WorldShipOracleDll {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FolderPaths
    )

    $regsvr32Exe = Get-NativeCommandPath -Leaf 'regsvr32.exe'
    $detectedDllCount = 0
    $removedDllCount = 0

    foreach ($folderPath in ($FolderPaths | Select-Object -Unique)) {
        Write-Log -Message ("Inspeccionando carpeta WorldShip: {0}" -f $folderPath)

        try {
            $dllItems = @(
                Get-ChildItem -LiteralPath $folderPath -Recurse -Force -File -ErrorAction Stop |
                    Where-Object { $_.Name -ieq 'oraociei12.dll' }
            )
        }
        catch [System.UnauthorizedAccessException] {
            Write-Log -Message ("Acceso denegado inspeccionando DLL en {0}" -f $folderPath) -Level 'WARN'
            continue
        }
        catch {
            Write-Log -Message ("No se pudo inspeccionar {0}: {1}" -f $folderPath, $_.Exception.Message) -Level 'WARN'
            continue
        }

        if ($dllItems.Count -eq 0) {
            Write-Log -Message ("No se encontró oraociei12.dll en {0}" -f $folderPath)
            continue
        }

        foreach ($dllItem in $dllItems) {
            $detectedDllCount++
            Write-Log -Message ("Se encontró oraociei12.dll en {0}" -f $dllItem.FullName) -Level 'WARN'
            Write-Log -Message 'Intentando desregistrar oraociei12.dll con regsvr32.exe /u /s'
            Invoke-ExternalProcess -FilePath $regsvr32Exe -Arguments @('/u', '/s', $dllItem.FullName) -IgnoreExitCode | Out-Null
            Remove-FileSystemItem -Path $dllItem.FullName -ForceTakeOwnership

            if (-not (Test-Path -LiteralPath $dllItem.FullName)) {
                $removedDllCount++
                Write-Log -Message ("DLL eliminada: {0}" -f $dllItem.FullName) -Level 'OK'
            } else {
                Write-Log -Message ("La DLL sigue presente tras el intento de eliminación: {0}" -f $dllItem.FullName) -Level 'WARN'
            }
        }
    }

    Write-Log -Message ("Total de DLL oraociei12.dll detectadas: {0}" -f $detectedDllCount)
    Write-Log -Message ("Total de DLL oraociei12.dll eliminadas: {0}" -f $removedDllCount)
}



function Get-ComputerHostName {
    [CmdletBinding()]
    param()

    ([string]$env:COMPUTERNAME).Trim().ToUpperInvariant()
}


function Test-IsExceptionComputer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerHostName
    )

    $normalizedHostName = ([string]$ComputerHostName).Trim().ToUpperInvariant()
    $normalizedExceptionList = @(
        $script:ExceptionComputerNames | ForEach-Object {
            ([string]$_).Trim().ToUpperInvariant()
        }
    )

    $normalizedExceptionList -contains $normalizedHostName
}


function Test-FinalCleanupEvidence {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowEmptyCollection()]
        [string[]]$WorldShipFolderPaths = @()
    )

    $remainingItems = @()

    foreach ($pathItem in (Get-TargetOraclePath | Select-Object -Unique)) {
        if (-not (Test-PathCoveredByPendingDelete -Path $pathItem -PendingRoots $script:PendingDeletePaths) -and (Test-Path -LiteralPath $pathItem)) {
            $remainingItems += $pathItem
        }
    }

    foreach ($registryPath in @(
        'HKLM:\SOFTWARE\Oracle',
        'HKLM:\SYSTEM\CurrentControlSet\Services\Oracle',
        'HKLM:\SOFTWARE\WOW6432Node\Oracle'
    )) {
        if (Test-Path -Path $registryPath) {
            $remainingItems += "Registry::{0}" -f $registryPath
        }
    }

    foreach ($folderPath in ($WorldShipFolderPaths | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $folderPath)) {
            continue
        }

        $dllItems = @(Get-ChildItem -LiteralPath $folderPath -Recurse -Force -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -ieq 'oraociei12.dll'
            })

        foreach ($dllItem in $dllItems) {
            if (-not (Test-PathCoveredByPendingDelete -Path $dllItem.FullName -PendingRoots $script:PendingDeletePaths)) {
                $remainingItems += $dllItem.FullName
            }
        }
    }

    @($remainingItems | Sort-Object -Unique)
}


$oracleItems = @()
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logDirectory = Join-Path -Path $LogRoot -ChildPath 'OracleClient11G-Removal'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$script:LogFile = Join-Path -Path $logDirectory -ChildPath ("Remove-OracleClient11G_{0}_{1}.log" -f $env:COMPUTERNAME, $timestamp)

if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
    $sysNativePowerShell = Join-Path -Path $env:WINDIR -ChildPath 'SysNative\WindowsPowerShell\v1.0\powershell.exe'

    if (-not $PSCommandPath -or -not (Test-Path -LiteralPath $sysNativePowerShell)) {
        throw 'Este script debe ejecutarse en PowerShell x64. Configure el despliegue para usar PowerShell de 64 bits.'
    }

    $relaunchArguments = Get-RelaunchArgumentList -ScriptPath $PSCommandPath -BoundParameters $PSBoundParameters -ExtraArguments $args
    & $sysNativePowerShell @relaunchArguments
    exit $LASTEXITCODE
}


try {
    $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $currentPrincipal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)

    if (-not ($currentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator) -or $currentIdentity.Name -eq 'NT AUTHORITY\SYSTEM')) {
        throw 'Este script necesita privilegios de administrador o SYSTEM.'
    }

    Write-Log -Message ('Inicio de ejecución en {0} - Usuario={1} - PowerShell={2}' -f $env:COMPUTERNAME, $currentIdentity.Name, $PSVersionTable.PSVersion.ToString()) -Level 'OK'
    Write-Log -Message ('Log: {0}' -f $script:LogFile) -Level 'OK'

    $computerHostName = Get-ComputerHostName
    if (Test-IsExceptionComputer -ComputerHostName $computerHostName) {
        Write-Log -Message ('Equipo en lista de excepción: {0}. No se ejecutará desinstalación ni post-limpieza.' -f $computerHostName) -Level 'WARN'

        $result = [pscustomobject]@{
            ComputerName         = $env:COMPUTERNAME
            ComputerHostName      = $computerHostName
            ExecutionStatus      = 'ExceptionList'
            Message              = 'Equipo en lista de excepción. Proceso omitido.'
            Success              = $true
            SearchRoot           = $SearchRoot
            DeinstallersFound    = 0
            WarningCount         = $script:WarningCount
            ErrorCount           = $script:ErrorCount
            RebootRecommended    = $script:RebootRecommended
            PendingDeletePaths   = @($script:PendingDeletePaths | Select-Object -Unique)
            RemainingEvidence    = @()
            LogFile              = $script:LogFile
        }
        Write-Log -Message ('Resultado final: {0}' -f ($result | ConvertTo-Json -Compress)) -Level 'INFO'
        $result | ConvertTo-Json -Compress

        exit 0
    }

    Write-Log -Message ('Raíz de búsqueda Oracle: {0}' -f $SearchRoot)

    $oracleItems = @(Get-OracleDeinstaller -RootPath $SearchRoot)
    Write-Log -Message ('Desinstaladores detectados: {0}' -f $oracleItems.Count)

    if ($oracleItems.Count -eq 0) {
        Write-Log -Message 'No applicable / Not found: no se encontró ningún deinstall.bat bajo la raíz indicada. Se continuará con la post-limpieza genérica.' -Level 'WARN'
    }

    $uninstallResults = @()
    $uninstallAttempted = $false

    foreach ($oracleItem in $oracleItems) {
        $oracleOutputDirectory = Join-Path -Path $logDirectory -ChildPath ([System.IO.Path]::GetFileName($oracleItem.OracleHome) + '_OracleDeinstall')

        if ($PSCmdlet.ShouldProcess($oracleItem.OracleHome, 'Ejecutar desinstalación silenciosa de Oracle Client 11G')) {
            $uninstallAttempted = $true
            $uninstallResults += Invoke-OracleClientUninstall -OracleItem $oracleItem -OutputDirectory $oracleOutputDirectory -TimeoutSeconds $UninstallTimeoutSeconds
        }
    }

    if ($uninstallAttempted) {
        $failedUninstallResults = @($uninstallResults | Where-Object {
            $null -eq $_ -or -not $_.Success
        })

        if ($failedUninstallResults.Count -gt 0) {
            $failureSummary = ($failedUninstallResults | ForEach-Object {
                if ($null -eq $_) {
                    'resultado nulo'
                } else {
                    '{0} (ExitCode={1})' -f $_.OracleHome, $_.WrapperExitCode
                }
            }) -join '; '

            throw ('La post-limpieza se cancela porque la desinstalación intentada no finalizó correctamente: {0}' -f $failureSummary)
        }
    } else {
        Write-Log -Message 'No se ha intentado ninguna desinstalación nativa; se continuará con la post-limpieza.'
    }

    $genericTargetRoots = @(Get-TargetOraclePath)
    $oracleHomeRoots = @($oracleItems | Select-Object -ExpandProperty OracleHome -ErrorAction SilentlyContinue)
    $targetRoots = @(($genericTargetRoots + $oracleHomeRoots) | Select-Object -Unique)

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Detener procesos Oracle residuales')) {
        Stop-OracleRelatedProcess -HomePaths ($oracleItems | Select-Object -ExpandProperty OracleHome) -AdditionalRootPaths (Get-TargetOraclePath)
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Eliminar servicios Oracle residuales')) {
        Remove-OrphanOracleService -RootPaths $targetRoots
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Eliminar claves de registro Oracle')) {
        Remove-OracleRegistryArtifacts
    }

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Eliminar carpetas y binarios Oracle residuales')) {
        foreach ($pathItem in (Get-TargetOraclePath | Select-Object -Unique)) {
            Remove-FileSystemItem -Path $pathItem -ForceTakeOwnership
        }
    }

    $worldShipFolders = @()
    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Buscar carpetas WorldShip y retirar oraociei12.dll')) {
        try {
            $worldShipFolders = @(Get-WorldShipFolder -DriveRoots $WorldShipSearchDrives)
            Write-Log -Message ('Carpetas WorldShip detectadas: {0}' -f $worldShipFolders.Count)

            foreach ($worldShipFolder in $worldShipFolders) {
                Write-Log -Message ("WorldShip candidato: {0}" -f $worldShipFolder)
            }
        }
        catch {
            Write-Log -Message ("La búsqueda de carpetas WorldShip falló: {0}" -f $_.Exception.Message) -Level 'WARN'
        }

        if ($worldShipFolders.Count -eq 0) {
            Write-Log -Message 'No se localizaron carpetas WorldShip.'
        } else {
            try {
                Remove-WorldShipOracleDll -FolderPaths $worldShipFolders
            }
            catch {
                Write-Log -Message ("La retirada de oraociei12.dll falló: {0}" -f $_.Exception.Message) -Level 'WARN'
            }
        }
    }

    $hardRemainingItems = @()
    if (-not $WhatIfPreference) {
        $hardRemainingItems = @(Test-FinalCleanupEvidence -WorldShipFolderPaths $worldShipFolders)

        if ($hardRemainingItems.Count -eq 0) {
            Write-Log -Message 'Validación final correcta: no quedan evidencias duras fuera de eliminaciones diferidas.' -Level 'OK'
        } else {
            foreach ($hardRemainingItem in $hardRemainingItems) {
                Write-Log -Message ("Evidencia restante: {0}" -f $hardRemainingItem) -Level 'WARN'
            }
        }
    } else {
        Write-Log -Message 'Validación final omitida en modo WhatIf.' -Level 'INFO'
    }

    $success = ($script:ErrorCount -eq 0 -and $hardRemainingItems.Count -eq 0)

    $result = [pscustomobject]@{
        ComputerName          = $env:COMPUTERNAME
        ComputerHostName       = Get-ComputerHostName
        ExecutionStatus       = if ($oracleItems.Count -eq 0) { 'CompletedWithGenericCleanup' } else { 'Completed' }
        Message               = if ($oracleItems.Count -eq 0) { 'No se encontró deinstall.bat; se ejecutó post-limpieza genérica.' } else { 'Proceso completado.' }
        Success               = $success
        SearchRoot            = $SearchRoot
        DeinstallersFound     = $oracleItems.Count
        WarningCount          = $script:WarningCount
        ErrorCount            = $script:ErrorCount
        RebootRecommended     = $script:RebootRecommended
        PendingDeletePaths    = @($script:PendingDeletePaths | Select-Object -Unique)
        RemainingEvidence     = @($hardRemainingItems)
        LogFile               = $script:LogFile
    }
    write-Log -Message ('Resultado final: {0}' -f ($result | ConvertTo-Json -Compress)) -Level 'INFO'
    $result | ConvertTo-Json -Compress

    if ($success) {
        exit 0
    }

    exit 1
}
catch {
    Write-Log -Message ("Fallo no controlado: {0}" -f $_.Exception.Message) -Level 'ERROR'

    $result = [pscustomobject]@{
        ComputerName          = $env:COMPUTERNAME
        ComputerHostName       = Get-ComputerHostName
        ExecutionStatus       = 'Failed'
        Message               = $_.Exception.Message
        Success               = $false
        SearchRoot            = $SearchRoot
        DeinstallersFound     = $oracleItems.Count
        WarningCount          = $script:WarningCount
        ErrorCount            = $script:ErrorCount
        RebootRecommended     = $script:RebootRecommended
        PendingDeletePaths    = @($script:PendingDeletePaths | Select-Object -Unique)
        RemainingEvidence     = @()
        LogFile               = $script:LogFile
    }

    exit 1
}
