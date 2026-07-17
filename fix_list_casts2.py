import os
import re

lib_dir = r"C:\projects\physio_tracker\Motionplus_app\lib"

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace all `.data ?? []` directly where we missed with the previous regex
    # Be careful not to replace the ones we already did
    if '?? []' in content:
        # Let's target any `snapshot.data ?? []` not followed by `;` or anywhere it still exists
        new_content = content.replace(
            "snapshot.data ?? []",
            "(snapshot.data as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[]"
        )
        
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            fix_file(filepath)
