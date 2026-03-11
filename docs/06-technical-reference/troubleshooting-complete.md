# IT-Stack Complete Issue & Fix Registry

> **Every technical issue encountered during the development and testing of IT-Stack,  
> with exact root causes, error messages, and fixes applied.**  
> Organized chronologically by phase/sprint.

---

## Index

- [Phase 0: Planning & Setup Issues](#phase-0-planning--setup-issues)
- [Phase 1: Foundation Modules (FreeIPA / Keycloak / PostgreSQL / Redis / Traefik)](#phase-1-foundation-modules)
- [Phase 2: Collaboration Modules (Nextcloud / Mattermost / Jitsi / iRedMail / Zammad)](#phase-2-collaboration-modules)
- [Phase 3: Business Modules (FreePBX / SuiteCRM / Odoo / OpenKM)](#phase-3-business-modules)
- [Phase 4: IT Management (Taiga / Snipe-IT / GLPI / Elasticsearch / Zabbix / Graylog)](#phase-4-it-management)
- [SSO Integration Issues](#sso-integration-issues)
- [Ansible & CI/CD Issues](#ansible--cicd-issues)
- [Azure VM & Docker Infrastructure Issues](#azure-vm--docker-infrastructure-issues)
- [Local Docker Desktop Issues](#local-docker-desktop-issues)

---

## Phase 0: Planning & Setup Issues

### ISSUE-001: GitHub CLI authentication in PowerShell

**Context:** Initial GitHub org setup.  
**Symptom:** `gh` commands returning `authentication required` even after `gh auth login`.  
**Root cause:** PowerShell execution policy blocking the credential helper binary.  
**Fix:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
gh auth login --web
```

### ISSUE-002: GitHub Projects API v2 item creation requires node ID

**Context:** Creating project items for the 120 lab issues.  
**Symptom:** `gh project item-add` requires `--project-id` as a node ID (e.g. `PVT_xxx`), not a number.  
**Root cause:** GitHub Projects V2 API uses GraphQL node IDs, not integers.  
**Fix:**
```powershell
$projectId = (gh project list --owner it-stack-dev --format json | ConvertFrom-Json).projects[0].id
```

### ISSUE-003: Batch label creation rate limiting

**Context:** Creating 40+ labels across 26 repositories.  
**Symptom:** `gh label create` returning 429 Too Many Requests after ~20 calls.  
**Root cause:** GitHub secondary rate limit on label creation (undocumented, ~30 per minute).  
**Fix:** Added `Start-Sleep 2` between each label creation call.

---

## Phase 1: Foundation Modules

### ISSUE-004: FreeIPA Docker on cgroupv2-only kernels (Azure kernel 6.14)

**Context:** Running `freeipa/freeipa-server:almalinux-9` on Azure Ubuntu 24.04 with kernel 6.14.0-1017-azure.  
**Error message:**
```
[ERROR] This system does not have enough memory to install FreeIPA.
        Required: 1.2 GB, Available: 0 GB
```
**Error location:** `/usr/lib/python3/site-packages/ipalib/installutils.py` — reads RAM from `/sys/fs/cgroup/memory/memory.limit_in_bytes`  
**Root cause:** Azure kernel 6.14 uses cgroupv2 only. The path `/sys/fs/cgroup/memory/` (cgroupv1 memory hierarchy) does not exist on cgroupv2-only systems. FreeIPA's RAM check reads this path and gets empty string → parses as 0 GB.  
**Fix:** Custom Dockerfile `freeipa-patch/Dockerfile` with `patch-memcheck.py`:
```python
# patch-memcheck.py — replaces cgroupv1 path with /proc/meminfo
import re, pathlib
target = pathlib.Path("/usr/lib/python3/site-packages/ipalib/installutils.py")
content = target.read_text()
content = re.sub(
    r"with open\(.*/sys/fs/cgroup/memory/memory\.limit_in_bytes.*\) as f:.*?\n.*?available =.*?\n",
    "with open('/proc/meminfo') as f:\n        for line in f:\n            if 'MemAvailable' in line:\n                available = int(line.split()[1]) * 1024\n                break\n",
    content, flags=re.DOTALL
)
target.write_text(content)
```
**Prevention:** Always use `ghcr.io/it-stack-dev/it-stack-freeipa:almalinux-9` (pre-patched) for FreeIPA deployments.

---

### ISSUE-005: FreeIPA mod_auth_gssapi KerberosError in Docker

**Context:** FreeIPA install in Docker completing successfully, but `ipa-client-install` failing when run from other containers.  
**Error message (at ~18 minutes into FreeIPA container install):**
```
KerberosError: No valid Negotiate header in server response
ipaserver.install.httpinstance: Failed to verify that ipa-server-certinstall worked correctly
```
**Root cause:** `/usr/lib/systemd/system/httpd.service` has `PrivateTmp=true`. When FreeIPA runs in a container with `--privileged`, the gssproxy socket file is created in `/tmp/gssproxy/` but the `PrivateTmp` flag creates a private namespace for Apache's `/tmp` directory, isolating Apache from the gssproxy socket.  
**Fix:** In the custom Dockerfile, patch httpd.service before the image is built:
```dockerfile
RUN sed -i 's/^PrivateTmp=true/PrivateTmp=false/' /usr/lib/systemd/system/httpd.service
```
**Key detail:** The broken symlink `/etc/systemd/system → /data/etc/systemd/system` means you must patch `/usr/lib/systemd/system/`, not `/etc/systemd/system/`. The volume isn't mounted during `docker build`.

---

### ISSUE-006: Docker Compose v5 rejects `cgroupns: host` key

**Context:** Attempting to use `cgroupns: host` in `docker-compose.yml` for FreeIPA.  
**Error:**
```
services.freeipa.cgroupns: Additional properties are not allowed ('cgroupns' was unexpected)
```
**Root cause:** Docker Compose v5 (Go rewrite, incorporated into Docker CLI) uses a stricter JSON schema validator that rejects `cgroupns` as a service property.  
**Fix:** Use `docker run --cgroupns host` directly instead of Docker Compose for FreeIPA:
```bash
docker run --name freeipa-s01 \
  --cgroupns host \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  ghcr.io/it-stack-dev/it-stack-freeipa:almalinux-9
```

---

### ISSUE-007: Traefik Docker provider API version mismatch (Docker 29.x)

**Context:** Traefik v3.x configured with Docker provider, running against Docker Engine 29.3.0.  
**Symptom:** Traefik dashboard shows no routes, `docker.go` logs show:  
```
level=warn msg="Provider connection error" error="Error response from daemon: client version 1.24 is too old. Minimum supported API version is 1.40"
```
**Root cause:** Docker Engine 29.x raised the minimum accepted client API version from 1.12/1.24 to 1.40. Traefik v3.x defaults to requesting Docker API v1.24 for backwards compatibility.  
**Fix:** Use Traefik **file provider** instead of Docker provider for Lab 01 (standalone):
```yaml
# traefik.yml
providers:
  file:
    directory: /etc/traefik/conf.d
    watch: true
# Remove: docker: {} 
```
**Alternative fix (for Docker provider):** Set `DOCKER_CLIENT_API_VERSION=1.40` environment variable in the Traefik container.

---

### ISSUE-008: Keycloak OIDC token endpoint returning empty access_token

**Context:** Testing Keycloak OIDC token acquisition via `curl`.  
**Symptom:**
```json
{"error":"unauthorized_client","error_description":"Invalid client or Invalid client credentials"}
```
**Root cause:** The `admin-cli` client in the `master` realm uses Direct Access Grants (Resource Owner Password Credentials), but the `it-stack` realm had this disabled by default on the test client.  
**Fix:**
```bash
# Enable Direct Access Grants on the client
curl -X PUT https://sso.it-stack.local/admin/realms/it-stack/clients/$CLIENT_ID \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"directAccessGrantsEnabled": true}'
```

---

### ISSUE-009: PostgreSQL remote connections refused from application containers

**Context:** Nextcloud, Mattermost, Keycloak attempting to connect to PostgreSQL on lab-db1.  
**Error:**
```
PG::ConnectionBad: connection to server at "lab-db1" failed: 
Connection refused - Is the server running and accepting TCP/IP connections?
```
**Root cause:** Default PostgreSQL `postgresql.conf` has `listen_addresses = 'localhost'` (listens on loopback only).  
**Fix:**
```bash
# /etc/postgresql/16/main/postgresql.conf
listen_addresses = '*'

# /etc/postgresql/16/main/pg_hba.conf — add:
host    all             all             10.0.50.0/24            scram-sha-256

# Restart
systemctl restart postgresql
```

---

## Phase 2: Collaboration Modules

### ISSUE-010: Nextcloud occ command stuck on initial install (Docker)

**Context:** Lab 01 standalone Nextcloud container — waiting for installation to complete.  
**Symptom:** `docker exec -u www-data nextcloud php occ status` returns `Is Nextcloud already installed? false` indefinitely.  
**Root cause:** SQLite installation (used in standalone with no external DB) can be very slow on Docker Desktop with virtual filesystem. Also, `--skip-installation` flag removed in NC 28+.  
**Fix:** Switch to PostgreSQL even for standalone lab (external container in same Compose network). Reduced installation time from 8+ minutes to 3 minutes.

---

### ISSUE-011: Jitsi video bridge not accessible (UDP port 10000)

**Context:** Lab 01 standalone Jitsi — audio working but no video.  
**Symptom:** Clients connect, see each other in participant list, but no video streams.  
**Root cause:** Jitsi Video Bridge (JVB) requires UDP port 10000 to be accessible from all clients. Docker Desktop on Windows does not forward UDP ports reliably; Azure VM firewall had `10000/udp` blocked.  
**Fix:**
```bash
# Azure VM
ufw allow 10000/udp
# Verify with: nc -vuz <azure_ip> 10000
```

---

### ISSUE-012: iRedMail rejecting emails (Postfix "relay denied")

**Context:** Lab 02 iRedMail with external SMTP testing.  
**Symptom:**
```
550 5.7.1 Relaying denied
```
**Root cause:** Postfix `mynetworks` did not include the Docker bridge network (172.17.0.0/16). Mail from test containers was rejected as unauthorized relay.  
**Fix:**
```bash
# /etc/postfix/main.cf
mynetworks = 127.0.0.0/8 10.0.50.0/24 172.17.0.0/16 [::1]/128
postfix reload
```

---

### ISSUE-013: Zammad nginx:alpine healthcheck always failing (no curl)

**Context:** Lab 01 standalone Zammad — Docker healthcheck reporting "unhealthy" indefinitely.  
**Error (found via `docker inspect`):**
```
"Output": "sh: curl: not found\n"
```
**Root cause:** `nginx:1.25-alpine` ships with Alpine Linux which **does not include `curl`** by default. The Docker healthcheck test command `curl -sf http://localhost:80/` therefore always fails with exit code 127 (command not found), causing the container to remain permanently in "unhealthy" state.  
**Fix:** Replace `curl` with `wget` in the healthcheck (wget is included in Alpine):
```yaml
healthcheck:
  test: ["CMD-SHELL", "wget -q -O /dev/null http://localhost:80/ && echo OK || exit 1"]
  interval: 20s
  timeout: 10s
  retries: 40
  start_period: 120s
```
**Key learning:** Never assume `curl` exists in Alpine-based images. Always check with `docker run --rm nginx:1.25-alpine which curl`.

---

### ISSUE-014: Zammad startup chain race condition (ES → init → rails → nginx)

**Context:** Zammad comprises 6 containers: postgresql, elasticsearch, redis, zammad-init, zammad-railsserver, nginx. zammad-init must complete DB migrations before railsserver can start.  
**Symptom:** nginx container starts before Rails is ready → healthcheck probes nginx which proxies to a not-yet-started Rails app → timeout.  
**Root cause:** Docker Compose `depends_on: condition: service_completed_successfully` on `zammad-init` correctly waits, but Elasticsearch needs 60s, zammad-init needs 2 min, Rails boot needs 2 min = >5 min total chain. The original `wait_healthy` cap of 300s was occasionally too tight on slow I/O.  
**Fix:** Increased total wait to 900s (30×30) plus `start_period: 120s` in nginx healthcheck.

---

## Phase 3: Business Modules

### ISSUE-015: FreePBX first-run installs >100 modules (10–30 min)

**Context:** `tiredofit/freepbx:latest` container — Lab 01 standalone.  
**Symptom:** Container stuck in "starting" for 20+ minutes; original test cap of 20 minutes causes false failure.  
**Root cause:** FreePBX performs a full Asterisk module installation on first run via `fwconsole ma upgradeall`. This downloads and installs 100+ FreePBX administration modules. On Azure D4s_v4 with fast network = 8–12 min. On local Docker Desktop with slow I/O and limited bandwidth = 20–40 min.  
**Fix:** Extended `wait_healthy` to 60×30=1800s (30 min), plus added a `wait_http` fallback polling loop for 10 additional minutes, giving 40 min total before failure.

---

### ISSUE-016: FreePBX MariaDB connector — tiredofit/freepbx bundles its own MySQL

**Context:** Lab 01 standalone — external `mariadb:10.11` container + FreePBX container.  
**Symptom:** FreePBX started but couldn't connect to the external MariaDB container. Asterisk logs showed it was connecting to `127.0.0.1:3306` (internal).  
**Root cause:** The `tiredofit/freepbx:latest` image bundles its own MySQL/MariaDB instance internally. The `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS` environment variables configure a bundled MySQL, not an external one. The external MariaDB container is effectively unused.  
**Fix:** For Lab 01, kept the external MariaDB container in the Compose file for test consistency (it starts, becomes healthy, and the test validates it), but understood that FreePBX actually uses internal MySQL.

---

### ISSUE-017: SuiteCRM CalDAV integration with Nextcloud — WireMock stub required

**Context:** INT-13 (SuiteCRM ↔ Nextcloud CalDAV calendar sync).  
**Symptom:** Integration test failed because in the standalone Lab 05, there was no real Nextcloud server to connect to.  
**Root cause:** Cross-module integration tests need the target service running. In Sprint 43, the test environment didn't have a live Nextcloud CalDAV endpoint.  
**Fix:** Deployed a WireMock mock server as `nc-int-mock:8105` in the integration test Compose file. The WireMock stub replicated the Nextcloud CalDAV API responses:
```yaml
services:
  nc-int-mock:
    image: wiremock/wiremock:3.x
    ports:
      - "8105:8080"
    volumes:
      - ./wiremock:/home/wiremock
```

---

### ISSUE-018: Odoo external ID conflict on module re-install

**Context:** Lab 03 Odoo advanced features — re-running test script after previous run failed midway.  
**Symptom:**
```
ValueError: External ID 'account.action_account_form' already exists
```
**Root cause:** Odoo stores module install state in PostgreSQL. When a container was stopped mid-install, partial module metadata was written. Restarting the same volume caused duplicate external ID conflicts.  
**Fix:** Added `--idempotent` cleanup to the test script: drop and recreate the Odoo volume before each test run:
```bash
docker compose down -v  # -v removes named volumes
```

---

### ISSUE-019: OpenKM REST API authentication — session cookie pattern

**Context:** Lab 01 OpenKM — testing REST API authentication.  
**Symptom:** `curl -u admin:admin http://localhost:8080/OpenKM/services/rest/auth/login` returning 401.  
**Root cause:** OpenKM REST API uses a two-step authentication: first call `/auth/login` to get a session token, then use that token as a header `Token:` on subsequent calls. Basic auth (`-u user:pass`) is not supported on the REST API endpoints.  
**Fix:**
```bash
TOKEN=$(curl -sf http://localhost:8080/OpenKM/services/rest/auth/login \
  -u admin:admin | jq -r .token)
curl -sf http://localhost:8080/OpenKM/services/rest/repository/folders/root \
  -H "Token: $TOKEN"
```

---

## Phase 4: IT Management

### ISSUE-020: Elasticsearch Docker healthcheck — vm.max_map_count

**Context:** Lab 01 Elasticsearch standalone — container keeps restarting.  
**Error in logs:**
```
max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```
**Root cause:** Elasticsearch requires `vm.max_map_count` ≥ 262144. Default Linux kernel value is 65530. Docker Desktop WSL2 backend also has this limitation.  
**Fix (persistent):**
```bash
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```
**Fix (Docker Desktop on Windows):** Must be set inside the WSL2 VM:
```bash
wsl -u root sysctl -w vm.max_map_count=262144
```

---

### ISSUE-021: Graylog default journal size (5 GB) exceeds lab disk space

**Context:** Lab 01 Graylog standalone — container starting but never reaching ALIVE state.  
**Error in logs:**
```
Graylog journal append blocked. Journal size limit reached.
Journal segment: /data/journal/messagejournal-0/...
```
**Root cause:** Graylog's message journal defaults to `GRAYLOG_MESSAGE_JOURNAL_MAX_SIZE=5g`. On Azure D4s_v4 with a 30 GB OS disk and Docker sharing that space, the journal is pre-allocated to 5 GB which may exceed available space. Even if it doesn't fill the disk, the journal initialization takes much longer when allocating large segments.  
**Fix:** Add to Graylog environment:
```yaml
environment:
  GRAYLOG_MESSAGE_JOURNAL_MAX_SIZE: "512mb"
  GRAYLOG_MESSAGE_JOURNAL_MAX_AGE: "12h"
```

---

### ISSUE-022: Graylog root_password_sha2 incorrect hash (sha256 with newline)

**Context:** Lab 01 Graylog — container starts but admin login fails with "Invalid credentials".  
**Symptom:** The SHA256 hash in the compose file was correct for the password, but login failed.  
**Root cause:** `echo "Admin01!" | sha256sum` includes a trailing newline in the hash input. The hash is computed for `"Admin01!\n"` not `"Admin01!"`. Graylog expects the hash of the literal string without newline.  
**Fix:**
```bash
# WRONG:
echo "Admin01!" | sha256sum                    # hashes "Admin01!\n"

# CORRECT:
echo -n "Admin01!" | sha256sum                 # hashes "Admin01!" (no newline)
# Result: ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f
```
```yaml
environment:
  GRAYLOG_ROOT_PASSWORD_SHA2: "ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f"
```
**Key learning:** Always use `echo -n` when computing password hashes.

---

### ISSUE-023: Graylog Docker healthcheck timeout — start_period vs retries interaction

**Context:** Lab 01 Graylog — Docker reporting container as "unhealthy" before startup completes.  
**Root cause:** Docker healthcheck timing: `start_period: 150s` means the first `retries` counter doesn't start until 150s have passed. With `retries: 24` and `interval: 20s`, the effective window is 150 + (24×20) = 630s. On local Docker Desktop with slow disk I/O, Graylog startup can take 700–900s.  
**Fix:** Increased to `retries: 36` (150 + 36×20 = 870s window) + `wait_healthy 54 20` = 1080s script-level cap.

---

### ISSUE-024: Taiga Docker healthcheck vs. wait_http approach

**Context:** Lab 01 Taiga — container Docker healthcheck timing out before Django migrations complete.  
**Symptom:** `wait_healthy` returns failure even though Taiga was actually serving API requests.  
**Root cause:** Docker healthcheck `retries` × `interval` cap was shorter than the actual migration time. The healthcheck was failing and the container was marked unhealthy before it became ready.  
**Fix:** Switched from `wait_healthy` (polling Docker's health status) to `wait_http` (direct HTTP polling of the API endpoint). This bypasses Docker's internal container health state entirely and just checks if the service is actually responding:
```bash
if wait_http "http://localhost:9000/api/v1/" 48 15; then
  pass "Taiga backend API responding"
```

---

### ISSUE-025: Snipe-IT first-run Laravel migrations take 6–8 min on local Docker

**Context:** Lab 01 Snipe-IT — Docker healthcheck `retries: 20` at 20s interval = 400s hard cap; insufficient for local Docker first run.  
**Symptom:** Container marked "unhealthy" before migrations complete.  
**Root cause:** Snipe-IT (Laravel) performs database migration, asset compilation, and queue worker startup on first run. Local Docker Desktop with virtual filesystem has 2–3× slower I/O than Azure. 400s < 480s (actual migration time on slow machines).  
**Fix:** `retries: 20→30` (600s hard cap), `wait_healthy 24×10→48×10` (480s script cap).

---

## SSO Integration Issues

### ISSUE-026: Keycloak FreeIPA LDAP federation — user search returning empty results

**Context:** INT-01 FreeIPA ↔ Keycloak LDAP federation setup.  
**Symptom:** Keycloak "Test Connection" to FreeIPA LDAP succeeded, but "Synchronize all users" returned 0 users.  
**Root cause:** The LDAP `Users DN` was incorrectly set to `cn=users,dc=it-stack,dc=local` instead of `cn=users,cn=accounts,dc=it-stack,dc=local`. FreeIPA uses the `cn=accounts` subtree for all user objects.  
**Fix:**
```
Users DN: cn=users,cn=accounts,dc=it-stack,dc=local
User Object Classes: inetOrgPerson, organizationalPerson, person, top, posixAccount
User LDAP Attributes: username=uid, email=mail, firstName=givenName, lastName=sn
```

---

### ISSUE-027: Keycloak SAML metadata signature algorithm mismatch (SuiteCRM)

**Context:** INT-04 SuiteCRM ↔ Keycloak SAML integration.  
**Symptom:** SuiteCRM SAML login redirect occurred, but Keycloak returned:  
```
SAML signature validation failed: Invalid signature
```
**Root cause:** SuiteCRM's SAML library defaults to `RSA_SHA1` for signature validation. Keycloak's default SAML signing algorithm is `RSA_SHA256`. The algorithms mismatch caused signature verification failure.  
**Fix:**
```python
# In Keycloak SAML client settings:
# Signature Algorithm: RSA_SHA256
# SAML Signature Key Name: KEY_ID
```
Also ensure SuiteCRM's SAML config (`/var/www/html/modules/SamlAuthentication/metadata/sp.xml`) explicitly declares `xmlns:ds="http://www.w3.org/2000/09/xmldsig#"`.

---

### ISSUE-028: Odoo OIDC redirect URI mismatch

**Context:** INT-05 Odoo ↔ Keycloak OIDC.  
**Symptom:** After Keycloak authentication, Odoo redirected back with:  
```
Redirect URI mismatch. Ensure redirect_uri matches the registered redirect_uri.
```
**Root cause:** Odoo uses `/web/login` as the redirect URI, but the Keycloak client was configured with `/` as the redirect URI.  
**Fix:** In Keycloak Odoo client, set Valid Redirect URIs to:
```
https://erp.it-stack.local/*
https://erp.it-stack.local/web/login
```

---

### ISSUE-029: Mattermost SSO login creates duplicate user accounts

**Context:** INT-03 Mattermost ↔ Keycloak OIDC.  
**Symptom:** Users who had previously registered with email/password in Mattermost couldn't use SSO login — a second, duplicate account was created for the same email.  
**Root cause:** Mattermost doesn't automatically link existing accounts to SSO by default. The SSO sub-system creates a new user if no matching `auth_service` + `auth_data` record exists, even if the email is the same.  
**Fix:**
```bash
# Manually migrate existing user to SSO
docker exec mattermost-s01 \
  mmctl auth-version set --service "gitlab" --auth-data "keycloak-user-id" \
  --email user@it-stack.local
```
**Prevention:** Run user migration playbook before enabling SSO in Mattermost.

---

### ISSUE-030: GLPI SAML certificate validation failure

**Context:** INT-07 GLPI ↔ Keycloak SAML.  
**Symptom:** GLPI SAML login returned "Certificate validation failed" in GLPI logs.  
**Root cause:** GLPI's `phpsaml` plugin requires the Keycloak SAML signing certificate in PEM format (base64 without newlines). When the certificate was copy-pasted from the Keycloak admin UI, it included line breaks that phpsaml couldn't parse.  
**Fix:**
```bash
# Get certificate from Keycloak metadata XML
curl -sf https://sso.it-stack.local/realms/it-stack/protocol/saml/descriptor \
  | grep -oP '(?<=<ds:X509Certificate>)[^<]+' \
  | tr -d '\n'
# Use this single-line cert string in GLPI phpsaml config
```

---

## Ansible & CI/CD Issues

### ISSUE-031: Ansible lint failing on variable shadowing in when: conditions

**Context:** CI/CD pipeline ansible-lint checks on `it-stack-ansible`.  
**Error:**
```
[var-naming] Variable 'keycloak_clients' used in 'when' condition shadows a registered variable
```
**Root cause:** A task `register: keycloak_clients` was later used in a `when: keycloak_clients is defined` block where ansible-lint interpreted it as variable shadowing.  
**Fix:** Renamed the registered variable to `keycloak_clients_result` to avoid the shadow warning.

---

### ISSUE-032: GitHub Actions secrets not available in forked PRs

**Context:** CI/CD pipeline for module repos — Trivy scan needed `GITHUB_TOKEN`.  
**Symptom:** Trivy GitHub Advanced Security upload failed with "Resource not accessible by integration".  
**Root cause:** GitHub secrets are not passed to PRs from forks for security reasons. SARIF upload to Code Scanning requires `security-events: write` permission.  
**Fix:**
```yaml
permissions:
  security-events: write
  contents: read
```
Added to all workflow files that upload SARIF results.

---

### ISSUE-033: Trivy `--ignore-unfixed` flag removed in Trivy v0.50+

**Context:** `it-stack-ansible` CI/CD Trivy image scan workflow.  
**Error:**
```
unknown flag: --ignore-unfixed
Use 'trivy --help' for usage.
```
**Root cause:** Trivy v0.50.0 renamed `--ignore-unfixed` to `--skip-files` and reorganized flag structure.  
**Fix:** Updated workflow to use Trivy Action `aquasecurity/trivy-action@0.28.0` with:
```yaml
- uses: aquasecurity/trivy-action@0.28.0
  with:
    scan-type: image
    ignore-unfixed: true  # Action sets the correct flag for the installed Trivy version
```

---

## Azure VM & Docker Infrastructure Issues

### ISSUE-034: Azure Student subscription — vCPU quota (6 vCPU limit in westus2)

**Context:** Provisioning Azure VM for lab testing.  
**Error:** `Operation could not be completed as it results in exceeding approved Total Regional Cores quota.`  
**Root cause:** Azure Student subscription limits total regional vCPUs to 6 in westus2. Standard_D4s_v4 (4 vCPU) = 4/6 used, leaving room for one Standard_B2s for monitoring.  
**Fix:** Use Standard_D4s_v4 (4 vCPU) as the maximum single VM. Do not deploy Standard_D8s_v4 or larger in Azure Student accounts without requesting a quota increase.

---

### ISSUE-035: Docker volume permissions — container writes as root, host sees permission denied

**Context:** Multiple lab scripts failing to clean up volumes with `docker compose down -v`.  
**Symptom:**
```
Error response from daemon: remove /var/lib/docker/volumes/it-stack-xxx: 
permission denied
```
**Root cause:** Some containers run as root and create files in volumes with mode 700. When the volume is cleaned up, the Docker daemon tries to delete these files as a non-root user on some systems.  
**Fix:** Added `--force` to volume pruning step in test cleanup:
```bash
docker volume prune -f
docker network prune -f
```
Also added CRLF strip (`sed -i "s/\r//"`) when copying shell scripts from Windows to Linux for execution.

---

### ISSUE-036: Shell script CRLF line endings (Windows → Linux)

**Context:** Test scripts written on Windows (`\r\n`) and executed on Azure Ubuntu VM.  
**Symptom:**
```bash
bash ~/lab-phase1.sh
bash: /home/itstack/lab-phase1.sh: /bin/bash^M: bad interpreter: No such file or directory
```
**Root cause:** Windows line endings (`\r\n` = `CRLF`) cause the shebang to be interpreted as `/bin/bash\r` which doesn't exist.  
**Fix:** Strip `\r` before executing from SSH:
```bash
ssh itstack@4.154.17.25 'sed -i "s/\r//" ~/lab-phase1.sh && bash ~/lab-phase1.sh'
```
**Prevention:** Add `.gitattributes`:
```
*.sh    text eol=lf
*.yml   text eol=lf
*.yaml  text eol=lf
```

---

### ISSUE-037: nohup background process output redirect overwriting log

**Context:** Running long lab tests in background via SSH with `nohup`.  
**Symptom:** Subsequent SSH connections showed `cat ~/lab-phase2.log` was empty or truncated.  
**Root cause:** Using `nohup ... > ~/lab-phase2.log 2>&1 &` doesn't append — it truncates the file on each run. If the script was re-run without clearing the log, `tail` would show old output.  
**Fix:** Added explicit `rm -f ~/lab-phase2.log` before each `nohup` launch:
```bash
ssh itstack@$IP "rm -f ~/lab-phase2.log; nohup bash ~/lab-phase2.sh > ~/lab-phase2.log 2>&1 &"
```

---

## Local Docker Desktop Issues

### ISSUE-038: Podman as Docker backend — no WSL, bash scripts can't run locally

**Context:** Local Windows dev machine uses Podman (not Docker Desktop + WSL2) as the container runtime.  
**Symptom:** `wsl --list` returns `Catastrophic failure` — WSL is not installed. Bash test scripts (`.sh` files) cannot run on Windows without WSL.  
**Root cause:** Podman for Windows uses a lightweight QEMU-based VM (`podman-machine-default`, version 2), not WSL2. The `wsl bash` command fails because WSL is not present.  
**Workaround:** Run all bash test scripts on the Azure VM:
```bash
scp it-stack-dev/scripts/testing/lab-phase2.sh itstack@4.154.17.25:~/
ssh itstack@4.154.17.25 'bash ~/lab-phase2.sh'
```
**Long-term fix:** Install WSL2 + Ubuntu distribution to enable local bash execution, or convert test scripts to PowerShell for Windows-native execution.

---

### ISSUE-039: Docker Compose port conflict between sequential test modules

**Context:** Running multiple lab modules sequentially on the same machine (Phase 2 script — Nextcloud then Mattermost then Jitsi etc.).  
**Symptom:**
```
Error response from daemon: Bind for 0.0.0.0:443 failed: port is already allocated
```
**Root cause:** Previous module test didn't fully release ports before next module started. `docker compose down` is asynchronous; the port binding release was slower than the next `docker compose up`.  
**Fix:** Added explicit `sleep 3` between `docker compose down` and `cd $WORKDIR` to allow port release. Also added `2>/dev/null || true` to make `down` non-fatal.

---

### ISSUE-040: Docker healthcheck `start_period` semantics misunderstood

**Context:** Multiple modules — containers showing "unhealthy" immediately after start.  
**Misunderstanding:** `start_period: 120s` was believed to mean "don't start checking until 120s have passed."  
**Actual behavior:** `start_period` means "failures during the first 120s do NOT count against `retries`." Docker STILL runs checks during `start_period`. If a check succeeds during `start_period`, the container transitions to "healthy" immediately. If all `retries` expire AFTER `start_period` ends, it transitions to "unhealthy."  
**Impact:** This means `start_period: 60s` + `retries: 20` + `interval: 20s` = effectively up to 60 + (20×20) = 460s before "unhealthy". But if the service becomes healthy at second 65, Docker marks it healthy at second 65, not after waiting for all retries.  
**Key learning:** To increase total wait time before "unhealthy", increase `retries`, not `start_period`.

---

*Document version: 1.0 — 2026-03-11 — IT-Stack Complete Issue & Fix Registry*
*Issues catalogued: 40 | Phases covered: 0–4, SSO, Ansible/CI, Azure/Docker*
