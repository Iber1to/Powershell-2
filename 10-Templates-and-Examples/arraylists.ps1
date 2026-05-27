# Se inicializan los array list    
$azureList = [System.Collections.ArrayList]::new()
$totalGruposList = [System.Collections.ArrayList]::new()
$estaEnAmbos = [System.Collections.ArrayList]::new()
$estaEnGruposynoEnAzure = [System.Collections.ArrayList]::new()
$estaEnAzureynoEnGrupos = [System.Collections.ArrayList]::new()


# Se cargan los datos de los archivos en los array list
Import-csv C:\temp\totalgrupos.txt | ForEach-Object {$totalGruposList.add($_.userPrincipalName)} |Out-Null
Import-csv C:\temp\totalAzure.txt | ForEach-Object {$azureList.add($_.userPrincipalName)} |Out-Null

# Se comparan los array list
foreach ($item in $totalGruposList) {
    if ($azureList.contains($item)) {
        $estaEnAmbos.add($item) |Out-Null
    } else {
        $estaEnGruposynoEnAzure.add($item) |Out-Null
    }
}
foreach ($item in $azureList) {
    if (-not $totalGruposList.contains($item)) {
        $estaEnAzureynoEnGrupos.add($item) |Out-Null
    } 
}
# Se muestran los resultados
write-host "Estan en grupos y no en azure: $($estaEnGruposynoEnAzure.count)"
write-host "Estan en Azure y no en grupos: $($estaEnAzureynoEnGrupos.count)"
write-host "Estan en ambos grupos $($estaEnAmbos.count)"

# Se exportan los resultados a archivos
<#
$estaEnGruposynoEnAzure | Export-csv C:\temp\estaEnGruposynoEnAzure.txt -NoTypeInformation
$estaEnAzureynoEnGrupos | Export-csv C:\temp\estaEnAzureynoEnGrupos.txt -NoTypeInformation
$estaEnAmbos | Export-csv C:\temp\estaEnAmbos.txt -NoTypeInformation
#>