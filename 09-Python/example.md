# example.py

Mini **servidor HTTP** de ejemplo que sirve un fichero XML con el `Content-Type` correcto.

## Cómo funciona
Extiende `SimpleHTTPRequestHandler` para que, al pedir `/folder_config.xml`, responda con `Content-type: application/xml` y el contenido del fichero. Escucha en el puerto 8000.

## Tecnología
`http.server` / `socketserver`.

## Notas
Útil como banco de pruebas local para servir configuraciones XML a otro script/agente.
