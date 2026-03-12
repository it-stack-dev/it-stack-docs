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

## Current Live Deployment (March 2026)

> **This section documents the actual running environment** built during the Phase 1–2 cloud lab session. It reflects what is live on the VM as of March 12, 2026. The scripted profiles below remain valid for fresh deployments.

### VM Specifications

| Property | Value |
|----------|-------|
| VM Name | `lab-single` |
| Size | Standard_D4s_v4 (4 vCPU / 16 GB RAM) |
| OS | Ubuntu 24.04 LTS |
| OS Disk | 30 GB — Premium SSD P4 |
| Public IP | `4.154.17.25` (static, Standard SKU) |
| Region | West US 2 |
| Resource Group | `rg-it-stack-phase1` |
| SSH User | `itstack` |
| Auto-shutdown | 22:00 UTC daily |
| Private DNS Zone | `lab.it-stack.local` |
| Docker version | 29.3.0 |
| Docker network | `it-stack-demo` |

```powershell
# Connect
ssh itstack@4.154.17.25
```

---

### Deployed Services & Ports

All services run as Docker containers on the single VM. There is no Traefik routing — each service is directly accessible on its own port via the public IP.

| # | Service | Container(s) | Public Port | Status | Notes |
|---|---------|-------------|------------|--------|-------|
| 18 | Traefik | `traefik-demo` | **:8080** | ✅ Running | Dashboard only (routing not active) |
| 02 | Keycloak | `keycloak-demo`, `keycloak-proxy` | **:8180** | ✅ Running | SSO — admin console |
| 06 | Nextcloud | `nc-demo`, `nc-db` | **:8280** | ✅ Running | 57 apps enabled |
| 07 | Mattermost | `mm-demo`, `mm-db` | **:8265** | ✅ Running | SMTP wired to mail-demo |
| 12 | SuiteCRM | `crm-demo`, `crm-db` | **:8302** | ✅ Running | SMTP via config_override.php |
| 13 | Odoo | `odoo-demo`, `odoo-db` | **:8303** | ✅ Running | DB: `testdb`; SMTP via ir_mail_server |
| 16 | Snipe-IT | `snipe-demo`, `snipe-db` | **:8305** | ✅ Running | 506 fixed (migration marked + re-run) |
| 08 | Jitsi Meet | `it-stack-jitsi-*` (4 containers) | **:8880** | ✅ Running | Guest mode; JVB on UDP :10000 |
| 15 | Taiga | `taiga-front-s01`, `taiga-back-s01`, `taiga-db-s01` | **:9001** | ✅ Running | Backend on :9000 (internal) |
| 19 | Zabbix | `zabbix-web-s01`, `zabbix-srv-s01`, `zabbix-db-s01` | **:8307** | ✅ Running | VM host added; GELF alerts configured |
| 20 | Graylog | `graylog-s01`, `graylog-es-s01`, `graylog-mongo-s01` | **:9002** | ✅ Running | GELF UDP :12201 + Syslog UDP :1514 inputs live |
| — | Mail Server | `mail-demo` | **:25/:587/:143** | ✅ Running | docker-mailserver 14; domain: itstack.local |
| 03 | PostgreSQL | `nc-db`, `mm-db`, `odoo-db`, `snipe-db`... | internal | ✅ Running | Per-service DBs on `it-stack-demo` network |

**Not yet deployed on this VM (pending disk expansion):**

| Service | Reason | Resolution |
|---------|--------|-----------|
| Zammad | 30 GB disk full during JS asset write | Expand OS disk to 64 GB (see [Disk Expansion](#disk-expansion)) |
| FreeIPA | High disk footprint; Keycloak handles SSO standalone | Deploy on separate VM for production |
| FreePBX | Not required for current use case | Phase 3 — deploy on `lab-pbx1` |
| OpenKM | Phase 3 | Deploy on `lab-biz1` |
| GLPI | Phase 4 | Deploy on `lab-mgmt1` |

---

### Service Access URLs

Replace `4.154.17.25` with the current VM public IP if it changes.

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Nextcloud | http://4.154.17.25:8280 | admin / Lab02Password! |
| Mattermost | http://4.154.17.25:8265 | admin@lab.localhost / Lab02Password! |
| SuiteCRM | http://4.154.17.25:8302 | admin / Admin01! |
| Odoo | http://4.154.17.25:8303 | admin / admin (DB: testdb) |
| Snipe-IT | http://4.154.17.25:8305 | admin / Lab01Password! |
| Keycloak | http://4.154.17.25:8180 | admin (see Keycloak env) |
| Traefik | http://4.154.17.25:8080 | No auth |
| Jitsi Meet | http://4.154.17.25:8880 | No login (guest mode) |
| Taiga | http://4.154.17.25:9001 | admin / 123123 (change on first login) |
| Zabbix | http://4.154.17.25:8307 | Admin / Lab01Password! |
| Graylog | http://4.154.17.25:9002 | admin / Admin01! |
| Email Test | http://4.154.17.25:9005 | No auth |

---

### NSG Rules (Azure Network Security Group)

All inbound ports opened on `nsg-it-stack-lab` / `lab-single-nsg`:

```powershell
$RG  = "rg-it-stack-phase1"
$NSG = "lab-single-nsg"

# Web UI ports
$webPorts = @(8080, 8180, 8265, 8280, 8302, 8303, 8305, 8307, 8380, 8880, 9001, 9002, 9005, 8025)
# Infrastructure ports
$infraPorts = @(25, 143, 587, 9200, 10051, 12201, 10000, 4443, 10050, 1514)

foreach ($p in ($webPorts + $infraPorts)) {
    az network nsg rule create --resource-group $RG --nsg-name $NSG `
        --name "Allow-$p" --priority (1000 + $p % 1000) `
        --protocol Tcp --destination-port-ranges $p --access Allow --direction Inbound | Out-Null
}
# Jitsi JVB (UDP)
az network nsg rule create --resource-group $RG --nsg-name $NSG `
    --name "Allow-JVB-UDP" --priority 1900 --protocol Udp `
    --destination-port-ranges 10000 --access Allow --direction Inbound | Out-Null
```

---

### Compose Files Location

Pre-built lab compose files are cloned at `~/it-stack-labs/` on the VM:

```
~/it-stack-labs/
├── jitsi/          docker-compose.yml  → port 8880
├── zammad/         docker-compose.yml  → port 8380  (pending disk expansion)
├── taiga/          docker-compose.yml  → ports 9001/9000
├── zabbix/         docker-compose.yml  → port 8307
└── graylog/        docker-compose.yml  → port 9002
```

Deploy any service:

```bash
# After patching localhost → 4.154.17.25 in the compose file:
VM_IP="4.154.17.25"
sed -i "s|http://localhost:8880|http://$VM_IP:8880|g" ~/it-stack-labs/jitsi/docker-compose.yml

docker compose -f ~/it-stack-labs/<service>/docker-compose.yml up -d
```

---

### Nextcloud — Enabled Apps (57 total)

Configured for a **physical security company** profile. All apps installed via `occ app:install` as user ID 33 (`www-data`):

**Collaboration & Productivity**

| App | Version | Purpose |
|-----|---------|---------|
| calendar | 4.7.20 | Shared calendars, CalDAV |
| contacts | 5.5.4 | Address book, CardDAV |
| tasks | 0.16.1 | Personal & team task lists |
| spreed (Talk) | 18.0.15 | Video calls, group chat, screen share |
| forms | 4.3.7 | Incident report forms, surveys |
| tables | 0.8.10 | Structured data, patrol logs |
| groupfolders | 16.0.15 | Departmental shared drives |

**Security & Identity**

| App | Version | Purpose |
|-----|---------|---------|
| suspicious_login | 6.0.0 | Anomalous login detection |
| twofactor_totp | 10.0.0-beta | TOTP 2FA (Google Auth / Authy) |
| twofactor_backupcodes | 1.17.0 | 2FA backup codes |
| admin_audit | 1.18.0 | Full admin action audit log |
| bruteforcesettings | 2.8.0 | Brute force protection |
| user_ldap | 1.19.0 | LDAP/FreeIPA user sync |
| user_saml | 6.6.1 | SSO & SAML (Keycloak) |
| files_accesscontrol | 1.18.1 | File access policies by group/tag |
| files_automatedtagging | 1.18.0 | Auto-tag files by type/source |

**Field Operations & Tracking**

| App | Version | Purpose |
|-----|---------|---------|
| inventory | 0.1.2 | Equipment / asset tracking |
| maps | 1.4.0 | Site maps, patrol route mapping |
| phonetrack | 0.8.2 | Mobile device tracking (GPS) |
| recognize | 6.1.1 | AI-based image/face recognition |

**SMTP Configuration (Nextcloud)**

```bash
docker exec -u 33 nc-demo php occ config:system:set mail_smtphost --value=mail-demo
docker exec -u 33 nc-demo php occ config:system:set mail_smtpport --value=587
docker exec -u 33 nc-demo php occ config:system:set mail_smtpname --value=admin@itstack.local
docker exec -u 33 nc-demo php occ config:system:set mail_smtppassword --value='Lab01Password!'
docker exec -u 33 nc-demo php occ config:system:set mail_domain --value=itstack.local
```

---

### Snipe-IT 506 Fix (Migration Conflict)

The 506 error was caused by a duplicate index migration (`2018_05_14_223646_add_indexes_to_assets` trying to create `assets_created_at_index` which already existed).

**Fix applied:**

```bash
# 1. Mark the conflicting migration as already run
docker exec snipe-db mysql -u snipeit -pLab02Password! snipeit -e "
  INSERT IGNORE INTO migrations (migration, batch) 
  VALUES ('2018_05_14_223646_add_indexes_to_assets', 999);
"

# 2. Run remaining pending migrations
docker exec snipe-demo php artisan migrate --force

# 3. Create admin user
docker exec snipe-demo php artisan snipeit:create-admin \
  --email=admin@itstack.local \
  --username=admin \
  --first_name=Admin \
  --last_name=ItStack \
  --password='Lab01Password!'
```

**SMTP configuration** — Snipe-IT reads mail settings from environment variables, not the database. The container was recreated with the correct ENV:

```bash
docker run -d --name snipe-demo --restart unless-stopped \
  --network it-stack-demo -p 8305:80 \
  -e MAIL_DRIVER=smtp \
  -e MAIL_HOST=mail-demo \
  -e MAIL_PORT=587 \
  -e MAIL_USERNAME=admin@itstack.local \
  -e MAIL_PASSWORD='Lab01Password!' \
  -e MAIL_FROM_ADDR=no-reply@itstack.local \
  snipe/snipe-it:latest
```

---

### SuiteCRM SMTP Configuration

SuiteCRM uses the Bitnami image. The config override file lives at:

```
/bitnami/suitecrm/public/legacy/config_override.php
```

Applied via:

```bash
docker exec crm-demo bash -c 'cat > /bitnami/suitecrm/public/legacy/config_override.php << EOF
<?php
$sugar_config["site_url"]          = "http://4.154.17.25:8302";
$sugar_config["mail_smtptype"]     = "smtp";
$sugar_config["mail_smtpserver"]   = "mail-demo";
$sugar_config["mail_smtpport"]     = "587";
$sugar_config["mail_smtpauth_req"] = true;
$sugar_config["mail_smtpuser"]     = "admin@itstack.local";
$sugar_config["mail_smtppass"]     = "Lab01Password!";
$sugar_config["mail_smtpssl"]      = "0";
$sugar_config["fromaddress"]       = "crm@itstack.local";
EOF'
```

---

### Odoo SMTP Configuration

Odoo's running database is named `testdb` (created during initial setup). SMTP configured directly via psql:

```bash
docker exec odoo-db psql -U odoo -d testdb << 'SQL'
INSERT INTO ir_mail_server (name, smtp_host, smtp_port, smtp_user, smtp_pass,
  smtp_encryption, sequence, active)
SELECT 'IT-Stack Mail','mail-demo',587,'admin@itstack.local','Lab01Password!',
  'none',1,true
WHERE NOT EXISTS (
  SELECT 1 FROM ir_mail_server WHERE smtp_host='mail-demo'
);
UPDATE ir_config_parameter SET value='odoo@itstack.local'
  WHERE key='mail.default.from';
SQL
```

---

### Graylog — Log Aggregation Setup

Graylog collects logs from all containers. Two inputs were created via the API on startup:

```bash
GL="http://localhost:9002"
GL_PASS="Admin01!"

# GELF UDP input (receives Docker GELF log driver output)
curl -u "admin:$GL_PASS" -X POST "$GL/api/system/inputs" \
  -H "Content-Type: application/json" -H "X-Requested-By: cli" \
  -d '{"title":"GELF UDP","type":"org.graylog2.inputs.gelf.udp.GELFUDPInput",
       "global":true,"configuration":{"bind_address":"0.0.0.0","port":12201}}'

# Syslog UDP input (receives host-level syslog)
curl -u "admin:$GL_PASS" -X POST "$GL/api/system/inputs" \
  -H "Content-Type: application/json" -H "X-Requested-By: cli" \
  -d '{"title":"Syslog UDP","type":"org.graylog2.inputs.syslog.udp.SyslogUDPInput",
       "global":true,"configuration":{"bind_address":"0.0.0.0","port":1514}}'
```

To enable Docker GELF logging for all new containers, edit `/etc/docker/daemon.json`:

```json
{
  "log-driver": "gelf",
  "log-opts": {
    "gelf-address": "udp://localhost:12201",
    "tag": "{{.Name}}"
  }
}
```

Then restart Docker: `sudo systemctl restart docker`

---

### Zabbix — Infrastructure Monitoring Setup

Zabbix is configured with the VM as a monitored host:

```bash
# Auth
ZBX_AUTH=$(curl -sS -X POST "http://localhost:8307/api_jsonrpc.php" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"user.login",
       "params":{"user":"Admin","password":"zabbix"},"id":1}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['result'])")

# Add VM as host
curl -sS -X POST "http://localhost:8307/api_jsonrpc.php" \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"host.create\",\"params\":{
    \"host\":\"lab-vm1\",
    \"name\":\"IT-Stack Azure VM\",
    \"interfaces\":[{\"type\":1,\"main\":1,\"useip\":1,
      \"ip\":\"4.154.17.25\",\"dns\":\"\",\"port\":\"10050\"}],
    \"groups\":[{\"groupid\":\"2\"}]},
    \"auth\":\"$ZBX_AUTH\",\"id\":1}"
```

Zabbix agent (port 10050) must be installed on the VM:

```bash
wget https://repo.zabbix.com/zabbix/7.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_latest+ubuntu24.04_all.deb
sudo apt-get update && sudo apt-get install -y zabbix-agent2
sudo sed -i 's/^Server=.*/Server=127.0.0.1/' /etc/zabbix/zabbix_agent2.conf
sudo systemctl enable --now zabbix-agent2
```

---

### Disk Expansion

The 30 GB OS disk reaches capacity after all Docker images and Nextcloud app files are downloaded. **Zammad requires ~1.5 GB of free space** for its JS asset write and will fail with `no space left on device` on a full disk.

**Step 1 — Expand the Azure managed disk (no VM restart needed):**

```powershell
# Azure Portal → rg-it-stack-phase1 → lab-single_OsDisk → Size + performance → 64 GB
# OR via CLI:
az disk update -g rg-it-stack-phase1 \
  -n lab-single_OsDisk_1_d9b38754900f4165bf0e9673ac477767 \
  --size-gb 64
```

**Step 2 — Extend the partition and filesystem (on the VM, no reboot):**

```bash
# Grow the partition
sudo growpart /dev/sda 1

# Resize the filesystem
sudo resize2fs /dev/root

# Verify
df -h /
```

**Step 3 — Deploy Zammad:**

```bash
docker compose -f ~/it-stack-labs/zammad/docker-compose.yml pull
docker compose -f ~/it-stack-labs/zammad/docker-compose.yml up -d
```

**Quick wins to free space without resizing:**

```bash
# Remove unused Docker images
docker image prune -f

# Remove stopped containers + unused volumes
docker system prune -f

# Specific: remove large unused images
docker rmi elasticsearch:8.17.3   # ~2 GB (Zammad needs ES 8.x — pull again after resize)
docker rmi mailhog/mailhog:latest # ~572 MB (not needed with real mail server)
```

---

### Azure Resource & Cost Summary (March 2026)

| Resource | SKU | Monthly Cost |
|----------|-----|-------------|
| `lab-single` VM @ 16 hrs/day | Standard_D4s_v4 | ~$95 |
| `lab-single_OsDisk` | Premium SSD P4 (30 GB) | ~$5.28 |
| `pip-lab-single` (attached) | Standard Static IP | ~$3.72 |
| `lab.it-stack.local` Private DNS | — | ~$0.50 |
| **Total** | | **~$105/month** |

Auto-shutdown at 22:00 UTC saves ~33% vs 24/7 operation.

**Idle resources to clean up:**

```powershell
# Delete 2 unattached static IPs
az network public-ip delete -g rg-it-stack-phase1 -n vnet-westus2-IPv4
az network public-ip delete -g it-stack -n workspace-1-vnet-IPv4
# Saves: ~$7.44/month

# Bastions (already being deleted — ~$140–$210/month each when active)
az network bastion delete -g rg-it-stack-phase1 -n rg-stack-test1 --no-wait
az network bastion delete -g it-stack -n workspace-1-vnet-bastion --no-wait
```

**Options to stay within Azure Student $100 credit:**

| Action | Monthly Saving |
|--------|---------------|
| Downsize VM to Standard_D2s_v4 (2 vCPU / 8 GB) | ~$47/mo |
| Enforce 8 hr/day usage (auto-shutdown + manual start) | ~$24/mo |
| Switch to Standard SSD E4 (30 GB) | ~$3/mo |
| Delete 2 idle static IPs | ~$7.44/mo |

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
