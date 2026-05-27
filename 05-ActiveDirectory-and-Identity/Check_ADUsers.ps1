function CrearUsuario {
    param (
        [Parameter(Mandatory=$true)] [string]$SamAccountNameOrigen,
        [Parameter(Mandatory=$true)] [string]$SamAccountNameDestino,
        [Parameter(Mandatory=$true)] [string]$Iguales,
        [Parameter(Mandatory=$false)] [string]$GivenName,
        [Parameter(Mandatory=$false)] [string]$SN,
        [Parameter(Mandatory=$false)] [string]$Description,
        [Parameter(Mandatory=$false)] [string]$LastLogon,
        [Parameter(Mandatory=$true)] [string]$Enabled,
        [Parameter(Mandatory=$false)] [string]$Mail,
        [Parameter(Mandatory=$true)] [string]$DistinguishedNameOrigen,
        [Parameter(Mandatory=$true)] [string]$DistinguishedNameDestino
    )
    $usuario = New-Object PSObject -Property @{
        "SamAccountName DO" = $SamAccountNameOrigen
        "SamAccountName INT" = $SamAccountNameDestino
        IGUALES = $Iguales
        Nombre = $givenName
        Apellidos = $SN
        Email = $Mail
        Descripcion = $Description
        UltimoLogon = [datetime]::FromFileTime($LastLogon).ToString('g')
        Habilitado = $Enabled
        "DN DO" = $DistinguishedNameOrigen
        "DN INT" = $DistinguishedNameDestino       
    }

    return $usuario
}

#Parametros
$dominioOrigen = "ClientInsuranceMT.com.mt"
$dominioDestino = "int.ClientInsurance.net"
$ficheroSalida = "C:\temp\exportUsersMatches.csv"

# ArrayLists
$usersDominioOrigen = New-Object System.Collections.ArrayList
$usersDominioDestino = New-Object System.Collections.ArrayList
$usersMatch = New-Object System.Collections.ArrayList

# Obtn todos los usuarios del dominio de origen y adelos al ArrayList
Get-ADUser -Filter * -Properties samAccountName,givenname,sn,distinguishedname,mail,Description,lastlogontimestamp,Enabled -server $dominioOrigen | Select-Object samAccountName, givenname, sn, distinguishedname, mail, Description, @{Name='LastLogon'; Expression={[datetime]::FromFileTime($_.lastlogontimestamp).ToString('g')}}, Enabled, memberof | ForEach-Object { $usersDominioOrigen.Add($_) > $null }

# Obtn todos los usuarios del dominio de destino y adelos al ArrayList
Get-ADUser -Filter * -Properties samAccountName,givenname,sn,distinguishedname,mail,Description,lastlogontimestamp,Enabled -server $dominioDestino | Select-Object samAccountName, givenname, sn, distinguishedname, mail, Description, @{Name='LastLogon'; Expression={[datetime]::FromFileTime($_.lastlogontimestamp).ToString('g')}}, Enabled, memberof | ForEach-Object { $usersDominioDestino.Add($_) > $null }

# Compara los usuarios de ambos dominios y aade los que coinciden al ArrayList usersMatch
foreach($user in $usersDominioOrigen){
    $Matchuser = $null
    $Matchuser = $usersDominioDestino.where({$_.samAccountName -eq $user.samAccountName})
    if($Matchuser){
        $userTemp = CrearUsuario -SamAccountNameOrigen $user.samAccountName -SamAccountNameDestino $Matchuser.samAccountName -Iguales "NUMA" -GivenName $user.givenname -SN $user.sn -Description $user.Description -LastLogon $user.lastlogontimestamp -Enabled $user.Enabled -Mail $user.mail -DistinguishedNameOrigen $user.distinguishedname -DistinguishedNameDestino $Matchuser.distinguishedname
        $usersMatch.Add($userTemp) > $null  
        }
    else{
        if(($user.givenname) -and ($user.sn)){$Matchuser = $usersDominioDestino.where({($_.givenName -eq $user.givenName) -and ($_.sn -eq $user.sn)})}
        if($Matchuser){
            foreach($item in $Matchuser){
                $userTemp = CrearUsuario -SamAccountNameOrigen $user.samAccountName -SamAccountNameDestino $item.samAccountName -Iguales "NOMBRE Y APELLIDOS" -GivenName $user.givenname -SN $user.sn -Description $user.Description -LastLogon $user.lastlogontimestamp -Enabled $user.Enabled -Mail $user.mail -DistinguishedNameOrigen $user.distinguishedname -DistinguishedNameDestino $item.distinguishedname
                $usersMatch.Add($userTemp) > $null
                }
            }
        else{
            if(($user.givenname) -and ($user.sn)){$Matchuser = $usersDominioDestino.where({($_.givenName -eq $user.givenName) -and ($_.sn.Split(" ")[0] -eq $user.sn.Split(" ")[0])})}
            if($Matchuser){
                foreach($item in $Matchuser){
                    $userTemp = CrearUsuario -SamAccountNameOrigen $user.samAccountName -SamAccountNameDestino $item.samAccountName -Iguales "NOMBRE Y PRIMER APELLIDO" -GivenName $user.givenname -SN $user.sn -Description $user.Description -LastLogon $user.lastlogontimestamp -Enabled $user.Enabled -Mail $user.mail -DistinguishedNameOrigen $user.distinguishedname -DistinguishedNameDestino $item.distinguishedname
                    $usersMatch.Add($userTemp) > $null
                    }
                } 
            }
        }
    }
    $usersMatch | Export-Csv -Path $ficheroSalida -Force -NoTypeInformation
