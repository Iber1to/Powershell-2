# extraer-datos-coleccion.ps1

Exporta los **nombres de equipo de una colección, separados por dominio**, a varios CSV.

## Cómo funciona

Carga el módulo de ConfigMgr, obtiene `Domain` y `Name` de los equipos de una colección y los reparte en CSV por dominio (APAC, EMEA, LATAM1, LATAM2) con `Export-Csv`.

## Tecnología
SCCM / ConfigMgr · export CSV.

## Notas
Pensado como paso previo para tratamientos por región (por ejemplo, listas de duplicados).
