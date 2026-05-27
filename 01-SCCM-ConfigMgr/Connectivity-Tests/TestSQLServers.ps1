
#Cargo el modulo para realizar las conexiones SQL.
import-module SqlServer

#Cargo el listado de servidores
$ListadoServers= import-csv -Path C:\Temp\CoSQL.csv -Delimiter ';'

#Genero las credenciales, Estas son del tipo SQL  no va a funcionar si tus credenciales son tipo Windows Auth 
$User= 'sqladmin'
$Password= ConvertTo-SecureString 'REDACTED_PASSWORD' -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList ($User, $password)
$cred.Password.MakeReadOnly()
$sqlCred = New-Object System.Data.SqlClient.SqlCredential($cred.username,$cred.password)

#Variable para almacenar los objetos con los datos consultados.  
$DeviceLists = @()

#Variables para la consulta SQL
$Database = "master"
$SQLQuery1 = $("SELECT SERVERPROPERTY('productversion') as productversion, SERVERPROPERTY ('productlevel') as productlevel, SERVERPROPERTY ('edition') as edition")

#Inicio el bucle para revisar todos los servidores
foreach($item in $ListadoServers)
    {
    $Server= $item.FQDN
    $SQLPing= Test-NetConnection -ComputerName $item.FQDN -WarningAction SilentlyContinue
    $SQLPing
    if($SQLPing.RemoteAddress -eq $null)
        {
        $DeviceSQL = New-Object -TypeName PSObject
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'DeviceName' -Value $item.SERVIDOR
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productversion' -Value 'noData'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productlevel' -Value 'noData'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'edition' -Value 'noData'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'ResuelveIP' -Value 'False'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Ping' -Value 'noData'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Puerto' -Value 'noData'
        $DeviceLists+= $DeviceSQL
        write-host "$($item.SERVIDOR) No se pudo resolver el nombre"       
        }
    elseif($SQLPing.PingSucceeded -eq $false)
        {
        $DeviceSQL = New-Object -TypeName PSObject
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'DeviceName' -Value $item.SERVIDOR
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productversion' -Value 'noData'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productlevel' -Value 'noData'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'edition' -Value 'noData'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'ResuelveIP' -Value 'True'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Ping' -Value 'False'
        $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Puerto' -Value 'noData'
        $DeviceLists+= $DeviceSQL
        write-host "$($item.SERVIDOR) sin ping a la ip $($SQLPing.RemoteAddress)"        
        }
    elseif($SQLPing.PingSucceeded -eq $True)
        {
        $SQLport= Test-NetConnection -ComputerName $item.FQDN -Port 1433 -WarningAction SilentlyContinue
        if($SQLport.TcpTestSucceeded -eq $True)
            {
            try
                { 
                #Establezco la conexion con el servidor
                $sqlConn = New-Object System.Data.SqlClient.SqlConnection
                $sqlConn.ConnectionString = "server='$Server';database='$Database'"
                $sqlConn.Credential = $sqlCred

                #Creo un objeto tipo tabla para guardar los resultados de la consulta
                $dt = new-object "System.Data.DataTable"
                $sqlConn.Open()
                $cmd1 = $sqlConn.CreateCommand()

                #Lanzo la consula y la guardo en la tabala anterior.
                $cmd1.CommandText = $SQLQuery1
                $data1 = $cmd1.ExecuteReader()
                $dt.Load($data1)
                write-host "$Server Datos capturados"

                #Creo el objeto con los datos de la tabla anterior
                foreach($row in $dt)
                    {
                    $DeviceSQL = New-Object -TypeName PSObject
                    $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'DeviceName' -Value $item.SERVIDOR
                    $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productversion' -Value $row.productversion
                    $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productlevel' -Value $row.productlevel
                    $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'edition' -Value $row.edition
                    $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'ResuelveIP' -Value 'True'
                    $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Ping' -Value 'True'
                    $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Puerto' -Value 'True'
                    $DeviceLists+= $DeviceSQL
                    }
            }
            catch
                {
                Write-Host "$Server Fallo al capturar los datos"
                #Creo el objeto sin información
                $DeviceSQL = New-Object -TypeName PSObject
                $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'DeviceName' -Value $item.SERVIDOR
                $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productversion' -Value 'noData'
                $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productlevel' -Value 'noData'
                $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'edition' -Value 'noData'
                $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'ResuelveIP' -Value 'True'
                $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Ping' -Value 'True'
                $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Puerto' -Value 'True'
                $DeviceLists+= $DeviceSQL
                }

            }
        else
            {
            write-host "$Server Puerto 1433 cerrado" 
            #Creo el objeto sin información
            $DeviceSQL = New-Object -TypeName PSObject
            $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'DeviceName' -Value $item.SERVIDOR
            $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productversion' -Value 'noData'
            $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'productlevel' -Value 'noData'
            $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'edition' -Value 'noData'
            $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'ResuelveIP' -Value 'True'
            $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Ping' -Value 'True'
            $DeviceSQL | Add-Member -MemberType NoteProperty  -Name 'Puerto' -Value 'False'
            $DeviceLists+= $DeviceSQL
            }
        }
    }
    
    
    
    


