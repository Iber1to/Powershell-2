Import-Module C:\01.Scripts\AAGFunctions.ps1


$ListDeviceFail = @()
$ListadoFinal = @()




$usuarios2= Get-CMDevice -CollectionName 'BGnew - A coruña Nordes - WorkStations' |Select-Object UserName, Name, ResourceID

foreach($Usuario in $Usuarios2){
Try{$DatosDevice= Get-CMResource -ResourceId $usuario.ResourceID -Fast |Select-Object IPAddresses
    $MyUsuario = New-Object System.Object
    $MyUsuario | Add-Member -Type NoteProperty -Name 'Nombre Maquina' -Value $usuario.Name
    $MyUsuario | Add-Member -type NoteProperty -name 'Nombre Usuario'  -Value $usuario.UserName
    $MyUsuario | Add-Member -type NoteProperty -name 'IPAddresses' -Value $DatosDevice.IPAddresses[0]
    $MyUsuario | Add-Member -type NoteProperty -name 'IPAddresses2' -Value $DatosDevice.IPAddresses[1]
    $MyUsuario | Add-Member -type NoteProperty -name 'IPAddresses3' -Value $DatosDevice.IPAddresses[2]
        
    $ListadoFinal += $MyUsuario
   }
Catch{ $ListDeviceFail = New-Object System.Object
       $ListDeviceFail | Add-Member -type NoteProperty -name 'Nombre' -Value $Name
       $ListDeviceFail += $Grupo
     }
}