#Conecta con el CAS para poder tener las CMDLETS de MECM disponibles.
function ConectCAS{
#Comprueba que el usuario con el que se ejecuta la consola es un 'ZX' que son los unicos que deberian tener permisos en el CAS
$CurrentUser = $env:UserName
if($CurrentUser.substring(0,2) -eq 'ZX'){
    #Conecta al CAS
    $SiteCode = "CAS" # Site code 
    $ProviderMachineName = "SRV004.contoso.local" # SMS Provider machine name
    $initParams = @{}
    
    # Import the ConfigurationManager.psd1 module 
    if((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
    }

    # Connect to the site's drive if it is not already present
    if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
    }

    # Set the current location to be the site code.
    Set-Location "$($SiteCode):\" @initParams
    }
#Si la consola esta ejecutada con un usuario distinto a un 'ZX' informa por consola e interrumpe la ejecución del script
else{
    write-host " El usuario actual es $CurrentUser y deber ser un 'ZX' para ejecutar el Script" -ForegroundColor Red
    Break
    }
}

#Inicializo variables
$ListadoFinal = @()


#Conecto al CAS
ConectCAS


#Cargo las boundaries. 
$AllBoundaries = Get-CMBoundary  | Select-Object -Property DisplayName,Value

#Proceso los resultados y creo el objeto con los datos solicitados.
foreach($BoundaryTemp in $AllBoundaries){
$BoundaryFinal= New-Object System.Object
$BoundaryFinal | Add-Member -type NoteProperty -name 'IP-Inicial'  -Value $BoundaryTemp.value.split('-')[0]
$BoundaryFinal | Add-Member -type NoteProperty -name 'IP-Final'  -Value $BoundaryTemp.value.split('-')[1]
$BoundaryFinal | Add-Member -type NoteProperty -name 'Descripción'  -Value $BoundaryTemp.DisplayName.split('',2)[1]
$BoundaryFinal | Add-Member -type NoteProperty -name 'Codigo Pais'  -Value $BoundaryTemp.DisplayName.split('-')[2]
$BoundaryFinal | Add-Member -type NoteProperty -name 'Tipo de Red'  -Value $BoundaryTemp.DisplayName.split('-')[3]
$ListadoFinal += $BoundaryFinal
}

#Exporto los resultados al escritorio del usuario. 
$ListadoFinal  |Export-Csv -Path "$home\Desktop\Listadeboundaries.csv" -NoTypeInformation
Write-Host "Se ha creado un archivo con las boundaries en " -ForegroundColor Green -NoNewline
Write-Host "$home\Desktop\Listadeboundaries.csv" -ForegroundColor Cyan 




