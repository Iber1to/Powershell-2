<#
.AUTHOR
       Powered by an external team to CONTOSO 

.SYNOPSIS
        Permite distribuir o eliminar paquetes en un DP remoto.

.DESCRIPTION
        Permite distribuir o eliminar paquetes de un Distribution Point. 
        Se conectara al CAS para tener acceso a los comandos de powershell para SCCM para ellos necesita que el usuario con el que se ejecuta el script sea del tipo ZX con los permisos correctos.

.PARAMETERS
        Los dos parametros son obligatorios si no se pasan como parametros al lanzar el script, se piden por consola. 
        $DistributionPoint. Define el distribution point contra el que se quiere trabajar. Se recomienda usar el FQDN del servidor. 
        $Path. Indica la ruta donde se encuentra el archivo txt con la lista de paquetes. En la lista solo se usaran los PacKageIDContent tipo "PE1002BC" tal y como aparecen en la pestaña "Content" del DP.

.LOGS
        No genera ningun archivo de log pero muestra en consola información de todo el proceso.

.EXAMPLES
        .\DPContent.ps1
        .\DPContent.ps1 -DistributionPoint distributionpoint1.contoso.com -Path C:\01.-Scripts\paquete.txt
        .\DPContent.ps1 -DistributionPoint 'distributionpoint1.contoso.com' -Path '.\paquete.txt'
         
        
#>
<#     
VERSION HISTORY
        V1.0 09 de Febrero de 2021 - Primera versión del Script

#>
param ([Parameter(Mandatory=$true)][string]$DistributionPoint, 
       [Parameter(Mandatory=$true)][string]$Path)
Clear
Write-Host "Testeando que los parametros introducidos son validos"
Write-Host
Write-Host

#Con esto quitamos la barra de progreso para el Test-NetConnection que puede llegar a ser muy molesta
$Global:ProgressPreference = 'SilentlyContinue'

#Compruebo que el servidor que se ha pasado con el parametro -DistributionPoint esta encendido
#Se podria comprobar tambien si esta en la lista de DP's pero habria que cargar la conexion con el CAS antes para poder traer la lista de DP's
Do{
$TestDistributionPoint= Test-NetConnection -ComputerName $DistributionPoint -WarningAction silentlyContinue 
If($TestDistributionPoint.PingSucceeded){Write-Host "Se ha contactado correctamente con el DP: $DistributionPoint" -ForegroundColor Green
                                         Write-Host
                                         Write-Host
                                        }
else{Write-Host "El DP: $DistributionPoint no responde. Introduce un DP valido" -ForegroundColor Red
     $DistributionPoint= Read-Host "Introduce un DP valido"
     Write-Host
     Write-Host
     }
}
Until ($TestDistributionPoint.PingSucceeded -eq $true)

#Compruebo que el archivo pasado con el parametro -Path existe y es accesible.
Do{
$TestPath= Test-Path -LiteralPath $Path -PathType Leaf
if($TestPath){Write-Host "Se ha localizado el archivo con los paquetes a procesar" -ForegroundColor Green
              Write-Host
              Write-Host
              }
else{Write-Host "No se localiza el archivo indicado para ser procesado " -ForegroundColor Red     
     $Path= Read-Host "Introduce una ruta de archivo valida"
     Write-Host
     Write-Host
     }
}
Until ($TestPath -eq $true)

#Cargo la lista de paquetes a procesar. Lo hago ya para que no haya problemas si se introduce una ruta relativa. 
#Las rutas relativas no funcionan si la conexion al CAS esta realizada
Try{$Pkts = Get-Content -Path $Path}
Catch{Write-Host "No se puede cargar el archivo con los paquetes" -ForegroundColor Red
      Write-Host "Vuelva a ejecutar el Script usando rutas completas 'C:\dir\tuarchivo.txt'"
      }


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


#Función usada para la distribución de paquetes
#Si el paquete ya existe en el DP saldra el mensaje de error generico 'El PackageId $pkt era del tipo xxxxxx y ha fallado al intentar ser distribuido'
function Distribuyepkts {
write-host
write-host "Distribuyendo paquetes:"
write-host
foreach($Pkt in $Pkts){
    
    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Package'
    $TestPkg = Get-CMPackage -Fast -Id $Pkt
    if($TestPkg){
        Try{
            start-CMContentDistribution -PackageId $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Package' y ha sido distribuido" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Package' y ha fallado al intentar ser distribuido" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Application'
    foreach($App in $CMApplication){
        if($App.packageid -eq $Pkt){
            Try{
            start-CMContentDistribution -ApplicationName $App.LocalizedDisplayName -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Application' y ha sido distribuido" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Application' y ha fallado al intentar ser distribuido" -ForegroundColor Red}
        }
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Driver Package'
    $TestDriverPackage = Get-CMDriverPackage -Id $Pkt
    if($TestDriverPackage){
        Try{
            start-CMContentDistribution -DriverPackageID $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Driver Package' y ha sido distribuido" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Driver Package' y ha fallado al intentar ser distribuido" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Boot Image'
    $TestBootImage = Get-CMBootImage -Id $Pkt
    if($TestBootImage){
        Try{
            start-CMContentDistribution -BootImageID $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Boot Image' y ha sido distribuido" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Boot Image' y ha fallado al intentar ser distribuido" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Operating System Image'
    $TestOperatingSystemImage = Get-CMOperatingSystemImage -id $Pkt
    if($TestOperatingSystemImage){
        Try{
            start-CMContentDistribution -OperatingSystemImageID $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Operating System Image' y ha sido distribuido" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Operating System Image' y ha fallado al intentar ser distribuido" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Operating System Upgrade Package'
    $TestOperatingSystemUpgradePackage = Get-CMOperatingSystemUpgradePackage -id $Pkt
    if($TestOperatingSystemUpgradePackage){
        Try{
            Start-CMContentDistribution -Force -OperatingSystemInstallerId $Pkt -DistributionPointName $DistributionPoint -WarningAction silentlyContinue
            Write-Host "El PackageId $pkt era del tipo 'Operating System Upgrade Package' y ha sido distribuido" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Operating System Upgrade Package' y ha fallado al intentar ser distribuido" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Software Update Package'
    $TestSoftwareUpdatePackage = Get-CMSoftwareUpdateDeploymentPackage -id $Pkt
    if($TestSoftwareUpdatePackage){
        Try{
            Start-CMContentDistribution -DeploymentPackageId $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Software Update Package' y ha sido distribuido" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Software Update Package' y ha fallado al intentar ser distribuido" -ForegroundColor Red}
    }
 
}
Write-Host
Write-Host
Write-Host "Todos los paquetes han sido procesados"
Show-Menu
}

#Función usada para la eliminación de paquetes
#Si el paquete no existe en el DP saldra el mensaje de error generico 'El PackageId $pkt era del tipo xxxxxx y ha fallado al intentar ser eliminado'
function EliminaPkts {
write-host
write-host "Eliminando paquetes:"
write-host
foreach($Pkt in $Pkts){
    
    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Package'
    $TestPkg = Get-CMPackage -Fast -Id $Pkt
    if($TestPkg){
        Try{
            Remove-CMContentDistribution -Force -PackageId $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Package' y ha sido eliminado" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Package' y ha fallado al intentar ser eliminado" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Application'
    foreach($App in $CMApplication){
        if($App.packageid -eq $Pkt){
            Try{
            Remove-CMContentDistribution -Force -ApplicationName $App.LocalizedDisplayName -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo Application y ha sido eliminado" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo Application y ha fallado al intentar ser eliminado" -ForegroundColor Red}
        }
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Driver Package'
    $TestDriverPackage = Get-CMDriverPackage -Id $Pkt
    if($TestDriverPackage){
        Try{
            Remove-CMContentDistribution -Force -DriverPackageID $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Driver Package' y ha sido eliminado" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Driver Package' y ha fallado al intentar ser eliminado" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Boot Image'
    $TestBootImage = Get-CMBootImage -Id $Pkt
    if($TestBootImage){
        Try{
            Remove-CMContentDistribution -Force -BootImageID $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Boot Image' y ha sido eliminado" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Boot Image' y ha fallado al intentar ser eliminado" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Operating System Image'
    $TestOperatingSystemImage = Get-CMOperatingSystemImage -id $Pkt
    if($TestOperatingSystemImage){
        Try{
            Remove-CMContentDistribution -Force -OperatingSystemImageID $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Operating System Image' y ha sido eliminado" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Operating System Image' y ha fallado al intentar ser eliminado" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Operating System Upgrade Package'
    $TestOperatingSystemUpgradePackage = Get-CMOperatingSystemUpgradePackage -id $Pkt
    if($TestOperatingSystemUpgradePackage){
        Try{
            Remove-CMContentDistribution -Force -OperatingSystemInstallerId $Pkt -DistributionPointName $DistributionPoint -WarningAction silentlyContinue
            Write-Host "El PackageId $pkt era del tipo 'Operating System Upgrade Package' y ha sido eliminado" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Operating System Upgrade Package' y ha fallado al intentar ser eliminado" -ForegroundColor Red}
    }

    #Identifica si el PackageIdContent pertenece a un paquete de Sofware del tipo: 'Software Update Package'
    $TestSoftwareUpdatePackage = Get-CMSoftwareUpdateDeploymentPackage -id $Pkt
    if($TestSoftwareUpdatePackage){
        Try{
            Remove-CMContentDistribution -Force -DeploymentPackageId $Pkt -DistributionPointName $DistributionPoint
            Write-Host "El PackageId $pkt era del tipo 'Software Update Package' y ha sido eliminado" -ForegroundColor Green
            }
        catch{Write-Host "El PackageId $pkt era del tipo 'Software Update Package' y ha fallado al intentar ser eliminado" -ForegroundColor Red}
    }
 
}
Write-Host
Write-Host
Write-Host "Todos los paquetes han sido procesados"
Show-Menu
}

#Función para la selección de acciones.
function Show-Menu {
    param (
        [string]$Title = '¿Que quieres hacer con los paquetes cargados? '
    )
    
    Write-Host "================ $Title ================"
    
    Write-Host "1: Presiona '1' para distribuir."
    Write-Host "2: Presiona '2' para eliminar."
    Write-Host "3: Presiona '3' para detener el Script."
    write-host
    do
 {
    
    $selection = Read-Host "Por favor elige una opcion"
    switch ($selection)
    {
    '1' {Distribuyepkts}
    '2' {EliminaPkts}
    '3' {Break} 
    }
    
 }
 until ($selection -eq '1'-or $selection -eq '2' -or $selection -eq '3' )
    
}

Write-Host "Conectando con el site CAS espere......"
write-host
write-host
ConectCAS
Write-Host "Conexión con el site CAS realizada" -ForegroundColor Green
write-host
write-host

Write-Host "Cargando listado de aplicaciones......."
write-host
write-host

#Cargo un listado con todas las aplicaciones en MECM para poder identificar más tarde si el PackageIDContent es una APP
Try
{$CMApplication = Get-CMApplication | Select-Object LocalizedDisplayName, PackageID
Write-Host "Listado de aplicaciones Cargado correctamente" -ForegroundColor Green
write-host
write-host
}
catch
{Write-Host "Listado de aplicaciones no se pudo cargar" -ForegroundColor Red
write-host
write-host
}

#Informo al usuario de la lista de paquetes que se ha cargado y lanzo el menu para que elija la acción a realizar.
Write-Host "Se van a procesar los siguientes paquetes:"
$Pkts
write-host
write-host

Show-Menu    