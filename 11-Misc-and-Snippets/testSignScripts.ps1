$pathSignScript = 'C:\Sign'
$listToSign = Get-ChildItem $pathSignScript


#Connect to sharepoint
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

#Variables
$SiteURL = "https://Crescent.sharepoint.com/Sites/Marketing"
$ServerRelativeUrl= "/Sites/Marketing/Shared Documents/2017"
 
Try {
    #Get Credentials to connect
    $Cred= Get-Credential
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
 
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = $Credentials
   
    #Get the web from URL
    $Web = $Ctx.web
    $Ctx.Load($Web)
    $Ctx.executeQuery()
 
    #Get the Folder object by Server Relative URL
    $Folder = $Web.GetFolderByServerRelativeUrl($ServerRelativeUrl)
    $Ctx.Load($Folder)
    $Ctx.ExecuteQuery()
     
    #Get Some Folder Properties
    Write-host -f Green "Total Number of Files in the Folder:"$Folder.ItemCount
}
Catch {
    write-host -f Red "Error Getting Folder!" $_.Exception.Message
}

    