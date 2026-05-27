# MensajeTaskSequence.ps1

Muestra al usuario un **cuadro de diálogo** durante una task sequence preguntando si desea instalar ahora o posponer.

## Cómo funciona
Usa `WScript.Shell.Popup` con los botones "Instalar ahora" / "Posponer" y, según la respuesta, continúa con la instalación o la pospone.

## Tecnología
`WScript.Shell` (COM) · interacción con el usuario.

## Notas
Pieza de interacción para integrar en despliegues que requieren confirmación del usuario.
