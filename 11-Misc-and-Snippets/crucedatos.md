# crucedatos.ps1

Cruza el **inventario de dispositivos de Intune contra unas listas de exclusión** para construir el conjunto final de equipos a remediar (trabajo hecho para un cliente, anonimizado).

## Cómo funciona
Usa varios `ArrayList` (usuarios excluidos, datos de Intune, datos filtrados, dispositivos a remediar), carga los ficheros de entrada y va filtrando los dispositivos de Intune quitando los excluidos hasta dejar la lista de los que hay que actuar.

## Tecnología
`System.Collections.ArrayList` · datos exportados de Intune · CSV/TXT.

## Notas
Cliente y rutas anonimizados. Mismo patrón de conciliación con ArrayLists que `arraylists.ps1`.
