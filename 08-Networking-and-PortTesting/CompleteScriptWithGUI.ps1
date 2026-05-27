<# 
    Nombre de la modificación: MOD001
    Modificación para la versión final de PortQuery: Se elimina la seleccion de ruta para el ejecutable de PortQuery y esta pasa a ser fija.
#>
<# 
    Nombre de la modificación: MOD002
    Modificación para la versión final de PortQuery: Se añade un boton para testear el DC del dominio en el que se esta ejecutando el script.
#>
<# 
    Nombre de la modificación: MOD003
    Modificación para la versión final de PortQuery: Se cambia el template html para el informe y se saca a un archivo externo.
#>
<# 
    Nombre de la modificación: MOD004
    Modificación para la versión final de PortQuery: Se cambian los iconos de la aplicación.
    Modificación para la versión final de PortQuery: Se añade una imagen de fondo de la aplicación.
    Modificación para la versión final de PortQuery: Se reorganizan los elementos de la aplicación.
#>
<# 
    Nombre de la modificación: MOD005
    Modificación para la versión final de PortQuery: Se añaden parametros para ejecuccion en linea.
    Modificación para la versión final de PortQuery: Se generan funciones para la ejecucion en linea.
    Ejemplo 1 Lanza el script en linea y ejecuta los tests para el AD local: 
        .\CompleteScriptWithGUI.ps1 -cliMode $true -ExecuteAD $true -Ppath "C:\temp\Outputs"
    Ejemplo 2, lanza el script en linea y ejecuta los tests para el dominio seleccionado:
        .\CompleteScriptWithGUI.ps1 -cliMode $true -Pdomain "openbank" -Ppath "C:\temp\Outputs"
    Ejemplo 3, lanza el script en linea y ejecuta los tests para el dominio seleccionado y para el AD local:
        .\CompleteScriptWithGUI.ps1 -cliMode $true -ExecuteAD $true -Pdomain "openbank" -Ppath "C:\temp\Outputs"
#>

# MOD005 - inicio
param (
        [string]$Pdomain,
        [string] $Ppath,
        [bool]$ExecuteAD,
        [bool]$cliMode
    )
# MOD005 - fin
# Import the Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms


# Leer el archivo XML en una variable para generar el menu de dominios dinamicamente
try {
    [xml]$domainsXml = Get-Content -Path '.\domains.xml' -ErrorAction Stop
}
catch {
    [System.Windows.Forms.MessageBox]::Show('El archivo domains.xml se tiene que encontrar en el mismo path de la aplicación', 'Falta archivo XML', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    Exit
}

# Inicializar un array vacío para almacenar los objetos de dominio
$domainObjects = @()

# Iterar sobre cada elemento de "Configuration" en el XML
foreach ($config in $domainsXml.Configurations.Configuration) {
    # Crear un objeto personalizado para cada "Configuration"
    $domainObject = [PSCustomObject]@{
        Domain   = $config.Domain
        FilePath = $config.FilePath
    }
    
    # Añadir el objeto personalizado al array
    $domainObjects += $domainObject
}

# MOD005 - inicio
# Testeando que los parametros son correctos
# Testeando que el Path es correcto cuando se han introducido parametros en linea
if($Pdomain -or $ExecuteAD){if((Test-Path -Path $Ppath) -eq $false){ Write-Host "El directorio de salida indicado no existe"; exit 1}}

if($Pdomain){
    $DomainValid = $domainObjects.Where({$_.Domain -eq $Pdomain})
    if(-not $DomainValid){
        Write-Host "El dominio indicado no existe en el XML"
        exit 1
    }
}
# MOD005 - fin

# MOD004 - inicio
# Initialize main form
$mainForm = New-Object System.Windows.Forms.Form
$mainForm.Text = 'Comunications Report'
$mainForm.Width = 1000
$mainForm.Height = 500
$ComunicationsReportImage = [System.Drawing.Image]::FromFile((Get-Location).Path + "\ClientBank.jpg")
$mainForm.BackgroundImage = $ComunicationsReportImage
$mainForm.BackgroundImageLayout = 'stretch'
$iconPath = Join-Path (Get-Location).Path "ClientBank.ico"
$mainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)

# Initialize buttons and labels
# Create ComboBox for domain selection
$domainComboBox = New-Object System.Windows.Forms.ComboBox
$domainComboBox.Location = New-Object System.Drawing.Point(432, 20)
$domainComboBox.autosize = $true
$domainComboBox.Items.Add("Select Domain")
foreach ($domain in $domainObjects) {
    $domainComboBox.Items.Add($domain.Domain)
}
$domainComboBox.SelectedIndex = 0

$labeldomainComboBox = New-Object System.Windows.Forms.Label
$labeldomainComboBox.Text = 'Domain: Not selected'
$labeldomainComboBox.autosize = $true
$labeldomainComboBox.Location = New-Object System.Drawing.Point(432, 50)
$labeldomainComboBox.BackColor = [System.Drawing.Color]::White

<# MOD001
    $buttonSelectPortQry = New-Object System.Windows.Forms.Button
    $buttonSelectPortQry.Text = 'Select PortQry Folder'
    $buttonSelectPortQry.autosize = $true
    $buttonSelectPortQry.Location = New-Object System.Drawing.Point(20, 70)

    $labelPortQryPath = New-Object System.Windows.Forms.Label
    $labelPortQryPath.Text = 'PortQry Path: Not selected'
    $labelPortQryPath.autosize = $true
    $labelPortQryPath.Location = New-Object System.Drawing.Point(190, 75)
#>

$buttonSelectOutputFolder = New-Object System.Windows.Forms.Button
$buttonSelectOutputFolder.Text = 'Select Output Folder'
$buttonSelectOutputFolder.autosize = $true
$buttonSelectOutputFolder.Location = New-Object System.Drawing.Point(658, 20)

$labelOutputFolderPath = New-Object System.Windows.Forms.Label
$labelOutputFolderPath.Text = 'Output Folder: Not selected'
$labelOutputFolderPath.autosize = $true
$labelOutputFolderPath.Location = New-Object System.Drawing.Point(658, 50)
$labelOutputFolderPath.BackColor = [System.Drawing.Color]::White

$buttonExecute = New-Object System.Windows.Forms.Button
$buttonExecute.Text = 'Launch Test Select Domain'
$buttonExecute.autosize = $true
$buttonExecute.Location = New-Object System.Drawing.Point(217, 20)

# MOD002 - inicio
$buttonExecuteAD = New-Object System.Windows.Forms.Button
$buttonExecuteAD.Text = 'Launch Test DC Local'
$buttonExecuteAD.autosize = $true
$buttonExecuteAD.Location = New-Object System.Drawing.Point(30, 20)
# MOD002 - fin

$buttonExit = New-Object System.Windows.Forms.Button
$buttonExit.Text = 'Exit'
$buttonExit.autosize = $true
$buttonExit.Location = New-Object System.Drawing.Point(880, 20)

$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(20, 320)
$outputTextBox.Size = New-Object System.Drawing.Size(940, 100)
$outputTextBox.Multiline = $true
$outputTextBox.ScrollBars = 'Vertical'

$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = 'Script Output:'
$outputLabel.autosize = $true
$outputLabel.Location = New-Object System.Drawing.Point(20, 300)
$outputLabel.BackColor = [System.Drawing.Color]::White
# MOD004 - fin

# Add controls to form
$mainForm.Controls.Add($domainComboBox)
$mainForm.Controls.Add($labeldomainComboBox)
<# MOD001
$mainForm.Controls.Add($buttonSelectPortQry)
$mainForm.Controls.Add($labelPortQryPath)
#>
$mainForm.Controls.Add($buttonSelectOutputFolder)
$mainForm.Controls.Add($labelOutputFolderPath)
$mainForm.Controls.Add($buttonExecute)
# MOD002 - inicio
$mainForm.Controls.Add($buttonExecuteAD)
# MOD002 - fin
$mainForm.Controls.Add($buttonExit)
$mainForm.Controls.Add($outputTextBox)
$mainForm.Controls.Add($outputLabel)

<# MOD001
# Define Open File Dialog for PortQry.exe
$portQryOpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$portQryOpenFileDialog.Filter = 'Executable files (*.exe)|*.exe'
#>

# Define Folder Browser Dialog for Output Folder
$outputFolderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog

# Button click events
$domainComboBox.add_SelectedIndexChanged({
    $script:selectedDomain = $domainComboBox.SelectedItem.ToString()
    $labeldomainComboBox.Text = "Domain: $selectedDomain"
})

<# MOD001
$buttonSelectPortQry.Add_Click({
    if ($portQryOpenFileDialog.ShowDialog() -eq 'OK') {
        $labelPortQryPath.Text = "PortQry Path: " + $portQryOpenFileDialog.FileName
    }
})
#>

$buttonSelectOutputFolder.Add_Click({
    # Establecer la carpeta inicial del di�logo
    $outputFolderBrowserDialog.SelectedPath = (Get-Location).Path
    if ($outputFolderBrowserDialog.ShowDialog() -eq 'OK') {
        $labelOutputFolderPath.Text = "Output Folder: " + $outputFolderBrowserDialog.SelectedPath
    }
})

$buttonExit.Add_Click({
    $mainForm.Close()
})

# MOD005 - inicio
function Execute {
    
    # MOD001 - se elimina la comprobación de la ruta de PortQry
    if ([string]::IsNullOrEmpty($script:selectedDomain)  -or [string]::IsNullOrEmpty($outputFolderBrowserDialog.SelectedPath)) {
        [System.Windows.Forms.MessageBox]::Show('Por favor, seleccione todas las rutas necesarias antes de ejecutar.', 'Información faltante', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    } 
    else {
        # Redefine Write-Output to append text to TextBox
        function Write-TextBox {
            param([string]$message)
            $outputTextBox.AppendText($message + "`r`n")
            }
        <# MOD001 
        $portQryPath = $portQryOpenFileDialog.FileName
        #>
        $portQryPath = ".\PortQry.exe"

        # Cargar el archivo XML
        Try{[xml]$xmlContent = Invoke-WebRequest -Uri $($domainObjects |Where-Object {$_.Domain -eq $domainComboBox.SelectedItem}).filepath}Catch{Write-TextBox -message "No se pudo descargar el archivo XML para el dominio $($domainComboBox.SelectedItem), por favor revise que el archivo esta en la ruta correcta y vuelva a intentarlo"; return}
        # Cargar el archivo XML en modo desarrollo. Comentar la entrada anterior y descomentar la siguiente.
        #[xml]$xmlContent = Get-Content ".\soloUDP.xml"
        
        # Inicializar un hash para almacenar los puertos agrupados por servidor y tipo
        $portsByServerAndType = @{}

        # Iterar sobre cada servidor y sus puertos para guardarlos en el almacen
        foreach ($server in $xmlContent.PortCheckList.Server) {
            $serverName = $server.Computer

            # Inicializar hash para este servidor si no existe
            if (-not $portsByServerAndType.ContainsKey($serverName)) {
            $portsByServerAndType[$serverName] = @{}
            }
            foreach ($portInfo in $server.Ports.PortInfo) {
            $type = $portInfo.Type
            $port = $portInfo.Port

            # Agrupar los puertos por tipo para este servidor
            if (-not $portsByServerAndType[$serverName].ContainsKey($type)) {
                $portsByServerAndType[$serverName][$type] = @()
            }
            $portsByServerAndType[$serverName][$type] += $port
            }
        }
        $Array = @()

        # Ejecutar PortQry.exe para cada servidor y tipo de puerto
        foreach ($serverName in $portsByServerAndType.Keys) {
        $serverPorts = $portsByServerAndType[$serverName]
        foreach ($type in $serverPorts.Keys) {
            $ports = $serverPorts[$type] -join ','
            Write-TextBox -message "Ejecutando PortQry.exe para el servidor $serverName y el tipo $type en los puertos $ports"

            # AquÃ­ ejecutamos PortQry.exe con 
            $results = @()
            $results = & $portQryPath -n $serverName -p $type -o $ports -sl
            if($cliMode -eq $false){
                if($results -contains "Failed to resolve name to IP address"){
                $serverFailed = [System.Windows.Forms.MessageBox]::Show("No se pudo resolver el servidor con nombre:$servername . Si continua con el escaneo no se contabilizara este servidor en el report, ¿Desea continuar? ", 'Fallo al resolver servidor', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

                # Comprobar el resultado
                if ($serverFailed -eq 'NO') {
                    Write-TextBox -message "No se pudo resolver la ip del servidor: $serverName , el proceso se interrumpio por el usuario"
                    return
                }
            }
            }
            $Ports = $results | Where-Object {$_.StartsWith("TCP port")}
            if($ports){
                Foreach ($Line in $Ports){
                    $PortNumber = ($Line -split "$TCP port ")[1].Trim()
                    $PortNumber = ($PortNumber -split " ")[0].Trim()
                    if($Line -match ": "){$Status = ($Line -split ": ")[1].Trim()}else{$Status = ($Line -split " is ")[1].Trim()}
                    $Object = New-Object PSObject -Property ([ordered]@{
                    Server = $serverName 
                    Port = $PortNumber
                    TypePort = "TCP"
                    Status = $Status
                    })

                    # Add custom object to our array
                    $Array += $Object
                }
            }
            $Ports = $results | Where-Object {$_.StartsWith("UDP port")}
            if($ports){
                Foreach ($Line in $Ports){
                    #silenciamos un error que dan algunas salidas del PortQry
                    Try{$PortNumber = ($Line -split "UDP port ")[1].Trim()}catch{}
                    $PortNumber = ($PortNumber -split " ")[0].Trim()
                    if($Line -match ": "){$Status = ($Line -split ": ")[1].Trim()}else{$Status = ($Line -split " is ")[1].Trim()}
                    $Object = New-Object PSObject -Property ([ordered]@{
                    Server = $serverName 
                    Port = $PortNumber
                    TypePort = "UDP"
                    Status = $Status
                    })
                    # Add custom object to our array
                    $Array += $Object
                }
            }
        }
        }

        <# PortQuery en ocasiones devuelve primero "LISTENING or FILTERED" y seguido lo da por bueno devolviendo "LISTENING"

            Ejemplo:
            Querying target system called:
            DC1
            Attempting to resolve name to IP address...
            Name resolved to 198.51.100.808
            querying...
            UDP port 137 (netbios-ns service): LISTENING or FILTERED
            Using ephemeral source port
            Attempting NETBIOS adapter status query to UDP port 137...
            Server's response: MAC address 00155d01c61e
            UDP port: LISTENING
        #>
        # El siguiente codigo es para filtrar resultados duplicados y dejar solo los correctos como "LISTENING"
        # Inicializa un diccionario para contar la frecuencia de cada puerto
        $PortCount = @{}

        # Inicializa un nuevo array para almacenar los resultados finales
        $FilteredArray = @()

        # Primera pasada: contar la frecuencia de cada puerto
        foreach ($entry in $Array) {
            $key = "$($entry.Server)-$($entry.Port)-$($entry.TypePort)"
            if (-not $PortCount.ContainsKey($key)) {
                $PortCount[$key] = @()
            }
            $PortCount[$key] += $entry
        }

        # Segunda pasada: aÃ±adir al array filtrado solo las entradas deseadas
        foreach ($entry in $Array) {
            $key = "$($entry.Server)-$($entry.Port)-$($entry.TypePort)"
            if ($PortCount[$key].Count -eq 1 -or $entry.Status -eq "LISTENING") {
                $FilteredArray += $entry
            }
        }       

        # Determinando si los servidores han terminado OK o Fail para el report
        # Agrupar por 'Server'
        $groupedByServer = $FilteredArray | Group-Object -Property Server

        # Inicializar un diccionario para almacenar el estado final de cada servidor
        $serverStatus = @{}
        foreach ($group in $groupedByServer) {
            # Suponemos que el servidor estÃ¡ en estado "OK" hasta que se demuestre lo contrario
            $status = "OK"
            foreach ($item in $group.Group) {
                if (($item.Status -match "FILTERED") -or ($item.Status -eq "NOT LISTENING")) {

                    # Si encontramos una entrada con "LISTENING or FILTERED", cambiamos el estado a "Fail"
                    $status = "Fail"
                    break
                }
            }
            # Almacenar el estado final del servidor en el diccionario
            $serverStatus[$group.Name] = $status
        }

        # Generando Informe con los resultados. 
        # Inicializar variables
        $totalServers = ($FilteredArray.server |Select-Object -Unique).count
        $totalPorts = $FilteredArray.Count
        $PortsOK = 0
        $PortsFail = 0
        $globalResult = "Correcto"
        $serverDetailsFails,$serverDetailsOK  = @()

        # $FilteredArray es el array de objetos con el resultado lo procesamos para obtener los datos del report HTML
        foreach ($entry in $FilteredArray) {
            if ($entry.Status -eq "Listening") {
                $PortsOK++
                $serverDetailsOK += "<p class='success'>$($entry.Server):$($entry.Port) $($entry.TypePort) is OK</p>`r`n"
            } 
            else {
                $PortsFail++
                $globalResult = "Con errores o puertos filtrados"
                $serverDetailsFails += "<p class='failure'>$($entry.Server):$($entry.Port) $($entry.TypePort) Filtered or failed</p>`r`n"
                }

        }
        $serverCountFail = ($serverStatus.Values | Where-Object {$_ -eq "Fail"}).Count
        $serverCountOk = ($serverStatus.Values | Where-Object {$_ -eq "OK"}).Count

        # Filtra los servidores que terminaron OK y los pone en un array
        $serverListOK = $serverStatus.Keys | Where-Object {$serverStatus[$_] -eq 'OK'}

        # Filtra los servidores que terminaron con Fail y los pone en un array
        $serverListFail = $serverStatus.Keys | Where-Object {$serverStatus[$_] -eq 'Fail'}

        # Elimina duplicados y convierte la lista en una cadena con saltos de lÃ­nea HTML para servidores OK
        $uniqueServerListOK = $serverListOK | Select-Object -Unique
        $serverListOKString = ($uniqueServerListOK -join "<br>")

        # Elimina duplicados y convierte la lista en una cadena con saltos de lÃ­nea HTML para servidores con fallos
        $uniqueServerListFail = $serverListFail | Select-Object -Unique
        $serverListFailString = ($uniqueServerListFail -join "<br>")

        # MOD003 - inicio
        # Plantilla HTML con estilos CSS
        $template = Get-Content -Path ".\ReportTemplate.html"
        
        # Sustituye los marcadores de posición por los valores de las variables
        $Template = $Template -Replace '\$globalResult', $globalResult
        $Template = $Template -Replace '\$totalServers', $totalServers
        $Template = $Template -Replace '\$serverCountOK', $serverCountOK
        $Template = $Template -Replace '\$serverCountFail', $serverCountFail
        $Template = $Template -Replace '\$serverListOKString', $serverListOKString
        $Template = $Template -Replace '\$totalPorts', $totalPorts
        $Template = $Template -Replace '\$PortsOK', $PortsOK
        $Template = $Template -Replace '\$PortsFail', $PortsFail
        $Template = $Template -Replace '\$serverListFailString', $serverListFailString
        $Template = $Template -Replace '\$serverDetailsOK', $serverDetailsOK
        $Template = $Template -Replace '\$serverDetailsFails', $serverDetailsFails
        # MOD003 - fin

        # Guardar el informe en multiples formatos
        $fileName = $script:selectedDomain
        $filePath = $outputFolderBrowserDialog.SelectedPath
        $fileHtml = $filePath + "\" + $fileName + ".html"
        $fileCsv = $filePath + "\" + $fileName + ".csv"
        $fileTxt = $filePath + "\" + $fileName + ".txt"

        $template | Out-File -FilePath $fileHtml
        $FilteredArray | Export-csv $fileCsv  -NoTypeInformation
        $FilteredArray | Out-File $fileTxt

        Write-TextBox -message "Se han generado los siguientes archivos en $filePath"
        Write-TextBox -message $fileHtml
        Write-TextBox -message $fileCsv
        Write-TextBox -message $fileTxt

        # Preguntar si quiere ver el report
        if($cliMode -eq $false){$userQuestion = [System.Windows.Forms.MessageBox]::Show('¿Desea abrir el report con los resultados?', 'Abrir Report', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)}

        # Comprobar el resultado
        if ($userQuestion -eq 'Yes') {
            # El usuario ha pulsado "Sí"
            Invoke-Item $fileHtml
            $FilteredArray | Out-GridView
            }
        Write-TextBox -message "Fin del escaneo"
    }
    
}

$buttonExecute.Add_Click({Execute})

function ExecuteAD {
    
    if ([string]::IsNullOrEmpty($outputFolderBrowserDialog.SelectedPath)) {
        [System.Windows.Forms.MessageBox]::Show('Por favor, seleccione todas las rutas necesarias antes de ejecutar.', 'Información faltante', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    } 
    else {
        # Redefine Write-Output to append text to TextBox
        function Write-TextBox {
            param([string]$message)
            $outputTextBox.AppendText($message + "`r`n")
            }
        <# MOD001 
        $portQryPath = $portQryOpenFileDialog.FileName
        #>
        $portQryPath = ".\PortQry.exe"

        # Cargar el archivo XML
        [xml]$xmlContent = Get-Content ".\DomainController.xml"

        # Cargar dominio local
        $domain = (Get-WmiObject Win32_ComputerSystem).Domain
        
        # Inicializar un hash para almacenar los puertos agrupados por servidor y tipo
        $portsByServerAndType = @{}

        # Iterar sobre cada servidor y sus puertos para guardarlos en el almacen
        foreach ($server in $xmlContent.PortCheckList.Server) {
            $serverName = $domain

            # Inicializar hash para este servidor si no existe
            if (-not $portsByServerAndType.ContainsKey($serverName)) {
            $portsByServerAndType[$serverName] = @{}
            }
            foreach ($portInfo in $server.Ports.PortInfo) {
            $type = $portInfo.Type
            $port = $portInfo.Port

            # Agrupar los puertos por tipo para este servidor
            if (-not $portsByServerAndType[$serverName].ContainsKey($type)) {
                $portsByServerAndType[$serverName][$type] = @()
            }
            $portsByServerAndType[$serverName][$type] += $port
            }
        }
        $Array = @()

        # Ejecutar PortQry.exe para cada servidor y tipo de puerto
        foreach ($serverName in $portsByServerAndType.Keys) {
        $serverPorts = $portsByServerAndType[$serverName]
        foreach ($type in $serverPorts.Keys) {
            $ports = $serverPorts[$type] -join ','
            Write-TextBox -message "Ejecutando PortQry.exe para el servidor $serverName y el tipo $type en los puertos $ports"

            # AquÃ­ ejecutamos PortQry.exe con 
            $results = @()
            $results = & $portQryPath -n $serverName -p $type -o $ports -sl
            if($cliMode -eq $false){
                if($results -contains "Failed to resolve name to IP address"){
                $serverFailed = [System.Windows.Forms.MessageBox]::Show("No se pudo resolver el servidor con nombre:$servername . Si continua con el escaneo no se contabilizara este servidor en el report, ¿Desea continuar? ", 'Fallo al resolver servidor', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

                # Comprobar el resultado
                if ($serverFailed -eq 'NO') {
                    Write-TextBox -message "No se pudo resolver la ip del servidor: $serverName , el proceso se interrumpio por el usuario"
                    return
                }
            }
            }
            $Ports = $results | Where-Object {$_.StartsWith("TCP port")}
            if($ports){
                Foreach ($Line in $Ports){
                    $PortNumber = ($Line -split "$TCP port ")[1].Trim()
                    $PortNumber = ($PortNumber -split " ")[0].Trim()
                    if($Line -match ": "){$Status = ($Line -split ": ")[1].Trim()}else{$Status = ($Line -split " is ")[1].Trim()}
                    $Object = New-Object PSObject -Property ([ordered]@{
                    Server = $serverName 
                    Port = $PortNumber
                    TypePort = "TCP"
                    Status = $Status
                    })

                    # Add custom object to our array
                    $Array += $Object
                }
            }
            $Ports = $results | Where-Object {$_.StartsWith("UDP port")}
            if($ports){
                Foreach ($Line in $Ports){
                    #silenciamos un error que dan algunas salidas del PortQry
                    Try{$PortNumber = ($Line -split "UDP port ")[1].Trim()}catch{}
                    $PortNumber = ($PortNumber -split " ")[0].Trim()
                    if($Line -match ": "){$Status = ($Line -split ": ")[1].Trim()}else{$Status = ($Line -split " is ")[1].Trim()}
                    $Object = New-Object PSObject -Property ([ordered]@{
                    Server = $serverName 
                    Port = $PortNumber
                    TypePort = "UDP"
                    Status = $Status
                    })
                    # Add custom object to our array
                    $Array += $Object
                }
            }
        }
        }

        <# PortQuery en ocasiones devuelve primero "LISTENING or FILTERED" y seguido lo da por bueno devolviendo "LISTENING"

            Ejemplo:
            Querying target system called:
            DC1
            Attempting to resolve name to IP address...
            Name resolved to 198.51.100.808
            querying...
            UDP port 137 (netbios-ns service): LISTENING or FILTERED
            Using ephemeral source port
            Attempting NETBIOS adapter status query to UDP port 137...
            Server's response: MAC address 00155d01c61e
            UDP port: LISTENING
        #>
        # El siguiente codigo es para filtrar resultados duplicados y dejar solo los correctos como "LISTENING"
        # Inicializa un diccionario para contar la frecuencia de cada puerto
        $PortCount = @{}

        # Inicializa un nuevo array para almacenar los resultados finales
        $FilteredArray = @()

        # Primera pasada: contar la frecuencia de cada puerto
        foreach ($entry in $Array) {
            $key = "$($entry.Server)-$($entry.Port)-$($entry.TypePort)"
            if (-not $PortCount.ContainsKey($key)) {
                $PortCount[$key] = @()
            }
            $PortCount[$key] += $entry
        }

        # Segunda pasada: aÃ±adir al array filtrado solo las entradas deseadas
        foreach ($entry in $Array) {
            $key = "$($entry.Server)-$($entry.Port)-$($entry.TypePort)"
            if ($PortCount[$key].Count -eq 1 -or $entry.Status -eq "LISTENING") {
                $FilteredArray += $entry
            }
        }       

        # Determinando si los servidores han terminado OK o Fail para el report
        # Agrupar por 'Server'
        $groupedByServer = $FilteredArray | Group-Object -Property Server

        # Inicializar un diccionario para almacenar el estado final de cada servidor
        $serverStatus = @{}
        foreach ($group in $groupedByServer) {
            # Suponemos que el servidor estÃ¡ en estado "OK" hasta que se demuestre lo contrario
            $status = "OK"
            foreach ($item in $group.Group) {
                if (($item.Status -match "FILTERED") -or ($item.Status -eq "NOT LISTENING")) {

                    # Si encontramos una entrada con "LISTENING or FILTERED", cambiamos el estado a "Fail"
                    $status = "Fail"
                    break
                }
            }
            # Almacenar el estado final del servidor en el diccionario
            $serverStatus[$group.Name] = $status
        }

        # Generando Informe con los resultados. 
        # Inicializar variables
        $totalServers = ($FilteredArray.server |Select-Object -Unique).count
        $totalPorts = $FilteredArray.Count
        $PortsOK = 0
        $PortsFail = 0
        $globalResult = "Correcto"
        $serverDetailsFails,$serverDetailsOK  = @()

        # $FilteredArray es el array de objetos con el resultado lo procesamos para obtener los datos del report HTML
        foreach ($entry in $FilteredArray) {
            if ($entry.Status -eq "Listening") {
                $PortsOK++
                $serverDetailsOK += "<p class='success'>$($entry.Server):$($entry.Port) $($entry.TypePort) is OK</p>`r`n"
            } 
            else {
                $PortsFail++
                $globalResult = "Con errores o puertos filtrados"
                $serverDetailsFails += "<p class='failure'>$($entry.Server):$($entry.Port) $($entry.TypePort) Filtered or failed</p>`r`n"
                }

        }
        $serverCountFail = ($serverStatus.Values | Where-Object {$_ -eq "Fail"}).Count
        $serverCountOk = ($serverStatus.Values | Where-Object {$_ -eq "OK"}).Count

        # Filtra los servidores que terminaron OK y los pone en un array
        $serverListOK = $serverStatus.Keys | Where-Object {$serverStatus[$_] -eq 'OK'}

        # Filtra los servidores que terminaron con Fail y los pone en un array
        $serverListFail = $serverStatus.Keys | Where-Object {$serverStatus[$_] -eq 'Fail'}

        # Elimina duplicados y convierte la lista en una cadena con saltos de lÃ­nea HTML para servidores OK
        $uniqueServerListOK = $serverListOK | Select-Object -Unique
        $serverListOKString = ($uniqueServerListOK -join "<br>")

        # Elimina duplicados y convierte la lista en una cadena con saltos de lÃ­nea HTML para servidores con fallos
        $uniqueServerListFail = $serverListFail | Select-Object -Unique
        $serverListFailString = ($uniqueServerListFail -join "<br>")

        # Plantilla HTML con estilos CSS
        $template = Get-Content -Path ".\ReportTemplate.html"
        
        # Sustituye los marcadores de posición por los valores de las variables
        $Template = $Template -Replace '\$globalResult', $globalResult
        $Template = $Template -Replace '\$totalServers', $totalServers
        $Template = $Template -Replace '\$serverCountOK', $serverCountOK
        $Template = $Template -Replace '\$serverCountFail', $serverCountFail
        $Template = $Template -Replace '\$serverListOKString', $serverListOKString
        $Template = $Template -Replace '\$totalPorts', $totalPorts
        $Template = $Template -Replace '\$PortsOK', $PortsOK
        $Template = $Template -Replace '\$PortsFail', $PortsFail
        $Template = $Template -Replace '\$serverListFailString', $serverListFailString
        $Template = $Template -Replace '\$serverDetailsOK', $serverDetailsOK
        $Template = $Template -Replace '\$serverDetailsFails', $serverDetailsFails

        # Guardar el informe en multiples formatos
        $fileName = $domain
        $filePath = $outputFolderBrowserDialog.SelectedPath
        $fileHtml = $filePath + "\" + $fileName + ".html"
        $fileCsv = $filePath + "\" + $fileName + ".csv"
        $fileTxt = $filePath + "\" + $fileName + ".txt"

        $template | Out-File -FilePath $fileHtml
        $FilteredArray | Export-csv $fileCsv  -NoTypeInformation
        $FilteredArray | Out-File $fileTxt

        Write-TextBox -message "Se han generado los siguientes archivos en $filePath"
        Write-TextBox -message $fileHtml
        Write-TextBox -message $fileCsv
        Write-TextBox -message $fileTxt

        # Preguntar si quiere ver el report
        if($cliMode -eq $false){$userQuestion = [System.Windows.Forms.MessageBox]::Show('¿Desea abrir el report con los resultados?', 'Abrir Report', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)}

        # Comprobar el resultado
        if ($userQuestion -eq 'Yes') {
            # El usuario ha pulsado "Sí"
            Invoke-Item $fileHtml
            $FilteredArray | Out-GridView
            }
        Write-TextBox -message "Fin del escaneo"
    }
    
}
# MOD002
$buttonExecuteAD.Add_Click({ExecuteAD})

# Show the form
If($cliMode -eq $false){$mainForm.ShowDialog()}

# Launch CLI ExecuteAD
if($cliMode -and $ExecuteAD){
    $outputFolderBrowserDialog.SelectedPath = $Ppath
    ExecuteAD
}

# Launch CLI Execute

if($cliMode -and $Pdomain){
    $outputFolderBrowserDialog.SelectedPath = $Ppath
    $script:selectedDomain = $Pdomain
    Execute
}
# MOD005 - fin