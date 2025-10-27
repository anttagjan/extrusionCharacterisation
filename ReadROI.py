import os
from read_roi import read_roi_zip

folder_path = "E:/Films/TimeAlignment/results"

# Liste des fichiers ZIP contenant "cell_death"
zip_files = [f for f in os.listdir(folder_path) if f.endswith('.zip') and 'cell_death' in f]

if not zip_files:
    print("Aucun fichier ZIP contenant 'cell_death' trouvé dans le dossier.")
    exit()

# Affiche la liste avec des indices
print("Fichiers disponibles :")
for i, f in enumerate(zip_files):
    print(f"{i}: {f}")

# Demande à l'utilisateur de choisir un fichier par son numéro
choice = input("\nEntrez le numéro du fichier à analyser : ")

try:
    index = int(choice)
    if index < 0 or index >= len(zip_files):
        print("Numéro invalide.")
        exit()
except ValueError:
    print("Veuillez entrer un nombre valide.")
    exit()

zip_path = os.path.join(folder_path, zip_files[index])
print(f"\nAnalyse du fichier : {zip_files[index]}")

try:
    roi_dict = read_roi_zip(zip_path)
    if not roi_dict:
        print("  - Aucun ROI trouvé")
    else:
        for name, roi in roi_dict.items():
            n_pos = roi.get('nPosition', roi.get('position', None))
            print(f"  ROI: {name}\t→\tnPosition: {n_pos}")
except Exception as e:
    print(f"  ERREUR en lisant le fichier : {e}")

