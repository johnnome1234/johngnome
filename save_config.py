import sys
import os

if len(sys.argv) < 4:
    sys.exit(1)

# Group arguments into triplets: section, key, val
args = sys.argv[1:]
triplets = [args[i:i+3] for i in range(0, len(args), 3)]

import os
file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'config.toml')

with open(file_path, 'r') as f:
    lines = f.readlines()

for section, key, value in triplets:
    new_lines = []
    in_section = False
    key_found = False
    
    for line in lines:
        if line.strip().startswith('['):
            if line.strip() == f"[{section}]":
                in_section = True
            else:
                if in_section and not key_found:
                    new_lines.append(f"{key} = {value}\n")
                    key_found = True
                in_section = False
            new_lines.append(line)
            continue
            
        if in_section:
            if "=" in line:
                k = line.split("=")[0].strip()
                if k == key:
                    existing_val = line.split("=")[1].strip()
                    comment = ""
                    if "#" in existing_val and not existing_val.startswith('"'):
                        comment = existing_val[existing_val.find("#"):]
                    elif existing_val.startswith('"') and existing_val.count('"') >= 2:
                        last_quote = existing_val.rfind('"')
                        if "#" in existing_val[last_quote:]:
                            comment = existing_val[existing_val.find("#", last_quote):]
                            
                    indent = line[:line.find(k)]
                    new_lines.append(f"{indent}{key} = {value} {comment}\n" if comment else f"{indent}{key} = {value}\n")
                    key_found = True
                    continue
        new_lines.append(line)
        
    if not key_found:
        if not in_section:
            new_lines.append(f"\n[{section}]\n")
        new_lines.append(f"{key} = {value}\n")
        
    lines = new_lines

with open(file_path, 'w') as f:
    f.writelines(lines)
