<#
.AUTHOR
       Powered by an external team to CONTOSO 

.SYNOPSIS
        Repara la libreria de los DP.

.DESCRIPTION
        Compara el listado de PKG en WMI contra PKGLIB. Detecta las discrepancias entre los dos listados y las elimina. 
        Finalmente pide la redistribución de los PKG que han dado problemas.
        Genera un archivo txt con las entradas eliminadas , para poder usarlo con el script DPcontent

.LOGS
        Muestra en pantalla información sobre los PKG que se han eliminado en WMI en PKGLIB y los que se ha pedido que sean redistribuidos.
#>
<#     
VERSION HISTORY
        V1.0 16 Diciembre de 2020 - Primera versión del Script
        V1.1 05 Mayo de 2021 - Se elimina la redistribucion de pkts y se genera un txt con esos pkts para hacer la distribución eliminación con el script DPContent.ps1

SOURCES
Jonathan Warnken
https://github.com/mrbodean/Technet/blob/master/Powershell/ReDistribute-Package
Jos Lieben
https://www.lieben.nu/liebensraum/2014/09/content-validation-issues-in-sccm-2012/

#>
function Write-CMTracelog{

        <#
        .SYNOPSIS
            A�ade una entrada a un archivo log
        
        .DESCRIPTION
            A�ade entradas a un archivo log existente o crea uno nuevo
        
        .PARAMETER Path
            Ruta del archivo. Si se omite hay que configurar el parametro PathCMTracelog
        
        .PARAMETER PathCMTracelog
            Variable a declarar en el script que use la funci�n con la ruta del archivo log.
            Se usa para evitar estar pasando constantemente el parametro 'Path' 
        
        .PARAMETER Message
            Contenido a a�adir en la entrada.
        
        .PARAMETER Component
            Componente que a�ade la entrada al log. Por defecto a�ade la propia funci�n.
        
        .PARAMETER Type
            Tipo de mensaje a a�arir. El valor por defecto es 'Information' . Los otros valores son 
            'Warning' y 'Error'
        
        .EXAMPLE
             $PathCMTracelog= 'C:\Temp\logalternativo.log'
             Write-CMTracelog 'Esto es un mensaje de prueba por defecto'
             Output= Esto es un mensaje de prueba por defecto  Write-CMTracelog 31/08/2021 13:21:20 0 (0x0)
        
        .EXAMPLE
            Write-CMTracelog -Path C:\Temp\logalternativo.log -Message $error[0] -Type Error -Component $MyInvocation.MyCommand.Name
        
        
        .NOTES
            Author:  IT Automation
            Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
            Twitter: @Alejand94399487
        #> 
        
        
        
            [CmdletBinding()]
            Param(
        
                  [Parameter(Mandatory=$true)]
                  [String]$Message,
                    
                  [Parameter()]
                  [ValidateNotNullOrEmpty()]
                  [String]$Path,
                          
                  [Parameter()]
                  [ValidateNotNullOrEmpty()]
                  [String]$Component= $MyInvocation.MyCommand.Name,
        
                  [Parameter()]
                  [ValidateNotNullOrEmpty()]
                  [ValidateSet("Information", "Warning", "Error")]
                  [String]$Type = 'Information'
            )
        
            if(!$Path){
                $Path= $PathCMTracelog
                }
                
            switch ($Type) {
                "Info" { [int]$Type = 1 }
                "Warning" { [int]$Type = 2 }
                "Error" { [int]$Type = 3 }
            }
        
            # Crea una entrada con formato CMTrace
            $Content = "<![LOG[$Message]LOG]!>" +`
                "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
                "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
                "component=`"$Component`" " +`
                "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
                "type=`"$Type`" " +`
                "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
                "file=`"`">"
        
            # A�ade la linea al archivo log   
            Add-Content -Path $Path -Value $Content
        }

$PathCMTracelog= "C:\01.Script\reparalibreria$(get-date -format "yyyyMMdd").log"
Write-CMTracelog "Iniciando Scripts"

$FQDN= ([System.Net.Dns]::GetHostByName($env:computerName)).hostname

# Se compara la libreria WMI contra la PKGLIB y viceversa

Write-CMTracelog ""
Write-CMTracelog "Cargando listado en WMI"
$WMIPkgList = Get-WmiObject -Namespace Root\SCCMDP -Class SMS_PackagesInContLib | Select-Object -ExpandProperty PackageID | Sort-Object
Write-CMTracelog "Cargando listado en ContentLib"
$ContentLib = (Get-ItemProperty -path HKLM:SOFTWARE\Microsoft\SMS\DP -Name ContentLibraryPath)

$PkgLibPath = ($ContentLib.ContentLibraryPath) + "\PkgLib"

$PkgLibList = (Get-ChildItem $PkgLibPath | Select-Object -ExpandProperty Name | Sort-Object)

$PkgLibList = ($PKgLibList | ForEach-Object {$_.replace(".INI","")})

Write-CMTracelog "Comparando las dos librerias"
$PksinWMIButNotContentLib = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "<=" } 

$PksinContentLibButNotWMI = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "=>" } 

#Borrando las inconsistencias

Write-CMTracelog 'Borrando entradas en WMI:'
$PksinWMIButNotContentLib
$PksinWMIButNotContentLib |Out-File -FilePath .\pkts_$FQDN.txt -Append
foreach ($item in $PksinWMIButNotContentLib){Get-WMIObject  -Namespace "root\sccmdp" -Query ("Select * from SMS_PackagesInContLib where PackageID = '$item'") | Remove-WmiObject
        Write-CMTracelog "Borrando item de WMI: $item"}

Write-CMTracelog 'Borrando archivos .INI  de estos paquetes en la carpeta PkgLib:'
$PksinContentLibButNotWMI
$PksinContentLibButNotWMI |Out-File -FilePath .\pkts_$FQDN.txt -Append
foreach ($item in $PksinContentLibButNotWMI){ Remove-Item $PkgLibPath\$item.ini
        Write-CMTracelog "Borrando item de PKGLIB: '$PkgLibPath\$item'"}
Write-CMTracelog "Fin del Script"