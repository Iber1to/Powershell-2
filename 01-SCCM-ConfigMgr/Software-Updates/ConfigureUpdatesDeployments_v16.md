# ConfigureUpdatesDeployments_v16.ps1

Automatiza la **configuración de los despliegues de actualizaciones (SUP/ADR)** calculando las fechas a partir del *Patch Tuesday* de cada mes.

## Cómo funciona

- Calcula el segundo martes del mes (Patch Tuesday) y, a partir de ahí, las ventanas de disponibilidad y deadline.
- Define horarios de despliegue por región (EMEA, válido para los sites PE1/PE2; APAC para el site PL1) y unos tiempos específicos para pre-producción.
- Con esas fechas configura/actualiza los despliegues de actualizaciones correspondientes.

## Tecnología
SCCM / ConfigMgr (Software Update Point / ADR) · cálculo de calendario (Patch Tuesday).

## Notas
Versión 16 del script (`_v16`), lo que da idea de cuánto se afinó el calendario de parcheo.
