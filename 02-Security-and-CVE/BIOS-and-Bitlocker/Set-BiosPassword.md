# Set-BiosPassword.ps1

Remediación que **establece la contraseña de Setup de la BIOS en equipos HP** y, de paso, obliga a pedirla en los menús de arranque (F9, F11, F12). Es la pareja de `detection-BiosPassword.ps1`.

## Cómo funciona

Tras verificar que el fabricante es HP, usa el interfaz WMI `HP_BIOSSettingInterface.SetBIOSSetting()` para:

1. Fijar el valor de *Setup Password*.
2. Activar el prompt de contraseña de administrador en F9 (Boot Menu), F11 (System Recovery) y F12 (Network Boot).

Cada llamada devuelve un código numérico que el script traduce a texto legible mediante un `switch` (0 = OK, 6 = "Access denied or incorrect password", 32768 = "Security or password policy not met", etc.), de modo que el resultado quede claro tanto en la consola como en el historial de Intune.

## Tecnología
WMI propietario de HP · contraseña entregada con el prefijo `"<utf-16/>"` que exige el interfaz de HP.

## Notas
La contraseña real venía **hardcodeada** en el script original; aquí aparece como `REDACTED_PASSWORD`. En producción debería inyectarse desde un secreto (Key Vault, variable de despliegue) y no quedar en el código.
