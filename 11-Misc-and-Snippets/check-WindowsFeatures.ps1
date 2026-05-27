# Checkea el estado del Feature
$check = Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -match 'Printing-PrintToPDFServices-Features'} -ErrorAction SilentlyContinue
if ($check.State -eq 'Enabled') {
    Write-Output $check.State
    Exit 0    
}
    elseif ($check.State -eq 'Disabled' ) 
        {
        Write-Output $check.State
        Exit 1 
        }
else {
    Write-Output 'Error Check'
    Exit 1
}

# Habilita el ' Printing-PrintToPDFServices-Features '    
try {
    Enable-WindowsOptionalFeature -Online -FeatureName "Printing-PrintToPDFServices-Features"
    Write-Output 'Succes to Enable'
    Exit 0
}
catch {
    Write-Output 'Fail to Enable'
    Exit 1
}



