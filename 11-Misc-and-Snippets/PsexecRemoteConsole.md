# PsexecRemoteConsole.ps1

Permite **abrir una consola o ejecutar un script en un equipo remoto** apoyándose en PsExec.

## Cómo funciona
Prepara la ejecución remota (con generación de una contraseña temporal mediante `Membership::GeneratePassword`) y lanza la consola/script en la máquina destino vía PsExec.

## Tecnología
PsExec (Sysinternals) · ejecución remota.

## Notas
De origen externo. `remoteconsole.ps1` es prácticamente idéntico. La contraseña se genera al vuelo (no va hardcodeada).
