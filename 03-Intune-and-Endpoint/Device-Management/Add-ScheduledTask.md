# Add-ScheduledTask.ps1

Importa una **tarea programada definida en XML** que ejecuta, al iniciar sesión el usuario, el script del "Mensaje de Seguridad de la Información (SGSI)".

## Cómo funciona
Lleva embebido el XML de la tarea (disparador `LogonTrigger`, límite de ejecución 1h, URI `\MensajeSGSI`) y lo registra en el Programador de tareas de Windows.

## Tecnología
Programador de tareas de Windows (XML de definición).

## Notas
El autor que figuraba en el XML era una cuenta de dominio; se ha anonimizado (`CONTOSO\...`).
