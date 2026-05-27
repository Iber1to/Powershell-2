# Preparando entorno
$UserName = 'EMEA\SVC_SCCM_PROXY'
$PlainPassword = "REDACTED_PASSWORD"
$SecurePassword = $PlainPassword | ConvertTo-SecureString -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
$Machine= hostname
$DomainMachine = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select-Object Name, Domain
if($DomainMachine.Domain -eq 'emea.contoso.local'){
    New-PSDrive -Name "Q" -Root "\\SRV002.emea.contoso.local\Bitlocker_Keys$" -PSProvider "FileSystem" -Credential $Credentials |Out-Null
    $logfile = q:\list_deploy_emea.txt
}elseif ($DomainMachine.Domain -eq 'latam2.contoso.local') {
    New-PSDrive -Name "Q" -Root "\\SRV024.latam2.contoso.local\Bitlocker_Keys$" -PSProvider "FileSystem" -Credential $Credentials |Out-Null
    $logfile = q:\list_deploy_latam2.txt
}elseif ($DomainMachine.Domain -eq 'latam1.contoso.local') {
    New-PSDrive -Name "Q" -Root "\\SRV001.latam1.contoso.local\Bitlocker_Keys$" -PSProvider "FileSystem" -Credential $Credentials |Out-Null
    $logfile = q:\list_deploy_latam1.txt
}

$Test=Test-Path -Path q:\$machine
if($Test -eq $false){mkdir q:\$machine}

#Checkear si ya esta encriptado
$Con= Get-BitLockerVolume -MountPoint C:
if($con.KeyProtector)
    {
    $listDisksVolumes = Get-Volume
    foreach ($itemVolume in $listDisksVolumes) {
            if(($itemVolume.DriveLetter -eq 'D') -and ($itemVolume.DriveType -eq 'Fixed')){
                $testEncript = Get-BitLockerVolume -MountPoint D: -ErrorAction SilentlyContinue
                if ($null -eq $testEncript.KeyProtector){
                    #Lanzando encriptado unidad d:
                    Try{
                    Enable-BitLocker -MountPoint D: -UsedSpaceOnly -RecoveryPasswordProtector        
                    Write-Host "Bitlocker activado con exito en la unidad"
                    }Catch {Write-Host "Fallo al habilitar Bitlocker en la unidad D:"}               
                    #Backup de las claves a AD y Primary de otras unidades:  
                    $BLV = Get-BitLockerVolume -MountPoint D:
                    Try{
                    Backup-BitLockerKeyProtector -MountPoint D: -KeyProtectorId $BLV.KeyProtector[1].KeyProtectorId
                    Write-Host "Clave unidad $Drive exportada con exito a AD"
                    }Catch{"Fallo al realizar backup en AD de la unidad D:"}
                    Try{
                    $timestamp= [DateTime]::Now.ToString("yyyy-MM-dd_HHmmss")
                    manage-bde.exe -protectors -get D: > q:\$machine\bde_protectors_$timestamp.txt -Append
                    Write-Host "Clave unidad C: exportada con exito a carpeta de red"
                    }Catch {Write-Host "Fallo al realizar backup de la unidad D: en el primary"}              
                }
            }
        }
    }   





$machine |Out-File -FilePath $logfile -Append

