# IT-Stack Hardware Deployment Guide

> **Step-by-step guide for deploying IT-Stack on real hardware (or VMs) — 8 Ubuntu 24.04 servers, 20 services, SSO-connected.**  
> **Prerequisites:** 8 servers provisioned, Ubuntu 24.04 LTS installed, SSH access, DNS configured.  
> **Estimated time:** 2–4 hours for the full stack (parallel deployment).

---

## Table of Contents

1. [Pre-Deployment Checklist](#1-pre-deployment-checklist)
2. [Network & DNS Setup](#2-network--dns-setup)
3. [Ansible Inventory & Vault Setup](#3-ansible-inventory--vault-setup)
4. [Phase 1 — Identity & Foundation](#4-phase-1--identity--foundation)
5. [Phase 2 — Collaboration](#5-phase-2--collaboration)
6. [Phase 3 — Communications & Business](#6-phase-3--communications--business)
7. [Phase 4 — IT Management & Observability](#7-phase-4--it-management--observability)
8. [Post-Deployment Verification](#8-post-deployment-verification)
9. [SSL / TLS Configuration](#9-ssl--tls-configuration)
10. [Backup Activation](#10-backup-activation)
11. [Monitoring Activation](#11-monitoring-activation)
12. [User Onboarding](#12-user-onboarding)

---

## 1. Pre-Deployment Checklist

### 1.1 Hardware Requirements

| Server | Hostname | IP | Min RAM | Min CPU | Min Disk | Services |
|--------|----------|-----|---------|---------|----------|----------|
| Identity | `lab-id1` | 10.0.50.11 | 16 GB | 4 vCPU | 50 GB | FreeIPA, Keycloak |
| Database | `lab-db1` | 10.0.50.12 | 32 GB | 8 vCPU | 200 GB | PostgreSQL, Redis, Elasticsearch |
| Collaboration | `lab-app1` | 10.0.50.13 | 24 GB | 6 vCPU | 500 GB | Nextcloud, Mattermost, Jitsi |
| Communications | `lab-comm1` | 10.0.50.14 | 16 GB | 4 vCPU | 100 GB | iRedMail, Zammad, Zabbix |
| Proxy | `lab-proxy1` | 10.0.50.15 | 8 GB | 2 vCPU | 50 GB | Traefik, Graylog |
| VoIP | `lab-pbx1` | 10.0.50.16 | 8 GB | 4 vCPU | 50 GB | FreePBX |
| Business | `lab-biz1` | 10.0.50.17 | 24 GB | 6 vCPU | 200 GB | SuiteCRM, Odoo, OpenKM |
| IT Mgmt | `lab-mgmt1` | 10.0.50.18 | 16 GB | 4 vCPU | 100 GB | Taiga, Snipe-IT, GLPI |

> **Virtualization note:** All servers can be VMs (VMware, Proxmox, KVM, Hyper-V) or bare metal.  
> **Cloud note:** Azure Standard_D4s_v4 (4 vCPU / 16 GB) is sufficient for lab testing. Use Standard_D8s_v4 for production collaboration and database nodes.

### 1.2 OS Setup (All 8 Servers)

```bash
# On each server — run as root or with sudo
# 1. Ensure Ubuntu 24.04 LTS
lsb_release -a

# 2. Update system
apt-get update && apt-get upgrade -y

# 3. Set hostname (replace with server-specific name)
hostnamectl set-hostname lab-id1
echo "10.0.50.11 lab-id1.it-stack.local lab-id1" >> /etc/hosts

# 4. Disable swap (required for Elasticsearch, k8s)
swapoff -a
sed -i '/swap/d' /etc/fstab

# 5. Install base packages
apt-get install -y curl wget git vim htop net-tools nmap ufw fail2ban \
  ca-certificates gnupg lsb-release python3 python3-pip

# 6. Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker itstack
systemctl enable docker

# 7. Set vm.max_map_count (required for Elasticsearch, OpenSearch)
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p

# 8. Configure UFW baseline (from Ansible — see below)
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable
```

### 1.3 SSH Key Distribution

```bash
# On the Ansible control node (your workstation or a jump host)
# Generate key if not exists
ssh-keygen -t ed25519 -f ~/.ssh/it-stack-deploy -C "it-stack-deploy"

# Copy to all servers
for host in 10.0.50.{11..18}; do
  ssh-copy-id -i ~/.ssh/it-stack-deploy.pub itstack@$host
done

# Verify
for host in 10.0.50.{11..18}; do
  ssh -i ~/.ssh/it-stack-deploy itstack@$host hostname
done
```

### 1.4 Pre-flight Checks

```bash
# Run from control node
cat << 'EOF' > /tmp/preflight.sh
#!/bin/bash
for host in lab-id1 lab-db1 lab-app1 lab-comm1 lab-proxy1 lab-pbx1 lab-biz1 lab-mgmt1; do
  ip=$(dig +short $host 2>/dev/null || getent hosts $host | awk '{print $1}')
  if ssh -o ConnectTimeout=5 -i ~/.ssh/it-stack-deploy itstack@$host "docker info" &>/dev/null; then
    echo "✅  $host ($ip) — SSH OK, Docker OK"
  else
    echo "❌  $host ($ip) — UNREACHABLE or Docker not running"
  fi
done
EOF
bash /tmp/preflight.sh
```

---

## 2. Network & DNS Setup

### 2.1 /etc/hosts Entries (All Servers)

Add to `/etc/hosts` on every server (or use your internal DNS):

```
10.0.50.11  lab-id1.it-stack.local    lab-id1
10.0.50.12  lab-db1.it-stack.local    lab-db1
10.0.50.13  lab-app1.it-stack.local   lab-app1
10.0.50.14  lab-comm1.it-stack.local  lab-comm1
10.0.50.15  lab-proxy1.it-stack.local lab-proxy1
10.0.50.16  lab-pbx1.it-stack.local   lab-pbx1
10.0.50.17  lab-biz1.it-stack.local   lab-biz1
10.0.50.18  lab-mgmt1.it-stack.local  lab-mgmt1
```

### 2.2 Service DNS Entries (via FreeIPA DNS after Phase 1)

| Subdomain | CNAME / A | Service |
|-----------|-----------|---------|
| `id.it-stack.local` | lab-id1 | FreeIPA |
| `sso.it-stack.local` | lab-id1 | Keycloak |
| `cloud.it-stack.local` | lab-app1 | Nextcloud |
| `chat.it-stack.local` | lab-app1 | Mattermost |
| `meet.it-stack.local` | lab-app1 | Jitsi |
| `mail.it-stack.local` | lab-comm1 | iRedMail |
| `desk.it-stack.local` | lab-comm1 | Zammad |
| `pbx.it-stack.local` | lab-pbx1 | FreePBX |
| `crm.it-stack.local` | lab-biz1 | SuiteCRM |
| `erp.it-stack.local` | lab-biz1 | Odoo |
| `docs.it-stack.local` | lab-biz1 | OpenKM |
| `pm.it-stack.local` | lab-mgmt1 | Taiga |
| `assets.it-stack.local` | lab-mgmt1 | Snipe-IT |
| `itsm.it-stack.local` | lab-mgmt1 | GLPI |
| `monitor.it-stack.local` | lab-comm1 | Zabbix |
| `logs.it-stack.local` | lab-proxy1 | Graylog |
| `proxy.it-stack.local` | lab-proxy1 | Traefik Dashboard |

### 2.3 Firewall Rules Summary

```bash
# lab-id1 (Identity)
ufw allow from 10.0.50.0/24 to any port 22    # SSH
ufw allow from 10.0.50.0/24 to any port 389   # LDAP
ufw allow from 10.0.50.0/24 to any port 636   # LDAPS
ufw allow from 10.0.50.0/24 to any port 88    # Kerberos
ufw allow from 10.0.50.0/24 to any port 8080  # Keycloak HTTP
ufw allow from 10.0.50.0/24 to any port 8443  # Keycloak HTTPS
ufw allow 80 443                               # Web UI via Traefik

# lab-db1 (Database)
ufw allow from 10.0.50.0/24 to any port 5432  # PostgreSQL
ufw allow from 10.0.50.0/24 to any port 6379  # Redis
ufw allow from 10.0.50.0/24 to any port 9200  # Elasticsearch HTTP
ufw allow from 10.0.50.0/24 to any port 9300  # Elasticsearch cluster

# lab-pbx1 (VoIP)
ufw allow from 10.0.50.0/24 to any port 5060  # SIP TCP/UDP
ufw allow from any to any port 10000:20000/udp # RTP media
```

---

## 3. Ansible Inventory & Vault Setup

### 3.1 Clone the Ansible Repo

```bash
# On the control node
git clone https://github.com/it-stack-dev/it-stack-ansible.git
cd it-stack-ansible
```

### 3.2 Inventory File

Edit `inventory/production.yml`:

```yaml
all:
  children:
    identity:
      hosts:
        lab-id1:
          ansible_host: 10.0.50.11

    database:
      hosts:
        lab-db1:
          ansible_host: 10.0.50.12

    collaboration:
      hosts:
        lab-app1:
          ansible_host: 10.0.50.13

    communications:
      hosts:
        lab-comm1:
          ansible_host: 10.0.50.14

    proxy:
      hosts:
        lab-proxy1:
          ansible_host: 10.0.50.15

    voip:
      hosts:
        lab-pbx1:
          ansible_host: 10.0.50.16

    business:
      hosts:
        lab-biz1:
          ansible_host: 10.0.50.17

    itmanagement:
      hosts:
        lab-mgmt1:
          ansible_host: 10.0.50.18

  vars:
    ansible_user: itstack
    ansible_ssh_private_key_file: ~/.ssh/it-stack-deploy
    ansible_python_interpreter: /usr/bin/python3
```

### 3.3 Vault Setup

```bash
# Create vault password file (keep outside the repo)
echo "YourVaultPasswordHere" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# Create vault secrets file
ansible-vault create group_vars/all/vault.yml --vault-password-file ~/.vault_pass.txt
```

Add these secrets to the vault file:

```yaml
# group_vars/all/vault.yml (encrypted)
vault_pg_password: "ProductionPostgresPassword!"
vault_redis_password: "ProductionRedisPassword!"
vault_keycloak_admin_password: "ProductionKeycloakAdmin!"
vault_freeipa_admin_password: "ProductionFreeIPAAdmin!"
vault_freeipa_ds_password: "ProductionFreeIPADS!"
vault_nextcloud_admin_password: "ProductionNextcloudAdmin!"
vault_mattermost_db_password: "ProductionMattermostDB!"
vault_zammad_db_password: "ProductionZammadDB!"
vault_suitecrm_db_password: "ProductionSuiteCRMDB!"
vault_odoo_admin_password: "ProductionOdooAdmin!"
vault_graylog_secret: "MinimumSixteenCharacterGraylogSecret!"
vault_graylog_sha2: "sha256-of-your-graylog-admin-password"
```

> **Generate SHA256 for Graylog:**  
> ```bash
> echo -n "YourGraylogAdminPassword" | sha256sum
> ```

---

## 4. Phase 1 — Identity & Foundation

> **Duration:** ~45 minutes  
> **Servers:** lab-id1, lab-db1, lab-proxy1  
> **Order is critical:** FreeIPA must be fully running before Keycloak starts LDAP federation.

### 4.1 Traefik (Reverse Proxy) — lab-proxy1

Deploy Traefik first so all other services can get SSL certificates immediately.

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-traefik.yml \
  --vault-password-file ~/.vault_pass.txt \
  -v
```

**Verify:**
```bash
curl -k https://proxy.it-stack.local:8080/api/rawdata | jq '.routers | keys'
# Should return empty list (no services yet)
```

### 4.2 FreeIPA (Identity / LDAP / Kerberos) — lab-id1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-freeipa.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit identity -v
```

**⚠️ This takes 20–30 minutes on first run.** FreeIPA installs a full LDAP + Kerberos + DNS + CA stack.

**Verify:**
```bash
ssh itstack@lab-id1 "ipactl status"
# Expected:
#   Directory Service: RUNNING
#   krb5kdc Service: RUNNING
#   kadmin Service: RUNNING
#   named Service: RUNNING
#   httpd Service: RUNNING

# Test LDAP bind
ssh itstack@lab-id1 "ldapsearch -x -H ldap://localhost -D 'cn=Directory Manager' \
  -w \$(ansible-vault view group_vars/all/vault.yml | grep freeipa_ds | cut -d' ' -f2) \
  -b 'dc=it-stack,dc=local' '(objectClass=organizationalUnit)' dn | head -10"
```

### 4.3 PostgreSQL — lab-db1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-postgresql.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit database -v
```

**Verify:**
```bash
ssh itstack@lab-db1 "psql -U postgres -c '\l'"
# Should list: postgres, template0, template1, plus all it-stack databases
```

### 4.4 Redis — lab-db1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-redis.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit database -v
```

**Verify:**
```bash
ssh itstack@lab-db1 "redis-cli ping"
# Expected: PONG
```

### 4.5 Keycloak (SSO) — lab-id1

> Keycloak must start after FreeIPA is confirmed running.

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-keycloak.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit identity -v
```

**Verify OIDC token:**
```bash
curl -s -X POST https://sso.it-stack.local/realms/master/protocol/openid-connect/token \
  -d 'client_id=admin-cli&grant_type=password' \
  -d "username=admin&password=$(vault view | grep keycloak_admin | cut -d' ' -f2)" \
  | jq -r '.access_token' | cut -c1-40
# Should return beginning of a JWT token
```

**Configure FreeIPA LDAP federation (automated):**
```bash
ansible-playbook -i inventory/production.yml \
  playbooks/configure-sso.yml \
  --vault-password-file ~/.vault_pass.txt -v
```

### 4.6 Phase 1 Verification

```bash
# Run the Phase 1 lab test script against the production servers
# (adjust IPs in the script to point to lab-id1/lab-db1/lab-proxy1)
ssh itstack@lab-id1 "bash ~/lab-phase1.sh"
# Expected: 18/18 PASS
```

---

## 5. Phase 2 — Collaboration

> **Duration:** ~30 minutes  
> **Servers:** lab-app1, lab-comm1  
> **Requires Phase 1 complete:** PostgreSQL and Keycloak must be running.

### 5.1 Nextcloud — lab-app1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-nextcloud.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit collaboration -v
```

**Configure Keycloak OIDC (automated):**
```bash
ansible-playbook -i inventory/production.yml \
  roles/nextcloud/tasks/keycloak-oidc.yml \
  --vault-password-file ~/.vault_pass.txt -v
```

**Verify:**
```bash
curl -sf https://cloud.it-stack.local/status.php | jq '.installed'
# Expected: true
```

### 5.2 Mattermost — lab-app1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-mattermost.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit collaboration -v
```

**Verify:**
```bash
curl -sf https://chat.it-stack.local/api/v4/system/ping | jq '.status'
# Expected: "OK"
```

### 5.3 Jitsi Meet — lab-app1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-jitsi.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit collaboration -v
```

**Verify:**
```bash
curl -sf https://meet.it-stack.local | grep -qi "Jitsi" && echo "OK"
```

### 5.4 iRedMail — lab-comm1

> ⚠️ iRedMail requires a clean, dedicated server. Do not run on a server with existing mail services.

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-iredmail.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit communications -v
```

**Post-install DNS records required:**
```
# Add these to your external DNS (MX / SPF / DKIM)
@     MX  10  mail.it-stack.local.
mail  A       10.0.50.14
@     TXT     "v=spf1 mx -all"
mail._domainkey  TXT  "v=DKIM1; k=rsa; p=<get from /etc/opendkim/keys/>"
```

### 5.5 Zammad — lab-comm1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-zammad.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit communications -v
```

**Verify:**
```bash
curl -sf https://desk.it-stack.local/api/v1/monitoring/health_check | jq '.healthy'
# Expected: true
```

---

## 6. Phase 3 — Communications & Business

> **Duration:** ~40 minutes  
> **Servers:** lab-pbx1, lab-biz1  
> **Requires Phase 2 complete.**

### 6.1 FreePBX — lab-pbx1

> ⚠️ FreePBX first-run installs 100+ Asterisk modules. Expect 15–30 minutes.

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-freepbx.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit voip -v
```

**SIP trunk configuration:**
After FreePBX is running, open the admin panel at `https://pbx.it-stack.local/admin/`:
1. **Admin → User Management** — sync with FreeIPA LDAP
2. **Connectivity → Trunks** — add your SIP provider
3. **Connectivity → Inbound Routes** — configure DID routing

### 6.2 SuiteCRM — lab-biz1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-suitecrm.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit business -v
```

**Configure Keycloak SAML:**
```bash
ansible-playbook -i inventory/production.yml \
  roles/suitecrm/tasks/keycloak-saml.yml \
  --vault-password-file ~/.vault_pass.txt -v
```

### 6.3 Odoo — lab-biz1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-odoo.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit business -v
```

**Post-install modules to activate:**
Open `https://erp.it-stack.local`, go to **Apps**, and install:
- `account` (Accounting)
- `sale` (Sales)
- `purchase` (Purchase)
- `inventory` (Inventory)
- `hr` (Human Resources)
- `project` (Project)

### 6.4 OpenKM — lab-biz1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-openkm.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit business -v
```

**Verify:**
```bash
curl -sf -u admin:admin https://docs.it-stack.local/OpenKM/services/rest/info | jq '.version'
```

---

## 7. Phase 4 — IT Management & Observability

> **Duration:** ~45 minutes  
> **Servers:** lab-mgmt1, lab-proxy1 (Graylog), lab-comm1 (Zabbix)  
> **Requires Phase 3 complete.**

### 7.1 Elasticsearch — lab-db1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-elasticsearch.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit database -v
```

### 7.2 Zabbix — lab-comm1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-zabbix.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit communications -v
```

**Register all 8 hosts:**
```bash
ansible-playbook -i inventory/production.yml \
  roles/zabbix/tasks/register-hosts.yml \
  --vault-password-file ~/.vault_pass.txt -v
# This auto-registers all 8 IT-Stack servers with the Linux template and TCP port checks
```

### 7.3 Graylog — lab-proxy1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-graylog.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit proxy -v
```

**Configure log inputs (automated):**
```bash
ansible-playbook -i inventory/production.yml \
  roles/graylog/tasks/configure-inputs.yml \
  --vault-password-file ~/.vault_pass.txt -v
# Creates: Syslog UDP :1514, GELF UDP :12201, GELF HTTP :12202, 8 streams
```

### 7.4 Taiga — lab-mgmt1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-taiga.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit itmanagement -v
```

### 7.5 Snipe-IT — lab-mgmt1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-snipeit.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit itmanagement -v
```

### 7.6 GLPI — lab-mgmt1

```bash
ansible-playbook -i inventory/production.yml \
  playbooks/deploy-glpi.yml \
  --vault-password-file ~/.vault_pass.txt \
  --limit itmanagement -v
```

---

## 8. Post-Deployment Verification

### 8.1 Full Integration Test

```bash
# Run the SSO integration test script
# (copy lab-sso-integrations.sh to lab-id1 and execute)
scp it-stack-dev/scripts/testing/lab-sso-integrations.sh itstack@lab-id1:~/
ssh itstack@lab-id1 'nohup bash ~/lab-sso-integrations.sh > ~/lab-sso.log 2>&1 &'
# Monitor
watch -n 30 "ssh itstack@lab-id1 'grep -cE \"\[PASS\]\" ~/lab-sso.log; grep -cE \"\[FAIL\]\" ~/lab-sso.log'"
# Expected: 35 PASS, 0 FAIL
```

### 8.2 Service Status Dashboard

```bash
cat << 'EOF' > /tmp/check-all.sh
#!/bin/bash
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
check() {
  local name=$1 url=$2
  code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)
  if [[ "$code" =~ ^[23] ]]; then
    echo -e "${GREEN}✅  $name${NC} — HTTP $code"
  else
    echo -e "${RED}❌  $name${NC} — HTTP $code"
  fi
}
check "Traefik Dashboard"  "https://proxy.it-stack.local:8080/api/rawdata"
check "FreeIPA Web UI"     "https://id.it-stack.local/ipa/ui/"
check "Keycloak"           "https://sso.it-stack.local/realms/master"
check "Nextcloud"          "https://cloud.it-stack.local/status.php"
check "Mattermost"         "https://chat.it-stack.local/api/v4/system/ping"
check "Jitsi"              "https://meet.it-stack.local"
check "iRedMail"           "https://mail.it-stack.local"
check "Zammad"             "https://desk.it-stack.local/api/v1/monitoring/health_check"
check "FreePBX"            "https://pbx.it-stack.local/admin/config.php"
check "SuiteCRM"           "https://crm.it-stack.local"
check "Odoo"               "https://erp.it-stack.local/web/health"
check "OpenKM"             "https://docs.it-stack.local/OpenKM/"
check "Taiga"              "https://pm.it-stack.local/api/v1/"
check "Snipe-IT"           "https://assets.it-stack.local/login"
check "GLPI"               "https://itsm.it-stack.local"
check "Zabbix"             "https://monitor.it-stack.local"
check "Graylog"            "https://logs.it-stack.local/api/system/lbstatus"
EOF
bash /tmp/check-all.sh
```

### 8.3 SSO Smoke Test

1. Open `https://sso.it-stack.local` — log in with your FreeIPA admin account
2. Open `https://cloud.it-stack.local` — click "Login with SSO" — should redirect to Keycloak and back
3. Open `https://chat.it-stack.local` — "Login with SSO" — should use same session
4. Open `https://erp.it-stack.local` — SSO login should work seamlessly

---

## 9. SSL / TLS Configuration

### 9.1 Internal CA via Traefik

```bash
# Activate TLS on all services via Ansible
ansible-playbook -i inventory/production.yml \
  playbooks/tls-setup.yml \
  --vault-password-file ~/.vault_pass.txt -v
```

### 9.2 Let's Encrypt (Public Domain)

If your IT-Stack is on a public domain (e.g., `company.internal`):

```yaml
# roles/traefik/templates/traefik.yml.j2
certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@yourcompany.com
      storage: /data/acme.json
      httpChallenge:
        entryPoint: web
```

```bash
ansible-playbook -i inventory/production.yml \
  roles/traefik/tasks/configure-letsencrypt.yml \
  --vault-password-file ~/.vault_pass.txt -v
```

---

## 10. Backup Activation

```bash
# Activate automated daily backups
ansible-playbook -i inventory/production.yml \
  playbooks/backup.yml \
  --vault-password-file ~/.vault_pass.txt -v

# Verify backup cron jobs installed
ssh itstack@lab-db1 "crontab -l | grep backup"
# Expected:
# 0 2 * * * /opt/it-stack/backup/backup-postgresql.sh
# 0 3 * * * /opt/it-stack/backup/backup-nextcloud.sh

# Test restore procedure
ansible-playbook -i inventory/production.yml \
  playbooks/test-restore.yml \
  --vault-password-file ~/.vault_pass.txt -v
# Expected: all databases restore to staging with object count verification
```

---

## 11. Monitoring Activation

```bash
# Install Zabbix agents on all 8 servers
ansible-playbook -i inventory/production.yml \
  roles/zabbix/tasks/register-hosts.yml \
  --vault-password-file ~/.vault_pass.txt -v

# Configure Graylog log collection
ansible-playbook -i inventory/production.yml \
  roles/graylog/tasks/configure-inputs.yml \
  --vault-password-file ~/.vault_pass.txt -v

# Set up Mattermost alert channel
# 1. Create #ops-alerts channel in Mattermost
# 2. Create an incoming webhook URL in Mattermost admin
# 3. Add webhook URL to vault:
ansible-vault edit group_vars/all/vault.yml
# Add: vault_mattermost_webhook_url: "https://chat.it-stack.local/hooks/xxxxx"

# Deploy alert integrations
ansible-playbook -i inventory/production.yml \
  roles/zabbix/tasks/mattermost-alerts.yml \
  roles/graylog/tasks/zabbix-alerts.yml \
  --vault-password-file ~/.vault_pass.txt -v
```

---

## 12. User Onboarding

### 12.1 Create First User

```bash
# Add user in FreeIPA (propagates to all SSO-connected services automatically)
ssh itstack@lab-id1 "kinit admin"
ssh itstack@lab-id1 "ipa user-add jdoe \
  --first=John --last=Doe \
  --email=jdoe@it-stack.local \
  --password"
```

### 12.2 Assign Groups

```bash
# Add to standard groups
ssh itstack@lab-id1 "ipa group-add-member it-staff --users=jdoe"
ssh itstack@lab-id1 "ipa group-add-member nextcloud-users --users=jdoe"
```

### 12.3 User Self-Service

Share the [User Onboarding Guide](16-user-onboarding.md) with all new users. It covers:
- Activating their SSO account
- Accessing Nextcloud (files + calendar)
- Setting up Mattermost (chat)
- Joining a Jitsi video call
- Submitting a Zammad support ticket

---

## Appendix: Common Deployment Issues

| Issue | Symptom | Fix |
|-------|---------|-----|
| FreeIPA install hangs at 25 min | `ipactl: Directory Service not running` | Check RAM: needs 2 GB free. Run `free -h` |
| Keycloak can't reach FreeIPA LDAP | `LDAP connection refused` | Verify FreeIPA LDAP port 389 open: `nc -zv lab-id1 389` |
| PostgreSQL connection refused | `psql: could not connect` | Check `pg_hba.conf` has `host all all 10.0.50.0/24 scram-sha-256` |
| Nextcloud "503 Service Unavailable" | No response on 443 | Traefik routing not configured; run `deploy-nextcloud.yml` again |
| Graylog stuck starting | Never shows ALIVE in lbstatus | Disk full or insufficient RAM; needs 4 GB free for journal (`df -h`, `free -h`) |
| Jitsi video not working | Audio only, no video | UDP port 10000 not open; `ufw allow 10000/udp` on lab-app1 |
| iRedMail emails bouncing | 550 sender verification failure | Add SPF record; verify MX points to lab-comm1 |
| FreePBX admin page blank | Empty response | Still initializing; wait 20 more minutes. Check `docker logs freepbx-s01-app` |

See [Production Troubleshooting Guide](21-production-troubleshooting.md) for comprehensive troubleshooting.

---

*Document version: 1.0 — 2026-03-11 — IT-Stack Hardware Deployment Guide*
