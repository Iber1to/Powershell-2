# test-snippet-002b.ps1

Compara los miembros de un **grupo de AD de administradores locales** (escenario LAPS) con los del **grupo local de Administradores** del equipo.

## Cómo funciona
Obtiene los miembros del grupo de AD `SCCM_Laps_LclAdm` (`Get-ADGroupMember`) y los del grupo local `Administrators` (`Get-LocalGroupMember`) para contrastar quién debería y quién está realmente como administrador local.

## Tecnología
Active Directory · grupos locales de Windows.

## Notas
Útil para verificar que la pertenencia a administradores locales coincide con lo aprobado en AD.
