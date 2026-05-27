# Definir el grupo de Active Directory
$ADGroup = "SCCM_Laps_LclAdm"
$AdminsAllowed = Get-ADGroupMember -Identity $ADGroup | Select-Object name, objectClass,distinguishedName

# Definir el grupo local de Administradores en la computadora
$LocalAdminGroup = "Administrators"
$MembersLocalAdmins = Get-LocalGroupMember -Group $LocalAdminGroup

# Iterar a través de cada miembro del grupo local de Administradores
foreach ($LocalAdmin in $LocalAdminGroup) {
    # Si el miembro es un usuario
    if ($LocalAdmin.objectClass -eq "Usuario") {
        $bAuthorized = $false
        # Comprobar si es una cuenta local o de servicio autorizada
        switch ($LocalAdmin.Name.name.split("\")[-1]) {
            "Soptec"  {$bAuthorized = $true}
            "soptec"  {$bAuthorized = $true}
            "Administrador"  {$bAuthorized = $true}
            "S00740003"  {$bAuthorized = $true}
            "S01010002" {$bAuthorized = $true}
        }

        # Si no es una cuenta local autorizada, comprobar en AD
        if (-not $bAuthorized) {
            foreach ($objADMember in $objADGroup.Members) {
                if ($objADMember.Class -eq "user" -and $objADMember.samAccountName -eq $objLocalMember.Name) {
                    $bAuthorized = $true
                    break
                }
            }
        }

        # Si el usuario no está autorizado, eliminarlo del grupo local de Administradores
        if (-not $bAuthorized) {
            $objLocalGroup.PSBase.Invoke("Remove", $objLocalMember.PSBase.Path)
        }
    }
}