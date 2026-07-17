import os
import re

lib_dir = r"C:\projects\physio_tracker\Motionplus_app\lib"

pattern = re.compile(r'(\w+)\s*=\s*snapshot\.data\s*\?\?\s*\[\];')

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if pattern.search(content):
        # We need to replace `final xyz = snapshot.data ?? [];`
        # with `final xyz = (snapshot.data as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];`
        
        # Exception for patient_dashboard where we already did rawSessions
        if 'rawSessions = snapshot.data ?? []' in content:
            # We skip this specific line or just rely on the fact that we fixed it already.
            pass
            
        new_content = re.sub(
            r'=\s*snapshot\.data\s*\?\?\s*\[\];',
            r'= (snapshot.data as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? <Map<String, dynamic>>[];',
            content
        )
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            fix_file(filepath)
