import os
import hashlib
import csv

def calculate_file_hash(file_path):
    """Calcula el hash SHA-256 de un archivo para compararlo, omitiendo archivos vacíos."""
    if os.path.getsize(file_path) == 0:
        return None  # Ignorar archivos vacíos
    sha256 = hashlib.sha256()
    with open(file_path, 'rb') as f:
        while chunk := f.read(8192):
            sha256.update(chunk)
    return sha256.hexdigest()

def find_registry_pol_files(root_dir):
    """Recorre una carpeta y subcarpetas buscando archivos registry.pol."""
    registry_pol_files = []
    for subdir, _, files in os.walk(root_dir):
        for file in files:
            if file == 'registry.pol':
                full_path = os.path.join(subdir, file)
                registry_pol_files.append(full_path)
    return registry_pol_files

def compare_files(file_list, exclude_hash):
    """Compara los archivos registry.pol por su hash, ignorando archivos vacíos y excluyendo el hash especificado."""
    file_hashes = {}
    duplicates = []

    for file_path in file_list:
        file_hash = calculate_file_hash(file_path)
        if file_hash and file_hash != exclude_hash:  # Excluir archivos con el hash especificado
            if file_hash in file_hashes:
                duplicates.append((file_hashes[file_hash], file_path))
            else:
                file_hashes[file_hash] = file_path

    return duplicates

# Ruta de la carpeta que quieres analizar
root_directory = 'C:\Work\Project'

# Hash del archivo que quieres excluir
exclude_file_hash = '5bb1f21f806938a043563024b13b33d74a2b95b767c5f81bde8456e9d0413a89'

# Encontrar todos los archivos registry.pol
registry_pol_files = find_registry_pol_files(root_directory)

# Comparar los archivos encontrados
duplicates = compare_files(registry_pol_files, exclude_file_hash)

# Ruta del archivo CSV de salida
output_csv_path = 'C:\\Temp\\gpoduplicadas.csv'

# Escribir los resultados en un archivo CSV
if duplicates:
    with open(output_csv_path, mode='w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow(["Archivo Original", "Archivo Duplicado"])
        for original, duplicate in duplicates:
            csv_writer.writerow([original, duplicate])
    print(f"Archivos duplicados guardados en: {output_csv_path}")
else:
    print("No se encontraron archivos duplicados.")