# temp-snippet-3.ps1

Snippet que registra una **tarea programada para respaldar la clave de BitLocker en Azure AD** (`BackupKeyToAAD`).

## Cómo funciona
Define el script objetivo (`bitlocker.ps1`), el nombre y carpeta de la tarea, detecta el usuario con sesión interactiva (`Win32_ComputerSystem`) y crea la tarea programada correspondiente.

## Tecnología
Programador de tareas · BitLocker · escrow de clave en Azure AD.

## Notas
Fragmento de trabajo relacionado con la gestión de claves de BitLocker.
