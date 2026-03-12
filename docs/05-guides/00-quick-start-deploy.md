# IT-Stack Quick Start — Deployment Guide

**Document:** 00  
**Location:** `docs/05-guides/00-quick-start-deploy.md`  
**Last Updated:** March 2026

> **Choose your deployment path below.** Both paths lead to the same 20-service IT-Stack platform.  
> The Cloud path is recommended for evaluation, demos, and learning.  
> The On-Premises path is recommended for production use with real users.

---

## Table of Contents

1. [Which Path Should I Choose?](#1-which-path-should-i-choose)
2. [Path A — Cloud: Single Azure VM](#2-path-a--cloud-single-azure-vm-recommended-for-evaluation)
   - [2.1 Provision the VM](#21-provision-the-vm)
   - [2.2 Open Firewall Ports](#22-open-firewall-ports)
   - [2.3 Deploy All Services](#23-deploy-all-services)
   - [2.4 Verify Everything Is Running](#24-verify-everything-is-running)
   - [2.5 Access Your Services](#25-access-your-services)
3. [Path B — On-Premises: 8-Server Production](#3-path-b--on-premises-8-server-production)
   - [3.1 Prepare Servers](#31-prepare-servers)
   - [3.2 Run Ansible Bootstrap](#32-run-ansible-bootstrap)
   - [3.3 Deploy in Phases](#33-deploy-in-phases)
4. [Post-Deployment — Both Paths](#4-post-deployment--both-paths)
5. [Environment Configuration Reference](#5-environment-configuration-reference)

---

## 1. Which Path Should I Choose?

| | Path A — Cloud (Azure VM) | Path B — On-Premises |
|-|--------------------------|---------------------|
| **Best for** | Evaluation, demos, learning, development | Production, real users, air-gapped environments |
| **Infrastructure** | 1 Azure VM (Standard_D4s_v4) | 8 physical or virtual servers |
| **Setup time** | ~30 minutes | 2–4 hours |
| **Monthly cost** | ~$105/month (16 hrs/day) | Hardware capital + power/cooling |
| **Services** | 12–20 via Docker Compose | All 20 via Ansible |
| **TLS/SSL** | Self-signed / NSG-exposed ports | Let's Encrypt via Traefik |
| **Identity** | Keycloak standalone | Keycloak + FreeIPA LDAP |
| **HA** | No (single point of failure) | Yes (service pairs) |
| **Disk** | 64 GB minimum | Per-server sizing (see §3.1) |

> **Current live environment:** Path A is running right now at `4.154.17.25`.  
> See [18-azure-lab-deployment.md](18-azure-lab-deployment.md) for live environment status.

---

## 2. Path A — Cloud: Single Azure VM *(Recommended for evaluation)*

### Prerequisites

- Azure subscription (Azure for Students works — $100 credit)
- Azure CLI installed: `winget install Microsoft.AzureCLI` (Windows) or `brew install azure-cli` (Mac)
- SSH key pair: `ssh-keygen -t ed25519 -f ~/.ssh/id_itstack`

---

### 2.1 Provision the VM

```powershell
# Log in
az login

# Variables — edit these
$RG     = "rg-it-stack-phase1"
$REGION = "westus2"
$VM     = "lab-single"
$SIZE   = "Standard_D4s_v4"   # 4 vCPU / 16 GB — stays within Azure Student 6-vCPU quota
$IMAGE  = "Ubuntu2404"
$ADMIN  = "itstack"
$SSH_KEY = "$HOME/.ssh/id_itstack.pub"

# Create resource group
az group create --name $RG --location $REGION

# Create VM (Ubuntu 24.04, SSH key auth, 64 GB OS disk)
az vm create `
  --resource-group $RG `
  --name $VM `
  --size $SIZE `
  --image $IMAGE `
  --admin-username $ADMIN `
  --ssh-key-values $SSH_KEY `
  --os-disk-size-gb 64 `
  --public-ip-sku Standard `
  --authentication-type ssh

# Get the public IP
$VM_IP = (az vm show -d -g $RG -n $VM --query publicIps -o tsv)
Write-Host "VM created. IP: $VM_IP"
Write-Host "SSH: ssh $ADMIN@$VM_IP"

# Set auto-shutdown at 22:00 UTC (saves ~33% compute cost)
az vm auto-shutdown -g $RG -n $VM --time 2200
```

> **Note:** The VM takes ~2 minutes to boot. Wait before SSHing.

---

### 2.2 Open Firewall Ports

```powershell
$NSG = "$VM-nsg"

# Web UI ports for all active services
$tcpPorts = @(
  8080,   # Traefik dashboard
  8180,   # Keycloak SSO
  8265,   # Mattermost
  8280,   # Nextcloud
  8302,   # SuiteCRM
  8303,   # Odoo
  8305,   # Snipe-IT
  8307,   # Zabbix
  8380,   # Zammad
  8880,   # Jitsi Meet
  9001,   # Taiga
  9002,   # Graylog
  25,     # SMTP (inbound)
  143,    # IMAP
  587     # SMTP submission
)

$priority = 1000
foreach ($p in $tcpPorts) {
    az network nsg rule create `
        --resource-group $RG `
        --nsg-name $NSG `
        --name "Allow-TCP-$p" `
        --priority $priority `
        --protocol Tcp `
        --destination-port-ranges $p `
        --access Allow `
        --direction Inbound | Out-Null
    Write-Host "Opened TCP :$p"
    $priority++
}

# Jitsi video bridge — UDP (required for WebRTC video)
az network nsg rule create `
    --resource-group $RG `
    --nsg-name $NSG `
    --name "Allow-UDP-10000" `
    --priority 1900 `
    --protocol Udp `
    --destination-port-ranges 10000 `
    --access Allow `
    --direction Inbound | Out-Null

Write-Host "All ports opened. VM is accessible at http://${VM_IP}:<port>"
```

---

### 2.3 Deploy All Services

SSH into the VM and run the full deployment script. This deploys all 13 services in the correct order with health-check waits between each.

```bash
# 1 — SSH to the VM (replace IP with yours)
ssh itstack@4.154.17.25

# 2 — Download and run the deployment script
curl -fsSL https://raw.githubusercontent.com/it-stack-dev/it-stack-installer/main/deploy-single-vm.sh \
  -o ~/deploy.sh

# OR copy from local if you have the repo:
# scp c:\IT-Stack\it-stack-dev\scripts\setup\deploy-stack-services.sh itstack@4.154.17.25:~/deploy.sh

chmod +x ~/deploy.sh
bash ~/deploy.sh 2>&1 | tee ~/deploy.log
```

**What the script does (in order):**

| Step | Service | Container | Port | Wait |
|------|---------|-----------|------|------|
| 1 | Docker network | `it-stack-demo` | — | instant |
| 2 | docker-mailserver | `mail-demo` | 25/587/143 | 30s |
| 3 | Traefik | `traefik-demo` | 8080 | 10s |
| 4 | Keycloak + Nginx proxy | `keycloak-demo`, `keycloak-proxy` | 8180 | 90s |
| 5 | Nextcloud + PostgreSQL | `nc-demo`, `nc-db` | 8280 | 120s |
| 6 | Mattermost + PostgreSQL | `mm-demo`, `mm-db` | 8265 | 90s |
| 7 | SuiteCRM + MariaDB | `crm-demo`, `crm-db` | 8302 | 120s |
| 8 | Odoo + PostgreSQL | `odoo-demo`, `odoo-db` | 8303 | 60s |
| 9 | Snipe-IT + MySQL | `snipe-demo`, `snipe-db` | 8305 | 90s |
| 10 | Jitsi (4 containers) | `jitsi-*` | 8880 / UDP 10000 | 30s |
| 11 | Taiga (3 containers) | `taiga-*` | 9001 | 60s |
| 12 | Zabbix (3 containers) | `zabbix-*` | 8307 | 60s |
| 13 | Graylog (3 containers) | `graylog-*` | 9002 | 90s |

**Total deployment time: ~15–20 minutes**

> **Zammad** requires 64 GB disk. It is deployed last and only if `df -h /` shows > 10 GB free.

**Enable Nextcloud apps (57 pre-configured apps for a physical security company profile):**

```bash
# After Nextcloud is up (~2 min after deploy completes)
curl -fsSL https://raw.githubusercontent.com/it-stack-dev/it-stack-installer/main/install-nc-apps.sh \
  -o ~/install-nc-apps.sh
bash ~/install-nc-apps.sh 2>&1 | tee ~/nc-apps.log
```

---

### 2.4 Verify Everything Is Running

```bash
# Full status check
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | sort

# Check for any exited containers
docker ps -a --filter status=exited --format 'table {{.Names}}\t{{.Status}}\t{{.ExitCode}}'

# Disk usage (should be < 85% for stable operation)
df -h /

# Test HTTP response for each service
for url in \
  "http://localhost:8080/ping" \
  "http://localhost:8180/health/live" \
  "http://localhost:8280/status.php" \
  "http://localhost:8265/api/v4/system/ping" \
  "http://localhost:8302" \
  "http://localhost:8303/web/database/manager" \
  "http://localhost:8305" \
  "http://localhost:8307" \
  "http://localhost:8880" \
  "http://localhost:9001" \
  "http://localhost:9002/api/system/lbstatus"; do
  code=$(curl -o /dev/null -s -w "%{http_code}" --connect-timeout 5 "$url")
  echo "$code  $url"
done
```

Expected: all return `200` or `302`.

---

### 2.5 Access Your Services

Replace `4.154.17.25` with your VM's public IP.

| Service | URL | Username | Password | Notes |
|---------|-----|----------|----------|-------|
| **Nextcloud** | http://4.154.17.25:8280 | admin | Lab02Password! | Files, Calendar, Chat |
| **Mattermost** | http://4.154.17.25:8265 | admin@itstack.local | Lab02Password! | Team chat |
| **Keycloak** | http://4.154.17.25:8180 | admin | *(see ENV)* | SSO admin |
| **SuiteCRM** | http://4.154.17.25:8302 | admin | Admin01! | CRM |
| **Odoo ERP** | http://4.154.17.25:8303 | admin | admin | DB: `testdb` |
| **Snipe-IT** | http://4.154.17.25:8305 | admin | Lab01Password! | Asset management |
| **Zabbix** | http://4.154.17.25:8307 | Admin | Lab01Password! | Monitoring |
| **Graylog** | http://4.154.17.25:9002 | admin | Admin01! | Log management |
| **Jitsi Meet** | http://4.154.17.25:8880 | — | guest mode | Video conferencing |
| **Taiga** | http://4.154.17.25:9001 | admin | 123123 | Project management |
| **Traefik** | http://4.154.17.25:8080 | — | — | Reverse proxy dashboard |
| **Zammad** | http://4.154.17.25:8380 | wizard | wizard | Help desk (after disk expand) |

> 🔒 **Change all default passwords** on first login. See [§4 Post-Deployment](#4-post-deployment--both-paths).

---

### 2.6 Expand Disk for Zammad (optional but recommended)

Zammad's asset compilation requires ~1.5 GB free space. If you provisioned the VM with 64 GB in §2.1, Zammad deploys automatically. If you're on a 30 GB disk:

```powershell
# Step 1 — Resize the disk in Azure (PowerShell, no VM restart needed)
$diskName = (az vm show -g $RG -n $VM --query "storageProfile.osDisk.name" -o tsv)
az disk update -g $RG -n $diskName --size-gb 64
```

```bash
# Step 2 — Resize the filesystem on the VM (no reboot needed)
ssh itstack@4.154.17.25 "sudo growpart /dev/sda 1 && sudo resize2fs /dev/root && df -h /"

# Step 3 — Deploy Zammad
ssh itstack@4.154.17.25 "docker compose -f ~/it-stack-labs/zammad/docker-compose.yml up -d"
```

---

## 3. Path B — On-Premises: 8-Server Production

> For detailed step-by-step procedures, see [19-hardware-deployment-guide.md](19-hardware-deployment-guide.md).  
> This section is a condensed executive summary.

### 3.1 Prepare Servers

8 Ubuntu 24.04 LTS servers (physical or VMs):

| Server | Hostname | IP | Min RAM | Min Disk | Services |
|--------|----------|-----|---------|----------|---------|
| Identity | `lab-id1` | 10.0.50.11 | 16 GB | 50 GB | FreeIPA, Keycloak |
| Database | `lab-db1` | 10.0.50.12 | 32 GB | 200 GB | PostgreSQL, Redis, Elasticsearch |
| Collaboration | `lab-app1` | 10.0.50.13 | 24 GB | 500 GB | Nextcloud, Mattermost, Jitsi |
| Communications | `lab-comm1` | 10.0.50.14 | 16 GB | 100 GB | iRedMail, Zammad, Zabbix |
| Proxy | `lab-proxy1` | 10.0.50.15 | 8 GB | 50 GB | Traefik, Graylog |
| VoIP | `lab-pbx1` | 10.0.50.16 | 8 GB | 50 GB | FreePBX |
| Business | `lab-biz1` | 10.0.50.17 | 24 GB | 200 GB | SuiteCRM, Odoo, OpenKM |
| IT Mgmt | `lab-mgmt1` | 10.0.50.18 | 16 GB | 100 GB | Taiga, Snipe-IT, GLPI |

**On each server, run baseline setup:**

```bash
# Run as root on each server
apt-get update && apt-get upgrade -y
apt-get install -y curl wget git python3 python3-pip ca-certificates gnupg
curl -fsSL https://get.docker.com | sh
usermod -aG docker itstack
echo "vm.max_map_count=262144" >> /etc/sysctl.conf && sysctl -p
```

---

### 3.2 Run Ansible Bootstrap

From your Windows control node:

```powershell
# Clone Ansible repo
cd C:\IT-Stack\it-stack-dev\repos\meta
git clone https://github.com/it-stack-dev/it-stack-ansible.git
cd it-stack-ansible

# Edit inventory
notepad inventory/hosts.ini
# Set [identity], [database], [collaboration], etc. with your server IPs

# Create vault secrets file
ansible-vault create vault/secrets.yml
# Enter all passwords (see 05-environment-configuration-reference below)

# Bootstrap all servers (installs Docker, base packages, UFW, NTP)
ansible-playbook -i inventory/hosts.ini --vault-password-file .vault_pass \
  playbooks/bootstrap-all.yml
```

---

### 3.3 Deploy in Phases

```bash
# Phase 1 — Identity & Foundation (deploy first, everything depends on this)
ansible-playbook -i inventory/hosts.ini --vault-password-file .vault_pass \
  playbooks/deploy-phase1.yml
# Services: FreeIPA → PostgreSQL → Redis → Keycloak → Traefik
# Expected time: ~20 minutes

# Phase 2 — Collaboration
ansible-playbook -i inventory/hosts.ini --vault-password-file .vault_pass \
  playbooks/deploy-phase2.yml
# Services: Nextcloud → Mattermost → Jitsi → iRedMail → Zammad
# Expected time: ~30 minutes

# Phase 3 — Communications & Business
ansible-playbook -i inventory/hosts.ini --vault-password-file .vault_pass \
  playbooks/deploy-phase3.yml
# Services: FreePBX → SuiteCRM → Odoo → OpenKM
# Expected time: ~30 minutes

# Phase 4 — IT Management & Observability
ansible-playbook -i inventory/hosts.ini --vault-password-file .vault_pass \
  playbooks/deploy-phase4.yml
# Services: Taiga → Snipe-IT → GLPI → Elasticsearch → Zabbix → Graylog
# Expected time: ~25 minutes

# Verify full stack
ansible all -i inventory/hosts.ini -m ping
make verify-all    # runs health checks on all 20 services
```

---

## 4. Post-Deployment — Both Paths

### Change All Default Passwords

```bash
# Nextcloud admin password
docker exec -u 33 nc-demo php occ user:resetpassword admin

# Mattermost — via UI: http://<IP>:8265 → Main Menu → Account Settings → Security

# SuiteCRM — via UI: Admin → User Management → admin → Edit

# Odoo — via UI: Settings → Users → Administrator → Edit

# Snipe-IT — via UI: Admin → Edit Profile

# Zabbix — via UI: Administration → Users → Admin → Change Password

# Graylog — via UI: System → Users → admin → Edit
```

### Configure SMTP (if using external email)

```bash
# docker-mailserver — add a real mailbox
docker exec mail-demo setup email add admin@yourdomain.com 'YourPassword'
docker exec mail-demo setup email add noreply@yourdomain.com 'YourPassword'

# Update all services to use your domain
# Edit ~/deploy.sh — change MAIL_DOMAIN=itstack.local → yourdomain.com
# Then re-run email configuration sections only
```

### Connect Thunderbird (email client)

See [23-thunderbird-integration.md](23-thunderbird-integration.md) for full step-by-step.

Quick settings:
- **IMAP:** host `4.154.17.25`, port `143`, STARTTLS, username `user@itstack.local`
- **SMTP:** host `4.154.17.25`, port `587`, STARTTLS

### Enable Zabbix Monitoring

```bash
# Install Zabbix Agent 2 on the VM (cloud path)
wget https://repo.zabbix.com/zabbix/7.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_latest+ubuntu24.04_all.deb
sudo apt-get update && sudo apt-get install -y zabbix-agent2
sudo sed -i 's/^Server=.*/Server=127.0.0.1/' /etc/zabbix/zabbix_agent2.conf
sudo systemctl enable --now zabbix-agent2
```

Then in Zabbix web UI: **Configuration → Hosts → Create Host** → add `lab-single` with IP `127.0.0.1`, template `Linux by Zabbix agent`.

### Configure Log Shipping to Graylog

```bash
# Route all Docker container logs to Graylog via GELF
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "log-driver": "gelf",
  "log-opts": {
    "gelf-address": "udp://localhost:12201",
    "tag": "{{.Name}}"
  }
}
EOF
sudo systemctl restart docker

# Note: existing containers need to be recreated to pick up new log driver
# New containers will automatically ship logs to Graylog
```

### Set Up Mattermost Alerts Channel

```bash
# Create webhook in Mattermost: Main Menu → Integrations → Incoming Webhooks
# Channel: #ops-alerts
# Copy the webhook URL, then configure Zabbix:
# Zabbix → Administration → Media types → Create media type
# Type: Webhook, URL: <your mattermost webhook URL>
```

---

## 5. Environment Configuration Reference

### Default Credentials (Change Before Production Use)

| Service | Username | Default Password | Config Location |
|---------|----------|-----------------|----------------|
| Nextcloud | admin | Lab02Password! | ENV: `NEXTCLOUD_ADMIN_PASSWORD` |
| Mattermost | admin@itstack.local | Lab02Password! | ENV: `MM_*` |
| Keycloak | admin | Lab01Password! | ENV: `KEYCLOAK_ADMIN_PASSWORD` |
| SuiteCRM | admin | Admin01! | DB: `suitecrm_config` |
| Odoo | admin | admin | DB: `testdb.res_users` |
| Snipe-IT | admin | Lab01Password! | ENV: `APP_KEY` / artisan |
| Zabbix | Admin | Lab01Password! | DB: `zabbix.users` |
| Graylog | admin | Admin01! | ENV: `GRAYLOG_ROOT_PASSWORD_SHA2` |
| Taiga | admin | 123123 | Django admin |
| Jitsi | — | guest mode | ENABLE_AUTH=1 to require login |
| docker-mailserver | admin@itstack.local | Lab01Password! | `setup email add` |

> ⚠️ These are **lab defaults**. Generate strong unique passwords before real users connect.  
> Use a password manager or `openssl rand -base64 32` to generate.

### Network Ports Summary

| Protocol | Port | Service | Required Open |
|----------|------|---------|--------------|
| TCP | 22 | SSH | Admin only (restrict to IP) |
| TCP | 8080 | Traefik dashboard | Internal or admin only |
| TCP | 8180 | Keycloak | All users |
| TCP | 8265 | Mattermost | All users |
| TCP | 8280 | Nextcloud | All users |
| TCP | 8302 | SuiteCRM | Internal |
| TCP | 8303 | Odoo | Internal |
| TCP | 8305 | Snipe-IT | IT staff |
| TCP | 8307 | Zabbix | IT staff |
| TCP | 8380 | Zammad | Support staff |
| TCP | 8880 | Jitsi Meet | All users |
| TCP | 9001 | Taiga | Project teams |
| TCP | 9002 | Graylog | IT staff |
| TCP | 25 | SMTP inbound | Mail only |
| TCP | 143 | IMAP | Email clients |
| TCP | 587 | SMTP submission | Email clients |
| UDP | 10000 | Jitsi JVB | All users (video calls) |
| UDP | 12201 | Graylog GELF | Internal Docker |
| UDP | 1514 | Graylog Syslog | Internal |

### Docker Network Reference

All containers run on the `it-stack-demo` bridge network:

```bash
# Inspect the network
docker network inspect it-stack-demo | python3 -m json.tool

# See which containers are on the network
docker network inspect it-stack-demo \
  --format '{{range .Containers}}{{.Name}} ({{.IPv4Address}}){{"\n"}}{{end}}'

# Test connectivity between containers
docker exec nc-demo curl -s http://mail-demo:587 -o /dev/null && echo "Mail reachable"
```

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [18-azure-lab-deployment.md](18-azure-lab-deployment.md) | Detailed Azure deployment + live environment reference |
| [19-hardware-deployment-guide.md](19-hardware-deployment-guide.md) | Full step-by-step hardware/on-prem guide |
| [22-gui-walkthrough.md](22-gui-walkthrough.md) | Browser tour of every service UI |
| [17-admin-runbook.md](17-admin-runbook.md) | Day-to-day operations and incident response |
| [21-production-troubleshooting.md](21-production-troubleshooting.md) | Diagnose and fix common issues |
| [23-thunderbird-integration.md](23-thunderbird-integration.md) | Email client setup (IMAP/SMTP/CalDAV/CardDAV) |
| [network-topology.md](../07-architecture/network-topology.md) | Cloud and on-prem network diagrams |

---

*IT-Stack Quick Start Deployment Guide · Version 1.0 · March 2026*
