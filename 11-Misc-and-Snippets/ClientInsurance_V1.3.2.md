# ClientInsurance_V1.3.2.ps1

Recopila **todos los datos necesarios para una auditoría de infraestructura de ConfigMgr** y los consolida (originalmente una auditoría hecha para un cliente del sector seguros, de ahí el nombre anonimizado).

## Cómo funciona
Reúne, por dispositivo, propiedades como Name, ResourceID, IsClient, SiteCode, ClientVersion, SO y build, estado de Endpoint Protection (antivirus, versión de firmas, motor), si es máquina virtual y `LastActiveTime`; y a nivel de sitio: nombre de servidor, SiteCode, build y versión. Lo junta en un informe único.

## Tecnología
SCCM / ConfigMgr · inventario de Endpoint Protection.

## Notas
El nombre original incluía el del cliente; se ha anonimizado a `ClientInsurance`. Útil como foto de estado de un parque gestionado.
