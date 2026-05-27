#Cambiar por la versíon a cambiar

$versionprincipal = 0
$StrCompliance= 'Compliance'

#Opcion 1


$UninstallItems= Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
foreach($item in $UninstallItems){
    $UEDisplayname= Get-ItemProperty -Path $item.PSPath -Name 'Displayname' -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
    if ($UEDisplayname.DisplayName -like '*Firefox*'){
                    
            $UninstallCommand= Get-ItemProperty -Path $item.PSPath -Name 'UninstallString' -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
            [int]$UninstallVersion= (Get-ItemProperty -Path $item.PSPath -Name 'DisplayVersion').DisplayVersion.Split('.')[0]
            If($UninstallVersion -le $versionprincipal){                
                If($UninstallCommand.UninstallString -like '*MsiExec.exe*'){Start-Process -FilePath ($UninstallCommand.UninstallString).Split(' ')[0] -ArgumentList ($UninstallCommand.UninstallString).Split(' ')[1], /qn}
                If($UninstallCommand.UninstallString -like '*helper.exe*'){
                    $PathUnintemp= $(($UninstallCommand.UninstallString).Split('"')[1])
                    $FilePathWithQuotes = '"{0}"' -f $PathUnintemp
                    Start-Process -FilePath "$(($UninstallCommand.UninstallString).Split('"')[1])" -ArgumentList '/s' -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
                }
                $StrCompliance= 'Compliance'
            }else{$StrCompliance= 'Compliance'}
    }
}

#Opcion2

$UninstallItemsWoW= Get-ChildItem -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
foreach($item in $UninstallItemsWoW){
    $UEDisplayname= Get-ItemProperty -Path $item.PSPath -Name 'Displayname' -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
    if ($UEDisplayname.DisplayName -like '*Firefox*'){
                  
        $UninstallCommand= Get-ItemProperty -Path $item.PSPath -Name 'UninstallString' -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
        [int]$UninstallVersion= (Get-ItemProperty -Path $item.PSPath -Name 'DisplayVersion').DisplayVersion.Split('.')[0] 
        If($UninstallVersion -le $versionprincipal){
            $UninstallCommand.UninstallString
            If($UninstallCommand.UninstallString -like '*MsiExec.exe*'){Start-Process -FilePath ($UninstallCommand.UninstallString).Split(' ')[0] -ArgumentList ($UninstallCommand.UninstallString).Split(' ')[1], /qn}
            If($UninstallCommand.UninstallString -like '*helper.exe*'){
                $PathUnintemp= $(($UninstallCommand.UninstallString).Split('"')[1])
                $FilePathWithQuotes = '"{0}"' -f $PathUnintemp
                Start-Process -FilePath "$(($UninstallCommand.UninstallString).Split('"')[1])" -ArgumentList '/s' -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
                }

            $StrCompliance= 'Compliance'
        }else{$StrCompliance= 'Compliance'}
    }
}

#Opcion 3
New-PSDrive HKU Registry HKEY_USERS -ErrorAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
$PathUserChrome= Get-ChildItem -Path HKU:\ -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
foreach($item in $PathUserChrome){
$checkUserPath= Test-Path -Path "HKU:\$($item.Name.Split('\')[-1])\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    if($checkUserPath){
       $UninstallItemsUser= Get-ChildItem -Path "HKU:\$($item.Name.Split('\')[-1])\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
            foreach($item in $UninstallItemsUser){
            $UEDisplayname= Get-ItemProperty -Path $item.PSPath -Name 'Displayname' -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
                if ($UEDisplayname.DisplayName -like '*Firefox*'){                  
                    $UninstallCommand= Get-ItemProperty -Path $item.PSPath -Name 'UninstallString' -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
                    [int]$UninstallVersion= (Get-ItemProperty -Path $item.PSPath -Name 'DisplayVersion').DisplayVersion.Split('.')[0]
                         If($UninstallVersion -le $versionprincipal){                
                            If($UninstallCommand.UninstallString -like '*MsiExec.exe*'){Start-Process -FilePath ($UninstallCommand.UninstallString).Split(' ')[0] -ArgumentList ($UninstallCommand.UninstallString).Split(' ')[1], /qn}
                            If($UninstallCommand.UninstallString -like '*helper.exe*'){
                                $PathUnintemp= $(($UninstallCommand.UninstallString).Split('"')[1])
                                $FilePathWithQuotes = '"{0}"' -f $PathUnintemp
                                Start-Process -FilePath "$(($UninstallCommand.UninstallString).Split('"')[1])" -ArgumentList '/s' -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
                            }
                    $StrCompliance= 'Compliance'
                }else{$StrCompliance= 'Compliance'}
             }   
        }
    }
}
Write-Output $StrCompliance