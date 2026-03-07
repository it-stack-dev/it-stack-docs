# 18 — Azure Lab Deployment Guide

> **Purpose:** Step-by-step instructions for deploying and running IT-Stack labs on Microsoft Azure using the provided PowerShell automation scripts.
> **Audience:** Engineers and students running IT-Stack labs from a Windows workstation.
> **Prerequisites:** Azure subscription with sufficient credit (Azure Student works), Windows with PowerShell 5.1+ (or 7+), Azure CLI, SSH.

---

## Overview: Three Deployment Profiles

| Profile | VM(s) | Size | RAM | Daily Cost | Labs | Use Case |
|---------|--------|------|-----|-----------|------|----------|
| **Phase1** | 1 VM | Standard_D4s_v4 | 16 GB | ~$1.50 / day | 01–03 | First-time setup, Azure Student start |
| **FullStack** | 1 VM | Standard_E16s_v4 | 128 GB | ~$8 / day | 01–05 | All 20 modules, integration testing |
| **Lab06HA** | 8 VMs | per-server | varies | ~$16 / day | 01–06 | Production HA, Ansible playbooks, DR drills |

> **Azure Student ($100 credit):**  
> - Phase1 → ~65 days of 8-hour sessions  
> - FullStack → ~12 days of 8-hour sessions  
> - Lab06HA → use sparingly — 1–2 full sessions for Lab 06
>
> **Azure Student vCPU quota:** Student subscriptions in westus2 are typically limited to 6 vCPUs. Phase1 uses `Standard_D4s_v4` (4 vCPUs) to stay within this limit. Do not use `Standard_D8s_v4` (8 vCPUs) — deployment will fail with a quota error.

---

## Prerequisites

### 1. Install Azure CLI (Windows)

```powershell
# Download and install from Microsoft
winget install Microsoft.AzureCLI

# Verify
az --version
```

Or download directly: <https://aka.ms/installazurecliwindows>

### 2. Log In to Azure

```powershell
az login
# A browser window opens — sign in with your Azure/student account

# Verify subscription (note the subscriptionId)
az account show
az account list --output table
```

### 3. Generate an SSH Key (if you don't have one)

```powershell
# Check if one already exists
Test-Path "$HOME\.ssh\id_rsa.pub"

# If not, generate one:
ssh-keygen -t rsa -b 4096 -f "$HOME\.ssh\id_rsa" -N '""'

# View the public key (the script uploads this to Azure)
Get-Content "$HOME\.ssh\id_rsa.pub"
```

### 4. Clone the Installer Repo

```powershell
git clone https://github.com/it-stack-dev/it-stack-installer.git
cd it-stack-installer
```

---

## Profile 1: Phase1 — Foundation Labs (Labs 01–03)

### What Gets Created

| Resource | Value |
|----------|-------|
| Resource Group | `rg-it-stack-phase1` |
| VM | `lab-single` (Standard_D4s_v4, 64 GB disk — 4 vCPU / 16 GB RAM) |
| Private IP | `10.0.50.10` |
| Public IP | Yes (assigned to lab-single) |
| OS | Ubuntu 24.04 LTS |
| Auto-shutdown | 22:00 UTC daily |
| Software pre-installed | Docker, Docker Compose v2, Ansible, git, IT-Stack repos |

**Phase 1 modules covered:** FreeIPA · Keycloak · PostgreSQL · Redis · Traefik

### Deploy

```powershell
cd it-stack-installer\scripts\azure

# Deploy (~ 10–15 minutes)
.\deploy-azure-lab.ps1 -Profile Phase1

# Preview without creating anything:
.\deploy-azure-lab.ps1 -Profile Phase1 -DryRun
```

### SSH Access

```powershell
# The script prints the public IP at the end, e.g. 20.10.50.123
ssh itstack@<PUBLIC_IP>
```

### Run Phase 1 Labs

After SSH-ing into the VM:

```bash
# ── Upload and run the Phase 1 standalone lab suite ──────────────────────────
# (from your Windows machine — run before SSH, or paste into a terminal)
# scp path/to/it-stack-dev/scripts/testing/lab-phase1.sh itstack@<IP>:~/lab-phase1.sh

# On the VM: run all 5 Phase 1 modules (without FreeIPA for a quick ~3-min run)
bash ~/lab-phase1.sh --skip-freeipa

# Run everything including FreeIPA (~20-25 min total — FreeIPA installs on first boot)
bash ~/lab-phase1.sh
```

**Expected output (all pass):**

```
>> Lab 02-01 — Keycloak Standalone
  [PASS] Keycloak HTTP endpoint responds (HTTP 302)
  [PASS] Keycloak admin login and OIDC token issued
  [PASS] Keycloak /health/ready: UP

>> Lab 03-01 — PostgreSQL Standalone
  [PASS] PostgreSQL pg_isready: accepting connections
  [PASS] PostgreSQL CRUD: CREATE TABLE + INSERT + SELECT
  [PASS] PostgreSQL multi-db: appdb and testdb created

>> Lab 04-01 — Redis Standalone
  [PASS] Redis PING: PONG
  [PASS] Redis SET/GET key-value
  [PASS] Redis LPUSH/LLEN list operations
  [PASS] Redis AOF persistence enabled

>> Lab 18-01 — Traefik Standalone
  [PASS] Traefik /ping: OK
  [PASS] Traefik dashboard API: HTTP 200
  [PASS] Traefik file provider: 'whoami' router loaded
  [PASS] Traefik reverse proxy: request routed to whoami backend

>> Lab 01-01 — FreeIPA Standalone
  [PASS] FreeIPA ipactl status: services running
  [PASS] FreeIPA LDAP bind: Directory Manager authenticated
  [PASS] FreeIPA Kerberos: admin kinit succeeded
  [PASS] FreeIPA web UI reachable (HTTP 301)

All Phase 1 standalone lab tests PASSED!
```

> **Note — Traefik Docker provider (Docker 29.x):** Docker Engine 29.x raised the minimum accepted client API version from 1.24 to 1.40. Traefik v3.x defaults to API 1.24 for initial negotiation, causing Docker label discovery to fail on this VM. Lab 01 validates routing via the file provider instead (equivalent functionality). Docker label discovery is tested in Lab 02+ where the Docker daemon version is controlled.

For Labs 02 and 03, see the individual lab guides in `docs/labs/`.

### Cost Control

```powershell
# Stop VMs (pay only for disk — ~$0.05/day): 
.\teardown-azure-lab.ps1 -StopOnly -ResourceGroup rg-it-stack-phase1

# Start VMs again:
.\teardown-azure-lab.ps1 -StartAll -ResourceGroup rg-it-stack-phase1

# Delete everything (free all resources):
.\teardown-azure-lab.ps1 -DeleteAll -ResourceGroup rg-it-stack-phase1
```

### Estimated Costs (Azure Student)

| Activity | Duration | Cost |
|----------|----------|------|
| Deploy + 8hr session (D4s_v4) | 1 day | ~$1.55 |
| Stop overnight (disk only) | 16 hrs | ~$0.05 |
| 1 week (8hrs/day, stopped overnight) | 7 days | ~$11.20 |
| Delete between sessions | — | $0.00 |

> **Standard_D4s_v4** (4 vCPU / 16 GB) costs ~$0.192/hr in westus2 as of 2026.

---

## Profile 2: FullStack — All 20 Modules (Labs 01–05)

### What Gets Created

| Resource | Value |
|----------|-------|
| Resource Group | `rg-it-stack-fullstack` |
| VM | `lab-single` (Standard_E16s_v4, 128 GB disk) |
| Private IP | `10.0.50.10` |
| Public IP | Yes |
| Auto-shutdown | 22:00 UTC daily |
| Software pre-installed | Docker, Docker Compose v2, Ansible, git, IT-Stack repos |

**All 20 modules** run as Docker containers on this single powerful VM.

### Deploy

```powershell
cd it-stack-installer\scripts\azure

# Deploy (~ 15–20 minutes)
.\deploy-azure-lab.ps1 -Profile FullStack
```

### SSH Access

```powershell
ssh itstack@<PUBLIC_IP>
```

### Run All Labs

```bash
cd ~/it-stack-installer

# ── Run Phase 1 labs ──────────────────────────────────────────────────────────
bash scripts/run-phase1-labs.sh

# ── Run Phase 2 labs (Nextcloud, Mattermost, Jitsi, iRedMail, Zammad) ─────────
bash scripts/run-phase2-labs.sh

# ── Run Phase 3 labs (FreePBX, SuiteCRM, Odoo, OpenKM) ───────────────────────
bash scripts/run-phase3-labs.sh

# ── Run Phase 4 labs (Taiga, Snipe-IT, GLPI, Elasticsearch, Zabbix, Graylog) ──
bash scripts/run-phase4-labs.sh

# ── Or run everything at once (Labs 01–05 for all 20 modules) ─────────────────
bash scripts/test-all-modules.sh

# ── Run a specific lab (e.g. Nextcloud SSO integration — Lab 06-04) ───────────
bash tests/labs/06-04-sso.sh
```

### Lab Numbering Quick Reference

| Module | # | Lab 01 | Lab 04 (SSO) |
|--------|---|--------|-------------|
| FreeIPA | 01 | `01-01-standalone.sh` | `01-04-sso.sh` |
| Keycloak | 02 | `02-01-standalone.sh` | `02-04-sso.sh` |
| PostgreSQL | 03 | `03-01-standalone.sh` | — |
| Nextcloud | 06 | `06-01-standalone.sh` | `06-04-sso.sh` |
| Mattermost | 07 | `07-01-standalone.sh` | `07-04-sso.sh` |
| ... | ... | ... | ... |

Full lab index: see [LAB_MANUAL_STRUCTURE.md](../../LAB_MANUAL_STRUCTURE.md)

### Cost Control

```powershell
.\teardown-azure-lab.ps1 -StopOnly  -ResourceGroup rg-it-stack-fullstack
.\teardown-azure-lab.ps1 -StartAll  -ResourceGroup rg-it-stack-fullstack
.\teardown-azure-lab.ps1 -DeleteAll -ResourceGroup rg-it-stack-fullstack
```

### Estimated Costs

| Activity | Duration | Cost |
|----------|----------|------|
| Deploy + 8hr session | 1 day | ~$8.00 |
| 1 week (8hrs/day) | 7 days | ~$56.00 |
| Azure Student $100 budget | — | ~12 full days |

---

## Profile 3: Lab06HA — Production HA (8-VM Cluster)

### What Gets Created

8 Ubuntu 24.04 VMs matching the production server layout:

| VM | IP | Size | Disk | Role |
|----|-----|------|------|------|
| lab-id1 | 10.0.50.11 | Standard_D4s_v4 | 64 GB | FreeIPA, Keycloak |
| lab-db1 | 10.0.50.12 | Standard_E8s_v4 | 100 GB | PostgreSQL, Redis, Elasticsearch |
| lab-app1 | 10.0.50.13 | Standard_D8s_v4 | 128 GB | Nextcloud, Mattermost, Jitsi |
| lab-comm1 | 10.0.50.14 | Standard_D4s_v4 | 64 GB | iRedMail, Zammad, Zabbix |
| **lab-proxy1** | **10.0.50.15** | Standard_D2s_v4 | 64 GB | **Traefik, Graylog ← Public IP** |
| lab-pbx1 | 10.0.50.16 | Standard_D2s_v4 | 64 GB | FreePBX |
| lab-biz1 | 10.0.50.17 | Standard_D8s_v4 | 100 GB | SuiteCRM, Odoo, OpenKM |
| lab-mgmt1 | 10.0.50.18 | Standard_D4s_v4 | 64 GB | Taiga, Snipe-IT, GLPI |

**Resource Group:** `rg-it-stack-lab06`  
**Only `lab-proxy1` gets a public IP.** All other VMs are private, accessible via SSH jump.  
**Private DNS zone:** `lab.it-stack.local` with A records + service aliases (`cloud.`, `chat.`, `meet.`, etc.)

### Deploy

```powershell
cd it-stack-installer\scripts\azure

# Deploy (~ 30–45 minutes for all 8 VMs)
.\deploy-azure-lab.ps1 -Profile Lab06HA
```

### SSH Access

```powershell
# Entry point — public IP on lab-proxy1 (Traefik / Graylog)
ssh itstack@<PUBLIC_IP_OF_LAB_PROXY1>

# Jump to identity server (FreeIPA / Keycloak)
ssh -J itstack@<PUBLIC_IP> itstack@10.0.50.11

# Jump to database server (PostgreSQL / Redis / ES)
ssh -J itstack@<PUBLIC_IP> itstack@10.0.50.12

# Jump to app server (Nextcloud / Mattermost / Jitsi)
ssh -J itstack@<PUBLIC_IP> itstack@10.0.50.13

# Jump via ~/.ssh/config (recommended for repeated use — see below)
ssh lab-id1
```

#### Recommended ~/.ssh/config

Add this to `~/.ssh/config` on your Windows machine (adjust the public IP):

```
Host lab-proxy1
    HostName <PUBLIC_IP>
    User itstack
    IdentityFile ~/.ssh/id_rsa

Host lab-id1
    HostName 10.0.50.11
    User itstack
    ProxyJump lab-proxy1
    IdentityFile ~/.ssh/id_rsa

Host lab-db1
    HostName 10.0.50.12
    User itstack
    ProxyJump lab-proxy1
    IdentityFile ~/.ssh/id_rsa

Host lab-app1
    HostName 10.0.50.13
    User itstack
    ProxyJump lab-proxy1
    IdentityFile ~/.ssh/id_rsa

Host lab-comm1
    HostName 10.0.50.14
    User itstack
    ProxyJump lab-proxy1
    IdentityFile ~/.ssh/id_rsa

Host lab-pbx1
    HostName 10.0.50.16
    User itstack
    ProxyJump lab-proxy1
    IdentityFile ~/.ssh/id_rsa

Host lab-biz1
    HostName 10.0.50.17
    User itstack
    ProxyJump lab-proxy1
    IdentityFile ~/.ssh/id_rsa

Host lab-mgmt1
    HostName 10.0.50.18
    User itstack
    ProxyJump lab-proxy1
    IdentityFile ~/.ssh/id_rsa
```

### Run Lab 06 — Ansible Deployment

Lab 06 is driven by Ansible from your **Windows control machine** (or from lab-proxy1).

#### Option A: Run Ansible from Windows (recommended)

```powershell
# Clone the Ansible repo
git clone https://github.com/it-stack-dev/it-stack-ansible.git
cd it-stack-ansible

# Step 1: Update the inventory with the lab IPs
notepad inventory\hosts.ini
# Set ansible_host for each server to its private IP
# Set ansible_ssh_common_args='-o ProxyJump=itstack@<PUBLIC_IP>'
```

`inventory/hosts.ini`:

```ini
[identity]
lab-id1   ansible_host=10.0.50.11

[database]
lab-db1   ansible_host=10.0.50.12

[collaboration]
lab-app1  ansible_host=10.0.50.13

[communications]
lab-comm1 ansible_host=10.0.50.14

[proxy]
lab-proxy1 ansible_host=10.0.50.15

[voip]
lab-pbx1  ansible_host=10.0.50.16

[business]
lab-biz1  ansible_host=10.0.50.17

[management]
lab-mgmt1 ansible_host=10.0.50.18

[all:vars]
ansible_user=itstack
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump=itstack@<PUBLIC_IP>'
```

```powershell
# Step 2: Test connectivity to all 8 nodes
ansible all -m ping

# Step 3: Configure secrets
copy vault\secrets.yml.example vault\secrets.yml
# Edit vault/secrets.yml — set passwords for all services
ansible-vault encrypt vault\secrets.yml

# Step 4: CIS hardening (SSH config, firewall, kernel hardening)
make harden

# Step 5: Deploy internal TLS (CA + per-host certificates)
make tls

# Step 6: Deploy Phase 1 — identity and database layer
make deploy-phase1
# Deploys: FreeIPA → Keycloak → PostgreSQL (all service DBs) → Redis → Traefik

# Step 7: Deploy Phase 2 — collaboration
make deploy-phase2
# Deploys: Nextcloud → Mattermost → Jitsi → iRedMail → Zammad

# Step 8: Deploy Phase 3 — back office
make deploy-phase3
# Deploys: FreePBX → SuiteCRM → Odoo → OpenKM

# Step 9: Deploy Phase 4 — IT management and observability
make deploy-phase4
# Deploys: Taiga → Snipe-IT → GLPI → Elasticsearch → Zabbix → Graylog

# Step 10: Configure backup schedules
make backup-setup

# Step 11: Smoke test all services
make smoke-test
```

#### Option B: Run Ansible from lab-proxy1

```bash
ssh itstack@<PUBLIC_IP>
cd ~/it-stack-ansible
# Edit inventory/hosts.ini (no proxy needed — all IPs are local)
# Set ansible_host directly to 10.0.50.xx IPs

ansible all -m ping
make deploy-phase1
# ... etc
```

#### Expected Deployment Timeline

| Step | Duration | What Happens |
|------|----------|-------------|
| `make harden` | 10 min | SSH config, UFW rules, sysctl tuning, fail2ban on all 8 nodes |
| `make tls` | 5 min | Internal CA creation, certs issued per host |
| `make deploy-phase1` | 20–30 min | FreeIPA realm, Keycloak realm, 10 PostgreSQL databases, Redis, Traefik |
| `make deploy-phase2` | 25–35 min | Nextcloud, Mattermost, Jitsi, iRedMail, Zammad + SSO wiring |
| `make deploy-phase3` | 20–30 min | FreePBX, SuiteCRM, Odoo, OpenKM + integrations |
| `make deploy-phase4` | 20–30 min | Taiga, Snipe-IT, GLPI, Elasticsearch, Zabbix, Graylog |
| **Total** | **~2 hours** | Full production-equivalent stack |

### Verify Services

After deployment, verify each service via the private DNS zone (internal VNet):

| Service | URL | Credentials |
|---------|-----|-------------|
| FreeIPA | `https://ipa.lab.it-stack.local/ipa/ui/` | admin / (vault secret) |
| Keycloak | `https://lab-id1:8443/admin/` | admin / (vault secret) |
| Nextcloud | `https://cloud.lab.it-stack.local/` | SSO via Keycloak |
| Mattermost | `https://chat.lab.it-stack.local/` | SSO via Keycloak |
| Zammad | `https://desk.lab.it-stack.local/` | SSO via Keycloak |
| Traefik Dashboard | `https://proxy.lab.it-stack.local:8080/` | admin / (vault secret) |
| Zabbix | `https://lab-comm1:3000/` | Admin / (vault secret) |
| Graylog | `https://lab-proxy1:9000/` | admin / (vault secret) |

> **Note:** These URLs work from within the VNet. For external access, use SSH tunneling or update Traefik routing rules.

### SSH Tunnel for Browser Access

```powershell
# Tunnel Nextcloud to localhost:8443 for browser testing
ssh -L 8443:10.0.50.13:443 itstack@<PUBLIC_IP>

# Then browse http://localhost:8443 (accept self-signed cert)
```

### Cost Control

```powershell
# Stop all 8 VMs (zero compute cost)
.\teardown-azure-lab.ps1 -StopOnly -ResourceGroup rg-it-stack-lab06

# Start all 8 VMs
.\teardown-azure-lab.ps1 -StartAll -ResourceGroup rg-it-stack-lab06

# Delete everything
.\teardown-azure-lab.ps1 -DeleteAll -ResourceGroup rg-it-stack-lab06
```

### Estimated Costs

| Activity | Duration | Cost |
|----------|----------|------|
| Full 8-VM cluster, 8hr session | 1 day | ~$16.00 |
| Stop overnight (disks only) | 16 hrs | ~$0.40 |
| 2 full Lab 06 sessions | 2 days | ~$32.00 |
| Azure Student $100 budget | — | ~6 full sessions |

> **Recommendation:** Use Lab06HA for focused 1–2 day Lab 06 sessions only. Use Phase1 or FullStack for daily development work.

---

## Common Operations

### Check Azure Costs

```powershell
# Check current billing period spend
az consumption usage list --billing-period-name $(Get-Date -Format "yyyyMM") `
    --query "[?contains(instanceName,'it-stack')]" `
    --output table

# Check resource costs for a specific RG
az cost management query --type Usage `
    --dataset-filter "{\"dimensions\":[{\"name\":\"ResourceGroupName\",\"operator\":\"In\",\"values\":[\"rg-it-stack-phase1\"]}]}" `
    --output table
```

### List All IT-Stack VMs

```powershell
az vm list --query "[?contains(name,'lab-')]" --output table
```

### Resize a VM

```powershell
# Stop first
az vm deallocate --resource-group rg-it-stack-phase1 --name lab-single

# Resize
az vm resize --resource-group rg-it-stack-phase1 --name lab-single `
    --size Standard_E16s_v4

# Start
az vm start --resource-group rg-it-stack-phase1 --name lab-single
```

### Take a Snapshot Before Risky Changes

```powershell
# Create OS disk snapshot
$diskId = az vm show -g rg-it-stack-phase1 -n lab-single `
    --query "storageProfile.osDisk.managedDisk.id" -o tsv

az snapshot create --resource-group rg-it-stack-phase1 `
    --name "snap-lab-single-$(Get-Date -Format 'yyyyMMdd')" `
    --source $diskId

# List snapshots
az snapshot list --resource-group rg-it-stack-phase1 --output table
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `az login` opens wrong account | Multiple accounts | `az account set --subscription <id>` |
| VM creation fails with "quota exceeded" | Azure Student limits to 6 vCPUs in westus2 | Script defaults to `Standard_D4s_v4` (4 vCPUs). Do NOT use D8s_v4 (8 vCPUs) on Student subs. |
| SSH timeout | VM still starting | Wait 2–3 min and retry |
| SSH "connection refused" | VM auto-shutdown triggered | `.\teardown-azure-lab.ps1 -StartAll` |
| Docker not ready after SSH | Cloud-init still running | `journalctl -u cloud-final --no-pager -n 50` |
| `ansible: command not found` on VM | Cloud-init incomplete | Wait 5 min, then `sudo apt-get install -y ansible-core` |
| Lab test fails: "port 443 not open" | Traefik not running | `docker compose -f docker/docker-compose.standalone.yml up -d` |
| Traefik Docker provider error: "client version 1.24 is too old" | Docker 29.x raised min API to 1.40; Traefik v3.x defaults to 1.24 | Use file provider for Lab 01 routing tests. Docker label discovery works in controlled environments (Docker ≤ 28.x or patched Traefik). |
| Public IP shows `null` | Pip not yet assigned | Wait 2 min: `az network public-ip show -g <rg> -n pip-lab-single --query ipAddress -o tsv` |
| Multi-VM: can't SSH to internal VMs | ~/.ssh/config not set up | See "SSH Access" section above |
| Ansible ping fails for some nodes | VMs still booting | `az vm wait -g rg-it-stack-lab06 -n lab-id1 --created` |

---

## Quick Reference

```powershell
# ── PHASE 1 (cheapest, start here) ───────────────────────────────────────────
.\deploy-azure-lab.ps1  -Profile Phase1
.\teardown-azure-lab.ps1 -StopOnly  -ResourceGroup rg-it-stack-phase1
.\teardown-azure-lab.ps1 -StartAll  -ResourceGroup rg-it-stack-phase1
.\teardown-azure-lab.ps1 -DeleteAll -ResourceGroup rg-it-stack-phase1

# ── FULL STACK (all 20 modules) ───────────────────────────────────────────────
.\deploy-azure-lab.ps1  -Profile FullStack
.\teardown-azure-lab.ps1 -StopOnly  -ResourceGroup rg-it-stack-fullstack
.\teardown-azure-lab.ps1 -DeleteAll -ResourceGroup rg-it-stack-fullstack

# ── LAB 06 HA (8-VM production cluster) ───────────────────────────────────────
.\deploy-azure-lab.ps1  -Profile Lab06HA
.\teardown-azure-lab.ps1 -StopOnly  -ResourceGroup rg-it-stack-lab06
.\teardown-azure-lab.ps1 -DeleteAll -ResourceGroup rg-it-stack-lab06

# ── PREVIEW BEFORE CREATING ───────────────────────────────────────────────────
.\deploy-azure-lab.ps1 -Profile Phase1    -DryRun
.\deploy-azure-lab.ps1 -Profile FullStack -DryRun
.\deploy-azure-lab.ps1 -Profile Lab06HA   -DryRun
```

---

## Related Documentation

| Document | Location |
|----------|----------|
| Lab Manual Structure | [docs/LAB_MANUAL_STRUCTURE.md](../LAB_MANUAL_STRUCTURE.md) |
| Lab Deployment Plan | [docs/lab-deployment-plan.md](../lab-deployment-plan.md) |
| Architecture Overview | [docs/enterprise-stack-complete-v2.md](../enterprise-stack-complete-v2.md) |
| Ansible Playbooks | [it-stack-ansible/README.md](https://github.com/it-stack-dev/it-stack-ansible) |
| Terraform Alternative | [it-stack-terraform/README.md](https://github.com/it-stack-dev/it-stack-terraform) |
| This Guide Source | `scripts/azure/deploy-azure-lab.ps1` |
| Teardown Script | `scripts/azure/teardown-azure-lab.ps1` |
