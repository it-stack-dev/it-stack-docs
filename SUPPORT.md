# Support

IT-Stack is a community-driven open-source project. Support is provided on a best-effort basis by maintainers and community members.

---

## Before Asking for Help

1. **Check the documentation** — most common questions are answered in the lab manuals
2. **Search existing issues** in the relevant repository
3. **Read the troubleshooting guide** in the module's `docs/TROUBLESHOOTING.md`
4. **Check the debug checklist** below

---

## Quick Debug Checklist

Work through this list before opening an issue:

```bash
# 1. Service status
systemctl status {service}

# 2. Recent logs
journalctl -u {service} -n 100 --no-pager

# 3. Docker logs (if containerized)
docker compose logs -f {service-name}

# 4. Connectivity to PostgreSQL
psql -h lab-db1 -U {service_user} -d {service_db} -c '\conninfo'

# 5. Keycloak SSO (if OIDC/SAML issue)
# Check realm → Clients → {service} → Settings and Credentials tabs
# Check Events → Login events for error details

# 6. FreeIPA / LDAP
ldapsearch -H ldap://lab-id1 -x -D "uid=admin,cn=users,cn=accounts,dc=lab,dc=local" -W -b "cn=users,cn=accounts,dc=lab,dc=local" "(uid={username})"

# 7. DNS resolution
dig @lab-id1 {hostname}.lab.local

# 8. Firewall
sudo ufw status numbered

# 9. Certificate validity
openssl s_client -connect {host}:443 -servername {host} </dev/null 2>/dev/null | openssl x509 -noout -dates

# 10. Traefik routing
# Dashboard: https://lab-proxy1:8080 → HTTP → Routers
```

---

## Documentation

| Resource | URL / Path |
|----------|-----------|
| Master Index | [docs/MASTER-INDEX.md](docs/MASTER-INDEX.md) |
| Architecture (8-server) | [docs/enterprise-stack-complete-v2.md](docs/enterprise-stack-complete-v2.md) |
| Lab Part 1: Network & OS | [docs/enterprise-it-lab-manual.md](docs/enterprise-it-lab-manual.md) |
| Lab Part 2: Identity/DB/SSO | [docs/enterprise-it-lab-manual-part2.md](docs/enterprise-it-lab-manual-part2.md) |
| Lab Part 3: Collaboration | [docs/enterprise-it-lab-manual-part3.md](docs/enterprise-it-lab-manual-part3.md) |
| Lab Part 4: Communications | [docs/enterprise-it-lab-manual-part4.md](docs/enterprise-it-lab-manual-part4.md) |
| Lab Part 5: Back Office | [docs/enterprise-lab-manual-part5.md](docs/enterprise-lab-manual-part5.md) |
| Integration Guide | [docs/integration-guide-complete.md](docs/integration-guide-complete.md) |
| Task Tracker | [docs/IT-STACK-TODO.md](docs/IT-STACK-TODO.md) |

---

## GitHub Issues

For bugs, feature requests, or lab issues:

- **Use the correct repository** — each module has its own repo (`it-stack-{module}`)
- **Use the correct labels** — `lab`, `module-XX`, `phase-X`, `priority-*`
- **Include context** — OS version, Docker version, which lab, which step failed

| Repo | Use For |
|------|---------|
| [it-stack-docs](https://github.com/it-stack-dev/it-stack-docs) | Documentation bugs, missing content |
| [it-stack-freeipa](https://github.com/it-stack-dev/it-stack-freeipa) | FreeIPA-specific issues |
| [it-stack-keycloak](https://github.com/it-stack-dev/it-stack-keycloak) | Keycloak, SSO, OIDC, SAML issues |
| [it-stack-postgresql](https://github.com/it-stack-dev/it-stack-postgresql) | PostgreSQL, database connection issues |
| [it-stack-traefik](https://github.com/it-stack-dev/it-stack-traefik) | Reverse proxy, routing, TLS issues |
| [it-stack-nextcloud](https://github.com/it-stack-dev/it-stack-nextcloud) | File storage, CalDAV, LDAP sync |
| [it-stack-mattermost](https://github.com/it-stack-dev/it-stack-mattermost) | Chat, webhooks, notifications |
| [it-stack-installer](https://github.com/it-stack-dev/it-stack-installer) | Setup scripts, bootstrap automation |
| [it-stack-ansible](https://github.com/it-stack-dev/it-stack-ansible) | Ansible playbooks, roles, vars |
| [it-stack-testing](https://github.com/it-stack-dev/it-stack-testing) | Integration tests, lab scripts |

---

## GitHub Discussions

For questions that aren't bugs — "how do I…", "would it work if…", "can someone help with…":

- Use **GitHub Discussions** in the relevant repository
- Or use the parent [it-stack-docs Discussions](https://github.com/it-stack-dev/it-stack-docs/discussions) for general questions

---

## Community Channels

> These will be set up once the Mattermost deployment (Phase 2) is complete.

| Channel | Purpose |
|---------|---------|
| `#general` | General IT-Stack discussion |
| `#labs` | Lab progress, questions, and results |
| `#ops-alerts` | Infrastructure alerts (Zabbix integration) |
| `#deployments` | Deployment announcements |
| `#security` | Security discussions |

---

## Common Issues by Module

### FreeIPA
- **Kerberos clock skew error** — NTP must be synchronized across all nodes (`timedatectl status`)
- **LDAP bind fails** — check `nsslapd-minssf` setting requires TLS; use `ldaps://` or StartTLS
- **Replica not syncing** — check `/var/log/dirsrv/slapd-*/errors` on both master and replica

### Keycloak
- **"Invalid redirect_uri"** — the registered URI in the client config must exactly match what the service sends
- **LDAP federation not syncing** — check connection test in Keycloak → User Federation → Test connection / Test authentication
- **Token expiry causing logout loops** — adjust `accessTokenLifespan` and `ssoSessionMaxLifespan` in realm settings

### PostgreSQL
- **"pg_hba.conf" rejection** — add an entry for the source IP/network using `scram-sha-256`
- **"too many connections"** — add a PgBouncer connection pooler between application and PostgreSQL
- **Slow queries** — `EXPLAIN ANALYZE {query}` and check for missing indexes via `pg_stat_user_tables`

### Traefik
- **Certificate not renewing** — check `/var/log/traefik/traefik.log` for ACME errors; verify port 80 is reachable from Let's Encrypt
- **502 Bad Gateway** — backend service is down or health check failed; check Traefik dashboard
- **Service not appearing in dashboard** — Docker label syntax error or service not on the correct Docker network

### Nextcloud
- **"Trusted domain" error** — add the domain to `config.php` `trusted_domains` array or use `occ config:system:set`
- **Cron not running** — check `docker exec -u www-data nextcloud php cron.php` and configure crontab
- **LDAP users not seeing files** — check user home directory provisioning; set `ldapExpertUUIDUserAttr` to `uid`

### Mattermost
- **Email notifications not sending** — check SMTP settings in System Console → Notifications → Email
- **SSO redirect loop** — verify the Keycloak client redirect URI includes the Mattermost base URL with trailing slash

### iRedMail
- **Container fails to start** — hostname must be a fully-qualified domain name (`-h mail.lab.local`); single-label hostnames cause Postfix config failure
- **SMTP relay rejected** — check `relay_domains` in Postfix and ensure the sending host/IP is in `mynetworks`
- **Roundcube login fails** — verify `ROUNDCUBE_DEFAULT_HOST` matches the Dovecot container name; IMAP must be reachable on port 143

### Zammad
- **Rails server not starting** — Elasticsearch must be healthy first; Zammad polls ES on boot and will crash if unreachable
- **Ticket search returns no results** — run `zammad run rake searchindex:rebuild` inside the container to repopulate the Elasticsearch index
- **API 401 Unauthorized** — Zammad API tokens are per-user; generate via Profile → Token Access; do not use Basic Auth in production

### Jitsi
- **Video calls drop immediately** — Jitsi Bridge (JVB) must have UDP port 10000 reachable from clients; check firewall/NAT
- **`config.js` not generated** — `XMPP_DOMAIN`, `XMPP_AUTH_DOMAIN`, and `JVB_ADVERTISE_IPS` must all be set correctly in the environment
- **JWT auth rejecting valid tokens** — ensure `APP_SECRET` matches between Prosody and the token generator; tokens are HS256

### FreePBX
- **Container takes 3–5 min to become ready** — the `tiredofit/freepbx` image runs its own internal MariaDB and runs `fwconsole chown/reload` at startup; do not test before the bootstrap completes
- **External MariaDB container appears empty** — `tiredofit/freepbx` bundles its own MariaDB; an external `mariadb` container will not be used and will have no FreePBX schema tables; test against the dashboard/Asterisk AMI instead
- **Asterisk CLI not responding** — run `docker exec freepbx asterisk -rx "core show version"` inside the container; `asterisk -r` (remote console) requires the daemon to be fully up
- **Admin panel returns 403** — FreePBX admin is at `/admin/config.php`, not `/`; ensure the Apache rewrite rules are applied

### SuiteCRM
- **`config.php` not found at `/bitnami/suitecrm/`** — the Bitnami image places it at `/bitnami/suitecrm/public/legacy/config.php`; use `find /opt/bitnami /bitnami -name "config.php" -path "*suitecrm*"` to locate it
- **Login page returns empty body** — Apache briefly restarts during Bitnami's PHP migration step; add a retry loop (5 attempts × 15 s) before asserting login page content
- **Installer loop on first boot** — pass `SUITECRM_SKIP_BOOTSTRAP=no` and ensure MySQL/MariaDB is healthy before starting the SuiteCRM container
- **Cron jobs not running** — the Bitnami image requires a separate `crond` process; set `SUITECRM_CRON_ENABLED=yes` or add a sidecar cron container

### Odoo
- **`odoo.conf` workers = 0** — Odoo defaults to no workers in container mode; set `workers = N` (N = vCPU count) and expose the longpolling port 8072 for production
- **XML-RPC version call returns `ConnectionRefusedError`** — Odoo needs ~60 s to initialize the database on first run; poll `/web/webclient/version_info` before testing XML-RPC
- **`Database manager` page is blank** — the built-in database manager is at `/web/database/manager`; it is disabled if `list_db = False` is set in `odoo.conf`
- **Module install hangs** — worker count too low or DB is locked; check `docker logs` for `FATAL: terminating connection due to administrator command`

### OpenKM
- **Container has no `curl` or `wget`** — the OpenKM Community Edition Docker image ships without curl; test port availability via `/proc/net/tcp` inside the container: `grep -qE ':1F90 ' /proc/net/tcp6 /proc/net/tcp` (0x1F90 = 8080)
- **REST API returns 401** — OpenKM REST requires HTTP Basic Auth; default credentials are `okmAdmin / admin`; endpoint base is `/OpenKM/services/rest/`
- **Tomcat OOM on startup** — set `-Xmx512m -Xms256m` JVM flags; OpenKM Community needs at least 512 MB heap
- **File upload fails** — default max upload size in `server.xml` is 50 MB; increase `maxPostSize` on the Connector element

### Elasticsearch
- **Node fails to start: `bootstrap checks failed`** — in a single-node lab, set `discovery.type=single-node` and `xpack.security.enabled=false`; also check `vm.max_map_count` ≥ 262144 (`sysctl -w vm.max_map_count=262144`)
- **Heap OOM** — default heap is 1 GB; set `ES_JAVA_OPTS="-Xms1g -Xmx1g"` and ensure the Docker memory limit is at least 2× the heap
- **Yellow cluster status** — expected on a single-node cluster (replica shards have nowhere to go); harmless for lab use; set `number_of_replicas: 0` in index templates for clean green status

### Zabbix
- **Zabbix server "Cannot connect to database"** — PostgreSQL must be healthy and the Zabbix schema must be initialized before the server starts; the official `zabbix-server-pgsql` image initializes the schema on first run
- **Web UI shows "Zabbix server is not running"** — server container is separate from the web container; ensure `ZBX_SERVER_HOST` in the web container matches the server container name
- **Agent not connecting** — check `ZBX_PASSIVE_ALLOW=true` and that port 10050 (agent) is accessible; use `zabbix_get` to test from the server

### Graylog
- **Graylog stays in "Starting" state** — MongoDB AND Elasticsearch/OpenSearch must both be healthy before Graylog starts; add `depends_on` with `condition: service_healthy` for both
- **`GRAYLOG_PASSWORD_SECRET` must be ≥ 16 chars** and `GRAYLOG_ROOT_PASSWORD_SHA2` must be the SHA-256 hash of your password (`echo -n "password" | sha256sum`)
- **UDP syslog input not receiving** — Docker does not expose UDP ports by default; add `- "514:514/udp"` and `- "12201:12201/udp"` (GELF) explicitly; also add `Protocol: UDP` in the input config

### Taiga
- **"Invalid token" on API calls** — Taiga uses JWT; obtain a token via `POST /api/v1/auth` with `{type: "normal", username, password}`; the `Authorization: Bearer <token>` header is required on all protected endpoints
- **Events WebSocket not connecting** — `taiga-events` requires Redis and must share the same `SECRET_KEY` as `taiga-back`; check `TAIGA_SECRET_KEY` env var consistency across containers
- **Async tasks not processing** — `taiga-async` is the Celery worker; if it is not running, project notifications and email sync will queue indefinitely

### Snipe-IT
- **`APP_KEY` not set error** — generate with `docker exec snipeit php artisan key:generate --show` and set the result in `APP_KEY`; never reuse a key across environments
- **Email notifications fail** — set `MAIL_*` env vars; Snipe-IT requires a working SMTP connection to send asset assignment emails
- **SAML "Metadata not found"** — the SAML SP metadata is at `/saml/metadata`; register this URL as the SP entity ID in Keycloak

### GLPI
- **First-run installer loops** — pass `MARIADB_*` env vars correctly; GLPI's CLI installer (`php bin/console glpi:database:install`) requires all DB credentials to be present before the install step
- **Cron tasks not running** — GLPI requires a cron container running `php front/cron.php`; without it, scheduled tasks (notifications, automatic actions) are silently skipped
- **LDAP sync "No users found"** — verify `LDAP BaseDN`, `Login Field` (`uid`), and `Use TLS` settings in Administration → Authentication → LDAP; test with the "Search directory" button

---

## Lab Test Script Development

These patterns emerged from building and debugging `lab-phase1.sh` through `lab-sso-integrations.sh`. Follow them when writing or modifying test scripts in `scripts/testing/`.

### Critical: `pipefail` + `|| echo "000"` = False Pass Bug

With `set -uo pipefail`, a pipeline failure causes `|| echo "000"` to produce **two** `000` outputs that concatenate to `"000000"`. An `http_ok "000000"` check then falsely passes if the regex is not strict.

```bash
# WRONG — pipefail + || echo "000" concatenates to "000000"
code=$(curl -s ... | tr -d '[:space:]' || echo "000")

# CORRECT — use "; true" to suppress pipefail without appending extra output
code=$(curl -s ... | tr -d '[:space:]'; true)
```

### `http_ok()` Must Use Strict Regex

```bash
http_ok() { [[ "$1" =~ ^[1-5][0-9][0-9]$ ]]; }
```

This rejects `"000"`, `"000000"`, empty strings, and any non-3-digit output that would otherwise falsely pass a `[[ $code -ge 200 ]]` check.

### Containers Without `curl`: Use `/proc/net/tcp`

Images that lack curl (e.g., OpenKM CE) can be port-checked from inside the container via the kernel TCP table:

```bash
# 0x1F90 = port 8080 in hex
docker exec "$CTR" grep -qE ':1F90 ' /proc/net/tcp6 /proc/net/tcp 2>/dev/null
```

Convert the target port to hex: `printf '%04X\n' 8080` → `1F90`.

### Services That Bundle Their Own Database

`tiredofit/freepbx` runs its own internal MariaDB. An external `mariadb:` container in the same Compose file will be empty (no FreePBX schema). Do not test row counts against it; test the application layer instead (dashboard HTTP, Asterisk AMI, `core show version`).

### SuiteCRM Post-Init Apache Restart Window

The Bitnami SuiteCRM image restarts Apache mid-initialization during its PHP migration step. Test login/content pages with a retry loop:

```bash
for i in $(seq 1 5); do
  code=$(host_http "http://localhost:$PORT/index.php?module=Users&action=Login"; true)
  http_ok "$code" && break
  sleep 15
done
```

### `wait_healthy()` Time Budget

Calculate wait time as `max_retries × interval_seconds`. For slow-starting services (Odoo, Zammad, Graylog) use at least 120 s total. Graylog + MongoDB + Elasticsearch can take 180–240 s on first pull.

---

## No SLA / Commercial Support

IT-Stack is community-supported open-source software. There is no SLA, no guaranteed response time, and no commercial support contract.

If your organization requires guaranteed support, consider:
- Hiring a systems administrator experienced with these open-source tools
- Engaging a Red Hat / Canonical partner for FreeIPA and Ubuntu support
- Using commercially supported versions (e.g., Red Hat Identity Management, Bitnami stacks)

---

## Security Issues

**Do not report security vulnerabilities in public issues.**

See [SECURITY.md](SECURITY.md) for the responsible disclosure process.
