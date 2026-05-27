#Opcion 1

$UninstallElements
$UninstallCommand= ''
$UninstallItems+= @{"Path" = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" ; "ParamName" = "DisplayName"}
foreach($item in $UninstallItems){
$UElementsTemp= Get-ChildItem $Item.Path -ErrorAction SilentlyContinue
$UninstallElements+=$UElementsTemp
}

ForEach ($Item in $UninstallElements) {
        $UEDisplayname= Get-ItemProperty -Path $item.PSPath -Name 'Displayname' -ErrorAction SilentlyContinue
       if ($UEDisplayname -like '*Chrome*'){
        
        $UninstallCommand= Get-ItemProperty -Path $item.PSPath -Name 'UninstallString'
        
        }
        
}
$UninstallCommand.UninstallString
Start-Process -FilePath ($UninstallCommand.UninstallString).Split(' ')[0] -ArgumentList ($UninstallCommand.UninstallString).Split(' ')[1], /passive


#Opcion 2

$PathWoW= 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome'
$TestUninstallWoW= Test-Path -Path $PathWoW 
if ($TestUninstallWoW){
    $UninstallWoWString= Get-ItemProperty -Path $PathWoW -Name 'UninstallString'
    Start-Process -FilePath ($UninstallWoWString.UninstallString.Split('"')[1]) -ArgumentList "$($UninstallWoWString.UninstallString.Split('"')[2])"
}






#Opcion 3
New-PSDrive HKU Registry HKEY_USERS
$PathUserChrome= Get-ChildItem -Path HKU:\
foreach($item in $PathUserChrome){
$checkUserPath= Test-Path -Path "HKU:\$($item.Name.Split('\')[-1])\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome"
    if($checkUserPath){
        $UninstallCommand= Get-ItemProperty -Path "HKU:\$($item.Name.Split('\')[-1])\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome" -Name 'UninstallString'
       }
}
Start-Process -FilePath $UninstallCommand.UninstallString.Split(' ')[0] -ArgumentList "--uninstall --multi-install --chrome --verbose-logging --force-uninstall --delete-profile"
$Error