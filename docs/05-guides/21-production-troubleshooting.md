# IT-Stack Production Troubleshooting Guide

> **Comprehensive reference for diagnosing and resolving issues in a running IT-Stack environment.**  
> For issues encountered during development/testing, see [Complete Issue History](../06-technical-reference/troubleshooting-complete.md).

> **Deployment Context:**  
> - **Cloud Lab VM** (`lab-single` at `4.154.17.25`): all services are Docker containers on a single host. Replace multi-host SSH commands with `ssh itstack@4.154.17.25`. Container names follow the pattern `<service>-demo` or `<service>-s01`.  
> - **On-Prem 8-Server**: services are spread across dedicated hosts (`lab-id1`, `lab-db1`, `lab-app1`...) and managed via Ansible. Use the server-specific sections below directly.

---

## Quick Triage Checklist

When something breaks, run this checklist before deep-diving:

```bash
# 1. What's actually running?
ssh itstack@<server> "docker ps --format 'table {{.Names}}\t{{.Status}}'"

# 2. Any containers exited unexpectedly?
ssh itstack@<server> "docker ps -a --filter status=exited --format 'table {{.Names}}\t{{.Status}}\t{{.ExitCode}}'"

# 3. Is disk full? (Elasticsearch, Graylog, PostgreSQL all stop writing when disk > 95%)
ssh itstack@<server> "df -h / /var/lib/docker"

# 4. Is memory exhausted?
ssh itstack@<server> "free -h; docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}'"

# 5. Firewall blocking something?
ssh itstack@<server> "ufw status numbered"

# 6. Network connectivity between servers?
ssh itstack@lab-app1 "nc -zv lab-db1 5432 && echo 'PGSQL OK' || echo 'PGSQL BLOCKED'"
ssh itstack@lab-app1 "nc -zv lab-id1 389 && echo 'LDAP OK' || echo 'LDAP BLOCKED'"
ssh itstack@lab-app1 "nc -zv lab-id1 8080 && echo 'KEYCLOAK OK' || echo 'KEYCLOAK BLOCKED'"
```

---

## Service-by-Service Troubleshooting

---

### FreeIPA (lab-id1:389/636/88)

#### Symptom: Web UI not loading (404/502)
```bash
ssh itstack@lab-id1 "ipactl status"
# If Directory Service not running:
ssh itstack@lab-id1 "ipactl restart"
# Check httpd specifically:
ssh itstack@lab-id1 "systemctl status httpd"
ssh itstack@lab-id1 "journalctl -u httpd -n 30"
```

#### Symptom: LDAP bind failing ("Invalid credentials" or "Can't contact LDAP server")
```bash
# Test LDAP bind directly
ssh itstack@lab-id1 "ldapsearch -x -H ldap://localhost:389 \
  -D 'uid=admin,cn=users,cn=accounts,dc=it-stack,dc=local' \
  -w YourAdminPassword -b 'dc=it-stack,dc=local' '(objectClass=*)' dn"

# Check if port is listening
ssh itstack@lab-id1 "ss -tlnp | grep :389"

# Restart LDAP specifically
ssh itstack@lab-id1 "ipactl stop; ipactl start"
```

#### Symptom: Kerberos authentication failures ("Credentials cache is empty")
```bash
ssh itstack@lab-id1 "kinit admin"
# If "Cannot contact any KDC for realm IT-STACK.LOCAL":
ssh itstack@lab-id1 "systemctl restart krb5kdc"
ssh itstack@lab-id1 "klist"
```

#### Symptom: FreeIPA DNS not resolving
```bash
ssh itstack@lab-id1 "systemctl status named"
ssh itstack@lab-id1 "dig @localhost lab-db1.it-stack.local"
# If named is down:
ssh itstack@lab-id1 "ipactl restart"
```

#### Symptom: FreeIPA container won't start (cgroupv2 error)
```
Error: /sys/fs/cgroup/memory/memory.limit_in_bytes: No such file or directory
```
**Fix:** Use the patched image:
```bash
docker stop freeipa-s01 2>/dev/null
docker run --name freeipa-s01 \
  --hostname lab-id1.it-stack.local \
  --cgroupns host \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  -v freeipa-data:/data \
  ghcr.io/it-stack-dev/it-stack-freeipa:almalinux-9 \
  ipa-server-install --setup-dns --no-forwarders
```

---

### Keycloak (lab-id1:8080/8443)

#### Symptom: Keycloak login loop / 502 Bad Gateway
```bash
ssh itstack@lab-id1 "docker logs keycloak-s01 --tail 50"
# Common cause: PostgreSQL connection lost
ssh itstack@lab-id1 "docker exec keycloak-s01 \
  curl -sf http://localhost:8080/health/ready | jq .status"
# If database connection error:
ssh itstack@lab-db1 "psql -U keycloak -d keycloak -c 'SELECT 1'"
ssh itstack@lab-id1 "docker restart keycloak-s01"
```

#### Symptom: Keycloak health endpoint returns "DOWN"
```bash
curl -sf http://lab-id1:8080/health/ready | jq .
# Check infinispan cluster (Keycloak distributed cache)
ssh itstack@lab-id1 "docker exec keycloak-s01 \
  /opt/keycloak/bin/kcadm.sh get serverinfo --server http://localhost:8080 \
  --realm master --user admin --password YourPassword"
```

#### Symptom: OIDC token request returning 401
```bash
# Re-test token endpoint
curl -sf -X POST https://sso.it-stack.local/realms/master/protocol/openid-connect/token \
  -d 'client_id=admin-cli&grant_type=password&username=admin&password=YourPass' \
  | jq .error_description

# Check if FreeIPA LDAP federation is healthy
# In Keycloak admin: User Federation → it-stack-ldap → Test connection
```

#### Symptom: Users can't log in via SSO ("User does not exist" in Keycloak)
```bash
# Force LDAP sync
curl -sf -X POST https://sso.it-stack.local/admin/realms/it-stack/user-storage/{id}/sync?action=triggerFullSync \
  -H "Authorization: Bearer $TOKEN"
# Or via admin UI: User Federation → it-stack-ldap → Synchronize all users
```

---

### PostgreSQL (lab-db1:5432)

#### Symptom: Connection refused from application servers
```bash
ssh itstack@lab-db1 "pg_lsclusters"
ssh itstack@lab-db1 "systemctl status postgresql"

# Check pg_hba.conf allows remote connections
ssh itstack@lab-db1 "grep -v '^#' /etc/postgresql/16/main/pg_hba.conf"
# Should have: host all all 10.0.50.0/24 scram-sha-256

# Check postgresql.conf listen_addresses
ssh itstack@lab-db1 "grep listen_addresses /etc/postgresql/16/main/postgresql.conf"
# Should be: listen_addresses = '*'

# Restart if config changed
ssh itstack@lab-db1 "systemctl restart postgresql"
```

#### Symptom: Database disk full
```bash
ssh itstack@lab-db1 "df -h /var/lib/postgresql"
# Check per-database size
ssh itstack@lab-db1 "sudo -u postgres psql -c \
  'SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database ORDER BY 2 DESC'"

# Clean up old WAL files if needed (usually safe after backup)
ssh itstack@lab-db1 "sudo -u postgres psql -c 'SELECT pg_switch_wal()'"
```

#### Symptom: Slow queries (Nextcloud, Odoo performance degraded)
```bash
# Check for long-running queries
ssh itstack@lab-db1 "sudo -u postgres psql -c \
  'SELECT pid, now() - query_start AS duration, query FROM pg_stat_activity \
   WHERE state != '\''idle'\'' ORDER BY duration DESC LIMIT 10'"

# Run VACUUM on heavily updated tables
ssh itstack@lab-db1 "sudo -u postgres psql -d nextcloud -c 'VACUUM ANALYZE'"
```

#### Symptom: Replication lag (if using streaming replication)
```bash
ssh itstack@lab-db1 "sudo -u postgres psql -c \
  'SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn, \
   (sent_lsn - replay_lsn) AS replication_delay FROM pg_stat_replication'"
```

---

### Redis (lab-db1:6379)

#### Symptom: Nextcloud/Mattermost session errors
```bash
ssh itstack@lab-db1 "redis-cli ping"
# If not PONG:
ssh itstack@lab-db1 "docker restart redis-s01"
ssh itstack@lab-db1 "redis-cli info replication"
# Check memory limit
ssh itstack@lab-db1 "redis-cli info memory | grep used_memory_human"
```

#### Symptom: Redis using too much memory
```bash
# Check current maxmemory setting
ssh itstack@lab-db1 "redis-cli config get maxmemory"
# Check eviction policy
ssh itstack@lab-db1 "redis-cli config get maxmemory-policy"
# For session data, use: allkeys-lru
```

---

### Elasticsearch (lab-db1:9200)

#### Symptom: Elasticsearch reports RED cluster health
```bash
ssh itstack@lab-db1 "curl -sf http://localhost:9200/_cluster/health | jq ."
# RED means unassigned shards. Check:
ssh itstack@lab-db1 "curl -sf 'http://localhost:9200/_cluster/allocation/explain' | jq .explanation"

# Common cause: disk > 85% (watermark)
ssh itstack@lab-db1 "df -h /var/lib/docker"

# Temporarily lower watermark if disk is tight
ssh itstack@lab-db1 "curl -X PUT 'http://localhost:9200/_cluster/settings' \
  -H 'Content-Type: application/json' \
  -d '{\"transient\":{\"cluster.routing.allocation.disk.watermark.low\":\"95%\",\"cluster.routing.allocation.disk.watermark.high\":\"97%\"}}'"
```

#### Symptom: vm.max_map_count error on container startup
```
max virtual memory areas vm.max_map_count [65530] is too low
```
**Fix:**
```bash
ssh itstack@lab-db1 "sysctl -w vm.max_map_count=262144"
echo "vm.max_map_count=262144" | ssh itstack@lab-db1 "sudo tee -a /etc/sysctl.conf"
```

---

### Nextcloud (lab-app1:443)

#### Symptom: Maintenance mode (locked out)
```bash
ssh itstack@lab-app1 "docker exec -u www-data nextcloud-s01 \
  php occ maintenance:mode --off"
```

#### Symptom: Files not syncing / can't upload
```bash
# Check available disk space on data directory
ssh itstack@lab-app1 "df -h /var/lib/docker"
# Re-scan files if something is out of sync
ssh itstack@lab-app1 "docker exec -u www-data nextcloud-s01 \
  php occ files:scan --all"
```

#### Symptom: LDAP users not appearing in Nextcloud
```bash
# Re-test LDAP connection in Nextcloud admin panel
# OR trigger LDAP sync via CLI
ssh itstack@lab-app1 "docker exec -u www-data nextcloud-s01 \
  php occ ldap:show-config"
ssh itstack@lab-app1 "docker exec -u www-data nextcloud-s01 \
  php occ ldap:test-config"
```

#### Symptom: Nextcloud background jobs not running (tasks piling up)
```bash
# Check cron job
ssh itstack@lab-app1 "crontab -l | grep nextcloud"
# Should have: */5 * * * * docker exec -u www-data nextcloud-s01 php occ background:cron
# If missing:
ssh itstack@lab-app1 "echo '*/5 * * * * docker exec -u www-data nextcloud-s01 php occ background:cron' | crontab -"
```

---

### Mattermost (lab-app1:8065)

#### Symptom: Mattermost not loading / blank page
```bash
ssh itstack@lab-app1 "docker logs mattermost-s01 --tail 30"
# Check DB connection
ssh itstack@lab-app1 "docker exec mattermost-s01 \
  curl -sf http://localhost:8065/api/v4/system/ping | jq .status"
```

#### Symptom: Push notifications not working
```bash
# Check MPNS (Mobile Push Notification Service) config
ssh itstack@lab-app1 "docker exec mattermost-s01 grep -i push /opt/mattermost/config/config.json | head -5"
# Ensure PushNotificationServer is set to https://push.mattermost.com
```

#### Symptom: Mattermost Zabbix/Graylog alerts not posting
```bash
# Test webhook manually
curl -X POST https://chat.it-stack.local/hooks/YOUR_WEBHOOK_ID \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test alert from Zabbix"}'
# Should return {"id":"...","create_at":...}
# Check if #ops-alerts channel webhook is active in Mattermost admin
```

---

### Traefik (lab-proxy1:80/443)

#### Symptom: 502 Bad Gateway / service unreachable via Traefik
```bash
ssh itstack@lab-proxy1 "docker logs traefik-s01 --tail 30"
# Check router/service status via API
curl -sf http://lab-proxy1:8080/api/http/routers | jq '.[].status'
# Check if backend service is healthy
curl -sf http://lab-proxy1:8080/api/http/services | jq '.[] | {name: .name, health: .serverStatus}'
```

#### Symptom: SSL certificate not renewing
```bash
# Check ACME cert status
ssh itstack@lab-proxy1 "docker exec traefik-s01 cat /data/acme.json | jq '.letsencrypt.Certificates[].domain'"
# Force renewal by removing acme.json and restarting (only if truly expired)
ssh itstack@lab-proxy1 "docker exec traefik-s01 rm /data/acme.json && docker restart traefik-s01"
```

#### Symptom: Traefik not discovering Docker containers (Docker provider)
```bash
# Check API version mismatch (Docker 29.x requires API 1.40+)
ssh itstack@lab-proxy1 "docker exec traefik-s01 \
  curl --unix-socket /var/run/docker.sock http://localhost/v1.40/containers/json" | jq '.[].Names'
# If this returns empty, use file provider instead of Docker provider
```

---

### Graylog (lab-proxy1:9000)

#### Symptom: Graylog web UI slow / unresponsive
```bash
ssh itstack@lab-proxy1 "docker stats graylog-s01 --no-stream"
# Graylog is JVM-based; check heap usage
ssh itstack@lab-proxy1 "docker exec graylog-s01 \
  curl -sf http://localhost:9000/api/system/jvm -u admin:YourPassword | jq .memory"

# Common fix: increase heap or reduce journal size
docker compose -f /opt/graylog/docker-compose.yml \
  exec graylog-s01 \
  grep GRAYLOG_MESSAGE_JOURNAL_MAX_SIZE /etc/environment
# Should be 512mb for labs, 2g for production
```

#### Symptom: Graylog not receiving logs from servers
```bash
# Test syslog input
echo "test log from troubleshooting" | nc -u lab-proxy1 1514
# Check input status in Graylog API
curl -sf http://lab-proxy1:9000/api/system/inputs -u admin:YourPassword | jq '.inputs[].state'
# Should be: "RUNNING" for all inputs
```

#### Symptom: Graylog stored messages not searchable
```bash
# Check Elasticsearch index health from Graylog perspective
curl -sf http://lab-proxy1:9000/api/system/indices/ranges -u admin:YourPassword | jq .
# If indices are in read-only mode (disk full):
curl -X PUT 'http://lab-db1:9200/_settings' \
  -H 'Content-Type: application/json' \
  -d '{"index.blocks.read_only_allow_delete": null}'
```

---

### Zabbix (lab-comm1)

#### Symptom: Hosts showing as unavailable
```bash
ssh itstack@lab-comm1 "docker exec zabbix-server-s01 \
  zabbix_get -s 10.0.50.11 -k agent.ping"
# Should return: 1
# If not: check zabbix-agent service on target host
ssh itstack@lab-id1 "systemctl status zabbix-agent2"
ssh itstack@lab-id1 "systemctl restart zabbix-agent2"
```

#### Symptom: Mattermost alerts not firing
```bash
# Check media type configuration
curl -sf http://lab-comm1:8080/api_jsonrpc.php \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"mediatype.get","params":{"output":"extend"},"auth":"YOUR_AUTH_TOKEN","id":1}' \
  | jq '.[].status'
# Should be: "0" (enabled)
# Verify webhook URL in Zabbix admin → Administration → Media Types → Mattermost
```

---

### FreePBX (lab-pbx1)

#### Symptom: Admin page won't load after restart
```bash
ssh itstack@lab-pbx1 "docker logs freepbx-s01-app --tail 30"
# FreePBX runs all services in one container. Check if fully started:
ssh itstack@lab-pbx1 "docker exec freepbx-s01-app fwconsole sa"
# Expected: Apache, Asterisk, MySQL running
# If not: FreePBX is still initializing (can take 20 min first boot)
ssh itstack@lab-pbx1 "docker exec freepbx-s01-app fwconsole ma list | head -5"
```

#### Symptom: SIP calls not connecting
```bash
# Check Asterisk SIP debug
ssh itstack@lab-pbx1 "docker exec freepbx-s01-app asterisk -rx 'sip show peers'"
ssh itstack@lab-pbx1 "docker exec freepbx-s01-app asterisk -rx 'pjsip show endpoints'"
# Check RTP ports open
ssh itstack@lab-pbx1 "ufw status | grep 10000"
# Should have: 10000:20000/udp ALLOW
```

---

### Zammad (lab-comm1)

#### Symptom: Zammad shows HTTP 422 or blank page
```bash
ssh itstack@lab-comm1 "docker logs it-stack-zammad-rails-lab01 --tail 20"
# Usually a Rails environment issue — check secrets
ssh itstack@lab-comm1 "docker exec it-stack-zammad-rails-lab01 \
  rails runner 'puts Setting.get(\"es_url\")' 2>/dev/null"
# Verify Elasticsearch health
curl -sf http://lab-comm1:9200/_cluster/health | jq .status
```

#### Symptom: Email tickets not being created
```bash
# Check iRedMail SMTP relay configuration in Zammad
# Admin Panel → Email → Accounts → Test Email Account
# Verify iRedMail is accepting relays from Zammad's IP
ssh itstack@lab-comm1 "docker exec iredmail-s01 grep 'PERMIT_MYNETWORKS' /etc/postfix/main.cf"
```

---

### SuiteCRM (lab-biz1)

#### Symptom: SuiteCRM returning 500 errors
```bash
ssh itstack@lab-biz1 "docker logs suitecrm-s01 --tail 20"
# Check PHP error log
ssh itstack@lab-biz1 "docker exec suitecrm-s01 tail -20 /var/log/apache2/error.log"
# Clear SuiteCRM cache
ssh itstack@lab-biz1 "docker exec suitecrm-s01 rm -rf /var/www/html/cache/*"
ssh itstack@lab-biz1 "docker restart suitecrm-s01"
```

#### Symptom: SAML SSO not working in SuiteCRM
```bash
# Verify Keycloak SAML client is active
curl -sf -X GET "https://sso.it-stack.local/admin/realms/it-stack/clients" \
  -H "Authorization: Bearer $TOKEN" | jq '.[] | select(.clientId=="suitecrm") | .enabled'
# Should be: true
# If not: re-run roles/suitecrm/tasks/keycloak-saml.yml
ansible-playbook -i inventory/production.yml roles/suitecrm/tasks/keycloak-saml.yml \
  --vault-password-file ~/.vault_pass.txt -v
```

---

### Odoo (lab-biz1)

#### Symptom: Odoo worker process crashes (OOMKilled)
```bash
ssh itstack@lab-biz1 "docker events --filter container=odoo-s01 --since 1h | grep OOMKilled"
# Fix: increase container memory limit in docker-compose.yml
# Add: mem_limit: 4g
ssh itstack@lab-biz1 "docker stats odoo-s01 --no-stream"
```

#### Symptom: Odoo database migration failed (after version upgrade)
```bash
# Stop Odoo, run migration manually
ssh itstack@lab-biz1 "docker stop odoo-s01"
ssh itstack@lab-biz1 "docker run --rm \
  -v odoo-data:/var/lib/odoo \
  -e PGHOST=lab-db1 -e PGUSER=odoo -e PGPASSWORD=YourPassword \
  ghcr.io/it-stack-dev/it-stack-odoo:latest \
  odoo --update all --stop-after-init -d odoo"
ssh itstack@lab-biz1 "docker start odoo-s01"
```

---

## Common Cross-Service Issues

### Issue: All services returning 502 via Traefik

**Cause:** Traefik re-configuring after a Docker event (container restart, network change).  
**Fix:**
```bash
ssh itstack@lab-proxy1 "docker restart traefik-s01"
sleep 10
curl -sf https://cloud.it-stack.local/status.php | jq .installed
```

### Issue: All SSO logins failing

**Cause:** Keycloak database connection lost, OR FreeIPA LDAP down.  
**Diagnostic:**
```bash
# Step 1: Is Keycloak healthy?
curl -sf https://sso.it-stack.local/health/ready | jq .status
# Step 2: Is FreeIPA LDAP running?
ssh itstack@lab-id1 "ipactl status | grep Directory"
# Step 3: Can Keycloak reach FreeIPA LDAP?
ssh itstack@lab-id1 "docker exec keycloak-s01 curl -sf ldap://lab-id1:389/ 2>&1 | head -3"
```

### Issue: Database disk pressure (all services degrading)

```bash
# Check all servers
for h in lab-id1 lab-db1 lab-app1 lab-comm1 lab-proxy1 lab-pbx1 lab-biz1 lab-mgmt1; do
  echo "=== $h ==="
  ssh itstack@$h "df -h / /var/lib/docker 2>/dev/null | tail -2"
done

# Emergency: clean up Docker images and stopped containers
ssh itstack@lab-db1 "docker system prune -f"
# WARNING: this removes all stopped containers and unused images
# Do NOT run on lab-pbx1 between reboots (FreePBX data in unnamed volumes)
```

### Issue: Services running but extremely slow

**Check for resource starvation:**
```bash
# Memory pressure across all nodes
for h in lab-id1 lab-db1 lab-app1 lab-comm1 lab-proxy1 lab-pbx1 lab-biz1 lab-mgmt1; do
  ssh itstack@$h "free -h | awk 'NR==2{printf \"%s: %s used / %s total (swap: %s)\n\",\"$h\",\$3,\$2,\$3}'" 2>/dev/null
done

# CPU steal time (VMs only) — indicates hypervisor contention
ssh itstack@lab-db1 "vmstat 1 5 | tail -5"
# "st" (steal) > 10% = hypervisor overloaded, contact your cloud/VM provider
```

---

## Log Locations Reference

| Service | Container | Log Command |
|---------|-----------|-------------|
| FreeIPA | (host systemd) | `journalctl -u dirsrv@IT-STACK -f` |
| Keycloak | keycloak-s01 | `docker logs keycloak-s01 -f` |
| PostgreSQL | (host systemd) | `journalctl -u postgresql -f` |
| Redis | redis-s01 | `docker logs redis-s01 -f` |
| Nextcloud | nextcloud-s01 | `docker exec nextcloud-s01 tail -f /var/www/html/data/nextcloud.log` |
| Mattermost | mattermost-s01 | `docker exec mattermost-s01 tail -f /mattermost/logs/mattermost.log` |
| Traefik | traefik-s01 | `docker logs traefik-s01 -f` |
| Graylog | graylog-s01 | `docker logs graylog-s01 -f` |
| Zabbix | zabbix-server-s01 | `docker logs zabbix-server-s01 -f` |
| FreePBX | freepbx-s01-app | `docker exec freepbx-s01-app tail -f /var/log/asterisk/full` |
| Zammad | it-stack-zammad-rails-* | `docker logs it-stack-zammad-rails-lab01 -f` |
| SuiteCRM | suitecrm-s01 | `docker exec suitecrm-s01 tail -f /var/log/apache2/error.log` |
| Odoo | odoo-s01 | `docker logs odoo-s01 -f` |

---

## Emergency Recovery Procedures

### Full Stack Restart (Ordered)

```bash
#!/bin/bash
# Emergency ordered restart — follow dependency chain
IDENTITY="itstack@lab-id1"
DATABASE="itstack@lab-db1"
APP="itstack@lab-app1"
COMM="itstack@lab-comm1"
PROXY="itstack@lab-proxy1"

echo "=== Step 1: Database layer ==="
ssh $DATABASE "docker restart postgresql-s01 redis-s01"
sleep 30

echo "=== Step 2: Identity layer ==="
ssh $IDENTITY "ipactl restart"
sleep 60

echo "=== Step 3: Keycloak SSO ==="
ssh $IDENTITY "docker restart keycloak-s01"
sleep 30

echo "=== Step 4: Core services ==="
ssh $APP "docker restart nextcloud-s01 mattermost-s01"
ssh $COMM "docker restart zammad-s01"
sleep 30

echo "=== Step 5: Proxy ==="
ssh $PROXY "docker restart traefik-s01"

echo "=== Done. Run check-all.sh to verify ==="
```

### Database Recovery from Backup

```bash
# Restore PostgreSQL database from backup
ssh itstack@lab-db1 "ls -lh /opt/it-stack/backups/"

# Stop the application that uses the database
ssh itstack@lab-app1 "docker stop nextcloud-s01"

# Restore from backup
ssh itstack@lab-db1 "sudo -u postgres pg_restore \
  -d nextcloud \
  /opt/it-stack/backups/nextcloud_$(date +%Y%m%d).dump"

# Restart the application
ssh itstack@lab-app1 "docker start nextcloud-s01"
```

---

*Document version: 1.0 — 2026-03-11 — IT-Stack Production Troubleshooting Guide*
