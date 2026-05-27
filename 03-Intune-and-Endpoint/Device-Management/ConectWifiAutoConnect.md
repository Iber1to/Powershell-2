# ConectWifiAutoConnect.ps1

Garantiza que un equipo se **conecte automáticamente a la red Wi-Fi corporativa** si su perfil ya existe.

## Cómo funciona
Comprueba con `netsh wlan show profiles` si existe el perfil del SSID corporativo; si existe, activa la autoconexión e intenta conectar.

## Tecnología
`netsh wlan`.

## Notas
El SSID real se ha anonimizado (`Corp-WiFi`).
