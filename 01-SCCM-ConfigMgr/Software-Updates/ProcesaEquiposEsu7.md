# ProcesaEquiposEsu7.ps1

Procesa los **logs de la task sequence de activación de ESU** y mueve los equipos a la colección que corresponda según el resultado.

## Cómo funciona

- Lee desde una ruta de red dos logs generados por la TS: equipos completados y equipos fallidos.
- Carga el módulo de ConfigMgr (CAS) y actualiza la pertenencia de esos equipos a las colecciones `ESU_Procesados_activado` y `ESU_Procesados_NOPrerequisites`.
- Registra el progreso con `Write-CMTracelog`.

## Tecnología
SCCM / ConfigMgr · lectura de logs en red.

## Notas
Rutas UNC y servidores anonimizados. ESU = Extended Security Updates para sistemas fuera de soporte.
