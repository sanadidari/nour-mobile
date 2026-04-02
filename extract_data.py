import fitz
import os

pdf_dir = r"c:\src\nour\pdfs"
img_out_dir = r"c:\src\nour\assets\images\huissiers"

os.makedirs(img_out_dir, exist_ok=True)

print("Demarrage de l'extraction des images de l'annuaire...")
# 1. Extraire les images de l'annuaire
try:
    doc = fitz.open(os.path.join(pdf_dir, "annuaire.pdf"))
    img_idx = 1
    for i in range(len(doc)):
        for img in doc.get_page_images(i):
            xref = img[0]
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            image_ext = base_image["ext"]
            # Conserver uniquement les images de plus de 5 Ko (pour filtrer les petits logos/icones).
            if len(image_bytes) > 5000:
                filepath = os.path.join(img_out_dir, f"huissier_photo_{img_idx}.{image_ext}")
                with open(filepath, "wb") as f:
                    f.write(image_bytes)
                img_idx += 1
    print(f"SUCCES : {img_idx - 1} photos sauvees dans {img_out_dir}.")
except Exception as e:
    print(f"Erreur annuaire: {e}")

# 2. Extraire le texte de la loi 81.03 et du decret
def extract_text(filename, out_filename):
    path = os.path.join(pdf_dir, filename)
    if os.path.exists(path):
        try:
            text_doc = fitz.open(path)
            full_text = []
            for p in text_doc:
                full_text.append(p.get_text())
            out_path = os.path.join(pdf_dir, out_filename)
            with open(out_path, "w", encoding="utf-8") as f:
                f.write("\n".join(full_text))
            
            # Verifier si c'est scanne ou texte natif
            if len("".join(full_text).strip()) < 50:
                print(f"ATTENTION : Le fichier {filename} ressemble a un PDF Scanne (images). Le texte n'a pas pu etre lu nativement.")
            else:
                print(f"SUCCES : Texte deduit de {filename} dans {out_filename}.")
        except Exception as e:
            print(f"Erreur avec {filename}: {e}")

extract_text("loi_81_03.pdf", "loi_81_03.txt")
extract_text("decret.pdf", "decret.txt")
