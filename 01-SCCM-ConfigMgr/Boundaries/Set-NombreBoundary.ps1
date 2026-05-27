Import-Module C:\01.Scripts\AAGFunctions.ps1
Connect-CMSite

Clear
#Cadena para localizar las boundaries que queremos cambiar.Ojo al '*' no lo olvideis
$SearchBoundary= 'PA1-APAC-AU*'

#String a cambiar 
$StringOriginal= 'PA1-'
$StringFinal= 'PE1-'

#Cargamos la lista de boundarys a cambiar
$listBoundary= Get-CMBoundary -BoundaryName $SearchBoundary
Write-Host "Ejemplo de boundaries seleccionadas: $($listBoundary[1].DisplayName)"
Write-Host ""
Write-Host ""
Write-Host Como va a quedar el nombre de la boundary: $($listBoundary[1].DisplayName.Replace($StringOriginal,$StringFinal))
Write-Host ""
Write-Host ""
Write-Host "Se van a modificar $($listBoundary.count) boundaries"
Read-Host -Prompt 'Presiona una tecla para cambiar las boundaries seleccionadas'


#Le cambiamos el nombre a cada una de las boundaries que cumplian la condicion de busqueda
foreach($n in $listBoundary){Set-CMBoundary -Id $n.BoundaryID -NewName ($n.DisplayName).Replace($StringOriginal,$StringFinal)}