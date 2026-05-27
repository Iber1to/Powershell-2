# Windows-Form_autogenerate.ps1

Ejemplo de **generación dinámica de objetos a partir de un XML** (`domains.xml`), como paso previo a poblar una interfaz.

## Cómo funciona
Lee `domains.xml`, itera sobre cada elemento `Configuration` y crea un `PSCustomObject` por cada uno, construyendo así la lista de objetos que alimentaría un formulario o un proceso posterior.

## Tecnología
Parsing XML · `PSCustomObject`.

## Notas
Plantilla de referencia para construir estructuras a partir de configuración en XML.
