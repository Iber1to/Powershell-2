$Count=@()
$CounTemp=@()
$Ousbrasil=@()

$DaysInactive = 90
$time = (Get-Date).Adddays(-($DaysInactive))

$Ousbrasil= 'OU=Desktops,OU=_Workstations,DC=latam2,DC=contoso,DC=local','OU=Portables,OU=_Workstations,DC=latam2,DC=contoso,DC=local','OU=DESKTOPS,OU=BRASIL,OU=WORKSTATION,DC=latam2,DC=contoso,DC=local','OU=NOTEBOOKS,OU=BRASIL,OU=WORKSTATION,DC=latam2,DC=contoso,DC=local'
foreach($item in $Ousbrasil){
    $CounTemp= Get-ADComputer -Server latam2.contoso.local -SearchBase $item -Filter {(lastlogontimestamp -lt $time)}
    $Count+= $CounTemp
     }
$Count.Count


$Count=@()
$CounTemp=@()
$Ousbrasil=@()
$Ousbrasil= 'OU=Desktops,OU=_Workstations,DC=latam2,DC=contoso,DC=local','OU=Portables,OU=_Workstations,DC=latam2,DC=contoso,DC=local','OU=DESKTOPS,OU=BRASIL,OU=WORKSTATION,DC=latam2,DC=contoso,DC=local','OU=NOTEBOOKS,OU=BRASIL,OU=WORKSTATION,DC=latam2,DC=contoso,DC=local'
foreach($item in $Ousbrasil){
    $CounTemp= Get-ADComputer -Server latam2.contoso.local -SearchBase $item -Filter {(Enabled -eq $False)}
    $Count+= $CounTemp
     }
$Count.Count



$Count=@()
$CounTemp=@()
$Ousbrasil=@()
$Ousbrasil= 'OU=Desktops,OU=_Workstations,DC=latam2,DC=contoso,DC=local','OU=Portables,OU=_Workstations,DC=latam2,DC=contoso,DC=local','OU=DESKTOPS,OU=BRASIL,OU=WORKSTATION,DC=latam2,DC=contoso,DC=local','OU=NOTEBOOKS,OU=BRASIL,OU=WORKSTATION,DC=latam2,DC=contoso,DC=local'
foreach($item in $Ousbrasil){
    $CounTemp= Get-ADComputer -Server latam2.contoso.local -SearchBase $item -Filter *
    $Count+= $CounTemp
     }
$Count.Count