
# ***** START DATE PROCESSING SECTION ***** 
	#Get Second Tuesday
	$FindNthDay=2
	$WeekDay='Tuesday'
	[datetime]$Today=[datetime]::NOW
	$todayM=$Today.Month.ToString()
	$todayY=$Today.Year.ToString()
	[datetime]$StrtMonth=$todayM+'/1/'+$todayY

	while ($StrtMonth.DayofWeek -ine $WeekDay ) { $StrtMonth=$StrtMonth.AddDays(1) }

	$SecondTuesday = $StrtMonth.AddDays(7*($FindNthDay-1))

	#Get day-of-week Availability and Deadline times
	

	#EMEA Deployment times, valid for PE1 and PE2 sites
	#APAC Deployment times, valid for site PL1
	$MondayDeplDay = $SecondTuesday.AddDays(6)
	
	[datetime]$GLOBALMondayAvailTime=$MondayDeplDay.AddHours(16)
	[datetime]$GLOBALMondayInstallTime=$MondayDeplDay.AddHours(20)
	
	<#
	[datetime]$EMEAMondayAvailTime=$MondayDeplDay.AddHours(16)
	[datetime]$EMEAMondayInstallTime=$MondayDeplDay.AddHours(20)
	[datetime]$APACMondayAvailTime=$MondayDeplDay.AddHours(4)
	[datetime]$APACMondayInstallTime=$MondayDeplDay.AddHours(18)
	#>
	
	$TuesdayDeplDay = $SecondTuesday.AddDays(7)
	[datetime]$GLOBALTuesdayAvailTime=$TuesdayDeplDay.AddHours(16)
	[datetime]$GLOBALTuesdayInstallTime=$TuesdayDeplDay.AddHours(20)

	$WednesdayDeplDay = $SecondTuesday.AddDays(8)
	[datetime]$GLOBALWednesdayAvailTime=$WednesdayDeplDay.AddHours(16)
	[datetime]$GLOBALWednesdayInstallTime=$WednesdayDeplDay.AddHours(20)

	$ThursdayDeplDay = $SecondTuesday.AddDays(9)
	[datetime]$GLOBALThursdayAvailTime=$ThursdayDeplDay.AddHours(16)
	[datetime]$GLOBALThursdayInstallTime=$ThursdayDeplDay.AddHours(20)
	
	$FridayDeplDay = $SecondTuesday.AddDays(10)
	[datetime]$GLOBALFridayAvailTime=$FridayDeplDay.AddHours(16)
	[datetime]$GLOBALFridayInstallTime=$FridayDeplDay.AddHours(20)
	
	#Get Pre-Production Availability and Deadline times
	$PREDeplDay = $SecondTuesday.AddDays(2)
	[datetime]$GLOBALPREAvailTime=$PREDeplDay.AddHours(14)
	[datetime]$GLOBALPREInstallTime=$PREDeplDay.AddHours(20)
	#[datetime]$APACPREAvailTime=$PREDeplDay.AddHours(4)
	#[datetime]$APACPREInstallTime=$PREDeplDay.AddHours(16)

	#Get COMMON Production Availability and Deadline times
	$PRODeplDay = $SecondTuesday.AddDays(7)
	[datetime]$GLOBALPROAvailTime=$PRODeplDay.AddHours(16)
	[datetime]$GLOBALPROInstallTime=$PRODeplDay.AddHours(20)
	#[datetime]$APACPROAvailTime=$PRODeplDay.AddHours(4)
	#[datetime]$APACPROInstallTime=$PRODeplDay.AddHours(18)

	
	#Get Dates
	$CurrentMonthName = (Get-Culture).DateTimeFormat.GetMonthName(8).ToUpper()
	$CurrentMonthNumber = (Get-Date).Month
	$MonthCode = "M" + $CurrentMonthNumber
	$CurrentYear = (Get-Date).Year
	$CurrentMonthDigits = $CurrentMonthNumber.ToString().length
	$CurrentMonthCodeLength = $CurrentMonthDigits + 1
	$CurrentDate = Get-Date

# ***** END DATE PROCESSING SECTION *****

#<#

#*** START ADR RULES REVIEW ***

	$ADR_PSO= New-Object -TypeName PSobject
	$ADR_SUG= New-Object -TypeName PSobject
	
	#$Areas = @("GLOBAL", "EMEA", "DE", "APAC")

	#New Model, only ADRs in CAS Site
	$Areas = @("GLOBAL")

	foreach ($Area in $Areas) {
		Write-Host "Start $($Area) ADR Review:" -ForegroundColor Yellow
		Write-Host ""
		#Start Windows 7 ADR Rules
		$Win7ADRName= "ADR_" + $Area + "_SUP_Windows_7"
		Write-Host "Getting Windows 7 ADR Rule: $($Win7ADRName)" -ForegroundColor DarkGray  
		$Win7ADR = Get-CMSoftwareUpdateAutoDeploymentRule $Win7ADRName -Fast
		
		If ($Win7ADR) {
			Write-Host "Rule Name: $($Win7ADR.Name)" 
			Write-Host "LastRunTime: $($Win7ADR.LastRunTime)"
			Write-Host "LastErrorCode: $($Win7ADR.LastErrorCode)"  -ForegroundColor Red
			Write-Host "LastErrorTime: $($Win7ADR.LastErrorTime)"
			Write-Host ""
			#Export Info to PSO
			$ADR_PSO| Add-Member -Name Win7RuleName -value $Win7ADR.Name -MemberType NoteProperty
			$ADR_PSO| Add-Member -Name Win7LastRunTime -value $Win7ADR.LastRunTime -MemberType NoteProperty
			$ADR_PSO| Add-Member -Name Win7LastErrorCode -value $Win7ADR.LastErrorCode -MemberType NoteProperty
			$ADR_PSO| Add-Member -Name Win7LastErrorTime -value $Win7ADR.LastErrorTime -MemberType NoteProperty
		}


		#Start Windows 10 ADR Rules
		$Win10ADRName= "ADR_" + $Area + "_SUP_Windows_10"
		Write-Host "Getting Windows 10 ADR Rule: $($Win10ADRName)" -ForegroundColor DarkGray
		$Win10ADR = Get-CMSoftwareUpdateAutoDeploymentRule $Win10ADRName -Fast
		If ($Win10ADR) {
			Write-Host "Rule Name: $($Win10ADR.Name)" 
			Write-Host "LastRunTime: $($Win10ADR.LastRunTime)"
			Write-Host "LastErrorCode: $($Win10ADR.LastErrorCode)"  -ForegroundColor Red
			Write-Host "LastErrorTime: $($Win10ADR.LastErrorTime)"
			Write-Host ""
			#Export Info to PSO
			$ADR_PSO| Add-Member -Name Win10RuleName -value $Win10ADR.Name -MemberType NoteProperty
			$ADR_PSO| Add-Member -Name Win10LastRunTime -value $Win10ADR.LastRunTime -MemberType NoteProperty
			$ADR_PSO| Add-Member -Name Win10LastErrorCode -value $Win10ADR.LastErrorCode -MemberType NoteProperty
			$ADR_PSO| Add-Member -Name Win10LastErrorTime -value $Win10ADR.LastErrorTime -MemberType NoteProperty
		}
		
		#Start Office Legacy ADR Rules
		$OffLegacyADRName= "ADR_" + $Area + "_SUP_Office_Legacy" 
		Write-Host "Getting Office Legacy ADR Rule: $($OffLegacyADRName)" -ForegroundColor DarkGray
		$OffLegacyADR = Get-CMSoftwareUpdateAutoDeploymentRule $OffLegacyADRName -Fast
		If ($OffLegacyADR) {
			Write-Host "Rule Name: $($OffLegacyADR.Name)" 
			Write-Host "LastRunTime: $($OffLegacyADR.LastRunTime)"
			Write-Host "LastErrorCode: $($OffLegacyADR.LastErrorCode)"  -ForegroundColor Red
			Write-Host "LastErrorTime: $($OffLegacyADR.LastErrorTime)"
			Write-Host ""
			#Export Info to PSO
			$ADR_PSO| Add-Member -Name OffLegacyRuleName -value $OffLegacyADR.Name -MemberType NoteProperty
			$ADR_PSO| Add-Member -Name OffLegacyLastRunTime -value $OffLegacyADR.LastRunTime -MemberType NoteProperty
			$ADR_PSO| Add-Member -Name OffLegacyLastErrorCode -value $OffLegacyADR.LastErrorCode -MemberType NoteProperty
			$ADR_PSO| Add-Member -Name OffLegacyLastErrorTime -value $OffLegacyADR.LastErrorTime -MemberType NoteProperty	
			
		}
	
		#Start Office 365 Semi-Annual ADR Rules
		$Off365ADRName= "ADR_" + $Area + "_SUP_Office_365_Semi-Annual" 
		Write-Host "Getting Office 365 Semi-Annual ADR Rule: $($Off365ADRName)" -ForegroundColor DarkGray
		$Off365ADR = Get-CMSoftwareUpdateAutoDeploymentRule $Off365ADRName -Fast
		If ($Off365ADR) {
			Write-Host "Rule Name: $($Off365ADR.Name)" 
			Write-Host "LastRunTime: $($Off365ADR.LastRunTime)"
			Write-Host "LastErrorCode: $($Off365ADR.LastErrorCode)" -ForegroundColor Red
			Write-Host "LastErrorTime: $($Off365ADR.LastErrorTime)"
			Write-Host ""
		}
	
	#Start Office 365 Monthly-Enterprise ADR Rules
		$Off365MADRName= "ADR_" + $Area + "_SUP_Office_365_Monthly-Enterprise" 
		Write-Host "Getting Office 365 Monthly-Enterprise ADR Rule: $($Off365ADRName)" -ForegroundColor DarkGray
		$Off365ADR = Get-CMSoftwareUpdateAutoDeploymentRule $Off365MADRName -Fast
		If ($Off365ADR) {
			Write-Host "Rule Name: $($Off365MADR.Name)" 
			Write-Host "LastRunTime: $($Off365MADR.LastRunTime)"
			Write-Host "LastErrorCode: $($Off365MADR.LastErrorCode)" -ForegroundColor Red
			Write-Host "LastErrorTime: $($Off365MADR.LastErrorTime)"
			Write-Host ""
		}
		
	}



#*** END ADR RULES REVIEW ***


#*** START SOFTWARE UPDATE GROUPS CONFIGURATION ***
Write-Host ""
Write-Host ""
Write-Host "Start SOFTWARE UPDATE GROUPS Review and Configuration" -ForegroundColor Yellow
Write-Host ""
$Prods = @("*Windows_10*", "*Windows_7*", "*Office_Legacy*", "*Office_365_Semi_Annual*", "*Office_365_Monthly_Enterprise*")
foreach ($Prod in $Prods) {
	
	Write-Host ""
	Write-Host "Get $($Prod) Software Update Groups"
	<#
	#Retrieve all SUGs in hierarchy
	foreach ($ActiveSUG in Get-CMSoftwareUpdateGroup | Where {
	$_.CreatedBy -eq "AutoUpdateRuleEngine" -and $_.LocalizedDisplayName -like $Prod -and ($_.DateCreated).AddDays(14) -gt $CurrentDate} ) 
	#>
	
	#Retrieve only GLOBAL SUGs
	foreach ($ActiveSUG in Get-CMSoftwareUpdateGroup | Where {
	$_.CreatedBy -eq "AutoUpdateRuleEngine" -and $_.LocalizedDisplayName -like "ADR_GLOBAL_SUP_$Prod" -and ($_.DateCreated).AddDays(7) -gt $CurrentDate} ) 

	{
		$CurrentSUGName = $ActiveSUG.LocalizedDisplayName
		Write-Host "Current SUG Name is $($CurrentSUGName). Created on date $($ActiveSUG.DateCreated)"
		#Compare last 2-3 characteres to SUG month code
		$CurrentMonthCode=$CurrentSUGName.Substring($CurrentSUGName.Length -$CurrentMonthCodeLength)

		If (!($CurrentMonthCode -eq $MonthCode)) {
			$separator = "_"
			$str = $CurrentSUGName.SPlit($separator)
			$Separator2 = " "
			$Newstr = ($str[4]).SPlit($Separator2)
			$NewSUGName = $str[0] + $separator + $str[1] + $separator  + $str[2] + $separator  + $str[3] +$separator  + $Newstr[0] + $separator + $CurrentYear + $separator + $MonthCode 
			Write-Host "Renaming $CurrentSUGName to $($NewSUGName) "
			Write-Host ""
			$ActiveSUG | Set-CMSoftwareUpdateGroup -NewName $NewSUGName
			#rename SUG
		}
		Else {
		Write-Host "Current SUG Name has the proper name"
		Write-Host ""
		}
	}
}   
#*** END SOFTWARE UPDATE GROUPS CONFIGURATION ***



#*** START ACTIVE UPDATE DEPLOYMENTS CONFIGURATION ***
Write-Host ""
Write-Host ""
Write-Host "Start SOFTWARE UPDATE DEPLOYMENTS Review and Configuration" -ForegroundColor Yellow
Write-Host ""

#Retrieve all active deployments for the lasta 7 days
#foreach ($ActiveDeployment in Get-CMSoftwareUpdateDeployment | Where {($_.CreationTime).AddDays(7) -gt $CurrentDate} )

foreach ($ActiveDeployment in Get-CMSoftwareUpdateDeployment | Where {(($_.CreationTime).AddDays(7) -gt $CurrentDate)  -and ($_.AssignmentName -like "ADR_GLOBAL*")}  )
{

	switch ($ActiveDeployment.TargetCollectionID) {
	
		##### GLOBAL #####
		
		### Special Cases ###
		
		#NoForcedRestart"
		"PE1006D3" {

			$NewAssignmentName = "ADR_GLOBAL_SUP_NoForcedRestart" + $MonthCode 
			$DeplAvailTime = $GLOBALPREAvailTime       
			$DeplInstallTime = $GLOBALPREInstallTime
			}	
	

		### Windows 10 ###
		"CAS00111" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_10_2021_" + $MonthCode  + "_PRE"
			$DeplAvailTime = $GLOBALPREAvailTime        
			$DeplInstallTime = $GLOBALPREInstallTime
			}
		"CAS00118" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_10_2021_" + $MonthCode  + "_PRO_Mo"
			$DeplAvailTime = $GLOBALMondayAvailTime
			$DeplInstallTime = $GLOBALMondayInstallTime
			}
		"CAS0011A" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_10_2021_" + $MonthCode  + "_PRO_Tu"
			$DeplAvailTime = $GLOBALTuesdayAvailTime
			$DeplInstallTime = $GLOBALTuesdayInstallTime
			}
		"CAS0011F" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_10_2021_" + $MonthCode  + "_PRO_We"
			$DeplAvailTime = $GLOBALWednesdayAvailTime        
			$DeplInstallTime = $GLOBALWednesdayInstallTime
			}
		"CAS00116" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_10_2021_" + $MonthCode  + "_PRO_Th"
			$DeplAvailTime = $GLOBALThursdayAvailTime        
			$DeplInstallTime = $GLOBALThursdayInstallTime
			}
		"CAS0011E" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_10_2021_" + $MonthCode  + "_PRO_Fr"
			$DeplAvailTime = $GLOBALFridayAvailTime       
			$DeplInstallTime = $GLOBALFridayInstallTime
			}
	
		"SMSOOOUS" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_10_2021_" + $MonthCode  + "_TS"
			$DeplAvailTime = $GLOBALPREAvailTime       
			$DeplInstallTime = $GLOBALPREInstallTime
			}	
	

		### Windows 7 ###	
		"CAS00112" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_7_2021_" + $MonthCode  + "_PRE"
			$DeplAvailTime = $GLOBALPREAvailTime        
			$DeplInstallTime = $GLOBALPREInstallTime
			}
		"CAS00119" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_7_2021_" + $MonthCode  + "_PRO_Mo"
			$DeplAvailTime = $GLOBALMondayAvailTime
			$DeplInstallTime = $GLOBALMondayInstallTime
			}
		"CAS0011B" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_7_2021_" + $MonthCode  + "_PRO_Tu"
			$DeplAvailTime = $GLOBALTuesdayAvailTime
			$DeplInstallTime = $GLOBALTuesdayInstallTime
			}
		"CAS0011C" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_7_2021_" + $MonthCode  + "_PRO_We"
			$DeplAvailTime = $GLOBALWednesdayAvailTime        
			$DeplInstallTime = $GLOBALWednesdayInstallTime
			}
		"CAS00117" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_7_2021_" + $MonthCode  + "_PRO_Th"
			$DeplAvailTime = $GLOBALThursdayAvailTime        
			$DeplInstallTime = $GLOBALThursdayInstallTime
			}
		"CAS0011D" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Windows_7_2021_" + $MonthCode  + "_PRO_Fr"
			$DeplAvailTime = $GLOBALFridayAvailTime       
			$DeplInstallTime = $GLOBALFridayInstallTime
			}
	
		##### Office Legacy #####

		"CAS00133" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_Legacy_2021_" + $MonthCode  + "_PRE"
			$DeplAvailTime = $GLOBALPREAvailTime        
			$DeplInstallTime = $GLOBALPREInstallTime
			}
		"CAS0012A" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_Legacy_2021_" + $MonthCode  + "_PRO_Mo"
			$DeplAvailTime = $GLOBALMondayAvailTime
			$DeplInstallTime = $GLOBALMondayInstallTime
			}
		"CAS00129" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_Legacy_2021_" + $MonthCode  + "_PRO_Tu"
			$DeplAvailTime = $GLOBALTuesdayAvailTime
			$DeplInstallTime = $GLOBALTuesdayInstallTime
			}
		"CAS00127" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_Legacy_2021_" + $MonthCode  + "_PRO_We"
			$DeplAvailTime = $GLOBALWednesdayAvailTime        
			$DeplInstallTime = $GLOBALWednesdayInstallTime
			}
		"CAS0012B" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_Legacy_2021_" + $MonthCode  + "_PRO_Th"
			$DeplAvailTime = $GLOBALThursdayAvailTime        
			$DeplInstallTime = $GLOBALThursdayInstallTime
			}
		"CAS00128" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_Legacy_2021_" + $MonthCode  + "_PRO_Fr"
			$DeplAvailTime = $GLOBALFridayAvailTime       
			$DeplInstallTime = $GLOBALFridayInstallTime
			}

		##### Office 365 Semi-Annual #####

		"CAS00134" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Semi-Annual_2021_" + $MonthCode  + "_PRE"
			$DeplAvailTime = $GLOBALPREAvailTime        
			$DeplInstallTime = $GLOBALPREInstallTime
			}
		"CAS00126" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Semi-Annual_2021_" + $MonthCode  + "_PRO_Mo"
			$DeplAvailTime = $GLOBALMondayAvailTime
			$DeplInstallTime = $GLOBALMondayInstallTime
			}
		"CAS00122" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Semi-Annual_2021_" + $MonthCode  + "_PRO_Tu"
			$DeplAvailTime = $GLOBALTuesdayAvailTime
			$DeplInstallTime = $GLOBALTuesdayInstallTime
			}
		"CAS00124" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Semi-Annual_2021_" + $MonthCode  + "_PRO_We"
			$DeplAvailTime = $GLOBALWednesdayAvailTime        
			$DeplInstallTime = $GLOBALWednesdayInstallTime
			}
		"CAS00125" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Semi-Annual_2021_" + $MonthCode  + "_PRO_Th"
			$DeplAvailTime = $GLOBALThursdayAvailTime        
			$DeplInstallTime = $GLOBALThursdayInstallTime
			}
		"CAS00123" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Semi-Annual_2021_" + $MonthCode  + "_PRO_Fr"
			$DeplAvailTime = $GLOBALFridayAvailTime       
			$DeplInstallTime = $GLOBALFridayInstallTime
			}		
	
		##### Office 365 Monthly-Enterprise #####

		"CAS00134" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Monthly-Enterprise_2021_" + $MonthCode  + "_PRE"
			$DeplAvailTime = $GLOBALPREAvailTime        
			$DeplInstallTime = $GLOBALPREInstallTime
			}
		"CAS005ED" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Monthly-Enterprise_2021_" + $MonthCode  + "_PRO_Mo"
			$DeplAvailTime = $GLOBALMondayAvailTime
			$DeplInstallTime = $GLOBALMondayInstallTime
			}
		"CAS005EF" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Monthly-Enterprise_2021_" + $MonthCode  + "_PRO_Tu"
			$DeplAvailTime = $GLOBALTuesdayAvailTime
			$DeplInstallTime = $GLOBALTuesdayInstallTime
			}
		"CAS005F0" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Monthly-Enterprise_2021_" + $MonthCode  + "_PRO_We"
			$DeplAvailTime = $GLOBALWednesdayAvailTime        
			$DeplInstallTime = $GLOBALWednesdayInstallTime
			}
		"CAS005EE" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Monthly-Enterprise_2021_" + $MonthCode  + "_PRO_Th"
			$DeplAvailTime = $GLOBALThursdayAvailTime        
			$DeplInstallTime = $GLOBALThursdayInstallTime
			}
		"CAS005EC" {
			$NewAssignmentName = "ADR_GLOBAL_SUP_Office_365_Monthly-Enterprise_2021_" + $MonthCode  + "_PRO_Fr"
			$DeplAvailTime = $GLOBALFridayAvailTime       
			$DeplInstallTime = $GLOBALFridayInstallTime
			}
				
	}
	
	
		Write-Host  ""
		Write-Host "Managing $($ActiveDeployment.AssignmentName) deployment" -Foregroundcolor Yellow
		Write-Host "Deployed to Collection ID: $($ActiveDeployment.TargetCollectionID)"
		
		Write-Host "Renaming $($ActiveDeployment.AssignmentName) to $($NewAssignmentName)"
		Write-Host "Creation Time is: $($ActiveDeployment.CreationTime)"
		Write-Host "Current Availability Time is: $($ActiveDeployment.StartTime)"
		Write-Host "NEW Availability date is $($DeplAvailTime)"  -Foregroundcolor Cyan
		Write-Host "Current Deadline Time is: $($ActiveDeployment.EnforcementDeadline)"
		Write-Host "NEW Deadline date is $($DeplInstallTime)"	-Foregroundcolor Cyan


		#Modify Deployment 
		###Set-CMSoftwareUpdateDeployment -DeploymentName $ActiveDeployment.AssignmentName -NewDeploymentName $NewAssignmentName -AvailableDateTime $DeplAvailTime -DeploymentExpireDateTime $DeplInstallTime
		$ActiveDeployment | Set-CMSoftwareUpdateDeployment -NewDeploymentName $NewAssignmentName -AvailableDateTime $DeplAvailTime -DeploymentExpireDateTime $DeplInstallTime
		

		
		

}
#*** END ACTIVE UPDATE DEPLOYMENTS CONFIGURATION ***

#REPORTING
	$ADR_PSO
	$ADR_Deployment

#Add Pause
Start-Sleep -Seconds 30

#Retrieve modified deployments

foreach ($ActiveDeployment in Get-CMSoftwareUpdateDeployment | Where {(($_.CreationTime).AddDays(15) -gt $CurrentDate)  -and ($_.AssignmentName -like "ADR_GLOBAL*")}  )
{

		$ADR_Deployment= New-Object -TypeName PSobject
		$ADR_Deployment| Add-Member -Name DeploymentName -value $ActiveDeployment.AssignmentName -MemberType NoteProperty
		$ADR_Deployment| Add-Member -Name DeploymentStartTime -value $ActiveDeployment.StartTime -MemberType NoteProperty
		$ADR_Deployment| Add-Member -Name DeploymentDeadline -value $ActiveDeployment.EnforcementDeadline -MemberType NoteProperty
		$ADR_Deployment| Add-Member -Name DeploymentTargetCollectionID -value $ActiveDeployment.TargetCollectionID -MemberType NoteProperty
		##$Array_ADR_Deployment+=$ADR_Deployment
		
		$OutFileName="c:\temp\kk.csv"
		##$Array_ADR_Deployment
		$ADR_Deployment
		###$Array_ADR_Deployment | Export-Csv -Append -Force -Path $OutFileName -NoTypeInformation 
		#>
}	
#*** START CHANGE MAX RUNTIME OF UPDATES ***

Get-CMSoftwareUpdate -Name "*Security Only Quality Update*" -Fast | Set-CMSoftwareUpdate -MaximumExecutionMins 60 –Verbose

Get-CMSoftwareUpdate -Name "* Security Monthly Quality Rollup*" -Fast | Set-CMSoftwareUpdate -MaximumExecutionMins 120 –Verbose