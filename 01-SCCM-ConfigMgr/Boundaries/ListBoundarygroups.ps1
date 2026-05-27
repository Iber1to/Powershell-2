Import-Module C:\01.Scripts\AAGFunctions.ps1

Connect-CMSite
$ListBoundaryGroups=

$ListBoundaryGroups= Get-CMBoundaryGroup
    foreach($item in $ListBoundaryGroups){
    $siteCode= $item.name.split('-')[0]
    if(($siteCode -ne $item.DefaultSiteCode) -and $item.name -ne 'CAS-SC-CMGCONTOSO-VPN' ){
        $BoundaryErrorSiteCode+= $item.Name}else{}
     }



    
