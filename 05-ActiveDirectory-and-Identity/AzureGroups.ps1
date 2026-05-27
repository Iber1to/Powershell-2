# Conecta a Microsoft Graph con un usuario distinto al que este logueado
Connect-MgGraph -ContextScope Process

# Datos para procesar los grupos por regiones
$AllRegionsGroupsId = "11111111-1111-1111-1111-000000008773" # ID del grupo que anida a todos los grupos de una region
$RegionPrefix = "MX-" # Prefijo de los paises de la region

# Lista todos los grupos de un pais
$RegionGroups = Get-MgGroup -Filter "startswith(displayName,'$regionPrefix')"
$RegionGroups = $RegionGroups | Where-Object { $_.Id -ne $AllRegionsGroupsId } # Excluimos el grupo que anida a todos los grupos de una region

# Procesamos a todos los grupos del pais y los anidamos en el de region
foreach ($itemGroup in $RegionGroups) {
        Write-Output "Adding $($itemGroup.DisplayName)"  
        try {
            New-MgGroupMember -GroupId $AllRegionsGroupsId -DirectoryObjectId $itemGroup.Id 
            Write-Output "Added OK"}
        catch { Write-Output "Fail to Adding $($itemGroup.DisplayName)"}
}

# Get-MgDeviceManagementDetectedApp -All
# Lista todas las aplicaciones instaladas en los dispositivos (Pestaña detect apps) El campo ID nos servira para buscar los equipos que la tienen instaladas

#Get-MgDeviceManagementDetectedAppManagedDevice -All -DetectedAppId "00008b62bfc2ebac2dcc5b379c0498a59ad90000ffff"
# Nos listara todos los dispositivos en los que se ha detectado esa aplicacion. Ojo que una misma App puede tener varios AppIDs

