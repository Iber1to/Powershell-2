<#
.SYNOPSIS
    Genera un archivo CSV con los resultados de una baseline dada. 

.DESCRIPTION
    Nombre de la Baseline que recopila: 'ESU Year3'
    Recopila los datos del deploy de una baseline con el estado y le añade las siguientes propiedades:
        -DeviceName: Nombre netbios del endpoint,
        -ResourceID: Identificador unico del endpoint en SCCM.
        -ComplianceState: Estado de cumplimiento de la baseline.
        -Domain: Dominio del endpoint.
        -Build: Build del Sistema operativo del Endpoint.
        -Sistema Operativo: Traducción de la propiedad 'Build' por un nombre más amigable.

    Los resultados se exportan como CSV a la ruta de red desde donde se importan a PowerBi.
    Servidor donde se exportan los datos: SRV006


.NOTES
    Author:  IT Automation
    Website: https://www.linkedin.com/in/alejandro-aguado-08882a31/
    Twitter: @Alejand94399487
#> 
Import-Module "C:\01.Scripts\AAGFunctions.ps1"

$PathCMTracelog= 'C:\Scripts de Mantenimiento\ESUY3\esuy3logwork.log'
if( $(Test-Path -Path $PathCMTracelog)){Remove-Item -Path $PathCMTracelog -Force}

Write-CMTracelog 'Iniciando Script'
$networkPath = '\\SRV006\ComplianceUpdateServers\esuy3.csv'

Write-CMTracelog 'Cargando resultados de la baseline y creando listado de objetos'
# Se trae todos los dispositivos de un deployment de una baseline en concreto.
$Output2 = Get-WMIObject  -Namespace root\sms\site_PE1 -class SMS_G_System_DCMDeploymentState -Filter "BaselineID = 'ScopeId_07A9F6D2-402D-4213-B63C-28D0A663EBC2/Baseline_46ca1f37-4731-466a-bee9-033ce3185667'" | Select-Object ResourceName, ComplianceState, ResourceID

#Creamos el objeto y le añadimos las primeras propiedades sacadas de la consulta WMI.
$DeviceLists = @()

foreach($item in $Output2)
    {
    $DeviceEndPoint = New-Object -TypeName PSObject
    $DeviceEndPoint | Add-Member -MemberType NoteProperty  -Name 'DeviceName' -Value $item.ResourceName
    $DeviceEndPoint | Add-Member -MemberType NoteProperty  -Name 'ResourceID' -Value $item.ResourceID
    #Modifico el valor numerico de ComplianceState por algo mas legible.
    switch($item.ComplianceState)
            {
            1 {$DeviceEndPoint | Add-Member -MemberType NoteProperty  -Name 'ComplianceState' -Value "Compliant"}
            3 {$DeviceEndPoint | Add-Member -MemberType NoteProperty  -Name 'ComplianceState' -Value "Non-Compliant"}
            4 {$DeviceEndPoint | Add-Member -MemberType NoteProperty  -Name 'ComplianceState' -Value "Error"}
            5 {$DeviceEndPoint | Add-Member -MemberType NoteProperty  -Name 'ComplianceState' -Value "Unknown"}
            } 
    $DeviceLists += $DeviceEndPoint
    }
Write-CMTracelog 'Objetos creados'
Write-CMTracelog 'Ampliando propiedades de los objetos'
#Conectamos con SCCM y completamos el resto de propiedades para el objeto.
#Por temas de contraseñas, permisos y otras lides en lugar de usar la CMDlets de SCCM para powershell uso una consulta WMI.    
foreach($item in $DeviceLists)
    {
    $datosSCCM= Get-WmiObject -Namespace root\sms\site_PE1 -class SMS_R_System -Filter "ResourceId = $($item.ResourceId)" | Select-Object ResourceDomainORWorkgroup,OperatingSystemNameandVersion,Build
    #$datosSCCM= Get-CMDevice -ResourceId $item.ResourceId -Resource -Fast |Select-Object ResourceDomainORWorkgroup,OperatingSystemNameandVersion,BuildExt
    if($datosSCCM)
        {
        $item | Add-Member -MemberType NoteProperty  -Name 'Domain' -Value $datosSCCM.ResourceDomainORWorkgroup -Force
        $item | Add-Member -MemberType NoteProperty  -Name 'Build' -Value $datosSCCM.Build -Force
        #Convierto la build en un dato más amigable tipo: Windows Server 2019
        switch($datosSCCM.Build)
            {            
            '6.1.7601' {$item | Add-Member -MemberType NoteProperty  -Name 'Sistema Operativo' -Value 'Windows 7, Service Pack 1' -Force}
            '6.1.7600' {$item | Add-Member -MemberType NoteProperty  -Name 'Sistema Operativo' -Value 'Windows 7' -Force}
            }
        }
    
    }
Write-CMTracelog 'Propiedades ampliadas'
#Exportando el fichero a la ruta de red para ser importado en PowerBi.
$DeviceLists | Export-Csv -Path $networkPath -NoTypeInformation -Force
Write-CMTracelog 'Script Finalizado'