$message = "Una nueva actualización o instalación está disponible. ¿Deseas instalarla ahora o posponerla?"
$caption = "Notificación de Instalación"
$buttons = @("Instalar ahora", "Posponer")
$result = $buttons[(New-Object -ComObject WScript.Shell).Popup($message, 0, $caption, 4 + 32)]

if ($result -eq "Instalar ahora") {
    # El usuario eligió proceder con la instalación
    Exit 0
} else {
    # El usuario eligió posponer la instalación
    Exit 1
}