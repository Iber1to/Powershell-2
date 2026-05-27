# Clear-BitlockerKeys.ps1

Herramienta **interactiva** (con cuadros de diálogo de Windows Forms) para limpiar/gestionar claves de BitLocker, pensada para ejecutarse a mano por un técnico y no de forma desatendida.

## Cómo funciona

- Carga `System.Windows.Forms` y define dos helpers (`ConfirmWindow`, `InforWindow`) que muestran `MessageBox` de confirmación e información.
- Comprueba privilegios de administrador antes de continuar.
- Verifica que el módulo **Active Directory** (RSAT) esté disponible y, si no lo está, ofrece instalarlo (`Get-WindowsCapability` / `Install-Module ActiveDirectory`) antes de operar sobre las claves.

## Tecnología
WinForms (GUI) · módulo Active Directory / RSAT · comprobación de elevación.

## Notas
Es un script de uso manual y asistido por interfaz; conviene revisarlo antes de ejecutarlo en lote porque depende de la interacción del operador.
