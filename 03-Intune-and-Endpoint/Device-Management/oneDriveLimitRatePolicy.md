# oneDriveLimitRatePolicy.ps1

Aplica, **en el contexto del usuario que ha iniciado sesión**, una política de registro para **limitar la velocidad de subida de OneDrive**.

## Cómo funciona
Obtiene el usuario logueado vía `Win32_ComputerSystem`, traduce su cuenta a SID, monta `HKEY_USERS` como PSDrive y escribe bajo `HKU:\<SID>\SOFTWARE\Policies\Microsoft\` las claves que limitan el ratio de subida de OneDrive.

## Tecnología
Registro de Windows (HKU del usuario) · traducción de cuenta a SID.

## Notas
Resuelve el SID del usuario real para escribir en su hive aunque el script corra como sistema.
