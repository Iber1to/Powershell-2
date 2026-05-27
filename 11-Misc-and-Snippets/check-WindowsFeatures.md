# check-WindowsFeatures.ps1

Detección que comprueba el **estado de una característica opcional de Windows** (en este caso *Print to PDF*).

## Cómo funciona
Con `Get-WindowsOptionalFeature -Online` consulta el estado de la feature `Printing-PrintToPDFServices-Features` y devuelve `Exit 0` si está habilitada, con la rama correspondiente si está deshabilitada.

## Tecnología
`Get-WindowsOptionalFeature` (DISM) · modelo de detección.

## Notas
Plantilla fácil de adaptar a cualquier otra característica opcional cambiando el `FeatureName`.
