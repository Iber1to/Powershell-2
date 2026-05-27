
#Busca la fecha mas reciente en un array
function UltimaFecha {
    Begin { $latest = $null }
    Process {
            if (($_ -ne $null) -and (($latest -eq $null) -or ($_ -gt $latest))) {
                $latest = $_ 
            }
    }
    End { $latest }
}

#Devuelve la fecha del ultimo parche instalado.
function Get-FechaUltimoParche{
    [CmdletBinding()]
    param ()
    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $HistoryCount = $Searcher.GetTotalHistoryCount()
    $Date = $Searcher.QueryHistory(0, $HistoryCount) | Where-Object {($_.Title -notmatch "Defender Antivirus") }| Select-Object -Property Date, ClientApplicationID  | UltimaFecha 
    Write-Output $Date
    }
 
#Devuelve la fecha de la ultima definicion del Antivirus instalado.
function Get-FechaUltimaDefAntivirus{
    [CmdletBinding()]
    param ()
    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $HistoryCount = $Searcher.GetTotalHistoryCount()
    $Date = $Searcher.QueryHistory(0, $HistoryCount) | Where-Object {($_.Title -match "Defender Antivirus")} | Select-Object -Property Date, ClientApplicationID | UltimaFecha
    Write-Output $Date        
    }



#Recopilamos la información del equipo
Try{Write-CMTracelog -Message "Nombre Netbios: $($env:COMPUTERNAME)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar el Nombre Netbios' -Type Warning }
Try{Write-CMTracelog -Message "Nombre FQDN: $((Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar el Nombre FQDN' -Type Warning }
Try{Write-CMTracelog -Message "Dominio: $((Get-WmiObject win32_computersystem).Domain)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar el Dominio' -Type Warning }
Try{Write-CMTracelog -Message "Sistema Operativo: $($(Get-CimInstance Win32_OperatingSystem).Caption)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar el Sistema Operativo' -Type Warning }
Try{Write-CMTracelog -Message "SO Version: $($(Get-CimInstance Win32_OperatingSystem).BuildNumber)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar la SO Version' -Type Warning }
Try{Write-CMTracelog -Message "Arquitectura: $($(Get-CimInstance Win32_OperatingSystem).OSArchitecture)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar la Arquitectura' -Type Warning }
Try{Write-CMTracelog -Message "Version cliente SCCM: $($(Get-CimInstance -Namespace root/ccm SMS_Client).ClientVersion)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar la Version cliente SCCM ' -Type Warning }
$DeviceIp= Get-NetIPAddress -AddressFamily IPv4 | where -Property InterfaceAlias -like 'Ether*' |Where -Property IPAddress -Like '10.*'
foreach($item in $DeviceIp){Try{Write-CMTracelog -Message "Direccion IP: $(($item).IPAddress)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar la Direccion IP' -Type Warning }}
$DateUltimoParche= Get-FechaUltimoParche -ErrorAction SilentlyContinue 
Try{Write-CMTracelog -Message "Fecha ultimo parche: $(($DateUltimoParche).Date)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar la Fecha ultimo parche' -Type Warning } 
Try{Write-CMTracelog -Message "Origen ultimo parche: $(($DateUltimoParche).ClientApplicationID)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar el Origen ultimo parche' -Type Warning } 
$DateUltimaDef= Get-FechaUltimaDefAntivirus -ErrorAction SilentlyContinue
Try{Write-CMTracelog -Message "Fecha ultima Definicion Antivirus: $(($DateUltimaDef).Date)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar la Fecha ultima Definicion Antivirus' -Type Warning } 
Try{Write-CMTracelog -Message "Origen ultima Definicion Antivirus: $(($DateUltimaDef).ClientApplicationID)"}catch{Write-CMTracelog -Message 'Se produjo un error al capturar el Origen ultima Definicion Antivirus' -Type Warning } 



$ListAdapter= Get-NetAdapter
Write-Output $ListAdapter.InterfaceDescription
Write-CMTracelog "Adpatadores de red instalados:"
Write-CMTracelog $ListAdapter.InterfaceDescription