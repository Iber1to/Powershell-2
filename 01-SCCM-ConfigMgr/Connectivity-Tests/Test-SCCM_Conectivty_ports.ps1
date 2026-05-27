<#
.AUTHOR
       Powered by an external team to CONTOSO 

.SYNOPSIS
        Permite comprobar la conectividad TCP para un cliente o servidor de SCCM en los puertos por defecto.

.DESCRIPTION
        Este script comprueba los puertos TCP necesarios para el funcionamiento de SCCM tanto en clientes como en Servidores.
        En el caso de servidores no comprueba los puertos que necesita contra otros servidores sean de SCCM, SQL, Active Directory o Microsoft.
        Para comprobar la conectividad de un servidor, ejecutar el script desde un equipo cliente introduciendo el FQDN o la IP del servidor a comprobar y escribiendo como opcion 'S'
        Para comprobar la conectividad de un cliente, ejecutar el script desde un servidor SCCM introduciendo el FQDN o la IP del cliente a comprobar y escribiendo como opcion 'C'

.PARAMETER $Machiname
        Es el primer parametro que nos pide. Tiene que ser el FQDN en formato "serversccm.contoso.local" o la IP. 
        Si este valor es distinto de Null o Empty lanzara el test.

.PARAMETER $Rol
        Es el segundo parametro que nos pide. Puede ser 'S' para servidor o 'C' para cliente. Este parametro determina los puertos que se van a comprobar.

.LOGS
        El script creara una carpeta llamada logs en el directorio donde se ejecute el script. Crea un archivo .csv con los resultados del test. Crea un archivo .log con los datos de la ejecucin.
#>
<#     
VERSION HISTORY
        V1.0 25 Octubre  2020 - Primera versin del Script

#>

[CmdletBinding()]

param (
    [string]$Machiname = $( Read-Host "Introduce el FQDN o la IP del equipo objetivo" ),
    [string]$Rol = $( Read-Host "Introduce 'S' para Servidor o 'C' para cliente " )
    )



function Ports{
  $Port = 80
  $Service = "Catalogo Aplicaciones"
  $Rol = "S"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 443
  $Service = "Catalogo Aplicaciones_secure"
  $Rol = "S"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 8530
  $Service = "WSUS"
  $Rol = "S"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 8531
  $Service = "WSUS_secure"
  $Rol = "S"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 8005
  $Service = "Actualizaciones Rapidas"
  $Rol = "S"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 445
  $Service = "SMB"
  $Rol = "S"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 10123
  $Service = "Punto de administracion"
  $Rol = "S"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 2701
  $Service = "Control Remoto"
  $Rol = "C"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 8003
  $Service = "Descarga P2P"
  $Rol = "C"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 3389
  $Service = "RDP y RTC"
  $Rol = "C","S"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  $Port = 135
  $Service = "RPC"
  $Rol = "S"
  [PSCustomObject]@{
    "Port"=$Port
    "Service"=$Service
    "Rol"= $Rol
  }
  }

  $portlist = Ports



#region ===LOGS FUNCTIONS ==================================================== 
#
$LogPath='.\Logs'
$Date = Get-Date -Format yyyy.MM.dd.HH.mm.ss
if (!($LogPath)) 
{
    $LogPath = (Get-Location).Path + "\LOGS"
}

if(!(Test-Path $LogPath -PathType Container)) 
{ 
    New-Item -ItemType directory -Path $LogPath
} 

$LogFile = $LogPath + "\Test-SCCM-$Date.log"

#
# Log Function
#

function Write-Log ([string]$msg)
{
   "$(Get-Date -Format yyyy.MM.dd.HH.mm.ss): $msg" | Out-File -FilePath $LogFile -Append -Force
    $msg
}

# Error Log Function
function Write-ErrorLog ([string]$msg)
{
   "ERROR: $(Get-Date -Format yyyy.MM.dd.HH.mm.ss): $msg" | Out-File -FilePath $LogFile -Append -Force
    Write-Error $msg 
}

# Debug Log Function
function Write-DebugLog
{
    [cmdletbinding()]
    Param (
        [string]$msg
    )
    Write-Debug $msg 
}
#
#endregion === LOGS FUNCTIONS =============================================

Write-Log "##### Comienza Test-SCCM"

If ($PSBoundParameters['Debug']) 
{
    $DebugPreference = 'Continue'
}


$results = @()
$portstotest = Ports


    if (![string]::IsNullOrEmpty($Machiname))
    {
        $Servername = $Machiname
        Write-Log "## "
        Write-Log "## Iniciando tests contra $Servername"
        $fullconnectivity = $true
        $someconnectivity = $false
        $testitem = New-Object PSObject
        $testitem  | Add-Member -type NoteProperty -Name 'DestinationServer' -Value $Servername
    
        Write-Host "Ping Server $Servername " -NoNewline
        $pingresult = Test-netconnection -ComputerName $Servername
        $testitem  | Add-Member -type NoteProperty -Name 'PingSucceeded' -Value $pingresult.PingSucceeded
        $fullconnectivity = $fullconnectivity -and $pingresult.PingSucceeded
        $someconnectivity = $someconnectivity -or $pingresult.PingSucceeded

        if ($pingresult.PingSucceeded)
        {
            Write-Host "OK" -ForegroundColor Green
        }
        else 
        {
            Write-Host "FAILED" -ForegroundColor Red
        }

        foreach ($port in $portstotest)
        {
            $value = ""
            $servicename = $port.service
            if (($port.Rol -eq $Rol))
            {
                Write-Host "Check $servicename on server $Servername " -NoNewline
                $rdpresult = Test-netconnection -ComputerName $Servername -Port $port.Port
                $value = $rdpresult.TcpTestSucceeded
                $fullconnectivity = $fullconnectivity -and $rdpresult.TcpTestSucceeded
                $someconnectivity = $someconnectivity -or $rdpresult.TcpTestSucceeded
        
                if ($rdpresult.TcpTestSucceeded)
                {
                    Write-Host "OK" -ForegroundColor Green
                }
                else 
                {
                    Write-Host "FAILED" -ForegroundColor Red
                }
            }
            $testitem  | Add-Member -type NoteProperty -Name $servicename -Value $value
        }

        $testitem  | Add-Member -type NoteProperty -Name 'FullConnectivity' -Value $fullconnectivity 
        $testitem  | Add-Member -type NoteProperty -Name 'NoConnectivity' -Value (!$someconnectivity)
        $results += $testitem
        if ($fullconnectivity)
        {
            Write-Log "Conectividad TOTAL con  $Servername"
        }
        elseif (!$someconnectivity) 
        {
            Write-Log "Conectividad NULA con $Servername"
        }
        else 
        {
            Write-Log "Conectividad PARCIAL con $Servername"
        }
        Write-Log "## Terminado el test contra $Servername"
        Write-Log "## "
    }



$Succeeded = @()
$Failed = @()
$Partial = @()

foreach ($result in $results)
{
    $Servername = $result.DestinationServer
    $item = New-Object PSObject
    $item  | Add-Member -type NoteProperty -Name 'Servername' -Value $Servername

    if ($result.FullConnectivity)
    {
        $Succeeded += $item
    }
    elseif ($result.NoConnectivity) 
    {
        $Failed += $item
    }
    else 
    {
        $Partial += $item
    }
}

Write-Host "Conectividad total:"
foreach ($server in $Succeeded)
{
    Write-Host $server.servername -ForegroundColor Green    
}

Write-Host "Sin conectividad:"
foreach ($server in $Failed)
{
    Write-Host $server.servername -ForegroundColor Red    
}

Write-Host "Conectividad parcial:"
foreach ($server in $Partial)
{
    Write-Host $server.servername -ForegroundColor Yellow        
}

$ResultsFile = $LogPath + "\Test-SCCM-$Date.csv"
$results | Export-CSV -Path $ResultsFile -NoTypeInformation -Encoding UTF8 -Delimiter ";"

Write-Log "#####  Test-SCCM Terminado"