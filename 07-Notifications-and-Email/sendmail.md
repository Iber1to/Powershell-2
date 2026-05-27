# sendmail.py

Snippet de Python de cuatro líneas que, pese al nombre, **no envía correo**: lista los paquetes pip instalados en el entorno.

## Cómo funciona
Usa `pip.get_installed_distributions()` para imprimir, ordenada, la lista de paquetes y versiones instalados.

## Notas
Es un fragmento suelto de diagnóstico del entorno Python; el nombre del fichero no se corresponde con su contenido. Depende de una API antigua de `pip` (ya retirada en versiones modernas).
