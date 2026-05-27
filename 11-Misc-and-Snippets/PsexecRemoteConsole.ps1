<#
.AUTHOR
       Powered by an external team to CONTOSO 

.SYNOPSIS
        Permite ejecutar una consola o un script en un equipo remoto.

.DESCRIPTION
        Permite abrir un CMD con privilegios elevados en un equipo remoto con LAPS.
        Permite ejecutar scripts en un equipo remoto con LAPS

.PARAMETER $Equipo
        Es el primer parametro que nos pide. Nombre NETBIOS del equipo remoto 
        Parametro obligatorio si esta vacio se detendra la ejecucion.

.PARAMETER $Script
        Es el segundo parametro que nos pide. Ruta del script a ejecutar en el equipo remoto.
        Parametro opcional.

.LOGS
        
#>
<#     
VERSION HISTORY
        V1.0 29 Octubre  2020 - Primera versión del Script

#>

param ([string]$Equipo = $( Read-Host "Introduce el nombre NETBIOS del equipo" ))

$ErrorActionPreference = "SilentlyContinue"

#Compruebo que el parametro no este vacio
if ($Equipo -eq "") {
Write-Host "Parametro no introducido" -ForegroundColor Red 
Break}

#Preparo las credenciales para la consola remota
$laps = Get-AdmPwdPassword –Computername $equipo
$password = ConvertTo-SecureString $laps.Password -AsPlainText -Force 
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList ("administrador",$Password)
net user administrador $laps.Password >> $CompLog

#Compruebo que la maquina tiene LAPS
if ($laps.Password -eq $null) {
Write-Host "Este equipo no tiene laps" -ForegroundColor Red 
Break}


#Resolviendo nombre Netbios
$dominios = @(".contoso.local", ".emea.contoso.local", ".latam1.contoso.local", ".latam2.contoso.local", ".apac.contoso.local", ".na.contoso.local")
$maquina = $null
foreach($dominio in $dominios){
$equipotemp = $equipo+$dominio
#Chequeo que la maquina tenga respuesta
$pingresult = Test-netconnection -ComputerName $equipotemp -WarningAction:SilentlyContinue
if ($pingresult.PingSucceeded -eq $true){
$maquina = $equipotemp
}
}

If ($maquina -eq $null){
Write-Host "El equipo no es accesible, comprueba que esta encendido" -ForegroundColor Red 
Break
}


#Ejecutamos la tarea
Start-Process -Filepath "C:\Pstools\psexec.exe" -Argumentlist "\\$maquina -h  CMD" -Credential $cred

#Funcion para crear un password aleatorio para .\administrador
Add-Type -AssemblyName 'System.Web'

function New-RandomPassword {
    param(
        [Parameter()]
        [int]$MinimumPasswordLength = 5,
        [Parameter()]
        [int]$MaximumPasswordLength = 10,
        [Parameter()]
        [int]$NumberOfAlphaNumericCharacters = 5,
        [Parameter()]
        [switch]$ConvertToSecureString
    )

    $length = Get-Random -Minimum $MinimumPasswordLength -Maximum $MaximumPasswordLength
    $plainTextPassword = [System.Web.Security.Membership]::GeneratePassword($length,$NumberOfAlphaNumericCharacters)
    if ($ConvertToSecureString.IsPresent) {
        ConvertTo-SecureString -String $password -AsPlainText -Force
    } else {
        $password
    }
}

$contraseña= New-RandomPassword -MinimumPasswordLength 10 -MaximumPasswordLength 15 -NumberOfAlphaNumericCharacters 6

#Actualizamos el usuario .\administrador con el password ramdon

net user administrador $contraseña >> $CompLog