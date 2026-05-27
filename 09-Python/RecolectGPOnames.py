import os
import csv
import xml.etree.ElementTree as ET

def extract_gpo_info_from_xml(file_path):
    """Extrae el GPOGuid y GPODisplayName de un archivo bkupInfo.xml."""
    tree = ET.parse(file_path)
    root = tree.getroot()

    gpo_guid = root.find('.//{http://www.microsoft.com/GroupPolicy/GPOOperations/Manifest}GPOGuid').text
    gpo_display_name = root.find('.//{http://www.microsoft.com/GroupPolicy/GPOOperations/Manifest}GPODisplayName').text
    
    return gpo_guid, gpo_display_name

def find_bkupinfo_files(root_dir):
    """Recorre una carpeta y subcarpetas buscando archivos bkupInfo.xml."""
    bkupinfo_files = []
    for subdir, _, files in os.walk(root_dir):
        for file in files:
            if file == 'bkupInfo.xml':
                full_path = os.path.join(subdir, file)
                bkupinfo_files.append(full_path)
    return bkupinfo_files

# Ruta de la carpeta que quieres analizar
root_directory = r'C:\Work\Project'

# Encontrar todos los archivos bkupInfo.xml
bkupinfo_files = find_bkupinfo_files(root_directory)

# Lista para almacenar la información extraída
gpo_info_list = []

# Extraer la información de cada archivo bkupInfo.xml
for file_path in bkupinfo_files:
    gpo_guid, gpo_display_name = extract_gpo_info_from_xml(file_path)
    gpo_info_list.append([gpo_guid, gpo_display_name])

# Ruta del archivo CSV de salida
output_csv_path = r'C:\Temp\gpo_info.csv'

# Verificar si la carpeta C:\Temp existe, si no, crearla
output_directory = os.path.dirname(output_csv_path)
if not os.path.exists(output_directory):
    os.makedirs(output_directory)

# Escribir la información en un archivo CSV
with open(output_csv_path, mode='w', newline='') as csv_file:
    csv_writer = csv.writer(csv_file)
    csv_writer.writerow(["GPOGuid", "GPODisplayName"])
    csv_writer.writerows(gpo_info_list)

print(f"Información GPO guardada en: {output_csv_path}")
