def procesar_clave_valor(datos):
    # Validación básica
    if not isinstance(datos, dict):
        raise TypeError("La entrada debe ser un diccionario")

    if not all(isinstance(v, (int, float)) for v in datos.values()):
        raise ValueError("Todos los valores deben ser numéricos")

    # 1) Identificar el valor más alto
    valor_maximo = max(datos.values())

    # Claves asociadas al valor más alto (por si hay empate)
    claves_valor_maximo = [
        clave for clave, valor in datos.items()
        if valor == valor_maximo
    ]

    # 2) Crear nueva estructura ordenada de mayor a menor
    datos_ordenados = dict(
        sorted(
            datos.items(),
            key=lambda item: item[1],
            reverse=True
        )
    )

    # 3) Imprimir claves y valores en el nuevo orden
    print("Datos ordenados de mayor a menor:")
    for clave, valor in datos_ordenados.items():
        print(f"{clave}: {valor}")

    return claves_valor_maximo, datos_ordenados

entrada = {
    "a": 10,
    "b": 5,
    "c": 20,
    "d": 15
}

claves_max, ordenado = procesar_clave_valor(entrada)

print("\nClaves con el valor más alto:", claves_max)