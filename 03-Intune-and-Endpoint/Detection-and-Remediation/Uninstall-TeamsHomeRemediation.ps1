# Remove package
Get-AppPackage | Where-Object{$_.name -like "*MicrosoftTeams*"} | Remove-AppPackage