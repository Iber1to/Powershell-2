#Para despliegue en Intune
#Parte para la deteccion
# Se modifican las salidas para que solo queden en verde los equipos HP a los que se les ha puesto contraseña
$computerModel = Get-WMIObject -Class Win32_ComputerSystem
$Interface = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSettingInterface -ErrorAction SilentlyContinue
$HPBiosSetting = Get-WmiObject -Namespace root\hp\InstrumentedBIOS -Class HP_BIOSSetting -ErrorAction SilentlyContinue
$SetupPasswordCheck = ($HPBiosSetting | Where-Object Name -eq "Setup Password").IsSet
if (($computerModel.Manufacturer -eq 'HP') -and ($SetupPasswordCheck -eq '0')){Write-Output 'No password active';Exit 1}
    elseif(($computerModel.Manufacturer -ne 'HP')){Write-Output 'Manufacturer not supported'; Exit 1}
        elseif(($computerModel.Manufacturer -eq 'HP') -and ($SetupPasswordCheck -eq '1')){Write-Output 'Password Enable'; Exit 0}       
else{Write-Output 'Unknown'; Exit 1}