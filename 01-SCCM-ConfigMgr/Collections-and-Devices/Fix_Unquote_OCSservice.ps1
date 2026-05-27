<#
.AUTHOR
       Powered by an external team to CONTOSO
       Based on an internal script 

.SYNOPSIS
        Corrección de la vulnerabilidad 'Unquoted Service Path Enumeration' de Microsoft Windows.

.DESCRIPTION
        Script para solucionar la vulnerabilidad "Unquoted Service Path Enumeration" tanto de servicios como desinstalación. El script modifica los valores del registro. 
 Requiere derechos de administrador.
 Realiza un backup en C: de cada registro modificado en formato C:\'nombre servicio modificado'.reg 

#>
<#     
VERSION HISTORY
        V1.0   18 de Agosto 2021
         V1.1   08 de Septiembre 2021 Se modifica para que solo corrija OCS   
        

#>


$FixParameters = @()
$FixParameters += @{"Path" = "HKLM:\SYSTEM\CurrentControlSet\Services\" ; "ParamName" = "ImagePath"}
$PTElements = @()
ForEach ($FixParameter in $FixParameters) {
        Get-ChildItem $FixParameter.Path -ErrorAction SilentlyContinue | ForEach-Object {
            $SpCharREGEX = '([\[\]])'
            $RegistryPath = $_.name -Replace 'HKEY_LOCAL_MACHINE', 'HKLM:' -replace $SpCharREGEX, '`$1'
            $OriginalPath = (Get-ItemProperty "$RegistryPath")
            $ImagePath = $OriginalPath.$($FixParameter.ParamName)
            If (($ImagePath -like "* *") -and ($ImagePath -notLike '"*"*') -and ($ImagePath -like '*.exe*')) {
                # Saltar MsiExec.exe en uninstall strings
                If ((($FixParameter.ParamName -eq 'UninstallString') -and ($ImagePath -NotMatch 'MsiExec(\.exe)?') -and ($ImagePath -Match '^((\w\:)|(%[-\w_()]+%))\\')) -or ($FixParameter.ParamName -eq 'ImagePath')) {
                    $NewPath = ($ImagePath -split ".exe ")[0]
                    $key = ($ImagePath -split ".exe ")[1]
                    $trigger = ($ImagePath -split ".exe ")[2]
                    $NewValue = ''
                    # Cargar servicio con vulnerabilidad, con clave en ImagePath
                    If (-not ($trigger | Measure-Object).count -ge 1) {
                        If (($NewPath -like "* *") -and ($NewPath -notLike "*.exe")) {
                            $NewValue = "`"$NewPath.exe`" $key"
                        } 
                        # Cargar servicio con vulnerabilidad, sin clave en ImagePath
                        ElseIf (($NewPath -like "* *") -and ($NewPath -like "*.exe")) {
                            $NewValue = "`"$NewPath`""
                        } 
                        If ((-not ([string]::IsNullOrEmpty($NewValue))) -and ($NewPath -like "* *")) {
                            try {
                                $soft_service = $(if ($FixParameter.ParamName -Eq 'ImagePath') {'Service'}Else {'Software'})
                                $OriginalPSPathOptimized = $OriginalPath.PSPath -replace $SpCharREGEX, '`$1'
                                Write-Output "  Valor Actual : $soft_service : '$($OriginalPath.PSChildName)' - $($OriginalPath.$($FixParameter.ParamName))"
                                Write-Output "  Valor Esperado  : $soft_service : '$($OriginalPath.PSChildName)' - $NewValue"
                                if ($Passthru){
                                    $PTElements += '' | Select-Object `
                                        @{n = 'Name'; e = {$OriginalPath.PSChildName}}, `
                                        @{n = 'Type'; e = {$soft_service}}, `
                                        @{n = 'ParamName'; e = {$FixParameter.ParamName}}, `
                                        @{n = 'Path'; e = {$OriginalPSPathOptimized}}, `
                                        @{n = 'OriginalValue'; e = {$OriginalPath.$($FixParameter.ParamName)}}, `
                                        @{n = 'ExpectedValue'; e = {$NewValue}}
                                } 
                                    if($OriginalPath.PSChildName -eq 'OCS Inventory Service'){
                                    # Haciendo Backup deja el archivo en C:\CCMScripts
                                    $TestFolder= Test-Path -Path C:\CCMScripts
                                    If($TestFolder -eq $false){New-Item -ItemType Directory -Path "C:\" -Name CCMScripts}
                                    $BackupFolder= "C:\CCMScripts"
                                    $BcpFileName = "$BackupFolder\$soft_service`_$($OriginalPath.PSChildName)`_$(get-date -uFormat "%Y-%m-%d_%H%M%S").reg"
                                    $BcpRegistryPath = $RegistryPath -replace '\:'
                                    Write-Output "  Creando Backup del registro : $BcpFileName"
                                    $ExportResult = REG EXPORT $BcpRegistryPath $BcpFileName | Out-String
                                    Write-Output "  Result : $($ExportResult -split '\r\n' | Where-Object {$_ -NotMatch '^$'})"
                                    }

                                    #Corrigiendo el registro
                                    if($OriginalPath.PSChildName -eq 'OCS Inventory Service'){
                                    Set-ItemProperty -Path $OriginalPSPathOptimized -Name $($FixParameter.ParamName) -Value $NewValue -ErrorAction Stop
                                    $DisplayName = ''
                                    $keyTmp = (Get-ItemProperty -Path $OriginalPSPathOptimized)
                                    If ($soft_service -match 'Software') {
                                        $DisplayName = $keyTmp.DisplayName
                                    }
                                    If ($keyTmp.$($FixParameter.ParamName) -eq $NewValue) {
                                        Write-Output "  SUCCESS  : Se ha modificado el valor del Path para $soft_service '$($OriginalPath.PSChildName)' $(if($DisplayName){"($DisplayName)"})"
                                    } 
                                    Else {
                                        Write-Output "  ERROR  : Algo va mal. No se pudo cambiar el valor del Path  para $soft_service '$(if($DisplayName){$DisplayName}else{$OriginalPath.PSChildName})'."
                                    } 
                                }
                            } 
                            Catch {
                                Write-Output "  ERROR  : Algo va mal. El cambio de valores ha fallado en el servicio '$($OriginalPath.PSChildName)'."
                                Write-Output "  ERROR  : $_"
                            } 
                            Clear-Variable NewValue
                        } 
                    } 
                }  
            } 
            If (($trigger | Measure-Object).count -ge 1) {
                Write-Output "  ERROR  : No se puede analizar  $($OriginalPath.$($FixParameter.ParamName)) en el registro  $($OriginalPath.PSPath -replace 'Microsoft\.PowerShell\.Core\\Registry\:\:') "
            } 
        } 
    } 