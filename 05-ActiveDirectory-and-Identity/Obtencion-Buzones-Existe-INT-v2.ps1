$fileSalida="c:\temp\DO\BuzonesDO2.csv"
$DC="ClientInsurance.com"
$DCINT="DCSRV01.int.ClientInsurance.net"
$baseDNs=@('OU=Usuarios Comunes,OU=ClientInsurance,OU=All Users,DC=ClientInsurance,DC=com')
$baseDNsExcl=@()
$baseDNINT="OU=Rep Dominicana,OU=MAPAMER,OU=DSDI,DC=int,DC=ClientInsurance,DC=net"

$OUs=@()


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

foreach ($ou in $OUs)
{
    
    $j++
    if ($baseDNsExcl -notcontains $ou.DistinguishedName)
    {
        write-host ("OU $j/$totalOUs - "+$ou.DistinguishedName) -f green
    

        $datos=$null
        $datos= Get-ADUser -Filter * -SearchBase $ou.DistinguishedName -Properties samAccountName,givenname,sn,distinguishedname,mail,Description,lastlogontimestamp,Enabled -server $DC `
        -SearchScope OneLevel | select samAccountName,givenname,sn,distinguishedname,mail,Description,lastlogontimestamp,Enabled
        if ($datos -ne $null)
        {
            foreach ($item in $datos)
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

                $userINT=$null
                $SANINT=$null
                $DNINT=$null
                $IGUALES="NO ENCONTRADO"
                $userINT=Get-ADUser $SAN -server $DCINT | select samAccountName,distinguishedname 
                if ($userINT -ne $null)
                {
                    $SANINT=$userINT[0].samAccountName
                    $DNINT=$userINT[0].distinguishedname
                    $IGUALES="NUMA"
                }
                else
                {
                    $userINT=Get-ADUser -filter {(givenName -eq $givenName) -and (sn -eq $sn)} -server $DCINT | select samAccountName,distinguishedname 
                    if ($userINT -ne $null)
                    {
                        $SANINT=$userINT[0].samAccountName
                        $DNINT=$userINT[0].distinguishedname
                        $IGUALES="NOMBRE Y APELLIDOS"
                    }
                    else
                    {
                      $aux=$sn.split(" ")
                      $sn1=$aux[0]
                      $userINT=Get-ADUser -filter {(givenName -eq $givenName) -and (sn -eq $sn1)} -server $DCINT -SearchBase $baseDNINT -SearchScope SubTree | select samAccountName,distinguishedname 
                      if ($userINT -ne $null)
                        {
                            $SANINT=$userINT[0].samAccountName
                            $DNINT=$userINT[0].distinguishedname
                            $IGUALES="NOMBRE Y PRIMER APELLIDO"
                        }
                    }
                }

                write-host ("$i"+" - "+$SAN+";"+$SANINT+";"+$IGUALES+";"+$givenName+";"+$sn+";"+$mail+";"+$description+";"+$lastlogon+";"+$enabled+";"+$DN+";"+$DNINT) -f cyan
                write-output ($SAN+";"+$SANINT+";"+$IGUALES+";"+$givenName+";"+$sn+";"+$mail+";"+$description+";"+$lastlogon+";"+$enabled+";"+$DN+";"+$DNINT)| out-file $fileSalida -Append
            }
        }
    }
    else
    {
        write-host ("OU $j/$totalOUs - "+$ou.DistinguishedName+" - EXCLUIDA") -f magenta
    }
}

