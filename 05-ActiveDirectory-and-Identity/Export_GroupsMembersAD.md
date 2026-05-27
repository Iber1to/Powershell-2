# Export_GroupsMembersAD.ps1

Exporta a CSV **todos los grupos de un dominio y sus miembros**.

## Cómo funciona
Contra el dominio origen indicado (`-Server`), obtiene todos los grupos (`Get-ADGroup -Filter *`) y los usuarios habilitados, y vuelca la pertenencia a un CSV con marca temporal en `C:\temp`.

## Tecnología
Active Directory.

## Notas
El dominio origen real se ha anonimizado. `Export_GroupsMembersADLimitOU.ps1` hace lo mismo pero acotado a una OU y de forma recursiva.
