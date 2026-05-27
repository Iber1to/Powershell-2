# Fail-Distributed-Content.ps1

Variante de `Fail-DistributedContent.ps1` que incorpora su propia función `Write-CMTracelog` para un registro más estructurado. Detecta el contenido que ha fallado de distribuirse a los DPs (estados de error en `SMS_PackageStatusDistPointsSummarizer`) y lo vuelve a distribuir.

## Notas
Misma finalidad que `Fail-DistributedContent.ps1`; cambia el enfoque de logging.
