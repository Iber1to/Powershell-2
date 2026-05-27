<# Para evitar generar una AzureApp con los permisos SharePoint:
    - Sites.Read.All
    Read items in all site collections. Allows the app to read documents and list items in all site collections without a signed in user.
    - Files.Read.All
    Read files in all site collections. Allows the app to read all files in all site collections without a signed in user.
Se va a utilizar el permiso que permite limitar los permisos concedidos a un unico site: 
    - Sites.Selected
    Access selected site collections. Allow the application to access a subset of site collections without a signed in user. The specific site collections and the permissions granted will be configured in SharePoint Online.

    ** Requisitos previso **
Vamos a necesitar registrar dos apps en Azure, una que sera la que entreguemos al proveedor, la otra para poder asignar permisos sobre el site en la del proveedor

App para el proveedor:
    - Display name: "Talgo Sharepoint Acces"
    - Application (client) ID: "11111111-1111-1111-1111-000000000056"
    - Client Secret: "REDACTED_CLIENT_SECRET" 
    - Api permission: "Sites.Selected"

App para la delegacion en el site:
    - Display name: "PnP.PowerShell"
    - Application (client) ID: "11111111-1111-1111-1111-000000000057"
    - Certificates: Autogenerado. Thumbprint: "8A36EE2986C88DA859061A6D568B4E35DDA521CF". Description: "MySPAppCert"
    - Client Secret: "REDACTED_CLIENT_SECRET"
    - Api permission: "Sites.FullControl.All"
    #>


# Paso 1. Generamos el autocertificado para la App de delegacion
    $cert = New-SelfSignedCertificate -Subject "CN=MySPAppCert" -CertStoreLocation Cert:\CurrentUser\My
    # Este es el que subiremos en la app
    Export-Certificate -Cert $cert -FilePath "C:\certs\spocert.cer"
    # Lo exportamos para tener un backup por si lo necesitamos instalar en otra maquina
    $pwdcert = ConvertTo-SecureString -String "MiPasswordCert" -AsPlainText -Force
    Export-PfxCertificate -Cert $cert -FilePath "C:\certs\spocert.pfx" -Password $pwdcert

# Paso 2. Delegamos permisos "Read" a la app del provedor en el site: "https://btren.sharepoint.com/sites/INGENIERIA"
    # Datos de las Apps
        $tenantId     = "11111111-1111-1111-1111-000000000058"          
        $AppProveedorId   = "11111111-1111-1111-1111-000000000056"           
        $AppProveedorSecret  = "REDACTED_CLIENT_SECRET"
        $AppProveedorDisplayName = "Talgo Sharepoint Acces"
        $AppAssignRolesId = "11111111-1111-1111-1111-000000000057"
        $AppAssignRolesSecret = "REDACTED_CLIENT_SECRET"
        $siteUrl    = "https://btren.sharepoint.com/sites/INGENIERIA"
        $SiteId = "btren.sharepoint.com,11111111-1111-1111-1111-000000000059,11111111-1111-1111-1111-000000000060"


# Paso 3. Asignamos el rol de read a la App del proveedor

    # Connectar con MgGraph con la App para asignar roles. No permite secret Value hay que usar el certificado
    Connect-MgGraph -TenantId $TenantID -ClientId $AppAssignRolesId -CertificateThumbprint "8a36ee2986c88da859061a6d568b4e35dda521cf"
    $Site = get-mgSite -SiteId $siteId

    # Generamos el objeto App con los datos de la App del proveedor
    $Application = @{}
    $Application.Add("id" , $AppProveedorId)
    $Application.Add("displayName", $AppProveedorDisplayName)
    
    # Rol a asignar a la App
    $RequestedRole = "read"

    # Le asignamos el rol a la App del proveedor para el site concreto
    $Status = New-MgSitePermission -SiteId $Site.Id -Roles $RequestedRole -GrantedToIdentities @{"application" = $Application}
    If ($Status.id) { 
        Write-Host ("{0} permission granted to site {1}" -f $RequestedRole, $Site.DisplayName )
    }

    # Chequeamos los permisos asignados
    [array]$Permissions = Get-MgSitePermission -SiteId $Site.Id 
    ForEach ($Permission in $Permissions){
        $Data = Get-MgSitePermission -PermissionId $Permission.Id -SiteId $Site.Id -Property Id, Roles, GrantedToIdentitiesV2
        Write-Host ("{0} permission available to {1}" -f ($Data.Roles -join ","), $Data.GrantedToIdentitiesV2.Application.DisplayName)
        }
    
    # 

# Paso 4. Comprobamos que la App del proveedor es capaz de leer los archivos del site.

        # Obtener token app del proveedor
        $tokenBody = @{
        client_id     = $AppProveedorId
        client_secret = $AppProveedorSecret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
        }
        $tokenResponse = Invoke-RestMethod -Method Post `
            -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
            -Body $tokenBody
        $token = $tokenResponse.access_token

        # Listamos los archivos en drive del site y los listamos
        $drive = Invoke-RestMethod -Method Get `
        -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/drive" `
        -Headers @{ Authorization = "Bearer $token" }

        Write-Host "`nDriveId:" $drive.id
        $items = Invoke-RestMethod -Method Get `
        -Uri "https://graph.microsoft.com/v1.0/drives/$($drive.id)/root/children" `
        -Headers @{ Authorization = "Bearer $token" }

        Write-Host "`nContenido del drive raíz:"
        $items.value | Select-Object name, folder, file, size


# El mismo test de antes pero esta vez con certificado en lugar de secretkey

# Parámetros de tu app
$TenantId   = "11111111-1111-1111-1111-000000000058"
$ClientId   = "11111111-1111-1111-1111-000000000056"
$CertThumb  = "9fd75bb493eaa0fea29d07be598cc8cd6531bf2b"   # el cert debe estar subido en la app (Certificates & secrets)
$SiteId = "btren.sharepoint.com,11111111-1111-1111-1111-000000000059,11111111-1111-1111-1111-000000000060"

# Cargar certificado , asegurate de cambiar la ruta a la tuya
$ClientCert = Get-Item "Cert:\CurrentUser\My\$CertThumb"

# Obtener token para Graph con client_credentials + certificado
$msToken = Get-MsalToken `
    -TenantId  $TenantId `
    -ClientId  $ClientId `
    -ClientCertificate $ClientCert `
    -Scopes "https://graph.microsoft.com/.default"

$token = $msToken.AccessToken

 # Listamos los archivos en drive del site y los listamos
        $drive = Invoke-RestMethod -Method Get `
        -Uri "https://graph.microsoft.com/v1.0/sites/$siteId/drive" `
        -Headers @{ Authorization = "Bearer $token" }

        Write-Host "`nDriveId:" $drive.id
        $items = Invoke-RestMethod -Method Get `
        -Uri "https://graph.microsoft.com/v1.0/drives/$($drive.id)/root/children" `
        -Headers @{ Authorization = "Bearer $token" }

        Write-Host "`nContenido del drive raíz:"
        $items.value | Select-Object name, folder, file, size