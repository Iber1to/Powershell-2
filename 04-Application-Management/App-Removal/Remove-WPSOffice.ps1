#Requires -Version 5.1
<#!
.SYNOPSIS
    Retira WPS Office y evidencias residuales de Kingsoft/WPS en endpoints Windows.

.DESCRIPTION
    Script controlador de remediación para entornos gestionados. Intenta primero la desinstalación limpia
    mediante entradas ARP/UninstallString y uninst.exe; posteriormente limpia evidencias de filesystem,
    registro por usuario, paquetes AppX wpsappext y ficheros instaladores descargados.

    Está diseñado para ejecución elevada, preferiblemente como SYSTEM desde Ivanti, Intune o MECM/SCCM.

.PARAMETER LogRoot
    Ruta base donde se crea la carpeta WPSOffice-Removal y el fichero de log.

.PARAMETER UserRoot
    Ruta base donde se buscan carpetas de usuario. Valor por defecto: C:\Users.

.PARAMETER SkipDeepUserScan
    Omite la búsqueda recursiva bajo C:\Users de carpetas Kingsoft/WPS_DOWNLOAD y ficheros
    *SETUP_XA_MUI_FREE.EXE*. Solo elimina rutas candidatas conocidas.

.EXAMPLE
    .\Remove-WPSOffice-Ivanti.ps1

    Ejecuta la retirada completa de WPS Office y evidencias residuales.

.EXAMPLE
    .\Remove-WPSOffice-Ivanti.ps1 -WhatIf

    Simula las acciones destructivas sin modificar el equipo.

.EXAMPLE
    .\Remove-WPSOffice-Ivanti.ps1 -Verbose

    Ejecuta la remediación y muestra información adicional en consola.

.OUTPUTS
    PSCustomObject con resumen de ejecución, errores, advertencias, ruta de log, reinicio recomendado
    y evidencias restantes.

.NOTES
    Author        = IT Automation
    Version       = 1.0.0
    Creation date = 2026-04-28
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $LogRoot = 'C:\ProgramData\Ivanti\Logs',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]
    $UserRoot = 'C:\Users',

    [Parameter(Mandatory = $false)]
    [switch]
    $SkipDeepUserScan
)

begin {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $Script:LogFile = $null
    $Script:ErrorCount = 0
    $Script:WarningCount = 0
    $Script:RebootRecommended = $false
    $Script:PendingDeletePathList = New-Object -TypeName System.Collections.Generic.List[string]
    $Script:HandledUninstallKeyPathList = New-Object -TypeName System.Collections.Generic.List[string]

    $Script:WpsTextTermList = @(
        'wps',
        'kingsoft',
        'chromehost',
        'chromelauncher',
        'ksomisc',
        'wps_download',
        'setup_xa_mui_free',
        'wpsappext'
    )

    $Script:ProcessNameList = @(
        'wps',
        'et',
        'wpp',
        'wpspdf',
        'ksomisc',
        'chromelauncher',
        'wpscenter',
        'wpscloudsvr',
        'wpsnotify',
        'wpsupdate',
        'wpscloudlaunch',
        'wpsoffice',
        'qingshellext',
        'ksoqing'
    )
}

process {
    function Initialize-LogFile {
        [CmdletBinding()]
        param ()

        $logDirectory = Join-Path -Path $LogRoot -ChildPath 'WPSOffice-Removal'

        if (-not (Test-Path -LiteralPath $logDirectory)) {
            New-Item -Path $logDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        $runId = Get-Date -Format 'yyyyMMdd_HHmmss'
        $Script:LogFile = Join-Path -Path $logDirectory -ChildPath "Remove-WPSOffice_$env:COMPUTERNAME`_$runId.log"
        New-Item -Path $Script:LogFile -ItemType File -Force -ErrorAction Stop | Out-Null
    }


    function Write-Log {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')]
            [string]
            $Level,

            [Parameter(Mandatory = $true)]
            [AllowEmptyString()]
            [string]
            $Message
        )

        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $entry = "$timestamp [$Level] $Message"

        if ($Script:LogFile) {
            $entry | Out-File -FilePath $Script:LogFile -Encoding UTF8 -Append -ErrorAction Stop
        }

        switch ($Level) {
            'ERROR' {
                $Script:ErrorCount++
                Write-Error -Message $Message -ErrorAction Continue
            }
            'WARN' {
                $Script:WarningCount++
                Write-Warning -Message $Message
            }
            default {
                Write-Verbose -Message $Message
            }
        }
    }


    function Test-AdministratorOrSystem {
        [CmdletBinding()]
        [OutputType([bool])]
        param ()

        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $identity
        $isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        $isSystem = $identity.User.Value -eq 'S-1-5-18'

        $isAdministrator -or $isSystem
    }


    function Restart-InNativePowerShell {
        [CmdletBinding()]
        param ()

        if (-not [Environment]::Is64BitOperatingSystem) {
            return
        }

        if ([Environment]::Is64BitProcess) {
            return
        }

        $nativePowerShell = Join-Path -Path $env:WINDIR -ChildPath 'SysNative\WindowsPowerShell\v1.0\powershell.exe'

        if (-not (Test-Path -LiteralPath $nativePowerShell)) {
            return
        }

        $argumentList = New-Object -TypeName System.Collections.Generic.List[string]
        $argumentList.Add('-NoProfile')
        $argumentList.Add('-ExecutionPolicy')
        $argumentList.Add('Bypass')
        $argumentList.Add('-File')
        $argumentList.Add($PSCommandPath)

        foreach ($parameterItem in $PSBoundParameters.GetEnumerator()) {
            if ($parameterItem.Value -is [switch]) {
                if ($parameterItem.Value.IsPresent) {
                    $argumentList.Add("-$($parameterItem.Key)")
                }
            } else {
                $argumentList.Add("-$($parameterItem.Key)")
                $argumentList.Add([string]$parameterItem.Value)
            }
        }

        Start-Process -FilePath $nativePowerShell -ArgumentList $argumentList.ToArray() -Wait -NoNewWindow
        exit $LASTEXITCODE
    }


    function Test-WpsText {
        [CmdletBinding()]
        [OutputType([bool])]
        param (
            [Parameter(Mandatory = $false)]
            [AllowNull()]
            [string]
            $Text
        )

        $result = $false

        if (-not [string]::IsNullOrWhiteSpace($Text)) {
            $lowerText = $Text.ToLowerInvariant()

            foreach ($term in $Script:WpsTextTermList) {
                if ($lowerText.Contains($term)) {
                    $result = $true
                    break
                }
            }
        }

        $result
    }


    function Invoke-NativeProcess {
        [CmdletBinding()]
        [OutputType([int])]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $FilePath,

            [Parameter(Mandatory = $false)]
            [string[]]
            $ArgumentList = @()
        )

        $exitCode = -1

        if (-not (Test-Path -LiteralPath $FilePath)) {
            Write-Log -Level 'WARN' -Message "No existe el ejecutable: $FilePath"
            $exitCode
            return
        }

        try {
            $argumentText = $ArgumentList -join ' '
            Write-Log -Level 'INFO' -Message "Ejecutando: $FilePath $argumentText"

            $startProcessParameter = @{
                FilePath     = $FilePath
                ArgumentList = $ArgumentList
                Wait         = $true
                PassThru     = $true
                ErrorAction  = 'Stop'
            }

            $startedProcess = Start-Process @startProcessParameter
            $exitCode = [int]$startedProcess.ExitCode

            if ($exitCode -eq 0) {
                Write-Log -Level 'OK' -Message "ExitCode 0 en $FilePath"
            } else {
                Write-Log -Level 'WARN' -Message "ExitCode $exitCode en $FilePath"
            }
        }
        catch {
            Write-Log -Level 'ERROR' -Message "Error ejecutando ${FilePath}: $($_.Exception.Message)"
        }

        $exitCode
    }


    function Split-ExecutableCommand {
        [CmdletBinding()]
        [OutputType([pscustomobject])]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $CommandLine
        )

        $cleanCommandLine = $CommandLine.Trim()
        $executable = $null
        $argumentText = ''

        if ($cleanCommandLine.StartsWith('"')) {
            $closingQuoteIndex = $cleanCommandLine.IndexOf('"', 1)

            if ($closingQuoteIndex -gt 0) {
                $executable = $cleanCommandLine.Substring(1, $closingQuoteIndex - 1)
                $argumentText = $cleanCommandLine.Substring($closingQuoteIndex + 1).Trim()
            }
        } else {
            $exeIndex = $cleanCommandLine.IndexOf('.exe', [StringComparison]::OrdinalIgnoreCase)

            if ($exeIndex -ge 0) {
                $executable = $cleanCommandLine.Substring(0, $exeIndex + 4).Trim()
                $argumentText = $cleanCommandLine.Substring($exeIndex + 4).Trim()
            } else {
                $spaceIndex = $cleanCommandLine.IndexOf(' ')

                if ($spaceIndex -gt 0) {
                    $executable = $cleanCommandLine.Substring(0, $spaceIndex).Trim()
                    $argumentText = $cleanCommandLine.Substring($spaceIndex + 1).Trim()
                } else {
                    $executable = $cleanCommandLine
                }
            }
        }

        [pscustomobject]@{
            FilePath     = $executable
            ArgumentText = $argumentText
        }
    }


    function Test-SilentArgumentPresent {
        [CmdletBinding()]
        [OutputType([bool])]
        param (
            [Parameter(Mandatory = $false)]
            [AllowEmptyString()]
            [string]
            $ArgumentText
        )

        $result = $false
        $silentTermList = @('/s', '/silent', '/quiet', '/qn', '-s', '-silent', '--silent', '--quiet')
        $lowerText = $ArgumentText.ToLowerInvariant()

        foreach ($silentTerm in $silentTermList) {
            if ($lowerText.Contains($silentTerm)) {
                $result = $true
                break
            }
        }

        $result
    }


    function Stop-WpsProcess {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param ()

        Write-Log -Level 'INFO' -Message 'Deteniendo procesos relacionados con WPS Office...'

        $processList = Get-Process -ErrorAction SilentlyContinue |
            Where-Object { $Script:ProcessNameList -contains $_.ProcessName.ToLowerInvariant() }

        if (-not $processList) {
            Write-Log -Level 'INFO' -Message 'No hay procesos WPS/Kingsoft en ejecución.'
            return
        }

        foreach ($processItem in $processList) {
            $target = "$($processItem.ProcessName) PID=$($processItem.Id)"

            if ($PSCmdlet.ShouldProcess($target, 'Stop-Process')) {
                try {
                    Stop-Process -Id $processItem.Id -Force -ErrorAction Stop
                    Write-Log -Level 'OK' -Message "Proceso detenido: $target"
                }
                catch {
                    Write-Log -Level 'WARN' -Message "No se pudo detener ${target}: $($_.Exception.Message)"
                }
            }
        }
    }


    function Get-WpsUninstallEntryFromRoot {
        [CmdletBinding()]
        [OutputType([pscustomobject])]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $RootPath
        )

        if (-not (Test-Path -LiteralPath $RootPath)) {
            return
        }

        $childKeyList = Get-ChildItem -LiteralPath $RootPath -ErrorAction SilentlyContinue

        foreach ($childKey in $childKeyList) {
            try {
                $itemData = Get-ItemProperty -LiteralPath $childKey.PSPath -ErrorAction Stop
                $displayProperty = $itemData.PSObject.Properties['DisplayName']
                $publisherProperty = $itemData.PSObject.Properties['Publisher']
                $uninstallProperty = $itemData.PSObject.Properties['UninstallString']
                $quietUninstallProperty = $itemData.PSObject.Properties['QuietUninstallString']

                $displayText = ''
                $publisherText = ''
                $uninstallString = ''
                $quietUninstallString = ''

                if ($displayProperty) {
                    $displayText = [string]$displayProperty.Value
                }

                if ($publisherProperty) {
                    $publisherText = [string]$publisherProperty.Value
                }

                if ($uninstallProperty) {
                    $uninstallString = [string]$uninstallProperty.Value
                }

                if ($quietUninstallProperty) {
                    $quietUninstallString = [string]$quietUninstallProperty.Value
                }

                $childName = [string]$childKey.PSChildName

                $isWpsEntry = (Test-WpsText -Text $displayText) -or
                    (Test-WpsText -Text $publisherText) -or
                    ($childName -like '*Kingsoft*') -or
                    ($childName -like '*WPS*')

                if ($isWpsEntry) {
                    [pscustomobject]@{
                        KeyPath              = $childKey.PSPath
                        DisplayName          = $displayText
                        Publisher            = $publisherText
                        UninstallString      = $uninstallString
                        QuietUninstallString = $quietUninstallString
                    }
                }
            }
            catch {
                Write-Log -Level 'WARN' -Message "No se pudo inspeccionar $($childKey.PSPath): $($_.Exception.Message)"
            }
        }
    }


    function Invoke-WpsUninstallEntry {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [pscustomobject]
            $Entry
        )

        if ($Script:HandledUninstallKeyPathList.Contains([string]$Entry.KeyPath)) {
            return
        }

        $Script:HandledUninstallKeyPathList.Add([string]$Entry.KeyPath)

        $commandText = $Entry.QuietUninstallString

        if ([string]::IsNullOrWhiteSpace($commandText)) {
            $commandText = $Entry.UninstallString
        }

        if ([string]::IsNullOrWhiteSpace($commandText)) {
            Write-Log -Level 'WARN' -Message "Entrada sin UninstallString: $($Entry.DisplayName) - $($Entry.KeyPath)"
            return
        }

        $targetName = "$($Entry.DisplayName) [$($Entry.KeyPath)]"

        if (-not $PSCmdlet.ShouldProcess($targetName, 'Ejecutar desinstalador WPS')) {
            return
        }

        Write-Log -Level 'INFO' -Message "UninstallString detectado para WPS: $commandText"

        if ($commandText.ToLowerInvariant().Contains('msiexec')) {
            $guidScan = [regex]::Match($commandText, '\{[0-9A-Fa-f\-]{36}\}')

            if ($guidScan.Success) {
                [void](Invoke-NativeProcess -FilePath "$env:WINDIR\System32\msiexec.exe" -ArgumentList @(
                    '/x',
                    $guidScan.Value,
                    '/qn',
                    '/norestart'
                ))
            } else {
                Write-Log -Level 'WARN' -Message "No se encontró ProductCode MSI en: $commandText"
            }

            return
        }

        $commandPart = Split-ExecutableCommand -CommandLine $commandText

        if ([string]::IsNullOrWhiteSpace($commandPart.FilePath)) {
            Write-Log -Level 'WARN' -Message "No se pudo resolver ejecutable en UninstallString: $commandText"
            return
        }

        $argumentList = New-Object -TypeName System.Collections.Generic.List[string]

        if (-not [string]::IsNullOrWhiteSpace($commandPart.ArgumentText)) {
            $argumentList.Add($commandPart.ArgumentText)
        }

        if (-not (Test-SilentArgumentPresent -ArgumentText $commandPart.ArgumentText)) {
            $argumentList.Add('/s')
        }

        [void](Invoke-NativeProcess -FilePath $commandPart.FilePath -ArgumentList $argumentList.ToArray())
    }


    function Invoke-WpsUninstallFromRoot {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $RootPath
        )

        $entryList = Get-WpsUninstallEntryFromRoot -RootPath $RootPath

        foreach ($entryItem in $entryList) {
            Invoke-WpsUninstallEntry -Entry $entryItem
        }
    }


    function Invoke-WpsUninstallFromFile {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $SearchRoot
        )

        if (-not (Test-Path -LiteralPath $SearchRoot)) {
            return
        }

        $uninstallerFileList = Get-ChildItem -LiteralPath $SearchRoot -Filter 'uninst.exe' -File -Recurse `
            -ErrorAction SilentlyContinue

        foreach ($uninstallerFile in $uninstallerFileList) {
            if ($PSCmdlet.ShouldProcess($uninstallerFile.FullName, 'Ejecutar uninst.exe /s')) {
                Write-Log -Level 'INFO' -Message "Ejecutando desinstalador localizado: $($uninstallerFile.FullName)"
                [void](Invoke-NativeProcess -FilePath $uninstallerFile.FullName -ArgumentList @('/s'))
            }
        }
    }


    function Remove-WpsAppxPackage {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param ()

        $getAppxCommand = Get-Command -Name 'Get-AppxPackage' -ErrorAction SilentlyContinue
        $removeAppxCommand = Get-Command -Name 'Remove-AppxPackage' -ErrorAction SilentlyContinue

        if ($getAppxCommand -and $removeAppxCommand) {
            try {
                $appxPackageList = Get-AppxPackage -AllUsers -ErrorAction Stop |
                    Where-Object { $_.Name -like 'wpsappext*' -or $_.PackageFullName -like '*wpsappext*' }

                foreach ($appxPackage in $appxPackageList) {
                    if ($PSCmdlet.ShouldProcess($appxPackage.PackageFullName, 'Remove-AppxPackage')) {
                        try {
                            $removeParameter = @{
                                Package     = $appxPackage.PackageFullName
                                ErrorAction = 'Stop'
                            }

                            if ($removeAppxCommand.Parameters.ContainsKey('AllUsers')) {
                                $removeParameter['AllUsers'] = $true
                            }

                            Remove-AppxPackage @removeParameter
                            Write-Log -Level 'OK' -Message "Paquete AppX eliminado: $($appxPackage.PackageFullName)"
                        }
                        catch {
                            Write-Log -Level 'WARN' -Message (
                                "No se pudo eliminar AppX $($appxPackage.PackageFullName): $($_.Exception.Message)"
                            )
                        }
                    }
                }
            }
            catch {
                Write-Log -Level 'WARN' -Message "No se pudieron consultar paquetes AppX: $($_.Exception.Message)"
            }
        }

        $getProvisionedCommand = Get-Command -Name 'Get-AppxProvisionedPackage' -ErrorAction SilentlyContinue
        $removeProvisionedCommand = Get-Command -Name 'Remove-AppxProvisionedPackage' -ErrorAction SilentlyContinue

        if ($getProvisionedCommand -and $removeProvisionedCommand) {
            try {
                $provisionedPackageList = Get-AppxProvisionedPackage -Online -ErrorAction Stop |
                    Where-Object { $_.DisplayName -like 'wpsappext*' -or $_.PackageName -like '*wpsappext*' }

                foreach ($provisionedPackage in $provisionedPackageList) {
                    if ($PSCmdlet.ShouldProcess($provisionedPackage.PackageName, 'Remove-AppxProvisionedPackage')) {
                        try {
                            Remove-AppxProvisionedPackage -Online -PackageName $provisionedPackage.PackageName `
                                -ErrorAction Stop | Out-Null
                            Write-Log -Level 'OK' -Message "Paquete AppX provisionado eliminado: $($provisionedPackage.PackageName)"
                        }
                        catch {
                            Write-Log -Level 'WARN' -Message (
                                "No se pudo eliminar AppX provisionado $($provisionedPackage.PackageName): " +
                                "$($_.Exception.Message)"
                            )
                        }
                    }
                }
            }
            catch {
                Write-Log -Level 'WARN' -Message "No se pudieron consultar paquetes AppX provisionados: $($_.Exception.Message)"
            }
        }
    }


    function Register-DeleteOnReboot {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path
        )

        $sessionManagerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'
        $valueName = 'PendingFileRenameOperations'
        $nativePath = "\??\$Path"

        if ($PSCmdlet.ShouldProcess($Path, 'Registrar eliminación al reinicio')) {
            try {
                $existingValue = (Get-ItemProperty -LiteralPath $sessionManagerPath -Name $valueName `
                    -ErrorAction SilentlyContinue).$valueName

                $pendingList = New-Object -TypeName System.Collections.Generic.List[string]

                if ($existingValue) {
                    foreach ($existingItem in $existingValue) {
                        $pendingList.Add([string]$existingItem)
                    }
                }

                if (-not $pendingList.Contains($nativePath)) {
                    $pendingList.Add($nativePath)
                    $pendingList.Add('')
                }

                Set-ItemProperty -LiteralPath $sessionManagerPath -Name $valueName -Type MultiString `
                    -Value $pendingList.ToArray() -ErrorAction Stop

                if (-not $Script:PendingDeletePathList.Contains($Path)) {
                    $Script:PendingDeletePathList.Add($Path)
                }

                $Script:RebootRecommended = $true
                Write-Log -Level 'WARN' -Message "Eliminación diferida al reinicio programada para: $Path"
            }
            catch {
                Write-Log -Level 'ERROR' -Message "No se pudo registrar eliminación diferida para ${Path}: $($_.Exception.Message)"
            }
        }
    }


    function Remove-PathRobust {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path
        )

        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Log -Level 'INFO' -Message "No existe: $Path"
            return
        }

        if (-not $PSCmdlet.ShouldProcess($Path, 'Eliminar ruta')) {
            return
        }

        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            Write-Log -Level 'OK' -Message "Eliminado: $Path"
            return
        }
        catch {
            Write-Log -Level 'WARN' -Message "Primer intento fallido al eliminar ${Path}: $($_.Exception.Message)"
        }

        $attribPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\attrib.exe'
        $takeOwnPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\takeown.exe'
        $icaclsPath = Join-Path -Path $env:WINDIR -ChildPath 'System32\icacls.exe'

        if (Test-Path -LiteralPath $attribPath) {
            [void](Invoke-NativeProcess -FilePath $attribPath -ArgumentList @('-R', '-S', '-H', $Path, '/S', '/D'))
        }

        if (Test-Path -LiteralPath $takeOwnPath) {
            $takeOwnArgumentList = @('/F', $Path, '/A')

            if ((Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue).PSIsContainer) {
                $takeOwnArgumentList += @('/R', '/D', 'Y')
            }

            [void](Invoke-NativeProcess -FilePath $takeOwnPath -ArgumentList $takeOwnArgumentList)
        }

        if (Test-Path -LiteralPath $icaclsPath) {
            [void](Invoke-NativeProcess -FilePath $icaclsPath -ArgumentList @(
                $Path,
                '/grant',
                '*S-1-5-32-544:F',
                '/T',
                '/C'
            ))
        }

        try {
            Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            Write-Log -Level 'OK' -Message "Eliminado tras tomar control: $Path"
        }
        catch {
            Write-Log -Level 'WARN' -Message "Segundo intento fallido al eliminar ${Path}: $($_.Exception.Message)"
            Register-DeleteOnReboot -Path $Path
        }
    }


    function Remove-RegistryTree {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path
        )

        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Log -Level 'INFO' -Message "Clave no presente: $Path"
            return
        }

        if ($PSCmdlet.ShouldProcess($Path, 'Eliminar clave de registro')) {
            try {
                Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
                Write-Log -Level 'OK' -Message "Clave eliminada: $Path"
            }
            catch {
                Write-Log -Level 'WARN' -Message "No se pudo eliminar clave ${Path}: $($_.Exception.Message)"
            }
        }
    }


    function Remove-RegistryValueWhenDataContainsWps {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path
        )

        if (-not (Test-Path -LiteralPath $Path)) {
            return
        }

        try {
            $itemProperty = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
            $propertyList = $itemProperty.PSObject.Properties |
                Where-Object { $_.Name -notlike 'PS*' }

            foreach ($propertyItem in $propertyList) {
                $valueText = [string]$propertyItem.Value

                if ((Test-WpsText -Text $propertyItem.Name) -or (Test-WpsText -Text $valueText)) {
                    $target = "$Path\$($propertyItem.Name)"

                    if ($PSCmdlet.ShouldProcess($target, 'Eliminar valor de registro')) {
                        try {
                            Remove-ItemProperty -LiteralPath $Path -Name $propertyItem.Name -Force -ErrorAction Stop
                            Write-Log -Level 'OK' -Message "Valor eliminado: $target"
                        }
                        catch {
                            Write-Log -Level 'WARN' -Message "No se pudo eliminar valor ${target}: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
        catch {
            Write-Log -Level 'WARN' -Message "No se pudo inspeccionar valores en ${Path}: $($_.Exception.Message)"
        }
    }


    function Remove-WpsUninstallRegistryFromRoot {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $RootPath
        )

        if (-not (Test-Path -LiteralPath $RootPath)) {
            Write-Log -Level 'INFO' -Message "Ruta de desinstalación no presente: $RootPath"
            return
        }

        $exactKeyList = @(
            (Join-Path -Path $RootPath -ChildPath 'Kingsoft Office')
            (Join-Path -Path $RootPath -ChildPath 'WPS Office')
        )

        foreach ($exactKey in $exactKeyList) {
            Remove-RegistryTree -Path $exactKey
        }

        $entryList = Get-WpsUninstallEntryFromRoot -RootPath $RootPath

        foreach ($entryItem in $entryList) {
            Remove-RegistryTree -Path $entryItem.KeyPath
        }
    }


    function Test-WpsRegistryKeyContent {
        [CmdletBinding()]
        [OutputType([bool])]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path
        )

        $hasWpsContent = $false

        try {
            $registryItem = Get-Item -LiteralPath $Path -ErrorAction Stop
            $textItemList = New-Object -TypeName System.Collections.Generic.List[string]
            $textItemList.Add([string]$Path)
            $textItemList.Add([string]$registryItem.PSChildName)

            foreach ($valueName in $registryItem.GetValueNames()) {
                $textItemList.Add([string]$valueName)
                $valueData = $registryItem.GetValue($valueName)

                if ($valueData -is [array]) {
                    $textItemList.Add(($valueData -join ' '))
                } else {
                    $textItemList.Add([string]$valueData)
                }
            }

            $hasWpsContent = Test-WpsText -Text ($textItemList -join ' ')
        }
        catch {
            Write-Log -Level 'WARN' -Message "No se pudo inspeccionar clave ${Path}: $($_.Exception.Message)"
        }

        $hasWpsContent
    }


    function Remove-WpsRegistryChildrenByContent {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $RootPath
        )

        if (-not (Test-Path -LiteralPath $RootPath)) {
            return
        }

        $childKeyList = Get-ChildItem -LiteralPath $RootPath -ErrorAction SilentlyContinue

        foreach ($childKey in $childKeyList) {
            if (Test-WpsRegistryKeyContent -Path $childKey.PSPath) {
                Remove-RegistryTree -Path $childKey.PSPath
            }
        }
    }


    function Remove-WpsClassIdReference {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $ClassId,

            [Parameter(Mandatory = $false)]
            [string]
            $HiveRootName
        )

        $classRootList = New-Object -TypeName System.Collections.Generic.List[string]
        $classRootList.Add((Join-PathMany -Root 'HKLM:' -SegmentList @('SOFTWARE', 'Classes', 'CLSID')))
        $classRootList.Add((Join-PathMany -Root 'HKLM:' -SegmentList @('SOFTWARE', 'WOW6432Node', 'Classes', 'CLSID')))

        if (-not [string]::IsNullOrWhiteSpace($HiveRootName)) {
            $userRoot = Join-Path -Path 'Registry::HKEY_USERS' -ChildPath $HiveRootName
            $classRootList.Add((Join-PathMany -Root $userRoot -SegmentList @('Software', 'Classes', 'CLSID')))
            $classRootList.Add((Join-PathMany -Root $userRoot -SegmentList @('Software', 'Classes', 'WOW6432Node', 'CLSID')))
        }

        foreach ($classRoot in $classRootList) {
            $classPath = Join-Path -Path $classRoot -ChildPath $ClassId

            if (Test-Path -LiteralPath $classPath) {
                Remove-RegistryTree -Path $classPath
            }
        }
    }


    function Remove-WpsExplorerNamespaceRoot {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $RootPath,

            [Parameter(Mandatory = $false)]
            [string]
            $HiveRootName
        )

        if (-not (Test-Path -LiteralPath $RootPath)) {
            return
        }

        $childKeyList = Get-ChildItem -LiteralPath $RootPath -ErrorAction SilentlyContinue

        foreach ($childKey in $childKeyList) {
            if (Test-WpsRegistryKeyContent -Path $childKey.PSPath) {
                $classId = [string]$childKey.PSChildName
                Remove-RegistryTree -Path $childKey.PSPath

                if ($classId -like '{*}') {
                    Remove-WpsClassIdReference -ClassId $classId -HiveRootName $HiveRootName
                }
            }
        }
    }


    function Remove-WpsExplorerNamespaceFromHive {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $HiveRootName
        )

        $userRoot = Join-Path -Path 'Registry::HKEY_USERS' -ChildPath $HiveRootName
        $namespaceRootList = @(
            (Join-PathMany -Root $userRoot -SegmentList @('Software', 'Microsoft', 'Windows', 'CurrentVersion', 'Explorer', 'Desktop', 'NameSpace')),
            (Join-PathMany -Root $userRoot -SegmentList @('Software', 'Microsoft', 'Windows', 'CurrentVersion', 'Explorer', 'MyComputer', 'NameSpace')),
            (Join-PathMany -Root $userRoot -SegmentList @('Software', 'Microsoft', 'Windows', 'CurrentVersion', 'Explorer', 'MountPoints2'))
        )

        foreach ($namespaceRoot in $namespaceRootList) {
            Remove-WpsExplorerNamespaceRoot -RootPath $namespaceRoot -HiveRootName $HiveRootName
        }
    }


    function Remove-WpsMachineExplorerNamespaceEvidence {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param ()

        Write-Log -Level 'INFO' -Message 'Limpiando namespace WPSDrive de Explorador de archivos a nivel de máquina...'

        $namespaceRootList = @(
            (Join-PathMany -Root 'HKLM:' -SegmentList @('SOFTWARE', 'Microsoft', 'Windows', 'CurrentVersion', 'Explorer', 'Desktop', 'NameSpace')),
            (Join-PathMany -Root 'HKLM:' -SegmentList @('SOFTWARE', 'Microsoft', 'Windows', 'CurrentVersion', 'Explorer', 'MyComputer', 'NameSpace')),
            (Join-PathMany -Root 'HKLM:' -SegmentList @('SOFTWARE', 'WOW6432Node', 'Microsoft', 'Windows', 'CurrentVersion', 'Explorer', 'Desktop', 'NameSpace')),
            (Join-PathMany -Root 'HKLM:' -SegmentList @('SOFTWARE', 'WOW6432Node', 'Microsoft', 'Windows', 'CurrentVersion', 'Explorer', 'MyComputer', 'NameSpace'))
        )

        foreach ($namespaceRoot in $namespaceRootList) {
            Remove-WpsExplorerNamespaceRoot -RootPath $namespaceRoot
        }

        Remove-WpsRegistryChildrenByContent -RootPath (Join-PathMany -Root 'HKLM:' -SegmentList @('SOFTWARE', 'Classes', 'CLSID'))
        Remove-WpsRegistryChildrenByContent -RootPath (Join-PathMany -Root 'HKLM:' -SegmentList @('SOFTWARE', 'WOW6432Node', 'Classes', 'CLSID'))
    }


    function Remove-WpsRegistryFromHive {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $HiveRootName
        )

        $registryRoot = "Registry::HKEY_USERS\$HiveRootName"

        Write-Log -Level 'INFO' -Message "Limpieza de registro WPS para hive $HiveRootName"

        Remove-RegistryTree -Path "$registryRoot\Software\Kingsoft"
        Remove-RegistryTree -Path "$registryRoot\Software\WPS Office"

        Remove-RegistryValueWhenDataContainsWps -Path "$registryRoot\Software\Microsoft\Windows\CurrentVersion\Run"
        Remove-RegistryValueWhenDataContainsWps -Path "$registryRoot\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        Remove-RegistryValueWhenDataContainsWps -Path (
            "$registryRoot\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
        )

        Remove-WpsUninstallRegistryFromRoot -RootPath (
            "$registryRoot\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        Remove-WpsUninstallRegistryFromRoot -RootPath (
            "$registryRoot\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )
    }


    function Get-UserHiveItem {
        [CmdletBinding()]
        [OutputType([pscustomobject])]
        param ()

        $registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

        if (-not (Test-Path -LiteralPath $registryPath)) {
            return
        }

        $keyList = Get-ChildItem -LiteralPath $registryPath -ErrorAction SilentlyContinue

        foreach ($keyItem in $keyList) {
            try {
                $itemData = Get-ItemProperty -LiteralPath $keyItem.PSPath -ErrorAction Stop
                $sid = [string]$keyItem.PSChildName
                $imagePath = [string]$itemData.ProfileImagePath

                if ($sid -notlike 'S-1-5-21-*') {
                    continue
                }

                if ([string]::IsNullOrWhiteSpace($imagePath)) {
                    continue
                }

                $expandedPath = [Environment]::ExpandEnvironmentVariables($imagePath)

                [pscustomobject]@{
                    Sid        = $sid
                    AccountDir = $expandedPath
                    NtUserDat  = Join-Path -Path $expandedPath -ChildPath 'NTUSER.DAT'
                }
            }
            catch {
                Write-Log -Level 'WARN' -Message "No se pudo leer ProfileList en $($keyItem.PSPath): $($_.Exception.Message)"
            }
        }
    }


    function Invoke-WithUserHive {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [pscustomobject]
            $UserHiveItem
        )

        $sid = [string]$UserHiveItem.Sid
        $loadedHivePath = "Registry::HKEY_USERS\$sid"
        $hiveRootName = $sid
        $loadedByScript = $false

        if (-not (Test-Path -LiteralPath $loadedHivePath)) {
            if (-not (Test-Path -LiteralPath $UserHiveItem.NtUserDat)) {
                Write-Log -Level 'WARN' -Message "No existe NTUSER.DAT para ${sid}: $($UserHiveItem.NtUserDat)"
                return
            }

            $safeSid = $sid -replace '[^A-Za-z0-9]', '_'
            $hiveRootName = "WPSRemoval_$safeSid"
            $mountPath = "HKU\$hiveRootName"
            $regExe = Join-Path -Path $env:WINDIR -ChildPath 'System32\reg.exe'

            if ($PSCmdlet.ShouldProcess($sid, 'Cargar hive de usuario')) {
                $loadExitCode = Invoke-NativeProcess -FilePath $regExe -ArgumentList @(
                    'load',
                    $mountPath,
                    $UserHiveItem.NtUserDat
                )

                if ($loadExitCode -ne 0) {
                    Write-Log -Level 'WARN' -Message "No se pudo cargar hive de $sid"
                    return
                }

                $loadedByScript = $true
            }
        }

        try {
            Remove-WpsRegistryFromHive -HiveRootName $hiveRootName
            Remove-WpsExplorerNamespaceFromHive -HiveRootName $hiveRootName
        }
        finally {
            if ($loadedByScript) {
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
                Start-Sleep -Seconds 1

                $regExe = Join-Path -Path $env:WINDIR -ChildPath 'System32\reg.exe'
                [void](Invoke-NativeProcess -FilePath $regExe -ArgumentList @('unload', "HKU\$hiveRootName"))
            }
        }
    }


    function Get-UserDirectoryItem {
        [CmdletBinding()]
        [OutputType([System.IO.DirectoryInfo])]
        param ()

        if (-not (Test-Path -LiteralPath $UserRoot)) {
            return
        }

        $excludedNameList = @('All Users', 'Default', 'Default User', 'Public', 'desktop.ini')

        Get-ChildItem -LiteralPath $UserRoot -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object {
                ($excludedNameList -notcontains $_.Name) -and
                (($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq 0)
            }
    }


    function Join-PathMany {
        [CmdletBinding()]
        [OutputType([string])]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Root,

            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string[]]
            $SegmentList
        )

        $combinedPath = $Root

        foreach ($segmentItem in $SegmentList) {
            $combinedPath = Join-Path -Path $combinedPath -ChildPath $segmentItem
        }

        $combinedPath
    }


    function Test-WpsShortcutFile {
        [CmdletBinding()]
        [OutputType([bool])]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path
        )

        $isWpsShortcut = Test-WpsText -Text ([System.IO.Path]::GetFileNameWithoutExtension($Path))

        if ($isWpsShortcut) {
            $isWpsShortcut
            return
        }

        $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()

        if ($extension -eq '.url') {
            try {
                $urlContent = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
                $isWpsShortcut = Test-WpsText -Text $urlContent
            }
            catch {
                Write-Log -Level 'WARN' -Message "No se pudo inspeccionar URL ${Path}: $($_.Exception.Message)"
            }

            $isWpsShortcut
            return
        }

        if ($extension -ne '.lnk') {
            $isWpsShortcut
            return
        }

        $shellObject = $null
        $shortcutObject = $null

        try {
            $shellObject = New-Object -ComObject WScript.Shell
            $shortcutObject = $shellObject.CreateShortcut($Path)
            $shortcutText = @(
                [string]$shortcutObject.TargetPath,
                [string]$shortcutObject.Arguments,
                [string]$shortcutObject.WorkingDirectory,
                [string]$shortcutObject.IconLocation,
                [string]$shortcutObject.Description
            ) -join ' '

            $isWpsShortcut = Test-WpsText -Text $shortcutText
        }
        catch {
            Write-Log -Level 'WARN' -Message "No se pudo inspeccionar acceso directo ${Path}: $($_.Exception.Message)"
        }
        finally {
            if ($shortcutObject) {
                [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shortcutObject)
            }

            if ($shellObject) {
                [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shellObject)
            }
        }

        $isWpsShortcut
    }


    function Remove-WpsShortcutFromPath {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param (
            [Parameter(Mandatory = $true)]
            [ValidateNotNullOrEmpty()]
            [string]
            $Path
        )

        if (-not (Test-Path -LiteralPath $Path)) {
            return
        }

        $shortcutFileList = Get-ChildItem -LiteralPath $Path -File -Force -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in '.lnk', '.url', '.appref-ms' }

        foreach ($shortcutFile in $shortcutFileList) {
            if (Test-WpsShortcutFile -Path $shortcutFile.FullName) {
                Remove-PathRobust -Path $shortcutFile.FullName
            }
        }

        $emptyDirectoryList = Get-ChildItem -LiteralPath $Path -Directory -Force -Recurse -ErrorAction SilentlyContinue |
            Sort-Object -Property FullName -Descending

        foreach ($emptyDirectory in $emptyDirectoryList) {
            try {
                $childItem = Get-ChildItem -LiteralPath $emptyDirectory.FullName -Force -ErrorAction Stop

                if (-not $childItem) {
                    Remove-PathRobust -Path $emptyDirectory.FullName
                }
            }
            catch {
                Write-Log -Level 'WARN' -Message "No se pudo evaluar carpeta vacía $($emptyDirectory.FullName): $($_.Exception.Message)"
            }
        }
    }


    function Remove-WpsShortcutEvidence {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param ()

        Write-Log -Level 'INFO' -Message 'Limpiando accesos directos WPS en escritorio, menú inicio y barra de tareas...'

        $commonShortcutRootList = @(
            [Environment]::GetFolderPath('CommonDesktopDirectory'),
            (Join-Path -Path ([Environment]::GetFolderPath('CommonStartMenu')) -ChildPath 'Programs')
        )

        foreach ($commonShortcutRoot in $commonShortcutRootList) {
            if (-not [string]::IsNullOrWhiteSpace($commonShortcutRoot)) {
                Remove-WpsShortcutFromPath -Path $commonShortcutRoot
            }
        }

        foreach ($userDirectory in (Get-UserDirectoryItem)) {
            $userShortcutRootList = @(
                (Join-PathMany -Root $userDirectory.FullName -SegmentList @('Desktop')),
                (Join-PathMany -Root $userDirectory.FullName -SegmentList @('OneDrive', 'Desktop')),
                (Join-PathMany -Root $userDirectory.FullName -SegmentList @('AppData', 'Roaming', 'Microsoft', 'Windows', 'Start Menu', 'Programs')),
                (Join-PathMany -Root $userDirectory.FullName -SegmentList @('AppData', 'Roaming', 'Microsoft', 'Internet Explorer', 'Quick Launch', 'User Pinned', 'TaskBar')),
                (Join-PathMany -Root $userDirectory.FullName -SegmentList @('AppData', 'Roaming', 'Microsoft', 'Internet Explorer', 'Quick Launch', 'User Pinned', 'StartMenu'))
            )

            foreach ($userShortcutRoot in $userShortcutRootList) {
                Remove-WpsShortcutFromPath -Path $userShortcutRoot
            }
        }
    }


    function Remove-WpsUserFileEvidence {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param ()

        $userDirectoryList = Get-UserDirectoryItem

        foreach ($userDirectory in $userDirectoryList) {
            Write-Log -Level 'INFO' -Message "Limpieza de evidencias WPS en usuario: $($userDirectory.FullName)"

            $knownPathList = @(
                (Join-Path -Path $userDirectory.FullName -ChildPath 'AppData\Local\Kingsoft'),
                (Join-Path -Path $userDirectory.FullName -ChildPath 'AppData\Roaming\Kingsoft'),
                (Join-Path -Path $userDirectory.FullName -ChildPath 'AppData\Local\WPS_DOWNLOAD'),
                (Join-Path -Path $userDirectory.FullName -ChildPath 'AppData\Roaming\WPS_DOWNLOAD'),
                (Join-Path -Path $userDirectory.FullName -ChildPath 'Downloads\WPS_DOWNLOAD'),
                (Join-Path -Path $userDirectory.FullName -ChildPath 'Download\WPS_DOWNLOAD')
            )

            $knownPathList += (Join-Path -Path $userDirectory.FullName -ChildPath 'WPSDrive')

            foreach ($knownPath in $knownPathList) {
                Remove-PathRobust -Path $knownPath
            }

            if ($SkipDeepUserScan) {
                continue
            }

            $deepDirectoryList = @()

            foreach ($directoryName in @('Kingsoft', 'WPS_DOWNLOAD')) {
                $deepDirectoryList += Get-ChildItem -LiteralPath $userDirectory.FullName -Directory `
                    -Filter $directoryName -Recurse -Force -ErrorAction SilentlyContinue
            }

            foreach ($deepDirectory in ($deepDirectoryList | Sort-Object -Property FullName -Unique)) {
                Remove-PathRobust -Path $deepDirectory.FullName
            }

            $setupFileList = Get-ChildItem -LiteralPath $userDirectory.FullName -File `
                -Filter '*SETUP_XA_MUI_FREE.EXE*' -Recurse -Force -ErrorAction SilentlyContinue

            foreach ($setupFile in $setupFileList) {
                Remove-PathRobust -Path $setupFile.FullName
            }
        }
    }


    function Remove-WpsMachineFileEvidence {
        [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
        param ()

        $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)', 'Machine')
        $programFiles = [Environment]::GetFolderPath('ProgramFiles')
        $programData = [Environment]::GetFolderPath('CommonApplicationData')

        $machinePathList = New-Object -TypeName System.Collections.Generic.List[string]

        if (-not [string]::IsNullOrWhiteSpace($programFilesX86)) {
            $machinePathList.Add((Join-Path -Path $programFilesX86 -ChildPath 'WPS Office'))
        }

        if (-not [string]::IsNullOrWhiteSpace($programFiles)) {
            $machinePathList.Add((Join-Path -Path $programFiles -ChildPath 'WPS Office'))
            $machinePathList.Add((Join-Path -Path $programFiles -ChildPath 'Kingsoft'))
        }

        if (-not [string]::IsNullOrWhiteSpace($programData)) {
            $machinePathList.Add((Join-Path -Path $programData -ChildPath 'Kingsoft'))
            $machinePathList.Add((Join-Path -Path $programData -ChildPath 'WPS Office'))
            $machinePathList.Add((Join-Path -Path $programData -ChildPath 'WPS'))
        }

        foreach ($machinePath in ($machinePathList | Sort-Object -Unique)) {
            Remove-PathRobust -Path $machinePath
        }

        $windowsAppsPath = Join-Path -Path $programFiles -ChildPath 'WindowsApps'

        if (Test-Path -LiteralPath $windowsAppsPath) {
            try {
                $windowsAppEvidenceList = Get-ChildItem -LiteralPath $windowsAppsPath -Directory `
                    -Filter '*wpsappext*' -Force -ErrorAction Stop

                foreach ($windowsAppEvidence in $windowsAppEvidenceList) {
                    Remove-PathRobust -Path $windowsAppEvidence.FullName
                }
            }
            catch {
                Write-Log -Level 'WARN' -Message "No se pudo inspeccionar WindowsApps: $($_.Exception.Message)"
            }
        }
    }


    function Remove-WpsMachineRegistryEvidence {
        [CmdletBinding()]
        param ()

        Write-Log -Level 'INFO' -Message 'Limpiando registro WPS a nivel de máquina...'

        Remove-RegistryValueWhenDataContainsWps -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
        Remove-RegistryValueWhenDataContainsWps -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
        Remove-RegistryValueWhenDataContainsWps -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
        Remove-RegistryValueWhenDataContainsWps -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\RunOnce'

        Remove-RegistryTree -Path 'HKLM:\SOFTWARE\Kingsoft'
        Remove-RegistryTree -Path 'HKLM:\SOFTWARE\WOW6432Node\Kingsoft'
        Remove-RegistryTree -Path 'HKLM:\SOFTWARE\WPS Office'
        Remove-RegistryTree -Path 'HKLM:\SOFTWARE\WOW6432Node\WPS Office'

        Remove-WpsUninstallRegistryFromRoot -RootPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        Remove-WpsUninstallRegistryFromRoot -RootPath (
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
        )
    }


    function Invoke-WpsUninstallDiscovery {
        [CmdletBinding()]
        param ()

        Write-Log -Level 'INFO' -Message 'Buscando entradas de desinstalación WPS/Kingsoft...'

        Invoke-WpsUninstallFromRoot -RootPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        Invoke-WpsUninstallFromRoot -RootPath 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

        $userHiveList = Get-UserHiveItem

        foreach ($userHiveItem in $userHiveList) {
            $sid = [string]$userHiveItem.Sid
            $hiveRootName = $sid
            $loadedByScript = $false

            if (-not (Test-Path -LiteralPath "Registry::HKEY_USERS\$sid")) {
                if (-not (Test-Path -LiteralPath $userHiveItem.NtUserDat)) {
                    continue
                }

                $safeSid = $sid -replace '[^A-Za-z0-9]', '_'
                $hiveRootName = "WPSRemoval_$safeSid"
                $regExe = Join-Path -Path $env:WINDIR -ChildPath 'System32\reg.exe'

                if ($PSCmdlet.ShouldProcess($sid, 'Cargar hive para detectar UninstallString')) {
                    $loadExitCode = Invoke-NativeProcess -FilePath $regExe -ArgumentList @(
                        'load',
                        "HKU\$hiveRootName",
                        $userHiveItem.NtUserDat
                    )

                    if ($loadExitCode -ne 0) {
                        continue
                    }

                    $loadedByScript = $true
                }
            }

            try {
                Invoke-WpsUninstallFromRoot -RootPath (
                    "Registry::HKEY_USERS\$hiveRootName\Software\Microsoft\Windows\CurrentVersion\Uninstall"
                )
                Invoke-WpsUninstallFromRoot -RootPath (
                    "Registry::HKEY_USERS\$hiveRootName\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                )
            }
            finally {
                if ($loadedByScript) {
                    [GC]::Collect()
                    [GC]::WaitForPendingFinalizers()
                    Start-Sleep -Seconds 1

                    $regExe = Join-Path -Path $env:WINDIR -ChildPath 'System32\reg.exe'
                    [void](Invoke-NativeProcess -FilePath $regExe -ArgumentList @('unload', "HKU\$hiveRootName"))
                }
            }
        }

        $searchRootList = New-Object -TypeName System.Collections.Generic.List[string]

        $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)', 'Machine')
        $programFiles = [Environment]::GetFolderPath('ProgramFiles')

        if ($programFilesX86) {
            $searchRootList.Add((Join-Path -Path $programFilesX86 -ChildPath 'WPS Office'))
        }

        if ($programFiles) {
            $searchRootList.Add((Join-Path -Path $programFiles -ChildPath 'WPS Office'))
        }

        foreach ($userDirectory in (Get-UserDirectoryItem)) {
            $searchRootList.Add((Join-Path -Path $userDirectory.FullName -ChildPath 'AppData\Local\Kingsoft\WPS Office'))
        }

        foreach ($searchRoot in ($searchRootList | Sort-Object -Unique)) {
            Invoke-WpsUninstallFromFile -SearchRoot $searchRoot
        }
    }


    function Remove-WpsUserRegistryEvidence {
        [CmdletBinding()]
        param ()

        Write-Log -Level 'INFO' -Message 'Limpiando registro WPS en todos los usuarios...'

        Remove-RegistryTree -Path 'HKCU:\Software\Kingsoft'
        Remove-RegistryTree -Path 'HKCU:\Software\WPS Office'

        $userHiveList = Get-UserHiveItem

        foreach ($userHiveItem in $userHiveList) {
            Write-Log -Level 'INFO' -Message "Procesando usuario $($userHiveItem.AccountDir) - SID $($userHiveItem.Sid)"
            Invoke-WithUserHive -UserHiveItem $userHiveItem
        }
    }


    function Test-WpsRemainingEvidence {
        [CmdletBinding()]
        [OutputType([pscustomobject])]
        param ()

        $remainingEvidenceList = New-Object -TypeName System.Collections.Generic.List[object]
        $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)', 'Machine')
        $programFiles = [Environment]::GetFolderPath('ProgramFiles')
        $programData = [Environment]::GetFolderPath('CommonApplicationData')

        $pathCandidateList = New-Object -TypeName System.Collections.Generic.List[string]

        if ($programFilesX86) {
            $pathCandidateList.Add((Join-Path -Path $programFilesX86 -ChildPath 'WPS Office'))
        }

        if ($programFiles) {
            $pathCandidateList.Add((Join-Path -Path $programFiles -ChildPath 'WPS Office'))
            $pathCandidateList.Add((Join-Path -Path $programFiles -ChildPath 'Kingsoft'))
        }

        if ($programData) {
            $pathCandidateList.Add((Join-Path -Path $programData -ChildPath 'Kingsoft'))
            $pathCandidateList.Add((Join-Path -Path $programData -ChildPath 'WPS Office'))
            $pathCandidateList.Add((Join-Path -Path $programData -ChildPath 'WPS'))
        }

        foreach ($userDirectory in (Get-UserDirectoryItem)) {
            $pathCandidateList.Add((Join-Path -Path $userDirectory.FullName -ChildPath 'AppData\Local\Kingsoft'))
            $pathCandidateList.Add((Join-Path -Path $userDirectory.FullName -ChildPath 'AppData\Roaming\Kingsoft'))
            $pathCandidateList.Add((Join-Path -Path $userDirectory.FullName -ChildPath 'AppData\Local\WPS_DOWNLOAD'))
            $pathCandidateList.Add((Join-Path -Path $userDirectory.FullName -ChildPath 'AppData\Roaming\WPS_DOWNLOAD'))
            $pathCandidateList.Add((Join-Path -Path $userDirectory.FullName -ChildPath 'Downloads\WPS_DOWNLOAD'))
        }

        foreach ($pathCandidate in ($pathCandidateList | Sort-Object -Unique)) {
            if (Test-Path -LiteralPath $pathCandidate) {
                $remainingEvidenceList.Add([pscustomobject]@{
                    Type = 'Path'
                    Data = $pathCandidate
                })
            }
        }

        if ($programFiles) {
            $windowsAppsPath = Join-Path -Path $programFiles -ChildPath 'WindowsApps'

            if (Test-Path -LiteralPath $windowsAppsPath) {
                $windowsAppEvidenceList = Get-ChildItem -LiteralPath $windowsAppsPath -Directory `
                    -Filter '*wpsappext*' -Force -ErrorAction SilentlyContinue

                foreach ($windowsAppEvidence in $windowsAppEvidenceList) {
                    $remainingEvidenceList.Add([pscustomobject]@{
                        Type = 'WindowsApps'
                        Data = $windowsAppEvidence.FullName
                    })
                }
            }
        }

        foreach ($rootPath in @(
            'HKLM:\SOFTWARE\Kingsoft',
            'HKLM:\SOFTWARE\WOW6432Node\Kingsoft',
            'HKLM:\SOFTWARE\WPS Office',
            'HKLM:\SOFTWARE\WOW6432Node\WPS Office'
        )) {
            if (Test-Path -LiteralPath $rootPath) {
                $remainingEvidenceList.Add([pscustomobject]@{
                    Type = 'Registry'
                    Data = $rootPath
                })
            }
        }

        $loadedUserRootList = Get-ChildItem -LiteralPath 'Registry::HKEY_USERS' -ErrorAction SilentlyContinue |
            Where-Object { $_.PSChildName -like 'S-1-5-21-*' }

        foreach ($loadedUserRoot in $loadedUserRootList) {
            foreach ($relativePath in @('Software\Kingsoft', 'Software\WPS Office')) {
                $registryCandidate = "Registry::HKEY_USERS\$($loadedUserRoot.PSChildName)\$relativePath"

                if (Test-Path -LiteralPath $registryCandidate) {
                    $remainingEvidenceList.Add([pscustomobject]@{
                        Type = 'Registry'
                        Data = $registryCandidate
                    })
                }
            }
        }

        $hardEvidenceList = New-Object -TypeName System.Collections.Generic.List[object]

        foreach ($remainingEvidence in $remainingEvidenceList) {
            if (-not $Script:PendingDeletePathList.Contains([string]$remainingEvidence.Data)) {
                $hardEvidenceList.Add($remainingEvidence)
            }
        }

        [pscustomobject]@{
            RemainingEvidence     = $remainingEvidenceList.ToArray()
            HardRemainingEvidence = $hardEvidenceList.ToArray()
        }
    }


    try {
        Restart-InNativePowerShell
        Initialize-LogFile

        Write-Log -Level 'OK' -Message (
            "Inicio de ejecución en $env:COMPUTERNAME - Usuario=$([Security.Principal.WindowsIdentity]::GetCurrent().Name)" +
            " - PowerShell=$($PSVersionTable.PSVersion)"
        )
        Write-Log -Level 'OK' -Message "Log: $Script:LogFile"

        if (-not (Test-AdministratorOrSystem)) {
            Write-Log -Level 'ERROR' -Message 'El script requiere ejecución elevada como Administrador local o SYSTEM.'
            exit 1
        }

        Stop-WpsProcess
        Invoke-WpsUninstallDiscovery
        Start-Sleep -Seconds 2
        Stop-WpsProcess

        Remove-WpsAppxPackage
        Remove-WpsMachineRegistryEvidence
        Remove-WpsMachineExplorerNamespaceEvidence
        Remove-WpsUserRegistryEvidence
        Remove-WpsShortcutEvidence
        Remove-WpsMachineFileEvidence
        Remove-WpsUserFileEvidence
        Stop-WpsProcess

        $validationResult = Test-WpsRemainingEvidence
        $hardEvidenceCount = @($validationResult.HardRemainingEvidence).Count
        $remainingEvidenceCount = @($validationResult.RemainingEvidence).Count

        if ($hardEvidenceCount -gt 0) {
            foreach ($evidenceItem in $validationResult.HardRemainingEvidence) {
                Write-Log -Level 'WARN' -Message "Evidencia restante: [$($evidenceItem.Type)] $($evidenceItem.Data)"
            }
        } elseif ($remainingEvidenceCount -gt 0) {
            Write-Log -Level 'WARN' -Message 'Solo quedan evidencias cuya eliminación se ha diferido al reinicio.'
        } else {
            Write-Log -Level 'OK' -Message 'No se detectan evidencias principales de WPS Office tras la limpieza.'
        }

        if ($Script:RebootRecommended) {
            Write-Log -Level 'WARN' -Message 'Se recomienda reiniciar el equipo para completar eliminaciones bloqueadas.'
        }

        $success = ($Script:ErrorCount -eq 0) -and ($hardEvidenceCount -eq 0)

        $result = [pscustomobject]@{
            ComputerName          = $env:COMPUTERNAME
            Success               = $success
            ErrorCount            = $Script:ErrorCount
            WarningCount          = $Script:WarningCount
            RebootRecommended     = $Script:RebootRecommended
            PendingDeletePaths    = $Script:PendingDeletePathList.ToArray()
            RemainingEvidence     = $validationResult.RemainingEvidence
            HardRemainingEvidence = $validationResult.HardRemainingEvidence
            LogFile               = $Script:LogFile
        }

        Write-Log -Level 'OK' -Message (
            "Fin de ejecución. Success=$success; Errores=$Script:ErrorCount; " +
            "Advertencias=$Script:WarningCount; Log=$Script:LogFile"
        )

        $result

        if ($success) {
            exit 0
        }

        exit 1
    }
    catch {
        Write-Log -Level 'ERROR' -Message "Error no controlado: $($_.Exception.Message)"

        [pscustomobject]@{
            ComputerName          = $env:COMPUTERNAME
            Success               = $false
            ErrorCount            = $Script:ErrorCount
            WarningCount          = $Script:WarningCount
            RebootRecommended     = $Script:RebootRecommended
            PendingDeletePaths    = $Script:PendingDeletePathList.ToArray()
            RemainingEvidence     = @()
            HardRemainingEvidence = @()
            LogFile               = $Script:LogFile
        }

        exit 1
    }
}

end {
}
