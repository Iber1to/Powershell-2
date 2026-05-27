#Load App Teams
$LoadTeams = Get-AppPackage | Where-Object{$_.name -like "*MicrosoftTeams*"}
if($LoadTeams){
    write-host "Teams Home detected"
    Exit 1
}
Write-Host "Teams Home not detected"
Exit 0