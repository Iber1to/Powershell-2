<#
Script que alimenta los grupos de seguridad de los 4 dominios para desinstalar el cliente SCCM de los equipos clonados.
Tambien recoge los resultados de los equipos que ya han ejecutado el script y los saca del grupo correspondiente
#>
#Funciónes para el log
$logprefix= [long] (Get-Date -Date ((Get-Date).ToUniversalTime()) -UFormat %s)
$LogName= 'clonados'
$outFilePathlog= 'C:\Scripts de Mantenimiento\logs\uninstallclient\'
$outFilelog ="$outFilePathlog\$Logname$logprefix.log"
 $(Get-Date -f g)

function Write-Log
    {
    [CmdletBinding()]
    param
        (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
        )


    $Time= (Get-Date -f g)
    $Tab= [char]9
    If($Severity -eq 'Information')
        {
        $line="$Time $Tab $Message $Tab"        
        Add-Content -Value $line -Path $outFilelog
        }
    else
        {
        $line="$Time $Tab $Message $Tab $Severity"        
        Add-Content -Value $line -Path $outFilelog
        }
    }

function Error-Log
    {
    Write-Log "Fallo al realizar la tarea" -Severity Error
    Write-Log $_.Exception.Message
    }


Write-Log "--- Iniciando Script ---" -Severity Warning
Write-Log "$(Get-Date -f g)"
Write-Log "---"
Write-Log "---"
#Variables configurables
$TargetCollection= 'GLOBAL_MGM_WS_QR_Clients_Pending'
$ApacDomainController= 'SRV056.apac.contoso.local'
$ApacSecurityGroup= 'G_AU_GPO_SCCM_Client_Uninstall'
$EmeaDomainController= 'SRV003.emea.contoso.local'
$EmeaSecurityGroup= 'G_EME_GPO_SCCM_Client_Uninstall'
$Latam1DomainController= 'SRV057.latam1.contoso.local'
$Latam1SecurityGroup= 'G_LA1_GPO_SCCM_Client_Uninstall'
$Latam2DomainController= 'SRV058.latam2.contoso.local'
$Latam2SecurityGroup= 'G_BR_GPO_SCCM_Client_Uninstall'
$FileRemovePath= '\\SRV002\client\Duplicados\'



#cargamos los csv con los equipos que ya han ejecutado el script
Write-Log "Cargando CSV con dispositivos de APAC"
$TestCsv= Test-Path -Path \\SRV002.emea.contoso.local\client\Duplicados\eliminar_Duplicados_APAC.csv
If($TestCsv)
{
    Try
        {
        $DevicesApacRemove= Import-Csv -Path \\SRV002.emea.contoso.local\client\Duplicados\eliminar_Duplicados_APAC.csv
        Write-Log "APAC datos cargados correctamente"
        }catch{Error-Log}
}else{Write-Log "Apac no tiene datos" -Severity Warning}


Write-Log "Cargando CSV con dispositivos de EMEA"
$TestCsv= Test-Path -Path \\SRV002.emea.contoso.local\client\Duplicados\eliminar_Duplicados_EMEA.csv
If($TestCsv)
{ 
    Try
        {
        $DevicesEmeaRemove= Import-Csv -Path \\SRV002.emea.contoso.local\client\Duplicados\eliminar_Duplicados_EMEA.csv
        Write-Log "EMEA datos cargados correctamente"
        }catch{Error-Log}
}else{Write-Log "EMEA no tiene datos" -Severity Warning}


Write-Log "Cargando CSV con dispositivos de LATAM1"
$TestCsv= Test-Path -Path \\SRV002.emea.contoso.local\client\Duplicados\eliminar_Duplicados_Latam1.csv
If($TestCsv)
    { 
    Try
        {
        $DevicesLatam1Remove= Import-Csv -Path \\SRV002.emea.contoso.local\client\Duplicados\eliminar_Duplicados_Latam1.csv
        Write-Log "LATAM1 datos cargados correctamente"
        }catch{Error-Log}
}else{Write-Log "LATAM1 no tiene datos" -Severity Warning}


Write-Log "Cargando CSV con dispositivos de LATAM2"
$TestCsv= Test-Path -Path \\SRV002.emea.contoso.local\client\Duplicados\eliminar_Duplicados_Latam2.csv
If($TestCsv)
    { 
    Try
        {
        $DevicesLatam2Remove= Import-Csv -Path \\SRV002.emea.contoso.local\client\Duplicados\eliminar_Duplicados_Latam2.csv
        Write-Log "LATAM2 datos cargados correctamente"
        }catch{Error-Log}
}else{Write-Log "LATAM2 no tiene datos" -Severity Warning}



#Procesamos los listados anteriores y quitamos los equipos de los grupos objetivo de Active Directory
Write-Log "--- Eliminando dispositivos APAC del grupo $ApacSecurityGroup ---"
foreach($device in $DevicesApacRemove)
    {
    $deviceSAM= $device.name+'$'
    Try
        {
        Remove-ADGroupMember -Server $ApacDomainController -Identity $ApacSecurityGroup -Members $deviceSAM -Confirm:$false 
        Write-Log "$($device.name) Fue eliminado del grupo $ApacSecurityGroup con exito"
        }catch{Error-Log}
    }
Write-Log "--- Finalizo el proceso de $ApacSecurityGroup ---"


Write-Log "--- Eliminando dispositivos de $EmeaSecurityGroup ---"
foreach($device in $DevicesEmeaRemove)
    {
    $deviceSAM= $device.name+'$'
    Try
        {
        Remove-ADGroupMember -Server $EmeaDomainController -Identity $EmeaSecurityGroup -Members $deviceSAM -Confirm:$false
        Write-Log "$($device.name) Fue eliminado del grupo $EmeaSecurityGroup con exito"
        }catch{Error-Log}    
    }
Write-Log "--- Finalizo el proceso de $EmeaSecurityGroup ---"


Write-Log "--- Eliminando dispositivos de $Latam1SecurityGroup ---"
foreach($device in $DevicesLatam1Remove)
    {
    $deviceSAM= $device.name+'$'
    Try
        {
        Remove-ADGroupMember -Server $Latam1DomainController -Identity $Latam1SecurityGroup -Members $deviceSAM -Confirm:$false
        Write-Log "$($device.name) Fue eliminado del grupo $Latam1SecurityGroup con exito"
        }catch{Error-Log}
    }
Write-Log "--- Finalizo el proceso de $Latam1SecurityGroup ---"


Write-Log "--- Eliminando dispositivos de $Latam2SecurityGroup ---"
foreach($device in $DevicesLatam2Remove)
    {
    $deviceSAM= $device.name+'$'
    Try
        {
        Remove-ADGroupMember -Server $Latam2DomainController -Identity $Latam2SecurityGroup -Members $deviceSAM -Confirm:$false
        Write-Log "$($device.name) Fue eliminado del grupo $Latam2SecurityGroup con exito"
        }catch{Error-Log}
    }
Write-Log "--- Finalizo el proceso de $Latam2SecurityGroup ---"



Write-Log "Iniciando Backup de los CSV procesados"

$date = Get-Date -format "yyyyMMdd"
#Creamos una carpeta por ejecución y guardamos todos los csv que procesamos anteriormente
$checkFolder= Test-Path -Path $FileRemovePath$date
If($checkFolder)
    {
    Write-Log "La carpeta de Backup $FileRemovePath$date ya existe"
    Write-Log "Moviendo CSV's a la carpeta Backup"
    Try
        {
        Move-Item -Path $FileRemovePath\*.csv -Destination $FileRemovePath$date -Force
        Write-Log "Los CSV's se movieron correctamente"
        }catch{Error-Log}
    }
else
    { 
    Try
      {
      Write-Log "Creando la carpeta de Backup $FileRemovePath$date"
      New-Item -Path $FileRemovePath$date -type directory -Force
      Write-Log "Carpeta creada con exito"
      }catch{Error-Log}
    Try
      {
      Write-Log "Moviendo CSV's a la carpeta Backup"
      Move-Item -Path $FileRemovePath\*.csv -Destination $FileRemovePath$date -Force
      Write-Log "Los CSV's se movieron correctamente"
      }catch{Error-Log}
    }

    


#Cargamos el modulo de SCCM para poder usar us CMDLETS
Write-Log "--- Conectando con el servidor CAS ---"
Try
    {
    Import-module ($Env:SMS_ADMIN_UI_PATH.Substring(0,$Env:SMS_ADMIN_UI_PATH.Length-5) + '\ConfigurationManager.psd1') -ErrorAction SilentlyContinue
    Set-Location CAS:
    Write-Log "Conexion al CAS completada"
    }catch{Error-Log}


#Trae todos los dispositivos en la coleccicon objetivo y los separa por dominio
Write-Log "Listando dispositivos de la coleccion $TargetCollection"
Try
    {
    $Devices= Get-CMDevice -CollectionName $TargetCollection |Select Domain, name
    Write-Log "Lista de dispositivos cargada"
    }catch{Error-Log}
Write-Log "Separando dispositivos por Dominio"
$DevicesApac= $Devices | where {$_.domain -like 'APAC'} |select Name
$DevicesEmea= $Devices | where {$_.domain -like 'EMEA'} |select Name
$DevicesLatam1= $Devices | where {$_.domain -like 'LATAM1'} |select Name
$DevicesLatam2= $Devices | where {$_.domain -like 'LATAM2'} |select Name
Write-Log "Proceso finalizado"


#Añadir los equipos a los Grupos objetivos de ActiveDirectory.
#Cargo primero los grupos para poder comprobar que los equipos no estan antes de cargarlos.
Write-Log "Listando dispositivos en los grupos de seguridad"
$membersAPAC = Get-ADGroupMember -Server $ApacDomainController -Identity $ApacSecurityGroup -Recursive | Select -ExpandProperty Name
Write-Log "Dispositivos en $ApacSecurityGroup listados con exito"
$membersEmea = Get-ADGroupMember -Server $EmeaDomainController -Identity $EmeaSecurityGroup -Recursive | Select -ExpandProperty Name
Write-Log "Dispositivos en $EmeaSecurityGroup listados con exito"
$membersLatam1 = Get-ADGroupMember -Server $Latam1DomainController -Identity $Latam1SecurityGroup -Recursive | Select -ExpandProperty Name
Write-Log "Dispositivos en $Latam1SecurityGroup listados con exito"
$membersLatam2 = Get-ADGroupMember -Server $Latam2DomainController -Identity $Latam2SecurityGroup -Recursive | Select -ExpandProperty Name
Write-Log "Dispositivos en $Latam2SecurityGroup listados con exito"


Write-Log "--- Incluyendo dispositivos al grupo $ApacSecurityGroup ---"
foreach($device in $DevicesApac)
    {
    $deviceSAM= $device.name+'$'
    if($membersAPAC -notcontains $device.Name)
        {
        Try
            {
            Add-ADGroupMember -Server $ApacDomainController -Identity $ApacSecurityGroup -Members $deviceSAM -ErrorAction Continue
            Write-Log "$($device.name) incluido con exito"
            }catch{Error-Log}
        }
    }


Write-Log "--- Incluyendo dispositivos al grupo $EmeaSecurityGroup ---"
foreach($device in $DevicesEmea)
    {
    $deviceSAM= $device.name+'$'
    if($membersEmea -notcontains $device.name)
        {
        Try{
           Add-ADGroupMember -Server $EmeaDomainController -Identity $EmeaSecurityGroup -Members $deviceSAM -ErrorAction Continue
           Write-Log "$($device.name) incluido con exito"
           }catch{Error-Log}
        }
    }


Write-Log "--- Incluyendo dispositivos al grupo $Latam1SecurityGroup ---"
foreach($device in $DevicesLatam1)
    {
    $deviceSAM= $device.name+'$'
    if($membersLatam1 -notcontains $device.name)
        {
        Try{
           Add-ADGroupMember -Server $Latam1DomainController -Identity $Latam1SecurityGroup -Members $deviceSAM -ErrorAction Continue
           Write-Log "$($device.name) incluido con exito"
           }catch{Error-Log}
        }
    }

    
Write-Log "--- Incluyendo dispositivos al grupo $Latam2SecurityGroup ---"
foreach($device in $DevicesLatam2)
    {
    $deviceSAM= $device.name+'$'
    if($membersLatam2 -notcontains $device.name)
        {
        Try
            {
            Add-ADGroupMember -Server $Latam2DomainController -Identity $Latam2SecurityGroup -Members $deviceSAM -ErrorAction Continue
            Write-Log "$($device.name) incluido con exito"
            }catch{Error-Log}
        }
    }
    

Write-Log "--"
Write-Log "--"
Write-Log "--- Script Finalizado ---" -Severity Warning
Write-Log "$(Get-Date -f g)"