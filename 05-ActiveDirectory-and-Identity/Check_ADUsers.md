# Check_ADUsers.ps1

Parte de un proyecto de **migración de Active Directory**: contiene la función `CrearUsuario`, que da de alta en el dominio destino los usuarios a partir de un mapeo origen→destino.

## Cómo funciona
`CrearUsuario` recibe los datos del usuario (SamAccountName origen y destino, nombre, apellidos, descripción, mail, DN origen, estado habilitado/deshabilitado, etc.) y crea/concilia la cuenta correspondiente en el dominio destino.

## Tecnología
Active Directory (`ActiveDirectory` module).

## Notas
Forma parte del juego de scripts de migración de identidades de un cliente (dominio anonimizado a `ClientInsurance*`).
