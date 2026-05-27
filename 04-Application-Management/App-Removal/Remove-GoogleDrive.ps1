#Requires -Version 5.1
<#
.SYNOPSIS
    Desinstala cualquier versión detectada de Google Drive en Windows.

.DESCRIPTION
    Detecta y desinstala variantes de Google Drive registradas en Windows, incluyendo:
    - Google Drive
    - Google Drive for desktop
    - Google Drive File Stream
    - Backup and Sync from Google

    El script:
    - Detiene procesos relacionados.
    - Busca instalaciones en las claves de desinstalación de HKLM y HKCU.
    - Interpreta de forma robusta UninstallString y QuietUninstallString.
    - Intenta localizar GoogleDriveSetup.exe si la ruta registrada no existe.
    - Opcionalmente limpia restos residuales en Program Files, ProgramData y AppData.
    - Si un archivo o carpeta queda bloqueado, programa eliminación diferida al reinicio.
    - Soporta -WhatIf y -Confirm.
    - Devuelve un objeto resumen al pipeline.

.PARAMETER RemoveResidualFiles
    Si se especifica, elimina restos residuales conocidos del producto en Program Files,
    ProgramData y AppData de las cuentas detectadas.

.PARAMETER IncludeCurrentUserOnly
    Limita la detección a HKCU. La limpieza residual de AppData también se limitará al
    usuario actual cuando sea posible.

.PARAMETER LogPath
    Ruta completa del archivo de log. Si no se indica, se genera en:
    C:\ProgramData\GoogleDriveRemoval\Remove-GoogleDrive_<Equipo>_<Timestamp>.log

.EXAMPLE
    .\Remove-GoogleDrive.ps1

.EXAMPLE
    .\Remove-GoogleDrive.ps1 -Verbose

.EXAMPLE
    .\Remove-GoogleDrive.ps1 -RemoveResidualFiles -Verbose

.EXAMPLE
    .\Remove-GoogleDrive.ps1 -WhatIf

.OUTPUTS
    PSCustomObject

.NOTES
    Compatible con Windows PowerShell 5.1 y PowerShell 7+.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param (
    [Parameter()]
    [switch]$RemoveResidualFiles,

    [Parameter()]
    [switch]$IncludeCurrentUserOnly,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ResolvedLogPath = $null
$script:ErrorCount = 0
$script:WarningCount = 0
$script:RebootRecommended = $false
$script:PendingDeletePathItems = New-Object System.Collections.Generic.List[string]


function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')]
        [string]$Level,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )

    $timeStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $lineText = '{0} [{1}] {2}' -f $timeStamp, $Level, $Message

    if (-not [string]::IsNullOrWhiteSpace($script:ResolvedLogPath)) {
        Add-Content -Path $script:ResolvedLogPath -Value $lineText -Encoding UTF8
    }

    switch ($Level) {
        'ERROR' {
            $script:ErrorCount++
            Write-Error $Message
        }
        'WARN' {
            $script:WarningCount++
            Write-Warning $Message
        }
        default {
            Write-Verbose $Message
        }
    }
}


function Initialize-Log {
    [CmdletBinding()]
    param ()

    if ([string]::IsNullOrWhiteSpace($LogPath)) {
        $basePath = Join-Path -Path $env:ProgramData -ChildPath 'GoogleDriveRemoval'
        if (-not (Test-Path -Path $basePath)) {
            New-Item -Path $basePath -ItemType Directory -Force | Out-Null
        }

        $fileName = 'Remove-GoogleDrive_{0}_{1}.log' -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd_HHmmss')
        $script:ResolvedLogPath = Join-Path -Path $basePath -ChildPath $fileName
    } else {
        $parentPath = Split-Path -Path $LogPath -Parent
        if (-not [string]::IsNullOrWhiteSpace($parentPath) -and -not (Test-Path -Path $parentPath)) {
            New-Item -Path $parentPath -ItemType Directory -Force | Out-Null
        }

        $script:ResolvedLogPath = $LogPath
    }

    New-Item -Path $script:ResolvedLogPath -ItemType File -Force | Out-Null
}


function Test-IsAdministrator {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)

    $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}


function Get-ObjectPropertyValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AllowNull()]
        [psobject]$InputObject,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PropertyName
    )

    if ($null -eq $InputObject) {
        $null
    } else {
        $propertyItem = $InputObject.PSObject.Properties[$PropertyName]

        if ($null -ne $propertyItem) {
            $propertyItem.Value
        } else {
            $null
        }
    }
}


function Expand-EnvironmentStringSafely {
    [CmdletBinding()]
    param (
        [Parameter()]
        [AllowNull()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        $null
    } else {
        [Environment]::ExpandEnvironmentVariables($Value)
    }
}


function Test-RegexPattern {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter()]
        [AllowNull()]
        [string]$InputText,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Pattern
    )

    if ([string]::IsNullOrWhiteSpace($InputText)) {
        $false
    } else {
        [regex]::IsMatch($InputText, $Pattern)
    }
}


function Get-UninstallRegistryPaths {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter()]
        [switch]$CurrentUserOnly
    )

    $pathItems = New-Object System.Collections.Generic.List[string]

    if (-not $CurrentUserOnly) {
        $pathItems.Add('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
        $pathItems.Add('HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
    }

    $pathItems.Add('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*')
    $pathItems.Add('HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')

    $pathItems.ToArray()
}


function Get-GoogleDriveInstallations {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param (
        [Parameter()]
        [switch]$CurrentUserOnly
    )

    $displayNamePattern = '(?i)(^Google Drive$|Google Drive for desktop|Drive File Stream|Backup and Sync from Google|Backup and Sync)'
    $publisherPattern = '(?i)Google'
    $resultItems = New-Object System.Collections.Generic.List[object]

    foreach ($pathItem in (Get-UninstallRegistryPaths -CurrentUserOnly:$CurrentUserOnly)) {
        try {
            $registryItems = Get-ItemProperty -Path $pathItem -ErrorAction SilentlyContinue
        } catch {
            continue
        }

        foreach ($registryItem in $registryItems) {
            $displayName = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName 'DisplayName'
            $publisher = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName 'Publisher'
            $displayVersion = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName 'DisplayVersion'
            $installLocation = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName 'InstallLocation'
            $uninstallString = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName 'UninstallString'
            $quietUninstallString = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName 'QuietUninstallString'
            $psPath = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName 'PSPath'
            $psChildName = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName 'PSChildName'

            if ([string]::IsNullOrWhiteSpace($displayName)) {
                continue
            }

            $isGoogleDrive = $false

            if (Test-RegexPattern -InputText $displayName -Pattern $displayNamePattern) {
                $isGoogleDrive = $true
            } elseif (
                (Test-RegexPattern -InputText $publisher -Pattern $publisherPattern) -and
                (Test-RegexPattern -InputText $displayName -Pattern '(?i)Drive')
            ) {
                $isGoogleDrive = $true
            }

            if ($isGoogleDrive) {
                $resultItems.Add([pscustomobject]@{
                    DisplayName          = $displayName
                    DisplayVersion       = $displayVersion
                    Publisher            = $publisher
                    InstallLocation      = $installLocation
                    UninstallString      = $uninstallString
                    QuietUninstallString = $quietUninstallString
                    PSPath               = $psPath
                    PSChildName          = $psChildName
                })
            }
        }
    }

    $resultItems |
        Sort-Object -Property DisplayName, DisplayVersion -Unique
}


function Stop-GoogleDriveProcesses {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([string[]])]
    param ()

    $processNames = @(
        'GoogleDriveFS',
        'GoogleDrive',
        'googledrivesync',
        'GoogleCrashHandler',
        'GoogleCrashHandler64'
    )

    $stoppedItems = New-Object System.Collections.Generic.List[string]

    foreach ($processName in $processNames) {
        $runningItems = @(Get-Process -Name $processName -ErrorAction SilentlyContinue)

        foreach ($runningItem in $runningItems) {
            if ($PSCmdlet.ShouldProcess($runningItem.ProcessName, 'Stop process')) {
                try {
                    Stop-Process -Id $runningItem.Id -Force -ErrorAction Stop
                    $stoppedItems.Add(('{0} ({1})' -f $runningItem.ProcessName, $runningItem.Id))
                    Write-Log -Level 'OK' -Message ("Proceso detenido: {0} (PID {1})" -f $runningItem.ProcessName, $runningItem.Id)
                } catch {
                    Write-Log -Level 'WARN' -Message ("No se pudo detener el proceso {0} (PID {1}): {2}" -f $runningItem.ProcessName, $runningItem.Id, $_.Exception.Message)
                }
            }
        }
    }

    $stoppedItems.ToArray()
}


function Split-UninstallCommand {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandLine
    )

    $trimmedCommandLine = $CommandLine.Trim()

    $regexResult = [regex]::Match(
        $trimmedCommandLine,
        '^\s*"(?<FilePath>[^"]+)"\s*(?<Arguments>.*)$'
    )

    if ($regexResult.Success) {
        [pscustomobject]@{
            FilePath  = $regexResult.Groups['FilePath'].Value
            Arguments = $regexResult.Groups['Arguments'].Value
        }
    } else {
        $regexResult = [regex]::Match(
            $trimmedCommandLine,
            '^\s*(?<FilePath>msiexec(?:\.exe)?)\s*(?<Arguments>.*)$'
        )

        if ($regexResult.Success) {
            [pscustomobject]@{
                FilePath  = $regexResult.Groups['FilePath'].Value
                Arguments = $regexResult.Groups['Arguments'].Value
            }
        } else {
            $regexResult = [regex]::Match(
                $trimmedCommandLine,
                '^\s*(?<FilePath>[A-Za-z]:\\.*?\.exe)\s*(?<Arguments>.*)$'
            )

            if ($regexResult.Success) {
                [pscustomobject]@{
                    FilePath  = $regexResult.Groups['FilePath'].Value
                    Arguments = $regexResult.Groups['Arguments'].Value
                }
            } else {
                throw "No se pudo interpretar la cadena de desinstalación: $CommandLine"
            }
        }
    }
}


function Get-SilentUninstallCommand {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Application
    )

    $commandLine = $null

    if (-not [string]::IsNullOrWhiteSpace($Application.QuietUninstallString)) {
        $commandLine = $Application.QuietUninstallString
    } else {
        $commandLine = $Application.UninstallString
    }

    if ([string]::IsNullOrWhiteSpace($commandLine)) {
        $null
    } else {
        $parsedCommand = Split-UninstallCommand -CommandLine $commandLine
        $filePath = Expand-EnvironmentStringSafely -Value $parsedCommand.FilePath
        $arguments = $parsedCommand.Arguments

        if (Test-RegexPattern -InputText $filePath -Pattern '(?i)^msiexec(?:\.exe)?$') {
            if (-not (Test-RegexPattern -InputText $arguments -Pattern '(?i)(/x|/uninstall)')) {
                $arguments = "/x $arguments".Trim()
            }

            if (-not (Test-RegexPattern -InputText $arguments -Pattern '(?i)(/quiet|/qn|/passive)')) {
                $arguments = "$arguments /qn /norestart".Trim()
            }

            [pscustomobject]@{
                RawCommand = $commandLine
                FilePath   = $filePath
                Arguments  = $arguments
            }
        } else {
            if (-not (Test-RegexPattern -InputText $arguments -Pattern '(?i)(/quiet|/silent|/s|/qn|/q|/verysilent|--silent)')) {
                $arguments = "$arguments --silent".Trim()
            }

            [pscustomobject]@{
                RawCommand = $commandLine
                FilePath   = $filePath
                Arguments  = $arguments
            }
        }
    }
}


function Get-GoogleDriveSetupCandidatePaths {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter()]
        [AllowNull()]
        [string]$InstallLocation
    )

    $candidatePaths = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($InstallLocation)) {
        $expandedInstallLocation = Expand-EnvironmentStringSafely -Value $InstallLocation

        if (-not [string]::IsNullOrWhiteSpace($expandedInstallLocation)) {
            $candidatePaths.Add((Join-Path -Path $expandedInstallLocation -ChildPath 'GoogleDriveSetup.exe'))
        }
    }

    $basePaths = @(
        "$env:ProgramFiles\Google\Drive File Stream",
        "$env:ProgramFiles\Google\Drive",
        "${env:ProgramFiles(x86)}\Google\Drive File Stream",
        "${env:ProgramFiles(x86)}\Google\Drive",
        "$env:LocalAppData\Google\DriveFS",
        "$env:LocalAppData\Google\Drive"
    ) | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    }

    foreach ($basePath in $basePaths) {
        if (Test-Path -Path $basePath) {
            try {
                $setupItems = Get-ChildItem -Path $basePath -Filter 'GoogleDriveSetup.exe' -Recurse -File -ErrorAction SilentlyContinue
                foreach ($setupItem in $setupItems) {
                    $candidatePaths.Add($setupItem.FullName)
                }
            } catch {
            }
        }
    }

    $candidatePaths.ToArray() | Sort-Object -Unique
}


function Resolve-UninstallExecutablePath {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Application,

        [Parameter(Mandatory)]
        [pscustomobject]$Command
    )

    $directCommand = $Command.FilePath

    if ([string]::IsNullOrWhiteSpace($directCommand)) {
        $null
    } elseif ([System.IO.Path]::IsPathRooted($directCommand)) {
        if (Test-Path -Path $directCommand -ErrorAction SilentlyContinue) {
            $directCommand
        } else {
            Write-Log -Level 'WARN' -Message ("No existe el ejecutable indicado en registro para {0}: {1}" -f $Application.DisplayName, $directCommand)

            $resolvedPath = $null
            foreach ($candidatePath in (Get-GoogleDriveSetupCandidatePaths -InstallLocation $Application.InstallLocation)) {
                if (Test-Path -Path $candidatePath -ErrorAction SilentlyContinue) {
                    Write-Log -Level 'INFO' -Message ("Usando ejecutable alternativo para {0}: {1}" -f $Application.DisplayName, $candidatePath)
                    $resolvedPath = $candidatePath
                    break
                }
            }

            $resolvedPath
        }
    } else {
        try {
            $commandItem = Get-Command -Name $directCommand -CommandType Application -ErrorAction Stop
            $commandItem.Source
        } catch {
            Write-Log -Level 'WARN' -Message ("No se pudo resolver el ejecutable {0} para {1}" -f $directCommand, $Application.DisplayName)
            $null
        }
    }
}


function Invoke-UninstallCommand {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory)]
        [pscustomobject]$Application
    )

    $command = Get-SilentUninstallCommand -Application $Application

    if ($null -eq $command) {
        Write-Log -Level 'WARN' -Message ("No hay cadena de desinstalación para: {0}" -f $Application.DisplayName)

        [pscustomobject]@{
            DisplayName = $Application.DisplayName
            Success     = $false
            ExitCode    = $null
            Message     = 'Sin UninstallString / QuietUninstallString'
        }
    } else {
        Write-Log -Level 'INFO' -Message ("UninstallString detectado para {0}: {1}" -f $Application.DisplayName, $command.RawCommand)

        $resolvedFilePath = Resolve-UninstallExecutablePath -Application $Application -Command $command

        if ([string]::IsNullOrWhiteSpace($resolvedFilePath)) {
            Write-Log -Level 'WARN' -Message ("No existe el ejecutable de desinstalación para {0}" -f $Application.DisplayName)

            [pscustomobject]@{
                DisplayName = $Application.DisplayName
                Success     = $false
                ExitCode    = $null
                Message     = 'No existe el ejecutable de desinstalación'
            }
        } else {
            if ($PSCmdlet.ShouldProcess($Application.DisplayName, 'Desinstalar Google Drive')) {
                try {
                    Write-Log -Level 'INFO' -Message ("Desinstalando: {0} - Comando: {1} {2}" -f $Application.DisplayName, $resolvedFilePath, $command.Arguments)

                    $processItem = Start-Process -FilePath $resolvedFilePath `
                                                 -ArgumentList $command.Arguments `
                                                 -Wait `
                                                 -PassThru `
                                                 -WindowStyle Hidden `
                                                 -ErrorAction Stop

                    if ($processItem.ExitCode -eq 0) {
                        Write-Log -Level 'OK' -Message ("Desinstalación completada: {0} - ExitCode={1}" -f $Application.DisplayName, $processItem.ExitCode)
                    } else {
                        Write-Log -Level 'WARN' -Message ("La desinstalación devolvió ExitCode={0} para {1}" -f $processItem.ExitCode, $Application.DisplayName)
                    }

                    [pscustomobject]@{
                        DisplayName = $Application.DisplayName
                        Success     = ($processItem.ExitCode -eq 0)
                        ExitCode    = $processItem.ExitCode
                        Message     = 'Uninstall executed'
                    }
                } catch {
                    Write-Log -Level 'ERROR' -Message ("Error desinstalando {0}: {1}" -f $Application.DisplayName, $_.Exception.Message)

                    [pscustomobject]@{
                        DisplayName = $Application.DisplayName
                        Success     = $false
                        ExitCode    = $null
                        Message     = $_.Exception.Message
                    }
                }
            }
        }
    }
}


function Get-TargetUserHives {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param (
        [Parameter()]
        [switch]$CurrentUserOnly
    )

    $userHiveItems = New-Object System.Collections.Generic.List[object]

    if ($CurrentUserOnly) {
        $currentUserHomePath = $env:USERPROFILE

        if (-not [string]::IsNullOrWhiteSpace($currentUserHomePath) -and (Test-Path -Path $currentUserHomePath)) {
            $userHiveItems.Add([pscustomobject]@{
                SID        = $null
                UserPath   = $currentUserHomePath
                NtUserPath = (Join-Path -Path $currentUserHomePath -ChildPath 'NTUSER.DAT')
            })
        }

        $userHiveItems.ToArray()
    } else {
        $excludedSids = @(
            'S-1-5-18',
            'S-1-5-19',
            'S-1-5-20'
        )

        $userHiveCatalogPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

        try {
            $userSidItems = Get-ChildItem -Path $userHiveCatalogPath -ErrorAction Stop
        } catch {
            Write-Log -Level 'WARN' -Message ("No se pudo enumerar ProfileList: {0}" -f $_.Exception.Message)
            $userSidItems = @()
        }

        foreach ($userSidItem in $userSidItems) {
            $sidValue = Split-Path -Path $userSidItem.Name -Leaf

            if ($excludedSids -contains $sidValue) {
                continue
            }

            try {
                $registryItem = Get-ItemProperty -Path $userSidItem.PSPath -ErrorAction Stop
                $userHomePath = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName 'ProfileImagePath'
                $userHomePath = Expand-EnvironmentStringSafely -Value $userHomePath

                if ([string]::IsNullOrWhiteSpace($userHomePath)) {
                    continue
                }

                if (-not (Test-Path -Path $userHomePath)) {
                    continue
                }

                if ([regex]::IsMatch($userHomePath, '\\(Default|Public|All Users)$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                    continue
                }

                $ntUserDatPath = Join-Path -Path $userHomePath -ChildPath 'NTUSER.DAT'

                $userHiveItems.Add([pscustomobject]@{
                    SID        = $sidValue
                    UserPath   = $userHomePath
                    NtUserPath = $ntUserDatPath
                })
            } catch {
                Write-Log -Level 'WARN' -Message ("No se pudo procesar el SID {0}: {1}" -f $sidValue, $_.Exception.Message)
            }
        }

        $userHiveItems.ToArray() |
            Sort-Object -Property UserPath -Unique
    }
}


function Get-PendingDeleteRegistryValue {
    [CmdletBinding()]
    [OutputType([string[]])]
    param ()

    $sessionManagerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $valueName = 'PendingFileRenameOperations'

    try {
        $registryItem = Get-ItemProperty -Path $sessionManagerPath -Name $valueName -ErrorAction SilentlyContinue
        $valueItem = Get-ObjectPropertyValue -InputObject $registryItem -PropertyName $valueName

        if ($null -eq $valueItem) {
            @()
        } else {
            @($valueItem)
        }
    } catch {
        @()
    }
}


function Add-PendingDeletePath {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    $sessionManagerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
    $valueName = 'PendingFileRenameOperations'
    $normalizedPath = [string]$Path
    $registrySourcePath = $normalizedPath

    if (-not $registrySourcePath.StartsWith('\??\')) {
        $registrySourcePath = '\??\' + $registrySourcePath
    }

    $existingValues = @(Get-PendingDeleteRegistryValue)
    $pendingValueItems = New-Object System.Collections.Generic.List[string]

    foreach ($valueItem in $existingValues) {
        if ($null -ne $valueItem) {
            $pendingValueItems.Add([string]$valueItem)
        }
    }

    $alreadyQueued = $false
    for ($index = 0; $index -lt $pendingValueItems.Count; $index += 2) {
        if ($pendingValueItems[$index] -eq $registrySourcePath) {
            $alreadyQueued = $true
            break
        }
    }

    if ($alreadyQueued) {
        Write-Log -Level 'INFO' -Message ("La ruta ya estaba registrada para eliminación diferida: {0}" -f $normalizedPath)
    } else {
        if ($PSCmdlet.ShouldProcess($normalizedPath, 'Registrar eliminación diferida al reinicio')) {
            $pendingValueItems.Add($registrySourcePath)
            $pendingValueItems.Add('')

            Set-ItemProperty -Path $sessionManagerPath -Name $valueName -Value $pendingValueItems.ToArray() -ErrorAction Stop
            Write-Log -Level 'WARN' -Message ("Eliminación diferida al reinicio programada para: {0}" -f $normalizedPath)

            if (-not ($script:PendingDeletePathItems -contains $normalizedPath)) {
                $script:PendingDeletePathItems.Add($normalizedPath)
            }

            $script:RebootRecommended = $true
        }
    }
}


function Remove-ItemRobust {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ScopeText
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Log -Level 'INFO' -Message ("No existe: {0}" -f $Path)
    } else {
        if ($PSCmdlet.ShouldProcess($Path, "Eliminar residuo de $ScopeText")) {
            try {
                Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
                Write-Log -Level 'OK' -Message ("Eliminado: {0}" -f $Path)

                [pscustomobject]@{
                    Removed       = $true
                    Deferred      = $false
                    RemovedPath   = $Path
                    DeferredPath  = $null
                }
            } catch {
                Write-Log -Level 'WARN' -Message ("No se pudo eliminar {0}; se intentará diferir al reinicio: {1}" -f $Path, $_.Exception.Message)

                try {
                    Add-PendingDeletePath -Path $Path -ErrorAction Stop
                    Write-Log -Level 'WARN' -Message ("La eliminación de {0} queda diferida al reinicio: {1}" -f $Path, $_.Exception.Message)

                    [pscustomobject]@{
                        Removed       = $false
                        Deferred      = $true
                        RemovedPath   = $null
                        DeferredPath  = $Path
                    }
                } catch {
                    Write-Log -Level 'ERROR' -Message ("No se pudo registrar la eliminación diferida para {0}: {1}" -f $Path, $_.Exception.Message)

                    [pscustomobject]@{
                        Removed       = $false
                        Deferred      = $false
                        RemovedPath   = $null
                        DeferredPath  = $null
                    }
                }
            }
        }
    }
}


function Remove-GoogleDriveResidualFiles {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param (
        [Parameter()]
        [switch]$CurrentUserOnly
    )

    $removedPaths = New-Object System.Collections.Generic.List[string]
    $deferredPaths = New-Object System.Collections.Generic.List[string]

    $machinePaths = @(
        "$env:ProgramFiles\Google\Drive File Stream",
        "$env:ProgramFiles\Google\Drive",
        "${env:ProgramFiles(x86)}\Google\Drive File Stream",
        "${env:ProgramFiles(x86)}\Google\Drive",
        "$env:ProgramData\Google\DriveFS",
        "$env:ProgramData\Google\Drive"
    ) | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } | Sort-Object -Unique

    foreach ($pathItem in $machinePaths) {
        $removeResult = Remove-ItemRobust -Path $pathItem -ScopeText 'máquina'

        if ($null -ne $removeResult) {
            if ($removeResult.Removed -and -not [string]::IsNullOrWhiteSpace($removeResult.RemovedPath)) {
                $removedPaths.Add($removeResult.RemovedPath)
            }

            if ($removeResult.Deferred -and -not [string]::IsNullOrWhiteSpace($removeResult.DeferredPath)) {
                $deferredPaths.Add($removeResult.DeferredPath)
            }
        }
    }

    $userHiveItems = @(Get-TargetUserHives -CurrentUserOnly:$CurrentUserOnly)

    foreach ($userHiveItem in $userHiveItems) {
        $userPaths = @(
            (Join-Path -Path $userHiveItem.UserPath -ChildPath 'AppData\Local\Google\DriveFS'),
            (Join-Path -Path $userHiveItem.UserPath -ChildPath 'AppData\Local\Google\Drive'),
            (Join-Path -Path $userHiveItem.UserPath -ChildPath 'AppData\Roaming\Google\DriveFS'),
            (Join-Path -Path $userHiveItem.UserPath -ChildPath 'AppData\Roaming\Google\Drive')
        ) | Sort-Object -Unique

        foreach ($pathItem in $userPaths) {
            $removeResult = Remove-ItemRobust -Path $pathItem -ScopeText 'usuario'

            if ($null -ne $removeResult) {
                if ($removeResult.Removed -and -not [string]::IsNullOrWhiteSpace($removeResult.RemovedPath)) {
                    $removedPaths.Add($removeResult.RemovedPath)
                }

                if ($removeResult.Deferred -and -not [string]::IsNullOrWhiteSpace($removeResult.DeferredPath)) {
                    $deferredPaths.Add($removeResult.DeferredPath)
                }
            }
        }
    }

    [pscustomobject]@{
        RemovedPaths  = @($removedPaths.ToArray() | Sort-Object -Unique)
        DeferredPaths = @($deferredPaths.ToArray() | Sort-Object -Unique)
    }
}


function Get-GoogleDriveResidualEvidence {
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter()]
        [switch]$CurrentUserOnly
    )

    $evidenceItems = New-Object System.Collections.Generic.List[string]

    $remainingApps = @(Get-GoogleDriveInstallations -CurrentUserOnly:$CurrentUserOnly)
    foreach ($appItem in $remainingApps) {
        $evidenceItems.Add(("Registro: {0} [{1}]" -f $appItem.DisplayName, $appItem.DisplayVersion))
    }

    $machinePaths = @(
        "$env:ProgramFiles\Google\Drive File Stream",
        "$env:ProgramFiles\Google\Drive",
        "${env:ProgramFiles(x86)}\Google\Drive File Stream",
        "${env:ProgramFiles(x86)}\Google\Drive",
        "$env:ProgramData\Google\DriveFS",
        "$env:ProgramData\Google\Drive"
    ) | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } | Sort-Object -Unique

    foreach ($pathItem in $machinePaths) {
        if (Test-Path -Path $pathItem) {
            $evidenceItems.Add(("Ruta: {0}" -f $pathItem))
        }
    }

    $userHiveItems = @(Get-TargetUserHives -CurrentUserOnly:$CurrentUserOnly)

    foreach ($userHiveItem in $userHiveItems) {
        $userPaths = @(
            (Join-Path -Path $userHiveItem.UserPath -ChildPath 'AppData\Local\Google\DriveFS'),
            (Join-Path -Path $userHiveItem.UserPath -ChildPath 'AppData\Local\Google\Drive'),
            (Join-Path -Path $userHiveItem.UserPath -ChildPath 'AppData\Roaming\Google\DriveFS'),
            (Join-Path -Path $userHiveItem.UserPath -ChildPath 'AppData\Roaming\Google\Drive')
        ) | Sort-Object -Unique

        foreach ($pathItem in $userPaths) {
            if (Test-Path -Path $pathItem) {
                $evidenceItems.Add(("Ruta: {0}" -f $pathItem))
            }
        }
    }

    $evidenceItems.ToArray() | Sort-Object -Unique
}


function Get-EvidencePathValue {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$EvidenceText
    )

    if ($EvidenceText.StartsWith('Ruta: ')) {
        $EvidenceText.Substring(6)
    } else {
        $null
    }
}


Initialize-Log

Write-Log -Level 'INFO' -Message ("Inicio de ejecución en {0} - Usuario={1} - PowerShell={2}" -f $env:COMPUTERNAME, [Security.Principal.WindowsIdentity]::GetCurrent().Name, $PSVersionTable.PSVersion)
Write-Log -Level 'INFO' -Message ("Log: {0}" -f $script:ResolvedLogPath)

if (-not (Test-IsAdministrator)) {
    throw 'Debes ejecutar este script con privilegios de administrador.'
}

$detectedApps = @(Get-GoogleDriveInstallations -CurrentUserOnly:$IncludeCurrentUserOnly)

if ($detectedApps.Count -eq 0) {
    Write-Log -Level 'INFO' -Message 'No se encontraron instalaciones registradas de Google Drive.'
} else {
    Write-Log -Level 'INFO' -Message ("Instalaciones detectadas: {0}" -f $detectedApps.Count)

    foreach ($appItem in $detectedApps) {
        Write-Log -Level 'INFO' -Message ("Detectado: {0} - Version={1} - Publisher={2}" -f $appItem.DisplayName, $appItem.DisplayVersion, $appItem.Publisher)
    }
}

$stoppedBefore = @(Stop-GoogleDriveProcesses)

$uninstallResults = New-Object System.Collections.Generic.List[object]
foreach ($appItem in $detectedApps) {
    $uninstallItem = Invoke-UninstallCommand -Application $appItem
    if ($null -ne $uninstallItem) {
        $uninstallResults.Add($uninstallItem)
    }
}

Start-Sleep -Seconds 3

$stoppedAfter = @(Stop-GoogleDriveProcesses)

$removedResidualFiles = @()

if ($RemoveResidualFiles) {
    $cleanupResult = Remove-GoogleDriveResidualFiles -CurrentUserOnly:$IncludeCurrentUserOnly
    $removedResidualFiles = @($cleanupResult.RemovedPaths)
}

$remainingEvidence = @(Get-GoogleDriveResidualEvidence -CurrentUserOnly:$IncludeCurrentUserOnly)

$hardEvidenceItems = New-Object System.Collections.Generic.List[string]
$deferredEvidenceItems = New-Object System.Collections.Generic.List[string]

foreach ($evidenceItem in $remainingEvidence) {
    $evidencePath = Get-EvidencePathValue -EvidenceText $evidenceItem

    if (
        -not [string]::IsNullOrWhiteSpace($evidencePath) -and
        ($script:PendingDeletePathItems -contains $evidencePath)
    ) {
        $deferredEvidenceItems.Add($evidenceItem)
    } else {
        $hardEvidenceItems.Add($evidenceItem)
    }
}

if (($hardEvidenceItems.Count -eq 0) -and ($deferredEvidenceItems.Count -eq 0)) {
    Write-Log -Level 'OK' -Message 'No se han encontrado evidencias residuales principales de Google Drive.'
} elseif (($hardEvidenceItems.Count -eq 0) -and ($deferredEvidenceItems.Count -gt 0)) {
    Write-Log -Level 'WARN' -Message 'Solo quedan restos bloqueados cuya eliminación se ha diferido al reinicio.'

    foreach ($deferredItem in $deferredEvidenceItems) {
        Write-Log -Level 'WARN' -Message ("Resto diferido a reinicio: {0}" -f $deferredItem)
    }

    if ($script:RebootRecommended) {
        Write-Log -Level 'WARN' -Message 'Se recomienda reiniciar el equipo para completar la eliminación de archivos Google Drive que estaban bloqueados.'
    }
} else {
    foreach ($hardItem in $hardEvidenceItems) {
        Write-Log -Level 'WARN' -Message ("Evidencia residual: {0}" -f $hardItem)
    }

    foreach ($deferredItem in $deferredEvidenceItems) {
        Write-Log -Level 'WARN' -Message ("Resto diferido a reinicio: {0}" -f $deferredItem)
    }

    if ($script:RebootRecommended) {
        Write-Log -Level 'WARN' -Message 'Se recomienda reiniciar el equipo para completar la eliminación de archivos Google Drive que estaban bloqueados.'
    }
}

$resultObject = [pscustomobject]@{
    ComputerName          = $env:COMPUTERNAME
    Success               = ($script:ErrorCount -eq 0)
    DetectedInstallations = $detectedApps.Count
    UninstallResults      = @($uninstallResults.ToArray())
    StoppedProcesses      = @($stoppedBefore + $stoppedAfter | Sort-Object -Unique)
    RemovedResidualFiles  = @($removedResidualFiles | Sort-Object -Unique)
    RemainingEvidence     = @($remainingEvidence)
    RebootRecommended     = $script:RebootRecommended
    PendingDeletePaths    = @($script:PendingDeletePathItems.ToArray() | Sort-Object -Unique)
    ErrorCount            = $script:ErrorCount
    WarningCount          = $script:WarningCount
    LogFile               = $script:ResolvedLogPath
}

Write-Log -Level 'OK' -Message ("Fin de ejecución. Errores={0}; Advertencias={1}; ReinicioPendiente={2}; Log={3}" -f $resultObject.ErrorCount, $resultObject.WarningCount, $resultObject.RebootRecommended, $resultObject.LogFile)

$resultObject

if ($script:ErrorCount -gt 0) {
    exit 1
}

exit 0