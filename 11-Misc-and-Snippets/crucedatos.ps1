# Defino las listas para los datos
$excludedUsers = [System.Collections.ArrayList]::new()
$IntuneData = [System.Collections.ArrayList]::new()
$FilteredIntuneData = [System.Collections.ArrayList]::new() # Lista para usuarios excluidos en IntuneData
$DevicesaRemediar = [System.Collections.ArrayList]::new()

# Defino las rutas de los archivos
$ficheroAzureCsv = "c:/Users/user/OneDrive - VendorIT/Scripts/Temporales/CruceClientStone/DevicesWithInventory_161565a1-99f3-451b-884c-5d6181106a07.csv"
$ficheroExcludedlist = "c:/Users/user/OneDrive - VendorIT/Scripts/Temporales/CruceClientStone/UsuariosExcluidos.txt"
$ficheroDevicesaRemediar = "C:\Users\user\OneDrive - VendorIT\Scripts\Temporales\CruceClientStone\Dispositivosaremediar.txt"

# Cargo archivos con datos
Import-csv $ficheroAzureCsv | ForEach-Object {$IntuneData.add($_)} | Out-Null
Import-csv $ficheroExcludedlist | ForEach-Object {$excludedUsers.add($_)} | Out-Null
Import-Csv $ficheroDevicesaRemediar | ForEach-Object {$DevicesaRemediar.add($_)} | Out-Null

# Filtrar datos de Intune para incluir solo usuarios excluidos
foreach ($intuneUser in $IntuneData) {
    $excludedUsers | ForEach-Object {
        if ($intuneUser.'Primary user UPN' -eq $_.UserPrincipalName) {
            $FilteredIntuneData.add($intuneUser)
        }
    }
}


 $FilteredIntuneData | Export-Csv -LiteralPath "C:\Users\user\OneDrive - VendorIT\Scripts\Temporales\CruceClientStone\ClientStone.csv"
 $DevicesaRemediar.ForEach({$FilteredIntuneData.'Device name'.Contains($_.DeviceName)})