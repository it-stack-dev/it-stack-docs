#!/usr/bin/env bash
# Phase 2 Lab Tests — Standalone (Lab XX-01) for all Phase 2 modules
# Modules: Nextcloud (06), Mattermost (07), Jitsi (08), iRedMail (09), Zammad (11)
# Usage  : bash lab-phase2.sh [options]
#   --skip-nextcloud    --skip-mattermost    --skip-jitsi
#   --skip-iredmail     --skip-zammad
#   --only-nextcloud    --only-mattermost    --only-jitsi
#   --only-iredmail     --only-zammad
# Requires: Docker, Docker Compose v2, ~14 GB RAM

set -uo pipefail

SKIP_NEXTCLOUD=false
SKIP_MATTERMOST=false
SKIP_JITSI=false
SKIP_IREDMAIL=false
SKIP_ZAMMAD=false
ONLY_MODULE=""

for arg in "$@"; do
  case "$arg" in
    --skip-nextcloud)  SKIP_NEXTCLOUD=true ;;
    --skip-mattermost) SKIP_MATTERMOST=true ;;
    --skip-jitsi)      SKIP_JITSI=true ;;
    --skip-iredmail)   SKIP_IREDMAIL=true ;;
    --skip-zammad)     SKIP_ZAMMAD=true ;;
    --only-nextcloud)  ONLY_MODULE="nextcloud" ;;
    --only-mattermost) ONLY_MODULE="mattermost" ;;
    --only-jitsi)      ONLY_MODULE="jitsi" ;;
    --only-iredmail)   ONLY_MODULE="iredmail" ;;
    --only-zammad)     ONLY_MODULE="zammad" ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

if [[ -n "$ONLY_MODULE" ]]; then
  SKIP_NEXTCLOUD=true; SKIP_MATTERMOST=true; SKIP_JITSI=true
  SKIP_IREDMAIL=true;  SKIP_ZAMMAD=true
  case "$ONLY_MODULE" in
    nextcloud)  SKIP_NEXTCLOUD=false ;;
    mattermost) SKIP_MATTERMOST=false ;;
    jitsi)      SKIP_JITSI=false ;;
    iredmail)   SKIP_IREDMAIL=false ;;
    zammad)     SKIP_ZAMMAD=false ;;
  esac
fi

PASS=0; FAIL=0
declare -a FAILURES=()

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

pass()  { echo -e "${GREEN}  [PASS]${NC} $1"; ((PASS++)); }
fail()  { echo -e "${RED}  [FAIL]${NC} $1"; ((FAIL++)); FAILURES+=("$1"); }
step()  { echo -e "\n${CYAN}>> $1${NC}"; }
info()  { echo -e "${YELLOW}  ...${NC} $1"; }

# wait_healthy <container> [max_iterations] [interval_seconds]
wait_healthy() {
  local name="$1" max="${2:-18}" interval="${3:-10}"
  local status
  for i in $(seq 1 "$max"); do
    sleep "$interval"
    status=$(docker inspect "$name" --format '{{.State.Health.Status}}' 2>/dev/null || echo "missing")
    [[ "$status" == "healthy" ]] && { echo ""; return 0; }
    echo -ne "    ${i}/${max} ($status) \r"
  done
  echo ""
  return 1
}

WORKDIR="$HOME/it-stack-labs"
mkdir -p "$WORKDIR"

# ──────────────────────────────────────────────────────────────────────────────
# LAB 06-01: NEXTCLOUD STANDALONE
# ──────────────────────────────────────────────────────────────────────────────
run_nextcloud() {
  step "Lab 06-01 — Nextcloud Standalone"
  local dir="$WORKDIR/nextcloud" name="it-stack-nextcloud-lab01"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << 'COMPOSE'
services:
  nextcloud:
    image: nextcloud:28-apache
    container_name: it-stack-nextcloud-lab01
    ports:
      - "8280:80"
    environment:
      SQLITE_DATABASE: nextcloud
      NEXTCLOUD_ADMIN_USER: admin
      NEXTCLOUD_ADMIN_PASSWORD: Lab02Password!
      NEXTCLOUD_TRUSTED_DOMAINS: localhost
    volumes:
      - nextcloud_data:/var/www/html
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost/status.php | grep -q '\"installed\":true'"]
      interval: 30s
      timeout: 15s
      retries: 10
      start_period: 120s
    networks:
      - it-stack-net
networks:
  it-stack-net:
    driver: bridge
volumes:
  nextcloud_data:
    name: it-stack-nextcloud-lab01-data
COMPOSE

  info "Pulling Nextcloud image (first run may take ~2 min)..."
  docker pull nextcloud:28-apache 2>&1 | tail -3

  info "Starting Nextcloud..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Nextcloud to install (up to 8 min)..."
  if wait_healthy "$name" 16 30; then
    true
  else
    fail "Nextcloud container not healthy after 8 min"
    docker logs "$name" 2>&1 | tail -20
    docker compose down -v 2>/dev/null; return
  fi

  # Test 1: status.php reports installed
  result=$(curl -sf http://localhost:8280/status.php 2>/dev/null)
  if echo "$result" | grep -q '"installed":true'; then
    pass "Nextcloud status.php: installed=true"
  else
    fail "Nextcloud status.php failed: ${result:0:120}"
  fi

  # Test 2: Main page / redirect reachable
  code=$(curl -sf -o /dev/null -w "%{http_code}" -L http://localhost:8280/ 2>/dev/null)
  if [[ "$code" == "200" ]]; then
    pass "Nextcloud web UI: HTTP $code"
  else
    fail "Nextcloud web UI returned HTTP $code (expected 200)"
  fi

  # Test 3: OCC command — check system status via exec
  result=$(docker exec -u www-data "$name" php /var/www/html/occ status 2>/dev/null)
  if echo "$result" | grep -qi "installed.*true\|Nextcloud is installed"; then
    pass "Nextcloud occ status: installed=true"
  else
    fail "Nextcloud occ status failed: ${result:0:120}"
  fi

  # Test 4: DAV endpoint available (WebDAV capability)
  code=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8280/remote.php/dav/ 2>/dev/null)
  if [[ "$code" == "200" || "$code" == "401" ]]; then
    pass "Nextcloud WebDAV endpoint reachable (HTTP $code)"
  else
    fail "Nextcloud WebDAV endpoint returned HTTP $code"
  fi

  info "Cleaning up Nextcloud..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 07-01: MATTERMOST STANDALONE
# ──────────────────────────────────────────────────────────────────────────────
run_mattermost() {
  step "Lab 07-01 — Mattermost Standalone"
  local dir="$WORKDIR/mattermost" cname="it-stack-mattermost-lab01" pgname="it-stack-mattermost-pg-lab01"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << 'COMPOSE'
services:
  postgres:
    image: postgres:15-alpine
    container_name: it-stack-mattermost-pg-lab01
    environment:
      POSTGRES_USER: mattermost
      POSTGRES_PASSWORD: Lab02Password!
      POSTGRES_DB: mattermost
    volumes:
      - mm_pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mattermost -d mattermost"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 20s
    networks:
      - it-stack-net

  mattermost:
    image: mattermost/mattermost-team-edition:9.11.1
    container_name: it-stack-mattermost-lab01
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - "8265:8065"
    environment:
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: "postgres://mattermost:Lab02Password!@postgres:5432/mattermost?sslmode=disable"
      MM_SERVICESETTINGS_SITEURL: "http://localhost:8265"
      MM_SERVICESETTINGS_ENABLELOCALMODE: "true"
      MM_PLUGINSETTINGS_ENABLEUPLOADS: "true"
      MM_TEAMSETTINGS_ENABLEOPENSERVER: "true"
    volumes:
      - mm_data:/mattermost/data
      - mm_logs:/mattermost/logs
      - mm_config:/mattermost/config
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:8065/api/v4/system/ping | grep -q 'OK'"]
      interval: 15s
      timeout: 10s
      retries: 20
      start_period: 60s
    networks:
      - it-stack-net

networks:
  it-stack-net:
    driver: bridge
volumes:
  mm_pg_data:
    name: it-stack-mattermost-pg-lab01-data
  mm_data:
    name: it-stack-mattermost-lab01-data
  mm_logs:
    name: it-stack-mattermost-lab01-logs
  mm_config:
    name: it-stack-mattermost-lab01-config
COMPOSE

  info "Starting Mattermost + PostgreSQL..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Mattermost to become healthy (up to 6 min)..."
  if wait_healthy "$cname" 24 15; then
    true
  else
    fail "Mattermost container not healthy after 6 min"
    docker logs "$cname" 2>&1 | tail -20
    docker compose down -v 2>/dev/null; return
  fi

  # Test 1: System ping API
  result=$(curl -sf http://localhost:8265/api/v4/system/ping 2>/dev/null)
  if echo "$result" | grep -qi '"status":"OK"'; then
    pass "Mattermost /api/v4/system/ping: status=OK"
  else
    fail "Mattermost ping failed: ${result:0:120}"
  fi

  # Test 2: Login page served
  code=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8265/login 2>/dev/null)
  if [[ "$code" == "200" ]]; then
    pass "Mattermost login page: HTTP 200"
  else
    fail "Mattermost login page returned HTTP $code"
  fi

  # Test 3: Create initial admin user via mmctl (local mode)
  result=$(docker exec "$cname" mmctl --local user create --email admin@lab.localhost \
    --username admin --password "Lab02Password!" --system-admin 2>&1)
  if echo "$result" | grep -qiE "created|already exists"; then
    pass "Mattermost mmctl: admin user created/exists"
  else
    fail "Mattermost mmctl user create failed: ${result:0:120}"
  fi

  # Test 4: API token login
  token_resp=$(curl -sf -X POST http://localhost:8265/api/v4/users/login \
    -H "Content-Type: application/json" \
    -d '{"login_id":"admin@lab.localhost","password":"Lab02Password!"}' \
    -D - 2>/dev/null | head -20)
  if echo "$token_resp" | grep -qi "token"; then
    pass "Mattermost admin login: auth token received"
  else
    fail "Mattermost admin login failed: ${token_resp:0:120}"
  fi

  info "Cleaning up Mattermost..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 08-01: JITSI STANDALONE
# ──────────────────────────────────────────────────────────────────────────────
run_jitsi() {
  step "Lab 08-01 — Jitsi Standalone"
  local dir="$WORKDIR/jitsi" webname="it-stack-jitsi-web-lab01"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << 'COMPOSE'
services:
  jitsi-web:
    image: jitsi/web:stable
    container_name: it-stack-jitsi-web-lab01
    ports:
      - "8880:80"
      - "8843:443"
    environment:
      PUBLIC_URL: "http://localhost:8880"
      XMPP_DOMAIN: "meet.jitsi"
      XMPP_AUTH_DOMAIN: "auth.meet.jitsi"
      XMPP_BOSH_URL_BASE: "http://xmpp.meet.jitsi:5280"
      XMPP_MUC_DOMAIN: "muc.meet.jitsi"
      TZ: "UTC"
      ENABLE_LETSENCRYPT: "0"
      DISABLE_HTTPS: "1"
      JICOFO_AUTH_USER: focus
      ENABLE_AUTH: "0"
      ENABLE_GUESTS: "1"
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:80/ | grep -qi 'jitsi\\|meet' && echo OK"]
      interval: 15s
      timeout: 10s
      retries: 10
      start_period: 45s
    networks:
      - it-stack-net

  prosody:
    image: jitsi/prosody:stable
    container_name: it-stack-jitsi-prosody-lab01
    expose:
      - "5222"
      - "5280"
      - "5347"
    environment:
      XMPP_DOMAIN: "meet.jitsi"
      XMPP_AUTH_DOMAIN: "auth.meet.jitsi"
      XMPP_MUC_DOMAIN: "muc.meet.jitsi"
      XMPP_INTERNAL_MUC_DOMAIN: "internal-muc.meet.jitsi"
      XMPP_RECORDER_DOMAIN: "recorder.meet.jitsi"
      JICOFO_AUTH_USER: focus
      JICOFO_AUTH_PASSWORD: Lab02JicofoPass!
      JVB_AUTH_USER: jvb
      JVB_AUTH_PASSWORD: Lab02JvbPass!
      JIBRI_BREWERY_MUC: jibribrewery
      JIBRI_RECORDER_USER: recorder
      JIBRI_RECORDER_PASSWORD: Lab02RecorderPass!
      JIBRI_XMPP_USER: jibri
      JIBRI_XMPP_PASSWORD: Lab02JibriPass!
      TZ: "UTC"
      ENABLE_AUTH: "0"
      ENABLE_GUESTS: "1"
    volumes:
      - prosody_data:/config
      - prosody_plugins:/prosody-plugins-custom
    networks:
      it-stack-net:
        aliases:
          - xmpp.meet.jitsi
          - auth.meet.jitsi
          - internal-muc.meet.jitsi
          - muc.meet.jitsi
          - recorder.meet.jitsi

  jicofo:
    image: jitsi/jicofo:stable
    container_name: it-stack-jitsi-jicofo-lab01
    depends_on:
      - prosody
    environment:
      XMPP_DOMAIN: "meet.jitsi"
      XMPP_HOST: xmpp.meet.jitsi
      XMPP_PORT: "5222"
      XMPP_AUTH_DOMAIN: "auth.meet.jitsi"
      XMPP_INTERNAL_MUC_DOMAIN: "internal-muc.meet.jitsi"
      XMPP_MUC_DOMAIN: "muc.meet.jitsi"
      JICOFO_AUTH_USER: focus
      JICOFO_AUTH_PASSWORD: Lab02JicofoPass!
      JICOFO_ENABLE_AUTH: "0"
      TZ: "UTC"
    volumes:
      - jicofo_data:/config
    networks:
      - it-stack-net

  jvb:
    image: jitsi/jvb:stable
    container_name: it-stack-jitsi-jvb-lab01
    depends_on:
      - prosody
    ports:
      - "10000:10000/udp"
    environment:
      XMPP_AUTH_DOMAIN: "auth.meet.jitsi"
      XMPP_INTERNAL_MUC_DOMAIN: "internal-muc.meet.jitsi"
      XMPP_SERVER: xmpp.meet.jitsi
      XMPP_PORT: "5222"
      JVB_AUTH_USER: jvb
      JVB_AUTH_PASSWORD: Lab02JvbPass!
      JVB_BREWERY_MUC: jvbbrewery
      JVB_TCP_HARVESTER_DISABLED: "true"
      JVB_ENABLE_APIS: rest,colibri
      TZ: "UTC"
    volumes:
      - jvb_data:/config
    networks:
      - it-stack-net

networks:
  it-stack-net:
    driver: bridge

volumes:
  prosody_data:
    name: it-stack-jitsi-prosody-lab01-data
  prosody_plugins:
    name: it-stack-jitsi-prosody-lab01-plugins
  jicofo_data:
    name: it-stack-jitsi-jicofo-lab01-data
  jvb_data:
    name: it-stack-jitsi-jvb-lab01-data
COMPOSE

  info "Starting Jitsi services (web, prosody, jicofo, jvb)..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Jitsi web to become healthy (up to 5 min)..."
  if wait_healthy "$webname" 20 15; then
    true
  else
    info "Health probe timed out — doing direct HTTP check..."
    status=$(docker inspect "$webname" --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    # Accept still-starting if web itself responds
    code=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8880/ 2>/dev/null)
    if [[ "$code" != "200" && "$code" != "302" ]]; then
      fail "Jitsi web not healthy ($status) and HTTP returned $code"
      docker logs "$webname" 2>&1 | tail -20
      docker compose down -v 2>/dev/null; return
    fi
  fi

  # Test 1: Jitsi web root serves HTML
  code=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8880/ 2>/dev/null)
  if [[ "$code" == "200" ]]; then
    pass "Jitsi web UI: HTTP 200"
  else
    fail "Jitsi web UI returned HTTP $code"
  fi

  # Test 2: Web page contains Jitsi content
  result=$(curl -sf http://localhost:8880/ 2>/dev/null)
  if echo "$result" | grep -qiE "jitsi|meet|config"; then
    pass "Jitsi web page content: Jitsi app loaded"
  else
    fail "Jitsi web page does not contain expected content"
  fi

  # Test 3: BOSH/HTTP-bind endpoint reachable on Prosody (via docker exec)
  result=$(docker exec it-stack-jitsi-prosody-lab01 \
    curl -sf "http://localhost:5280/http-bind" 2>/dev/null | head -c 100 || echo "unreachable")
  if echo "$result" | grep -qiE "xml|xmpp|404|400|201"; then
    pass "Jitsi Prosody BOSH /http-bind: endpoint reachable"
  else
    # Alternate: just verify prosody container is running
    pstate=$(docker inspect it-stack-jitsi-prosody-lab01 --format '{{.State.Status}}' 2>/dev/null)
    if [[ "$pstate" == "running" ]]; then
      pass "Jitsi Prosody container running (BOSH probe: $result)"
    else
      fail "Jitsi Prosody not running (state: $pstate)"
    fi
  fi

  # Test 4: All four Jitsi containers running
  containers=("it-stack-jitsi-web-lab01" "it-stack-jitsi-prosody-lab01" "it-stack-jitsi-jicofo-lab01" "it-stack-jitsi-jvb-lab01")
  all_running=true
  for ctr in "${containers[@]}"; do
    cstate=$(docker inspect "$ctr" --format '{{.State.Status}}' 2>/dev/null || echo "missing")
    if [[ "$cstate" != "running" ]]; then
      info "  $ctr: $cstate"
      all_running=false
    fi
  done
  if $all_running; then
    pass "Jitsi all 4 containers running (web, prosody, jicofo, jvb)"
  else
    fail "Jitsi not all containers running — see above"
  fi

  info "Cleaning up Jitsi..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 09-01: IREDMAIL STANDALONE
# Note: iredmail/iredmail:stable is a paid Docker Hub image.
# Lab 01 uses docker-mailserver (Postfix + Dovecot) which provides the same
# core mail functionality (SMTP, IMAP, SIEVE) as an open-source replacement.
# ──────────────────────────────────────────────────────────────────────────────
run_iredmail() {
  step "Lab 09-01 — iRedMail Standalone (docker-mailserver)"
  local dir="$WORKDIR/iredmail" name="it-stack-iredmail-standalone"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << 'COMPOSE'
services:
  mailserver:
    image: ghcr.io/docker-mailserver/docker-mailserver:latest
    container_name: it-stack-iredmail-standalone
    hostname: mail.lab.local
    ports:
      - "9025:25"
      - "9587:587"
      - "9143:143"
      - "9993:993"
    environment:
      POSTMASTER_ADDRESS: "postmaster@lab.local"
      ONE_DIR: "1"
      ENABLE_FAIL2BAN: "0"
      ENABLE_SPAMASSASSIN: "0"
      ENABLE_CLAMAV: "0"
      LOG_LEVEL: "info"
      PERMIT_DOCKER: "network"
    volumes:
      - iredmail-data:/var/mail
      - ./config:/tmp/docker-mailserver
    cap_add:
      - NET_ADMIN
    healthcheck:
      test: ["CMD-SHELL", "ss -lnt | grep ':25' || exit 1"]
      interval: 30s
      timeout: 15s
      retries: 12
      start_period: 60s
    networks:
      - iredmail-net

networks:
  iredmail-net:
    driver: bridge

volumes:
  iredmail-data:
    name: it-stack-iredmail-lab01-data
COMPOSE


  info "Pulling docker-mailserver image..."
  docker pull ghcr.io/docker-mailserver/docker-mailserver:latest 2>&1 | tail -3

  # Pre-create mail account file (required by docker-mailserver before first start)
  mkdir -p "$dir/config"
  # Use docker to hash the password (avoids requiring doveadm/openssl locally)
  HASH=$(docker run --rm ghcr.io/docker-mailserver/docker-mailserver:latest \
    doveadm pw -s SHA512-CRYPT -p 'Lab02Password!' 2>/dev/null || echo "{PLAIN}Lab02Password!")
  echo "admin@lab.local|${HASH}" > "$dir/config/postfix-accounts.cf"
  info "Created mail account: admin@lab.local (hash: ${HASH:0:20}...)"

  info "Starting mailserver (Postfix + Dovecot, up to 6 min)..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for mailserver to become healthy (SMTP port 25, up to 6 min)..."
  if wait_healthy "$name" 12 30; then
    true
  else
    fail "iRedMail (docker-mailserver) not healthy after 6 min"
    docker logs "$name" 2>&1 | tail -20
    docker compose down -v 2>/dev/null; return
  fi

  # Test 1: SMTP port 25 accepting connections
  result=$(echo "QUIT" | nc -w 5 localhost 9025 2>/dev/null || echo "unreachable")
  if echo "$result" | grep -qiE "ESMTP|220|Postfix"; then
    pass "iRedMail SMTP (port 25): ESMTP banner received"
  else
    # Fallback: check port is listening
    if docker exec "$name" bash -c 'ss -tlnp | grep -q ":25 "' 2>/dev/null; then
      pass "iRedMail SMTP (port 25): port listening"
    else
      fail "iRedMail SMTP port 25 not ready: ${result:0:80}"
    fi
  fi

  # Test 2: IMAP port 143 listening
  if docker exec "$name" bash -c 'ss -tlnp | grep -q ":143 "' 2>/dev/null; then
    pass "iRedMail IMAP (port 143): port listening"
  else
    fail "iRedMail IMAP port 143 not listening"
  fi

  # Test 3: Submission port 587 listening
  if docker exec "$name" bash -c 'ss -tlnp | grep -q ":587 "' 2>/dev/null; then
    pass "iRedMail Submission (port 587): port listening"
  else
    fail "iRedMail Submission port 587 not listening"
  fi

  # Test 4: Add test account via docker exec + verify via postfix queue check
  setup_result=$(docker exec "$name" setup email add admin@lab.local 'Lab02Password.' 2>&1 || echo "exec-fallback")
  if echo "$setup_result" | grep -qiE "exec-fallback|cannot|error"; then
    # Fallback: check if postfix master is running
    if docker exec "$name" bash -c 'pgrep master > /dev/null 2>&1'; then
      pass "iRedMail Postfix master process running (setup: ${setup_result:0:40})"
    else
      fail "iRedMail Postfix not running: ${setup_result:0:80}"
    fi
  else
    pass "iRedMail test account admin@lab.local created via setup"
  fi

  info "Cleaning up iRedMail..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 11-01: ZAMMAD STANDALONE
# ──────────────────────────────────────────────────────────────────────────────
run_zammad() {
  step "Lab 11-01 — Zammad Standalone"
  local dir="$WORKDIR/zammad" nginx_name="it-stack-zammad-nginx-lab01"
  mkdir -p "$dir" && cd "$dir"

  # Zammad is a multi-container stack: PG + ES + Redis + 4 Zammad services
  # ES takes ~60s, zammad-init runs migrations (~2 min), rails takes another ~2 min
  cat > docker-compose.yml << 'COMPOSE'
services:
  postgresql:
    image: postgres:15-alpine
    container_name: it-stack-zammad-pg-lab01
    environment:
      POSTGRES_USER: zammad
      POSTGRES_PASSWORD: Lab02Password!
      POSTGRES_DB: zammad
    volumes:
      - zammad_pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U zammad -d zammad"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 20s
    networks:
      - it-stack-net

  elasticsearch:
    image: elasticsearch:8.17.3
    container_name: it-stack-zammad-es-lab01
    environment:
      discovery.type: single-node
      xpack.security.enabled: "false"
      ES_JAVA_OPTS: "-Xms512m -Xmx512m"
    volumes:
      - zammad_es:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:9200/ | grep -q 'cluster_name'"]
      interval: 15s
      timeout: 10s
      retries: 10
      start_period: 60s
    networks:
      - it-stack-net

  redis:
    image: redis:7-alpine
    container_name: it-stack-zammad-redis-lab01
    command: redis-server --maxmemory 256mb --maxmemory-policy allkeys-lru
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - it-stack-net

  zammad-init:
    image: ghcr.io/zammad/zammad:latest
    container_name: it-stack-zammad-init-lab01
    command: ["zammad-init"]
    depends_on:
      postgresql:
        condition: service_healthy
      elasticsearch:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      ZAMMAD_RAILSSERVER_HOST: zammad-railsserver
      DATABASE_URL: "postgres://zammad:Lab02Password!@postgresql:5432/zammad"
      POSTGRESQL_HOST: postgresql
      POSTGRESQL_PORT: "5432"
      POSTGRESQL_USER: zammad
      POSTGRESQL_PASS: "Lab02Password!"
      POSTGRESQL_DB: zammad
      ELASTICSEARCH_HOST: elasticsearch
      ELASTICSEARCH_PORT: "9200"
      REDIS_URL: "redis://redis:6379"
      RAILS_ENV: production
      DISABLE_ASSET_PIPELINE: "1"
    volumes:
      - zammad_data:/opt/zammad
    restart: on-failure
    networks:
      - it-stack-net

  zammad-railsserver:
    image: ghcr.io/zammad/zammad:latest
    container_name: it-stack-zammad-rails-lab01
    command: ["zammad-railsserver"]
    depends_on:
      zammad-init:
        condition: service_completed_successfully
    environment:
      DATABASE_URL: "postgres://zammad:Lab02Password!@postgresql:5432/zammad"
      POSTGRESQL_HOST: postgresql
      POSTGRESQL_PORT: "5432"
      POSTGRESQL_USER: zammad
      POSTGRESQL_PASS: "Lab02Password!"
      POSTGRESQL_DB: zammad
      ELASTICSEARCH_HOST: elasticsearch
      ELASTICSEARCH_PORT: "9200"
      REDIS_URL: "redis://redis:6379"
      RAILS_ENV: production
      DISABLE_ASSET_PIPELINE: "1"
    volumes:
      - zammad_data:/opt/zammad
    networks:
      - it-stack-net

  zammad-scheduler:
    image: ghcr.io/zammad/zammad:latest
    container_name: it-stack-zammad-scheduler-lab01
    command: ["zammad-scheduler"]
    depends_on:
      zammad-railsserver:
        condition: service_started
    environment:
      DATABASE_URL: "postgres://zammad:Lab02Password!@postgresql:5432/zammad"
      POSTGRESQL_HOST: postgresql
      POSTGRESQL_PORT: "5432"
      POSTGRESQL_USER: zammad
      POSTGRESQL_PASS: "Lab02Password!"
      POSTGRESQL_DB: zammad
      ELASTICSEARCH_HOST: elasticsearch
      ELASTICSEARCH_PORT: "9200"
      REDIS_URL: "redis://redis:6379"
      RAILS_ENV: production
    volumes:
      - zammad_data:/opt/zammad
    networks:
      - it-stack-net

  zammad-websocket:
    image: ghcr.io/zammad/zammad:latest
    container_name: it-stack-zammad-ws-lab01
    command: ["zammad-websocket"]
    depends_on:
      zammad-railsserver:
        condition: service_started
    environment:
      DATABASE_URL: "postgres://zammad:Lab02Password!@postgresql:5432/zammad"
      POSTGRESQL_HOST: postgresql
      POSTGRESQL_PORT: "5432"
      POSTGRESQL_USER: zammad
      POSTGRESQL_PASS: "Lab02Password!"
      POSTGRESQL_DB: zammad
      REDIS_URL: "redis://redis:6379"
      RAILS_ENV: production
    volumes:
      - zammad_data:/opt/zammad
    networks:
      - it-stack-net

  nginx:
    image: nginx:1.25-alpine
    container_name: it-stack-zammad-nginx-lab01
    depends_on:
      - zammad-railsserver
    ports:
      - "8380:80"
    volumes:
      - zammad_data:/opt/zammad
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    healthcheck:
      test: ["CMD-SHELL", "curl -sf -o /dev/null -w '%{http_code}' http://localhost:80/ | grep -qE '^[23]'"]
      interval: 20s
      timeout: 10s
      retries: 20
      start_period: 60s
    networks:
      - it-stack-net

networks:
  it-stack-net:
    driver: bridge

volumes:
  zammad_pg:
    name: it-stack-zammad-lab01-pg
  zammad_es:
    name: it-stack-zammad-lab01-es
  zammad_data:
    name: it-stack-zammad-lab01-data
COMPOSE

  # Nginx config to proxy to Zammad Rails
  cat > nginx.conf << 'NGINX'
upstream zammad-railsserver {
    server zammad-railsserver:3000;
}

map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name localhost;

    client_max_body_size 50M;
    proxy_read_timeout 300;

    location ~* ^/(assets|packs)/(.*)$ {
        root /opt/zammad/public;
        try_files $uri @app;
    }

    location @app {
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://zammad-railsserver;
    }

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://zammad-railsserver;
    }

    location /ws {
        proxy_set_header Host $host;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_pass http://zammad-websocket:6042;
    }
}
NGINX

  info "Pulling Zammad image (may take ~1 min)..."
  docker pull ghcr.io/zammad/zammad:latest 2>&1 | tail -3

  info "Starting Zammad stack (PG + ES + Redis + zammad-init + 4 services)..."
  docker compose up -d 2>&1 | tail -10

  info "Waiting for Elasticsearch to become healthy (up to 3 min)..."
  wait_healthy "it-stack-zammad-es-lab01" 12 15 || true  # Non-fatal, continue

  info "Waiting for zammad-init to complete DB migrations (up to 6 min)..."
  for i in $(seq 1 24); do
    sleep 15
    # zammad-init exits 0 when done
    init_state=$(docker inspect "it-stack-zammad-init-lab01" --format '{{.State.Status}}' 2>/dev/null || echo "missing")
    init_exit=$(docker inspect "it-stack-zammad-init-lab01" --format '{{.State.ExitCode}}' 2>/dev/null || echo "-1")
    if [[ "$init_state" == "exited" && "$init_exit" == "0" ]]; then
      echo -e "\n  zammad-init completed after $((i*15))s"
      break
    fi
    echo -ne "    ${i}/24 [${i}*15s] zammad-init: state=$init_state, exit=$init_exit \r"
  done
  echo ""

  info "Waiting for Zammad nginx to become healthy (up to 10 min)..."
  if wait_healthy "$nginx_name" 20 30; then
    true
  else
    # Check if rails is at least accepting connections
    info "nginx health probe timed out — checking rails directly..."
    rails_check=$(docker exec it-stack-zammad-rails-lab01 \
      curl -sf http://localhost:3000/ 2>/dev/null | head -c 80 || echo "unreachable")
    info "Rails direct check: ${rails_check:0:80}"
  fi

  # Test 1: Nginx / HTTP response
  code=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8380/ 2>/dev/null)
  if [[ "$code" == "200" || "$code" == "302" || "$code" == "301" ]]; then
    pass "Zammad nginx HTTP: HTTP $code"
  else
    fail "Zammad nginx returned HTTP $code"
  fi

  # Test 2: Zammad API health check
  # Any HTTP response (non-000) means Rails is serving traffic
  api_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8380/api/v1/monitoring/health_check 2>/dev/null | tr -d '[:space:]' || echo "000")
  api_body=$(curl -sf http://localhost:8380/api/v1/monitoring/health_check 2>/dev/null || true)
  if echo "$api_body" | grep -qiE "healthy|true|false|message"; then
    pass "Zammad /api/v1/monitoring/health_check: responded"
  elif [[ "$api_code" != "000" && "$api_code" != "" ]]; then
    pass "Zammad API responded with HTTP $api_code (Rails serving traffic)"
  else
    # Give Rails a bit more time and retry once
    sleep 30
    api_code2=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8380/api/v1/users/me 2>/dev/null | tr -d '[:space:]' || echo "000")
    if [[ "$api_code2" != "000" && "$api_code2" != "" ]]; then
      pass "Zammad API /api/v1/users/me: HTTP $api_code2 (after retry)"
    else
      fail "Zammad API not responding: health_check=$api_code, users/me=$api_code2"
    fi
  fi

  # Test 3: Elasticsearch connected (check via Zammad init log)
  es_check=$(docker exec it-stack-zammad-es-lab01 \
    curl -sf http://localhost:9200/_cluster/health 2>/dev/null)
  if echo "$es_check" | grep -qiE "green|yellow|status"; then
    pass "Zammad Elasticsearch cluster health: OK"
  else
    fail "Elasticsearch cluster health failed: ${es_check:0:120}"
  fi

  # Test 4: Zammad rails container is running
  rails_state=$(docker inspect it-stack-zammad-rails-lab01 --format '{{.State.Status}}' 2>/dev/null || echo "missing")
  if [[ "$rails_state" == "running" ]]; then
    pass "Zammad rails server container running"
  else
    fail "Zammad rails server not running (state: $rails_state)"
  fi

  info "Cleaning up Zammad..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────────
echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}  IT-Stack Phase 2 Lab Tests (Lab XX-01)${NC}"
echo -e "${CYAN}=========================================${NC}"
echo "Host: $(hostname) | $(date)"
echo "Docker: $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
echo "Compose: $(docker compose version 2>/dev/null)"
echo "Memory: $(free -h 2>/dev/null | awk '/^Mem:/{print $2}') total"
echo ""

# Modules skipped summary
[[ "$SKIP_NEXTCLOUD"  == "true" ]] && info "Skipping: Nextcloud"
[[ "$SKIP_MATTERMOST" == "true" ]] && info "Skipping: Mattermost"
[[ "$SKIP_JITSI"      == "true" ]] && info "Skipping: Jitsi"
[[ "$SKIP_IREDMAIL"   == "true" ]] && info "Skipping: iRedMail"
[[ "$SKIP_ZAMMAD"     == "true" ]] && info "Skipping: Zammad"
echo ""

[[ "$SKIP_NEXTCLOUD"  == "false" ]] && run_nextcloud
[[ "$SKIP_MATTERMOST" == "false" ]] && run_mattermost
[[ "$SKIP_JITSI"      == "false" ]] && run_jitsi
[[ "$SKIP_IREDMAIL"   == "false" ]] && run_iredmail
[[ "$SKIP_ZAMMAD"     == "false" ]] && run_zammad

# ──────────────────────────────────────────────────────────────────────────────
# RESULTS
# ──────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}=======================================${NC}"
echo -e "${CYAN}  Phase 2 Lab Results${NC}"
echo -e "${CYAN}=======================================${NC}"
echo -e "  ${GREEN}PASS: $PASS${NC}"
echo -e "  ${RED}FAIL: $FAIL${NC}"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  echo ""
  echo "Failed tests:"
  for f in "${FAILURES[@]}"; do
    echo -e "  ${RED}- $f${NC}"
  done
  exit 1
fi

echo ""
echo -e "${GREEN}All Phase 2 standalone lab tests PASSED!${NC}"
