import os
from PIL import Image

# Configuration
SOURCE_DIR = "assets/screenshots"
OUTPUT_DIR = "assets/images/huissiers"

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

# Liste ordonnée des captures telle que vous les avez envoyées (par date/nom WhatsApp)
# Remplissez ici le nombre de personnes visibles sur chaque screenshot dans l'ordre alphabétique des fichiers
# Selon vos images : 10, 8, 9, 8, 6, 10, 9, 6, 3, 9
PAGE_COUNTS = [10, 8, 9, 8, 6, 10, 9, 6, 3, 9]

def extract_from_screenshot(image_path, start_index, count_on_this_page):
    img = Image.open(image_path)
    width, height = img.size
    
    print(f"Extraction de {count_on_this_page} personnes depuis {os.path.basename(image_path)}...")
    
    extracted = 0
    for i in range(count_on_this_page):
        # CADRAGE AJUSTÉ : On prend plus large pour éviter de couper le haut ou le bas
        # On cible le centre de la zone photo
        left = width * 0.03   # Un peu plus à gauche
        top = height * (0.05 + (i * 0.093)) # On commence plus haut et on ajuste l'écart
        right = width * 0.22  # Un peu plus à droite
        bottom = top + (height * 0.09) # Plus de hauteur
        
        if bottom > height: break
            
        portrait = img.crop((left, top, right, bottom))
        
        # On sauvegarde en PNG pour la transparence
        portrait.save(f"{OUTPUT_DIR}/huissier_photo_{start_index + i}.png")
        extracted += 1
        
    return extracted

files = sorted([f for f in os.listdir(SOURCE_DIR) if f.lower().endswith(('.png', '.jpg', '.jpeg'))])
current_idx = 1

for i, f in enumerate(files):
    if i < len(PAGE_COUNTS):
        num_to_extract = PAGE_COUNTS[i]
        added = extract_from_screenshot(os.path.join(SOURCE_DIR, f), current_idx, num_to_extract)
        current_idx += added
    else:
        print(f"⚠️ Plus de données de comptage pour le fichier {f}")

print(f"✅ Terminé ! {current_idx - 1} portraits extraits proprement.")
