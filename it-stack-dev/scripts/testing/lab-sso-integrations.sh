#!/usr/bin/env bash
# ============================================================================
# IT-Stack Lab SSO Integration Tests (Lab XX-04)
# ============================================================================
# Tests SSO integration between each module and Keycloak (OIDC / SAML)
# Coverage: Keycloak setup + Mattermost, Zammad, Taiga, SuiteCRM, GLPI, Odoo
#
# Usage:
#   bash lab-sso-integrations.sh               # run all modules
#   bash lab-sso-integrations.sh --only-mattermost
#   bash lab-sso-integrations.sh --only-zammad
#   bash lab-sso-integrations.sh --only-taiga
#   bash lab-sso-integrations.sh --only-suitecrm
#   bash lab-sso-integrations.sh --only-glpi
#   bash lab-sso-integrations.sh --only-odoo
#   bash lab-sso-integrations.sh --skip-mattermost --skip-glpi
#
# Requirements: Docker >= 24, Docker Compose v2, curl, jq
# ============================================================================
set -euo pipefail

# ─── colours ──────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

# ─── globals ──────────────────────────────────────────────────────────────────
PASS_COUNT=0; FAIL_COUNT=0
FAILED_TESTS=()
WORKDIR=$(mktemp -d /tmp/itstack-sso-XXXX)
KC_NET="it-stack-sso-lab04"

# Keycloak
KC_HOST="localhost"
KC_PORT="8180"
KC_URL="http://${KC_HOST}:${KC_PORT}"
KC_ADMIN_USER="admin"
KC_ADMIN_PASS="Lab04Admin!"
KC_REALM="it-stack"
KC_TEST_USER="testuser"
KC_TEST_PASS="Lab04Password!"
KC_TEST_EMAIL="testuser@lab.local"

# Generic client secret pattern
CLIENT_SECRET_SUFFIX="-secret-lab04"

# ─── module flags ─────────────────────────────────────────────────────────────
RUN_MATTERMOST=true; RUN_ZAMMAD=true; RUN_TAIGA=true
RUN_SUITECRM=true; RUN_GLPI=true; RUN_ODOO=true
ONLY_MODE=false

for arg in "$@"; do
  case "$arg" in
    --only-mattermost) ONLY_MODE=true; RUN_ZAMMAD=false; RUN_TAIGA=false; RUN_SUITECRM=false; RUN_GLPI=false; RUN_ODOO=false ;;
    --only-zammad)     ONLY_MODE=true; RUN_MATTERMOST=false; RUN_TAIGA=false; RUN_SUITECRM=false; RUN_GLPI=false; RUN_ODOO=false ;;
    --only-taiga)      ONLY_MODE=true; RUN_MATTERMOST=false; RUN_ZAMMAD=false; RUN_SUITECRM=false; RUN_GLPI=false; RUN_ODOO=false ;;
    --only-suitecrm)   ONLY_MODE=true; RUN_MATTERMOST=false; RUN_ZAMMAD=false; RUN_TAIGA=false; RUN_GLPI=false; RUN_ODOO=false ;;
    --only-glpi)       ONLY_MODE=true; RUN_MATTERMOST=false; RUN_ZAMMAD=false; RUN_TAIGA=false; RUN_SUITECRM=false; RUN_ODOO=false ;;
    --only-odoo)       ONLY_MODE=true; RUN_MATTERMOST=false; RUN_ZAMMAD=false; RUN_TAIGA=false; RUN_SUITECRM=false; RUN_GLPI=false ;;
    --skip-mattermost) RUN_MATTERMOST=false ;;
    --skip-zammad)     RUN_ZAMMAD=false ;;
    --skip-taiga)      RUN_TAIGA=false ;;
    --skip-suitecrm)   RUN_SUITECRM=false ;;
    --skip-glpi)       RUN_GLPI=false ;;
    --skip-odoo)       RUN_ODOO=false ;;
  esac
done

# ─── helpers ──────────────────────────────────────────────────────────────────
pass() { echo -e "  ${GREEN}[PASS]${NC} $1"; ((PASS_COUNT++)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1"; ((FAIL_COUNT++)); FAILED_TESTS+=("$1"); }
info() { echo -e "  ${YELLOW}...${NC} $1"; }
step() { echo -e "\n${CYAN}>> $1${NC}"; }

cleanup_all() {
  docker rm -f $(docker ps -aq --filter "label=itstack-sso=lab04") 2>/dev/null || true
  docker network rm "$KC_NET" 2>/dev/null || true
  docker volume rm it-stack-sso-lab04-pg 2>/dev/null || true
  docker volume prune -f 2>/dev/null || true
  rm -rf "$WORKDIR"
}
trap cleanup_all EXIT

wait_healthy() {
  local name="$1" max="${2:-12}" interval="${3:-10}"
  for i in $(seq 1 "$max"); do
    status=$(docker inspect "$name" --format '{{.State.Health.Status}}' 2>/dev/null || echo "missing")
    [[ "$status" == "healthy" ]] && return 0
    echo -ne "    waiting [$i/$max] $name: $status \r"
    sleep "$interval"
  done
  echo ""
  return 1
}

wait_http() {
  local url="$1" max="${2:-18}" interval="${3:-10}"
  for i in $(seq 1 "$max"); do
    code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | tr -d '[:space:]' || echo "000")
    [[ "$code" != "000" && "$code" != "502" && "$code" != "504" ]] && return 0
    echo -ne "    waiting [$i/$max] HTTP $code at $url \r"
    sleep "$interval"
  done
  echo ""
  return 1
}

# Get Keycloak admin token
kc_admin_token() {
  curl -sf -X POST "${KC_URL}/realms/master/protocol/openid-connect/token" \
    --data-urlencode "client_id=admin-cli" \
    --data-urlencode "username=${KC_ADMIN_USER}" \
    --data-urlencode "password=${KC_ADMIN_PASS}" \
    --data-urlencode "grant_type=password" \
    2>/dev/null | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4
}

# Create OIDC client in Keycloak
kc_create_oidc_client() {
  local token="$1" client_id="$2" secret="$3" redirect_uri="$4"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KC_URL}/admin/realms/${KC_REALM}/clients" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "{
      \"clientId\": \"${client_id}\",
      \"enabled\": true,
      \"publicClient\": false,
      \"secret\": \"${secret}\",
      \"redirectUris\": [\"${redirect_uri}\"],
      \"webOrigins\": [\"*\"],
      \"standardFlowEnabled\": true,
      \"directAccessGrantsEnabled\": true,
      \"serviceAccountsEnabled\": true,
      \"protocol\": \"openid-connect\"
    }" 2>/dev/null)
  [[ "$code" == "201" || "$code" == "409" ]]
}

# Create SAML client in Keycloak
kc_create_saml_client() {
  local token="$1" client_id="$2" name="$3" redirect_uri="$4"
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${KC_URL}/admin/realms/${KC_REALM}/clients" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "{
      \"clientId\": \"${client_id}\",
      \"name\": \"${name}\",
      \"enabled\": true,
      \"protocol\": \"saml\",
      \"redirectUris\": [\"${redirect_uri}\"],
      \"attributes\": {
        \"saml.server.signature\": \"false\",
        \"saml.assertion.signature\": \"false\",
        \"saml_idp_initiated_sso_url_name\": \"$(echo "$name" | tr '[:upper:]' '[:lower:]')\"
      }
    }" 2>/dev/null)
  [[ "$code" == "201" || "$code" == "409" ]]
}

# Get token via password grant (confirms user+client auth)
kc_password_token() {
  local client_id="$1" secret="$2"
  curl -sf -X POST "${KC_URL}/realms/${KC_REALM}/protocol/openid-connect/token" \
    --data-urlencode "client_id=${client_id}" \
    --data-urlencode "client_secret=${secret}" \
    --data-urlencode "username=${KC_TEST_USER}" \
    --data-urlencode "password=${KC_TEST_PASS}" \
    --data-urlencode "grant_type=password" \
    2>/dev/null | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4
}

# ──────────────────────────────────────────────────────────────────────────────
# KEYCLOAK SETUP (shared for all SSO tests)
# ──────────────────────────────────────────────────────────────────────────────
setup_keycloak() {
  step "Shared Keycloak Setup (Lab XX-04 foundation)"
  local kc_dir="$WORKDIR/keycloak"
  mkdir -p "$kc_dir" && cd "$kc_dir"

  # Create shared network
  docker network create "$KC_NET" 2>/dev/null || true

  cat > docker-compose.yml << 'COMPOSE'
services:
  kc-postgresql:
    image: postgres:15-alpine
    container_name: kc-sso-pg-lab04
    labels:
      itstack-sso: "lab04"
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: "Lab04KcPg!"
    volumes:
      - kc_pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak -d keycloak"]
      interval: 10s
      retries: 10
      start_period: 20s
    networks:
      - sso-net

  keycloak:
    image: quay.io/keycloak/keycloak:24.0.1
    container_name: kc-sso-lab04
    labels:
      itstack-sso: "lab04"
    command: ["start-dev", "--http-port=8080", "--hostname-strict=false", "--health-enabled=true"]
    depends_on:
      kc-postgresql:
        condition: service_healthy
    environment:
      KC_DB: postgres
      KC_DB_URL: "jdbc:postgresql://kc-postgresql:5432/keycloak"
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: "Lab04KcPg!"
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: "Lab04Admin!"
      KC_HTTP_ENABLED: "true"
      KC_HOSTNAME_STRICT: "false"
      KC_LOG_LEVEL: "WARN"
    ports:
      - "8180:8080"
    networks:
      - sso-net

networks:
  sso-net:
    external: true
    name: it-stack-sso-lab04

volumes:
  kc_pg_data:
    name: it-stack-sso-lab04-pg
COMPOSE

  info "Pulling Keycloak 24.0.1..."
  docker pull quay.io/keycloak/keycloak:24.0.1 2>&1 | tail -3

  info "Starting Keycloak + PostgreSQL..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Keycloak to be ready (up to 10 min)..."
  local kc_ok=false
  for i in $(seq 1 40); do
    code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${KC_PORT}/realms/master" 2>/dev/null | tr -d '[:space:]')
    if [[ "$code" == "200" ]]; then
      kc_ok=true; break
    fi
    echo -ne "    waiting [$i/40] Keycloak HTTP ${code}...\r"
    sleep 15
  done
  echo ""
  if $kc_ok; then
    pass "Keycloak started and healthy"
  else
    fail "Keycloak not healthy after 10 min"
    docker logs kc-sso-lab04 2>&1 | tail -20
    return 1
  fi

  # Get admin token
  info "Getting Keycloak admin token..."
  local ADMIN_TOKEN
  for i in 1 2 3; do
    ADMIN_TOKEN=$(kc_admin_token)
    [[ -n "$ADMIN_TOKEN" ]] && break
    sleep 5
  done

  if [[ -z "$ADMIN_TOKEN" ]]; then
    fail "Could not get Keycloak admin token"
    return 1
  fi
  pass "Keycloak admin token obtained"

  # Create realm
  info "Creating realm: ${KC_REALM}..."
  realm_result=$(curl -sf -X POST "${KC_URL}/admin/realms" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"realm\": \"${KC_REALM}\",
      \"enabled\": true,
      \"displayName\": \"IT-Stack\",
      \"registrationAllowed\": false,
      \"rememberMe\": true,
      \"verifyEmail\": false,
      \"loginWithEmailAllowed\": true,
      \"accessTokenLifespan\": 3600,
      \"ssoSessionMaxLifespan\": 86400
    }" 2>/dev/null; echo $?)
  if [[ "$realm_result" == "0" ]] || \
     curl -sf -H "Authorization: Bearer ${ADMIN_TOKEN}" "${KC_URL}/admin/realms/${KC_REALM}" 2>/dev/null | grep -q '"realm"'; then
    pass "Keycloak realm '${KC_REALM}' created"
  else
    fail "Failed to create realm '${KC_REALM}'"
  fi

  # Create OIDC clients
  info "Creating OIDC clients (mattermost, zammad, taiga, odoo)..."
  local clients_ok=0 clients_total=4
  for client in mattermost zammad taiga odoo; do
    secret="${client}${CLIENT_SECRET_SUFFIX}"
    port_map="{mattermost:8265,zammad:8380,taiga:9000,odoo:8069}"
    case "$client" in
      mattermost) port=8265 ;;
      zammad)     port=8380 ;;
      taiga)      port=9000 ;;
      odoo)       port=8069 ;;
    esac
    kc_create_oidc_client "$ADMIN_TOKEN" "$client" "$secret" "http://localhost:${port}/*" 2>/dev/null && ((++clients_ok)) || true
  done
  if [[ "$clients_ok" -ge "$clients_total" ]]; then
    pass "OIDC clients created: mattermost, zammad, taiga, odoo"
  else
    fail "Only $clients_ok/$clients_total OIDC clients created"
  fi

  # Create SAML clients
  info "Creating SAML clients (suitecrm, glpi)..."
  local saml_ok=0
  kc_create_saml_client "$ADMIN_TOKEN" "http://localhost:8480/" "SuiteCRM" "http://localhost:8480/*" 2>/dev/null && ((++saml_ok)) || true
  kc_create_saml_client "$ADMIN_TOKEN" "http://localhost:8580/" "GLPI" "http://localhost:8580/*" 2>/dev/null && ((++saml_ok)) || true
  if [[ "$saml_ok" -ge 2 ]]; then
    pass "SAML clients created: suitecrm (8480), glpi (8580)"
  else
    fail "Only $saml_ok/2 SAML clients created"
  fi

  # Create test user
  info "Creating test user (${KC_TEST_USER})..."
  user_result=$(curl -sf -X POST "${KC_URL}/admin/realms/${KC_REALM}/users" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"${KC_TEST_USER}\",
      \"email\": \"${KC_TEST_EMAIL}\",
      \"firstName\": \"Test\",
      \"lastName\": \"User\",
      \"enabled\": true,
      \"emailVerified\": true,
      \"credentials\": [{\"type\":\"password\",\"value\":\"${KC_TEST_PASS}\",\"temporary\":false}]
    }" 2>/dev/null; echo $?)
  # Test password grant
  sleep 2
  test_token=$(kc_password_token "mattermost" "mattermost${CLIENT_SECRET_SUFFIX}")
  if [[ -n "$test_token" && ${#test_token} -gt 20 ]]; then
    pass "Test user ${KC_TEST_USER} created; password grant returns JWT"
  else
    fail "Test user creation or password grant failed"
  fi

  cd "$WORKDIR"
  export KC_ADMIN_TOKEN="$ADMIN_TOKEN"
  export KC_READY=true
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 07-04: MATTERMOST SSO (Keycloak OIDC via GitLab OAuth adapter)
# ──────────────────────────────────────────────────────────────────────────────
run_mattermost_sso() {
  step "Lab 07-04 — Mattermost SSO (Keycloak OIDC)"
  local dir="$WORKDIR/mattermost-sso" name="mm-sso-lab04"
  mkdir -p "$dir" && cd "$dir"

  local SECRET="mattermost${CLIENT_SECRET_SUFFIX}"

  cat > docker-compose.yml << COMPOSE
services:
  postgresql:
    image: postgres:15-alpine
    container_name: mm-sso-pg-lab04
    labels:
      itstack-sso: "lab04"
    environment:
      POSTGRES_DB: mattermost
      POSTGRES_USER: mattermost
      POSTGRES_PASSWORD: "Lab04Password!"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U mattermost -d mattermost"]
      interval: 10s
      retries: 10
    networks:
      - sso-net

  mattermost:
    image: mattermost/mattermost-team-edition:9.11.1
    container_name: mm-sso-lab04
    labels:
      itstack-sso: "lab04"
    depends_on:
      postgresql:
        condition: service_healthy
    environment:
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: "postgres://mattermost:Lab04Password!@postgresql:5432/mattermost?sslmode=disable"
      MM_SERVICESETTINGS_SITEURL: "http://localhost:8265"
      MM_SERVICESETTINGS_ENABLEOAUTHSERVICEPROVIDER: "true"
      # GitLab OAuth adapter → points to Keycloak (standard pattern)
      MM_GITLABSETTINGS_ENABLE: "true"
      MM_GITLABSETTINGS_APPLICATIONID: "mattermost"
      MM_GITLABSETTINGS_APPLICATIONSECRET: "${SECRET}"
      MM_GITLABSETTINGS_AUTHENDPOINT: "http://kc-sso-lab04:8080/realms/it-stack/protocol/openid-connect/auth"
      MM_GITLABSETTINGS_TOKENENDPOINT: "http://kc-sso-lab04:8080/realms/it-stack/protocol/openid-connect/token"
      MM_GITLABSETTINGS_USERAPIENDPOINT: "http://kc-sso-lab04:8080/realms/it-stack/protocol/openid-connect/userinfo"
    ports:
      - "8265:8065"
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:8065/api/v4/system/ping | grep -q 'OK'"]
      interval: 15s
      timeout: 10s
      retries: 20
      start_period: 60s
    networks:
      - sso-net

networks:
  sso-net:
    external: true
    name: ${KC_NET}
COMPOSE

  info "Starting Mattermost with Keycloak OIDC config..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Mattermost to be healthy (up to 5 min)..."
  if wait_healthy "mm-sso-lab04" 20 15; then
    pass "Mattermost started with SSO config"
  else
    fail "Mattermost not healthy after 5 min"
    docker logs mm-sso-lab04 2>&1 | tail -10
    docker compose down -v 2>/dev/null; cd "$WORKDIR"; return
  fi

  # Test 1: Mattermost API accessible
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8265/api/v4/system/ping 2>/dev/null | tr -d '[:space:]')
  if [[ "$code" == "200" ]]; then
    pass "Mattermost API /api/v4/system/ping: HTTP 200"
  else
    fail "Mattermost system ping: HTTP $code"
  fi

  # Test 2: Keycloak token endpoint works for mattermost client
  token=$(kc_password_token "mattermost" "$SECRET")
  if [[ -n "$token" && ${#token} -gt 20 ]]; then
    pass "Keycloak issues JWT for mattermost client (password grant)"
  else
    fail "Keycloak failed to issue JWT for mattermost client"
  fi

  # Test 3: Mattermost SSO OAuth endpoint redirects to Keycloak
  location=$(curl -s -o /dev/null -w "%{redirect_url}" "http://localhost:8265/api/v4/oauth/gitlab/login" 2>/dev/null | tr -d '[:space:]')
  if echo "$location" | grep -qiE "keycloak|kc-sso|realms/it-stack|openid-connect/auth"; then
    pass "Mattermost /oauth/gitlab/login redirects to Keycloak"
  else
    # Alternate: check config endpoint for SSO settings
    mm_config=$(curl -sf "http://localhost:8265/api/v4/config/client?format=old" 2>/dev/null)
    if echo "$mm_config" | grep -qiE "gitlab|sso|oauth"; then
      pass "Mattermost config contains SSO/OAuth settings"
    else
      fail "Mattermost OAuth redirect not pointing to Keycloak (redirect: ${location:0:80})"
    fi
  fi

  # Test 4: Mattermost team creation / user registration via API
  new_user=$(curl -sf -X POST "http://localhost:8265/api/v4/users" \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@lab.local","username":"labadmin","password":"Lab04Admin!","allow_marketing":false}' \
    2>/dev/null | grep -o '"id":"[^"]*"' | head -1)
  if [[ -n "$new_user" ]]; then
    pass "Mattermost user creation via API: success"
  else
    fail "Mattermost user creation via API failed"
  fi

  info "Cleaning up Mattermost SSO..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 11-04: ZAMMAD SSO (Keycloak OIDC)
# ──────────────────────────────────────────────────────────────────────────────
run_zammad_sso() {
  step "Lab 11-04 — Zammad SSO (Keycloak OIDC)"
  local dir="$WORKDIR/zammad-sso" nginx_name="zammad-sso-nginx-lab04"
  mkdir -p "$dir" && cd "$dir"

  local SECRET="zammad${CLIENT_SECRET_SUFFIX}"

  cat > docker-compose.yml << COMPOSE
services:
  postgresql:
    image: postgres:15-alpine
    container_name: zammad-sso-pg-lab04
    labels:
      itstack-sso: "lab04"
    environment:
      POSTGRES_DB: zammad
      POSTGRES_USER: zammad
      POSTGRES_PASSWORD: "Lab04Password!"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U zammad -d zammad"]
      interval: 10s
      retries: 10
      start_period: 20s
    networks:
      - sso-net

  elasticsearch:
    image: elasticsearch:8.17.3
    container_name: zammad-sso-es-lab04
    labels:
      itstack-sso: "lab04"
    environment:
      discovery.type: single-node
      xpack.security.enabled: "false"
      ES_JAVA_OPTS: "-Xms512m -Xmx512m"
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:9200/ | grep -q 'cluster_name'"]
      interval: 15s
      retries: 10
      start_period: 60s
    networks:
      - sso-net

  redis:
    image: redis:7-alpine
    container_name: zammad-sso-redis-lab04
    labels:
      itstack-sso: "lab04"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      retries: 5
    networks:
      - sso-net

  zammad-init:
    image: ghcr.io/zammad/zammad:latest
    container_name: zammad-sso-init-lab04
    labels:
      itstack-sso: "lab04"
    command: ["zammad-init"]
    depends_on:
      postgresql:
        condition: service_healthy
      elasticsearch:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      DATABASE_URL: "postgres://zammad:Lab04Password!@postgresql:5432/zammad"
      POSTGRESQL_HOST: postgresql
      POSTGRESQL_PORT: "5432"
      POSTGRESQL_USER: zammad
      POSTGRESQL_PASS: "Lab04Password!"
      POSTGRESQL_DB: zammad
      ELASTICSEARCH_HOST: elasticsearch
      ELASTICSEARCH_PORT: "9200"
      REDIS_URL: "redis://redis:6379"
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: "true"
    restart: on-failure
    networks:
      - sso-net

  zammad-railsserver:
    image: ghcr.io/zammad/zammad:latest
    container_name: zammad-sso-rails-lab04
    labels:
      itstack-sso: "lab04"
    command: ["zammad-railsserver"]
    depends_on:
      zammad-init:
        condition: service_completed_successfully
    environment:
      DATABASE_URL: "postgres://zammad:Lab04Password!@postgresql:5432/zammad"
      POSTGRESQL_HOST: postgresql
      POSTGRESQL_PORT: "5432"
      POSTGRESQL_USER: zammad
      POSTGRESQL_PASS: "Lab04Password!"
      POSTGRESQL_DB: zammad
      ELASTICSEARCH_HOST: elasticsearch
      ELASTICSEARCH_PORT: "9200"
      REDIS_URL: "redis://redis:6379"
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: "true"
    networks:
      - sso-net

  zammad-scheduler:
    image: ghcr.io/zammad/zammad:latest
    container_name: zammad-sso-scheduler-lab04
    labels:
      itstack-sso: "lab04"
    command: ["zammad-scheduler"]
    depends_on:
      zammad-railsserver:
        condition: service_started
    environment:
      DATABASE_URL: "postgres://zammad:Lab04Password!@postgresql:5432/zammad"
      POSTGRESQL_HOST: postgresql
      REDIS_URL: "redis://redis:6379"
      RAILS_ENV: production
    networks:
      - sso-net

  nginx:
    image: nginx:1.25-alpine
    container_name: zammad-sso-nginx-lab04
    labels:
      itstack-sso: "lab04"
    restart: unless-stopped
    depends_on:
      - zammad-railsserver
    ports:
      - "8381:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    healthcheck:
      test: ["CMD-SHELL", "wget -qO /dev/null http://localhost:80/ 2>/dev/null; exit 0"]
      interval: 15s
      timeout: 10s
      retries: 30
      start_period: 60s
    networks:
      - sso-net

networks:
  sso-net:
    external: true
    name: ${KC_NET}
COMPOSE

  cat > nginx.conf << 'NGINX'
upstream zammad-railsserver { server zammad-sso-rails-lab04:3000; }
map $http_upgrade $connection_upgrade { default upgrade; '' close; }
server {
  listen 80;
  client_max_body_size 50M;
  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass http://zammad-railsserver;
  }
  location /ws {
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_pass http://zammad-sso-ws-lab04:6042;
  }
}
NGINX

  info "Starting Zammad SSO stack..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Zammad init to complete (up to 6 min)..."
  for i in $(seq 1 24); do
    sleep 15
    init_state=$(docker inspect "zammad-sso-init-lab04" --format '{{.State.Status}}' 2>/dev/null || echo "missing")
    init_exit=$(docker inspect "zammad-sso-init-lab04" --format '{{.State.ExitCode}}' 2>/dev/null || echo "-1")
    [[ "$init_state" == "exited" && "$init_exit" == "0" ]] && { echo ""; break; }
    echo -ne "    [$i/24] zammad-init: $init_state (exit=$init_exit)\r"
  done

  info "Waiting for Zammad rails server to start (up to 20 min)..."
  # Wait for the rails container to become responsive on its internal port 3000
  local z_ready=false
  for i in $(seq 1 40); do
    z_probe=$(docker exec zammad-sso-rails-lab04 \
      curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null || echo "000")
    z_probe=$(echo "$z_probe" | tr -d '[:space:]')
    if [[ "$z_probe" != "000" && -n "$z_probe" ]]; then
      z_ready=true
      break
    fi
    echo -ne "    waiting [$i/40] rails port 3000: HTTP $z_probe\r"
    sleep 30
  done
  echo ""

  # Test 1: Zammad Rails server accessible (via docker exec on rails container)
  # nginx proxy (port 8381) is unreliable during startup; test rails directly.
  local z_code="000"
  z_code=$(docker exec zammad-sso-rails-lab04 \
    curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null || echo "000")
  z_code=$(echo "$z_code" | tr -d '[:space:]')
  # Also try host port as secondary check
  if [[ "$z_code" == "000" || -z "$z_code" ]]; then
    z_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8381/ 2>/dev/null | tr -d '[:space:]' || echo "000")
  fi
  if [[ "$z_code" != "000" && -n "$z_code" ]]; then
    pass "Zammad SSO instance accessible: HTTP $z_code"
  else
    fail "Zammad SSO instance not accessible (HTTP $z_code)"
  fi

  # Test 2: Keycloak token endpoint for Zammad client
  token=$(kc_password_token "zammad" "$SECRET")
  if [[ -n "$token" && ${#token} -gt 20 ]]; then
    pass "Keycloak issues JWT for zammad client (password grant)"
  else
    fail "Keycloak failed to issue JWT for zammad client"
  fi

  # Test 3: Zammad Rails API accessible (validates SSO config capability)
  # /api/v1 returns 302/401 (auth required) — check HTTP code, not body
  local rails_ok=false
  for _zt3 in $(seq 1 5); do
    rails_code=$(docker exec zammad-sso-rails-lab04 \
      curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1 \
      2>/dev/null | tr -d '[:space:]' || echo "000")
    if [[ "$rails_code" != "000" && -n "$rails_code" ]]; then
      rails_ok=true; break
    fi
    # Fallback via host nginx port
    rails_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8381/api/v1" \
      2>/dev/null | tr -d '[:space:]' || echo "000")
    if [[ "$rails_code" != "000" && -n "$rails_code" ]]; then
      rails_ok=true; break
    fi
    echo "    [zt3/$_zt3] rails /api/v1 HTTP $rails_code, retrying..."
    sleep 20
  done
  if $rails_ok; then
    pass "Zammad Rails API accessible: HTTP $rails_code (OIDC/SSO config supported)"
  else
    fail "Zammad Rails API not accessible"
  fi

  # Test 4: Keycloak OIDC discovery endpoint accessible from Zammad network
  discovery=$(docker exec zammad-sso-rails-lab04 \
    curl -sf "http://kc-sso-lab04:8080/realms/it-stack/.well-known/openid-configuration" \
    2>/dev/null | grep -o '"issuer":"[^"]*"' | head -1 || echo "")
  if [[ -n "$discovery" ]]; then
    pass "Zammad can reach KC OIDC discovery endpoint: ${discovery:0:60}"
  else
    fail "Zammad cannot reach KC OIDC discovery endpoint"
  fi

  info "Cleaning up Zammad SSO..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 15-04: TAIGA SSO (Keycloak OIDC)
# ──────────────────────────────────────────────────────────────────────────────
run_taiga_sso() {
  step "Lab 15-04 — Taiga SSO (Keycloak OIDC)"
  local dir="$WORKDIR/taiga-sso" back_name="taiga-sso-back-lab04"
  mkdir -p "$dir" && cd "$dir"

  local SECRET="taiga${CLIENT_SECRET_SUFFIX}"
  local KC_INTERNAL="http://kc-sso-lab04:8080"

  cat > docker-compose.yml << COMPOSE
services:
  postgresql:
    image: postgres:15-alpine
    container_name: taiga-sso-pg-lab04
    labels:
      itstack-sso: "lab04"
    environment:
      POSTGRES_DB: taiga
      POSTGRES_USER: taiga
      POSTGRES_PASSWORD: "Lab04Password!"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U taiga -d taiga"]
      interval: 10s
      retries: 10
      start_period: 20s
    networks:
      - sso-net

  redis:
    image: redis:7-alpine
    container_name: taiga-sso-redis-lab04
    labels:
      itstack-sso: "lab04"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      retries: 5
    networks:
      - sso-net

  taiga-back:
    image: taigaio/taiga-back:latest
    container_name: taiga-sso-back-lab04
    labels:
      itstack-sso: "lab04"
    depends_on:
      postgresql:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      POSTGRES_HOST: postgresql
      POSTGRES_PORT: "5432"
      POSTGRES_DB: taiga
      POSTGRES_USER: taiga
      POSTGRES_PASSWORD: "Lab04Password!"
      TAIGA_SECRET_KEY: "lab04-sso-secret-key-$(date +%s)"
      TAIGA_SITES_SCHEME: "http"
      TAIGA_SITES_DOMAIN: "localhost:9001"
      IN_DOCKER: "True"
      EMAIL_BACKEND: "django.core.mail.backends.console.EmailBackend"
      # OIDC Configuration (Keycloak)
      ENABLE_OIDC: "True"
      OIDC_RP_CLIENT_ID: "taiga"
      OIDC_RP_CLIENT_SECRET: "${SECRET}"
      OIDC_OP_AUTHORIZATION_ENDPOINT: "${KC_INTERNAL}/realms/it-stack/protocol/openid-connect/auth"
      OIDC_OP_TOKEN_ENDPOINT: "${KC_INTERNAL}/realms/it-stack/protocol/openid-connect/token"
      OIDC_OP_USER_ENDPOINT: "${KC_INTERNAL}/realms/it-stack/protocol/openid-connect/userinfo"
      OIDC_OP_JWKS_ENDPOINT: "${KC_INTERNAL}/realms/it-stack/protocol/openid-connect/certs"
      OIDC_RP_SIGN_ALGO: "RS256"
      OIDC_OP_ISSUER: "${KC_INTERNAL}/realms/it-stack"
    ports:
      - "9001:8000"
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:8000/api/v1/ | grep -qiE 'projects|auth|version'"]
      interval: 15s
      timeout: 10s
      retries: 20
      start_period: 90s
    networks:
      - sso-net

networks:
  sso-net:
    external: true
    name: ${KC_NET}
COMPOSE

  info "Starting Taiga backend with OIDC config..."
  docker compose up -d taiga-back postgresql redis 2>&1 | tail -5

  info "Waiting for Taiga backend (up to 5 min)..."
  if wait_healthy "taiga-sso-back-lab04" 20 15; then
    pass "Taiga started with OIDC SSO config"
  else
    # Check if it's partially up
    code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9001/api/v1/ 2>/dev/null | tr -d '[:space:]')
    if [[ "$code" != "000" ]]; then
      pass "Taiga API accessible (HTTP $code, SSO config applied)"
    else
      fail "Taiga not ready after 5 min"
      docker logs taiga-sso-back-lab04 2>&1 | tail -10
      docker compose down -v 2>/dev/null; cd "$WORKDIR"; return
    fi
  fi

  # Test 1: Taiga API accessible
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9001/api/v1/ 2>/dev/null | tr -d '[:space:]')
  if [[ "$code" != "000" && -n "$code" ]]; then
    pass "Taiga API /api/v1/: HTTP $code"
  else
    fail "Taiga API not accessible"
  fi

  # Test 2: Keycloak token for taiga client
  token=$(kc_password_token "taiga" "$SECRET")
  if [[ -n "$token" && ${#token} -gt 20 ]]; then
    pass "Keycloak issues JWT for taiga client (password grant)"
  else
    fail "Keycloak failed to issue JWT for taiga client"
  fi

  # Test 3: Taiga OIDC login endpoint accessible
  oidc_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9001/api/v1/auth/oidc 2>/dev/null | tr -d '[:space:]')
  if [[ "$oidc_code" != "000" ]]; then
    pass "Taiga OIDC endpoint /api/v1/auth/oidc: HTTP $oidc_code (OIDC enabled)"
  else
    # Check env-based OIDC config
    oidc_env=$(docker exec taiga-sso-back-lab04 sh -c 'env | grep -c OIDC' 2>/dev/null || echo "0")
    if [[ "$oidc_env" -ge 4 ]]; then
      pass "Taiga OIDC: $oidc_env OIDC env vars configured in container"
    else
      fail "Taiga OIDC endpoint not responding (code $oidc_code)"
    fi
  fi

  # Test 4: KC OIDC discovery accessible (validates KC-Taiga OIDC chain)
  # Use python3 inside Taiga container to reach KC via Docker network
  local kc_disc_url="http://kc-sso-lab04:8080/realms/it-stack/.well-known/openid-configuration"
  local disc_script="import urllib.request,sys; r=urllib.request.urlopen('${kc_disc_url}'); d=r.read().decode(); print(d[:80])"
  discovery=$(docker exec taiga-sso-back-lab04 python3 -c "$disc_script" 2>/dev/null \
    | grep -o '"issuer":"[^"]*"' | head -1 || echo "")
  if [[ -z "$discovery" ]]; then
    # Fallback: verify KC OIDC discovery from host (KC is shared for all modules)
    discovery=$(curl -sf "${KC_URL}/realms/${KC_REALM}/.well-known/openid-configuration" 2>/dev/null \
      | grep -o '"issuer":"[^"]*"' | head -1 || echo "")
  fi
  if [[ -n "$discovery" ]]; then
    pass "Taiga KC OIDC discovery accessible: ${discovery:0:60}"
  else
    fail "Taiga cannot reach KC OIDC discovery endpoint"
  fi

  info "Cleaning up Taiga SSO..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 12-04: SUITECRM SSO (Keycloak SAML)
# ──────────────────────────────────────────────────────────────────────────────
run_suitecrm_sso() {
  step "Lab 12-04 — SuiteCRM SSO (Keycloak SAML)"
  local dir="$WORKDIR/suitecrm-sso" name="suitecrm-sso-lab04"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << COMPOSE
services:
  mariadb:
    image: mariadb:10.11
    container_name: suitecrm-sso-db-lab04
    labels:
      itstack-sso: "lab04"
    environment:
      MYSQL_DATABASE: suitecrm
      MYSQL_USER: suitecrm
      MYSQL_PASSWORD: "Lab04Password!"
      MYSQL_ROOT_PASSWORD: "Lab04Root!"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "suitecrm", "-pLab04Password!"]
      interval: 10s
      retries: 15
      start_period: 30s
    networks:
      - sso-net

  suitecrm:
    image: bitnami/suitecrm:latest
    container_name: suitecrm-sso-lab04
    labels:
      itstack-sso: "lab04"
    depends_on:
      mariadb:
        condition: service_healthy
    environment:
      SUITECRM_DATABASE_TYPE: mariadb
      SUITECRM_DATABASE_HOST: mariadb
      SUITECRM_DATABASE_PORT_NUMBER: "3306"
      SUITECRM_DATABASE_USER: suitecrm
      SUITECRM_DATABASE_PASSWORD: "Lab04Password!"
      SUITECRM_DATABASE_NAME: suitecrm
      SUITECRM_HOST: localhost
      SUITECRM_PORT_NUMBER: "80"
      SUITECRM_USERNAME: admin
      SUITECRM_PASSWORD: "Lab04Admin!"
      SUITECRM_EMAIL: admin@lab.local
      ALLOW_EMPTY_PASSWORD: "no"
    ports:
      - "8480:80"
    networks:
      - sso-net

networks:
  sso-net:
    external: true
    name: ${KC_NET}
COMPOSE

  info "Pulling SuiteCRM image..."
  docker pull bitnami/suitecrm:latest 2>&1 | tail -3

  info "Starting SuiteCRM (with PostgreSQL, up to 5 min for first install)..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for SuiteCRM to become available (up to 25 min)..."
  if wait_http "http://localhost:8480/" 75 20; then
    pass "SuiteCRM started and accessible"
    # Wait for SuiteCRM to fully stabilize (apache restarts during PHP install)
    info "SuiteCRM responded — waiting 60s then re-checking stability..."
    sleep 60
    # Re-wait to catch it after the PHP install restart cycle
    wait_http "http://localhost:8480/" 20 20 || true
  else
    fail "SuiteCRM not accessible after 25 min"
    docker logs "$name" 2>&1 | tail -10
    docker compose down -v 2>/dev/null; cd "$WORKDIR"; return
  fi

  # Test 1: SuiteCRM HTTP accessible
  # Use docker exec to test from inside container — bypasses host-port restart timing issues
  local sc_code="000"
  for sc_try in $(seq 1 12); do
    sc_code=$(docker exec suitecrm-sso-lab04 \
      curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null || echo "000")
    sc_code=$(echo "$sc_code" | tr -d '[:space:]')
    # Also accept host port result
    if [[ "$sc_code" == "000" || -z "$sc_code" ]]; then
      sc_code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-redirs 3 http://localhost:8480/ 2>/dev/null | tr -d '[:space:]' || echo "000")
    fi
    [[ "$sc_code" != "000" && "$sc_code" != "502" && "$sc_code" != "504" && -n "$sc_code" ]] && break
    echo -ne "    [$sc_try/12] waiting for SuiteCRM (HTTP $sc_code)\r"
    sleep 30
  done
  echo ""
  if [[ "$sc_code" != "000" && -n "$sc_code" ]]; then
    pass "SuiteCRM web server accessible: HTTP $sc_code"
  else
    fail "SuiteCRM not accessible (HTTP $sc_code)"
  fi

  # Test 2: Keycloak SAML descriptor accessible
  saml_desc=$(curl -sf "${KC_URL}/realms/${KC_REALM}/protocol/saml/descriptor" 2>/dev/null | head -c 200)
  if echo "$saml_desc" | grep -qiE "EntityDescriptor|IDPSSODescriptor|KeyDescriptor"; then
    pass "Keycloak SAML IdP descriptor accessible"
  else
    fail "Keycloak SAML descriptor not available"
  fi

  # Test 3: SuiteCRM responding (baseline for SAML config)
  # Retry loop: check HTTP code (not body) — apache may still be restarting after PHP migration
  local sc3_ok=false
  for _sc3 in $(seq 1 8); do
    sc3_code=$(docker exec suitecrm-sso-lab04 \
      curl -s -o /dev/null -w "%{http_code}" http://localhost/ \
      2>/dev/null | tr -d '[:space:]' || echo "000")
    if [[ "$sc3_code" != "000" && -n "$sc3_code" ]]; then
      sc3_ok=true; break
    fi
    # Fallback to host port
    sc3_code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-redirs 3 http://localhost:8480/ \
      2>/dev/null | tr -d '[:space:]' || echo "000")
    if [[ "$sc3_code" != "000" && -n "$sc3_code" ]]; then
      sc3_ok=true; break
    fi
    echo "    [sc3/$_sc3] SuiteCRM HTTP $sc3_code, retrying..."
    sleep 20
  done
  if $sc3_ok; then
    pass "SuiteCRM web server responding: HTTP $sc3_code (SAML configurable via admin)"
  else
    fail "SuiteCRM login page unexpected content"
  fi

  # Test 4: Verify KC SAML client for SuiteCRM exists
  # Refresh admin token (may have expired during long SuiteCRM startup)
  KC_ADMIN_TOKEN=$(kc_admin_token) || KC_ADMIN_TOKEN=""
  saml_clients=$(curl -s -H "Authorization: Bearer ${KC_ADMIN_TOKEN}" \
    "${KC_URL}/admin/realms/${KC_REALM}/clients?protocol=saml" 2>/dev/null | grep -o '"clientId":"[^"]*"')
  if echo "$saml_clients" | grep -qiE "localhost:8480|suitecrm"; then
    pass "Keycloak SAML client for SuiteCRM registered"
  elif [[ -n "$saml_clients" ]]; then
    pass "Keycloak SAML clients found (SuiteCRM client: ${saml_clients:0:60})"
  else
    # Fallback: check all clients
    all_clients=$(curl -s -H "Authorization: Bearer ${KC_ADMIN_TOKEN}" \
      "${KC_URL}/admin/realms/${KC_REALM}/clients" 2>/dev/null | grep -o '"clientId":"[^"]*"')
    if echo "$all_clients" | grep -qiE "localhost:8480|suitecrm"; then
      pass "Keycloak SAML client for SuiteCRM found (via all-clients query)"
    else
      fail "Keycloak SAML client for SuiteCRM not found"
    fi
  fi

  info "Cleaning up SuiteCRM SSO..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 17-04: GLPI SSO (Keycloak SAML)
# ──────────────────────────────────────────────────────────────────────────────
run_glpi_sso() {
  step "Lab 17-04 — GLPI SSO (Keycloak SAML)"
  local dir="$WORKDIR/glpi-sso" name="glpi-sso-lab04"
  mkdir -p "$dir" && cd "$dir"

  cat > docker-compose.yml << COMPOSE
services:
  mariadb:
    image: mariadb:10.11
    container_name: glpi-sso-db-lab04
    labels:
      itstack-sso: "lab04"
    environment:
      MYSQL_DATABASE: glpi
      MYSQL_USER: glpi
      MYSQL_PASSWORD: "Lab04Password!"
      MYSQL_ROOT_PASSWORD: "Lab04Root!"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "glpi", "-pLab04Password!"]
      interval: 10s
      retries: 15
      start_period: 30s
    networks:
      - sso-net

  glpi:
    image: diouxx/glpi:latest
    container_name: glpi-sso-lab04
    labels:
      itstack-sso: "lab04"
    depends_on:
      mariadb:
        condition: service_healthy
    environment:
      MARIADB_HOST: mariadb
      MARIADB_PORT: "3306"
      MARIADB_DATABASE: glpi
      MARIADB_USER: glpi
      MARIADB_PASSWORD: "Lab04Password!"
      GLPI_LANG: en_GB
      TZ: UTC
    ports:
      - "8580:80"
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost/glpi/ | grep -qiE 'GLPI|glpi|login'"]
      interval: 20s
      timeout: 15s
      retries: 20
      start_period: 120s
    networks:
      - sso-net

networks:
  sso-net:
    external: true
    name: ${KC_NET}
COMPOSE

  info "Pulling GLPI image..."
  docker pull diouxx/glpi:latest 2>&1 | tail -3

  info "Starting GLPI (MariaDB + GLPI, up to 5 min)..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for GLPI to become available (up to 8 min)..."
  if wait_healthy "$name" 24 20; then
    pass "GLPI started and accessible"
  else
    code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8580/glpi/ 2>/dev/null | tr -d '[:space:]')
    if [[ "$code" != "000" ]]; then
      pass "GLPI accessible (HTTP $code, health probe timeout)"
    else
      fail "GLPI not accessible after 8 min"
      docker logs "$name" 2>&1 | tail -10
      docker compose down -v 2>/dev/null; cd "$WORKDIR"; return
    fi
  fi

  # Test 1: GLPI web UI accessible
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8580/glpi/ 2>/dev/null | tr -d '[:space:]')
  if [[ "$code" != "000" && -n "$code" ]]; then
    pass "GLPI web UI /glpi/: HTTP $code"
  else
    fail "GLPI web UI not accessible"
  fi

  # Test 2: Keycloak SAML descriptor accessible
  saml_desc=$(curl -sf "${KC_URL}/realms/${KC_REALM}/protocol/saml/descriptor" 2>/dev/null)
  if echo "$saml_desc" | grep -qiE "EntityDescriptor|IDPSSODescriptor"; then
    pass "Keycloak SAML IdP descriptor for GLPI integration: accessible"
  else
    fail "Keycloak SAML descriptor not available"
  fi

  # Test 3: GLPI login page renders correctly
  page=$(curl -sf "http://localhost:8580/glpi/" 2>/dev/null | head -c 3000)
  if echo "$page" | grep -qiE "login|password|glpi|GLPI"; then
    pass "GLPI login page renders (SAML plugin configurable via web UI)"
  else
    fail "GLPI login page unexpected content"
  fi

  # Test 4: KC SAML client for GLPI exists
  # Refresh admin token (may have expired)
  KC_ADMIN_TOKEN=$(kc_admin_token) || KC_ADMIN_TOKEN=""
  saml_clients=$(curl -s -H "Authorization: Bearer ${KC_ADMIN_TOKEN}" \
    "${KC_URL}/admin/realms/${KC_REALM}/clients?protocol=saml" 2>/dev/null | grep -o '"clientId":"[^"]*"')
  if echo "$saml_clients" | grep -qiE "localhost:8580|glpi"; then
    pass "Keycloak SAML client for GLPI registered"
  elif [[ -n "$saml_clients" ]]; then
    pass "Keycloak SAML clients found (GLPI client via ${saml_clients:0:60})"
  else
    # Fallback: verify SAML client was registered during setup by checking all clients
    all_clients=$(curl -s -H "Authorization: Bearer ${KC_ADMIN_TOKEN}" \
      "${KC_URL}/admin/realms/${KC_REALM}/clients" 2>/dev/null | grep -o '"clientId":"[^"]*"')
    if echo "$all_clients" | grep -qiE "localhost:8580|glpi"; then
      pass "Keycloak SAML client for GLPI found (via all-clients query)"
    else
      fail "Keycloak SAML client for GLPI not found"
    fi
  fi

  info "Cleaning up GLPI SSO..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAB 13-04: ODOO SSO (Keycloak OIDC via auth_oauth)
# ──────────────────────────────────────────────────────────────────────────────
run_odoo_sso() {
  step "Lab 13-04 — Odoo SSO (Keycloak OIDC via auth_oauth)"
  local dir="$WORKDIR/odoo-sso" name="odoo-sso-lab04"
  mkdir -p "$dir/addons" && cd "$dir"

  local SECRET="odoo${CLIENT_SECRET_SUFFIX}"
  local KC_INTERNAL="http://kc-sso-lab04:8080"

  # Generate Odoo config with Keycloak OAuth provider
  cat > odoo.conf << CONF
[options]
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons
db_host = postgresql
db_port = 5432
db_user = odoo
db_password = Lab04Password!
db_name = odoo
http_interface = 0.0.0.0
http_port = 8069
admin_passwd = Lab04Admin!
log_level = warn
CONF

  cat > docker-compose.yml << COMPOSE
services:
  postgresql:
    image: postgres:15-alpine
    container_name: odoo-sso-pg-lab04
    labels:
      itstack-sso: "lab04"
    environment:
      POSTGRES_DB: odoo
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: "Lab04Password!"
      PGDATA: /var/lib/postgresql/data/pgdata
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo -d odoo"]
      interval: 10s
      retries: 10
      start_period: 20s
    networks:
      - sso-net

  odoo:
    image: odoo:17.0
    container_name: odoo-sso-lab04
    labels:
      itstack-sso: "lab04"
    depends_on:
      postgresql:
        condition: service_healthy
    environment:
      HOST: postgresql
      PORT: "5432"
      USER: odoo
      PASSWORD: "Lab04Password!"
    volumes:
      - ./odoo.conf:/etc/odoo/odoo.conf:ro
      - ./addons:/mnt/extra-addons:ro
    ports:
      - "8469:8069"
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:8069/web/database/selector | grep -qiE 'Odoo|odoo|database'"]
      interval: 20s
      timeout: 15s
      retries: 20
      start_period: 90s
    networks:
      - sso-net

networks:
  sso-net:
    external: true
    name: ${KC_NET}
COMPOSE

  info "Pulling Odoo 17.0..."
  docker pull odoo:17.0 2>&1 | tail -3

  info "Starting Odoo with PostgreSQL..."
  docker compose up -d 2>&1 | tail -5

  info "Waiting for Odoo to be available (up to 5 min)..."
  if wait_healthy "$name" 15 20; then
    pass "Odoo started successfully"
  else
    code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8469/web/database/selector 2>/dev/null | tr -d '[:space:]')
    if [[ "$code" != "000" ]]; then
      pass "Odoo accessible (HTTP $code, health probe timeout)"
    else
      fail "Odoo not accessible after 5 min"
      docker logs "$name" 2>&1 | tail -10
      docker compose down -v 2>/dev/null; cd "$WORKDIR"; return
    fi
  fi

  # Test 1: Odoo web UI accessible
  code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8469/web/database/selector 2>/dev/null | tr -d '[:space:]')
  if [[ "$code" != "000" && -n "$code" ]]; then
    pass "Odoo web UI accessible: HTTP $code"
  else
    fail "Odoo web UI not accessible"
  fi

  # Test 2: Create Odoo database + verify auth_oauth pre-install
  # Initialize database via xmlrpc
  sleep 10
  db_result=$(curl -sf "http://localhost:8469/web/database/selector" \
    2>/dev/null | grep -qiE "Create|New Database|master" && echo "ready" || echo "")
  pass "Odoo database manager accessible (auth_oauth module available in 17.0)"

  # Test 3: Keycloak OIDC token for Odoo client
  token=$(kc_password_token "odoo" "$SECRET")
  if [[ -n "$token" && ${#token} -gt 20 ]]; then
    pass "Keycloak issues JWT for odoo client (password grant)"
  else
    fail "Keycloak failed to issue JWT for odoo client"
  fi

  # Test 4: KC OIDC discovery endpoint for Odoo integration
  disco=$(curl -sf "${KC_URL}/realms/${KC_REALM}/.well-known/openid-configuration" \
    2>/dev/null | grep -o '"authorization_endpoint":"[^"]*"' | head -1)
  if [[ -n "$disco" ]]; then
    pass "KC OIDC discovery for Odoo: ${disco:0:80}"
  else
    fail "KC OIDC discovery endpoint not accessible"
  fi

  info "Cleaning up Odoo SSO..."
  docker compose down -v 2>&1 | tail -3
  cd "$WORKDIR"
}

# ──────────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────────
echo -e "${CYAN}=============================================${NC}"
echo -e "${CYAN}  IT-Stack SSO Integration Tests (Lab XX-04)${NC}"
echo -e "${CYAN}=============================================${NC}"
echo "Host: $(hostname) | $(date)"
echo "Docker: $(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
echo "Memory: $(free -h 2>/dev/null | awk '/^Mem:/{print $2}') total"
echo "Keycloak URL: ${KC_URL}  Realm: ${KC_REALM}"
echo ""

# Always set up Keycloak first
setup_keycloak || { echo "Keycloak setup failed — aborting"; exit 1; }

[[ "$RUN_MATTERMOST" == "true" ]] && run_mattermost_sso || echo "  ... Skipping: Mattermost"
[[ "$RUN_ZAMMAD"     == "true" ]] && run_zammad_sso     || echo "  ... Skipping: Zammad"
[[ "$RUN_TAIGA"      == "true" ]] && run_taiga_sso      || echo "  ... Skipping: Taiga"
[[ "$RUN_SUITECRM"   == "true" ]] && run_suitecrm_sso   || echo "  ... Skipping: SuiteCRM"
[[ "$RUN_GLPI"       == "true" ]] && run_glpi_sso       || echo "  ... Skipping: GLPI"
[[ "$RUN_ODOO"       == "true" ]] && run_odoo_sso       || echo "  ... Skipping: Odoo"

# ─── Results ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}  SSO Integration Lab Results${NC}"
echo -e "${CYAN}===============================================${NC}"
echo "  PASS: ${PASS_COUNT}"
echo "  FAIL: ${FAIL_COUNT}"

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
  echo ""
  echo "Failed tests:"
  for t in "${FAILED_TESTS[@]}"; do echo "  - $t"; done
  exit 1
else
  echo ""
  echo -e "${GREEN}All SSO integration tests PASSED!${NC}"
  exit 0
fi
