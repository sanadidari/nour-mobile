import os
from PIL import Image, ImageChops

SOURCE = "assets/tempon"
DEST = "assets/images/huissiers"

if not os.path.exists(DEST):
    os.makedirs(DEST)

def trim_to_portrait(img):
    # On cherche le premier cadre non blanc
    # Le portrait est dans un cadre gris avec un fond clair autour
    bg = Image.new("RGB", img.size, (255, 255, 255))
    diff = ImageChops.difference(img.convert("RGB"), bg)
    bbox = diff.getbbox()
    if not bbox:
        return img
    
    left, top, right, bottom = bbox
    # Le portrait est un carré à gauche. On prend la hauteur comme référence pour la largeur.
    portrait_size = bottom - top
    # On ajuste un peu pour enlever la bordure grise si nécessaire
    return img.crop((left, top, left + portrait_size, bottom))

files = [f for f in os.listdir(SOURCE) if f.lower().endswith(('.png', '.jpg'))]

for f in files:
    try:
        img = Image.open(os.path.join(SOURCE, f))
        portrait = trim_to_portrait(img)
        num = f.split('.')[0]
        portrait.save(f"{DEST}/huissier_photo_{num}.png")
    except Exception as e:
        print(f"Error {f}: {e}")

print("Cleanup and extraction finished!")
