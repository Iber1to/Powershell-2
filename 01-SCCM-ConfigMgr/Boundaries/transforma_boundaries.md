# transforma_boundaries.ps1

Utilidad para **transformar/migrar boundaries** en el CAS (por ejemplo, normalizar nombres o convertir tipos de boundary), con un control de permisos previo.

## Cómo funciona

- La función `ConectCAS` comprueba que el usuario que ejecuta la consola sea del tipo privilegiado (prefijo de cuenta `ZX`), únicos con permisos en el CAS; si no, avisa e interrumpe.
- Conecta a la unidad del site `CAS` cargando el módulo de ConfigMgr y, a partir de ahí, opera sobre el conjunto de boundaries.

## Tecnología
SCCM / ConfigMgr (CAS) · control de cuenta privilegiada.

## Notas
El nombre del SMS Provider se ha anonimizado (`SRV004.contoso.local`). El patrón de cuenta `ZX` es la convención interna para cuentas con permisos sobre el CAS.
