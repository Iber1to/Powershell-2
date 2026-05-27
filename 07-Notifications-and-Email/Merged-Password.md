# Merged-Password.ps1

Pequeña **utilidad gráfica** (WinForms/WPF) para lanzar operaciones de contraseña de las **cuentas de servicio de CMDB** eligiendo la región en una lista.

## Cómo funciona
Muestra un formulario con una lista de regiones; al seleccionar una, la función `launchPass` resuelve la cuenta de servicio y el servidor de ese dominio (EMEA → `SVC_CMDB_EMEA` / `emea.contoso.local`, etc.) y ejecuta la operación correspondiente.

## Tecnología
WinForms / WPF (GUI) · Active Directory.

## Notas
Las cuentas de servicio y dominios se han anonimizado (`SVC_CMDB_*`, `*.contoso.local`).
