# Obtencion-Buzones-Existe-INT-v2.ps1

Script de **descubrimiento para una migración de AD/Exchange**: comprueba qué buzones del dominio origen **ya existen** en el dominio destino ("INT").

## Cómo funciona
Define el dominio origen y el controlador del dominio destino (`DCINT`), los DN base donde buscar (y los de exclusión), recorre los objetos del origen y comprueba su existencia en el destino, generando un CSV de cruce.

## Tecnología
Active Directory (consultas multi-dominio).

## Notas
Forma parte de la batería de scripts de migración del cliente (dominios anonimizados a `ClientInsurance*`). Los CSV de resultados están en `99-Datasets-Redacted`.
