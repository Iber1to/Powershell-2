function Get-ADUserGroupsRecursive {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DistinguishedName,

        [Parameter(Mandatory=$true)]
        [string]$User,

        [Parameter()]
        [System.Collections.Generic.HashSet[string]]$ProcessedGroups = @(),

        [Parameter()]
        [System.Collections.Generic.Stack[string]]$GroupStack = @()
    )

    # Agregamos el grupo actual al stack
    $GroupStack.Push($DistinguishedName)
     switch -Wildcard ($DistinguishedName) {
        "*DC=es,DC=ClientInsurance,DC=net*" { $DCCorp = "es.ClientInsurance.net"; break }
        "*DC=int,DC=ClientInsurance,DC=net*" { $DCCorp = "int.ClientInsurance.net"; break }
        "*DC=ext,DC=ClientInsurance,DC=net*" { $DCCorp = "ext.ClientInsurance.net"; break }
        "*DC=ltm,DC=ClientInsurance,DC=net*" { $DCCorp = "ltm.ClientInsurance.net"; break }
        "*DC=ibe,DC=ClientInsurance,DC=net*" { $DCCorp = "ibe.ClientInsurance.net"; break }
        "*DC=nam,DC=ClientInsurance,DC=net*" { $DCCorp = "nam.ClientInsurance.net"; break }
        "*DC=apc,DC=ClientInsurance,DC=net*" { $DCCorp = "apc.ClientInsurance.net"; break }
        "*DC=ema,DC=ClientInsurance,DC=net*" { $DCCorp = "ema.ClientInsurance.net"; break }
        "*DC=ClientInsurance,DC=net*" { $DCCorp = "ClientInsurance.net"; break }
    }

    $groups = Get-ADGroup -Server $DCCorp -Filter {memberOf -eq $DistinguishedName} -Properties memberOf
    foreach ($group in $groups) {
        $groupObj = $group | Select-Object SamAccountName, DistinguishedName, GroupCategory, GroupScope
        $groupObj | Add-Member -MemberType NoteProperty -Name "user" -Value $User
        if ($GroupStack.Contains($group.DistinguishedName)) {
            # El grupo es circular
            $groupObj | Add-Member -MemberType NoteProperty -Name "GrupoTipo" -Value "Circular"
            $groupObj
        } elseif (-not $ProcessedGroups.Contains($group.DistinguishedName)) {
            # El grupo es anidado
            $ProcessedGroups.Add($group.DistinguishedName) | Out-Null
            $groupObj | Add-Member -MemberType NoteProperty -Name "GrupoTipo" -Value "Anidado"
            $groupObj
            Get-ADUserGroupsRecursive -DistinguishedName $group.DistinguishedName -User $User -ProcessedGroups $ProcessedGroups -GroupStack $GroupStack
        }
    }

    # Quitamos el grupo actual del stack después de procesarlo
    $GroupStack.Pop() | Out-Null
}

#Parametros
$dominioOrigen = "int.ClientInsurance.net"
$ficheroSalida = "C:\temp\exportGroupsDataLimitOU_" + (Get-Date -Format "yyyyMMdd_HHmm") + ".csv"
$OUselect = "OU=Malta,OU=MAPINTER,OU=DSDI,DC=int,DC=ClientInsurance,DC=net"

#Configuro Array para guardar los datos
$arrayListGroups = New-Object System.Collections.ArrayList
$listUser = @()

#Listamos usuarios habilitados en la OU seleccionado
$listUser = Get-ADUser -Server $dominioOrigen -SearchBase $OUselect -Filter 'Enabled -eq $True' -Property SamAccountName | Select-Object SamAccountName

#Proceso los usuarios obtenidos anteriormente para sacar los grupos a los que pertenece
foreach ($User in $listUser) {
    #Listamos los grupos directos y los añadimos al listado
    $directGroups = (Get-ADUser -Server $dominioOrigen -Identity $User.SamAccountName -Properties memberOf).memberOf
    foreach ($directgroup in $directGroups) {
        switch -Wildcard ($directgroup) {
        "*DC=es,DC=ClientInsurance,DC=net*" { $DCCorp1 = "es.ClientInsurance.net"; break }
        "*DC=int,DC=ClientInsurance,DC=net*" { $DCCorp1 = "int.ClientInsurance.net"; break }
        "*DC=ext,DC=ClientInsurance,DC=net*" { $DCCorp1 = "ext.ClientInsurance.net"; break }
        "*DC=ltm,DC=ClientInsurance,DC=net*" { $DCCorp1 = "ltm.ClientInsurance.net"; break }
        "*DC=ibe,DC=ClientInsurance,DC=net*" { $DCCorp1 = "ibe.ClientInsurance.net"; break }
        "*DC=nam,DC=ClientInsurance,DC=net*" { $DCCorp1 = "nam.ClientInsurance.net"; break }
        "*DC=apc,DC=ClientInsurance,DC=net*" { $DCCorp1 = "apc.ClientInsurance.net"; break }
        "*DC=ema,DC=ClientInsurance,DC=net*" { $DCCorp1 = "ema.ClientInsurance.net"; break }
        "*DC=ClientInsurance,DC=net*" { $DCCorp1 = "ClientInsurance.net"; break }
    }
        $group = Get-ADGroup  $directgroup -Server $DCCorp1
        $groupObj = $group | Select-Object SamAccountName, DistinguishedName, GroupCategory, GroupScope
        $groupObj | Add-Member -MemberType NoteProperty -Name "user" -Value $User.SamAccountName
        $groupObj | Add-Member -MemberType NoteProperty -Name "GrupoTipo" -Value "Directo"
        $arrayListGroups.Add($groupObj) | Out-Null
        }
    #Listamos los grupos anidados y los añadimos al listado
    $results = $directGroups | ForEach-Object { Get-ADUserGroupsRecursive -DistinguishedName $_ -User $User.SamAccountName }
    $results | ForEach-Object{$arrayListGroups.Add($_)| Out-Null}
}

# Crear un HashSet para almacenar las combinaciones únicas
$uniqueHashSet = @{}

# Filtrar los grupos únicos
$uniqueGroups = $arrayListGroups | Where-Object {
    $key = "$($_.SamAccountName)-$($_.DistinguishedName)-$($_.GroupCategory)-$($_.GroupScope)-$($_.user)-$($_.GrupoTipo)"
    if (-not $uniqueHashSet.ContainsKey($key)) {
        $uniqueHashSet[$key] = $true
        return $true
    }
    return $false
}

# Exportar los grupos únicos al CSV
$uniqueGroups | Export-Csv -Path $ficheroSalida -Force -NoTypeInformation