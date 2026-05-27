# Fix_Unquote_OCSservice.ps1

Corrige la vulnerabilidad **Unquoted Service Path** centrándose (desde la v1.1) en el servicio de **OCS Inventory**.

## Cómo funciona

- Recorre el registro buscando rutas de servicio con espacios sin entrecomillar (el clásico `C:\Program Files\...` sin comillas que permite secuestro del binario).
- Antes de tocar nada, hace **backup** de cada clave modificada en `C:\<nombre del servicio>.reg`, y luego reescribe el valor con las comillas correctas.
- Requiere permisos de administrador.

## Tecnología
Registro de Windows · hardening de servicios.

## Notas
De origen externo (basado en otro script interno). La versión 1.1 acotó la corrección al servicio de OCS.
