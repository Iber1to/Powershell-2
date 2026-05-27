<#
.SYNOPSIS
    Añade una entrada a un archivo log

.DESCRIPTION
    Añade entradas a un archivo log existente o crea uno nuevo

.PARAMETER Path
    Ruta del archivo. Si se omite hay que configurar el parametro PathCMTracelog

.PARAMETER PathCMTracelog
    Variable a declarar en el script que use la función con la ruta del archivo log.
    Se usa para evitar estar pasando constantemente el parametro 'Path' 

.PARAMETER Message
    Contenido a añadir en la entrada.

.PARAMETER Component
    Componente que añade la entrada al log. Por defecto añade la propia función.

.PARAMETER Type
    Tipo de mensaje a añarir. El valor por defecto es 'Information' . Los otros valores son 
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

function Write-CMTracelog {

<#
.SYNOPSIS
    Añade una entrada a un archivo log

.DESCRIPTION
    Añade entradas a un archivo log existente o crea uno nuevo

.PARAMETER Path
    Ruta del archivo. Si se omite hay que configurar el parametro PathCMTracelog

.PARAMETER PathCMTracelog
    Variable a declarar en el script que use la función con la ruta del archivo log.
    Se usa para evitar estar pasando constantemente el parametro 'Path' 

.PARAMETER Message
    Contenido a añadir en la entrada.

.PARAMETER Component
    Componente que añade la entrada al log. Por defecto añade la propia función.

.PARAMETER Type
    Tipo de mensaje a añarir. El valor por defecto es 'Information' . Los otros valores son 
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

    # Añade la linea al archivo log   
    Add-Content -Path $Path -Value $Content
}


#Rutas donde se van a guardar los resultados

$PathCMTracelog= "C:\CCMScripts\$($env:COMPUTERNAME)_comunicaciones.log"
$testCCM = Test-Path -Path "C:\CCMScripts"
if($testCCM){}else{md C:\CCMScripts}
$StrCompliance= $null



Write-CMTracelog 'Iniciando Script'
Write-CMTracelog ' '
Write-CMTracelog ' '


      
#Devuelve el directorio de los logs del cliente SCCM 
function Get-CCMLogDirectory {
        $obj = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global').LogDirectory
        if ($null -eq $obj) { $obj = "$env:SystemDrive\windows\ccm\Logs" }
        Write-Output $obj
    }


#Localizando el servidor MP
$MpServerLog= Get-Content -Path "$(Get-CCMLogDirectory)\CcmNotificationAgent.log" | Select-String "AccessMP"
$MpServerName= $MpServerLog[$MpServerLog.Count -1].ToString().Split(' ')[2].split("]")[0]
$MpServerDate= [Datetime]::ParseExact(($MpServerLog[$MpServerLog.Count -1].ToString() -split 'date="')[1].split('"')[0], 'MM-dd-yyyy', $null)
$SmsClient = new-object –comobject “Microsoft.SMS.Client”
if($MpServerName -eq $SmsClient.GetCurrentManagementPoint()){$MpServer= $SmsClient.GetCurrentManagementPoint()}else{$MpServer= 'Conflicto con el MP'} 

Write-CMTracelog "Servidor MP: $MpServer configurado el $MpServerDate"

#Localizando el servidor WSUS configurado
$Wsuslog= Get-Content -Path "$(Get-CCMLogDirectory)\WUAHandler.log" | Select-String "Existing WUA Managed server was already set"
$WsusServerName= $Wsuslog[$Wsuslog.Count - 1].ToString().Split("//")[2].split(":")[0]
$WsusDate= [Datetime]::ParseExact(($Wsuslog[$Wsuslog.Count - 1].ToString() -split 'date="')[1].split('"')[0], 'MM-dd-yyyy', $null)
if([string]::IsNullOrEmpty($WsusServerName)){
    $TestWsusReg= Test-Path -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if($TestWsusReg){
        $WsusServerName= (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate").WUServer.Split('//')[2].split(':')[0]
        }else{$WsusServerName='Regedit vacio'}
        }

Write-CMTracelog "Servidor WSUS: $WsusServerName configurado el $WsusDate"

#Localizando el servidor DP usado por ultima vez
$DPServerLog= Get-Content -Path "$(Get-CCMLogDirectory)\ContentTransferManager.log" | Select-String "SMS_DP_SMSPKG"
$DPServerName= $DPServerLog[$DPServerLog.Count -1].ToString().Split('//')[2].split("/")[0]
$DPServerDate= [Datetime]::ParseExact(($DPServerLog[$DPServerLog.Count -1].ToString() -split 'date="')[1].split('"')[0], 'MM-dd-yyyy', $null)

Write-CMTracelog "Servidor DP: $DPServerName configurado el $DPServerDate"




Write-CMTracelog "Lista de IP's en la maquina:"
Get-NetIPAddress -AddressFamily IPv4|Where-Object -Property InterfaceAlias -NotLike '*Pseudo-Interface*'| Sort-Object -Property InterfaceAlias  |foreach{Write-CMTracelog "$($_.InterfaceAlias): $($_.IPAddress)" } 
Write-Output  $(Get-NetIPAddress -AddressFamily IPv4|Where-Object -Property InterfaceAlias -NotLike '*Pseudo-Interface*'| Sort-Object -Property InterfaceAlias  |foreach{write-host $_.IPAddress } )


# Comprueba los puertos de entrada en el equipo necesarios para el cliente SCCM.
Write-CMTracelog "Comprobando puertos abiertos en localhost"
$LocalPorts= 80,135,445,2701
$LocalPortsError= $null
Foreach ($Port in $LocalPorts)
    {
    $Result = Try{Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop}Catch{"Error"}
    If ($Result -eq "Error")
        {
            $LocalPortsError+= "$Port-"
        }
        Else
        {
            Write-CMTracelog "Puerto $Port resuelto con exito"
        }             
    }
 Write-CMTracelog " Puertos locales cerrados: $LocalPortsError"
 Write-Output "Puertos locales Error: $LocalPortsError"



 # Comprueba los puertos contra el Management Point.
If($MpServerName)
    {
        Write-CMTracelog "Comprobando puertos contra el Management Point"
        $ManagementPorts = 80,135,445,10123
        $ManagementPortsError = $null
        Foreach ($Port in $ManagementPorts)
            {
                $Result = Try{Test-NetConnection -ComputerName $MpServerName -Port $Port  -ErrorAction SilentlyContinue -WarningAction SilentlyContinue}Catch{}
                If ($Result.TcpTestSucceeded)
                {
                    Write-CMTracelog "Puerto MP: $Port resuelto con exito"
                }
                Else
                {
                    $ManagementPortsError+= "$Port-"    
                }             
            }
         If($ManagementPortsError)
         {
            Write-CMTracelog " Puertos inaccesibles contra el MP: $ManagementPortsError"  -Type Error
         }
    }
Else
    {
        Write-CMTracelog "Fallo al capturar el nombre del servidor Management Point" -Type Error
        $ManagementPortsError='error'        
    }
Write-Output "MP: $MpServerName"
Write-Output "Puertos MP error: $ManagementPortsError"  
    
    
# Comprueba los puertos contra el SUP
If($WsusServerName)
    {
        Write-CMTracelog "Comprobando puertos contra el SUP"
        If($WsusServerName -eq 'CMGCONTOSO.CONTOSO.COM')
            {
                $SUPPorts = 443
            }
        Else
            {
                $SUPPorts = 80,8530
            }
        
        $SUPPortsError = $null
        Foreach ($Port in $SUPPorts)
        {
            $Result = Try{Test-NetConnection -ComputerName $WsusServerName -Port $Port  -ErrorAction SilentlyContinue -WarningAction SilentlyContinue}Catch{}
            If ($Result.TcpTestSucceeded)
            {
                Write-CMTracelog "Puerto SUP: $Port resuelto con exito"
            }
            Else
            {
                $SUPPortsError+= "$Port-"    
            }             
        }
        If($SUPPortsError)
            {
                Write-CMTracelog " Puertos inaccesibles contra el SUP: $SUPPortsError"  -Type Error
            }
    }
Else
    {
    Write-CMTracelog "Fallo al capturar el nombre del servidor SUP" -Type Error
    }
Write-Output "SUP: $WsusServerName"
Write-Output "Puertos SUP error: $SUPPortsError"


# Comprueba los puertos contra el Distribution Point.
If($DPServerName)
    {
        Write-CMTracelog "Comprobando puertos contra el Distribution Point"
        $DistributionPorts = 80
        $DistributionPortsError = $null
        Foreach ($Port in $DistributionPorts)
            {
                $Result = Try{Test-NetConnection -ComputerName $DPServerName -Port $Port  -ErrorAction SilentlyContinue -WarningAction SilentlyContinue}Catch{}
                If ($Result.TcpTestSucceeded)
                {
                    Write-CMTracelog "Puerto DP: $Port resuelto con exito"
                }
                Else
                {
                    $DistributionPortsError+= "$Port-"    
                }             
            }
         If($DistributionPortsError)
         {
            Write-CMTracelog " Puertos inaccesibles contra el DP: $DistributionPortsError"  -Type Error
         }
    }
Else
    {
        Write-CMTracelog "Fallo al capturar el nombre del servidor Distribution Point" -Type Error        
    }
Write-Output "DP: $DPServerName"
Write-Output "Puertos DP error: $DistributionPortsError"

# Comprueba los puertos requeridos por AD.

$DomainController= 'emea.contoso.local'
$DomainControllerIP=''
 If($DomainController)
    {
        Write-CMTracelog "Comprobando puertos contra el Domain Controller: $DomainController"
        $DomainControllerPorts = 53,88,135,389,445,636,3268
        $DomainControllerPortsError = $null
        Foreach ($Port in $DomainControllerPorts)
            {
                $Result = Try{Test-NetConnection -ComputerName $DomainController -Port $Port  -ErrorAction SilentlyContinue -WarningAction SilentlyContinue}Catch{}
                $DomainControllerIP= $Result.RemoteAddress.IPAddressToString
                $DomainControllerName= ping -a $DomainControllerIP
                $DomainControllerName= $DomainControllerName[1].split('')[3]
                If ($Result.TcpTestSucceeded)
                {
                    Write-CMTracelog "Puerto DC: $Port resuelto con exito"
                }
                Else
                {
                    $DomainControllerPortsError+= "$Port-"    
                }             
            }
         If($DomainControllerPortsError)
         {
            Write-CMTracelog " Puertos inaccesibles contra el DC $DomainController : $DomainControllerPortsError"  -Type Error
         }
         
    }
Else
    {
        Write-CMTracelog "Fallo al capturar el nombre del servidor Domain Controller" -Type Error        
    }
Write-Output "DC: $DomainControllerName - IP: $DomainControllerIP"    
Write-Output "Puertos DC error: $DomainControllerPortsError"


#Evaluamos si el equipo ha pasado el test
If(($DomainControllerPortsError -eq $null) -and ($DistributionPortsError -eq $null) -and ($SUPPortsError -eq $null) -and ($ManagementPortsError -eq $null) -and ($LocalPortsError -eq $null ))
    {
        Write-CMTracelog "$($env:COMPUTERNAME) Test SUPERADO" -Type Warning
        $StrCompliance= 'Compliance'
    }
Else
    {
        Write-CMTracelog "$($env:COMPUTERNAME) Test FALLADO" -Type Error
        $StrCompliance= 'Error'
    }

$CheckPrimary= Test-Path '\\SRV002\Deploy_logs$'
If($CheckPrimary)
    {
        Copy-Item -Path $PathCMTracelog -Destination '\\SRV002\Deploy_logs$\TestPuertos'
    }
Else{Write-Output "Primary Server acces: FAILED"}

Write-Output $StrCompliance