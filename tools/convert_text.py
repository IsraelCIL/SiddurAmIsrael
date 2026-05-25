import json, os

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    changed = False
    for key in ['text', 'default_text']:
        if key in data and isinstance(data[key], str) and '\n' in data[key]:
            data[key] = data[key].split('\n')
            changed = True
    if 'variants' in data and isinstance(data['variants'], dict):
        new_variants = {}
        for k, v in data['variants'].items():
            if isinstance(v, str) and '\n' in v:
                new_variants[k] = v.split('\n')
                changed = True
            else:
                new_variants[k] = v
        if changed:
            data['variants'] = new_variants
    if changed:
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print('Updated:', filepath)

dirs = ['assets/prayers/segments', 'assets/prayers/nusach']
for d in dirs:
    for root, _, files in os.walk(d):
        for fname in files:
            if fname.endswith('.json'):
                process_file(os.path.join(root, fname))
print('Done')
