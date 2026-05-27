# InvokeSccmActions.ps1

Función que **dispara los ciclos de acción del cliente de ConfigMgr** de forma remota (forzar inventario, evaluación de políticas, etc.) sin tener que ir equipo por equipo a la pestaña *Actions*.

## Cómo funciona

Invoca por WMI el método `TriggerSchedule` de la clase `SMS_CLIENT` (namespace `root\ccm`) para cada ciclo: evaluación de despliegue de aplicaciones, Discovery Data Collection, File Collection, Hardware Inventory, Machine Policy Retrieval/Evaluation y Software Inventory.

## Tecnología
SCCM / ConfigMgr (cliente) vía WMI `SMS_CLIENT.TriggerSchedule`.

## Notas
Los GUID de cada *trigger schedule* son **identificadores públicos y fijos de ConfigMgr** (no son secretos); el proceso de anonimización los ha sustituido por valores ficticios, así que para reutilizar el script habría que reponer los valores reales documentados por Microsoft. El parámetro de equipo objetivo es `$Machine`.
