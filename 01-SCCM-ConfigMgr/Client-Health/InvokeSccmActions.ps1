function InvokeSccmActions
{
   param (
       # Specify Target
       [Parameter(Mandatory=$true)]
       [string]
       $Machine='localhost'
   )
    # Application Deployment Evaluation Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000044}"
    # Discovery Data Collection Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000008}"
    # File Collection Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000009}"
    # Hardware Inventory Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000001}"
    # Machine Policy Retrieval Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000012}"
    # Machine Policy Evaluation Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000006}"
    # Software Inventory Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000007}"
    # Software Metering Usage Report Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000018}"
    # Software Update Deployment Evaluation Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000040}"
    # Software Update Scan Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000005}"
    # State Message Refresh
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000004}"
    # User Policy Retrieval Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000016}"
    # User Policy Evaluation Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000017}"
    # Windows Installers Source List Update Cycle
    Invoke-WMIMethod -ComputerName $Server -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{11111111-1111-1111-1111-000000000003}"
}
InvokeSccmActions