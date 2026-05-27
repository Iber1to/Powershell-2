$fileSalida="c:\temp\DO\ListasDistribucionDO_23_03_2022.csv"
$DC="ClientInsurance.com"
$DCINT="DCSRV01.int.ClientInsurance.net"
$baseDNs=@('OU=Distribution Groups,OU=All Groups,DC=ClientInsurance,DC=com','OU=Distribution And Security Groups,OU=All Groups,DC=ClientInsurance,DC=com')
$baseDNsExcl=@('')
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
"SamAccountName DO;SamAccountName INT;IGUALES;Email;Descripcion;Categoria Grupo;Ambito Grupo;DN DO;DN INT" | Out-file $fileSalida

foreach ($ou in $OUs)
{
    
    $j++
    if ($baseDNsExcl -notcontains $ou.DistinguishedName)
    {
        write-host ("OU $j/$totalOUs - "+$ou.DistinguishedName) -f green
    

        $datos=$null
        $datos= Get-ADGroup -Filter * -SearchBase $ou.DistinguishedName -Properties samAccountName,distinguishedname,mail,Description,GroupCategory,GroupScope -server $DC `
        -SearchScope OneLevel | select samAccountName,distinguishedname,mail,Description,GroupCategory,GroupScope
        if ($datos -ne $null)
        {
            foreach ($item in $datos)
            {
                $i++
                $SAN=$item.samAccountName
                $DN=$item.distinguishedname
                $description=$item.Description
                $groupCategory=$item.GroupCategory
                $groupScope=$item.GroupScope 
                $mail=$item.mail

                $groupINT=$null
                $SANINT=$null
                $DNINT=$null
                $IGUALES="NO ENCONTRADO"
                $groupINT=Get-ADGroup $SAN -server $DCINT | select samAccountName,distinguishedname 
                if ($groupINT -ne $null)
                {
                    $SANINT=$groupINT[0].samAccountName
                    $DNINT=$groupINT[0].distinguishedname
                    $IGUALES="NOMBRE"
                }

                write-host ("$i"+" - "+$SAN+";"+$SANINT+";"+$IGUALES+";"+$mail+";"+$description+";"+$groupCategory+";"+$groupScope+";"+$DN+";"+$DNINT) -f cyan
                write-output ($SAN+";"+$SANINT+";"+$IGUALES+";"+$mail+";"+$description+";"+$groupCategory+";"+$groupScope+";"+$DN+";"+$DNINT)| out-file $fileSalida -Append
            }
        }
    }
    else
    {
        write-host ("OU $j/$totalOUs - "+$ou.DistinguishedName+" - EXCLUIDA") -f magenta
    }
}

