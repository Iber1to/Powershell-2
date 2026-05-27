import http.server
import socketserver

PORT = 8000  # Puerto en el que se ejecutará el servidor

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/folder_config.xml':
            # Cambiar el tipo de contenido a 'application/xml'
            self.send_response(200)
            self.send_header('Content-type', 'application/xml')
            self.end_headers()
            # Cargar y enviar el archivo XML
            with open('folder_config.xml', 'rb') as f:
                self.wfile.write(f.read())
        else:
            # Si la ruta no es '/folder_config.xml', manejar de la forma usual
            return super().do_GET()

# Iniciar el servidor
with socketserver.TCPServer(("", PORT), CustomHandler) as httpd:
    print(f"Sirviendo en el puerto {PORT}")
    httpd.serve_forever()
