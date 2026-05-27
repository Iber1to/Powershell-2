# Define el nombre de la red Wi-Fi (SSID)
$wifiName = "Corp-WiFi"  # Reemplaza con el nombre de tu red Wi-Fi

# Verifica si el perfil de la red Wi-Fi existe en el equipo
$profileExists = netsh wlan show profiles | Select-String -Pattern $wifiName

if ($profileExists) {
    # Si el perfil existe, conecta a la red Wi-Fi
    Write-Output "El perfil de la red Wi-Fi '$wifiName' existe. Intentando conectar..."
    Try {

        # Activar la opción de autoconectar para la red Wi-Fi
        netsh wlan set profileparameter name=$wifiName connectionmode=auto

        # Conectar a la red Wi-Fi
        netsh wlan connect name=$wifiName

        #Exit 0
    } catch {
        Write-Output "Se ha producido un error:"
        Write-Output "Mensaje de Error: $($_.Exception.Message)"
        Write-Output "Tipo de Error: $($_.Exception.GetType().FullName)"
        Write-Output "Traza de la pila: $($_.Exception.StackTrace)"
        #Exit 1
    }
} else {
    # Si el perfil no existe, no hace nada
    Write-Output "El perfil de la red Wi-Fi '$wifiName' no existe. No se realizará ninguna acción."
    #Exit 0
}
