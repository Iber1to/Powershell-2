#Cambiar por la versíon a cambiar

$versionprincipal = 95
$StrCompliance= 'Compliance'

#Opcion 1


$UninstallItems= Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
foreach($item in $UninstallItems){
    $UEDisplayname= Get-ItemProperty -Path $item.PSPath -Name 'Displayname' -ErrorAction SilentlyContinue
    $UEDisplayname.DisplayName
        if ($UEDisplayname.DisplayName -like '*Chrome*'){
                    
            $UninstallCommand= Get-ItemProperty -Path $item.PSPath -Name 'UninstallString'
            [int]$UninstallVersion= (Get-ItemProperty -Path $item.PSPath -Name 'DisplayVersion').DisplayVersion.Split('.')[0]
            If($UninstallVersion -le $versionprincipal){
                $UninstallCommand.UninstallString
                #Start-Process -FilePath ($UninstallCommand.UninstallString).Split(' ')[0] -ArgumentList ($UninstallCommand.UninstallString).Split(' ')[1], /passive
                $StrCompliance= 'Compliance'
            }else{$StrCompliance= 'Compliance'}
    }
}

#Opcion2

$UninstallItemsWoW= Get-ChildItem -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
foreach($item in $UninstallItemsWoW){
    $UEDisplayname= Get-ItemProperty -Path $item.PSPath -Name 'Displayname' -ErrorAction SilentlyContinue
    $UEDisplayname.DisplayName
    if ($UEDisplayname.DisplayName -like '*Chrome*'){
                    
        $UninstallCommand= Get-ItemProperty -Path $item.PSPath -Name 'UninstallString'
        [int]$UninstallVersion= (Get-ItemProperty -Path $item.PSPath -Name 'DisplayVersion').DisplayVersion.Split('.')[0]
        If($UninstallVersion -le $versionprincipal){
            $UninstallCommand.UninstallString
            Start-Process -FilePath ($UninstallCommand.UninstallString).Split(' ')[0] -ArgumentList ($UninstallCommand.UninstallString).Split(' ')[1], /qn
            $StrCompliance= 'Compliance'
        }else{$StrCompliance= 'Compliance'}
    }
}
       
        




#Opcion 3
New-PSDrive HKU Registry HKEY_USERS
$PathUserChrome= Get-ChildItem -Path HKU:\
foreach($item in $PathUserChrome){
$checkUserPath= Test-Path -Path "HKU:\$($item.Name.Split('\')[-1])\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome"
    if($checkUserPath){
       $StrCompliance= 'No Compliance' 
       }
}

Write-Output $StrCompliance