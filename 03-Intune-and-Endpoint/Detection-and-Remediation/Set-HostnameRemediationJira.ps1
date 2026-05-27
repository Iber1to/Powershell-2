Start-Transcript -Path "C:\Windows\Temp\Set-HostanameRemediation.log" -Force
function Get-HostsFile {
    <#
    .SYNOPSIS
        Get the path to the local hostfile
    .DESCRIPTION
        Check the PSVersionTable to see our platform and then return the path to the hosts file accordingly.
    .EXAMPLE
        Get-HostsFile
    #>

    Switch ($PSVersionTable) {
        {
            ($_.PSEdition -eq 'Desktop') -or
            ($_.PSEdition -eq 'Core' -and $_.Platform -eq 'Win32NT')
        } 
            {return 'C:\Windows\System32\drivers\etc\hosts' }
        {
            $_.PSEdition -eq 'Core' -and $_.Platform -eq 'Unix'
        } 
            {return '/etc/hosts'}
    }
    Write-Error "Could not determin platform"
}

function Set-HostsRecord {
    <#
    .SYNOPSIS
        Edit your hosts file using powershell
    .DESCRIPTION
        Update or add a record to your local hosts files
    .PARAMETER HostName
        Specify the hostname you want to add or edit
    .PARAMETER IPAddress
        Specify the ip address you want to set or update the host to
    .EXAMPLE
        Set single hostname to a specific ip.

        Set-HostsRecord -HostName google.com -IPAddress 127.0.0.1
    .EXAMPLE
        Set multiple hostnames to the same ip.
        
        Set-HostsRecord -HostName "www.google.com google.com youtube.com" -IPAddress 127.0.0.1
    #>
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$True)]$HostName,
        [Parameter(Mandatory=$True)][ValidateScript(
            {
                $_ -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
            }
            )]$IPAddress
    )

    $HostFile = Get-HostsFile
    $HostNames = $HostName -split ' '
    $i = 0
    $CurrRecord = $null
    While ( $null -eq $CurrRecord -and $i -lt $HostNames.Count) {
        $CurrRecord = Get-HostsRecord -HostName $HostNames[$i]
        $i++
    }
    If ($CurrRecord) {
        $NewRecordFile = Get-Content $HostFile | ForEach-Object {
            If ($_ -imatch $HostNames[$i-1]) {
                Write-Output "$IPAddress $HostName"
            } else {
                $_
            }
        }
        $NewRecordFile | Out-File $HostFile -Encoding ascii
    } else {
        Write-Output "`n$IPAddress $HostName" | Out-File $HostFile -Append -Encoding ascii
    }

}

function Remove-HostsRecord {
    <#
    .SYNOPSIS
        Remove a host record enty
    .DESCRIPTION
        Remove an entire host file entry if a single host is matched from the local hosts file
    .PARAMETER HostName
        Specify the hostname to remove from the hosts file
    .EXAMPLE
        Remove all hosts pointing to the same ip ad google.com. If you want to just remove a single host, see Set-HostsRecord

        Remove-HostRecord -HostName google.com
    #>
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$True)]$HostName,
        [switch]$Confirm=[switch]$False
    )

    $CurrHost = Get-HostsRecord -HostName $HostName
    If (-Not $CurrHost) {
        Write-Error "No record for $HostName found"
    } else {
        $HostFile = Get-HostsFile
        If (-Not $Confirm) {
            $read = $null
            While ($read -notin 'y','n') {
                $read = Read-Host "Confirm deletion of $HostName $CurrHost (y/n)"
            }
            If ($read -eq 'n') {
                return
            }
        }
        $NewRecordFile = Get-Content $HostFile | Where-Object {
            $_ -inotmatch $HostName
        }
        $NewRecordFile | Out-File $HostFile -Encoding ascii
    }
}

function Get-HostsRecord {
    <#
    .SYNOPSIS
        See the ipaddress set for a host in the hosts file
    .DESCRIPTION
        Parse the hosts file into a hashtable, return the value of any keys matching the Hostname Name
    .PARAMETER HostName
        Specify a host to show only
    .EXAMPLE
        Get-HostsRecord -HostName google.com

        127.0.0.1
    .EXMAPLE
        Get-HostsRecord

        Name                           Value
        ----                           -----
        localhost                      127.0.0.1
        hp                             198.51.100.810
        pi                             198.51.100.811

    #>
    [CmdLetBinding()]
    Param($HostName)

    $HostFile = Get-HostsFile
    $Hosts = @{}
    Get-Content $HostFile | ForEach-Object {
        If ($_ -match '^(\s|)\d+.*') {
            $Split = $_.Trim() -split '\s+',2
            $HostSplit = $Split[1] -split '\s+'
            $HostSplit | ForEach-Object {
                $Hosts.Add($_,$Split[0]) 
            }
        }
    }
    If ($HostName) {
        return $Hosts[$HostName]
    } else {
        return $Hosts
    }
}

Set-HostsRecord -HostName "jira.ClientUtility.es" -IPAddress "198.51.100.815"

Stop-Transcript