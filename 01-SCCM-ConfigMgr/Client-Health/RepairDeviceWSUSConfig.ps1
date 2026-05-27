$MachinePol = "$env:windir\system32\GroupPolicy\Machine"
$UserPol = "$env:windir\system32\GroupPolicy\User"

#Remove Wsus regedit entries
Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name WUServer -Force -ErrorAction SilentlyContinue |Out-Null
Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\" -Name WUStatusServer -Force -ErrorAction SilentlyContinue |Out-Null


#delete the Machine (Computer) Policy folder
If (Test-Path $MachinePol) {ri -Path $MachinePol -Recurse -Confirm:$false -ErrorAction SilentlyContinue |Out-Null}

#delete the User Policy folder
If (Test-Path $UserPol) {ri -Path $UserPol -Recurse -Confirm:$false -ErrorAction SilentlyContinue |Out-Null}

Invoke-Command -ScriptBlock {gpupdate /force} -ErrorAction SilentlyContinue | Out-Null

Get-Service | where {$_.Name -eq "CCMExec"} | Restart-Service -ErrorAction SilentlyContinue -WarningAction SilentlyContinue| Out-Null  #Reinicia el cliente SCCM 
