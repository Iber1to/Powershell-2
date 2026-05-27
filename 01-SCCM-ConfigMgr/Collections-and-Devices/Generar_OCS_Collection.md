# Generar_OCS_Collection.ps1

Carga en una **colección de SCCM** los equipos de un informe de OCS (los que están en estado `KO` o `NoData`) para poder actuar sobre ellos.

## Cómo funciona

- Importa un CSV con los resultados de OCS.
- Según dos líneas que se comentan/descomentan, cuenta y selecciona los equipos `KO` o los `NoData`.
- Se conecta al CAS (módulo de ConfigMgr) y va añadiendo esos equipos a la colección destino indicada.

## Tecnología
SCCM / ConfigMgr · import de CSV.

## Notas
El propio script avisa de qué líneas hay que alternar para procesar KO frente a NoData; es un patrón manual a tener en cuenta antes de ejecutarlo.
