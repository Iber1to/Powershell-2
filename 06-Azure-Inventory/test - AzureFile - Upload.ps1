# Variables
$storageAccountName = "intunereportinventory"
$containerName = "hardwareinventory"
$blobName = "Remove-OneDrive_09700OPT714_20260327_103617.log" # El nombre que tendrá el archivo en Azure
$filePath = "C:\Users\user\OneDrive - VendorIT\Documents\Current Projects\ClientCourier\Remove-OneDrive_09700OPT714_20260327_103617.log" # La ruta completa al archivo que deseas subir
$sasToken = "REDACTED_SAS_TOKEN" # Tu SAS Token generado previamente

# URI de Azure Storage Blob
$blobUri = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName$sasToken"

# Leer el contenido del archivo
$fileContent = [System.IO.File]::ReadAllBytes($filePath)
# Llamada PUT a la API REST para subir el archivo
Invoke-RestMethod -Uri $blobUri -Method Put -Headers @{
    "x-ms-blob-type"="BlockBlob"
} -ContentType "application/octet-stream" -Body $fileContent


# Connection string: 
    # BlobEndpoint=https://intunereportinventory.blob.core.windows.net/;QueueEndpoint=https://intunereportinventory.queue.core.windows.net/;FileEndpoint=https://intunereportinventory.file.core.windows.net/;TableEndpoint=https://intunereportinventory.table.core.windows.net/;SharedAccessSignature=REDACTED_SAS_TOKEN

# SAS Token
    # REDACTED_SAS_TOKEN

# Blob Service SAS URL
    # https://intunereportinventory.blob.core.windows.net/REDACTED_SAS_TOKEN



    
# Variables
$storageAccountName = "intunereportinventory"
$containerName = "hardwareinventory"
$blobName = "Remove-OneDrive_09700OPT714_20260327_103617.log"
$filePath = "C:\Users\user\OneDrive - VendorIT\Documents\Current Projects\ClientCourier\Remove-OneDrive_09700OPT714_20260327_103617.log"

# SAS token corregido (usa & en vez de &amp;)
$sasToken = "REDACTED_SAS_TOKEN"
# IMPORTANTE: añadir el ?
$blobUri = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName`?$sasToken"

# Subir archivo
$fileContent = [System.IO.File]::ReadAllBytes($filePath)

Invoke-RestMethod -Uri $blobUri -Method Put -Headers @{
    "x-ms-blob-type" = "BlockBlob"
} -ContentType "application/octet-stream" -Body $fileContent
