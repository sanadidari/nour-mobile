import os
import re
import codecs

dart_file = 'c:/src/nour/lib/models/huissiers_data.dart'
assets_dir = 'c:/src/nour/assets/images/huissiers'

with codecs.open(dart_file, 'r', encoding='utf-8') as f:
    text = f.read()

def replacer(match):
    original = match.group(0)
    filename = match.group(1)
    
    m = re.search(r'huissier_(\d+)\.png', filename)
    if not m: return original
    
    num = m.group(1)
    
    new_name_png = f'huissier_photo_{num}.png'
    new_name_jpeg = f'huissier_photo_{num}.jpeg'
    
    if os.path.exists(os.path.join(assets_dir, new_name_png)):
        return "photoUrl: 'assets/images/huissiers/" + new_name_png + "'"
    elif os.path.exists(os.path.join(assets_dir, new_name_jpeg)):
        return "photoUrl: 'assets/images/huissiers/" + new_name_jpeg + "'"
    else:
        return original

new_text = re.sub(r"photoUrl:\s*'assets/images/huissiers/(.*?)'", replacer, text)

with codecs.open(dart_file, 'w', encoding='utf-8') as f:
    f.write(new_text)

print('Done fixing paths.')
