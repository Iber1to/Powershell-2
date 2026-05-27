$fileSalida="c:\temp\DO\UsuariosDO_v6.csv"
$fileSalidaGrupos="c:\temp\DO\GruposOrigenDO_6.csv"
$fileSalidaGruposINT="c:\temp\DO\GruposDestinoINT_6.csv"
$fileExclusiones="c:\temp\DO\EXCLUSIONES-USUARIOS.txt"
$fileNoEncontrados="c:\temp\DO\NOENCONTRADOS.txt"

$DC="ClientInsurance.com"
$DCINT="DCSRV01.int.ClientInsurance.net"
$baseDNs=@('OU=ClientInsurance,OU=All Users,DC=ClientInsurance,DC=com','OU=Oficina Delegadas,OU=All Users,DC=ClientInsurance,DC=com')
#$baseDNs=@('OU=Auditoria Interna,OU=ClientInsurance,OU=All Users,DC=ClientInsurance,DC=com')
$baseDNsExcl=@('OU=Usuarios Comunes,OU=ClientInsurance,OU=All Users,DC=ClientInsurance,DC=com')
$baseDNINT="OU=Rep Dominicana,OU=MAPAMER,OU=DSDI,DC=int,DC=ClientInsurance,DC=net"

$OUs=@()

$exclusiones=get-content $fileExclusiones
$noEncontrados=get-content $fileNoEncontrados

$ErrorActionPreference = "SilentlyContinue"

foreach ($baseDN in $baseDNs)
{

    $OUs += Get-ADOrganizationalUnit -Filter 'Name -like "*"' -server $DC -SearchBase $baseDN -SearchScope SubTree | select DistinguishedName

}

$totalOUs=$Ous.Count
write-host "OUs a analizar: $totalOUs" -f yellow

$j=0
$i=0
"SamAccountName DO;SamAccountName INT;IGUALES;Nombre;Apellidos;Email;Descripcion;Ultimo Logon;Habilitado;DN DO;DN INT" | Out-file $fileSalida
"SamAccountName;DN-DO;Grupo;Categoria;Scope" | Out-file $fileSalidaGrupos
"SamAccountName;SamAccontNameINT;DN-INT;Grupo;Categoria;Scope;DC" | Out-file $fileSalidaGruposINT


foreach ($ou in $OUs)
{
    
    $j++
    if ($baseDNsExcl -notcontains $ou.DistinguishedName)
    {
        write-host ("OU $j/$totalOUs - "+$ou.DistinguishedName) -f green
    

        $datos=$null
        $datos= Get-ADUser -Filter * -SearchBase $ou.DistinguishedName -Properties samAccountName,givenname,sn,distinguishedname,mail,Description,lastlogontimestamp,Enabled,memberof -server $DC `
        -SearchScope OneLevel | select samAccountName,givenname,sn,distinguishedname,mail,Description,lastlogontimestamp,Enabled,memberof
        if ($datos -ne $null)
        {
            foreach ($item in $datos)
            {
                if ($exclusiones -notcontains $item.SamAccountName)
                {
                    $i++
                    $SAN=$item.samAccountName
                    $DN=$item.distinguishedname
                    $description=$item.Description
                    $lastlogon=[datetime]::FromFileTime($item.lastlogontimestamp).ToString('g')
                    $enabled=$item.Enabled
                    $sn=$item.sn
                    $givenName=$item.givenname
                    $mail=$item.mail


                    $findGroups = $item | select -ExpandProperty memberof 
                    if ($findGroups -ne $null)
                    {
                        foreach ($g in $findGroups)
                        {
                           $grupo=Get-ADGroup -Identity $g -server $DC | select GroupCategory,GroupScope
                           write-host "$SAN;$DN;$g;$($grupo.GroupCategory);$($grupo.GroupScope)" -f magenta
                           write-output "$SAN;$DN;$g;$($grupo.GroupCategory);$($grupo.GroupScope)" | out-file $fileSalidaGrupos -append
                        }
                    }

                    $userINT=$null
                    $SANINT=$null
                    $DNINT=$null
                    $IGUALES="NO ENCONTRADO"
                    $encontradoINT=$false

                    $userINT=Get-ADUser $SAN -properties memberof -server $DCINT | select samAccountName,distinguishedname,memberof 
                    if ($userINT -ne $null)
                    {
                        $SANINT=$userINT[0].samAccountName
                        $DNINT=$userINT[0].distinguishedname
                        $IGUALES="NUMA"
                        $encontradoINT=$true
                    }
                    else
                    {
                        $userINT=Get-ADUser -filter {(givenName -eq $givenName) -and (sn -eq $sn)} -properties memberof -server $DCINT | select samAccountName,distinguishedname,memberof 
                        if ($userINT -ne $null)
                        {
                            $SANINT=$userINT[0].samAccountName
                            $DNINT=$userINT[0].distinguishedname
                            $IGUALES="NOMBRE Y APELLIDOS"
                            $encontradoINT=$true
                        }
                        else
                        {
                            $aux=$sn.split(" ")
                            $sn1=$aux[0]
                            $userINT=Get-ADUser -filter {(givenName -eq $givenName) -and (sn -eq $sn1)} -server $DCINT -SearchBase $baseDNINT -SearchScope SubTree -properties memberof | select samAccountName,distinguishedname,memberof  
                            if ($userINT -ne $null)
                            {
                                $SANINT=$userINT[0].samAccountName
                                $DNINT=$userINT[0].distinguishedname
                                $IGUALES="NOMBRE Y PRIMER APELLIDO"
                                $encontradoINT=$true
                            }
                            else
                            {
                                foreach ($uNoENC in $NoEncontrados)
                                {
                                    $aux=$uNoENC.split(";")
                                    if ($SAN -eq $aux[0])
                                    {
                                        $userINT=Get-ADUser $aux[1] -properties memberof -server $DCINT | select samAccountName,distinguishedname,memberof 
                                        $SANINT=$userINT[0].samAccountName
                                        $DNINT=$userINT[0].distinguishedname
                                        $IGUALES="DATO DO" 
                                        $encontradoINT=$true
                                        break
                                    }
                                }                                
                                
                            }
                        }
                    }
                    if ($encontradoINT)
                    {
                        $findGroupsINT = $userINT[0] | select -ExpandProperty memberof 
                        if ($findGroupsINT -ne $null)
                        {
                            foreach ($g in $findGroupsINT)
                            {
                               
                                if ($g.contains("DC=es,DC=ClientInsurance,DC=net"))
                                {
                                    $DCCorp="DCSRV01.es.ClientInsurance.net"
                                }
                                elseif ($g.contains("DC=int,DC=ClientInsurance,DC=net"))
                                {
                                    $DCCorp="DCSRV01.int.ClientInsurance.net"
                                }
                                elseif ($g.contains("DC=ext,DC=ClientInsurance,DC=net"))
                                {
                                    $DCCorp="DCSRV01.ext.ClientInsurance.net"
                                }
                                elseif ($g.contains("DC=ltm,DC=ClientInsurance,DC=net"))
                                {
                                    $DCCorp="DCSRV01.ltm.ClientInsurance.net"
                                }
                                elseif ($g.contains("DC=ibe,DC=ClientInsurance,DC=net"))
                                {
                                    $DCCorp="DCSRV01.ibe.ClientInsurance.net"
                                }
                                elseif ($g.contains("DC=nam,DC=ClientInsurance,DC=net"))
                                {
                                    $DCCorp="DCSRV01.nam.ClientInsurance.net"
                                }
                                elseif ($g.contains("DC=apc,DC=ClientInsurance,DC=net"))
                                {
                                    $DCCorp="DCSRV01.apc.ClientInsurance.net"
                                }
                                elseif ($g.contains("DC=ema,DC=ClientInsurance,DC=net"))
                                {
                                    $DCCorp="DCSRV01.ema.ClientInsurance.net"
                                }
                                elseif ($g.contains("DC=ClientInsurance,DC=net"))
                                {
                                    $DCCorp="DCSRV01.ClientInsurance.net"
                                }

                                $grupoINT=$null
                                $grupoINT=Get-ADGroup -Identity $g -server $DCCorp | select GroupCategory,GroupScope
                                write-host "$SAN;$SANINT;$DNINT;$g;$($grupoINT.GroupCategory);$($grupoINT.GroupScope);$DCCorp" -f gray
                                write-output "$SAN;$SANINT;$DNINT;$g;$($grupoINT.GroupCategory);$($grupoINT.GroupScope);$DCCorp" | out-file $fileSalidaGruposINT -append
                            }
                        }
                    }

                    write-host ("$i"+" - "+$SAN+";"+$SANINT+";"+$IGUALES+";"+$givenName+";"+$sn+";"+$mail+";"+$description+";"+$lastlogon+";"+$enabled+";"+$DN+";"+$DNINT) -f cyan
                    write-output ($SAN+";"+$SANINT+";"+$IGUALES+";"+$givenName+";"+$sn+";"+$mail+";"+$description+";"+$lastlogon+";"+$enabled+";"+$DN+";"+$DNINT)| out-file $fileSalida -Append
                }
                else 
                {
                    write-host $item.SamAccountName -f red
                }
            
            }
        }
    }
    else
    {
        write-host ("OU $j/$totalOUs - "+$ou.DistinguishedName+" - EXCLUIDA") -f magenta
    }
}

