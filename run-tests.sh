#!/usr/bin/env bash
# Kill any previous test runs
pkill -f "lab-phase" 2>/dev/null || true
pkill -f "lab-all" 2>/dev/null || true
sleep 2

# Clean containers and volumes
docker stop $(docker ps -q) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true
docker volume prune -f 2>/dev/null || true
docker network prune -f 2>/dev/null || true
echo "=== Containers cleaned ==="

# Build patched FreeIPA image in background (needed for phase1 FreeIPA test)
rm -f ~/freeipa-build.log
cd ~/freeipa-patch
nohup bash -c 'docker build -t it-stack-freeipa-patched:almalinux-9 . >> ~/freeipa-build.log 2>&1 && echo "FREEIPA_BUILD_DONE" >> ~/freeipa-build.log || echo "FREEIPA_BUILD_FAILED" >> ~/freeipa-build.log' > /dev/null 2>&1 &
echo "=== FreeIPA image building in background (PID=$!) ==="
cd ~

# Strip CRLF from scripts
for f in ~/lab-phase*.sh; do sed -i "s/\r//" "$f"; done

# Run all phases sequentially — skip FreeIPA initially (image still building)
rm -f ~/lab-all.log
nohup bash -c '
set +e
echo ">> PHASE 1 START $(date)" >> ~/lab-all.log
bash ~/lab-phase1.sh --skip-freeipa >> ~/lab-all.log 2>&1
echo ">> PHASE 1 DONE $(date)" >> ~/lab-all.log

echo ">> PHASE 2 START $(date)" >> ~/lab-all.log
bash ~/lab-phase2.sh >> ~/lab-all.log 2>&1
echo ">> PHASE 2 DONE $(date)" >> ~/lab-all.log

echo ">> PHASE 3 START $(date)" >> ~/lab-all.log
bash ~/lab-phase3.sh >> ~/lab-all.log 2>&1
echo ">> PHASE 3 DONE $(date)" >> ~/lab-all.log

echo ">> PHASE 4 START $(date)" >> ~/lab-all.log
bash ~/lab-phase4.sh >> ~/lab-all.log 2>&1
echo ">> PHASE 4 DONE $(date)" >> ~/lab-all.log

# Now run FreeIPA — image should be built by now (~15 min build vs full test suite)
echo ">> FREEIPA START $(date)" >> ~/lab-all.log
bash ~/lab-phase1.sh >> ~/lab-all.log 2>&1
echo ">> FREEIPA DONE ALL COMPLETE $(date)" >> ~/lab-all.log
' > /dev/null 2>&1 &
echo "=== Test suite launched (PID=$!) — tail ~/lab-all.log to monitor ==="
