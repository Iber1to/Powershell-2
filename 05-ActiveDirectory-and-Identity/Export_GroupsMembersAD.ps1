#Parametros
$dominioOrigen = "ClientInsuranceMT.com.mt"
$ficheroSalida = "C:\temp\exportGroupsData_" + (Get-Date -Format "yyyyMMdd_HHmm") + ".csv"

#Configuro Array para guardar los datos
$arrayListGroups = New-Object System.Collections.ArrayList
#Cargo todos los grupos en el dominio
$groupsDominioOrigen = Get-ADGroup -Filter * -Server $dominioOrigen
#Listamos usuarios habilitados
$allusers = Get-ADUser -Filter 'Enabled -eq $True' -Property SamAccountName | Select-Object SamAccountName 

#Proceso los datos de todos los objetos del tipo "USUARIO"
foreach ($group in $groupsDominioOrigen) {
    try{$members = Get-ADGroupMember -Identity $group -Server $dominioOrigen}catch{Write-Output "Fallo al listar el grupo: $group"}
   
    
    foreach ($member in $members) {
        if(($member.objectClass -eq "user")-and ($allusers.SamAccountName.Contains($member.SamAccountName))){
        
            $obj = New-Object PSObject
            $obj | Add-Member -MemberType NoteProperty -Name "SamAccountName" -Value $member.SamAccountName
            $obj | Add-Member -MemberType NoteProperty -Name "DistinguishedName" -Value $member.DistinguishedName
            $obj | Add-Member -MemberType NoteProperty -Name "GroupDistinguishedName" -Value $group.DistinguishedName
            $obj | Add-Member -MemberType NoteProperty -Name "GroupCategory" -Value $group.GroupCategory
            $obj | Add-Member -MemberType NoteProperty -Name "GroupScope" -Value $group.GroupScope
            $obj | Add-Member -MemberType NoteProperty -Name "Object Class" -Value $member.objectClass
            $arrayListGroups.Add($obj) | Out-Null
        }
    }
}


#Exportamos el fichero de salida
$arrayListGroups | Export-Csv -Path $ficheroSalida -Force -NoTypeInformation