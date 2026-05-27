# Remove-OracleClient11G.ps1

Desinstala **Oracle Client 11G** y limpia los restos locales de la instalación.

## Cómo funciona
Localiza y ejecuta el desinstalador nativo (bajo `C:\app`), **espera a que el proceso termine realmente**, valida evidencias mínimas de finalización y completa la limpieza de ficheros y registro.

## Tecnología
Desinstalador nativo de Oracle · registro · sistema de ficheros.

## Notas
Especialmente cuidadoso con la espera de finalización, porque el desinstalador de Oracle lanza subprocesos.
