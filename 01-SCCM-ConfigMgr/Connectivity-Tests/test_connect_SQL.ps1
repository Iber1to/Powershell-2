import-module SqlServer
 
[string] $Server= "SRV002"
[string] $Database = "CM_PE1"
[string] $SQLQuery1 = $("select * from v_GS_System inner join v_HS_System on v_HS_System.ResourceID = v_GS_System.ResourceID where v_GS_System.Name0 <> v_HS_System.Name0")
 

$Connection = New-Object System.Data.SQLClient.SQLConnection
$dt = new-object "System.Data.DataTable"

$Connection.ConnectionString = "server='$Server';database='$Database';trusted_connection=true;"
$Connection.Open()


$cmd1 = $Connection.CreateCommand()
$cmd1.CommandText = $SQLQuery1
$data1 = $cmd1.ExecuteReader()
$dt.Load($data1)

$DeviceLists = @()
foreach($row in $dt)
    {
    $DeviceClonados = New-Object -TypeName PSObject
    $DeviceClonados | Add-Member -MemberType NoteProperty  -Name 'DeviceName' -Value $row.Name0
    $DeviceClonados | Add-Member -MemberType NoteProperty  -Name 'DeviceName01' -Value $row.Name01
    $DeviceClonados | Add-Member -MemberType NoteProperty  -Name 'DeviceDomain' -Value $row.Domain01
    $DeviceClonados | Add-Member -MemberType NoteProperty  -Name 'DeviceSystemRole' -Value $row.SystemRole01
    $DeviceLists+= $DeviceClonados
    }