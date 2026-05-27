<#
.AUTHOR
       Powered by an external team to CONTOSO 

.SYNOPSIS
        Repara la libreria de los DP.

.DESCRIPTION
        Compara el listado de PKG en WMI contra PKGLIB. Detecta las discrepancias entre los dos listados y las elimina. 
        Finalmente pide la redistribución de los PKG que han dado problemas. 

.LOGS
        Muestra en pantalla información sobre los PKG que se han eliminado en WMI en PKGLIB y los que se ha pedido que sean redistribuidos.
#>
<#     
VERSION HISTORY
        V1.0 16 Diciembre de 2020 - Primera versión del Script
        V1.1 28 Diciembre de 2020 - Se añaden menus para poder elegir si redistribuir los pkt's

SOURCES
Jonathan Warnken
https://github.com/mrbodean/Technet/blob/master/Powershell/ReDistribute-Package
Jos Lieben
https://www.lieben.nu/liebensraum/2014/09/content-validation-issues-in-sccm-2012/

#>


# Se compara la libreria WMI contra la PKGLIB y viceversa

$WMIPkgList = Get-WmiObject -Namespace Root\SCCMDP -Class SMS_PackagesInContLib | Select-Object -ExpandProperty PackageID | Sort-Object

$ContentLib = (Get-ItemProperty -path HKLM:SOFTWARE\Microsoft\SMS\DP -Name ContentLibraryPath)

$PkgLibPath = ($ContentLib.ContentLibraryPath) + "\PkgLib"

$PkgLibList = (Get-ChildItem $PkgLibPath | Select-Object -ExpandProperty Name | Sort-Object)

$PkgLibList = ($PKgLibList | ForEach-Object {$_.replace(".INI","")})

$PksinWMIButNotContentLib = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "<=" } 

$PksinContentLibButNotWMI = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "=>" } 
$PksinWMIButNotContentLib
$PksinContentLibButNotWMI

#Borrando las inconsistencias

Write-Host 'Borrando estas entradas en WMI:'
$PksinWMIButNotContentLib
foreach ($item in $PksinWMIButNotContentLib){Get-WMIObject  -Namespace "root\sccmdp" -Query ("Select * from SMS_PackagesInContLib where PackageID = '$item'") | Remove-WmiObject
                                             Write-host "Borrando item de WMI: $item"}


Write-Host 'Borrando archivos .INI  de estos paquetes en la carpeta PkgLib:'
$PksinContentLibButNotWMI
foreach ($item in $PksinContentLibButNotWMI){ Remove-Item $PkgLibPath\$item.ini
                                              Write-Host "Borrando item de PKGLIB: '$PkgLibPath\$item'"}


#Funcion Menu

function Show-Menu {
    param (
        [string]$Title = '¿Redistribuir los paquetes? '
    )
    
    Write-Host "================ $Title ================"
    
    Write-Host "1: Presiona '1' para redistribuir."
    Write-Host "2: Presiona '2' para terminar."
    
}

do
 {
    Show-Menu
    $selection = Read-Host "Por favor elige una opcion"
    switch ($selection)
    {
    '1' {
    Continue
    } '2' {
    
    write-host 'Script finalizado'
    EXIT
    } 
    }
    pause
 }
 until ($selection -eq '1'-or $selection -eq '2' )


#Redistribuyo los pkts con problemas.


#Obtengo el $SiteCode para el DP
$ComputerName = $env:COMPUTERNAME
    $Sitetemp= get-WMIObject -ComputerName $ComputerName -Namespace "root\CCM\LocationServices" -Class "SMS_MPList" 
    $SiteCode= $Sitetemp.sitecode
    if ($SiteCode -eq "") { 
        throw ("Sitecode de ConfigMgr Site en " + $ComputerName + " no ha podido ser determinado y no se puede continuar.") 
        Break
    }

#Asigno el SiteServer (Primary Server del DP)

$siteServer =Switch ($SiteCode)
{
'PE1' {'SRV002.emea.contoso.local'}
'PA1'{'SRV007.apac.contoso.local'}
'PL1'{'SRV001.latam1.contoso.local'}
'PL2'{'SRV024.latam2.contoso.local'}
}

#Asigno el DP al que se van a redistribuir los pkt's
$target= $ComputerName

 

Foreach($PkgID in $PksinWMIButNotContentLib){
            try{
                
                $DistributionPoint = Get-WmiObject -Namespace "root\SMS\Site_$SiteCode" -Class SMS_DistributionPoint -Filter "PackageID='$($PkgId)' and ServerNALPath like '%$($target)%'"  -ComputerName $SiteServer
                If($DistributionPoint){
                    $DistributionPoint.RefreshNow = $True
                    $DistributionPoint.Put()|Out-Null
                    Write-Host "Redistribuyendo $($PkgID) on $($target)" -ForegroundColor Green
                }else{
                    Write-host "No se ha localizado el  paquete $($PkgID) en la lista de contenido de $($target)" -ForegroundColor Red
                }
            }
            catch{
                $errormsg = $Error[0].ToString()
                Write-Error -Message "Imposible redistribuir paquete $($PkgID) on $($target)! $($errormsg)"
            }
        }

Foreach($PkgID in $PksinContentLibButNotWMI){
            try{
                
                $DistributionPoint = Get-WmiObject -Namespace "root\SMS\Site_$SiteCode" -Class SMS_DistributionPoint -Filter "PackageID='$($PkgId)' and ServerNALPath like '%$($target)%'"  -ComputerName $SiteServer
                If($DistributionPoint){
                    $DistributionPoint.RefreshNow = $True
                    $DistributionPoint.Put()|Out-Null
                    Write-Host "Redistribuyendo $($PkgID) on $($target)" -ForegroundColor Green
                }else{
                    Write-host "No se ha localizado el  paquete $($PkgID) en la lista de contenido de $($target)" -ForegroundColor Red
                }
            }
            catch{
                $errormsg = $Error[0].ToString()
                Write-Error -Message "Imposible redistribuir paquete $($PkgID) on $($target)! $($errormsg)"
            }
        }


        #>