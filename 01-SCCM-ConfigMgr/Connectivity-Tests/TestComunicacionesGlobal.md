# TestComunicacionesGlobal.ps1

Test **integral de comunicaciones** de un cliente de ConfigMgr: comprueba en una sola pasada los puertos contra su Management Point, el WSUS/SUP, el Distribution Point y el controlador de dominio.

## Cómo funciona

- Incorpora su propia función `Write-CMTracelog` (con ayuda en formato comment-based) para registrar cada paso.
- Determina el MP actual del cliente y, si no coincide con el esperado, lo marca como conflicto.
- Lanza `Test-NetConnection` contra MP, WSUS, DP y DC en sus puertos correspondientes y resume qué comunica y qué no.

## Tecnología
ConfigMgr (cliente) · `Test-NetConnection` · logging CMTrace.

## Notas
Conviven varias iteraciones: `_resultadolimitado` (salida reducida), `_revisar` (versión de trabajo en revisión) y `_Descartes` (recorte/variante). Ésta es la versión de referencia.
