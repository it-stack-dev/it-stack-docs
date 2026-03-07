# IT-Stack Administrator Runbook

**Document:** 17  
**Location:** `docs/05-guides/17-admin-runbook.md`  
**Last Updated:** March 2026

---

## Overview

This runbook covers day-to-day and incident-response procedures for IT-Stack administrators. All configuration management is done via Ansible. All secrets are in `vault/secrets.yml` (Ansible Vault encrypted).

**Ansible repo:** `C:\IT-Stack\it-stack-dev\repos\meta\it-stack-ansible\`  
**Quick reference:** `make help` from the repo root

---

## Daily Operations Checklist

Run this each morning (automate via Zabbix dashboard):

```bash
# 1. Check all services are healthy
ansible all -i inventory/hosts.ini -m ping

# 2. Check Zabbix dashboard
open https://zabbix.yourdomain.com

# 3. Check Graylog for overnight errors
open https://logs.yourdomain.com

# 4. Verify last night's backups ran
make backup-verify
```

---

## User Management

### Add a New User

```bash
# 1. Connect to FreeIPA server
ssh ansible@lab-id1

# 2. Create user in FreeIPA (replaces manual via all downstream services via LDAP)
sudo ipa user-add jsmith \
  --first="Jane" \
  --last="Smith" \
  --email="jsmith@yourdomain.com" \
  --shell=/bin/bash \
  --password

# 3. Add to relevant groups
sudo ipa group-add-member employees --users=jsmith
sudo ipa group-add-member nextcloud-users --users=jsmith

# 4. Set temporary password (user must change on first login)
sudo ipa user-mod jsmith --password-expiration=now
```

The user is now available in all services via LDAP federation. Services pick up the new user automatically on first login attempt.

**FreePBX extension:** Assign via FreePBX Admin → Applications → Extensions → Add Extension

### Remove a User (Offboarding)

```bash
# 1. Disable account immediately (preserves data)
sudo ipa user-disable jsmith

# 2. End all active Keycloak sessions
# Keycloak Admin → Users → jsmith → Sessions → Logout All

# 3. After data retention period, fully delete
sudo ipa user-del jsmith
```

**Checklist before deletion:**
- [ ] Reassign or export Nextcloud files
- [ ] Transfer Taiga project ownership
- [ ] Archive Zammad tickets
- [ ] Export SuiteCRM contacts
- [ ] Document any asset assignments (Snipe-IT)

### Reset User Password

```bash
# FreeIPA admin web UI: https://ipa.yourdomain.com/ipa/ui
# Or via CLI:
ssh ansible@lab-id1
sudo ipa user-mod jsmith --password
# Enter new temporary password; user must change on next login
```

### Unlock Locked Account (after failed logins)

```bash
ssh ansible@lab-id1
sudo ipa user-unlock jsmith
```

---

## Service Management

### Restart a Service

```bash
# Via Ansible (preferred — idempotent, logs the change)
ansible lab-app1 -i inventory/hosts.ini -b -m systemd -a "name=nextcloud state=restarted"

# Or directly on the host
ssh ansible@lab-app1
sudo systemctl restart nextcloud
sudo systemctl status nextcloud
```

### Deploy a Service Update

```bash
# Update a single service (e.g., Mattermost)
make deploy-mattermost

# Or with --check first to preview changes
ansible-playbook -i inventory/hosts.ini --vault-password-file .vault_pass \
  --check --diff playbooks/deploy-mattermost.yml
```

### Check Service Health

```bash
# All services via Ansible
ansible all -i inventory/hosts.ini -b -m shell -a "systemctl is-active '*' | grep -v 'inactive\|not-found'" 

# Individual services
ssh ansible@lab-app1 'systemctl status nextcloud mattermost nginx'
ssh ansible@lab-db1  'systemctl status postgresql redis-server'
ssh ansible@lab-id1  'systemctl status ipa httpd krb5kdc'
```

---

## Backup & Restore

### Run an Immediate Backup

```bash
make backup              # Full backup: PostgreSQL + Nextcloud + configs
make backup-pg           # PostgreSQL only
```

### Verify Backups

```bash
make backup-verify
# Shows size and integrity check for all backup archives
```

### Restore PostgreSQL Database

```bash
ssh ansible@lab-db1
sudo -u postgres bash

# Restore a single database (pg_restore format)
dropdb nextcloud
createdb nextcloud -O nextcloud
pg_restore -d nextcloud /var/backups/it-stack/postgres/nextcloud_2026-03-07.dump

# Restore full cluster (pg_dumpall format)
# WARNING: This overwrites ALL databases
psql -f /var/backups/it-stack/postgres/pg_dumpall_2026-03-07.sql.gz \
     <(zcat /var/backups/it-stack/postgres/pg_dumpall_2026-03-07.sql.gz)
```

### Restore Nextcloud Files

```bash
ssh ansible@lab-app1

# Enable maintenance mode
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# Restore from backup
sudo rsync -av /var/backups/it-stack/nextcloud/data/ /var/lib/nextcloud/data/

# Re-scan files
sudo -u www-data php /var/www/nextcloud/occ files:scan --all

# Disable maintenance mode
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off
```

---

## TLS Certificate Management

### Check Certificate Expiry Dates

```bash
# Check all service certs on Traefik
ssh ansible@lab-proxy1
for f in /etc/ssl/it-stack/*.crt; do
  echo "$f: $(openssl x509 -noout -enddate -in $f)"
done
```

### Renew Internal CA Certificates

Internal certs expire every 825 days (~2.25 years). Renew proactively when < 60 days remain:

```bash
# Renew all certs and redeploy to Traefik
make tls-certs

# Or renew everything including CA (every 10 years)
make tls
```

---

## Security Incident Response

### Suspected Account Compromise

```bash
# 1. Immediately disable the account
ssh ansible@lab-id1
sudo ipa user-disable <username>

# 2. Force Keycloak session termination
# Keycloak Admin → Users → <username> → Sessions → Logout All

# 3. Check login history
ssh ansible@lab-id1
sudo cat /var/log/dirsrv/slapd-*/access | grep "<username>" | tail -100

# 4. Check for unusual Nextcloud activity
ssh ansible@lab-app1
sudo grep "<username>" /var/log/nextcloud/nextcloud.log | tail -50

# 5. Scan for anomalous SSH connections
ssh ansible@<affected-host>
sudo grep "Accepted\|Failed" /var/log/auth.log | tail -100
sudo ausearch -ua <username> -ts recent   # auditd search

# 6. Change account password, re-enable if cleared
sudo ipa user-enable <username>
sudo ipa user-mod <username> --password
```

### Service Under Attack (DoS / Brute Force)

```bash
# Check fail2ban status
ssh ansible@<target-host>
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Manually ban an IP
sudo fail2ban-client set sshd banip <IP>

# Check UFW blocked traffic
sudo ufw status numbered
sudo tail -f /var/log/syslog | grep UFW
```

### Emergency: Take a Service Offline

```bash
# Traefik route disable — add a maintenance middleware in dynamic config
# Or: completely stop the service
ansible <host> -i inventory/hosts.ini -b -m systemd -a "name=<service> state=stopped"

# Block all traffic to a host (extreme measure)
ansible <host> -i inventory/hosts.ini -b -m community.general.ufw -a "state=disabled"
```

---

## Monitoring & Alerting

### Zabbix — Add a New Host to Monitoring

```bash
# Via Ansible (preferred)
ansible-playbook -i inventory/hosts.ini --vault-password-file .vault_pass \
  playbooks/deploy-zabbix.yml --tags agent --limit <new-host>

# Or manually: Zabbix Web → Configuration → Hosts → Create Host
# Use Template: "Linux by Zabbix agent"
# Interface: agent on port 10050
```

### Silence a Noisy Alert

In Zabbix Web:
1. **Monitoring → Problems** → Find the alert
2. Click the alert → **Acknowledge** → Add comment + check **Suppress problem**
3. Set suppression duration

### Graylog — Create an Alert Rule

1. Open `https://logs.yourdomain.com`
2. **Alerts → Notifications** → Create notification (Mattermost webhook to `#ops-alerts`)
3. **Alerts → Event Definitions** → Create event
   - Filter: `level <= 3` (errors and above)  
   - Series: Count > 0 in 5 minutes
   - Action: Send notification

---

## Scheduled Maintenance Window

Standard procedure for planned maintenance:

```bash
# 1. Send advance notice via Mattermost #general (at least 48h notice)

# 2. Run pre-maintenance backup
make backup

# 3. Enable maintenance mode on Nextcloud
ssh ansible@lab-app1
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# 4. Perform maintenance

# 5. Verify all services are healthy
ansible all -i inventory/hosts.ini -m ping
make backup-verify

# 6. Disable Nextcloud maintenance mode
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

# 7. Post in #general: "Maintenance complete. All services restored."
```

---

## Common Issues & Quick Fixes

| Symptom | First Check | Fix |
|---------|-------------|-----|
| User can't log in | FreeIPA: `ipa user-show <user>` — is account active? | `ipa user-unlock <user>` |
| Nextcloud slow | lab-app1 PHP workers full | Restart PHP-FPM: `systemctl restart php8.3-fpm` |
| Email not delivered | lab-comm1 Postfix queue | `postqueue -p` → `postqueue -f` to flush |
| Mattermost shows 502 | Mattermost service down | `systemctl restart mattermost` |
| Jitsi call drops | JVB UDP ports blocked | Check UFW allows 10000/udp from all |
| Database queries slow | PostgreSQL connections full | Check with `pg_activity` on lab-db1 |
| Keycloak 503 | Keycloak out of memory | `journalctl -u keycloak -n 50` — restart if OOM |
| Traefik cert expired | Check expiry (see TLS section) | `make tls-certs` |
| Disk 90%+ on lab-app1 | Nextcloud data growing | Expand volume + `df -h /var/lib/nextcloud` |
| Zabbix alerts flood | New service added without monitoring config | Configure proper thresholds in Zabbix |

---

## Ansible Vault — Working with Secrets

```bash
# Edit secrets (opens in $EDITOR)
make vault-edit

# View secrets without editing
make vault-view

# Encrypt a new value inline
ansible-vault encrypt_string --vault-password-file .vault_pass 'MySecret' --name 'var_name'
# → Paste output into group_vars or playbook vars

# Re-key vault to new password
ansible-vault rekey --vault-password-file .vault_pass \
  --new-vault-password-file .vault_pass_new vault/secrets.yml
```

---

## Key File Locations (per server)

| Server | Config Paths |
|--------|-------------|
| lab-id1 | FreeIPA: `/etc/ipa/`, `/etc/dirsrv/`, Keycloak: `/etc/keycloak/` |
| lab-db1 | PostgreSQL: `/etc/postgresql/16/main/`, Redis: `/etc/redis/redis.conf` |
| lab-app1 | Nextcloud: `/var/www/nextcloud/`, `/var/lib/nextcloud/data/`, Mattermost: `/opt/mattermost/config/` |
| lab-comm1 | Postfix: `/etc/postfix/`, Dovecot: `/etc/dovecot/`, Zammad: `/etc/zammad/` |
| lab-proxy1 | Traefik: `/etc/traefik/`, Graylog: `/etc/graylog/server/` |
| lab-pbx1 | Asterisk/FreePBX: `/etc/asterisk/`, `/var/lib/asterisk/` |
| lab-biz1 | SuiteCRM: `/var/www/html/suitecrm/`, Odoo: `/etc/odoo/`, OpenKM: `/opt/tomcat/` |
| lab-mgmt1 | GLPI: `/var/www/glpi/`, Snipe-IT: `/var/www/snipeit/`, Taiga: `/opt/taiga/` |

---

*IT-Stack Administrator Runbook · Version 1.0 · March 2026*
