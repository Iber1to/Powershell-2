# creaunacoleccionporcadaSITEboundary.ps1

**Script de terceros** (Harry Lowton) que crea colecciones a partir de las **boundaries de sitio de Active Directory**.

## Cómo funciona

- Importa el módulo de ConfigMgr y obtiene las boundaries de site de AD.
- Crea dos carpetas de colecciones (una de "site count" y otra de "site clients") y, por cada site encontrado, genera dos colecciones que muestran respectivamente todos los dispositivos del site y cuántos clientes de ConfigMgr hay.
- Los nombres de las carpetas son configurables mediante variables.

## Tecnología
SCCM / ConfigMgr · boundaries de AD Site.

## Notas
Código de origen externo; atribución mantenida en la cabecera.
