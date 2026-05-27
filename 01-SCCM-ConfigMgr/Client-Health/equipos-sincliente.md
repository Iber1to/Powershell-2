# equipos-sincliente.ps1

Genera y **envía por correo un informe de equipos no gestionados**: cruza el censo de Active Directory con lo que ve SCCM para destacar máquinas activas en AD que no tienen (o tienen roto) el cliente de ConfigMgr.

## Cómo funciona

- Saca de AD todos los equipos que **no han cambiado su contraseña de máquina** en X días (un buen proxy de "equipo realmente activo"; el valor recomendado es 90).
- Saca de SCCM los dispositivos sin cliente.
- Combina ambas fuentes, resuelve el último usuario que inició sesión y compone una tabla por equipo: en SCCM / con cliente / OU / última actividad SCCM / último logon AD / usuario / SO / info adicional.
- Adjunta los CSV y lo manda por correo.

## Parámetros
`-Daysold` (días desde el último cambio de contraseña de máquina), `-DomainSuffix` (sufijo de dominio interno) y `-StaleCollectionID`.

## Tecnología
Active Directory · SCCM / ConfigMgr · correo con adjuntos.

## Notas
Pensado para ejecutarse desde el servidor de SCCM con permisos de lectura sobre objetos de CM y de equipo en AD.
