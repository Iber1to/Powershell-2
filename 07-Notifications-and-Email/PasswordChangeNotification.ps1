<#
.Synopsis
   Script to Automated Email Reminders when Users Passwords due to Expire.
.DESCRIPTION
   Script to Automated Email Reminders when Users Passwords due to Expire.
   Robert Pearman / WindowsServerEssentials.com
   Version 2.9 August 2018
   Requires: Windows PowerShell Module for Active Directory
   For assistance and ideas, visit the TechNet Gallery Q&A Page. http://gallery.technet.microsoft.com/Password-Expiry-Email-177c3e27/view/Discussions#content

   Alternativley visit my youtube channel, https://www.youtube.com/robtitlerequired

   Videos are available to cover most questions, some videos are based on the earlier version which used static variables, however most of the code
   can still be applied to this version, for example for targeting groups, or email design.

   Please take a look at the existing Q&A as many questions are simply repeating earlier ones, with the same answers!


.EXAMPLE
  PasswordChangeNotification.ps1 -smtpServer mail.domain.com -expireInDays 21 -from "IT Support <user@example.com>" -Logging -LogPath "c:\logFiles" -testing -testRecipient user@example.com
  
  This example will use mail.domain.com as an smtp server, notify users whose password expires in less than 21 days, send mail from user@example.com
  Logging is enabled, log path is c:\logfiles
  Testing is enabled, and test recipient is user@example.com

.EXAMPLE
  PasswordChangeNotification.ps1 -smtpServer mail.domain.com -expireInDays 21 -from "IT Support <user@example.com>" -reportTo user@example.com -interval 1,2,5,10,15
  
  This example will use mail.domain.com as an smtp server, notify users whose password expires in less than 21 days, send mail from user@example.com
  Report is enabled, reports sent to user@example.com
  Interval is used, and emails will be sent to people whose password expires in less than 21 days if the script is run, with 15, 10, 5, 2 or 1 days remaining untill password expires.

#>
param(
    # $smtpServer Enter Your SMTP Server Hostname or IP Address
    [Parameter(Position=0)]
    [ValidateNotNull()]
    [string]$smtpServer,
    # Notify Users if Expiry Less than X Days
    [Parameter(Position=1)]
    [ValidateNotNull()]
    [int]$expireInDays,
    # From Address, eg "IT Support <user@example.com>"
    [Parameter(Position=2)]
    [ValidateNotNull()]
    [string]$from,
    [Parameter(Position=3)]
    [switch]$logging,
    # Log File Path
    [Parameter(Position=4)]
    [string]$logPath,
    # Testing Enabled
    [Parameter(Position=5)]
    [switch]$testing,
    # Test Recipient, eg user@example.com
    [Parameter(Position=6)]
    [string]$testRecipient,
    # Output more detailed status to console
    [Parameter(Position=7)]
    [switch]$status,
    # Log file recipient
    [Parameter(Position=8)]
    [string]$reportto,
    # Notification Interval
    [Parameter(Position=9)]
    [array]$interval
)
###################################################################################################################
# Time / Date Info
$start = [datetime]::Now
$midnight = $start.Date.AddDays(1)
$timeToMidnight = New-TimeSpan -Start $start -end $midnight.Date
$midnight2 = $start.Date.AddDays(2)
$timeToMidnight2 = New-TimeSpan -Start $start -end $midnight2.Date
# System Settings
$textEncoding = [System.Text.Encoding]::UTF8
$today = $start
# End System Settings

############################################################  New Params credentials ############################################################
#Specify user credentials.
$SMTPServer = "smtp.office365.com"
$SMTPPort = 587
$mailFrom = "automation@contoso.com"
$password = "REDACTED_PASSWORD"
$securePwd = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($mailFrom, $securePwd)
$From = $mailFrom
############################################################End new params #######################################################################

# Load AD Module
try{
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch{
    Write-Warning "Unable to load Active Directory PowerShell Module"
}
# Set Output Formatting - Padding characters
$padVal = "20"
Write-Output "Script Loaded"
Write-Output "*** Settings Summary ***"
$smtpServerLabel = "SMTP Server".PadRight($padVal," ")
$expireInDaysLabel = "Expire in Days".PadRight($padVal," ")
$fromLabel = "From".PadRight($padVal," ")
$testLabel = "Testing".PadRight($padVal," ")
$testRecipientLabel = "Test Recipient".PadRight($padVal," ")
$logLabel = "Logging".PadRight($padVal," ")
$logPathLabel = "Log Path".PadRight($padVal," ")
$reportToLabel = "Report Recipient".PadRight($padVal," ")
$interValLabel = "Intervals".PadRight($padval," ")
# Testing Values
if($testing)
{
    if($null -eq ($testRecipient))
    {
        Write-Output "No Test Recipient Specified"
        Exit
    }
}
# Logging Values
if($logging)
{
    if($null -eq ($logPath))
    {
        $logPath = $PSScriptRoot
    }
}
# Output Summary Information
Write-Output "$smtpServerLabel : $smtpServer"
Write-Output "$expireInDaysLabel : $expireInDays"
Write-Output "$fromLabel : $from"
Write-Output "$logLabel : $logging"
Write-Output "$logPathLabel : $logPath"
Write-Output "$testLabel : $testing"
Write-Output "$testRecipientLabel : $testRecipient"
Write-Output "$reportToLabel : $reportto"
Write-Output "$interValLabel : $interval"
Write-Output "*".PadRight(25,"*")
# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired
# To target a specific OU - use the -searchBase Parameter -https://docs.microsoft.com/en-us/powershell/module/addsadministration/get-aduser
# You can target specific group members using Get-AdGroupMember, explained here https://www.youtube.com/watch?v=4CX9qMcECVQ 
# based on earlier version but method still works here.
$users = get-aduser -filter {(Enabled -eq $true) -and (PasswordNeverExpires -eq $false)} -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress | Where-Object { $_.passwordexpired -eq $false }
# Count Users
$usersCount = ($users | Measure-Object).Count
Write-Output "Found $usersCount User Objects"
# Collect Domain Password Policy Information
$defaultMaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop).MaxPasswordAge.Days 
Write-Output "Domain Default Password Age: $defaultMaxPasswordAge"
# Collect Users
$colUsers = @()
# Process Each User for Password Expiry
Write-Output "Process User Objects"
foreach ($user in $users)
{
    # Store User information
    $Name = $user.GivenName
    $emailaddress = $user.emailaddress
    #$passwordSetDate = $user.PasswordLastSet
    $samAccountName = $user.SamAccountName
    $pwdLastSet = $user.PasswordLastSet
    # Check for Fine Grained Password
    $maxPasswordAge = $defaultMaxPasswordAge
    $PasswordPol = (Get-AduserResultantPasswordPolicy $user) 
    if ($null -ne ($PasswordPol))
    {
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge.Days
    }
    # Create User Object
    $userObj = New-Object System.Object
    $expireson = $pwdLastSet.AddDays($maxPasswordAge)
    $daysToExpire = New-TimeSpan -Start $today -End $Expireson
    # Round Expiry Date Up or Down
    if(($daysToExpire.Days -eq "0") -and ($daysToExpire.TotalHours -le $timeToMidnight.TotalHours))
    {
        $userObj | Add-Member -Type NoteProperty -Name UserMessage -Value "hoy."
    }
    if(($daysToExpire.Days -eq "0") -and ($daysToExpire.TotalHours -gt $timeToMidnight.TotalHours) -or ($daysToExpire.Days -eq "1") -and ($daysToExpire.TotalHours -le $timeToMidnight2.TotalHours))
    {
        $userObj | Add-Member -Type NoteProperty -Name UserMessage -Value "mañana."
    }
    if(($daysToExpire.Days -ge "1") -and ($daysToExpire.TotalHours -gt $timeToMidnight2.TotalHours))
    {
        $days = $daysToExpire.TotalDays
        $days = [math]::Round($days)
        $userObj | Add-Member -Type NoteProperty -Name UserMessage -Value "en $days días."
    }
    $daysToExpire = [math]::Round($daysToExpire.TotalDays)
    $userObj | Add-Member -Type NoteProperty -Name UserName -Value $samAccountName
    $userObj | Add-Member -Type NoteProperty -Name Name -Value $Name
    $userObj | Add-Member -Type NoteProperty -Name EmailAddress -Value $emailAddress
    $userObj | Add-Member -Type NoteProperty -Name PasswordSet -Value $pwdLastSet
    $userObj | Add-Member -Type NoteProperty -Name DaysToExpire -Value $daysToExpire
    $userObj | Add-Member -Type NoteProperty -Name ExpiresOn -Value $expiresOn
    # Add userObj to colusers array
    $colUsers += $userObj
}
# Count Users
$colUsersCount = ($colUsers | Measure-Object).Count
Write-Output "$colusersCount Users processed"
# Select Users to Notify
$notifyUsers = $colUsers | Where-Object { $_.DaysToExpire -le $expireInDays}
$notifiedUsers = @()
$notifyCount = ($notifyUsers | Measure-Object).Count
Write-Output "$notifyCount Users with expiring passwords within $expireInDays Days"
# Process notifyusers
foreach ($user in $notifyUsers)
{
    # Email Address
    $samAccountName = $user.UserName
    $emailAddress = $user.EmailAddress
    # Set Greeting Message
    $name = $user.Name
    $messageDays = $user.UserMessage
    # Subject Setting
    $subject="Tú contraseña expira: $messageDays"
    # Email Body Set Here, Note You can use HTML, including Images.
    # examples here https://youtu.be/iwvQ5tPqgW0 
    $body ="<div lang='ES' link='#0563C1' vlink='#954F72' style='word-wrap:break-word'><div class='x_WordSection1'><p class='x_MsoNormal'><span style='font-family: Arial, sans-serif, serif, EmojiFont;'>&nbsp;</span></p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify'>ID ClientFuneral: <b><i>$samAccountName </i></b></p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify' aria-hidden='true'>&nbsp;</p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify'>Estimado usuario, <span style='color:red'>$name</span></p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify' aria-hidden='true'>&nbsp;</p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify'>El sistema automático de verificación de la caducidad de la contraseña ha detectado que su contraseña en el dominio de <b>ClientFuneral</b> expira: <b><i>$messageDays</i></b> Siguiendo la política definida, en el caso de que no se realice el cambio de contraseña antes del periodo de expiración, su cuenta <b><i>$samAccountName  </i></b>será bloqueada.</p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify'>Recomendamos el cambio de la contraseña lo antes posible.</p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify' aria-hidden='true'>&nbsp;</p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify'>Si tiene alguna cuestión sobre como cambiar la contraseña, por favor revise la siguiente información: <b><i><a href='https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2FClientFuneral.sharepoint.com%2FDocumentos%2520compartidos%2FForms%2FAllItems.aspx%3Fid%3D%252FDocumentos%2520compartidos%252FP%25C3%25ADldoras%2520informativas%252FPIL_13_Cambio%2520contrase%25C3%25B1a%2520Windows%252010.pdf%26parent%3D%252FDocumentos%2520compartidos%252FP%25C3%25ADldoras%2520informativas&amp;data=user%40contoso.com%7Cd5f3773951164fcff0c308dbbf28c12c%7C14cb4ab462b845a2a944e225383ee1f9%7C0%7C0%7C638313954369976199%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&amp;sdata=hzXEag6%2FfU3r%2FE9dvbwGtu7JW2IR%2F2L%2FcZmpPOHm6uA%3D&amp;reserved=0' target='_blank' rel='noopener noreferrer' data-auth='Verified' originalsrc='https://ClientFuneral.sharepoint.com/Documentos%20compartidos/Forms/AllItems.aspx?id=%2FDocumentos%20compartidos%2FP%C3%ADldoras%20informativas%2FPIL_13_Cambio%20contrase%C3%B1a%20Windows%2010.pdf&amp;parent=%2FDocumentos%20compartidos%2FP%C3%ADldoras%20informativas' shash='qAO44/N024XSCZjCaCFO5zHeCsTL5VkWLCjm/XS691RHRZmX4QJKddIwDwqAPcshze/i0AC/p5O9GRtDtEybu0BYaMXKKg0TKgCdmmojIoROivyJ9xXlij0zlDpD4tVsPJe5GcuDPZWsVhexzWknZYoboobG+pW0WWV32oSY+j4=' title='Dirección URL original: https://ClientFuneral.sharepoint.com/Documentos%20compartidos/Forms/AllItems.aspx?id=%2FDocumentos%20compartidos%2FP%C3%ADldoras%20informativas%2FPIL_13_Cambio%20contrase%C3%B1a%20Windows%2010.pdf&amp;parent=%2FDocumentos%20compartidos%2FP%C3%ADldoras%20informativas. Haga clic o pulse si confía en este vínculo.' data-linkindex='0'><span class='x_MsoSmartlink'><span style=''><img data-imagetype='AttachmentByCid' originalsrc='cid:image014.png@01D9F11D.F4025740' data-custom='AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAJZci0bBjTBDms46YurE8GQ%3D' naturalheight='0' naturalwidth='0' src='https://attachments.office.net/owa/user%40contoso.com/service.svc/s/GetAttachmentThumbnail?id=AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAJZci0bBjTBDms46YurE8GQ%3D&amp;thumbnailType=2&amp;token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjczRkI5QkJFRjYzNjc4RDRGN0U4NEI0NDBCQUJCMTJBMzM5RDlGOTgiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJjX3VidnZZMmVOVDM2RXRFQzZ1eEtqT2RuNWcifQ.eyJvcmlnaW4iOiJodHRwczovL291dGxvb2sub2ZmaWNlLmNvbSIsInVjIjoiNmNmZDg2ZGM0N2ZmNGI1NzljYTlkMWY2NmJhOTIxYmYiLCJzaWduaW5fc3RhdGUiOiJbXCJkdmNfbW5nZFwiLFwia21zaVwiXSIsInZlciI6IkV4Y2hhbmdlLkNhbGxiYWNrLlYxIiwiYXBwY3R4c2VuZGVyIjoiT3dhRG93bmxvYWRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaXNzcmluZyI6IldXIiwiYXBwY3R4Ijoie1wibXNleGNocHJvdFwiOlwib3dhXCIsXCJwdWlkXCI6XCIxMTUzODAxMTIzNjgzNDA4NDA5XCIsXCJzY29wZVwiOlwiT3dhRG93bmxvYWRcIixcIm9pZFwiOlwiNTY5MTE5ZmYtNmRkZS00ZmMyLTg4ZDYtN2FjY2M1ZjVjZWUyXCIsXCJwcmltYXJ5c2lkXCI6XCJTLTEtNS0yMS0xMzIyNjM4MzQ2LTIzMzcwMzEwNDAtMTgwNTIwMjk1NC0yOTAxMjE0MVwifSIsIm5iZiI6MTY5NzYyNTUwMSwiZXhwIjoxNjk3NjI2MTAxLCJpc3MiOiIwMDAwMDAwMi0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDBAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiYXVkIjoiMDAwMDAwMDItMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwL2F0dGFjaG1lbnRzLm9mZmljZS5uZXRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaGFwcCI6Im93YSJ9.K908J0JYAjyduFb88h3EuXdg5p1wk8WjfSJ2zz67BV3aHXl-EbJS-YMG2AFXWMX7dj4RzJxhJt77CN-Ium5HNsXaWNTqBE7iuA39TRRLBpfx2Tip2YgJijhStlCAQmmytpuSZ6uoMNtQNnMPKR2ASpba60EoMZZ0XTtgwOhcbdVE7LzPO-SRBkEALUS18dNPLeYTNeaBn1W5jXKsf_6ns-Cv3E2mWBGSG5AvuH9Ub1I1oxzeu9qC1JHYeRMPEv9jgWpr9GG9bvfSRGFGCwa7mTG2m9QU_ImmaqfNZnpfMBEZKE15-ivkN-EV_Ktlrea2a-HddYRYbeNbW1yndxh4lw&amp;X-OWA-CANARY=jAJJTrYapUuIB3dq9aR2CKB6oYvGz9sY0_JfcXrhCnErqT8TgeeYhtJQLPcb-7pq4HqDDkbDdoA.&amp;owa=outlook.office.com&amp;scriptVer=20231006004.18&amp;animation=true' border='0' width='16' height='16' id='x_Imagen_x0020_21' alt='​icono de pdf' style='width: 0.1666in; height: 0.1666in; min-height: auto; min-width: auto;' crossorigin='use-credentials' fetchpriority='high' class='Do8Zj'></span>&nbsp;PIL_13_Cambio contraseña</span></a></i></b></p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify' aria-hidden='true'>&nbsp;</p><p class='x_MsoNormal' style='text-align:justify' aria-hidden='true'>&nbsp;</p><p class='x_MsoNormal' style='margin-left:35.4pt; text-align:justify'>Recibe un cordial saludo</p><p class='x_MsoNormal' style='text-indent:35.4pt; background:white'><span style='font-family: &quot;Century Gothic&quot;, sans-serif, serif, EmojiFont; color: rgb(36, 36, 36);'>&nbsp;</span></p><p class='x_MsoNormal' style='background:white'><span style=''>&nbsp;</span></p><p class='x_MsoNormal' style='text-indent:35.4pt; background:white'><span style='font-family: &quot;Century Gothic&quot;, sans-serif, serif, EmojiFont; color: rgb(36, 36, 36);'>Área de TI y Procesos</span><span style=''></span></p><p class='x_MsoNormal' style='text-indent:35.4pt; background:white'><span style='font-family: &quot;Century Gothic&quot;, sans-serif, serif, EmojiFont; color: rgb(36, 36, 36);'>ClientFuneral</span><span style=''></span></p><p class='x_MsoNormal' style='text-indent:35.4pt; background:white'><span style='font-family: &quot;Century Gothic&quot;, sans-serif, serif, EmojiFont; color: rgb(36, 36, 36);'>Calle Doctor Esquerdo, 138, 5ª</span><span style=''></span></p><p class='x_MsoNormal' style='text-indent:35.4pt; background:white'><span style='font-family: &quot;Century Gothic&quot;, sans-serif, serif, EmojiFont; color: rgb(36, 36, 36);'>28007 Madrid</span><span style=''></span></p><p class='x_MsoNormal' style='text-indent:35.4pt; background:white'><span style='font-family: &quot;Century Gothic&quot;, sans-serif, serif, EmojiFont; color: rgb(36, 36, 36);'>Teléfono: 91 700 30 20</span><span style=''></span></p><p class='x_MsoNormal' style='text-indent:35.4pt; background:white'><span style='font-family: &quot;Century Gothic&quot;, sans-serif, serif, EmojiFont; color: black;'><a href='https://eur01.safelinks.protection.outlook.com/?url=http%3A%2F%2Fwww.ClientFuneral.es%2F&amp;data=user%40contoso.com%7Cd5f3773951164fcff0c308dbbf28c12c%7C14cb4ab462b845a2a944e225383ee1f9%7C0%7C0%7C638313954369976199%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&amp;sdata=7CuAn35S3Clcyk2oNBhGq0AGkrlMXEVBAyip3USAf5U%3D&amp;reserved=0' target='_blank' rel='noopener noreferrer' data-auth='Verified' originalsrc='http://www.ClientFuneral.es/' shash='WQ4biN69KaNl8AxEv6JWC/lQ3yUgaOVUl5686wXNtJobtcsRucPZXgdZ43erT1E8QcnOgqPczDEBhJ305GpvgTJVzW6OdZnxkz/A6PdpteDM2LYfaahZRsebf33yGlprL1hHXs7YnltGynU/qor+UbTYIW0zrpLO6JWLGyIMlMQ=' title='Dirección URL original: http://www.ClientFuneral.es/. Haga clic o pulse si confía en este vínculo.' data-linkindex='1'>www.ClientFuneral.es</a></span><span style=''></span></p><p class='x_MsoNormal' style='background:white'><span style='font-family: &quot;Century Gothic&quot;, sans-serif, serif, EmojiFont; color: rgb(36, 36, 36);'>&nbsp;</span><span style=''></span></p><p class='x_MsoNormal' style='text-indent:35.4pt; background:white'><span style='color:black'><a href='https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fwww.facebook.com%2FClientFuneral&amp;data=user%40contoso.com%7Cd5f3773951164fcff0c308dbbf28c12c%7C14cb4ab462b845a2a944e225383ee1f9%7C0%7C0%7C638313954369976199%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&amp;sdata=XQ3W%2F8g4FhIHacVvnqKzzA8H%2Ffs3gJ0%2FtBDaaQyMwNs%3D&amp;reserved=0' target='_blank' rel='noopener noreferrer' data-auth='Verified' originalsrc='https://www.facebook.com/ClientFuneral' shash='laLhuR7oJmc3yd3dq7Vi9hpfJNT/20mZTmottRQCfX0sUV2g2Zvdikvt0ZygbcoDHRxim5wNkCOiYVKBOBvr/0TLMQ8SnruX6FSibKjSVERRSz/dUstnW4Po/D2zbVW8RGZo2FIMukewKI5yY9/dkpMebNai0jJOOXokJEWb4TU=' title='Dirección URL original: https://www.facebook.com/ClientFuneral. Haga clic o pulse si confía en este vínculo.' data-linkindex='2'><span style='color:black; text-decoration:none'><img data-imagetype='AttachmentByCid' originalsrc='cid:image008.png@01D9F11D.972043C0' data-custom='AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAAYsPexRoQZEp02CGhtD%2B5E%3D' naturalheight='0' naturalwidth='0' src='https://attachments.office.net/owa/user%40contoso.com/service.svc/s/GetAttachmentThumbnail?id=AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAAYsPexRoQZEp02CGhtD%2B5E%3D&amp;thumbnailType=2&amp;token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjczRkI5QkJFRjYzNjc4RDRGN0U4NEI0NDBCQUJCMTJBMzM5RDlGOTgiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJjX3VidnZZMmVOVDM2RXRFQzZ1eEtqT2RuNWcifQ.eyJvcmlnaW4iOiJodHRwczovL291dGxvb2sub2ZmaWNlLmNvbSIsInVjIjoiNmNmZDg2ZGM0N2ZmNGI1NzljYTlkMWY2NmJhOTIxYmYiLCJzaWduaW5fc3RhdGUiOiJbXCJkdmNfbW5nZFwiLFwia21zaVwiXSIsInZlciI6IkV4Y2hhbmdlLkNhbGxiYWNrLlYxIiwiYXBwY3R4c2VuZGVyIjoiT3dhRG93bmxvYWRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaXNzcmluZyI6IldXIiwiYXBwY3R4Ijoie1wibXNleGNocHJvdFwiOlwib3dhXCIsXCJwdWlkXCI6XCIxMTUzODAxMTIzNjgzNDA4NDA5XCIsXCJzY29wZVwiOlwiT3dhRG93bmxvYWRcIixcIm9pZFwiOlwiNTY5MTE5ZmYtNmRkZS00ZmMyLTg4ZDYtN2FjY2M1ZjVjZWUyXCIsXCJwcmltYXJ5c2lkXCI6XCJTLTEtNS0yMS0xMzIyNjM4MzQ2LTIzMzcwMzEwNDAtMTgwNTIwMjk1NC0yOTAxMjE0MVwifSIsIm5iZiI6MTY5NzYyNTUwMSwiZXhwIjoxNjk3NjI2MTAxLCJpc3MiOiIwMDAwMDAwMi0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDBAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiYXVkIjoiMDAwMDAwMDItMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwL2F0dGFjaG1lbnRzLm9mZmljZS5uZXRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaGFwcCI6Im93YSJ9.K908J0JYAjyduFb88h3EuXdg5p1wk8WjfSJ2zz67BV3aHXl-EbJS-YMG2AFXWMX7dj4RzJxhJt77CN-Ium5HNsXaWNTqBE7iuA39TRRLBpfx2Tip2YgJijhStlCAQmmytpuSZ6uoMNtQNnMPKR2ASpba60EoMZZ0XTtgwOhcbdVE7LzPO-SRBkEALUS18dNPLeYTNeaBn1W5jXKsf_6ns-Cv3E2mWBGSG5AvuH9Ub1I1oxzeu9qC1JHYeRMPEv9jgWpr9GG9bvfSRGFGCwa7mTG2m9QU_ImmaqfNZnpfMBEZKE15-ivkN-EV_Ktlrea2a-HddYRYbeNbW1yndxh4lw&amp;X-OWA-CANARY=jAJJTrYapUuIB3dq9aR2CKB6oYvGz9sY0_JfcXrhCnErqT8TgeeYhtJQLPcb-7pq4HqDDkbDdoA.&amp;owa=outlook.office.com&amp;scriptVer=20231006004.18&amp;animation=true' border='0' width='19' height='19' id='x_Imagen_x0020_22' style='width: 0.2in; height: 0.2in; min-height: auto; min-width: auto;' crossorigin='use-credentials' fetchpriority='high' class='Do8Zj'></span></a></span><b><span style='font-size:9.0pt; color:#FF2F92'>&nbsp;&nbsp;&nbsp;</span></b><span style='color:black'><a href='https://eur01.safelinks.protection.outlook.com/?url=http%3A%2F%2Fwww.instagram.com%2FClientFuneral%2F&amp;data=user%40contoso.com%7Cd5f3773951164fcff0c308dbbf28c12c%7C14cb4ab462b845a2a944e225383ee1f9%7C0%7C0%7C638313954369976199%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&amp;sdata=dKhM1MJ4jVQj%2BoYU%2FjFgo0vOZqtXHda3eOahCIaQ5Po%3D&amp;reserved=0' target='_blank' rel='noopener noreferrer' data-auth='Verified' originalsrc='http://www.instagram.com/ClientFuneral/' shash='fsvbYi7nHxtUX6MZsBkdHIt3CXgkXoqtFM2bTR6pMU3PnFWZoUfpRjVTuiuyGhvSP2J/3OBTdOuAil+XEwS50dcIRHttevKdqh6kGkwewZfnWzV0TQbxWyx6r9gfw/xfmwdu4ZL1sJkcv4zfmfAQE2IlGL6kdRAUGL+S4bhQuKo=' title='Dirección URL original: http://www.instagram.com/ClientFuneral/. Haga clic o pulse si confía en este vínculo.' data-linkindex='3'><span style='color:black; text-decoration:none'><img data-imagetype='AttachmentByCid' originalsrc='cid:image009.png@01D9F11D.972043C0' data-custom='AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAPNPI0vEAy1PpVBMc8JOG%2Fg%3D' naturalheight='0' naturalwidth='0' src='https://attachments.office.net/owa/user%40contoso.com/service.svc/s/GetAttachmentThumbnail?id=AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAPNPI0vEAy1PpVBMc8JOG%2Fg%3D&amp;thumbnailType=2&amp;token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjczRkI5QkJFRjYzNjc4RDRGN0U4NEI0NDBCQUJCMTJBMzM5RDlGOTgiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJjX3VidnZZMmVOVDM2RXRFQzZ1eEtqT2RuNWcifQ.eyJvcmlnaW4iOiJodHRwczovL291dGxvb2sub2ZmaWNlLmNvbSIsInVjIjoiNmNmZDg2ZGM0N2ZmNGI1NzljYTlkMWY2NmJhOTIxYmYiLCJzaWduaW5fc3RhdGUiOiJbXCJkdmNfbW5nZFwiLFwia21zaVwiXSIsInZlciI6IkV4Y2hhbmdlLkNhbGxiYWNrLlYxIiwiYXBwY3R4c2VuZGVyIjoiT3dhRG93bmxvYWRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaXNzcmluZyI6IldXIiwiYXBwY3R4Ijoie1wibXNleGNocHJvdFwiOlwib3dhXCIsXCJwdWlkXCI6XCIxMTUzODAxMTIzNjgzNDA4NDA5XCIsXCJzY29wZVwiOlwiT3dhRG93bmxvYWRcIixcIm9pZFwiOlwiNTY5MTE5ZmYtNmRkZS00ZmMyLTg4ZDYtN2FjY2M1ZjVjZWUyXCIsXCJwcmltYXJ5c2lkXCI6XCJTLTEtNS0yMS0xMzIyNjM4MzQ2LTIzMzcwMzEwNDAtMTgwNTIwMjk1NC0yOTAxMjE0MVwifSIsIm5iZiI6MTY5NzYyNTUwMSwiZXhwIjoxNjk3NjI2MTAxLCJpc3MiOiIwMDAwMDAwMi0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDBAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiYXVkIjoiMDAwMDAwMDItMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwL2F0dGFjaG1lbnRzLm9mZmljZS5uZXRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaGFwcCI6Im93YSJ9.K908J0JYAjyduFb88h3EuXdg5p1wk8WjfSJ2zz67BV3aHXl-EbJS-YMG2AFXWMX7dj4RzJxhJt77CN-Ium5HNsXaWNTqBE7iuA39TRRLBpfx2Tip2YgJijhStlCAQmmytpuSZ6uoMNtQNnMPKR2ASpba60EoMZZ0XTtgwOhcbdVE7LzPO-SRBkEALUS18dNPLeYTNeaBn1W5jXKsf_6ns-Cv3E2mWBGSG5AvuH9Ub1I1oxzeu9qC1JHYeRMPEv9jgWpr9GG9bvfSRGFGCwa7mTG2m9QU_ImmaqfNZnpfMBEZKE15-ivkN-EV_Ktlrea2a-HddYRYbeNbW1yndxh4lw&amp;X-OWA-CANARY=jAJJTrYapUuIB3dq9aR2CKB6oYvGz9sY0_JfcXrhCnErqT8TgeeYhtJQLPcb-7pq4HqDDkbDdoA.&amp;owa=outlook.office.com&amp;scriptVer=20231006004.18&amp;animation=true' border='0' width='19' height='19' id='x_Imagen_x0020_23' style='width: 0.2in; height: 0.2in; min-height: auto; min-width: auto;' crossorigin='use-credentials' fetchpriority='high' class='Do8Zj'></span></a></span><b><span style='font-size:9.0pt; color:#FF2F92'>&nbsp;&nbsp;&nbsp;</span></b><span style='color:black'><a href='https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fwww.linkedin.com%2Fcompany%2FClientFuneral%2F&amp;data=user%40contoso.com%7Cd5f3773951164fcff0c308dbbf28c12c%7C14cb4ab462b845a2a944e225383ee1f9%7C0%7C0%7C638313954369976199%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&amp;sdata=YREmmvzTgCAx%2BjcTmLTCVLwfRCVMPoKhUBm5bo%2BwTSw%3D&amp;reserved=0' target='_blank' rel='noopener noreferrer' data-auth='Verified' originalsrc='https://www.linkedin.com/company/ClientFuneral/' shash='kOe/qS23Kk9hUQPFZXgbkjHWol0nLNYoVmFmX1raUqrPPs20lKvNDe5GUfj9h66gzQcnvecOnAbST6JwmP+Wvf0QFHMyS6Cna1HCwMTTLFRb/SV29tumAqgRBgRz3tTDncjbZMJ8ZOZ7jgEd1bUx+iWvtHF65vyemkiV2D2mHbY=' title='Dirección URL original: https://www.linkedin.com/company/ClientFuneral/. Haga clic o pulse si confía en este vínculo.' data-linkindex='4'><span style='color:black; text-decoration:none'><img data-imagetype='AttachmentByCid' originalsrc='cid:image010.png@01D9F11D.972043C0' data-custom='AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAI6FGsdx9TRAgU7fWKaO13k%3D' naturalheight='0' naturalwidth='0' src='https://attachments.office.net/owa/user%40contoso.com/service.svc/s/GetAttachmentThumbnail?id=AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAI6FGsdx9TRAgU7fWKaO13k%3D&amp;thumbnailType=2&amp;token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjczRkI5QkJFRjYzNjc4RDRGN0U4NEI0NDBCQUJCMTJBMzM5RDlGOTgiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJjX3VidnZZMmVOVDM2RXRFQzZ1eEtqT2RuNWcifQ.eyJvcmlnaW4iOiJodHRwczovL291dGxvb2sub2ZmaWNlLmNvbSIsInVjIjoiNmNmZDg2ZGM0N2ZmNGI1NzljYTlkMWY2NmJhOTIxYmYiLCJzaWduaW5fc3RhdGUiOiJbXCJkdmNfbW5nZFwiLFwia21zaVwiXSIsInZlciI6IkV4Y2hhbmdlLkNhbGxiYWNrLlYxIiwiYXBwY3R4c2VuZGVyIjoiT3dhRG93bmxvYWRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaXNzcmluZyI6IldXIiwiYXBwY3R4Ijoie1wibXNleGNocHJvdFwiOlwib3dhXCIsXCJwdWlkXCI6XCIxMTUzODAxMTIzNjgzNDA4NDA5XCIsXCJzY29wZVwiOlwiT3dhRG93bmxvYWRcIixcIm9pZFwiOlwiNTY5MTE5ZmYtNmRkZS00ZmMyLTg4ZDYtN2FjY2M1ZjVjZWUyXCIsXCJwcmltYXJ5c2lkXCI6XCJTLTEtNS0yMS0xMzIyNjM4MzQ2LTIzMzcwMzEwNDAtMTgwNTIwMjk1NC0yOTAxMjE0MVwifSIsIm5iZiI6MTY5NzYyNTUwMSwiZXhwIjoxNjk3NjI2MTAxLCJpc3MiOiIwMDAwMDAwMi0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDBAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiYXVkIjoiMDAwMDAwMDItMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwL2F0dGFjaG1lbnRzLm9mZmljZS5uZXRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaGFwcCI6Im93YSJ9.K908J0JYAjyduFb88h3EuXdg5p1wk8WjfSJ2zz67BV3aHXl-EbJS-YMG2AFXWMX7dj4RzJxhJt77CN-Ium5HNsXaWNTqBE7iuA39TRRLBpfx2Tip2YgJijhStlCAQmmytpuSZ6uoMNtQNnMPKR2ASpba60EoMZZ0XTtgwOhcbdVE7LzPO-SRBkEALUS18dNPLeYTNeaBn1W5jXKsf_6ns-Cv3E2mWBGSG5AvuH9Ub1I1oxzeu9qC1JHYeRMPEv9jgWpr9GG9bvfSRGFGCwa7mTG2m9QU_ImmaqfNZnpfMBEZKE15-ivkN-EV_Ktlrea2a-HddYRYbeNbW1yndxh4lw&amp;X-OWA-CANARY=jAJJTrYapUuIB3dq9aR2CKB6oYvGz9sY0_JfcXrhCnErqT8TgeeYhtJQLPcb-7pq4HqDDkbDdoA.&amp;owa=outlook.office.com&amp;scriptVer=20231006004.18&amp;animation=true' border='0' width='19' height='19' id='x_Imagen_x0020_24' style='width: 0.2in; height: 0.2in; min-height: auto; min-width: auto;' crossorigin='use-credentials' fetchpriority='high' class='Do8Zj'></span></a></span><b><span style='font-size:9.0pt; color:#FF2F92'>&nbsp;&nbsp;&nbsp;</span></b><span style='color:black'><a href='https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Ftwitter.com%2FClientFuneral&amp;data=user%40contoso.com%7Cd5f3773951164fcff0c308dbbf28c12c%7C14cb4ab462b845a2a944e225383ee1f9%7C0%7C0%7C638313954369976199%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&amp;sdata=%2FF3LqBIE9nfi2AXq2nJe88jprJDYpfcGdZXSFFQOQ%2Bk%3D&amp;reserved=0' target='_blank' rel='noopener noreferrer' data-auth='Verified' originalsrc='https://twitter.com/ClientFuneral' shash='dBmp6UsuVRpL3WdZHBd3q7SYZ5QMsJiVuflKb6TNkaHZrdCuB74/+tUEJvMilBj4ikxA+9XkcIvj9EQpmB6yZk+gyWOKQ4/AM1nd7YU43MRQslsyRC5d75KPImg9cgyV4cWgypjWJFnuM2cy5dxYWgcWgWrtgWG0thuAkZwUgwE=' title='Dirección URL original: https://twitter.com/ClientFuneral. Haga clic o pulse si confía en este vínculo.' data-linkindex='5'><span style='color:black; text-decoration:none'><img data-imagetype='AttachmentByCid' originalsrc='cid:image011.png@01D9F11D.972043C0' data-custom='AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAC1qSL%2Fq5qxLl7rN1fSdqg4%3D' naturalheight='0' naturalwidth='0' src='https://attachments.office.net/owa/user%40contoso.com/service.svc/s/GetAttachmentThumbnail?id=AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAC1qSL%2Fq5qxLl7rN1fSdqg4%3D&amp;thumbnailType=2&amp;token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjczRkI5QkJFRjYzNjc4RDRGN0U4NEI0NDBCQUJCMTJBMzM5RDlGOTgiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJjX3VidnZZMmVOVDM2RXRFQzZ1eEtqT2RuNWcifQ.eyJvcmlnaW4iOiJodHRwczovL291dGxvb2sub2ZmaWNlLmNvbSIsInVjIjoiNmNmZDg2ZGM0N2ZmNGI1NzljYTlkMWY2NmJhOTIxYmYiLCJzaWduaW5fc3RhdGUiOiJbXCJkdmNfbW5nZFwiLFwia21zaVwiXSIsInZlciI6IkV4Y2hhbmdlLkNhbGxiYWNrLlYxIiwiYXBwY3R4c2VuZGVyIjoiT3dhRG93bmxvYWRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaXNzcmluZyI6IldXIiwiYXBwY3R4Ijoie1wibXNleGNocHJvdFwiOlwib3dhXCIsXCJwdWlkXCI6XCIxMTUzODAxMTIzNjgzNDA4NDA5XCIsXCJzY29wZVwiOlwiT3dhRG93bmxvYWRcIixcIm9pZFwiOlwiNTY5MTE5ZmYtNmRkZS00ZmMyLTg4ZDYtN2FjY2M1ZjVjZWUyXCIsXCJwcmltYXJ5c2lkXCI6XCJTLTEtNS0yMS0xMzIyNjM4MzQ2LTIzMzcwMzEwNDAtMTgwNTIwMjk1NC0yOTAxMjE0MVwifSIsIm5iZiI6MTY5NzYyNTUwMSwiZXhwIjoxNjk3NjI2MTAxLCJpc3MiOiIwMDAwMDAwMi0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDBAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiYXVkIjoiMDAwMDAwMDItMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwL2F0dGFjaG1lbnRzLm9mZmljZS5uZXRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaGFwcCI6Im93YSJ9.K908J0JYAjyduFb88h3EuXdg5p1wk8WjfSJ2zz67BV3aHXl-EbJS-YMG2AFXWMX7dj4RzJxhJt77CN-Ium5HNsXaWNTqBE7iuA39TRRLBpfx2Tip2YgJijhStlCAQmmytpuSZ6uoMNtQNnMPKR2ASpba60EoMZZ0XTtgwOhcbdVE7LzPO-SRBkEALUS18dNPLeYTNeaBn1W5jXKsf_6ns-Cv3E2mWBGSG5AvuH9Ub1I1oxzeu9qC1JHYeRMPEv9jgWpr9GG9bvfSRGFGCwa7mTG2m9QU_ImmaqfNZnpfMBEZKE15-ivkN-EV_Ktlrea2a-HddYRYbeNbW1yndxh4lw&amp;X-OWA-CANARY=jAJJTrYapUuIB3dq9aR2CKB6oYvGz9sY0_JfcXrhCnErqT8TgeeYhtJQLPcb-7pq4HqDDkbDdoA.&amp;owa=outlook.office.com&amp;scriptVer=20231006004.18&amp;animation=true' border='0' width='19' height='19' id='x_Imagen_x0020_25' style='width: 0.2in; height: 0.2in; min-height: auto; min-width: auto;' crossorigin='use-credentials' fetchpriority='high' class='Do8Zj'></span></a></span><b><span style='font-size:9.0pt; color:#FF2F92'>&nbsp;&nbsp;&nbsp;</span></b><span style='color:black'><a href='https://eur01.safelinks.protection.outlook.com/?url=https%3A%2F%2Fwww.youtube.com%2Fchannel%2FUCuCKBlkringQuZXaTbvGHeQ&amp;data=user%40contoso.com%7Cd5f3773951164fcff0c308dbbf28c12c%7C14cb4ab462b845a2a944e225383ee1f9%7C0%7C0%7C638313954369976199%7CUnknown%7CTWFpbGZsb3d8eyJWIjoiMC4wLjAwMDAiLCJQIjoiV2luMzIiLCJBTiI6Ik1haWwiLCJXVCI6Mn0%3D%7C3000%7C%7C%7C&amp;sdata=%2BZ2ZP6r1X6VLZNM77U66Sl7p%2Fe1RZu0haRDEcDqRzBw%3D&amp;reserved=0' target='_blank' rel='noopener noreferrer' data-auth='Verified' originalsrc='https://www.youtube.com/channel/UCuCKBlkringQuZXaTbvGHeQ' shash='WmHKVtffOyodWZQ0VrM5JsTx+L1GFcrIr8Osgs/8vtazjeHEmC62Sk96jVPKrPShWKb4jY4ybVnsTcLzHMJlL3byzQ4DogeD+6XM7TNe5OtDQod4iPvyQGi6NUwO/YAqAT55+JPkepYodIR02kLJrc9nzfuiSUEeIMr5T0vO7hA=' title='Dirección URL original: https://www.youtube.com/channel/UCuCKBlkringQuZXaTbvGHeQ. Haga clic o pulse si confía en este vínculo.' data-linkindex='6'><span style='color:black; text-decoration:none'><img data-imagetype='AttachmentByCid' originalsrc='cid:image012.png@01D9F11D.972043C0' data-custom='AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQACvicPg51v1HlOpTZz1cl4A%3D' naturalheight='0' naturalwidth='0' src='https://attachments.office.net/owa/user%40contoso.com/service.svc/s/GetAttachmentThumbnail?id=AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQACvicPg51v1HlOpTZz1cl4A%3D&amp;thumbnailType=2&amp;token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjczRkI5QkJFRjYzNjc4RDRGN0U4NEI0NDBCQUJCMTJBMzM5RDlGOTgiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJjX3VidnZZMmVOVDM2RXRFQzZ1eEtqT2RuNWcifQ.eyJvcmlnaW4iOiJodHRwczovL291dGxvb2sub2ZmaWNlLmNvbSIsInVjIjoiNmNmZDg2ZGM0N2ZmNGI1NzljYTlkMWY2NmJhOTIxYmYiLCJzaWduaW5fc3RhdGUiOiJbXCJkdmNfbW5nZFwiLFwia21zaVwiXSIsInZlciI6IkV4Y2hhbmdlLkNhbGxiYWNrLlYxIiwiYXBwY3R4c2VuZGVyIjoiT3dhRG93bmxvYWRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaXNzcmluZyI6IldXIiwiYXBwY3R4Ijoie1wibXNleGNocHJvdFwiOlwib3dhXCIsXCJwdWlkXCI6XCIxMTUzODAxMTIzNjgzNDA4NDA5XCIsXCJzY29wZVwiOlwiT3dhRG93bmxvYWRcIixcIm9pZFwiOlwiNTY5MTE5ZmYtNmRkZS00ZmMyLTg4ZDYtN2FjY2M1ZjVjZWUyXCIsXCJwcmltYXJ5c2lkXCI6XCJTLTEtNS0yMS0xMzIyNjM4MzQ2LTIzMzcwMzEwNDAtMTgwNTIwMjk1NC0yOTAxMjE0MVwifSIsIm5iZiI6MTY5NzYyNTUwMSwiZXhwIjoxNjk3NjI2MTAxLCJpc3MiOiIwMDAwMDAwMi0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDBAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiYXVkIjoiMDAwMDAwMDItMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwL2F0dGFjaG1lbnRzLm9mZmljZS5uZXRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaGFwcCI6Im93YSJ9.K908J0JYAjyduFb88h3EuXdg5p1wk8WjfSJ2zz67BV3aHXl-EbJS-YMG2AFXWMX7dj4RzJxhJt77CN-Ium5HNsXaWNTqBE7iuA39TRRLBpfx2Tip2YgJijhStlCAQmmytpuSZ6uoMNtQNnMPKR2ASpba60EoMZZ0XTtgwOhcbdVE7LzPO-SRBkEALUS18dNPLeYTNeaBn1W5jXKsf_6ns-Cv3E2mWBGSG5AvuH9Ub1I1oxzeu9qC1JHYeRMPEv9jgWpr9GG9bvfSRGFGCwa7mTG2m9QU_ImmaqfNZnpfMBEZKE15-ivkN-EV_Ktlrea2a-HddYRYbeNbW1yndxh4lw&amp;X-OWA-CANARY=jAJJTrYapUuIB3dq9aR2CKB6oYvGz9sY0_JfcXrhCnErqT8TgeeYhtJQLPcb-7pq4HqDDkbDdoA.&amp;owa=outlook.office.com&amp;scriptVer=20231006004.18&amp;animation=true' border='0' width='19' height='19' id='x_Imagen_x0020_26' style='width: 0.2in; height: 0.2in; min-height: auto; min-width: auto;' crossorigin='use-credentials' fetchpriority='high' class='Do8Zj'></span></a></span><span style=''></span></p><p class='x_MsoNormal' style='text-indent:35.4pt; background:white'><span style='color:black'><img data-imagetype='AttachmentByCid' originalsrc='cid:image013.png@01D9F11D.972043C0' data-custom='AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAOW8hFm1aoJPtvmTQBAjrKM%3D' naturalheight='0' naturalwidth='0' src='https://attachments.office.net/owa/user%40contoso.com/service.svc/s/GetAttachmentThumbnail?id=AAMkAGI3MmIxZTA1LTJjMTYtNDFhOC1hMDBjLTc3NDUyOWRiZDA1MQBGAAAAAACbw5HGPTR9SpnOmS2IDmeQBwAobkZY8c%2B1RYB0eb5MWKYvAAAAAAEMAAAobkZY8c%2B1RYB0eb5MWKYvAADX9AKTAAABEgAQAOW8hFm1aoJPtvmTQBAjrKM%3D&amp;thumbnailType=2&amp;token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjczRkI5QkJFRjYzNjc4RDRGN0U4NEI0NDBCQUJCMTJBMzM5RDlGOTgiLCJ0eXAiOiJKV1QiLCJ4NXQiOiJjX3VidnZZMmVOVDM2RXRFQzZ1eEtqT2RuNWcifQ.eyJvcmlnaW4iOiJodHRwczovL291dGxvb2sub2ZmaWNlLmNvbSIsInVjIjoiNmNmZDg2ZGM0N2ZmNGI1NzljYTlkMWY2NmJhOTIxYmYiLCJzaWduaW5fc3RhdGUiOiJbXCJkdmNfbW5nZFwiLFwia21zaVwiXSIsInZlciI6IkV4Y2hhbmdlLkNhbGxiYWNrLlYxIiwiYXBwY3R4c2VuZGVyIjoiT3dhRG93bmxvYWRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaXNzcmluZyI6IldXIiwiYXBwY3R4Ijoie1wibXNleGNocHJvdFwiOlwib3dhXCIsXCJwdWlkXCI6XCIxMTUzODAxMTIzNjgzNDA4NDA5XCIsXCJzY29wZVwiOlwiT3dhRG93bmxvYWRcIixcIm9pZFwiOlwiNTY5MTE5ZmYtNmRkZS00ZmMyLTg4ZDYtN2FjY2M1ZjVjZWUyXCIsXCJwcmltYXJ5c2lkXCI6XCJTLTEtNS0yMS0xMzIyNjM4MzQ2LTIzMzcwMzEwNDAtMTgwNTIwMjk1NC0yOTAxMjE0MVwifSIsIm5iZiI6MTY5NzYyNTUwMSwiZXhwIjoxNjk3NjI2MTAxLCJpc3MiOiIwMDAwMDAwMi0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDBAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiYXVkIjoiMDAwMDAwMDItMDAwMC0wZmYxLWNlMDAtMDAwMDAwMDAwMDAwL2F0dGFjaG1lbnRzLm9mZmljZS5uZXRAMTRjYjRhYjQtNjJiOC00NWEyLWE5NDQtZTIyNTM4M2VlMWY5IiwiaGFwcCI6Im93YSJ9.K908J0JYAjyduFb88h3EuXdg5p1wk8WjfSJ2zz67BV3aHXl-EbJS-YMG2AFXWMX7dj4RzJxhJt77CN-Ium5HNsXaWNTqBE7iuA39TRRLBpfx2Tip2YgJijhStlCAQmmytpuSZ6uoMNtQNnMPKR2ASpba60EoMZZ0XTtgwOhcbdVE7LzPO-SRBkEALUS18dNPLeYTNeaBn1W5jXKsf_6ns-Cv3E2mWBGSG5AvuH9Ub1I1oxzeu9qC1JHYeRMPEv9jgWpr9GG9bvfSRGFGCwa7mTG2m9QU_ImmaqfNZnpfMBEZKE15-ivkN-EV_Ktlrea2a-HddYRYbeNbW1yndxh4lw&amp;X-OWA-CANARY=jAJJTrYapUuIB3dq9aR2CKB6oYvGz9sY0_JfcXrhCnErqT8TgeeYhtJQLPcb-7pq4HqDDkbDdoA.&amp;owa=outlook.office.com&amp;scriptVer=20231006004.18&amp;animation=true' border='0' width='200' height='50' id='x_Imagen_x0020_27' style='width: 2.0833in; height: 0.525in; min-height: auto; min-width: auto; cursor: pointer;' crossorigin='use-credentials' fetchpriority='high' class='Do8Zj'></span><span style=''></span></p><p class='x_MsoNormal'><span style='font-family: Arial, sans-serif, serif, EmojiFont;'>&nbsp;</span></p>"
    # If Testing Is Enabled - Email Administrator
    if($testing)
    {
        $emailaddress = $testRecipient
    } # End Testing
    # If a user has no email address listed
    if($null -eq ($emailaddress))
    {
        $emailaddress = $testRecipient    
    }# End No Valid Email
    $samLabel = $samAccountName.PadRight($padVal," ")
    try{
        # If using interval paramter - follow this section
        if($interval)
        {
            $daysToExpire = [int]$user.DaysToExpire
            # check interval array for expiry days
            if(($interval) -Contains($daysToExpire))
            {
                # if using status - output information to console
                if($status)
                {
                    Write-Output "Sending Email : $samLabel : $emailAddress"
                }
                # Send message - if you need to use SMTP authentication watch this video https://youtu.be/_-JHzG_LNvw
                Send-Mailmessage -smtpServer $smtpServer -Port $SMTPPort -UseSsl -from $from -to $emailaddress -subject $subject -body $body -bodyasHTML -Credential $credential -priority High -Encoding $textEncoding -ErrorAction Stop
                $user | Add-Member -MemberType NoteProperty -Name SendMail -Value "OK"
            }
            else
            {
                # if using status - output information to console
                # No Message sent
                if($status)
                {
                    Write-Output "Sending Email : $samLabel : $emailAddress : Skipped - Interval"
                }
                $user | Add-Member -MemberType NoteProperty -Name SendMail -Value "Skipped - Interval"
            }
        }
        else
        {
            # if not using interval paramter - follow this section
            # if using status - output information to console
            if($status)
            {
                Write-Output "Sending Email : $samLabel : $emailAddress"
            }
            Send-Mailmessage -smtpServer $smtpServer -Port $SMTPPort -UseSsl -from $from -to $emailaddress -subject $subject -body $body -bodyasHTML -Credential $credential -priority High -Encoding $textEncoding -ErrorAction Stop
            $user | Add-Member -MemberType NoteProperty -Name SendMail -Value "OK"
        }
    }
    catch{
        # error section
        $errorMessage = $_.exception.Message
        # if using status - output information to console
        if($status)
        {
           $errorMessage
        }
        $user | Add-Member -MemberType NoteProperty -Name SendMail -Value $errorMessage    
    }
    $notifiedUsers += $user
}
if($logging)
{
    # Create Log File
    Write-Output "Creating Log File"
    $day = $today.Day
    $month = $today.Month
    $year = $today.Year
    $date = "$day-$month-$year"
    $logFileName = "$date-PasswordLog.csv"
    if(($logPath.EndsWith("\")))
    {
       $logPath = $logPath -Replace ".$"
    }
    $logFile = $logPath, $logFileName -join "\"
    Write-Output "Log Output: $logfile"
    $notifiedUsers | Export-CSV $logFile
    if($reportTo)
    {
        $reportSubject = "Password Expiry Report"
        $reportBody = "Password Expiry Report Attached"
        try{
            Send-Mailmessage -smtpServer $smtpServer -Port $SMTPPort -UseSsl -from $from -to $reportTo -subject $reportSubject -body $reportbody -bodyasHTML -Credential $credential -priority High -Encoding $textEncoding -Attachments $logFile -ErrorAction Stop 
        }
        catch{
            $errorMessage = $_.Exception.Message
            Write-Output $errorMessage
        }
    }
}
$notifiedUsers | Select-Object UserName,Name,EmailAddress,PasswordSet,DaysToExpire,ExpiresOn | Sort-Object DaystoExpire | Format-Table -autoSize

$stop = [datetime]::Now
$runTime = New-TimeSpan $start $stop
Write-Output "Script Runtime: $runtime"
# End
