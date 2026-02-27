#!/usr/bin/env pwsh
# scaffold-module.ps1 — Scaffold a complete IT-Stack module repo
# Usage: .\scaffold-module.ps1 -Module freeipa
# All 20 modules supported.

param(
    [Parameter(Mandatory)]
    [ValidateSet("freeipa","keycloak","postgresql","redis","elasticsearch",
                 "nextcloud","mattermost","jitsi","iredmail","freepbx","zammad",
                 "suitecrm","odoo","openkm","taiga","snipeit","glpi",
                 "traefik","zabbix","graylog")]
    [string]$Module,
    [string]$ReposBase = "C:\IT-Stack\it-stack-dev\repos",
    [switch]$Push
)

# ── Module metadata ─────────────────────────────────────────────────────────
$meta = @{
    freeipa       = @{ num="01"; phase=1; cat="identity";       server="lab-id1";    ports=@("389 (LDAP)","636 (LDAPS)","88 (Kerberos)","53 (DNS)");  image="freeipa/freeipa-server:rocky-9";    short="FreeIPA LDAP/Kerberos identity provider";         full="FreeIPA provides centralized identity management using LDAP, Kerberos, DNS, and PKI for the IT-Stack platform." }
    keycloak      = @{ num="02"; phase=1; cat="identity";       server="lab-id1";    ports=@("8080 (HTTP)","8443 (HTTPS)");                            image="quay.io/keycloak/keycloak:24";      short="Keycloak OAuth2/OIDC/SAML SSO provider";          full="Keycloak is the central SSO broker for all IT-Stack services, federating users from FreeIPA via LDAP." }
    postgresql    = @{ num="03"; phase=1; cat="database";       server="lab-db1";    ports=@("5432 (PostgreSQL)");                                     image="postgres:16";                       short="PostgreSQL primary database";                     full="PostgreSQL hosts all service databases: Keycloak, Nextcloud, Mattermost, Zammad, SuiteCRM, Odoo, OpenKM, Taiga, Snipe-IT, and GLPI." }
    redis         = @{ num="04"; phase=1; cat="database";       server="lab-db1";    ports=@("6379 (Redis)");                                          image="redis:7-alpine";                    short="Redis cache and session store";                   full="Redis provides caching, session management, and queue brokering for the IT-Stack collaboration and communications services." }
    elasticsearch = @{ num="05"; phase=4; cat="database";       server="lab-db1";    ports=@("9200 (REST API)","9300 (Cluster)");                      image="docker.elastic.co/elasticsearch/elasticsearch:8.13.0"; short="Elasticsearch search and log indexing"; full="Elasticsearch provides full-text search for Nextcloud and log indexing for Graylog." }
    nextcloud     = @{ num="06"; phase=2; cat="collaboration";  server="lab-app1";   ports=@("80 (HTTP)","443 (HTTPS)");                               image="nextcloud:28-apache";               short="Nextcloud file sync, calendar, and office suite"; full="Nextcloud provides file storage, WebDAV, CalDAV, CardDAV, and collaborative office document editing for the entire organization." }
    mattermost    = @{ num="07"; phase=2; cat="collaboration";  server="lab-app1";   ports=@("8065 (HTTP)");                                           image="mattermost/mattermost-team-edition:9"; short="Mattermost team messaging";                 full="Mattermost is the team chat platform, replacing Slack/Teams with full SSO via Keycloak OIDC." }
    jitsi         = @{ num="08"; phase=2; cat="collaboration";  server="lab-app1";   ports=@("443 (HTTPS)","10000/udp (Media)");                       image="jitsi/web:stable";                  short="Jitsi video conferencing";                        full="Jitsi provides self-hosted video conferencing, replacing Zoom/Teams meetings with OIDC authentication via Keycloak." }
    iredmail      = @{ num="09"; phase=2; cat="communications"; server="lab-comm1";  ports=@("25 (SMTP)","143 (IMAP)","993 (IMAPS)","587 (Submission)"); image="iredmail/iredmail:stable";         short="iRedMail email server";                           full="iRedMail provides a complete email stack (Postfix, Dovecot, SpamAssassin, ClamAV) for the organization's email infrastructure." }
    freepbx       = @{ num="10"; phase=3; cat="communications"; server="lab-pbx1";   ports=@("5060 (SIP)","5061 (SIP TLS)","80 (Admin HTTP)","10000-20000/udp (RTP)"); image="tiredofit/freepbx:16"; short="FreePBX/Asterisk VoIP PBX";           full="FreePBX with Asterisk provides VoIP telephony, auto-attendant, voicemail, call recording, and CTI integration with SuiteCRM." }
    zammad        = @{ num="11"; phase=2; cat="communications"; server="lab-comm1";  ports=@("3000 (HTTP)");                                           image="zammad/zammad-docker-compose:latest"; short="Zammad help desk and ticketing";              full="Zammad is the customer service platform providing ticket management, live chat, and knowledge base, integrated with Keycloak OIDC." }
    suitecrm      = @{ num="12"; phase=3; cat="business";       server="lab-biz1";   ports=@("80 (HTTP)","443 (HTTPS)");                               image="bitnami/suitecrm:latest";           short="SuiteCRM customer relationship management";       full="SuiteCRM provides full CRM capabilities including sales pipeline, contact management, and reporting, integrated with FreePBX and Odoo." }
    odoo          = @{ num="13"; phase=3; cat="business";       server="lab-biz1";   ports=@("8069 (HTTP)","8072 (WebSocket)");                        image="odoo:17";                           short="Odoo ERP and business management";                full="Odoo provides ERP, accounting, HR, inventory, and purchasing modules, integrated with FreeIPA for employee directory sync." }
    openkm        = @{ num="14"; phase=3; cat="business";       server="lab-biz1";   ports=@("8080 (HTTP)");                                           image="openkm/openkm-ce:latest";           short="OpenKM document management system";               full="OpenKM is the central document repository for the organization, providing versioned document storage and workflow automation." }
    taiga         = @{ num="15"; phase=4; cat="it-management";  server="lab-mgmt1";  ports=@("80 (HTTP)","443 (HTTPS)");                               image="taigaio/taiga-front:latest";        short="Taiga agile project management";                  full="Taiga provides Scrum and Kanban project management boards, replacing Jira with full OIDC SSO via Keycloak." }
    snipeit       = @{ num="16"; phase=4; cat="it-management";  server="lab-mgmt1";  ports=@("80 (HTTP)","443 (HTTPS)");                               image="snipe/snipe-it:latest";             short="Snipe-IT IT asset management";                    full="Snipe-IT tracks all hardware assets, licenses, and accessories, integrated with GLPI CMDB and Odoo for procurement workflows." }
    glpi          = @{ num="17"; phase=4; cat="it-management";  server="lab-mgmt1";  ports=@("80 (HTTP)","443 (HTTPS)");                               image="diouxx/glpi:latest";                short="GLPI IT service management and CMDB";             full="GLPI provides IT service management (ITSM), CMDB, and software inventory, integrated with Zammad for ticket escalation." }
    traefik       = @{ num="18"; phase=1; cat="infrastructure"; server="lab-proxy1"; ports=@("80 (HTTP)","443 (HTTPS)","8080 (Dashboard)");            image="traefik:v3.0";                      short="Traefik reverse proxy and load balancer";         full="Traefik is the central reverse proxy, routing all HTTPS traffic to services via subdomain, handling TLS termination and certificate management." }
    zabbix        = @{ num="19"; phase=4; cat="infrastructure"; server="lab-comm1";  ports=@("10051 (Server)","3000 (Web UI)");                        image="zabbix/zabbix-server-pgsql:alpine-6.4-latest"; short="Zabbix infrastructure monitoring";      full="Zabbix monitors all IT-Stack servers and services, sending alerts to Mattermost and integrating with Graylog for log-based triggers." }
    graylog       = @{ num="20"; phase=4; cat="infrastructure"; server="lab-proxy1"; ports=@("9000 (Web UI)","1514 (Syslog)","12201 (GELF)");          image="graylog/graylog:5.2";               short="Graylog centralized log management";              full="Graylog aggregates logs from all IT-Stack services via syslog/GELF, providing search, alerting, and dashboards integrated with Zabbix." }
}

$m     = $meta[$Module]
$num   = $m.num
$phase = $m.phase
$cat   = $m.cat
$repo  = "it-stack-$Module"

# ── Resolve destination directory ────────────────────────────────────────────
$catDirs = @{
    "identity"      = "01-identity"
    "database"      = "02-database"
    "collaboration" = "03-collaboration"
    "communications"= "04-communications"
    "business"      = "05-business"
    "it-management" = "06-it-management"
    "infrastructure"= "07-infrastructure"
}
$destDir = "$ReposBase\$($catDirs[$cat])\$repo"

if (!(Test-Path $destDir)) {
    Write-Host "  No local clone found at $destDir" -ForegroundColor Red
    Write-Host "  Clone first: git clone https://github.com/it-stack-dev/$repo.git $destDir" -ForegroundColor Yellow
    exit 1
}

Write-Host "Scaffolding $repo (Module $num)..." -ForegroundColor Cyan
Set-Location $destDir

$ports = ($m.ports -join ", ")

# ── Helper: write file, create parent dirs ────────────────────────────────────
function Write-ModFile($relPath, $content) {
    $full = Join-Path $destDir $relPath
    $dir  = Split-Path $full
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $content | Set-Content $full -Encoding UTF8
    Write-Host "  [+] $relPath" -ForegroundColor DarkGray
}

# ── README.md ─────────────────────────────────────────────────────────────────
Write-ModFile "README.md" @"
# IT-Stack $($Module.ToUpper()) — Module $num

$($m.full)

**Category:** $cat · **Phase:** $phase · **Server:** $($m.server)  
**Ports:** $ports

---

## Quick Start — Lab 01 (Standalone)

``````bash
# Clone and run standalone lab
git clone https://github.com/it-stack-dev/$repo.git
cd $repo
make test-lab-01
``````

## Lab Progression

| Lab | Name | Duration | Purpose |
|-----|------|----------|---------|
| [01-standalone](docs/labs/01-standalone.md) | Standalone | 30–60 min | Basic functionality in isolation |
| [02-external](docs/labs/02-external.md) | External Dependencies | 45–90 min | Network integration, external services |
| [03-advanced](docs/labs/03-advanced.md) | Advanced Features | 60–120 min | Production features, performance |
| [04-sso](docs/labs/04-sso.md) | SSO Integration | 90–120 min | Keycloak OIDC/SAML authentication |
| [05-integration](docs/labs/05-integration.md) | Advanced Integration | 90–150 min | Multi-module ecosystem integration |
| [06-production](docs/labs/06-production.md) | Production Deployment | 120–180 min | HA cluster, monitoring, DR |

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Module Manifest

See [`$repo.yml`]($repo.yml) for full module metadata.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and the [organization guide](https://github.com/it-stack-dev/.github/blob/main/CONTRIBUTING.md).

## License

Apache 2.0 — see [LICENSE](LICENSE).
"@

# ── Module manifest ───────────────────────────────────────────────────────────
Write-ModFile "$repo.yml" @"
# $repo.yml — IT-Stack Module Manifest
# Module $($num): $($m.short)

module:
  name: $Module
  number: "$num"
  repo: it-stack-dev/$repo
  version: "0.1.0"
  phase: $phase
  category: $cat
  server: $($m.server)
  description: "$($m.short)"

upstream:
  name: $(switch ($Module) {
    "freeipa" { "FreeIPA" }; "keycloak" { "Keycloak" }; "postgresql" { "PostgreSQL" }
    "redis" { "Redis" }; "elasticsearch" { "Elasticsearch" }; "nextcloud" { "Nextcloud" }
    "mattermost" { "Mattermost" }; "jitsi" { "Jitsi Meet" }; "iredmail" { "iRedMail" }
    "freepbx" { "FreePBX / Asterisk" }; "zammad" { "Zammad" }; "suitecrm" { "SuiteCRM" }
    "odoo" { "Odoo" }; "openkm" { "OpenKM" }; "taiga" { "Taiga" }; "snipeit" { "Snipe-IT" }
    "glpi" { "GLPI" }; "traefik" { "Traefik" }; "zabbix" { "Zabbix" }; "graylog" { "Graylog" }
  })
  image: $($m.image)
  license: $(switch ($Module) {
    "keycloak" { "Apache-2.0" }; "postgresql" { "PostgreSQL" }; "redis" { "BSD-3-Clause" }
    "elasticsearch" { "Elastic-2.0" }; "nextcloud" { "AGPL-3.0" }; "mattermost" { "MIT" }
    "jitsi" { "Apache-2.0" }; "iredmail" { "GPL-3.0" }; "freepbx" { "GPL-2.0" }
    "zammad" { "AGPL-3.0" }; "suitecrm" { "AGPL-3.0" }; "odoo" { "LGPL-3.0" }
    "openkm" { "GPL-2.0" }; "taiga" { "AGPL-3.0" }; "snipeit" { "AGPL-3.0" }
    "glpi" { "GPL-2.0" }; "traefik" { "MIT" }; "zabbix" { "AGPL-3.0" }
    "graylog" { "SSPL-1.0" }; default { "GPL-3.0" }
  })

ports:
$(foreach ($p in $m.ports) { "  - $p`n" })
labs:
  - id: "$num-01"
    name: Standalone
    docker_compose: docker/docker-compose.standalone.yml
    test_script: tests/labs/test-lab-$num-01.sh
  - id: "$num-02"
    name: External Dependencies
    docker_compose: docker/docker-compose.lan.yml
    test_script: tests/labs/test-lab-$num-02.sh
  - id: "$num-03"
    name: Advanced Features
    docker_compose: docker/docker-compose.advanced.yml
    test_script: tests/labs/test-lab-$num-03.sh
  - id: "$num-04"
    name: SSO Integration
    docker_compose: docker/docker-compose.sso.yml
    test_script: tests/labs/test-lab-$num-04.sh
  - id: "$num-05"
    name: Advanced Integration
    docker_compose: docker/docker-compose.integration.yml
    test_script: tests/labs/test-lab-$num-05.sh
  - id: "$num-06"
    name: Production Deployment
    docker_compose: docker/docker-compose.production.yml
    test_script: tests/labs/test-lab-$num-06.sh

resources:
  cpu_cores: 2
  ram_gb: $(switch ($Module) {
    "freeipa" { 4 }; "keycloak" { 4 }; "postgresql" { 8 }; "redis" { 2 }
    "elasticsearch" { 8 }; "nextcloud" { 4 }; "mattermost" { 4 }; "jitsi" { 4 }
    "iredmail" { 4 }; "freepbx" { 4 }; "zammad" { 4 }; "suitecrm" { 4 }
    "odoo" { 8 }; "openkm" { 4 }; "taiga" { 4 }; "snipeit" { 2 }
    "glpi" { 2 }; "traefik" { 2 }; "zabbix" { 4 }; "graylog" { 8 }
  })
  disk_gb: 20

health_check:
  endpoint: /health
  metrics_endpoint: /metrics
  log_path: /var/log/$Module/
"@

# ── Makefile ──────────────────────────────────────────────────────────────────
Write-ModFile "Makefile" @"
# Makefile — IT-Stack $($Module.ToUpper()) (Module $num)
.PHONY: help build install test test-lab-01 test-lab-02 test-lab-03 \
        test-lab-04 test-lab-05 test-lab-06 deploy clean lint

COMPOSE_STANDALONE = docker/docker-compose.standalone.yml
COMPOSE_LAN        = docker/docker-compose.lan.yml
COMPOSE_ADVANCED   = docker/docker-compose.advanced.yml
COMPOSE_SSO        = docker/docker-compose.sso.yml
COMPOSE_INTEGRATION= docker/docker-compose.integration.yml
COMPOSE_PRODUCTION = docker/docker-compose.production.yml

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*`$`$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", `$`$1, `$`$2}'

build: ## Build Docker image
	docker build -t it-stack/$($Module):latest .

install: ## Start standalone (Lab 01) environment
	docker compose -f `$`$(COMPOSE_STANDALONE) up -d
	@echo "Waiting for $Module to be ready..."
	@sleep 10
	@docker compose -f `$`$(COMPOSE_STANDALONE) ps

test: test-lab-01 ## Run default test (Lab 01)

test-lab-01: ## Lab 01 — Standalone
	@bash tests/labs/test-lab-$num-01.sh

test-lab-02: ## Lab 02 — External Dependencies
	@bash tests/labs/test-lab-$num-02.sh

test-lab-03: ## Lab 03 — Advanced Features
	@bash tests/labs/test-lab-$num-03.sh

test-lab-04: ## Lab 04 — SSO Integration
	@bash tests/labs/test-lab-$num-04.sh

test-lab-05: ## Lab 05 — Advanced Integration
	@bash tests/labs/test-lab-$num-05.sh

test-lab-06: ## Lab 06 — Production Deployment
	@bash tests/labs/test-lab-$num-06.sh

deploy: ## Deploy to target server ($($m.server))
	ansible-playbook -i ansible/inventory.yml ansible/playbooks/deploy-$Module.yml

clean: ## Stop and remove all containers and volumes
	docker compose -f `$`$(COMPOSE_STANDALONE) down -v --remove-orphans
	docker compose -f `$`$(COMPOSE_LAN) down -v --remove-orphans 2>/dev/null || true
	docker compose -f `$`$(COMPOSE_ADVANCED) down -v --remove-orphans 2>/dev/null || true

lint: ## Lint docker-compose and shell scripts
	docker compose -f `$`$(COMPOSE_STANDALONE) config -q
	@for f in tests/labs/*.sh; do shellcheck `$`$f; done
"@

# ── Dockerfile ────────────────────────────────────────────────────────────────
Write-ModFile "Dockerfile" @"
# Dockerfile — IT-Stack $($Module.ToUpper()) wrapper
# Module $num | Category: $cat | Phase: $phase
# Base image: $($m.image)

FROM $($m.image)

# Labels
LABEL org.opencontainers.image.title="it-stack-$Module" \
      org.opencontainers.image.description="$($m.short)" \
      org.opencontainers.image.vendor="it-stack-dev" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/it-stack-dev/$repo"

# Copy custom configuration and scripts
COPY src/ /opt/it-stack/$Module/
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
"@

# ── Entrypoint script ─────────────────────────────────────────────────────────
Write-ModFile "docker/entrypoint.sh" @"
#!/bin/bash
# entrypoint.sh — IT-Stack $Module container entrypoint
set -euo pipefail

echo "Starting IT-Stack $($Module.ToUpper()) (Module $num)..."

# Source any environment overrides
if [ -f /opt/it-stack/$Module/config.env ]; then
    # shellcheck source=/dev/null
    source /opt/it-stack/$Module/config.env
fi

# Execute the upstream entrypoint or command
exec "`$`$@"
"@

# ── Docker Compose files (6) ──────────────────────────────────────────────────
$firstPort = ($m.ports[0] -replace "\s.*","")

Write-ModFile "docker/docker-compose.standalone.yml" @"
# Lab 01 — Standalone: Complete $($m.short -replace ' — IT-Stack.*','') in isolation
# No external dependencies required.
---
services:
  $($Module):
    image: $($m.image)
    container_name: it-stack-$Module
    restart: unless-stopped
    ports:
      - "$firstPort`:`$firstPort"
    environment:
      - IT_STACK_ENV=lab-01-standalone
    volumes:
      - ${Module}_data:/var/lib/$Module
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
    networks:
      - it-stack-net

networks:
  it-stack-net:
    driver: bridge

volumes:
  ${Module}_data:
"@

Write-ModFile "docker/docker-compose.lan.yml" @"
# Lab 02 — External Dependencies: $Module with external PostgreSQL and Redis
---
services:
  $($Module):
    image: $($m.image)
    container_name: it-stack-$Module
    restart: unless-stopped
    ports:
      - "$firstPort`:`$firstPort"
    environment:
      - IT_STACK_ENV=lab-02-lan
      - DB_HOST=${DB_HOST:-lab-db1}
      - DB_PORT=5432
      - REDIS_HOST=${REDIS_HOST:-lab-db1}
    networks:
      - it-stack-net

  # Lightweight local DB for lab (replace with lab-db1 in real env)
  postgres:
    image: postgres:16
    container_name: it-stack-$Module-db
    environment:
      POSTGRES_DB: ${Module}_db
      POSTGRES_USER: ${Module}_user
      POSTGRES_PASSWORD: ${Module}_pass
    volumes:
      - ${Module}_pg_data:/var/lib/postgresql/data
    networks:
      - it-stack-net

networks:
  it-stack-net:
    driver: bridge

volumes:
  ${Module}_pg_data:
"@

Write-ModFile "docker/docker-compose.advanced.yml" @"
# Lab 03 — Advanced Features: $Module with TLS, resource limits, logging
---
services:
  $($Module):
    image: $($m.image)
    container_name: it-stack-$Module
    restart: unless-stopped
    ports:
      - "$firstPort`:`$firstPort"
    environment:
      - IT_STACK_ENV=lab-03-advanced
      - TLS_ENABLED=true
    volumes:
      - ${Module}_data:/var/lib/$Module
      - ./certs:/etc/ssl/certs:ro
    deploy:
      resources:
        limits:
          cpus: "2.0"
          memory: $($m.ram_gb)G
    logging:
      driver: json-file
      options:
        max-size: "100m"
        max-file: "5"
    networks:
      - it-stack-net

networks:
  it-stack-net:
    driver: bridge

volumes:
  ${Module}_data:
"@

Write-ModFile "docker/docker-compose.sso.yml" @"
# Lab 04 — SSO Integration: $Module with Keycloak OIDC authentication
---
services:
  $($Module):
    image: $($m.image)
    container_name: it-stack-$Module
    restart: unless-stopped
    ports:
      - "$firstPort`:`$firstPort"
    environment:
      - IT_STACK_ENV=lab-04-sso
      - KEYCLOAK_URL=${KEYCLOAK_URL:-https://lab-id1:8443}
      - KEYCLOAK_REALM=${KEYCLOAK_REALM:-it-stack}
      - KEYCLOAK_CLIENT_ID=$Module
      - KEYCLOAK_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET:-changeme}
    networks:
      - it-stack-net

  # Local Keycloak for SSO lab (replace with lab-id1 in real env)
  keycloak:
    image: quay.io/keycloak/keycloak:24
    container_name: it-stack-$Module-keycloak
    command: start-dev
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
    ports:
      - "8080:8080"
    networks:
      - it-stack-net

networks:
  it-stack-net:
    driver: bridge
"@

Write-ModFile "docker/docker-compose.integration.yml" @"
# Lab 05 — Advanced Integration: $Module with full IT-Stack ecosystem
---
services:
  $($Module):
    image: $($m.image)
    container_name: it-stack-$Module
    restart: unless-stopped
    ports:
      - "$firstPort`:`$firstPort"
    environment:
      - IT_STACK_ENV=lab-05-integration
      - KEYCLOAK_URL=${KEYCLOAK_URL:-https://lab-id1:8443}
      - DB_HOST=${DB_HOST:-lab-db1}
      - REDIS_HOST=${REDIS_HOST:-lab-db1}
      - SMTP_HOST=${SMTP_HOST:-lab-comm1}
      - GRAYLOG_HOST=${GRAYLOG_HOST:-lab-proxy1}
    extra_hosts:
      - "lab-id1:10.0.50.11"
      - "lab-db1:10.0.50.12"
      - "lab-proxy1:10.0.50.15"
    networks:
      - it-stack-net

networks:
  it-stack-net:
    driver: bridge
"@

Write-ModFile "docker/docker-compose.production.yml" @"
# Lab 06 — Production: $Module HA-ready with monitoring and external volumes
---
services:
  $($Module):
    image: $($m.image)
    container_name: it-stack-$Module
    restart: always
    ports:
      - "$firstPort`:`$firstPort"
    environment:
      - IT_STACK_ENV=production
      - KEYCLOAK_URL=${KEYCLOAK_URL}
      - DB_HOST=${DB_HOST}
      - REDIS_HOST=${REDIS_HOST}
      - GRAYLOG_HOST=${GRAYLOG_HOST}
    volumes:
      - ${Module}_data:/var/lib/$Module
      - /etc/ssl/certs:/etc/ssl/certs:ro
    deploy:
      replicas: 1
      resources:
        limits:
          cpus: "4.0"
          memory: $($m.ram_gb)G
        reservations:
          cpus: "1.0"
          memory: 1G
      restart_policy:
        condition: any
        delay: 5s
    logging:
      driver: gelf
      options:
        gelf-address: "udp://`${GRAYLOG_HOST}:12201"
        tag: "it-stack-$Module"
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 120s
    networks:
      - it-stack-net

networks:
  it-stack-net:
    external: true
    name: it-stack-production

volumes:
  ${Module}_data:
    external: true
    name: it-stack-${Module}-data
"@

# ── Lab test scripts (6) ──────────────────────────────────────────────────────
$labDefs = @(
    @{ id="01"; name="Standalone";            compose="standalone";   desc="Basic $Module functionality in complete isolation" }
    @{ id="02"; name="External Dependencies"; compose="lan";          desc="$Module with external PostgreSQL, Redis, and network integration" }
    @{ id="03"; name="Advanced Features";     compose="advanced";     desc="$Module with TLS, resource limits, and production-grade configuration" }
    @{ id="04"; name="SSO Integration";       compose="sso";          desc="$Module with Keycloak OIDC/SAML authentication" }
    @{ id="05"; name="Advanced Integration";  compose="integration";  desc="$Module integrated with full IT-Stack ecosystem" }
    @{ id="06"; name="Production Deployment"; compose="production";   desc="$Module in production-grade HA configuration with monitoring" }
)

foreach ($lab in $labDefs) {
    $labId = "$num-$($lab.id)"
    Write-ModFile "tests/labs/test-lab-$labId.sh" @"
#!/usr/bin/env bash
# test-lab-$labId.sh — Lab $labId: $($lab.name)
# Module $($num): $($m.short)
# $($lab.desc)
set -euo pipefail

LAB_ID="$labId"
LAB_NAME="$($lab.name)"
MODULE="$Module"
COMPOSE_FILE="docker/docker-compose.$($lab.compose).yml"
PASS=0
FAIL=0

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

pass() { echo -e "`${GREEN}[PASS]`${NC} `$1"; ((PASS++)); }
fail() { echo -e "`${RED}[FAIL]`${NC} `$1"; ((FAIL++)); }
info() { echo -e "`${CYAN}[INFO]`${NC} `$1"; }
warn() { echo -e "`${YELLOW}[WARN]`${NC} `$1"; }

echo -e "`${CYAN}======================================`${NC}"
echo -e "`${CYAN} Lab `${LAB_ID}: `${LAB_NAME}`${NC}"
echo -e "`${CYAN} Module: `${MODULE}`${NC}"
echo -e "`${CYAN}======================================`${NC}"
echo ""

# ── PHASE 1: Setup ────────────────────────────────────────────────────────────
info "Phase 1: Setup"
docker compose -f "`${COMPOSE_FILE}" up -d
info "Waiting 30s for `${MODULE} to initialize..."
sleep 30

# ── PHASE 2: Health Checks ────────────────────────────────────────────────────
info "Phase 2: Health Checks"

if docker compose -f "`${COMPOSE_FILE}" ps | grep -q "running\|Up"; then
    pass "Container is running"
else
    fail "Container is not running"
fi

# ── PHASE 3: Functional Tests ─────────────────────────────────────────────────
info "Phase 3: Functional Tests (Lab $($lab.id) — $($lab.name))"

# TODO: Add module-specific functional tests here
# Example:
# if curl -sf http://localhost:$firstPort/health > /dev/null 2>&1; then
#     pass "Health endpoint responds"
# else
#     fail "Health endpoint not reachable"
# fi

warn "Functional tests for Lab $labId pending implementation"

# ── PHASE 4: Cleanup ──────────────────────────────────────────────────────────
info "Phase 4: Cleanup"
docker compose -f "`${COMPOSE_FILE}" down -v --remove-orphans
info "Cleanup complete"

# ── Results ───────────────────────────────────────────────────────────────────
echo ""
echo -e "`${CYAN}======================================`${NC}"
echo -e " Lab `${LAB_ID} Complete"
echo -e " `${GREEN}PASS: `${PASS}`${NC} | `${RED}FAIL: `${FAIL}`${NC}"
echo -e "`${CYAN}======================================`${NC}"

if [ "`${FAIL}" -gt 0 ]; then
    exit 1
fi
"@
}

# ── Documentation ─────────────────────────────────────────────────────────────
Write-ModFile "docs/ARCHITECTURE.md" @"
# Architecture — IT-Stack $($Module.ToUpper())

## Overview

$($m.full)

## Role in IT-Stack

- **Category:** $cat
- **Phase:** $phase
- **Server:** $($m.server) (`10.0.50.$(switch($Module){"freeipa"{"11"};"keycloak"{"11"};"postgresql"{"12"};"redis"{"12"};"elasticsearch"{"12"};"nextcloud"{"13"};"mattermost"{"13"};"jitsi"{"13"};"iredmail"{"14"};"zammad"{"14"};"freepbx"{"16"};"suitecrm"{"17"};"odoo"{"17"};"openkm"{"17"};"taiga"{"18"};"snipeit"{"18"};"glpi"{"18"};"traefik"{"15"};"zabbix"{"14"};"graylog"{"15"}})`)
- **Ports:** $ports

## Dependencies

| Dependency | Type | Required For |
|-----------|------|--------------|
| FreeIPA | Identity | User directory |
| Keycloak | SSO | Authentication |
| PostgreSQL | Database | Data persistence |
| Redis | Cache | Sessions/queues |
| Traefik | Proxy | HTTPS routing |

## Data Flow

``````
User → Traefik (HTTPS) → $Module → PostgreSQL (data)
                       ↗ Keycloak (auth)
                       ↗ Redis (sessions)
``````

## Security

- All traffic over TLS via Traefik
- Authentication delegated to Keycloak OIDC
- Database credentials via Ansible Vault
- Logs shipped to Graylog
"@

Write-ModFile "docs/DEPLOYMENT.md" @"
# Deployment Guide — IT-Stack $($Module.ToUpper())

## Prerequisites

- Ubuntu 24.04 Server on $($m.server) (10.0.50.*)
- Docker 24+ and Docker Compose v2
- Phase 1 complete: FreeIPA, Keycloak, PostgreSQL, Redis, Traefik running
- DNS entry: $Module.it-stack.lab → $($m.server)

## Deployment Steps

### 1. Create Database (PostgreSQL on lab-db1)

``````sql
CREATE USER ${Module}_user WITH PASSWORD 'CHANGE_ME';
CREATE DATABASE ${Module}_db OWNER ${Module}_user;
``````

### 2. Configure Keycloak Client

Create OIDC client `$Module` in realm `it-stack`:
- Client ID: `$Module`
- Valid redirect URI: `https://$Module.it-stack.lab/*`
- Web origins: `https://$Module.it-stack.lab`

### 3. Configure Traefik

Add to Traefik dynamic config:
``````yaml
http:
  routers:
    $($Module):
      rule: Host(\`$Module.it-stack.lab\`)
      service: $Module
      tls: {}
  services:
    $($Module):
      loadBalancer:
        servers:
          - url: http://$($m.server):$firstPort
``````

### 4. Deploy

``````bash
# Copy production compose to server
scp docker/docker-compose.production.yml admin@$($m.server):~/

# Deploy
ssh admin@$($m.server) 'docker compose -f docker-compose.production.yml up -d'
``````

### 5. Verify

``````bash
curl -I https://$Module.it-stack.lab/health
``````

## Environment Variables

| Variable | Description | Default |
|---------|-------------|---------|
| `DB_HOST` | PostgreSQL host | `lab-db1` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `REDIS_HOST` | Redis host | `lab-db1` |
| `KEYCLOAK_URL` | Keycloak base URL | `https://lab-id1:8443` |
| `KEYCLOAK_REALM` | Keycloak realm | `it-stack` |
"@

Write-ModFile "docs/TROUBLESHOOTING.md" @"
# Troubleshooting — IT-Stack $($Module.ToUpper())

## Quick Diagnostics

``````bash
# Container status
docker compose ps

# View logs (last 50 lines)
docker compose logs --tail=50 $Module

# Follow logs
docker compose logs -f $Module

# Exec into container
docker compose exec $Module bash
``````

## Common Issues

### Container fails to start

1. Check logs: `docker compose logs $Module`
2. Verify environment variables are set correctly
3. Check database connectivity: `pg_isready -h lab-db1 -p 5432`
4. Verify port is not already in use: `ss -tlnp | grep $firstPort`

### Authentication fails (SSO)

1. Verify Keycloak client is configured: `https://lab-id1:8443/admin/`
2. Check client secret matches environment variable
3. Verify redirect URIs match exactly
4. Check Keycloak realm is `it-stack`

### Database connection error

``````bash
# Test connectivity
psql -h lab-db1 -U ${Module}_user -d ${Module}_db -c '\conninfo'

# Check pg_hba.conf allows connection from $($m.server)
``````

### Performance issues

1. Check resource usage: `docker stats it-stack-$Module`
2. Verify Redis is reachable: `redis-cli -h lab-db1 ping`
3. Check Elasticsearch if used: `curl http://lab-db1:9200/_cluster/health`

## Log Locations

| Log | Path |
|-----|------|
| Application | `docker compose logs $Module` |
| Nginx/proxy | `/var/log/nginx/` |
| System | `journalctl -u docker` |
| Graylog | `https://logs.it-stack.lab` (after Lab 05) |
"@

$labDocDefs = @(
    @{ id="01"; name="Standalone";            compose="standalone";  focus="Run $Module in complete isolation. No external dependencies." }
    @{ id="02"; name="External Dependencies"; compose="lan";         focus="Connect $Module to external PostgreSQL and Redis on separate containers." }
    @{ id="03"; name="Advanced Features";     compose="advanced";    focus="Configure TLS, resource limits, persistent volumes, and production logging." }
    @{ id="04"; name="SSO Integration";       compose="sso";         focus="Integrate $Module with Keycloak OIDC for single sign-on." }
    @{ id="05"; name="Advanced Integration";  compose="integration"; focus="Connect $Module to the full IT-Stack ecosystem (FreeIPA, Traefik, Graylog, Zabbix)." }
    @{ id="06"; name="Production Deployment"; compose="production";  focus="Deploy $Module in production with HA, monitoring, backup, and DR." }
)

foreach ($ld in $labDocDefs) {
    $labId = "$num-$($ld.id)"
    Write-ModFile "docs/labs/$($ld.id)-$($ld.name.ToLower() -replace ' ','-').md" @"
# Lab $labId — $($ld.name)

**Module:** $num — $($m.short)  
**Duration:** See [lab manual](https://github.com/it-stack-dev/it-stack-docs)  
**Test Script:** `tests/labs/test-lab-$labId.sh`  
**Compose File:** `docker/docker-compose.$($ld.compose).yml`

## Objective

$($ld.focus)

## Prerequisites

$(if ($ld.id -eq "01") { "- Docker and Docker Compose installed`n- No other prerequisites" } elseif ($ld.id -eq "02") { "- Lab $num-01 passes`n- External PostgreSQL and Redis accessible" } else { "- Labs $num-01 through $num-0$(([int]$ld.id) - 1) pass`n- Prerequisite services running" })

## Steps

### 1. Prepare Environment

``````bash
cd it-stack-$Module
cp .env.example .env  # edit as needed
``````

### 2. Start Services

``````bash
make test-lab-$($ld.id)
``````

Or manually:

``````bash
docker compose -f docker/docker-compose.$($ld.compose).yml up -d
``````

### 3. Verify

``````bash
docker compose ps
curl -sf http://localhost:$firstPort/health
``````

### 4. Run Test Suite

``````bash
bash tests/labs/test-lab-$labId.sh
``````

## Expected Results

All tests pass with `FAIL: 0`.

## Cleanup

``````bash
docker compose -f docker/docker-compose.$($ld.compose).yml down -v
``````

## Troubleshooting

See [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) for common issues.
"@
}

# ── GitHub Actions workflows ───────────────────────────────────────────────────
Write-ModFile ".github/workflows/ci.yml" @"
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate docker-compose files
        run: |
          for f in docker/docker-compose.*.yml; do
            echo "Validating \$f..."
            docker compose -f "\$f" config -q
          done
      - name: Lint shell scripts
        run: |
          sudo apt-get install -y shellcheck
          shellcheck tests/labs/*.sh docker/entrypoint.sh

  test-lab-01:
    name: Lab 01 — Standalone
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Run Lab 01
        run: bash tests/labs/test-lab-$num-01.sh

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v4
      - name: Run Trivy on Dockerfile
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: config
          scan-ref: .
"@

Write-ModFile ".github/workflows/release.yml" @"
name: Release

on:
  push:
    tags: ['v*.*.*']

jobs:
  build-and-push:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: `${{ github.actor }}
          password: `${{ secrets.GITHUB_TOKEN }}
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/it-stack-dev/$repo
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: `${{ steps.meta.outputs.tags }}
          labels: `${{ steps.meta.outputs.labels }}
"@

# ── Standard repo files ───────────────────────────────────────────────────────
Write-ModFile "CHANGELOG.md" @"
# Changelog — IT-Stack $($Module.ToUpper())

All notable changes to this module are documented here.  
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)  
Versioning: [SemVer](https://semver.org/spec/v2.0.0.html)

## [Unreleased]

### Added
- Initial module scaffold with 6-lab structure
- Docker Compose files for all 6 lab environments
- Lab test scripts ($num-01 through $num-06)
- Architecture, deployment, and troubleshooting documentation
- GitHub Actions CI/CD workflows
- Module manifest: $repo.yml

## [0.1.0] — $(Get-Date -Format 'yyyy-MM-dd')

- Initial repository scaffold
"@

Write-ModFile "CONTRIBUTING.md" @"
# Contributing to IT-Stack $($Module.ToUpper())

Thank you for contributing to this module!

Please read the organization-level contribution guidelines first:  
https://github.com/it-stack-dev/.github/blob/main/CONTRIBUTING.md

## Module-Specific Notes

- This is **Module $num** in the IT-Stack platform
- All changes must preserve the 6-lab testing progression
- Lab $num-01 (Standalone) must always work without external dependencies
- Test with `make test-lab-01` before submitting a PR

## Development Setup

``````bash
git clone https://github.com/it-stack-dev/$repo.git
cd $repo
make install
make test
``````

## Submitting Changes

1. Branch from `develop`: `git checkout -b feature/your-feature develop`
2. Make your changes
3. Run `make test-lab-01` to verify standalone still works
4. Open a PR targeting `develop`
"@

Write-ModFile "SECURITY.md" @"
# Security Policy — IT-Stack $($Module.ToUpper())

## Reporting Vulnerabilities

Please report security vulnerabilities to: **security@it-stack.lab**  
Do NOT open public GitHub issues for security vulnerabilities.

Response SLA: 72 hours for acknowledgment.  
See the organization security policy:  
https://github.com/it-stack-dev/.github/blob/main/SECURITY.md

## Module Security Notes

- All credentials stored via Ansible Vault
- TLS required in production (Lab 06)
- Authentication via Keycloak OIDC (Lab 04+)
- Logs shipped to Graylog for audit trail
"@

Write-ModFile "CODE_OF_CONDUCT.md" @"
# Code of Conduct

This project follows the Contributor Covenant Code of Conduct.  
See the organization-level policy:  
https://github.com/it-stack-dev/.github/blob/main/CODE_OF_CONDUCT.md

## Enforcement

Violations may be reported to: **conduct@it-stack.lab**
"@

Write-ModFile "SUPPORT.md" @"
# Support — IT-Stack $($Module.ToUpper())

## Getting Help

1. **Check documentation** — [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. **Search issues** — https://github.com/it-stack-dev/$repo/issues
3. **Open an issue** — Include logs, environment, and steps to reproduce

## Common First Steps

``````bash
# Container status
docker compose ps

# Logs
docker compose logs --tail=50 $Module

# Health check
curl -I http://localhost:$firstPort/health
``````

## No SLA

This is an open-source project maintained on a best-effort basis.  
No service level agreements are provided.
"@

Write-ModFile "LICENSE" @"
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

Copyright 2026 it-stack-dev contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"@

Write-ModFile ".gitignore" @"
# Secrets
.env
.env.*
!.env.example
configs/secrets/
*.key
*.pem
*.crt

# Docker volumes
data/
volumes/

# Terraform
.terraform/
*.tfstate

# Ansible
*.retry
"@

Write-ModFile ".env.example" @"
# $repo — Example environment variables
# Copy to .env and fill in values

# Database
DB_HOST=lab-db1
DB_PORT=5432
DB_NAME=${Module}_db
DB_USER=${Module}_user
DB_PASSWORD=CHANGE_ME

# Redis
REDIS_HOST=lab-db1
REDIS_PORT=6379

# Keycloak SSO
KEYCLOAK_URL=https://lab-id1:8443
KEYCLOAK_REALM=it-stack
KEYCLOAK_CLIENT_ID=$Module
KEYCLOAK_CLIENT_SECRET=CHANGE_ME

# Logging
GRAYLOG_HOST=lab-proxy1
GRAYLOG_PORT=12201
"@

# ── Placeholder src/ ──────────────────────────────────────────────────────────
Write-ModFile "src/.gitkeep" ""
Write-ModFile "tests/unit/.gitkeep" ""
Write-ModFile "tests/integration/.gitkeep" ""
Write-ModFile "tests/e2e/.gitkeep" ""
Write-ModFile "kubernetes/base/.gitkeep" ""
Write-ModFile "kubernetes/overlays/dev/.gitkeep" ""
Write-ModFile "kubernetes/overlays/staging/.gitkeep" ""
Write-ModFile "kubernetes/overlays/production/.gitkeep" ""
Write-ModFile "helm/templates/.gitkeep" ""
Write-ModFile "ansible/roles/.gitkeep" ""
Write-ModFile "ansible/playbooks/.gitkeep" ""

# ── Git commit ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Committing scaffold..." -ForegroundColor Cyan

git add .
git commit -m "feat: initial scaffold for $repo (Module $num)`n`nAdds complete 6-lab structure:`n- 6 Docker Compose environments (standalone -> production)`n- 6 lab test scripts ($num-01 through $num-06)`n- Architecture, Deployment, Troubleshooting docs`n- 6 lab guide docs`n- Module manifest: $repo.yml`n- Makefile, Dockerfile, GitHub Actions CI/Release"

if ($Push) {
    Write-Host "Pushing to GitHub..." -ForegroundColor Cyan
    git push -u origin main
    Write-Host "Pushed!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Scaffold complete: $repo" -ForegroundColor Green
Write-Host "Files created in: $destDir" -ForegroundColor DarkGray
