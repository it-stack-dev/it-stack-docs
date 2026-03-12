#!/bin/bash
# IT-Stack Demo Launcher
# Starts all browser-accessible services simultaneously on their respective ports
# All images are already cached on this VM.
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
info() { echo -e "${CYAN}[→]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }

# --- SHARED NETWORK ---
docker network create it-stack-demo 2>/dev/null || true

# =============================================================================
# 1. TRAEFIK — Proxy Dashboard  (port 8080)
# =============================================================================
info "Starting Traefik dashboard (port 8080)..."
docker rm -f traefik-demo 2>/dev/null || true
docker run -d --name traefik-demo \
  --network it-stack-demo \
  -p 8080:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  traefik:v3.1 \
  --api.insecure=true \
  --providers.docker=true \
  --entrypoints.web.address=:80
log "Traefik → http://\$VM_IP:8080"

# =============================================================================
# 2. KEYCLOAK — SSO/Identity  (port 8180, in-memory H2 for quick demo)
# =============================================================================
info "Starting Keycloak (port 8180)..."
docker rm -f keycloak-demo 2>/dev/null || true
docker run -d --name keycloak-demo \
  --network it-stack-demo \
  -p 8180:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=Lab01Password! \
  -e KC_HTTP_ENABLED=true \
  -e KC_HOSTNAME_STRICT=false \
  quay.io/keycloak/keycloak:24.0.5 start-dev
log "Keycloak → http://\$VM_IP:8180  admin / Lab01Password!"

# =============================================================================
# 3. NEXTCLOUD — File sharing  (port 8280)
# =============================================================================
info "Starting Nextcloud + PostgreSQL (port 8280)..."
docker rm -f nc-demo nc-db-demo 2>/dev/null || true
docker volume rm nc-db-demo nc-data-demo 2>/dev/null || true

docker run -d --name nc-db-demo \
  --network it-stack-demo \
  -e POSTGRES_DB=nextcloud \
  -e POSTGRES_USER=nextcloud \
  -e POSTGRES_PASSWORD=Lab02Password! \
  -v nc-db-demo:/var/lib/postgresql/data \
  postgres:16

# wait for postgres
info "  Waiting for Nextcloud DB..."
for i in {1..30}; do
  docker exec nc-db-demo pg_isready -U nextcloud -d nextcloud &>/dev/null && break
  sleep 2
done

docker run -d --name nc-demo \
  --network it-stack-demo \
  -p 8280:80 \
  -e POSTGRES_HOST=nc-db-demo \
  -e POSTGRES_DB=nextcloud \
  -e POSTGRES_USER=nextcloud \
  -e POSTGRES_PASSWORD=Lab02Password! \
  -e NEXTCLOUD_ADMIN_USER=admin \
  -e NEXTCLOUD_ADMIN_PASSWORD=Lab02Password! \
  -e NEXTCLOUD_TRUSTED_DOMAINS="localhost 4.154.17.25" \
  -v nc-data-demo:/var/www/html \
  nextcloud:28-apache
log "Nextcloud → http://\$VM_IP:8280  admin / Lab02Password!  (first load ~90s)"

# =============================================================================
# 4. MATTERMOST — Team Chat  (port 8265)
# =============================================================================
info "Starting Mattermost + PostgreSQL (port 8265)..."
docker rm -f mm-demo mm-db-demo 2>/dev/null || true
docker volume rm mm-db-demo 2>/dev/null || true

docker run -d --name mm-db-demo \
  --network it-stack-demo \
  -e POSTGRES_DB=mattermost \
  -e POSTGRES_USER=mattermost \
  -e POSTGRES_PASSWORD=Lab02Password! \
  -v mm-db-demo:/var/lib/postgresql/data \
  postgres:16

info "  Waiting for Mattermost DB..."
for i in {1..30}; do
  docker exec mm-db-demo pg_isready -U mattermost -d mattermost &>/dev/null && break
  sleep 2
done

docker run -d --name mm-demo \
  --network it-stack-demo \
  -p 8265:8065 \
  -e MM_SQLSETTINGS_DRIVERNAME=postgres \
  -e MM_SQLSETTINGS_DATASOURCE="postgres://mattermost:Lab02Password!@mm-db-demo:5432/mattermost?sslmode=disable" \
  -e MM_SERVICESETTINGS_SITEURL="http://4.154.17.25:8265" \
  mattermost/mattermost-team-edition:9.11.1
log "Mattermost → http://\$VM_IP:8265  (setup wizard: set admin@lab.localhost / Lab02Password!)"

# =============================================================================
# 5. ZABBIX — Monitoring  (port 8307)
# =============================================================================
info "Starting Zabbix (port 8307)..."
docker rm -f zabbix-demo zabbix-db-demo zabbix-server-demo 2>/dev/null || true
docker volume rm zabbix-db-demo 2>/dev/null || true

docker run -d --name zabbix-db-demo \
  --network it-stack-demo \
  -e POSTGRES_DB=zabbix \
  -e POSTGRES_USER=zabbix \
  -e POSTGRES_PASSWORD=Lab02Password! \
  -v zabbix-db-demo:/var/lib/postgresql/data \
  postgres:16

info "  Waiting for Zabbix DB..."
for i in {1..30}; do
  docker exec zabbix-db-demo pg_isready -U zabbix -d zabbix &>/dev/null && break
  sleep 2
done

docker run -d --name zabbix-server-demo \
  --network it-stack-demo \
  -e DB_SERVER_HOST=zabbix-db-demo \
  -e POSTGRES_DB=zabbix \
  -e POSTGRES_USER=zabbix \
  -e POSTGRES_PASSWORD=Lab02Password! \
  zabbix/zabbix-server-pgsql:alpine-7.0-latest

docker run -d --name zabbix-demo \
  --network it-stack-demo \
  -p 8307:8080 \
  -e ZBX_SERVER_HOST=zabbix-server-demo \
  -e DB_SERVER_HOST=zabbix-db-demo \
  -e POSTGRES_DB=zabbix \
  -e POSTGRES_USER=zabbix \
  -e POSTGRES_PASSWORD=Lab02Password! \
  zabbix/zabbix-web-nginx-pgsql:alpine-7.0-latest
log "Zabbix → http://\$VM_IP:8307  Admin / zabbix"

# =============================================================================
# 6. GLPI — ITSM / Help Desk  (port 8306)
# =============================================================================
info "Starting GLPI (port 8306)..."
docker rm -f glpi-demo glpi-db-demo 2>/dev/null || true
docker volume rm glpi-db-demo glpi-data-demo 2>/dev/null || true

docker run -d --name glpi-db-demo \
  --network it-stack-demo \
  -e MYSQL_ROOT_PASSWORD=Lab02Password! \
  -e MYSQL_DATABASE=glpi \
  -e MYSQL_USER=glpi \
  -e MYSQL_PASSWORD=Lab02Password! \
  -v glpi-db-demo:/var/lib/mysql \
  mariadb:10.11

info "  Waiting for GLPI DB..."
for i in {1..30}; do
  docker exec glpi-db-demo mysqladmin ping -u glpi -pLab02Password! &>/dev/null && break
  sleep 3
done

docker run -d --name glpi-demo \
  --network it-stack-demo \
  -p 8306:80 \
  -e GLPI_DB_HOST=glpi-db-demo \
  -e GLPI_DB_NAME=glpi \
  -e GLPI_DB_USER=glpi \
  -e GLPI_DB_PASSWORD=Lab02Password! \
  -v glpi-data-demo:/var/www/html/files \
  diouxx/glpi:latest
log "GLPI → http://\$VM_IP:8306  glpi / glpi"

# =============================================================================
# 7. TAIGA — Project Management  (ports 9000/9001)
# =============================================================================
info "Starting Taiga (port 9001)..."
docker rm -f taiga-demo taiga-db-demo taiga-redis-demo taiga-back-demo taiga-async-demo taiga-events-demo 2>/dev/null || true
docker volume rm taiga-db-demo taiga-static-demo taiga-media-demo 2>/dev/null || true

docker run -d --name taiga-db-demo \
  --network it-stack-demo \
  -e POSTGRES_DB=taiga \
  -e POSTGRES_USER=taiga \
  -e POSTGRES_PASSWORD=Lab02Password! \
  -v taiga-db-demo:/var/lib/postgresql/data \
  postgres:16

docker run -d --name taiga-redis-demo \
  --network it-stack-demo \
  redis:7-alpine

info "  Waiting for Taiga DB..."
for i in {1..30}; do
  docker exec taiga-db-demo pg_isready -U taiga -d taiga &>/dev/null && break
  sleep 2
done

docker run -d --name taiga-back-demo \
  --network it-stack-demo \
  -p 9000:8000 \
  -e TAIGA_SECRET_KEY=lab-demo-secret-key-12345 \
  -e POSTGRES_HOST=taiga-db-demo \
  -e POSTGRES_DB=taiga \
  -e POSTGRES_USER=taiga \
  -e POSTGRES_PASSWORD=Lab02Password! \
  -e TAIGA_SITES_DOMAIN=4.154.17.25:9000 \
  -e RABBITMQ_URL="" \
  -v taiga-static-demo:/taiga-back/static \
  -v taiga-media-demo:/taiga-back/media \
  ghcr.io/taigaio/taiga-back:latest || warn "Taiga back not available — skip"

docker run -d --name taiga-demo \
  --network it-stack-demo \
  -p 9001:80 \
  -e TAIGA_URL="http://4.154.17.25:9000" \
  -e TAIGA_WS_URL="ws://4.154.17.25:9001" \
  ghcr.io/taigaio/taiga-front:latest || warn "Taiga front not available — skip"
log "Taiga → http://\$VM_IP:9001  admin / 123123"

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  IT-Stack Demo — All Services Starting${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Service         URL                              Login"
echo "  ─────────────── ──────────────────────────────── ─────────────────────"
echo "  Traefik         http://4.154.17.25:8080          (no login)"
echo "  Keycloak        http://4.154.17.25:8180          admin / Lab01Password!"
echo "  Nextcloud       http://4.154.17.25:8280          admin / Lab02Password!"
echo "  Mattermost      http://4.154.17.25:8265          setup wizard first"
echo "  Zabbix          http://4.154.17.25:8307          Admin / zabbix"
echo "  GLPI            http://4.154.17.25:8306          glpi / glpi"
echo "  Taiga           http://4.154.17.25:9001          admin / 123123"
echo ""
echo "  ⚠  Nextcloud & Mattermost need ~90s to fully initialize"
echo "  ⚠  Mattermost: complete the setup wizard before logging in"
echo "  ⚠  Zabbix: images may need to pull (~1min) if not cached"
echo ""
echo "  Monitor status:  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
echo "  Stop all:        docker rm -f \$(docker ps -q)"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
