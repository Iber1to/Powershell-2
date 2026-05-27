<#
ReRunTaskSequence v1
-----------------
 
This script reruns a task sequence on a remote computer.
 
Tested on: SCCM2012R2
 
-Prereqs:-
> You need the PackageID of the Task Sequence which you can get from the SCCM Console

> You should have local admin rights on the computer to restart the ccmexec service
> Variables, enter the $ComputerName and $TSID (PackageID) variables
#>
 

$TSID = "CAS001CE"
Get-WmiObject -Namespace "root\ccm\scheduler" -Class ccm_scheduler_history | where {$_.ScheduleID -like "*$TSID*"} | ft ScheduleID # Outputs the Schedule ID
Get-WmiObject -Namespace "root\ccm\scheduler" -Class ccm_scheduler_history | where {$_.ScheduleID -like "*$TSID*"} | Remove-WmiObject # Deletes the Schedule
Get-WmiObject -Namespace "root\ccm\scheduler" -Class ccm_scheduler_history | where {$_.ScheduleID -like "*$TSID*"} | ft ScheduleID # No output confirms the deletion
Get-Service | where {$_.Name -eq "CCMExec"} | Restart-Service # Restart the SMS Agent Host service
