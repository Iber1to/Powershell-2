# chrome_Uninstall.ps1

Localiza la **cadena de desinstalación de Chrome** recorriendo las claves de desinstalación del registro para poder retirarlo.

## Cómo funciona
Recorre `HKLM:\...\Uninstall` recolectando los elementos con `DisplayName`, identifica Chrome y prepara/ejecuta su comando de desinstalación.

## Tecnología
Registro de Windows (claves de desinstalación).

## Notas
Es la pieza de "desinstalación" que complementa a los scripts de versión mínima.
