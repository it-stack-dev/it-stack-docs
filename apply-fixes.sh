#!/usr/bin/env bash
# Apply the three Docker runner fixes to lab scripts on Azure VM
set -e

echo "=== Fix 1: Zammad nginx — curl → wget ==="
python3 - << 'PYEOF'
import re

with open('/home/itstack/lab-phase2.sh', 'r') as f:
    content = f.read()

old = 'test: ["CMD-SHELL", "curl -sf -o /dev/null -w \'%{http_code}\' http://localhost:80/ | grep -qE \'^[23]\'"]'
new = 'test: ["CMD-SHELL", "wget -q -O /dev/null http://localhost:80/ && echo OK || exit 1"]'

if old in content:
    content = content.replace(old, new)
    with open('/home/itstack/lab-phase2.sh', 'w') as f:
        f.write(content)
    print("FIXED: curl replaced with wget in Zammad nginx healthcheck")
elif 'wget -q -O /dev/null http://localhost:80/' in content:
    print("ALREADY FIXED: wget already present in Zammad nginx healthcheck")
else:
    # Try regex approach
    pattern = r'test: \["CMD-SHELL", "curl[^"]*localhost:80/[^"]*"\]'
    match = re.search(pattern, content)
    if match:
        content = re.sub(pattern, 'test: ["CMD-SHELL", "wget -q -O /dev/null http://localhost:80/ && echo OK || exit 1"]', content)
        with open('/home/itstack/lab-phase2.sh', 'w') as f:
            f.write(content)
        print(f"FIXED via regex: replaced '{match.group()}'")
    else:
        print(f"WARNING: Could not locate curl healthcheck. Current healthcheck lines:")
        for i, line in enumerate(content.split('\n')):
            if 'localhost:80' in line or ('zammad' in line.lower() and 'health' in line.lower()):
                print(f"  line {i+1}: {line.strip()}")
PYEOF

echo ""
echo "=== Fix 2: FreePBX — wait_healthy 40x30 → 60x30 (20min → 30min) ==="
python3 - << 'PYEOF'
with open('/home/itstack/lab-phase3.sh', 'r') as f:
    content = f.read()

old = 'wait_healthy "$app" 40 30'
new = 'wait_healthy "$app" 60 30'

if old in content:
    count = content.count(old)
    content = content.replace(old, new)
    with open('/home/itstack/lab-phase3.sh', 'w') as f:
        f.write(content)
    print(f"FIXED: FreePBX wait extended to 30min ({count} occurrence(s) replaced)")
elif 'wait_healthy "$app" 60 30' in content:
    print("ALREADY FIXED: FreePBX wait is already 60x30")
else:
    print("WARNING: wait_healthy pattern not found. Searching for FreePBX wait...")
    for i, line in enumerate(content.split('\n')):
        if 'wait_healthy' in line and ('freepbx' in line.lower() or 'app' in line):
            print(f"  line {i+1}: {line.strip()}")
PYEOF

echo ""
echo "=== Fix 3: Snipe-IT — wait_healthy 24x10 → 48x10 (4min → 8min) ==="
python3 - << 'PYEOF'
with open('/home/itstack/lab-phase4.sh', 'r') as f:
    content = f.read()

old = 'wait_healthy "$app" 24 10'
new = 'wait_healthy "$app" 48 10'

if old in content:
    count = content.count(old)
    content = content.replace(old, new)
    with open('/home/itstack/lab-phase4.sh', 'w') as f:
        f.write(content)
    print(f"FIXED: Snipe-IT wait extended to 8min ({count} occurrence(s) replaced)")
elif 'wait_healthy "$app" 48 10' in content:
    print("ALREADY FIXED: Snipe-IT wait is already 48x10")
else:
    print("WARNING: wait_healthy pattern not found. Searching for snipeit wait...")
    for i, line in enumerate(content.split('\n')):
        if 'wait_healthy' in line and ('snipe' in line.lower() or 'app' in line):
            print(f"  line {i+1}: {line.strip()}")
PYEOF

echo ""
echo "=== Verification ==="
echo "phase2 nginx healthcheck:"
grep -n 'localhost:80' ~/lab-phase2.sh | head -3

echo "phase3 freepbx wait:"
grep -n 'wait_healthy.*app' ~/lab-phase3.sh | head -3

echo "phase4 snipeit wait:"
grep -n 'wait_healthy.*app' ~/lab-phase4.sh | grep -i snipe | head -3
# Fallback: show all app waits in snipeit section
grep -n 'wait_healthy.*app' ~/lab-phase4.sh | head -5

echo ""
echo "ALL FIXES APPLIED SUCCESSFULLY"
