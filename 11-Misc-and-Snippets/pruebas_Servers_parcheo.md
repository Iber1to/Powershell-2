# pruebas_Servers_parcheo.ps1

Versión de **pruebas** del informe de cumplimiento de parcheo de servidores (baseline 'Informe parcheo Servidores').

## Cómo funciona
Igual que `ComplianceUpdateServersResume.ps1`: lee por WMI el estado de la baseline y arma un objeto por dispositivo (DeviceName, ResourceID, ComplianceState, Domain, Build, SO) para volcarlo a CSV. Aquí en modo banco de pruebas.

## Tecnología
SCCM / ConfigMgr · export CSV.

## Notas
La versión consolidada está en `01-SCCM-ConfigMgr/Software-Updates/ComplianceUpdateServersResume.ps1`.
