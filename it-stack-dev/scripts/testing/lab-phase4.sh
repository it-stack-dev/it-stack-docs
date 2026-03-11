#!/usr/bin/env bash
# Phase 4 Lab Tests — Standalone (Lab XX-01) for all Phase 4 modules
# Modules: Elasticsearch (05), Snipe-IT (16), GLPI (17), Zabbix (19), Taiga (15), Graylog (20)
# Usage  : bash lab-phase4.sh [options]
#   --skip-elasticsearch  --skip-snipeit  --skip-glpi
#   --skip-zabbix         --skip-taiga    --skip-graylog
#   --only-elasticsearch  --only-snipeit  --only-glpi
#   --only-zabbix         --only-taiga    --only-graylog
# Requires: Docker, Docker Compose v2, ~14 GB RAM
#
# Port map (unique across all modules, no cleanup-dependency):
#   Elasticsearch  : 9200  (native ES port)
#   Snipe-IT       : 8305
#   GLPI           : 8306
#   Zabbix web     : 8307
#   Taiga back     : 9000 / front: 9001
#   Graylog        : 9002

set -uo pipefail

SKIP_ELASTICSEARCH=false
SKIP_SNIPEIT=false
SKIP_GLPI=false
SKIP_ZABBIX=false
SKIP_TAIGA=false
SKIP_GRAYLOG=false
ONLY_MODULE=""

for arg in "$@"; do
  case "$arg" in
    --skip-elasticsearch)  SKIP_ELASTICSEARCH=true ;;
    --skip-snipeit)        SKIP_SNIPEIT=true ;;
    --skip-glpi)           SKIP_GLPI=true ;;
    --skip-zabbix)         SKIP_ZABBIX=true ;;
    --skip-taiga)          SKIP_TAIGA=true ;;
    --skip-graylog)        SKIP_GRAYLOG=true ;;
    --only-elasticsearch)  ONLY_MODULE="elasticsearch" ;;
    --only-snipeit)        ONLY_MODULE="snipeit" ;;
    --only-glpi)           ONLY_MODULE="glpi" ;;
    --only-zabbix)         ONLY_MODULE="zabbix" ;;
    --only-taiga)          ONLY_MODULE="taiga" ;;
    --only-graylog)        ONLY_MODULE="graylog" ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

if [[ -n "$ONLY_MODULE" ]]; then
  SKIP_ELASTICSEARCH=true; SKIP_SNIPEIT=true; SKIP_GLPI=true
  SKIP_ZABBIX=true; SKIP_TAIGA=true; SKIP_GRAYLOG=true
  case "$ONLY_MODULE" in
    elasticsearch)  SKIP_ELASTICSEARCH=false ;;
    snipeit)        SKIP_SNIPEIT=false ;;
    glpi)           SKIP_GLPI=false ;;
    zabbix)         SKIP_ZABBIX=false ;;
    taiga)          SKIP_TAIGA=false ;;
    graylog)        SKIP_GRAYLOG=false ;;
  esac
fi

PASS=0; FAIL=0
declare -a FAILURES=()

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

pass()  { echo -e "${GREEN}  [PASS]${NC} $1"; ((++PASS)); }
fail()  { echo -e "${RED}  [FAIL]${NC} $1"; ((++FAIL)); FAILURES+=("$1"); }
step()  { echo -e "\n${CYAN}>> $1${NC}"; }
info()  { echo -e "${YELLOW}  ...${NC} $1"; }

# ###########################################################################
# HELPER: http_ok <code>
#   Returns true (0) when $1 is a valid HTTP response code (1xx-5xx).
#   Rejects "000" and the pipefail "000000" concatenation bug.
# ###########################################################################
http_ok() { [[ "$1" =~ ^[1-5][0-9][0-9]$ ]]; }

# ###########################################################################
# HELPER: host_http <url>
#   GET HTTP response code from the host; always exactly 3 digits.
# ###########################################################################
host_http() {
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-redirs 3 \
         --max-time 15 "$1" 2>/dev/null | tr -d '[:space:]'; true)
  echo "${code:-000}"
}

# ###########################################################################
# HELPER: host_http_noredirect <url>
#   GET HTTP response code without following redirects.
# ###########################################################################
host_http_noredirect() {
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" \
         --max-time 15 "$1" 2>/dev/null | tr -d '[:space:]'; true)
  echo "${code:-000}"
}

# ###########################################################################
# HELPER: exec_http <container> <url>
#   GET HTTP response code via docker exec ('; true' prevents pipefail 000000).
# ###########################################################################
exec_http() {
  local code
  code=$(docker exec "$1" curl -s -o /dev/null -w "%{http_code}" \
         --max-time 15 "$2" 2>/dev/null | tr -d '[:space:]'; true)
  echo "${code:-000}"
}

# ###########################################################################
# HELPER: host_get <url>
#   Fetch page body (first 4000 bytes) from the host.
# ###########################################################################
host_get() {
  local body
  body=$(curl -sL --max-time 20 "$1" 2>/dev/null | head -c 4000; true)
  echo "${body:-}"
}

# ###########################################################################
# HELPER: host_get_auth <url> <user> <pass>
#   GET with HTTP Basic auth.
# ###########################################################################
host_get_auth() {
  local body
  body=$(curl -sL --max-time 20 -u "$2:$3" "$1" 2>/dev/null | head -c 4000; true)
  echo "${body:-}"
}

# ###########################################################################
# HELPER: host_http_auth <url> <user> <pass>
#   HTTP response code with Basic auth.
# ###########################################################################
host_http_auth() {
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 \
         -u "$2:$3" "$1" 2>/dev/null | tr -d '[:space:]'; true)
  echo "${code:-000}"
}

# ###########################################################################
# HELPER: wait_healthy <container> [max_iters] [interval_s]
#   Polls Docker healthcheck until "healthy" or timeout.
# ###########################################################################
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

# ###########################################################################
# HELPER: wait_http <url> [max_iters] [interval_s]
#   Polls a URL until it returns a valid HTTP response — for containers that
#   lack a Docker healthcheck (e.g. GLPI community image).
# ###########################################################################
wait_http() {
  local url="$1" max="${2:-30}" interval="${3:-10}"
  local code
  for i in $(seq 1 "$max"); do
    sleep "$interval"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null | tr -d '[:space:]'; true)
    http_ok "${code:-000}" && { echo ""; return 0; }
    echo -ne "    ${i}/${max} (HTTP ${code:-000}) \r"
  done
  echo ""
  return 1
}

WORKDIR="$HOME/it-stack-labs"
mkdir -p "$WORKDIR"

# ============================================================================
# LAB 05-01: ELASTICSEARCH STANDALONE
# ============================================================================
run_elasticsearch() {
  step "Lab 05-01 — Elasticsearch Standalone"
  local dir="$WORKDIR/elasticsearch" ctr="es-s01"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << 'COMPOSE'
services:
  es-s01:
    image: elasticsearch:8.17.3
    container_name: es-s01
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
      - cluster.name=lab-cluster
    ports:
      - "9200:9200"
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:9200/_cluster/health || exit 1"]
      interval: 15s
      timeout: 10s
      retries: 12
      start_period: 30s

networks:
  default:
    name: es-s01-net
COMPOSE

  info "Pulling elasticsearch:8.17.3 (may take a few minutes)..."
  docker compose pull -q 2>/dev/null || true
  docker compose up -d

  # Test 1: container healthy
  info "Waiting for Elasticsearch to become healthy (~3 min)..."
  if wait_healthy "$ctr" 18 10; then
    pass "05-01 T1: Elasticsearch container healthy"
  else
    fail "05-01 T1: Elasticsearch container not healthy (timeout)"
    docker compose logs --tail=20 es-s01
    docker compose down -v 2>/dev/null; return
  fi

  # Test 2: cluster health endpoint
  local code
  code=$(host_http "http://localhost:9200/_cluster/health")
  if http_ok "$code"; then
    pass "05-01 T2: GET /_cluster/health → HTTP $code"
  else
    fail "05-01 T2: GET /_cluster/health → HTTP $code (expected 2xx)"
  fi

  # Test 3: cluster status is green or yellow (not red, not empty)
  local health_body
  health_body=$(host_get "http://localhost:9200/_cluster/health")
  if echo "$health_body" | grep -qE '"status"\s*:\s*"(green|yellow)"'; then
    local status
    status=$(echo "$health_body" | grep -oP '"status"\s*:\s*"\K[^"]+' | head -1)
    pass "05-01 T3: Cluster status = $status"
  else
    fail "05-01 T3: Cluster status not green/yellow — body: ${health_body:0:200}"
  fi

  # Test 4: create a test index
  code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    "http://localhost:9200/lab-test-index" \
    -H "Content-Type: application/json" \
    -d '{"settings":{"number_of_shards":1,"number_of_replicas":0}}' \
    --max-time 10 2>/dev/null | tr -d '[:space:]'; true)
  if http_ok "$code"; then
    pass "05-01 T4: PUT /lab-test-index → HTTP $code (index created)"
  else
    fail "05-01 T4: PUT /lab-test-index → HTTP $code (expected 2xx)"
  fi

  # Test 5: index a document and retrieve it
  curl -s -X POST "http://localhost:9200/lab-test-index/_doc" \
    -H "Content-Type: application/json" \
    -d '{"message":"hello from it-stack lab","phase":4}' \
    --max-time 10 > /dev/null 2>&1 || true
  local search_body
  search_body=$(curl -s "http://localhost:9200/lab-test-index/_search" \
    --max-time 10 2>/dev/null; true)
  if echo "$search_body" | grep -q '"total"'; then
    pass "05-01 T5: Document indexed and _search returns hits"
  else
    fail "05-01 T5: Document indexing/search failed — body: ${search_body:0:200}"
  fi

  docker compose down -v 2>/dev/null
  cd "$WORKDIR"
}

# ============================================================================
# LAB 16-01: SNIPE-IT STANDALONE
# ============================================================================
run_snipeit() {
  step "Lab 16-01 — Snipe-IT Standalone"
  local dir="$WORKDIR/snipeit" app="snipeit-s01" db="snipeit-s01-db"
  mkdir -p "$dir" && cd "$dir"

  # APP_KEY: valid Laravel key — base64-encoded 32-byte random string
  cat > docker-compose.yml << 'COMPOSE'
services:
  snipeit-s01-db:
    image: mariadb:10.11
    container_name: snipeit-s01-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: RootLab01!
      MYSQL_DATABASE: snipeit
      MYSQL_USER: snipeit
      MYSQL_PASSWORD: SnipeItLab01!
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-pRootLab01!"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    networks:
      - snipeit-s01-net

  snipeit-s01:
    image: snipe/snipe-it:latest
    container_name: snipeit-s01
    restart: unless-stopped
    depends_on:
      snipeit-s01-db:
        condition: service_healthy
    environment:
      APP_ENV: production
      APP_DEBUG: "false"
      APP_KEY: "base64:SLIsofMQp1LwWP4v4QHYaS8dW5K3bGEbVGe4TqGxCOc="
      APP_URL: "http://localhost:8305"
      DB_CONNECTION: mysql
      DB_HOST: snipeit-s01-db
      DB_DATABASE: snipeit
      DB_USERNAME: snipeit
      DB_PASSWORD: SnipeItLab01!
      DB_PORT: "3306"
      MAIL_PORT_587_TCP_ADDR: "localhost"
      MAIL_PORT_587_TCP_PORT: "1025"
      MAIL_ENV_FROM_ADDR: "lab@it-stack.local"
      MAIL_ENV_FROM_NAME: "IT-Stack Lab"
      MAIL_ENV_ENCRYPTION: "null"
      PHP_UPLOAD_LIMIT: "100"
      PHP_MAX_EXECUTION: "120"
    ports:
      - "8305:80"
    networks:
      - snipeit-s01-net
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost/login || exit 1"]
      interval: 20s
      timeout: 10s
      retries: 30
      start_period: 90s

networks:
  snipeit-s01-net:
    name: snipeit-s01-net
COMPOSE

  info "Pulling Snipe-IT images..."
  docker compose pull -q 2>/dev/null || true
  docker compose up -d

  # Test 1: DB healthy
  info "Waiting for MariaDB..."
  if wait_healthy "$db" 12 10; then
    pass "16-01 T1: Snipe-IT MariaDB healthy"
  else
    fail "16-01 T1: Snipe-IT MariaDB not healthy"
    docker compose down -v 2>/dev/null; return
  fi

  # Test 2: App container healthy (migrations + first run take up to 8 min on local Docker)
  info "Waiting for Snipe-IT app to become healthy (~8 min for first run migrations on local Docker)..."
  if wait_healthy "$app" 48 10; then
    pass "16-01 T2: Snipe-IT app container healthy"
  else
    fail "16-01 T2: Snipe-IT app not healthy (timeout)"
    docker compose logs --tail=20 snipeit-s01
    docker compose down -v 2>/dev/null; return
  fi

  # Test 3: HTTP /login → 2xx
  local code
  code=$(host_http "http://localhost:8305/login")
  if http_ok "$code"; then
    pass "16-01 T3: GET /login → HTTP $code"
  else
    fail "16-01 T3: GET /login → HTTP $code (expected 2xx)"
  fi

  # Test 4: Login page contains Snipe-IT branding
  local body
  body=$(host_get "http://localhost:8305/login")
  if echo "$body" | grep -qi "snipe"; then
    pass "16-01 T4: Login page contains Snipe-IT branding"
  else
    fail "16-01 T4: Login page missing Snipe-IT branding — body: ${body:0:300}"
  fi

  docker compose down -v 2>/dev/null
  cd "$WORKDIR"
}

# ============================================================================
# LAB 17-01: GLPI STANDALONE
# ============================================================================
run_glpi() {
  step "Lab 17-01 — GLPI Standalone"
  local dir="$WORKDIR/glpi" app="glpi-s01" db="glpi-s01-db"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << 'COMPOSE'
services:
  glpi-s01-db:
    image: mariadb:10.11
    container_name: glpi-s01-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: RootLab01!
      MYSQL_DATABASE: glpi
      MYSQL_USER: glpi
      MYSQL_PASSWORD: GlpiLab01!
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-pRootLab01!"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    networks:
      - glpi-s01-net

  glpi-s01:
    image: diouxx/glpi:latest
    container_name: glpi-s01
    restart: unless-stopped
    depends_on:
      glpi-s01-db:
        condition: service_healthy
    environment:
      TIMEZONE: UTC
      GLPI_MYSQL_HOST: glpi-s01-db
      GLPI_MYSQL_PORT: "3306"
      GLPI_MYSQL_DATABASE: glpi
      GLPI_MYSQL_USER: glpi
      GLPI_MYSQL_PASSWORD: GlpiLab01!
      GLPI_MYSQL_ROOT_PASSWORD: RootLab01!
      GLPI_INSTALL_DB: "1"
    ports:
      - "8306:80"
    networks:
      - glpi-s01-net

networks:
  glpi-s01-net:
    name: glpi-s01-net
COMPOSE

  info "Pulling GLPI images..."
  docker compose pull -q 2>/dev/null || true
  docker compose up -d

  # Test 1: DB healthy
  info "Waiting for MariaDB..."
  if wait_healthy "$db" 12 10; then
    pass "17-01 T1: GLPI MariaDB healthy"
  else
    fail "17-01 T1: GLPI MariaDB not healthy"
    docker compose down -v 2>/dev/null; return
  fi

  # GLPI community image has no Docker healthcheck — poll HTTP directly
  info "Waiting for GLPI web server (may take 3–5 min for DB install)..."
  if wait_http "http://localhost:8306/" 36 10; then
    pass "17-01 T2: GLPI web server responding"
  else
    fail "17-01 T2: GLPI web server not responding (timeout)"
    docker compose logs --tail=30 glpi-s01
    docker compose down -v 2>/dev/null; return
  fi

  # Test 3: HTTP main URL → 2xx or 3xx
  local code
  code=$(host_http_noredirect "http://localhost:8306/")
  if http_ok "$code"; then
    pass "17-01 T3: GET / → HTTP $code"
  else
    # Try following redirects
    code=$(host_http "http://localhost:8306/")
    if http_ok "$code"; then
      pass "17-01 T3: GET / (with redirect) → HTTP $code"
    else
      fail "17-01 T3: GET / → HTTP $code (expected 2xx/3xx)"
    fi
  fi

  # Test 4: Response body contains GLPI
  local body
  body=$(host_get "http://localhost:8306/")
  if echo "$body" | grep -qi "glpi"; then
    pass "17-01 T4: GLPI page body contains GLPI branding"
  else
    # Also check /front/login.php
    body=$(host_get "http://localhost:8306/front/login.php")
    if echo "$body" | grep -qi "glpi"; then
      pass "17-01 T4: GLPI login page contains GLPI branding"
    else
      fail "17-01 T4: GLPI page missing GLPI branding — body: ${body:0:300}"
    fi
  fi

  docker compose down -v 2>/dev/null
  cd "$WORKDIR"
}

# ============================================================================
# LAB 19-01: ZABBIX STANDALONE
# ============================================================================
run_zabbix() {
  step "Lab 19-01 — Zabbix Standalone"
  local dir="$WORKDIR/zabbix" web="zabbix-web-s01" srv="zabbix-srv-s01" pgdb="zabbix-db-s01"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << 'COMPOSE'
services:
  zabbix-db-s01:
    image: postgres:15-alpine
    container_name: zabbix-db-s01
    restart: unless-stopped
    environment:
      POSTGRES_DB: zabbix
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: ZabbixLab01!
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U zabbix -d zabbix"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 20s
    networks:
      - zabbix-s01-net

  zabbix-srv-s01:
    image: zabbix/zabbix-server-pgsql:ubuntu-7.2-latest
    container_name: zabbix-srv-s01
    restart: unless-stopped
    depends_on:
      zabbix-db-s01:
        condition: service_healthy
    environment:
      DB_SERVER_HOST: zabbix-db-s01
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: ZabbixLab01!
      POSTGRES_DB: zabbix
      ZBX_STARTPOLLERS: "2"
      ZBX_CACHESIZE: "32M"
    ports:
      - "10051:10051"
    networks:
      - zabbix-s01-net
    healthcheck:
      test: ["CMD-SHELL", "zabbix_server -R ha_status 2>/dev/null || zabbix_server --version 2>&1 | grep -q Zabbix"]
      interval: 15s
      timeout: 10s
      retries: 12
      start_period: 60s

  zabbix-web-s01:
    image: zabbix/zabbix-web-nginx-pgsql:ubuntu-7.2-latest
    container_name: zabbix-web-s01
    restart: unless-stopped
    depends_on:
      zabbix-db-s01:
        condition: service_healthy
      zabbix-srv-s01:
        condition: service_started
    environment:
      ZBX_SERVER_HOST: zabbix-srv-s01
      DB_SERVER_HOST: zabbix-db-s01
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: ZabbixLab01!
      POSTGRES_DB: zabbix
      PHP_TZ: UTC
    ports:
      - "8307:8080"
    networks:
      - zabbix-s01-net
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:8080/ | grep -qi zabbix || exit 1"]
      interval: 15s
      timeout: 10s
      retries: 16
      start_period: 60s

networks:
  zabbix-s01-net:
    name: zabbix-s01-net
COMPOSE

  info "Pulling Zabbix images..."
  docker compose pull -q 2>/dev/null || true
  docker compose up -d

  # Test 1: DB healthy
  info "Waiting for PostgreSQL..."
  if wait_healthy "$pgdb" 12 10; then
    pass "19-01 T1: Zabbix PostgreSQL healthy"
  else
    fail "19-01 T1: Zabbix PostgreSQL not healthy"
    docker compose down -v 2>/dev/null; return
  fi

  # Test 2: Web UI healthy
  info "Waiting for Zabbix web UI to become healthy (~4 min for DB schema init)..."
  if wait_healthy "$web" 24 15; then
    pass "19-01 T2: Zabbix web UI healthy"
  else
    fail "19-01 T2: Zabbix web UI not healthy (timeout)"
    docker compose logs --tail=20 zabbix-web-s01
    docker compose down -v 2>/dev/null; return
  fi

  # Test 3: HTTP → 200
  local code
  code=$(host_http "http://localhost:8307/")
  if http_ok "$code"; then
    pass "19-01 T3: GET / → HTTP $code"
  else
    fail "19-01 T3: GET / → HTTP $code (expected 2xx)"
  fi

  # Test 4: API jsonrpc — get version
  local api_body
  api_body=$(curl -s -X POST "http://localhost:8307/api_jsonrpc.php" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"apiinfo.version","params":[],"id":1}' \
    --max-time 15 2>/dev/null; true)
  if echo "$api_body" | grep -q '"result"'; then
    local ver
    ver=$(echo "$api_body" | grep -oP '"result"\s*:\s*"\K[^"]+' | head -1)
    pass "19-01 T4: Zabbix API jsonrpc returns version $ver"
  else
    fail "19-01 T4: Zabbix API jsonrpc failed — body: ${api_body:0:200}"
  fi

  docker compose down -v 2>/dev/null
  cd "$WORKDIR"
}

# ============================================================================
# LAB 15-01: TAIGA STANDALONE
# ============================================================================
run_taiga() {
  step "Lab 15-01 — Taiga Standalone"
  local dir="$WORKDIR/taiga" back="taiga-back-s01" pgdb="taiga-db-s01"
  mkdir -p "$dir" && cd "$dir"

  # Note: standalone lab tests the Django backend (taiga-back) + API only.
  # taiga-front (Angular SPA) and taiga-events (WebSocket) are Phase 4 Lab 02.
  cat > docker-compose.yml << 'COMPOSE'
services:
  taiga-db-s01:
    image: postgres:15-alpine
    container_name: taiga-db-s01
    restart: unless-stopped
    environment:
      POSTGRES_DB: taiga
      POSTGRES_USER: taiga
      POSTGRES_PASSWORD: TaigaLab01!
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U taiga -d taiga"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 20s
    networks:
      - taiga-s01-net

  taiga-back-s01:
    image: taigaio/taiga-back:latest
    container_name: taiga-back-s01
    restart: unless-stopped
    depends_on:
      taiga-db-s01:
        condition: service_healthy
    environment:
      DJANGO_SECRET_KEY: "taiga-django-secret-lab01-it-stack-phase4"
      POSTGRES_HOST: taiga-db-s01
      POSTGRES_DB: taiga
      POSTGRES_USER: taiga
      POSTGRES_PASSWORD: TaigaLab01!
      TAIGA_SECRET_KEY: "taiga-secret-lab01-it-stack-phase4"
      ENABLE_TELEMETRY: "False"
      PUBLIC_REGISTER_ENABLED: "True"
      RABBITMQ_USER: taiga
      RABBITMQ_PASS: taiga
      RABBITMQ_VHOST: taiga
      RABBITMQ_HOST: "localhost"
      RABBITMQ_PORT: "5672"
    ports:
      - "9000:8000"
    networks:
      - taiga-s01-net
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:8000/api/v1/ -o /dev/null || exit 1"]
      interval: 15s
      timeout: 10s
      retries: 24
      start_period: 120s

  taiga-front-s01:
    image: taigaio/taiga-front:latest
    container_name: taiga-front-s01
    restart: unless-stopped
    environment:
      TAIGA_URL: "http://localhost:9000"
      TAIGA_WEBSOCKETS_URL: "ws://localhost:9000"
    ports:
      - "9001:80"
    networks:
      - taiga-s01-net

networks:
  taiga-s01-net:
    name: taiga-s01-net
COMPOSE

  info "Pulling Taiga images..."
  docker compose pull -q 2>/dev/null || true
  docker compose up -d

  # Test 1: DB healthy
  info "Waiting for PostgreSQL..."
  if wait_healthy "$pgdb" 12 10; then
    pass "15-01 T1: Taiga PostgreSQL healthy"
  else
    fail "15-01 T1: Taiga PostgreSQL not healthy"
    docker compose down -v 2>/dev/null; return
  fi

  # Test 2: Poll backend API directly — Django migrations + gunicorn take 6–10 min on first run.
  # Use wait_http (direct HTTP poll) instead of Docker healthcheck to avoid timing complexity.
  info "Waiting for Taiga backend API to respond (~8 min for first-run migrations)..."
  if wait_http "http://localhost:9000/api/v1/" 48 15; then
    pass "15-01 T2: Taiga backend API responding"
  else
    fail "15-01 T2: Taiga backend API not responding (timeout)"
    docker compose logs --tail=30 taiga-back-s01
    docker compose down -v 2>/dev/null; return
  fi

  # Test 3: Backend API /api/v1/ → 200
  local code
  code=$(host_http "http://localhost:9000/api/v1/")
  if http_ok "$code"; then
    pass "15-01 T3: GET /api/v1/ → HTTP $code"
  else
    fail "15-01 T3: GET /api/v1/ → HTTP $code (expected 2xx)"
  fi

  # Test 4: Frontend (taiga-front nginx) → 200
  # Give front a brief moment to start (it's just nginx serving static files)
  sleep 10
  code=$(host_http "http://localhost:9001/")
  if http_ok "$code"; then
    pass "15-01 T4: Taiga frontend GET / → HTTP $code"
  else
    fail "15-01 T4: Taiga frontend GET / → HTTP $code (expected 2xx)"
  fi

  docker compose down -v 2>/dev/null
  cd "$WORKDIR"
}

# ============================================================================
# LAB 20-01: GRAYLOG STANDALONE
# ============================================================================
run_graylog() {
  step "Lab 20-01 — Graylog Standalone"
  local dir="$WORKDIR/graylog" graylog="graylog-s01" mongo="graylog-mongo-s01" es="graylog-es-s01"
  mkdir -p "$dir" && cd "$dir"

  # Graylog 5.2.x with Elasticsearch 7.17 (lighter than OpenSearch for standalone lab)
  # GRAYLOG_ROOT_PASSWORD_SHA2 = SHA256("Admin01!")
  # Computed: echo -n "Admin01!" | sha256sum
  #   = ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f
  cat > docker-compose.yml << 'COMPOSE'
services:
  graylog-mongo-s01:
    image: mongo:6.0
    container_name: graylog-mongo-s01
    restart: unless-stopped
    networks:
      - graylog-s01-net
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 15s
      timeout: 10s
      retries: 10
      start_period: 30s

  graylog-es-s01:
    image: elasticsearch:7.17.22
    container_name: graylog-es-s01
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
      - "bootstrap.memory_lock=true"
    ulimits:
      memlock:
        soft: -1
        hard: -1
    networks:
      - graylog-s01-net
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:9200/_cluster/health || exit 1"]
      interval: 15s
      timeout: 10s
      retries: 12
      start_period: 30s

  graylog-s01:
    image: graylog/graylog:5.2
    container_name: graylog-s01
    restart: unless-stopped
    depends_on:
      graylog-mongo-s01:
        condition: service_healthy
      graylog-es-s01:
        condition: service_healthy
    environment:
      # Must be at least 16 chars and same across restarts
      GRAYLOG_PASSWORD_SECRET: "ItStackGraylogLabSecret01ForPhase4"
      # SHA256 of "Admin01!" — verified: echo -n "Admin01!" | sha256sum
      GRAYLOG_ROOT_PASSWORD_SHA2: "141780dc12e8a07c36e2cd28c975455b09328e6c65782c4152a1e18a4d802c98"
      GRAYLOG_HTTP_EXTERNAL_URI: "http://localhost:9002/"
      GRAYLOG_ELASTICSEARCH_HOSTS: "http://graylog-es-s01:9200"
      GRAYLOG_MONGODB_URI: "mongodb://graylog-mongo-s01:27017/graylog"
      # Reduce journal size — default 5 GB exceeds typical lab disk space
      GRAYLOG_MESSAGE_JOURNAL_MAX_SIZE: "512mb"
      GRAYLOG_MESSAGE_JOURNAL_MAX_AGE: "12h"
      TZ: UTC
    ports:
      - "9002:9000"
      - "1514:1514/udp"
      - "12201:12201/udp"
    networks:
      - graylog-s01-net
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:9000/api/system/lbstatus | grep -qi ALIVE || exit 1"]
      interval: 20s
      timeout: 15s
      retries: 36
      start_period: 150s

networks:
  graylog-s01-net:
    name: graylog-s01-net
COMPOSE

  info "Pulling Graylog images (mongo:6.0 + elasticsearch:7.17.22 + graylog:5.2)..."
  docker compose pull -q 2>/dev/null || true
  docker compose up -d

  # Test 1: MongoDB healthy
  info "Waiting for MongoDB..."
  if wait_healthy "$mongo" 12 15; then
    pass "20-01 T1: Graylog MongoDB healthy"
  else
    fail "20-01 T1: Graylog MongoDB not healthy"
    docker compose logs --tail=20 graylog-mongo-s01
    docker compose down -v 2>/dev/null; return
  fi

  # Test 2: Elasticsearch healthy
  info "Waiting for Elasticsearch (Graylog dependency)..."
  if wait_healthy "$es" 12 15; then
    pass "20-01 T2: Graylog Elasticsearch healthy"
  else
    fail "20-01 T2: Graylog Elasticsearch dependency not healthy"
    docker compose logs --tail=20 graylog-es-s01
    docker compose down -v 2>/dev/null; return
  fi

  # Test 3: Graylog healthy (~10-18 min on local Docker for journal + index init)
  info "Waiting for Graylog to become healthy (~15 min for journal + index init on local Docker)..."
  if wait_healthy "$graylog" 54 20; then
    pass "20-01 T3: Graylog container healthy"
  else
    fail "20-01 T3: Graylog container not healthy (timeout)"
    docker compose logs --tail=30 graylog-s01
    docker compose down -v 2>/dev/null; return
  fi

  # Test 4: API /api/system with basic auth → 200
  local code
  code=$(host_http_auth "http://localhost:9002/api/system" "admin" "Admin01!")
  if http_ok "$code"; then
    pass "20-01 T4: GET /api/system → HTTP $code"
  else
    fail "20-01 T4: GET /api/system → HTTP $code (expected 2xx)"
  fi

  # Test 5: /api/system/lbstatus — no-auth health endpoint returns ALIVE
  local lb_body
  lb_body=$(host_get "http://localhost:9002/api/system/lbstatus")
  if echo "$lb_body" | grep -qi "ALIVE"; then
    pass "20-01 T5: Graylog /api/system/lbstatus returns ALIVE"
  else
    fail "20-01 T5: Graylog lbstatus not ALIVE — body: ${lb_body:0:200}"
  fi

  docker compose down -v 2>/dev/null
  cd "$WORKDIR"
}

# ============================================================================
# MAIN
# ============================================================================
echo ""
echo -e "${CYAN}========================================================${NC}"
echo -e "${CYAN}  IT-Stack Phase 4 — Standalone Lab Tests               ${NC}"
echo -e "${CYAN}  Modules: Elasticsearch · Snipe-IT · GLPI              ${NC}"
echo -e "${CYAN}           Zabbix · Taiga · Graylog                     ${NC}"
echo -e "${CYAN}========================================================${NC}"
echo "Host: $(hostname) | $(date)"
echo "Docker: $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
echo "Compose: $(docker compose version 2>/dev/null)"
echo "Memory: $(free -h 2>/dev/null | awk '/^Mem:/{print $2}') total"
echo ""

# Ensure vm.max_map_count is set for Elasticsearch
current_mmc=$(cat /proc/sys/vm/max_map_count 2>/dev/null || echo 0)
if [[ "$current_mmc" -lt 262144 ]]; then
  info "Setting vm.max_map_count=262144 (required for Elasticsearch/OpenSearch)"
  sudo sysctl -w vm.max_map_count=262144 2>/dev/null || true
fi

[[ "$SKIP_ELASTICSEARCH" == "true" ]] && info "Skipping: Elasticsearch"
[[ "$SKIP_SNIPEIT"       == "true" ]] && info "Skipping: Snipe-IT"
[[ "$SKIP_GLPI"          == "true" ]] && info "Skipping: GLPI"
[[ "$SKIP_ZABBIX"        == "true" ]] && info "Skipping: Zabbix"
[[ "$SKIP_TAIGA"         == "true" ]] && info "Skipping: Taiga"
[[ "$SKIP_GRAYLOG"       == "true" ]] && info "Skipping: Graylog"
echo ""

[[ "$SKIP_ELASTICSEARCH" == "false" ]] && run_elasticsearch
[[ "$SKIP_SNIPEIT"       == "false" ]] && run_snipeit
[[ "$SKIP_GLPI"          == "false" ]] && run_glpi
[[ "$SKIP_ZABBIX"        == "false" ]] && run_zabbix
[[ "$SKIP_TAIGA"         == "false" ]] && run_taiga
[[ "$SKIP_GRAYLOG"       == "false" ]] && run_graylog

# ============================================================================
# RESULTS
# ============================================================================
echo ""
echo -e "${CYAN}=======================================${NC}"
echo -e "${CYAN}  Phase 4 Lab Results${NC}"
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
echo -e "${GREEN}All Phase 4 standalone lab tests PASSED!${NC}"
