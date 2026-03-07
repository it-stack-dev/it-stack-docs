#!/usr/bin/env bash
# Phase 1 Lab Tests — Standalone (Lab XX-01) for all Phase 1 modules
# Modules: Keycloak, PostgreSQL, Redis, Traefik  (FreeIPA run separately)
# Usage  : bash lab-phase1.sh [--skip-freeipa]
# Requires: Docker, Docker Compose v2

set -uo pipefail
SKIP_FREEIPA=false
[[ "${1:-}" == "--skip-freeipa" ]] && SKIP_FREEIPA=true

PASS=0; FAIL=0
declare -a FAILURES=()

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

pass() { echo -e "${GREEN}  [PASS]${NC} $1"; ((PASS++)); }
fail() { echo -e "${RED}  [FAIL]${NC} $1"; ((FAIL++)); FAILURES+=("$1"); }
step() { echo -e "\n${CYAN}>> $1${NC}"; }
info() { echo -e "${YELLOW}  ...${NC} $1"; }

WORKDIR="$HOME/it-stack-labs"
mkdir -p "$WORKDIR"

# ──────────────────────────────────────────────────────────
# LAB 02-01: KEYCLOAK STANDALONE
# ──────────────────────────────────────────────────────────
run_keycloak() {
  step "Lab 02-01 — Keycloak Standalone"
  local dir="$WORKDIR/keycloak" name="it-stack-keycloak-lab01"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << 'COMPOSE'
services:
  keycloak:
    image: quay.io/keycloak/keycloak:24.0.5
    container_name: it-stack-keycloak-lab01
    command: start-dev
    ports:
      - "8180:8080"
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: Lab01Password!
      KC_HTTP_ENABLED: "true"
      KC_HOSTNAME_STRICT: "false"
      KC_HOSTNAME_STRICT_HTTPS: "false"
      KC_LOG_LEVEL: INFO
      KC_HEALTH_ENABLED: "true"
      KC_METRICS_ENABLED: "true"
    healthcheck:
      test: ["CMD", "/bin/bash", "-c", "exec 3<>/dev/tcp/localhost/8080"]
      interval: 15s
      timeout: 10s
      retries: 20
      start_period: 60s
    networks:
      - it-stack-net
networks:
  it-stack-net:
    driver: bridge
COMPOSE

  info "Starting Keycloak..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Keycloak to become healthy (up to 5 min)..."
  for i in $(seq 1 30); do
    sleep 10
    status=$(docker inspect $name --format '{{.State.Health.Status}}' 2>/dev/null)
    [[ "$status" == "healthy" ]] && break
    echo -ne "    ${i}/30 ($status) \r"
  done
  echo ""

  status=$(docker inspect $name --format '{{.State.Health.Status}}' 2>/dev/null)
  if [[ "$status" != "healthy" ]]; then
    fail "Keycloak container is $status after 5 min"
    docker compose down -v 2>/dev/null; return
  fi

  # Test 1: Admin API responds (Keycloak redirects / -> /auth or login page, 302 is normal)
  response=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8180/)
  if [[ "$response" == "200" || "$response" == "302" || "$response" == "303" ]]; then
    pass "Keycloak HTTP endpoint responds (HTTP $response)"
  else
    fail "Keycloak HTTP endpoint returned $response"
  fi

  # Test 2: Admin login — obtain token
  info "Testing admin token endpoint..."
  token_resp=$(curl -sf -X POST http://localhost:8180/realms/master/protocol/openid-connect/token \
    -d "client_id=admin-cli" -d "username=admin" \
    -d "password=Lab01Password!" -d "grant_type=password" 2>/dev/null)
  if echo "$token_resp" | grep -q "access_token"; then
    pass "Keycloak admin login and OIDC token issued"
  else
    fail "Keycloak admin token request failed"
  fi

  # Test 3: Health endpoint
  health=$(curl -sf http://localhost:8180/health/ready 2>/dev/null)
  if echo "$health" | grep -qi "UP"; then
    pass "Keycloak /health/ready: UP"
  else
    fail "Keycloak /health/ready not UP: $health"
  fi

  info "Cleaning up Keycloak..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────
# LAB 03-01: POSTGRESQL STANDALONE
# ──────────────────────────────────────────────────────────
run_postgresql() {
  step "Lab 03-01 — PostgreSQL Standalone"
  local dir="$WORKDIR/postgresql" name="it-stack-postgresql-lab01"
  mkdir -p "$dir/init" && cd "$dir"

  # Init script to create multiple databases — created via docker exec after healthcheck
  : # no init volume needed for standalone lab

  cat > docker-compose.yml << 'COMPOSE'
services:
  postgresql:
    image: postgres:16
    container_name: it-stack-postgresql-lab01
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: labadmin
      POSTGRES_PASSWORD: Lab01Password!
      POSTGRES_DB: labdb
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U labadmin -d labdb"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s
    networks:
      - it-stack-net
networks:
  it-stack-net:
    driver: bridge
volumes:
  postgresql_data:
    name: it-stack-postgresql-lab01-data
COMPOSE

  info "Starting PostgreSQL..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for PostgreSQL to become healthy (up to 2 min)..."
  for i in $(seq 1 12); do
    sleep 10
    status=$(docker inspect $name --format '{{.State.Health.Status}}' 2>/dev/null)
    [[ "$status" == "healthy" ]] && break
    echo -ne "    ${i}/12 ($status) \r"
  done
  echo ""

  status=$(docker inspect $name --format '{{.State.Health.Status}}' 2>/dev/null)
  if [[ "$status" != "healthy" ]]; then
    fail "PostgreSQL container is $status after 2 min"
    docker compose down -v 2>/dev/null; return
  fi

  # Test 1: pg_isready
  result=$(docker exec $name pg_isready -U labadmin -d labdb 2>&1)
  if echo "$result" | grep -q "accepting connections"; then
    pass "PostgreSQL pg_isready: accepting connections"
  else
    fail "pg_isready failed: $result"
  fi

  # Test 2: CRUD
  docker exec $name psql -U labadmin -d labdb -c "
    CREATE TABLE IF NOT EXISTS lab_test (id SERIAL PRIMARY KEY, val TEXT);
    INSERT INTO lab_test (val) VALUES ('hello from lab 03-01');
  " > /dev/null 2>&1
  result=$(docker exec $name psql -U labadmin -d labdb -tAc "SELECT val FROM lab_test LIMIT 1" 2>/dev/null)
  if [[ "$result" == "hello from lab 03-01" ]]; then
    pass "PostgreSQL CRUD: CREATE TABLE + INSERT + SELECT"
  else
    fail "PostgreSQL CRUD failed: got '$result'"
  fi

  # Test 3: Create additional databases manually and verify
  docker exec $name psql -U labadmin -d labdb -c "CREATE DATABASE appdb;" > /dev/null 2>&1 || true
  docker exec $name psql -U labadmin -d labdb -c "CREATE DATABASE testdb;" > /dev/null 2>&1 || true
  dbs=$(docker exec $name psql -U labadmin -d labdb -tAc "SELECT datname FROM pg_database WHERE datname IN ('appdb','testdb') ORDER BY datname" 2>/dev/null)
  if echo "$dbs" | grep -q "appdb" && echo "$dbs" | grep -q "testdb"; then
    pass "PostgreSQL multi-db: appdb and testdb created"
  else
    fail "PostgreSQL multi-db creation failed: $dbs"
  fi

  info "Cleaning up PostgreSQL..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────
# LAB 04-01: REDIS STANDALONE
# ──────────────────────────────────────────────────────────
run_redis() {
  step "Lab 04-01 — Redis Standalone"
  local dir="$WORKDIR/redis" name="it-stack-redis-lab01"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << 'COMPOSE'
services:
  redis:
    image: redis:7-alpine
    container_name: it-stack-redis-lab01
    ports:
      - "6379:6379"
    command: >
      redis-server
      --requirepass "Lab01Password!"
      --maxmemory 256mb
      --maxmemory-policy allkeys-lru
      --appendonly yes
      --loglevel notice
      --bind 0.0.0.0
      --protected-mode no
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "Lab01Password!", "ping"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 15s
    networks:
      - it-stack-net
networks:
  it-stack-net:
    driver: bridge
volumes:
  redis_data:
    name: it-stack-redis-lab01-data
COMPOSE

  info "Starting Redis..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Redis to become healthy (up to 2 min)..."
  for i in $(seq 1 12); do
    sleep 10
    status=$(docker inspect $name --format '{{.State.Health.Status}}' 2>/dev/null)
    [[ "$status" == "healthy" ]] && break
    echo -ne "    ${i}/12 ($status) \r"
  done
  echo ""

  status=$(docker inspect $name --format '{{.State.Health.Status}}' 2>/dev/null)
  if [[ "$status" != "healthy" ]]; then
    fail "Redis container is $status after 2 min"
    docker compose down -v 2>/dev/null; return
  fi

  # Test 1: PING
  result=$(docker exec $name redis-cli -a Lab01Password! ping 2>/dev/null)
  if [[ "$result" == "PONG" ]]; then
    pass "Redis PING: PONG"
  else
    fail "Redis PING failed: $result"
  fi

  # Test 2: SET + GET
  docker exec $name redis-cli -a Lab01Password! SET lab:test "hello from lab 04-01" > /dev/null 2>&1
  result=$(docker exec $name redis-cli -a Lab01Password! GET lab:test 2>/dev/null)
  if [[ "$result" == "hello from lab 04-01" ]]; then
    pass "Redis SET/GET key-value"
  else
    fail "Redis SET/GET failed: $result"
  fi

  # Test 3: Data structures — LPUSH + LRANGE
  docker exec $name redis-cli -a Lab01Password! LPUSH lab:list a b c > /dev/null 2>&1
  result=$(docker exec $name redis-cli -a Lab01Password! LLEN lab:list 2>/dev/null)
  if [[ "$result" == "3" ]]; then
    pass "Redis LPUSH/LLEN list operations"
  else
    fail "Redis list ops failed: LLEN=$result"
  fi

  # Test 4: Persistence — check AOF enabled
  result=$(docker exec $name redis-cli -a Lab01Password! CONFIG GET appendonly 2>/dev/null | tail -1)
  if [[ "$result" == "yes" ]]; then
    pass "Redis AOF persistence enabled"
  else
    fail "Redis AOF not enabled: $result"
  fi

  info "Cleaning up Redis..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────
# LAB 18-01: TRAEFIK STANDALONE
# ──────────────────────────────────────────────────────────
run_traefik() {
  step "Lab 18-01 — Traefik Standalone"
  local dir="$WORKDIR/traefik" name="it-stack-traefik-lab01"
  mkdir -p "$dir" && cd "$dir"

  # Note: Docker label discovery requires DOCKER_API_VERSION>=1.40 fix in Traefik
  # (Docker 29.x raised minimum accepted API version from 1.24 to 1.40).
  # Lab 01 uses file provider to test core routing functionality equivalently.
  # Docker label discovery is validated in Lab 02 (multi-machine, Docker 28.x or patched).

  cat > dynamic.yml << 'DYNCONF'
http:
  routers:
    whoami:
      rule: "Host(`app.lab.localhost`)"
      entryPoints:
        - web
      service: whoami-svc
  services:
    whoami-svc:
      loadBalancer:
        servers:
          - url: "http://it-stack-whoami-lab01/"
DYNCONF

  cat > docker-compose.yml << 'COMPOSE'
services:
  traefik:
    image: traefik:v3.1
    container_name: it-stack-traefik-lab01
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"
      - "--ping=true"
      - "--ping.entryPoint=web"
      - "--entrypoints.web.address=:8088"
      - "--providers.file.filename=/etc/traefik/dynamic.yml"
      - "--providers.file.watch=true"
      - "--log.level=INFO"
    ports:
      - "8088:8088"
      - "8080:8080"
    volumes:
      - ./dynamic.yml:/etc/traefik/dynamic.yml:ro
    healthcheck:
      test: ["CMD-SHELL", "wget -qO/dev/null http://localhost:8088/ping"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 15s
    networks:
      - it-stack-net
  whoami:
    image: traefik/whoami:latest
    container_name: it-stack-whoami-lab01
    networks:
      - it-stack-net
networks:
  it-stack-net:
    driver: bridge
COMPOSE

  info "Starting Traefik..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Traefik to become healthy (up to 2 min)..."
  for i in $(seq 1 12); do
    sleep 10
    status=$(docker inspect $name --format '{{.State.Health.Status}}' 2>/dev/null)
    [[ "$status" == "healthy" ]] && break
    echo -ne "    ${i}/12 ($status) \r"
  done
  echo ""

  status=$(docker inspect $name --format '{{.State.Health.Status}}' 2>/dev/null)
  if [[ "$status" != "healthy" ]]; then
    fail "Traefik container is $status"
    docker logs $name 2>&1 | tail -10
    docker compose down -v 2>/dev/null; return
  fi

  # Test 1: /ping endpoint
  result=$(curl -sf http://localhost:8088/ping 2>/dev/null)
  if [[ "$result" == "OK" ]]; then
    pass "Traefik /ping: OK"
  else
    fail "Traefik /ping failed: $result"
  fi

  # Test 2: Dashboard API accessible
  code=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost:8080/api/rawdata 2>/dev/null)
  if [[ "$code" == "200" ]]; then
    pass "Traefik dashboard API: HTTP 200"
  else
    fail "Traefik dashboard API returned $code"
  fi

  # Test 3: File provider route registered
  routers=$(curl -sf http://localhost:8080/api/http/routers 2>/dev/null)
  if echo "$routers" | grep -qi "whoami"; then
    pass "Traefik file provider: 'whoami' router loaded"
  else
    fail "Traefik file provider router not found; got: ${routers:0:120}"
  fi

  # Test 4: Reverse proxy routing via Host header
  info "Testing reverse proxy routing to whoami backend..."
  sleep 3
  result=$(curl -sf -H "Host: app.lab.localhost" http://localhost:8088/ 2>/dev/null)
  if echo "$result" | grep -qiE "hostname|ip|x-forwarded|GET / HTTP"; then
    pass "Traefik reverse proxy: request routed to whoami backend"
  else
    fail "Traefik reverse proxy: routing failed (result: ${result:0:80})"
  fi

  info "Cleaning up Traefik..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────
# LAB 01-01: FREEIPA STANDALONE  (slow — ~15 min)
# ──────────────────────────────────────────────────────────
run_freeipa() {
  step "Lab 01-01 — FreeIPA Standalone (takes 10-20 min on first run)"
  local name="it-stack-freeipa-lab01"
  # Note: Uses 'docker run' directly (not compose) because Docker Compose schema
  # validation rejects 'cgroupns: host' key. The --cgroupns host flag is required
  # on Docker 29+ with kernel 6.x cgroupv2-only hosts (Azure Ubuntu 24.04).
  # Image: patched from freeipa/freeipa-server:almalinux-9 to fix RAM check.
  # Build: cd ~/freeipa-patch && docker build -t it-stack-freeipa-patched:almalinux-9 .

  # Clean any prior run
  docker rm -f "$name" 2>/dev/null || true
  docker volume rm it-stack-freeipa-lab01-data 2>/dev/null || true

  info "Starting FreeIPA via docker run (cgroupns:host required for cgroupv2)..."
  docker run -d \
    --name "$name" \
    --hostname freeipa.lab.localhost \
    --privileged \
    --cgroupns host \
    --security-opt seccomp:unconfined \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    -p 8180:80 -p 8443:443 -p 8389:389 -p 8636:636 \
    -e "IPA_SERVER_INSTALL_OPTS=--unattended --realm=LAB.LOCALHOST --domain=lab.localhost --ds-password=Lab01DsPassword! --admin-password=Lab01Password! --no-ntp --no-sshd --no-ui-redirect --setup-dns --forwarder=1.1.1.1 --auto-reverse --no-host-dns" \
    -v it-stack-freeipa-lab01-data:/data:Z \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
    it-stack-freeipa-patched:almalinux-9 2>&1

  info "Waiting for FreeIPA — install takes 10-20 min, checking every 30s for up to 30 min..."
  for i in $(seq 1 60); do
    sleep 30
    cstate=$(docker inspect "$name" --format '{{.State.Status}}' 2>/dev/null)
    # Check install log for failure
    if docker logs "$name" 2>&1 | tail -3 | grep -qiE "command failed"; then
      echo ""
      fail "FreeIPA install failed"
      docker logs "$name" 2>&1 | tail -25
      docker rm -f "$name" 2>/dev/null; docker volume rm it-stack-freeipa-lab01-data 2>/dev/null; return
    fi
    # Check if systemd is up (ipactl is then available)
    if docker exec "$name" ipactl status > /dev/null 2>&1; then
      echo -e "\n  FreeIPA services up after $((i*30))s"
      break
    fi
    echo -ne "    ${i}/60 [$((i*30))s] state: $cstate \r"
  done
  echo ""

  # Verify ipactl works
  if ! docker exec "$name" ipactl status > /dev/null 2>&1; then
    fail "FreeIPA not ready after 30 min"
    docker logs "$name" 2>&1 | tail -30
    docker rm -f "$name" 2>/dev/null; docker volume rm it-stack-freeipa-lab01-data 2>/dev/null; return
  fi

  # Test 1: ipactl status
  result=$(docker exec "$name" ipactl status 2>&1 | head -10)
  if echo "$result" | grep -qiE "running|active"; then
    pass "FreeIPA ipactl status: services running"
  else
    fail "FreeIPA ipactl status failed: $result"
  fi

  # Test 2: LDAP responding
  result=$(docker exec "$name" ldapwhoami -H ldap://localhost -x -D "cn=Directory Manager" -w Lab01DsPassword! 2>&1)
  if echo "$result" | grep -qi "dn:"; then
    pass "FreeIPA LDAP bind: Directory Manager authenticated"
  else
    fail "FreeIPA LDAP bind failed: $result"
  fi

  # Test 3: Kerberos KDC
  result=$(docker exec "$name" bash -c "echo Lab01Password! | kinit admin 2>&1 && klist 2>&1 | head -5")
  if echo "$result" | grep -qi "admin"; then
    pass "FreeIPA Kerberos: admin kinit succeeded"
  else
    fail "FreeIPA Kerberos: kinit failed: $result"
  fi

  # Test 4: HTTP redirect working
  code=$(curl -sk -o /dev/null -w "%{http_code}" http://localhost:8180/ipa/ui/ 2>/dev/null)
  if [[ "$code" == "200" || "$code" == "301" || "$code" == "302" ]]; then
    pass "FreeIPA web UI reachable (HTTP $code)"
  else
    fail "FreeIPA web UI returned $code"
  fi

  info "Cleaning up FreeIPA..."
  docker rm -f "$name" 2>&1 | tail -1
  docker volume rm it-stack-freeipa-lab01-data 2>/dev/null
}

# ──────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  IT-Stack Phase 1 Lab Tests (Lab XX-01)${NC}"
echo -e "${CYAN}========================================${NC}"
echo "Host: $(hostname) | $(date)"
echo "Docker: $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
echo "Compose: $(docker compose version 2>/dev/null)"
echo ""

# Ensure no port conflicts from previous runs
docker ps -q | xargs -r docker stop > /dev/null 2>&1 || true

run_keycloak
run_postgresql
run_redis
run_traefik

if [[ "$SKIP_FREEIPA" == "false" ]]; then
  run_freeipa
else
  info "FreeIPA skipped (--skip-freeipa flag)"
fi

# ──────────────────────────────────────────────────────────
# RESULTS
# ──────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}  Phase 1 Lab Results${NC}"
echo -e "${CYAN}======================================${NC}"
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
echo -e "${GREEN}All Phase 1 standalone lab tests PASSED!${NC}"
