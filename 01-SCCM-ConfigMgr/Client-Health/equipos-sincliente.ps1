<#
.SYNOPSIS
Emails report of unmanaged devices with CSV attachments.

.DESCRIPTION
Pulls all devices from AD that have not changed their password in X days.
Pulls all SCCM unmanaged devices.
Combines this data and checks for last logon user, then pulls the following information into a report:
Computer | InSCCM | Client | OU | Last SCCM Activity | Last AD Logon | User | Time | Currently Logged in | Operating System | Additional Info

.REQUIREMENTS
Designed to run from the SCCM Server
Account running must have permissions to read CM Objects
Account running must have permissions to read AD Computer objects and atrributes

.PARAMETER Daysold
Mandatory string parameter; The number of days since machines in AD have changed their password (Default AD policy is every 30 days.  Recommend this parameter be 90 days).

.PARAMETER DomainSuffix
Mandatory string parameter; Your internal domain suffix. (Example: contoso.com)

.PARAMETER StaleCollectionID
Mandatory string parameter; The ID of a collection you create that holds devices that have no client
- Collection Query to use: select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,
                           SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,
                           SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Client != "1" 
                           or SMS_R_System.Client is null and SMS_R_System.OperatingSystemNameandVersion like "%NT%"

.PARAMETER SMTPServer
Mandatory string parameter; The FQDN of your SMTP server

.PARAMETER SMTPTo
Mandatory string parameter; The email address or DL you want to sent the report to

.PARAMETER $SMTPFrom
Mandatory string parameter; The email address you want to send the report from


.EXAMPLE (Office 365 Exchange Online)
.\Get-UnmanagedDevices-Report.ps1 -DaysOld 90 -DomainSuffix contoso.com -StaleCollectionID P0120304 -SMTPServer contoso-com01c.mail.protection.outlook.com -SMTPTo automation@contoso.com -SMTPFrom automation@contoso.com

.EXAMPLE (On premises Exchange)
.\Get-UnmanagedDevices-Report.ps1 -DaysOld 90 -DomainSuffix contoso.com -StaleCollectionID P0120304 -SMTPServer smtp.contoso.com -SMTPTo automation@contoso.com -SMTPFrom automation@contoso.com


.NOTES
This script is written to email using SMTP without a named account.  You will need to adjust if you need to send from a mailbox.
Written by William Bracken (Borrowed parts of other scripts of course)
Model Technology Solutions

.VERSION
Version 1.0 - 01/18/2017
Script creation
Version 1.1 - 01/25/2017
Added parameters

.LINK
Home



#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$True)]
    $DaysOld,

    [Parameter(Mandatory=$True)]
    $DomainSuffix,

    [Parameter(Mandatory=$True)]
    $StaleCollectionID,

    [Parameter(Mandatory=$True)]
    $SMTPServer,

    [Parameter(Mandatory=$True)]
    $SMTPFrom,

    [Parameter(Mandatory=$True)]
    $SMTPTo
)

#------------------------------------------------
# Get Last Logon user data
#------------------------------------------------
Function Get-LastLogon
{

    [CmdletBinding()]
    param(
    	[Parameter()]
    	[String]$ComputerName,
    	[String]$FilterSID,
    	[String]$WQLFilter="NOT SID = 'S-1-5-18' AND NOT SID = 'S-1-5-19' AND NOT SID = 'S-1-5-20'"
    	)

        # Adjusting ErrorActionPreference to stop on all errors
	    $ErrorActionPreference = "Stop"

        $NewUser = ''
        $Time = ''
        $CurrentlyLoggedOn = ''
        $AdditionalInfo = ''

        If ($FilterSID)
        {
        	$WQLFilter = $WQLFilter + " AND NOT SID = `'$FilterSID`'"
		}
        Try
        {
            
            Test-Connection $Computer -Count 1 | Out-Null
            $Win32User = Get-WmiObject -Class Win32_UserProfile -Filter $WQLFilter -ComputerName $Computer
			$LastUser = $Win32User | Sort-Object -Property LastUseTime -Descending | Select-Object -First 4

            Foreach ($sid in $LastUser)  
            {
			    $Loaded = $sid.Loaded
                If (!($null -eq $sid.LastuseTime))
                {
                    $Script:Time = ([WMI]'').ConvertToDateTime($sid.LastUseTime)
        					
				    #Convert SID to Account for friendly display
				    $Script:UserSID = New-Object System.Security.Principal.SecurityIdentifier($sid.SID)
                    Try 
                    {
    				    $User = $Script:UserSID.Translate([System.Security.Principal.NTAccount])

                        # =================================
                        # Disregard service accounts (accounts that have S_ in the name.  Adjust for your organization)
                        If ($user -notlike "*s_*")
                        {
                            $NewUser = $User
                        }
                    }
                    Catch
                    {
                        $_.Exception.Message
                    }
                }
                Else
                {
                                
                }
            }
                       
            # If NewUser is empty set for report
            If (!($NewUser))
            {
                $NewUser = "None Found"
            }
            $Time = $Script:Time
            $CurrentlyLoggedOn = $Loaded
            $AdditionalInfo = "N/A"
        			
        }#End Try
        Catch
	    {
    	    # Set Variables for PSObject For Output
            $Time = "N/A"
            $CurrentlyLoggedOn = "N/A"

            If ($_.Exception.Message -Like "*Some or all identity references could not be translated*")
			{
    		    Write-Warning "Unable to Translate $Script:UserSID, try filtering the SID `nby using the -FilterSID parameter."	
    			Write-Warning "It may be that $Script:UserSID is local to $Computer, Unable to translate remote SID"
			}
            elseif ($_.Exception.Message -like "*No such host is known*")
            {
                # Set AdditionalInfo for PSObject
                $AdditionalInfo = "Ping returned Invalid Hostname"
            }
            elseif ($_.Exception.Message -like "*Error due to lack of resources*")
            {
                $AdditionalInfo = "Ping returned no reply"
            }
            elseif ($_.Exception.Message -like "*A non-recoverable error occurred*")
            {
                $AdditionalInfo = "Ping returned no reply"
            }
            elseIf ($_.Exception.Message -like "*The RPC server is unavailable*")
            {
                # Set AdditionalInfo for PSObject
                #$AdditionalInfo = "Ping replies but RPC Server in unavailable"
                Write-Host "Checking reverse lookup" -ForegroundColor Green
                $PingTest = Test-Connection $Computer -Count 1
                $IPAddress = $PingTest.IPV4Address.IPAddressToString
                Write-host "IP Address: $IPaddress" -ForegroundColor Cyan
                $Ping = &cmd.exe "/c ping -a $IPAddress -n 1"
                $PingParsed = $Ping[1] -split "Pinging "
                $PingParsed2 = $PingParsed -split ".$DomainSuffix"
                $ReverseLookup = $PingParsed2[1]
                Write-Host "Reverse Lookup: $ReverseLookup" -ForegroundColor Cyan
                If ($ReverseLookup -like "*bytes of data*")
                {
                    $AdditionalInfo = "Reverse Lookup shows no Record"
                }
                elseif ($ReverseLookup -ne $Computer)
                {
                    $AdditionalInfo = "Reverse Lookup shows $ReverseLookup"
                }
                Else 
                {
                    $AdditionalInfo = "Name Resolves. RPC Server is Unavailable"
                }
            }
            elseif ($_.Exception.Message -like "*Problem with some part of the filterspec*")
            {
                $AdditionalInfo = "Ping TTL expired in transit"
            }
            elseif ($_.Exception.Message -like "*Access is Denied*")
            {
                # Set AdditionalInfo for PSObject
                $AdditionalInfo = "Ping replies but Access is Denied"
            }
            else
            {
                # Set AdditionalInfo for PSObject
                $AdditionalInfo = $_.Exception.Message
            }
		}#End Catch
        If (!($NewUser))
        {
                $NewUser = "None Found"
        }
        Return $NewUser, $Time, $CurrentlyLoggedOn, $AdditionalInfo
}# End Function Get-LastLogon

#------------------------------------------------
# Import the configuration manager module
#------------------------------------------------
Function Import-CMModule 
{
Write-Host "Importing configuration manager module"
Try {
        Import-Module -Name "$(split-path $Env:SMS_ADMIN_UI_PATH)\ConfigurationManager.psd1"
        $global:Site = Get-PSDrive -PSProvider CMSite
        Set-Location "$($Site):"
        Write-host "Site PSDrive now $Site" -ForegroundColor Green
        Set-Variable -Name Site -Value $Site.Name
    }
    Catch 
    {
        Write-host "Cannot import the Configuration Manager module. $_" -ForegroundColor Green
        exit 1
    } 
}

#============================================================================================
# Start Script

# Import CM Module
Import-CMModule

# Create Array
$ADMachines = @()
# Get days ago date
$DaysAgo = [Datetime]::Today.AddDays(-$DaysOld)

# Get AD Objects
Write-host "Getting AD Computers" -ForegroundColor Green
$ADMachines = Get-ADComputer -Filter {PasswordLastSet -le $DaysAgo} -Properties DistinguishedName, LastLogondate, lastLogonTimestamp, SID, OperatingSystem, Name, PasswordLastSet

# Create array
$ADMachinesColl = @()

# Process AD machines
$ADMachinesColl = Foreach ($ADMachine in $ADMachines)
{
    Write-host "=================================" -ForegroundColor Green
    Write-host "Processing AD Information for : " $ADMachine.Name -ForegroundColor Green
    
    # Set Object Variables
    $OU = $ADMachine.DistinguishedName -split $ADMachine.Name | Select-Object -Last 1
    $OU = $OU.TrimStart(",")
    Write-host "OU: " $OU -ForegroundColor Green

    Write-host "Converting LastLogonTimeStamp: " $ADMachine.LastLogonTimeStamp
    $LastLogonTimeStamp = $ADMachine | Select-Object LastLogonTimeStamp,@{Name = "Stamp";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}
    $LastMachineLogon = $LastLogonTimeStamp.Stamp
    Write-host "Converted Value: $LastMachineLogon" -ForegroundColor Green

    $OperatingSystem = $ADMachine.OperatingSystem
    Write-host "Operating System: $OperatingSystem" -ForegroundColor Green
   
    Write-host "Processing CM Information: " -ForegroundColor Green
    $ADMachineCMInfo = Get-CMDevice -Name $ADMachine.Name | Select-Object Name, IsClient, IsObsolete, LastActiveTime
    If ($ADMachineCMInfo.Name)
    {
        $Client = $ADMachineCMInfo.IsClient
        $InSCCMTrueFalse = $true
        $LastSCCMActivity = $ADMachineCMInfo.LastActiveTime
    }
    else
    {
        Write-host "No CM Object found for: " $ADMachine.Name -ForegroundColor Green
        $Client = $false
        $InSCCMTrueFalse = $false
        $LastSCCMActivity = "N/A"
    }
    If (!($LastSCCMActivity))
    {
        $LastSCCMActivity = "None found"
    }
    $Computer=$ADMachine.Name

    # Try to get Last Logged on user information
    $UserInfo = Get-LastLogon -ComputerName $ADMachine.Name -FilterSID $ADMachine.SID
    $NewUser = $UserInfo[0]
    $Time = $UserInfo[1]
    $CurrentlyLoggedOn = $UserInfo[2]
    $AdditionalInfo = $UserInfo[3]

    # For Debugging
    Write-Host "CM: Creating new object" -ForegroundColor Green
    Write-Host "--------------" -ForegroundColor Green
    Write-Host "Computer=$Computer" -ForegroundColor Green
    Write-Host "Client=$client" -ForegroundColor Green
    Write-Host "InSCCMTrueFalse=$InSCCMTrueFalse" -ForegroundColor Green
    Write-Host "LastSCCMActivity=$LastSCCMActivity" -ForegroundColor Green
    Write-Host "OU=$OU" -ForegroundColor Green
    Write-Host "LastMachineADLogon=$LastMachineLogon" -ForegroundColor Green
    Write-Host "User=$NewUser" -ForegroundColor Green
    Write-Host "Time=$Time" -ForegroundColor Green
    Write-Host "CurrentlyLoggedOn=$CurrentlyLoggedOn" -ForegroundColor Green
    Write-Host "OperatingSystem=$OperatingSystem" -ForegroundColor Green
    Write-Host "AdditionalInformation=$AdditionalInfo" -ForegroundColor Green
    Write-Host "--------------" -ForegroundColor Blue

    # Create PSObject
    New-Object -TypeName PSObject -Property @{
    Computer=$Computer
    Client=$Client
    InSCCM=$InSCCMTrueFalse
    LastSCCMActivity = $LastSCCMActivity
    OU=$OU
    LastMachineADLogon=$LastMachineLogon
	User=$NewUser
	Time=$Time
	CurrentlyLoggedOn=$CurrentlyLoggedOn
    OperatingSystem = $OperatingSystem
    AdditionalInformation=$AdditionalInfo
    } | Select-Object Computer, InSCCM, Client, OU, LastSCCMActivity, LastMachineADLogon, User, Time, CurrentlyLoggedOn, OperatingSystem, AdditionalInformation
}

# Get CM Devices from Stale Collection
Write-host "Getting CM Devices from non client collection" -ForegroundColor Green
$CMMachines = @()
$CMMachines = Get-CMDevice -CollectionId "$StaleCollectionID" 

# Create array
$CMMachinesColl = @()

# Process CM Objects
$CMMAchinesColl = Foreach ($CMMachine in $CMMachines)
{
    # Flush Variables
    $OU = ""
    $NewUser = ""
    $Time = ""

    # Set Object variables
    If (!($CMMachine.LastActiveTime))
    {
        $LastSCCMActivity = "N/A"
    }

    If ($ADMachinesColl.Computer -notcontains $CMMachine.Name -and $CMMachine.DeviceOS -notlike "*Server*" -and $CMMachine.Name -notlike "*Unknown*")
    {
        Write-host "=================================" -ForegroundColor Green
        Write-host "CM-Processing AD Information for : " $CMMachine.Name -ForegroundColor Green
        Try 
        {
            # Get AD info for CM Object
            $CMMachineADInfo = Get-ADComputer -Identity $CMMachine.Name -Properties DistinguishedName, LastLogondate, lastLogonTimestamp, SID, OperatingSystem, Name -ErrorAction Stop
            
            # Set Object variables
            $OU = $CMMachineADInfo.DistinguishedName -split $CMMachine.Name | Select-Object -Last 1
            $OU = $OU.TrimStart(",")
            Write-host "OU: " $OU -ForegroundColor Green

            Write-host "Converting LastLogonTimeStamp: " $CMMachineADInfo.LastLogonTimeStamp -ForegroundColor Green
            $LastLogonTimeStamp = $CMMachineADInfo | Select-Object LastLogonTimeStamp,@{Name = "Stamp";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}}
            $LastMachineLogon = $LastLogonTimeStamp.Stamp
            Write-host "Converted Value: $LastMachineLogon" -ForegroundColor Green

            $OperatingSystem = $CMMachineADInfo.OperatingSystem
            $Computer = $CMMachineADInfo.Name
            $Client = $CMMachine.IsClient
            $inSCCMTrueFalse = $true
            $LastSCCMActivity = $CMMachine.LastActiveTime
            if (!($LastSCCMActivity))
            {
                $LastSCCMActivity = "None found"
            }
            $UserInfo = Get-LastLogon -ComputerName $CMMachineADInfo.Name -FilterSID $CMMachineADInfo.SID
            $NewUser = $UserInfo[0]
            $Time = $UserInfo[1]
            $CurrentlyLoggedOn = $UserInfo[2]
            $AdditionalInfo = $UserInfo[3]
            
        }
        Catch
        {
            write-host "CM: Unable to locate an AD object for :" $CMMachine.Name -ForegroundColor Green
            Write-host $_.Exception.Message -ForegroundColor Cyan

            # Set Object variables
            $OU = "N/A"
            $LastMachineLogon = "N/A"
            $NewUser = "N/A"
            $Time = "N/A"
            $CurrentlyLoggedOn = "N/A"

            If ($_.Exception.Message -like "*Cannot find an object with identity*")
            {
                $AdditionalInfo = "NO AD OBJECT FOUND"
            }
            else
            {
                $AdditionalInfo = $_.Exception.Message
            }
        } # End Catch

        # Set Object variables
        $Client = $CMMachine.IsClient
        $inSCCMTrueFalse = $true
        $LastSCCMActivity = $CMMachine.LastActiveTime
        if (!($LastSCCMActivity))
        {
            $LastSCCMActivity = "None found"
        }
        $Computer = $CMMachine.Name
        $OperatingSystem = $CMMachineADInfo.OperatingSystem

        # User CM OS if it cannot be found in AD
        If ($null -eq $CMMachineADInfo.OperatingSystem)
        {
            $OperatingSystem = $CMMachine.DeviceOS
        }

        # For Debugging
        Write-Host "CM: Creating new object" -ForegroundColor Green
        Write-Host "--------------" -ForegroundColor Green
        Write-Host "Computer=$Computer" -ForegroundColor Green
        Write-Host "Client=$client" -ForegroundColor Green
        Write-Host "InSCCMTrueFalse=$InSCCMTrueFalse" -ForegroundColor Green
        Write-Host "LastSCCMActivity=$LastSCCMActivity" -ForegroundColor Green
        Write-Host "OU=$OU" -ForegroundColor Green
        Write-Host "LastMachineADLogon=$LastMachineLogon" -ForegroundColor Green
        Write-Host "User=$NewUser" -ForegroundColor Green
        Write-Host "Time=$Time" -ForegroundColor Green
        Write-Host "CurrentlyLoggedOn=$CurrentlyLoggedOn" -ForegroundColor Green
        Write-Host "OperatingSystem=$OperatingSystem" -ForegroundColor Green
        Write-Host "AdditionalInformation=$AdditionalInfo" -ForegroundColor Green
        Write-Host "--------------" -ForegroundColor Blue

        # Create PS Object
        New-Object -TypeName PSObject -Property @{
        Computer=$Computer
        Client=$Client
        InSCCM=$InSCCMTrueFalse
        LastSCCMActivity=$LastSCCMActivity
        OU=$OU
        LastMachineADLogon=$LastMachineLogon
    	User=$NewUser
    	Time=$Time
    	CurrentlyLoggedOn=$CurrentlyLoggedOn
        OperatingSystem=$OperatingSystem
        AdditionalInformation=$AdditionalInfo
        }| Select-Object Computer, InSCCM, Client, OU, LastSCCMActivity, LastMachineADLogon, User, Time, CurrentlyLoggedOn, OperatingSystem, AdditionalInformation
    }
}

# Add all the data together
$Collection = @()
$Collection = $ADMachinesColl
$Collection += $CMMachinesColl

# Separate into two arrays by Last AD login of specified days
$StaleUnManaged = @()
$FreshUnManaged = @()
foreach ($item in $Collection) 
{
    If ($item.LastMachineADLogon -lt $DaysAgo) 
    {
        $StaleUnManaged += $item
    } 
    else
    {
        $FreshUnManaged += $item
    }
}

# Count
$StaleCount = $StaleUnManaged.Count
$FreshCount = $FreshUnManaged.Count

# Sort
$StaleUnmanagedSorted = $StaleUnManaged.GetEnumerator() | Sort-Object -Property LastMachineADLogon
$FreshUnmanagedSorted = $FreshUnManaged.GetEnumerator() | Sort-Object -Property LastMachineADLogon

# Export to CSV for attachment
$StaleUnmanagedSorted | Export-Csv -NoTypeInformation -Path "$ENV:TEMP\StaleUnmanaged.csv" -Force
$FreshUnmanagedSorted | Export-Csv -NoTypeInformation -Path "$ENV:TEMP\RecentUnmanaged.csv" -Force

# Define Styles and Header
$Header =  @"
<style>
    BODY {
        padding-left: 40px;
        font-family: 'Segoe UI', Frutiger, 'Frutiger Linotype', 'Dejavu Sans', 'Helvetica Neue', Arial, sans-serif;
           font-style: normal;
           font-variant: normal;
           line-height: normal;
           white-space: nowrap;
    }
    TABLE {
        border-width: 1px;
        border-style: solid;
        border-color: black;
        border-collapse: collapse;
        width: 100%;
    }
    TH {
        border-width: 1px;
        padding: 0px;
        border-style: solid;
        border-color: black;
        background-color:green;
        color:white;
        padding: 5px;
        font-weight: bold;
        text-align:left;
        font-size: 16px;
    }
    TD {
        border-width: 1px;
        padding: 0px;
        border-style: solid;
        border-color: black;
        background-color:#FEFEFE;
        padding: 2px;
        font-size: 12px;
    }
    UL {
        list-style-type: none;
        list-style-position: inside;
        padding-left: 0px;
        margin: 0px;
    }
    LI {
        padding-left: 40px;
        padding-right: 40px;
    }
    h1 {
           font-size: 32px;
           font-weight: 500;
    }
    h2 {
           font-size: 23px;
           font-weight: 500;
    }
    h3 {
           font-size: 17px;
           font-weight: 500;
    }
    h4 {
           font-size: 14px;
           font-weight: 500;
    }
    p {
           font-size: 10px;
           font-weight: 400;
    }
    blockquote {
           font-size: 17px;
           font-weight: 400;
    }
    pre {
           font-size: 10px;
           font-weight: 400;
    }
</style>
"@


# Convert object into string for HTML email
$UnManagedHTML = ''
$UnManagedHTML += "<H2>Unmanaged Devices Report.</H2><br><H3><strong>STALE:</strong> Computers that have not signed into AD in $Daysold days or more <strong>(Count: $StaleCount)</strong></H3>"
$UnManagedHTML += $StaleUnmanagedSorted | ConvertTo-Html -Fragment
$UnManagedHTML += "<H3><strong>RECENT:</strong> Computers that have logged into AD in last $Daysold days <strong>(Count: $FreshCount)</strong></H3>"
$UnManagedHTML += $FreshUnmanagedSorted | ConvertTo-Html -Fragment

# Create email Body
$HTMLBody = ConvertTo-Html -Head $Header -Body $UnManagedHTML | Out-String

# Email report with attachements
Send-MailMessage -SmtpServer "$SMTPServer" -To "$SMTPTo" -From "$SMTPFrom" -Subject "All UnManaged Machine Report" -BodyAsHtml -Body $HTMLBody -Attachments "$ENV:TEMP\StaleUnmanaged.csv"