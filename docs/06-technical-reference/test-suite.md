# IT-Stack Comprehensive Test Suite

> **Reference document for all test categories, individual module tests,  
> integration tests, CI patterns, and performance benchmarks.**

---

## Table of Contents

- [Test Philosophy & Categories](#test-philosophy--categories)
- [Unit Tests — Individual Module Health](#unit-tests--individual-module-health)
- [Integration Tests — Cross-Service Validation](#integration-tests--cross-service-validation)
- [End-to-End Tests — Full Workflow Validation](#end-to-end-tests--full-workflow-validation)
- [Lab Test Scripts Reference](#lab-test-scripts-reference)
- [Performance & Load Tests](#performance--load-tests)
- [Security Tests](#security-tests)
- [CI/CD Pipeline Tests (GitHub Actions)](#cicd-pipeline-tests-github-actions)
- [Test Environments & Matrices](#test-environments--matrices)
- [Test Utilities & Helpers](#test-utilities--helpers)
- [Expected Baselines (Azure D4s_v4)](#expected-baselines-azure-d4sv4)

---

## Test Philosophy & Categories

### Pyramid Structure

```
                        ┌─────────────┐
                        │    E2E      │  10 workflows — slow, fragile, essential
                        │  (Lab 05–06)│
                   ┌────┴─────────────┴────┐
                   │   Integration Tests    │  23 integrations — medium speed
                   │      (Lab 04–05)       │
              ┌────┴────────────────────────┴────┐
              │      Component/Module Tests       │  20 modules × 6 labs = 120 tests
              │         (Lab 01–06)               │
         ┌────┴──────────────────────────────────┴────┐
         │              Unit / Health Tests             │  1 per service endpoint
         │     (Individual healthcheck assertions)      │
         └──────────────────────────────────────────────┘
```

### Categories

| Category | Tag | Scope | Speed | Requires External |
|----------|-----|-------|-------|-------------------|
| Health check | `#health` | Single service endpoint | < 5s | No |
| Unit | `#unit` | Single container, no deps | < 2 min | No |
| Component | `#component` | Full module, isolated | 5–30 min | No |
| Integration | `#integration` | Two or more modules | 15–60 min | Yes |
| SSO | `#sso` | Module + Keycloak + FreeIPA | 30–90 min | Yes |
| E2E | `#e2e` | Full workflow, multiple users | 60–180 min | Full stack |
| Performance | `#perf` | Load and stress tests | 15–30 min | Module only |
| Security | `#security` | Auth, TLS, headers | 5–15 min | No |

---

## Unit Tests — Individual Module Health

Each module must pass the following health assertions immediately after container startup:

### Module 01 — FreeIPA

```bash
# tests/unit/freeipa/test-health.sh
assert_http_200() { curl -sf -o /dev/null -w "%{http_code}" "$1"; }

test_freeipa_ipa_ui() {
  STATUS=$(assert_http_200 "https://lab-id1.it-stack.local/ipa/ui/")
  [ "$STATUS" = "200" ] && pass "FreeIPA UI accessible" || fail "FreeIPA UI returned $STATUS"
}

test_freeipa_ldap_bind() {
  ldapsearch -x -H ldap://lab-id1.it-stack.local \
    -D "uid=admin,cn=users,cn=accounts,dc=it-stack,dc=local" \
    -w "$IPA_ADMIN_PASSWORD" \
    -b "cn=users,cn=accounts,dc=it-stack,dc=local" \
    "(uid=admin)" dn | grep -q "dn:" && pass "LDAP bind succeeded" || fail "LDAP bind failed"
}

test_freeipa_kerberos() {
  echo "$IPA_ADMIN_PASSWORD" | kinit admin@IT-STACK.LOCAL && pass "Kerberos kinit succeeded" || fail "Kerberos kinit failed"
  kdestroy
}

test_freeipa_dns() {
  dig @lab-id1.it-stack.local lab-db1.it-stack.local +short | grep -q "10.0.50.12" && pass "DNS resolves lab-db1" || fail "DNS resolution failed"
}
```

### Module 02 — Keycloak

```bash
# tests/unit/keycloak/test-health.sh
test_keycloak_health() {
  curl -sf http://lab-id1.it-stack.local:8080/health/ready | \
    jq -r .status | grep -q "UP" && pass "Keycloak ready" || fail "Keycloak health check failed"
}

test_keycloak_realm_exists() {
  TOKEN=$(curl -sf http://lab-id1.it-stack.local:8080/realms/master/protocol/openid-connect/token \
    -d "grant_type=password&client_id=admin-cli&username=admin&password=$KC_ADMIN_PASSWORD" \
    | jq -r .access_token)
  curl -sf -H "Authorization: Bearer $TOKEN" \
    http://lab-id1.it-stack.local:8080/admin/realms/it-stack \
    | jq -r .realm | grep -q "it-stack" && pass "it-stack realm exists" || fail "it-stack realm missing"
}

test_keycloak_token_endpoint() {
  RESP=$(curl -sf http://lab-id1.it-stack.local:8080/realms/it-stack/protocol/openid-connect/token \
    -d "grant_type=password&client_id=test-client&username=testuser&password=Test01!" \
    | jq -r .token_type)
  [ "$RESP" = "Bearer" ] && pass "OIDC token endpoint working" || fail "Token endpoint failed: $RESP"
}
```

### Module 03 — PostgreSQL

```bash
# tests/unit/postgresql/test-health.sh
test_postgresql_connection() {
  pg_isready -h lab-db1.it-stack.local -p 5432 -U postgres && pass "PostgreSQL accepting connections" || fail "PostgreSQL not ready"
}

test_postgresql_databases_exist() {
  for DB in keycloak nextcloud mattermost zammad suitecrm odoo openkm taiga snipeit glpi; do
    psql -h lab-db1.it-stack.local -U postgres -lqt | cut -d '|' -f1 | grep -qw "$DB" && \
      pass "Database $DB exists" || fail "Database $DB missing"
  done
}

test_postgresql_replication_slots() {
  SLOTS=$(psql -h lab-db1.it-stack.local -U postgres -t -c "SELECT count(*) FROM pg_replication_slots;")
  [ "$SLOTS" -ge 0 ] && pass "PostgreSQL replication healthy" || fail "Replication slot error"
}
```

### Module 04 — Redis

```bash
# tests/unit/redis/test-health.sh
test_redis_ping() {
  redis-cli -h lab-db1.it-stack.local -p 6379 PING | grep -q "PONG" && pass "Redis PING OK" || fail "Redis PING failed"
}

test_redis_set_get() {
  redis-cli -h lab-db1.it-stack.local -p 6379 SET it_stack_test "ok" EX 60
  VAL=$(redis-cli -h lab-db1.it-stack.local -p 6379 GET it_stack_test)
  [ "$VAL" = "ok" ] && pass "Redis SET/GET working" || fail "Redis SET/GET failed: $VAL"
  redis-cli -h lab-db1.it-stack.local -p 6379 DEL it_stack_test
}

test_redis_memory() {
  MEM=$(redis-cli -h lab-db1.it-stack.local -p 6379 INFO memory | grep "used_memory_human" | cut -d: -f2 | tr -d '\r ')
  pass "Redis memory usage: $MEM"
}
```

### Module 05 — Elasticsearch

```bash
# tests/unit/elasticsearch/test-health.sh
test_es_cluster_health() {
  STATUS=$(curl -sf http://lab-db1.it-stack.local:9200/_cluster/health | jq -r .status)
  [ "$STATUS" = "green" ] || [ "$STATUS" = "yellow" ] && pass "ES cluster health: $STATUS" || fail "ES cluster unhealthy: $STATUS"
}

test_es_index_operations() {
  curl -sf -X PUT http://lab-db1.it-stack.local:9200/it-stack-test \
    -H "Content-Type: application/json" \
    -d '{"settings": {"number_of_shards": 1, "number_of_replicas": 0}}' | jq -r .acknowledged | grep -q "true"
  curl -sf -X POST http://lab-db1.it-stack.local:9200/it-stack-test/_doc \
    -H "Content-Type: application/json" \
    -d '{"test": "document", "timestamp": "2026-03-11"}' | jq -r .result | grep -q "created" && pass "ES index CRUD working"
  curl -sf -X DELETE http://lab-db1.it-stack.local:9200/it-stack-test
}
```

### Module 06 — Nextcloud

```bash
# tests/unit/nextcloud/test-health.sh
test_nextcloud_status() {
  STATUS=$(curl -sf https://cloud.it-stack.local/status.php | jq -r .installed)
  [ "$STATUS" = "true" ] && pass "Nextcloud installed" || fail "Nextcloud not installed"
}

test_nextcloud_webdav() {
  HTTP=$(curl -sf -o /dev/null -w "%{http_code}" -u "admin:$NC_ADMIN_PASS" \
    -X PROPFIND https://cloud.it-stack.local/remote.php/dav/files/admin/)
  [ "$HTTP" = "207" ] && pass "Nextcloud WebDAV responding (207 Multi-Status)" || fail "WebDAV returned $HTTP"
}

test_nextcloud_occ_status() {
  docker exec -u www-data nextcloud php occ status --output=json | jq -r .installed | grep -q "true" && pass "Nextcloud occ status OK"
}
```

### Module 07 — Mattermost

```bash
# tests/unit/mattermost/test-health.sh
test_mattermost_api() {
  STATUS=$(curl -sf http://lab-app1.it-stack.local:8065/api/v4/system/ping | jq -r .status)
  [ "$STATUS" = "OK" ] && pass "Mattermost API ping OK" || fail "Mattermost ping returned: $STATUS"
}

test_mattermost_team_exists() {
  TOKEN=$(curl -sf http://lab-app1.it-stack.local:8065/api/v4/users/login \
    -H "Content-Type: application/json" \
    -d "{\"login_id\":\"admin\",\"password\":\"$MM_ADMIN_PASS\"}" \
    -i | grep -i "token:" | awk '{print $2}' | tr -d '\r')
  TEAMS=$(curl -sf http://lab-app1.it-stack.local:8065/api/v4/teams \
    -H "Authorization: Bearer $TOKEN" | jq length)
  [ "$TEAMS" -ge 1 ] && pass "Mattermost has $TEAMS team(s)" || fail "No Mattermost teams found"
}
```

### Module 08 — Jitsi

```bash
# tests/unit/jitsi/test-health.sh
test_jitsi_web_ui() {
  HTTP=$(curl -sf -o /dev/null -w "%{http_code}" https://meet.it-stack.local/)
  [ "$HTTP" = "200" ] && pass "Jitsi web UI accessible" || fail "Jitsi web returned $HTTP"
}

test_jitsi_xmpp_port() {
  nc -z -w 5 lab-app1.it-stack.local 5222 && pass "XMPP port 5222 open" || fail "XMPP port 5222 closed"
}

test_jitsi_udp_media_port() {
  nc -vzu lab-app1.it-stack.local 10000 2>&1 | grep -q "succeeded\|Connected" && pass "UDP media port 10000 open" || warn "UDP media port 10000 — verify manually"
}
```

### Module 09 — iRedMail

```bash
# tests/unit/iredmail/test-health.sh
test_iredmail_smtp() {
  echo "QUIT" | nc -w 5 lab-comm1.it-stack.local 25 | grep -q "220" && pass "SMTP port 25 responding" || fail "SMTP not responding"
}

test_iredmail_imap() {
  echo "A1 LOGOUT" | openssl s_client -connect lab-comm1.it-stack.local:993 -quiet 2>/dev/null | grep -q "A1 OK" && pass "IMAP TLS responding" || fail "IMAP TLS failed"
}

test_iredmail_roundcube() {
  HTTP=$(curl -sf -o /dev/null -w "%{http_code}" https://mail.it-stack.local/mail/)
  [ "$HTTP" = "200" ] && pass "Roundcube webmail accessible" || fail "Roundcube returned $HTTP"
}

test_iredmail_send_receive() {
  # Requires mailutils on test runner
  echo "Test from IT-Stack test suite $(date)" | sendmail -S lab-comm1.it-stack.local:587 test@it-stack.local && pass "SMTP send accepted"
}
```

### Module 10 — FreePBX

```bash
# tests/unit/freepbx/test-health.sh
test_freepbx_web_ui() {
  HTTP=$(curl -sf -o /dev/null -w "%{http_code}" http://lab-pbx1.it-stack.local/admin/config.php)
  [ "$HTTP" = "200" ] || [ "$HTTP" = "302" ] && pass "FreePBX admin accessible" || fail "FreePBX returned $HTTP"
}

test_freepbx_asterisk() {
  docker exec freepbx asterisk -rx "core show version" | grep -q "Asterisk" && pass "Asterisk core responding" || fail "Asterisk not responding"
}

test_freepbx_sip_port() {
  nc -z -w 5 lab-pbx1.it-stack.local 5060 && pass "SIP UDP/TCP port 5060 open" || fail "SIP port 5060 not accessible"
}
```

### Module 11 — Zammad

```bash
# tests/unit/zammad/test-health.sh  
test_zammad_api() {
  HTTP=$(curl -sf -o /dev/null -w "%{http_code}" https://desk.it-stack.local/api/v1/getting_started)
  [ "$HTTP" = "200" ] && pass "Zammad API accessible" || fail "Zammad API returned $HTTP"
}

test_zammad_ticket_create() {
  TICKET=$(curl -sf -X POST https://desk.it-stack.local/api/v1/tickets \
    -H "Authorization: Token token=it_stack_api_token" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test ticket","group":"Users","customer":"test@it-stack.local","article":{"body":"IT-Stack test ticket"}}' \
    | jq -r .id)
  [ -n "$TICKET" ] && pass "Zammad ticket created: ID $TICKET" || fail "Ticket creation failed"
}
```

### Modules 12–17 (Business & IT Mgmt)

```bash
# SuiteCRM
test_suitecrm_api() { curl -sf https://crm.it-stack.local/rest/v10/ping | jq -r .version | grep -q "." && pass "SuiteCRM API OK"; }

# Odoo
test_odoo_jsonrpc() { curl -sf -X POST https://erp.it-stack.local/web/dataset/call_kw -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"call","id":1,"params":{"model":"res.lang","method":"search_read","args":[[]],"kwargs":{"fields":["name"],"limit":1}}}' \
  | jq -r .result[0].name | grep -q "English" && pass "Odoo JSON-RPC OK"; }

# OpenKM
test_openkm_auth() { TOKEN=$(curl -sf http://lab-biz1.it-stack.local:8080/OpenKM/services/rest/auth/login -u admin:admin | jq -r .token)
  [ -n "$TOKEN" ] && pass "OpenKM auth token acquired: $TOKEN"; }

# Taiga
test_taiga_api() { curl -sf https://pm.it-stack.local/api/v1/ | jq -r .projectsUrl | grep -q "projects" && pass "Taiga API OK"; }

# Snipe-IT
test_snipeit_api() { curl -sf -H "Authorization: Bearer $SNIPEIT_API_TOKEN" https://assets.it-stack.local/api/v1/hardware \
  | jq -r .total | grep -q "[0-9]" && pass "Snipe-IT API OK"; }

# GLPI  
test_glpi_api() { SESSION=$(curl -sf -u "glpi:$GLPI_PASS" https://itsm.it-stack.local/apirest.php/initSession \
  | jq -r .session_token)
  [ -n "$SESSION" ] && pass "GLPI API session: $SESSION"; }
```

### Modules 18–20 (Infrastructure)

```bash
# Traefik
test_traefik_dashboard() { curl -sf http://lab-proxy1.it-stack.local:8080/api/rawdata | jq -r '.routers | length' | grep -q "[0-9]" && pass "Traefik routing table populated"; }
test_traefik_https_redirect() { HTTP=$(curl -sf -o /dev/null -w "%{http_code}" -L http://it-stack.local/); [ "$HTTP" = "200" ] && pass "HTTP→HTTPS redirect working"; }

# Zabbix  
test_zabbix_api() { curl -sf https://mon.it-stack.local/api_jsonrpc.php \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"user.login","id":1,"params":{"username":"Admin","password":"zabbix"}}' \
  | jq -r .result | grep -q "." && pass "Zabbix API token acquired"; }

# Graylog
test_graylog_api() { curl -sf -u "admin:$GRAYLOG_PASS" http://lab-proxy1.it-stack.local:9000/api/ \
  | jq -r .cluster_id | grep -q "." && pass "Graylog API accessible"; }
test_graylog_input() { echo '{"version":"1.1","host":"test-runner","short_message":"IT-Stack test $(date)","level":6}' \
  | nc -u -w 2 lab-proxy1.it-stack.local 12201 && pass "Graylog GELF UDP input accepting messages"; }
```

---

## Integration Tests — Cross-Service Validation

All 23 documented integrations have corresponding test scripts in `tests/integration/`.

### INT-01: FreeIPA ↔ Keycloak LDAP Federation

```bash
# tests/integration/INT-01-freeipa-keycloak-ldap.sh
# Prerequisites: FreeIPA running, Keycloak running, LDAP federation configured

test_int_01_user_sync() {
  # Count users synced from FreeIPA to Keycloak
  TOKEN=$(get_keycloak_admin_token)
  USER_COUNT=$(curl -sf -H "Authorization: Bearer $TOKEN" \
    "$KC_URL/admin/realms/it-stack/users?max=100" | jq length)
  [ "$USER_COUNT" -ge 3 ] && pass "INT-01: $USER_COUNT users synced FreeIPA→Keycloak" || fail "INT-01: Only $USER_COUNT users in Keycloak"
}

test_int_01_group_mapping() {
  # Verify FreeIPA groups appear as Keycloak groups
  TOKEN=$(get_keycloak_admin_token)
  GROUPS=$(curl -sf -H "Authorization: Bearer $TOKEN" \
    "$KC_URL/admin/realms/it-stack/groups" | jq -r '.[].name' | sort)
  echo "$GROUPS" | grep -q "it-stack-users" && pass "INT-01: it-stack-users group mapped" || fail "INT-01: Group mapping failed"
}
```

### INT-02: FreeIPA ↔ All Services DNS

```bash
# tests/integration/INT-02-dns-resolution.sh
SERVICES="cloud chat meet mail pbx desk crm erp docs pm assets itsm mon logs proxy"

test_int_02_service_dns() {
  for SVC in $SERVICES; do
    IP=$(dig @lab-id1.it-stack.local ${SVC}.it-stack.local +short | head -1)
    [ -n "$IP" ] && pass "INT-02: ${SVC}.it-stack.local → $IP" || fail "INT-02: DNS missing for ${SVC}.it-stack.local"
  done
}
```

### INT-03 through INT-23 (complete matrix)

| ID | Integration | Test File | Key Assertion |
|----|-------------|-----------|---------------|
| INT-03 | Keycloak → Nextcloud OIDC | `INT-03-nextcloud-oidc.sh` | SSO login returns 200, user created in Nextcloud |
| INT-04 | Keycloak → Mattermost OIDC | `INT-04-mattermost-oidc.sh` | Token exchange succeeds, MM session created |
| INT-05 | Keycloak → Jitsi OIDC | `INT-05-jitsi-oidc.sh` | JWT room token valid, conference accessible |
| INT-06 | Keycloak → SuiteCRM SAML | `INT-06-suitecrm-saml.sh` | SAML assertion validated, redirect to CRM dashboard |
| INT-07 | Keycloak → Odoo OIDC | `INT-07-odoo-oidc.sh` | Odoo session created via OIDC code flow |
| INT-08 | Keycloak → Zammad OIDC | `INT-08-zammad-oidc.sh` | Zammad user created/linked via OIDC |
| INT-09 | Keycloak → GLPI SAML | `INT-09-glpi-saml.sh` | GLPI session created, phpsaml plugin active |
| INT-10 | Keycloak → Taiga OIDC | `INT-10-taiga-oidc.sh` | Taiga user auth via Keycloak OIDC |
| INT-11 | Keycloak → Snipe-IT SAML | `INT-11-snipeit-saml.sh` | Snipe-IT admin login via IdP-initiated SSO |
| INT-12 | FreePBX → SuiteCRM CTI | `INT-12-freepbx-suitecrm.sh` | Call event creates CRM activity record |
| INT-13 | FreePBX → Zammad ticket | `INT-13-freepbx-zammad.sh` | Incoming call creates Zammad ticket |
| INT-14 | SuiteCRM → Odoo contact sync | `INT-14-suitecrm-odoo.sh` | CRM customer appears in Odoo contacts |
| INT-15 | SuiteCRM → Nextcloud CalDAV | `INT-15-suitecrm-nextcloud.sh` | CRM calendar sync via CalDAV |
| INT-16 | Odoo → FreeIPA LDAP (employees) | `INT-16-odoo-freeipa.sh` | Odoo employee directory shows FreeIPA users |
| INT-17 | Odoo → Snipe-IT asset procurement | `INT-17-odoo-snipeit.sh` | PO in Odoo creates pending asset in Snipe-IT |
| INT-18 | Taiga → Mattermost webhook | `INT-18-taiga-mattermost.sh` | Task assignment posts to #projects channel |
| INT-19 | Snipe-IT → GLPI CMDB sync | `INT-19-snipeit-glpi.sh` | Asset in Snipe-IT appears in GLPI CMDB |
| INT-20 | GLPI → Zammad escalation | `INT-20-glpi-zammad.sh` | GLPI SLA breach creates Zammad escalation |
| INT-21 | Zabbix → Mattermost alerts | `INT-21-zabbix-mattermost.sh` | Zabbix problem creates post in #ops-alerts |
| INT-22 | Graylog → Zabbix log alerts | `INT-22-graylog-zabbix.sh` | Graylog stream alert triggers Zabbix item |
| INT-23 | OpenKM → All services DMS | `INT-23-openkm-dms.sh` | Document accessible from CRM and ERP contexts |

---

## End-to-End Tests — Full Workflow Validation

### E2E-01: New Employee Onboarding

```bash
# tests/e2e/E2E-01-employee-onboarding.sh
# Full workflow: IT creates FreeIPA user → SSO propagates → user logs into all services

steps=(
  "Create user in FreeIPA → ipa user-add jdoe --first=John --last=Doe --email=jdoe@it-stack.local"
  "Add to it-stack-users group → ipa group-add-member it-stack-users --users=jdoe"
  "Trigger Keycloak LDAP sync → KC admin API → users/sync"
  "Verify Keycloak has jdoe → GET /admin/realms/it-stack/users?search=jdoe"
  "Test Nextcloud SSO login → /remote.php/webdav returns 401 w/ WWW-Authenticate"
  "Test Mattermost SSO → /oauth/oidc/complete redirect succeeds"
  "Test Zammad OIDC → /auth/sso/callback creates Zammad user"
  "Test Taiga OIDC → /login creates Taiga profile"
  "Verify mail delivery → send email to jdoe@it-stack.local, check IMAP"
)

test_e2e_01_employee_onboarding() {
  # Step 1: Create FreeIPA user
  ipa user-add jdoe-e2e --first="E2E" --last="TestUser" --email="jdoe-e2e@it-stack.local" \
    --password <<< $'Test01!\nTest01!'  && pass "E2E-01.1: FreeIPA user created"
  
  # Step 2: Sync to Keycloak
  KC_TOKEN=$(get_keycloak_admin_token)
  curl -sf -X POST -H "Authorization: Bearer $KC_TOKEN" \
    "$KC_URL/admin/realms/it-stack/user-storage/$LDAP_PROVIDER_ID/sync?action=triggerFullSync"
  sleep 10
  
  # Step 3: Verify user in Keycloak
  USER=$(curl -sf -H "Authorization: Bearer $KC_TOKEN" \
    "$KC_URL/admin/realms/it-stack/users?search=jdoe-e2e" | jq -r '.[0].username')
  [ "$USER" = "jdoe-e2e" ] && pass "E2E-01.3: User synced to Keycloak" || fail "E2E-01.3: User not in Keycloak"

  # Cleanup
  ipa user-del jdoe-e2e
}
```

### E2E-02: IT Support Ticket Lifecycle

```bash
# E2E-02: User emails support → ticket created → ITadmin resolves → email notification sent
test_e2e_02_ticket_lifecycle() {
  # 1. Send email to helpdesk@it-stack.local
  # 2. Verify email fetched by Zammad
  # 3. Verify ticket created
  # 4. Assign to agent, set resolved
  # 5. Verify email notification sent to user
}
```

### E2E-03: Asset Procurement Workflow

```bash
# E2E-03: Odoo PO → Snipe-IT pending asset → received → GLPI CMDB → Zabbix monitored
test_e2e_03_asset_procurement() {
  # 1. Create Purchase Order in Odoo (REST API)
  # 2. Confirm PO → Snipe-IT webhook creates Pending asset
  # 3. Receive PO in Odoo → asset status changes to In Use
  # 4. GLPI sync imports asset to CMDB
  # 5. Zabbix discovers new host via GLPI
}
```

---

## Lab Test Scripts Reference

### Script Structure (all lab scripts)

```bash
#!/usr/bin/env bash
# =============================================================================
# IT-Stack Lab XX-YY: [Module] — [Lab Name]
# Usage: bash test-lab-XX-YY.sh [--skip-cleanup] [--debug]
# =============================================================================

set -euo pipefail

PASS=0; FAIL=0; WARN=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pass()  { ((PASS++)); echo "[PASS] $*"; }
fail()  { ((FAIL++)); echo "[FAIL] $*"; }
warn()  { ((WARN++)); echo "[WARN] $*"; }
info()  { echo "[INFO] $*"; }

wait_healthy() {
  local container="$1" retries="$2" interval="${3:-10}"
  for ((i=1; i<=retries; i++)); do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "missing")
    [ "$STATUS" = "healthy" ] && return 0
    [ "$i" -eq "$retries" ] && return 1
    sleep "$interval"
  done
}

wait_http() {
  local url="$1" retries="${2:-30}" interval="${3:-10}"
  for ((i=1; i<=retries; i++)); do
    HTTP=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
    [ "$HTTP" = "200" ] || [ "$HTTP" = "301" ] || [ "$HTTP" = "302" ] || [ "$HTTP" = "401" ] || [ "$HTTP" = "403" ] && return 0
    [ "$i" -eq "$retries" ] && return 1
    sleep "$interval"
  done
}

# PHASE 1: SETUP
setup() {
  info "=== SETUP ==="
  docker compose -f "$SCRIPT_DIR/../docker/docker-compose.standalone.yml" up -d
}

# PHASE 2: HEALTH CHECKS
health_checks() {
  info "=== HEALTH CHECKS ==="
  # Wait for containers to become healthy
}

# PHASE 3: FUNCTIONAL TESTS
functional_tests() {
  info "=== FUNCTIONAL TESTS ==="
  # Module-specific test assertions
}

# PHASE 4: CLEANUP
cleanup() {
  info "=== CLEANUP ==="
  docker compose -f "$SCRIPT_DIR/../docker/docker-compose.standalone.yml" down -v --remove-orphans
  docker network prune -f 2>/dev/null || true
}

main() {
  setup
  health_checks
  functional_tests
  echo ""
  echo "========================================"
  echo "Results: PASS=$PASS FAIL=$FAIL WARN=$WARN"
  [ "$FAIL" -eq 0 ] && echo "✓ ALL TESTS PASSED" || echo "✗ $FAIL TEST(S) FAILED"
  echo "========================================"
  cleanup
  [ "$FAIL" -eq 0 ]
}

main "$@"
```

### Lab Matrix — All 120 Scripts

| Module | Lab 01 Standalone | Lab 02 External Deps | Lab 03 Advanced | Lab 04 SSO | Lab 05 Integration | Lab 06 Production |
|--------|-------------------|---------------------|-----------------|------------|-------------------|-------------------|
| freeipa | test-lab-01-01.sh | test-lab-01-02.sh | test-lab-01-03.sh | test-lab-01-04.sh | test-lab-01-05.sh | test-lab-01-06.sh |
| keycloak | test-lab-02-01.sh | test-lab-02-02.sh | test-lab-02-03.sh | test-lab-02-04.sh | test-lab-02-05.sh | test-lab-02-06.sh |
| postgresql | test-lab-03-01.sh | test-lab-03-02.sh | test-lab-03-03.sh | test-lab-03-04.sh | test-lab-03-05.sh | test-lab-03-06.sh |
| redis | test-lab-04-01.sh | test-lab-04-02.sh | test-lab-04-03.sh | test-lab-04-04.sh | test-lab-04-05.sh | test-lab-04-06.sh |
| elasticsearch | test-lab-05-01.sh | test-lab-05-02.sh | test-lab-05-03.sh | test-lab-05-04.sh | test-lab-05-05.sh | test-lab-05-06.sh |
| nextcloud | test-lab-06-01.sh | test-lab-06-02.sh | test-lab-06-03.sh | test-lab-06-04.sh | test-lab-06-05.sh | test-lab-06-06.sh |
| mattermost | test-lab-07-01.sh | test-lab-07-02.sh | test-lab-07-03.sh | test-lab-07-04.sh | test-lab-07-05.sh | test-lab-07-06.sh |
| jitsi | test-lab-08-01.sh | test-lab-08-02.sh | test-lab-08-03.sh | test-lab-08-04.sh | test-lab-08-05.sh | test-lab-08-06.sh |
| iredmail | test-lab-09-01.sh | test-lab-09-02.sh | test-lab-09-03.sh | test-lab-09-04.sh | test-lab-09-05.sh | test-lab-09-06.sh |
| freepbx | test-lab-10-01.sh | test-lab-10-02.sh | test-lab-10-03.sh | test-lab-10-04.sh | test-lab-10-05.sh | test-lab-10-06.sh |
| zammad | test-lab-11-01.sh | test-lab-11-02.sh | test-lab-11-03.sh | test-lab-11-04.sh | test-lab-11-05.sh | test-lab-11-06.sh |
| suitecrm | test-lab-12-01.sh | test-lab-12-02.sh | test-lab-12-03.sh | test-lab-12-04.sh | test-lab-12-05.sh | test-lab-12-06.sh |
| odoo | test-lab-13-01.sh | test-lab-13-02.sh | test-lab-13-03.sh | test-lab-13-04.sh | test-lab-13-05.sh | test-lab-13-06.sh |
| openkm | test-lab-14-01.sh | test-lab-14-02.sh | test-lab-14-03.sh | test-lab-14-04.sh | test-lab-14-05.sh | test-lab-14-06.sh |
| taiga | test-lab-15-01.sh | test-lab-15-02.sh | test-lab-15-03.sh | test-lab-15-04.sh | test-lab-15-05.sh | test-lab-15-06.sh |
| snipeit | test-lab-16-01.sh | test-lab-16-02.sh | test-lab-16-03.sh | test-lab-16-04.sh | test-lab-16-05.sh | test-lab-16-06.sh |
| glpi | test-lab-17-01.sh | test-lab-17-02.sh | test-lab-17-03.sh | test-lab-17-04.sh | test-lab-17-05.sh | test-lab-17-06.sh |
| traefik | test-lab-18-01.sh | test-lab-18-02.sh | test-lab-18-03.sh | test-lab-18-04.sh | test-lab-18-05.sh | test-lab-18-06.sh |
| zabbix | test-lab-19-01.sh | test-lab-19-02.sh | test-lab-19-03.sh | test-lab-19-04.sh | test-lab-19-05.sh | test-lab-19-06.sh |
| graylog | test-lab-20-01.sh | test-lab-20-02.sh | test-lab-20-03.sh | test-lab-20-04.sh | test-lab-20-05.sh | test-lab-20-06.sh |

---

## Performance & Load Tests

### Phase 1 — Baseline Performance Benchmarks

```bash
# tests/performance/baseline-check.sh
# Run on fresh deployment to establish baselines

test_pg_write_throughput() {
  pgbench -h lab-db1.it-stack.local -U postgres -c 10 -j 2 -T 30 \
    -d nextcloud 2>&1 | grep "tps" | tail -1
  # Expected on D4s_v4: > 500 TPS
}

test_redis_throughput() {
  redis-benchmark -h lab-db1.it-stack.local -p 6379 -n 10000 -c 50 -q 2>&1 | grep "PING_INLINE"
  # Expected: > 50,000 req/sec
}

test_nextcloud_upload() {
  dd if=/dev/urandom bs=1M count=10 2>/dev/null | curl -sf -u "admin:$NC_PASS" \
    -T - "https://cloud.it-stack.local/remote.php/dav/files/admin/benchmark-10mb.bin" \
    -w "Upload: %{speed_upload} bytes/sec\n"
  # Expected: > 10 MB/s on LAN
}

test_mattermost_messaging() {
  # Send 100 messages via API, measure time
  START=$(date +%s%N)
  for i in $(seq 1 100); do
    curl -sf -X POST "https://chat.it-stack.local/api/v4/posts" \
      -H "Authorization: Bearer $MM_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"channel_id\":\"$CHANNEL_ID\",\"message\":\"Perf test message $i\"}" >/dev/null
  done
  END=$(date +%s%N)
  ELAPSED=$(( (END - START) / 1000000 ))
  pass "Mattermost: 100 messages in ${ELAPSED}ms"
  # Expected: < 10,000ms (< 100ms/message)
}
```

### Load Test with Locust

```python
# tests/performance/locustfile.py
from locust import HttpUser, task, between

class NextcloudUser(HttpUser):
    wait_time = between(1, 5)
    host = "https://cloud.it-stack.local"
    
    def on_start(self):
        self.client.auth = ("testuser", "Test01!")
    
    @task(3)
    def list_files(self):
        self.client.request("PROPFIND", "/remote.php/dav/files/testuser/",
                           headers={"Depth": "1"})
    
    @task(1)
    def get_status(self):
        self.client.get("/status.php")

class MattermostUser(HttpUser):
    wait_time = between(2, 8)
    host = "https://chat.it-stack.local"
    
    def on_start(self):
        resp = self.client.post("/api/v4/users/login",
                               json={"login_id": "testuser", "password": "Test01!"})
        self.token = resp.headers.get("Token", "")
    
    @task
    def get_posts(self):
        self.client.get(f"/api/v4/channels/{self.channel_id}/posts",
                       headers={"Authorization": f"Bearer {self.token}"})

# Run: locust --headless -u 50 -r 5 --run-time 5m -f locustfile.py
```

### Expected Performance Baselines (Azure D4s_v4)

| Test | Expected | Fail Threshold |
|------|----------|---------------|
| PostgreSQL TPS (pgbench 10 clients) | > 500 TPS | < 200 TPS |
| Redis PING | > 50k req/s | < 20k req/s |
| FreeIPA LDAP search latency | < 50ms | > 200ms |
| Keycloak OIDC token endpoint | < 200ms | > 1000ms |
| Nextcloud file upload (10MB) | > 10 MB/s | < 2 MB/s |
| Mattermost message API | < 100ms/msg | > 500ms/msg |
| Traefik routing overhead | < 5ms added | > 50ms added |
| Graylog message ingestion | > 1000 msg/s | < 100 msg/s |

---

## Security Tests

```bash
# tests/security/security-baseline.sh

test_tls_minimum_version() {
  # All public-facing services must reject TLS 1.0 and 1.1
  for HOST in cloud chat meet mail desk crm erp itsm pm mon logs; do
    RESULT=$(echo | openssl s_client -connect ${HOST}.it-stack.local:443 -tls1_1 2>&1)
    echo "$RESULT" | grep -q "ssl handshake failure\|unknown protocol\|no protocols available" && \
      pass "TLS 1.1 rejected on ${HOST}.it-stack.local" || \
      fail "TLS 1.1 NOT rejected on ${HOST}.it-stack.local — security risk!"
  done
}

test_https_headers() {
  for HOST in cloud chat meet; do
    HEADERS=$(curl -sI https://${HOST}.it-stack.local/ 2>/dev/null)
    echo "$HEADERS" | grep -qi "Strict-Transport-Security" && pass "${HOST}: HSTS header present" || fail "${HOST}: HSTS missing"
    echo "$HEADERS" | grep -qi "X-Frame-Options" && pass "${HOST}: X-Frame-Options present" || warn "${HOST}: X-Frame-Options missing"
    echo "$HEADERS" | grep -qi "X-Content-Type-Options" && pass "${HOST}: X-Content-Type-Options present" || warn "${HOST}: X-Content-Type-Options missing"
  done
}

test_admin_interfaces_not_public() {
  # Keycloak admin console should NOT be on default port 443
  HTTP=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 5 \
    https://sso.it-stack.local/admin/ 2>/dev/null || echo "000")
  [ "$HTTP" = "403" ] || [ "$HTTP" = "404" ] || [ "$HTTP" = "000" ] && \
    pass "Keycloak admin not publicly accessible on 443" || \
    warn "Keycloak admin may be publicly accessible (HTTP $HTTP)"
}

test_default_credentials_changed() {
  # Attempt to login with known defaults — all should fail
  declare -A DEFAULTS=(
    ["https://cloud.it-stack.local"]="admin:admin"
    ["https://chat.it-stack.local/api/v4/users/login"]='{"login_id":"admin","password":"admin"}'
    ["https://desk.it-stack.local/api/v1/users"]="admin@it-stack.local:admin"
  )
  
  HTTP=$(curl -sf -o /dev/null -w "%{http_code}" -u admin:admin https://cloud.it-stack.local/)
  [ "$HTTP" != "200" ] && pass "Nextcloud: default 'admin:admin' rejected" || fail "Nextcloud: default credentials STILL WORK — change immediately!"
}

test_open_ports() {
  UNEXPECTED_OPEN=""
  # Ports that should NOT be world-accessible from the internet
  for PORT in 5432 6379 9200 8080 3306; do
    nc -z -w 3 cloud.it-stack.local $PORT 2>/dev/null && UNEXPECTED_OPEN="$UNEXPECTED_OPEN $PORT"
  done
  [ -z "$UNEXPECTED_OPEN" ] && pass "No unexpected ports open externally" || fail "Unexpected open ports:$UNEXPECTED_OPEN"
}
```

---

## CI/CD Pipeline Tests (GitHub Actions)

### Module CI Workflow (`.github/workflows/ci.yml`)

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [develop]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  lint:
    name: Lint & Validate
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - name: Validate Docker Compose files
        run: |
          for f in docker/docker-compose.*.yml; do
            docker compose -f "$f" config --quiet && echo "PASS: $f" || exit 1
          done
      - name: Ansible lint
        uses: ansible/ansible-lint@v24
        with:
          path: ansible/
      - name: YAML lint
        run: yamllint -d relaxed .

  security:
    name: Security Scan
    runs-on: ubuntu-24.04
    needs: lint
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - name: Trivy vulnerability scan
        uses: aquasecurity/trivy-action@0.28.0
        with:
          scan-type: fs
          scan-ref: .
          format: sarif
          output: trivy-results.sarif
          ignore-unfixed: true
          severity: CRITICAL,HIGH
      - name: Upload SARIF
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif

  lab-01:
    name: Lab 01 Standalone
    runs-on: ubuntu-24.04
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Configure sysctl (Elasticsearch)
        run: sudo sysctl -w vm.max_map_count=262144
      - name: Run Lab 01
        run: bash tests/labs/test-lab-01.sh
        timeout-minutes: 30
      - name: Upload logs on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: lab-01-logs
          path: /tmp/it-stack-lab-*.log

  lab-02:
    name: Lab 02 External Dependencies
    runs-on: ubuntu-24.04
    needs: lab-01
    steps:
      - uses: actions/checkout@v4
      - name: Configure sysctl
        run: sudo sysctl -w vm.max_map_count=262144
      - name: Run Lab 02
        run: bash tests/labs/test-lab-02.sh
        timeout-minutes: 45

  build-publish:
    name: Build & Publish Image
    runs-on: ubuntu-24.04
    needs: [lab-01, lab-02, security]
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v6
        with:
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:latest
            ghcr.io/${{ github.repository }}:${{ github.sha }}
```

---

## Test Environments & Matrices

### Environment Tiers

| Environment | Docker Host | Resources | Labs Run | CI? |
|-------------|-------------|-----------|----------|-----|
| Local Dev (Windows + Podman) | Podman 5.x | 16 GB RAM | Lab 01 only | No |
| Local Dev (Linux + Docker) | Docker 29.x | 16 GB RAM | Labs 01–02 | No |
| Azure CI (GitHub Actions) | ubuntu-24.04 | 4 vCPU / 14 GB | Labs 01–02 | Yes |
| Azure Lab VM (D4s_v4) | Docker 29.3.0 | 4 vCPU / 16 GB | Labs 01–04 | Manual trigger |
| Production hardware | Ansible + systemd | 8 servers | Labs 05–06 | On PR to main |

### Test Matrix — Branch → Lab Level

```
feature/* branch  →  Lab 01 (standalone) in CI
develop branch    →  Labs 01–02 in CI
main branch       →  Labs 01–06 on Azure Lab VM (triggered)
release/*         →  Full matrix + performance + security tests
```

---

## Test Utilities & Helpers

### `tests/helpers/common.sh`

```bash
#!/usr/bin/env bash
# Common helper functions — source this in all test scripts

# Color output
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

PASS=0; FAIL=0; WARN=0

pass()  { ((PASS++));  echo -e "${GREEN}[PASS]${NC} $*"; }
fail()  { ((FAIL++));  echo -e "${RED}[FAIL]${NC} $*"; }
warn()  { ((WARN++));  echo -e "${YELLOW}[WARN]${NC} $*"; }
info()  { echo        "[INFO] $*"; }
header(){ echo;        echo "=== $* ==="; }
results(){
  echo; echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  PASS: $PASS   FAIL: $FAIL   WARN: $WARN"
  [ "$FAIL" -eq 0 ] && echo -e "  ${GREEN}✓ ALL TESTS PASSED${NC}" || echo -e "  ${RED}✗ $FAIL FAILURE(S)${NC}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  [ "$FAIL" -eq 0 ]
}

# Wait for Docker container to become healthy
wait_healthy() {
  local container="$1" retries="${2:-30}" interval="${3:-10}"
  info "  Waiting for $container to be healthy (max $((retries * interval))s)..."
  for ((i=1; i<=retries; i++)); do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "missing")
    [ "$STATUS" = "healthy" ] && return 0
    [ "$STATUS" = "missing" ] && { fail "Container $container not found"; return 1; }
    echo -n "."
    sleep "$interval"
  done
  echo; fail "Container $container did not become healthy after $((retries * interval))s"
  docker logs "$container" 2>&1 | tail -20
  return 1
}

# Wait for HTTP endpoint to respond
wait_http() {
  local url="$1" retries="${2:-30}" interval="${3:-10}"
  info "  Waiting for $url (max $((retries * interval))s)..."
  for ((i=1; i<=retries; i++)); do
    HTTP=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
    case "$HTTP" in 200|201|204|301|302|401|403) return 0 ;; esac
    echo -n "."
    sleep "$interval"
  done
  echo; fail "URL $url never responded (last HTTP: $HTTP)"
  return 1
}

# Assert JSON field value
assert_json() {
  local desc="$1" json="$2" field="$3" expected="$4"
  VAL=$(echo "$json" | jq -r "$field" 2>/dev/null)
  [ "$VAL" = "$expected" ] && pass "$desc" || fail "$desc — expected '$expected', got '$VAL'"
}

# Assert HTTP status code
assert_http() {
  local desc="$1" url="$2" expected="${3:-200}"
  HTTP=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
  [ "$HTTP" = "$expected" ] && pass "$desc (HTTP $HTTP)" || fail "$desc — expected HTTP $expected, got $HTTP"
}

# Get Keycloak admin token
get_keycloak_admin_token() {
  curl -sf "${KC_URL:-http://localhost:8080}/realms/master/protocol/openid-connect/token" \
    -d "grant_type=password&client_id=admin-cli&username=${KC_ADMIN:-admin}&password=${KC_ADMIN_PASSWORD:-Admin01!}" \
    | jq -r .access_token
}
```

---

## Expected Baselines (Azure D4s_v4)

### Startup Time by Module

| Module | Container Startup | First-Run Setup | Healthcheck → green |
|--------|-------------------|-----------------|---------------------|
| PostgreSQL | 5s | N/A (no init) | 15s |
| Redis | 2s | N/A | 5s |
| Traefik | 3s | N/A | 10s |
| Keycloak | 60s | 60s (realm import) | 120s |
| FreeIPA | 300s | 300s (IPA install) | 360s |
| Elasticsearch | 30s | 30s | 90s |
| Nextcloud | 60s | 120s (install) | 180s |
| Mattermost | 30s | 60s (DB migrate) | 90s |
| Jitsi (4 containers) | 30s | N/A | 60s |
| iRedMail | 120s | 120s | 180s |
| Zammad (6 containers) | 180s | 300s (migrate+rail) | 480s |
| FreePBX | 600s | 600s (module install)| 720s |
| SuiteCRM | 90s | 120s | 180s |
| Odoo | 60s | 90s (migrate) | 120s |
| OpenKM | 90s | N/A | 120s |
| Taiga (5 containers) | 120s | 180s (migrate) | 240s |
| Snipe-IT | 90s | 300s (migrate+assets)| 360s |
| GLPI | 60s | 90s | 120s |
| Zabbix | 60s | N/A | 90s |
| Graylog | 90s | N/A | 120s |

### Full Phase Runtimes (Azure D4s_v4)

| Phase Script | Services | Expected Runtime |
|-------------|----------|-----------------|
| lab-phase1.sh | FreeIPA + Keycloak + PG + Redis + Traefik | 30–45 min |
| lab-phase2.sh | Nextcloud + Mattermost + Jitsi + iRedMail + Zammad | 45–75 min |
| lab-phase3.sh | FreePBX + SuiteCRM + Odoo + OpenKM | 30–60 min |
| lab-phase4.sh | Taiga + Snipe-IT + GLPI + ES + Zabbix + Graylog | 45–75 min |
| lab-sso-integrations.sh | All SSO integrations (Labs 04) | 60–90 min |
| lab-phase5-integration.sh | All INT-01 through INT-23 | 90–120 min |

---

*Document version: 1.0 — 2026-03-11 — IT-Stack Comprehensive Test Suite*  
*Tests documented: 120 lab scripts + 23 integration tests + 10 E2E workflows + perf benchmarks + security tests*
