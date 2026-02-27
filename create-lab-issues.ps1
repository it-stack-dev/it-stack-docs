#!/usr/bin/env pwsh
# create-lab-issues.ps1 — Create all 120 lab issues (6 per module × 20 modules)

$org = "it-stack-dev"
$token   = gh auth token
$headers = @{ Authorization = "Bearer $token"; Accept = "application/vnd.github.v3+json"; "Content-Type" = "application/json" }

# ── Module definitions ────────────────────────────────────────────────────────
$modules = @(
    @{ num="01"; mod="freeipa";       repo="it-stack-freeipa";       phase=1; cat="identity";       phaseName="Phase 1: Foundation";    milestonePrimary=1 }
    @{ num="02"; mod="keycloak";      repo="it-stack-keycloak";      phase=1; cat="identity";       phaseName="Phase 1: Foundation";    milestonePrimary=1 }
    @{ num="03"; mod="postgresql";    repo="it-stack-postgresql";    phase=1; cat="database";       phaseName="Phase 1: Foundation";    milestonePrimary=1 }
    @{ num="04"; mod="redis";         repo="it-stack-redis";         phase=1; cat="database";       phaseName="Phase 1: Foundation";    milestonePrimary=1 }
    @{ num="05"; mod="elasticsearch"; repo="it-stack-elasticsearch"; phase=4; cat="database";       phaseName="Phase 4: IT Management"; milestonePrimary=4 }
    @{ num="06"; mod="nextcloud";     repo="it-stack-nextcloud";     phase=2; cat="collaboration";  phaseName="Phase 2: Collaboration"; milestonePrimary=2 }
    @{ num="07"; mod="mattermost";    repo="it-stack-mattermost";    phase=2; cat="collaboration";  phaseName="Phase 2: Collaboration"; milestonePrimary=2 }
    @{ num="08"; mod="jitsi";         repo="it-stack-jitsi";         phase=2; cat="collaboration";  phaseName="Phase 2: Collaboration"; milestonePrimary=2 }
    @{ num="09"; mod="iredmail";      repo="it-stack-iredmail";      phase=2; cat="communications"; phaseName="Phase 2: Collaboration"; milestonePrimary=2 }
    @{ num="10"; mod="freepbx";       repo="it-stack-freepbx";       phase=3; cat="communications"; phaseName="Phase 3: Back Office";   milestonePrimary=3 }
    @{ num="11"; mod="zammad";        repo="it-stack-zammad";        phase=2; cat="communications"; phaseName="Phase 2: Collaboration"; milestonePrimary=2 }
    @{ num="12"; mod="suitecrm";      repo="it-stack-suitecrm";      phase=3; cat="business";       phaseName="Phase 3: Back Office";   milestonePrimary=3 }
    @{ num="13"; mod="odoo";          repo="it-stack-odoo";          phase=3; cat="business";       phaseName="Phase 3: Back Office";   milestonePrimary=3 }
    @{ num="14"; mod="openkm";        repo="it-stack-openkm";        phase=3; cat="business";       phaseName="Phase 3: Back Office";   milestonePrimary=3 }
    @{ num="15"; mod="taiga";         repo="it-stack-taiga";         phase=4; cat="it-management";  phaseName="Phase 4: IT Management"; milestonePrimary=4 }
    @{ num="16"; mod="snipeit";       repo="it-stack-snipeit";       phase=4; cat="it-management";  phaseName="Phase 4: IT Management"; milestonePrimary=4 }
    @{ num="17"; mod="glpi";          repo="it-stack-glpi";          phase=4; cat="it-management";  phaseName="Phase 4: IT Management"; milestonePrimary=4 }
    @{ num="18"; mod="traefik";       repo="it-stack-traefik";       phase=1; cat="infrastructure"; phaseName="Phase 1: Foundation";    milestonePrimary=1 }
    @{ num="19"; mod="zabbix";        repo="it-stack-zabbix";        phase=4; cat="infrastructure"; phaseName="Phase 4: IT Management"; milestonePrimary=4 }
    @{ num="20"; mod="graylog";       repo="it-stack-graylog";       phase=4; cat="infrastructure"; phaseName="Phase 4: IT Management"; milestonePrimary=4 }
)

# ── Lab definitions ───────────────────────────────────────────────────────────
$labs = @(
    @{
        labNum = "01"; name = "Standalone"
        duration = "30-60 min"; machines = "1"
        priority = "priority-high"
        titleTpl = "Lab {0}-01: Standalone — {1}"
        bodyTpl = @"
## Lab {0}-01: Standalone

**Module:** {1} (`{2}`)
**Duration:** 30–60 minutes
**Machines:** 1 (standalone Docker host)
**Difficulty:** Beginner

## Objective

Verify that {1} starts, passes health checks, and performs basic functionality in complete isolation — no external dependencies required.

## Prerequisites

- Docker and Docker Compose installed
- 4 GB RAM minimum available
- Ports available: see module manifest

## Environment

Uses `docker/docker-compose.standalone.yml` — fully self-contained, all dependencies included.

## Test Script

`tests/labs/test-lab-01.sh`

## Success Criteria

- [ ] Service starts without errors
- [ ] Health check endpoint returns 200
- [ ] Basic functionality verified (login, create, read)
- [ ] Service stops and cleans up cleanly

## Steps

1. `make test-lab-01` or run `tests/labs/test-lab-01.sh` directly
2. Verify all assertions pass
3. Review logs for warnings

## Notes

This lab must pass before proceeding to Lab {0}-02.
"@
    }
    @{
        labNum = "02"; name = "External Dependencies"
        duration = "45-90 min"; machines = "2-3"
        priority = "priority-high"
        titleTpl = "Lab {0}-02: External Dependencies — {1}"
        bodyTpl = @"
## Lab {0}-02: External Dependencies

**Module:** {1} (`{2}`)
**Duration:** 45–90 minutes
**Machines:** 2–3
**Difficulty:** Intermediate

## Objective

Integrate {1} with external services: PostgreSQL (`lab-db1`), Redis, and network-level connectivity.

## Prerequisites

- Lab {0}-01 passing
- PostgreSQL accessible at `lab-db1:5432`
- Redis accessible at `lab-db1:6379`
- Network connectivity between nodes

## Environment

Uses `docker/docker-compose.lan.yml` — connects to external database and cache services.

## Test Script

`tests/labs/test-lab-02.sh`

## Success Criteria

- [ ] Database connection established and schema created
- [ ] Redis cache connection working
- [ ] Service performs correctly with external data store
- [ ] Data persists across restarts

## Steps

1. Ensure `lab-db1` PostgreSQL and Redis are running
2. `make test-lab-02` or run `tests/labs/test-lab-02.sh`
3. Verify database tables created
4. Test restart persistence

## Notes

Requires Phase 1 Foundation (PostgreSQL, Redis) to be running.
"@
    }
    @{
        labNum = "03"; name = "Advanced Features"
        duration = "60-120 min"; machines = "2-3"
        priority = "priority-med"
        titleTpl = "Lab {0}-03: Advanced Features — {1}"
        bodyTpl = @"
## Lab {0}-03: Advanced Features

**Module:** {1} (`{2}`)
**Duration:** 60–120 minutes
**Machines:** 2–3
**Difficulty:** Intermediate–Advanced

## Objective

Configure and verify production-grade features: TLS, performance tuning, backup/restore, and advanced configuration options.

## Prerequisites

- Labs {0}-01 and {0}-02 passing
- Traefik reverse proxy running (`lab-proxy1`)
- SSL certificates available

## Environment

Uses `docker/docker-compose.advanced.yml` — production-feature configuration with TLS and tuning.

## Test Script

`tests/labs/test-lab-03.sh`

## Success Criteria

- [ ] HTTPS working via Traefik with valid certificate
- [ ] Performance benchmarks within acceptable range
- [ ] Backup and restore cycle completes successfully
- [ ] Advanced configuration options verified

## Steps

1. Configure Traefik routing for `{1}` subdomain
2. `make test-lab-03` or run `tests/labs/test-lab-03.sh`
3. Run backup test
4. Verify TLS certificate

## Notes

TLS configuration requires Traefik (Module 18) to be running.
"@
    }
    @{
        labNum = "04"; name = "SSO Integration"
        duration = "90-120 min"; machines = "3-4"
        priority = "priority-med"
        titleTpl = "Lab {0}-04: SSO Integration — {1}"
        bodyTpl = @"
## Lab {0}-04: SSO Integration

**Module:** {1} (`{2}`)
**Duration:** 90–120 minutes
**Machines:** 3–4
**Difficulty:** Advanced

## Objective

Integrate {1} with Keycloak for SSO authentication using OIDC or SAML. Users authenticate via Keycloak, which federates to FreeIPA LDAP.

## Prerequisites

- Labs {0}-01 through {0}-03 passing
- FreeIPA running (`lab-id1`) with users populated
- Keycloak running (`lab-id1:8443`) with `it-stack` realm
- DNS resolving `lab-id1.it-stack.lab`

## Environment

Uses `docker/docker-compose.sso.yml` — Keycloak OIDC/SAML integration enabled.

## Test Script

`tests/labs/test-lab-04.sh`

## Keycloak Client Setup

1. Create client `{2}` in Keycloak `it-stack` realm
2. Set redirect URIs to `https://{1}.it-stack.lab/*`
3. Configure {1} with client ID and secret

## Success Criteria

- [ ] Keycloak client created and configured
- [ ] Login redirects to Keycloak
- [ ] FreeIPA users can authenticate via SSO
- [ ] User attributes/groups mapped correctly
- [ ] Logout works (single sign-out)

## Steps

1. Run Keycloak client setup: `scripts/setup-keycloak-client.sh`
2. Configure {1} SSO settings
3. `make test-lab-04` or run `tests/labs/test-lab-04.sh`
4. Test login with FreeIPA user

## Notes

Identity chain: User → Keycloak → FreeIPA LDAP → Kerberos
"@
    }
    @{
        labNum = "05"; name = "Advanced Integration"
        duration = "90-150 min"; machines = "4-5"
        priority = "priority-med"
        titleTpl = "Lab {0}-05: Advanced Integration — {1}"
        bodyTpl = @"
## Lab {0}-05: Advanced Integration

**Module:** {1} (`{2}`)
**Duration:** 90–150 minutes
**Machines:** 4–5
**Difficulty:** Advanced

## Objective

Deep integration with the broader IT-Stack ecosystem — API connections, webhooks, data sync, and cross-service workflows.

## Prerequisites

- Labs {0}-01 through {0}-04 passing
- Multiple IT-Stack services running (see specific integrations below)
- All Phase 1 Foundation services running

## Environment

Uses `docker/docker-compose.integration.yml` — full ecosystem integration.

## Test Script

`tests/labs/test-lab-05.sh`

## Integration Points

See `docs/ARCHITECTURE.md` for the specific cross-service integrations for this module.

## Success Criteria

- [ ] API integrations with dependent services functional
- [ ] Webhooks/notifications firing correctly
- [ ] Data sync working bidirectionally
- [ ] End-to-end workflow scenarios pass

## Steps

1. Ensure all prerequisite services are running
2. Configure integration credentials in `configs/modules/{2}.yaml`
3. `make test-lab-05` or run `tests/labs/test-lab-05.sh`
4. Validate each integration point

## Notes

Refer to `docs/integration-guide-complete.md` in `it-stack-docs` for detailed integration procedures.
"@
    }
    @{
        labNum = "06"; name = "Production Deployment"
        duration = "120-180 min"; machines = "5+"
        priority = "priority-low"
        titleTpl = "Lab {0}-06: Production Deployment — {1}"
        bodyTpl = @"
## Lab {0}-06: Production Deployment

**Module:** {1} (`{2}`)
**Duration:** 120–180 minutes
**Machines:** 5+ (full 8-server layout)
**Difficulty:** Expert

## Objective

Deploy {1} in a production-ready configuration: high availability, monitoring, disaster recovery, and load testing.

## Prerequisites

- Labs {0}-01 through {0}-05 passing
- Full 8-server IT-Stack layout available
- Zabbix monitoring running (`lab-comm1`)
- Graylog log management running (`lab-proxy1`)

## Environment

Uses `docker/docker-compose.production.yml` — HA-ready with health checks, resource limits, and external volumes.

## Test Script

`tests/labs/test-lab-06.sh`

## Production Checklist

- [ ] Deployed to correct production server (`{3}`)
- [ ] Resource limits configured (CPU, memory)
- [ ] Persistent volumes on dedicated storage
- [ ] Health check passing
- [ ] Zabbix monitoring agent configured
- [ ] Logs shipping to Graylog
- [ ] Backup job scheduled and tested
- [ ] Failover/recovery procedure documented
- [ ] Load test completed (target: 100 concurrent users)

## Steps

1. Review `docs/DEPLOYMENT.md` for production prerequisites
2. Deploy using `make deploy-production`
3. `make test-lab-06` or run `tests/labs/test-lab-06.sh`
4. Run load test
5. Validate Zabbix alerts and Graylog logs

## Notes

This lab represents production readiness. All previous labs must pass before this is attempted.
"@
    }
)

# ── Get milestone numbers per repo ────────────────────────────────────────────
function Get-MilestoneNumber {
    param($repoName, $phaseName)
    $ms = Invoke-RestMethod "https://api.github.com/repos/$org/$repoName/milestones?state=all&per_page=10" -Headers $headers
    $match = $ms | Where-Object { $_.title -eq $phaseName }
    if ($match) { return $match.number } else { return $null }
}

# ── Module display names ───────────────────────────────────────────────────────
$displayNames = @{
    "freeipa"="FreeIPA"; "keycloak"="Keycloak"; "postgresql"="PostgreSQL"; "redis"="Redis"
    "elasticsearch"="Elasticsearch"; "nextcloud"="Nextcloud"; "mattermost"="Mattermost"
    "jitsi"="Jitsi"; "iredmail"="iRedMail"; "freepbx"="FreePBX"; "zammad"="Zammad"
    "suitecrm"="SuiteCRM"; "odoo"="Odoo"; "openkm"="OpenKM"; "taiga"="Taiga"
    "snipeit"="Snipe-IT"; "glpi"="GLPI"; "traefik"="Traefik"; "zabbix"="Zabbix"; "graylog"="Graylog"
}
$productionServers = @{
    "freeipa"="lab-id1"; "keycloak"="lab-id1"; "postgresql"="lab-db1"; "redis"="lab-db1"
    "elasticsearch"="lab-db1"; "nextcloud"="lab-app1"; "mattermost"="lab-app1"; "jitsi"="lab-app1"
    "iredmail"="lab-comm1"; "freepbx"="lab-pbx1"; "zammad"="lab-comm1"
    "suitecrm"="lab-biz1"; "odoo"="lab-biz1"; "openkm"="lab-biz1"
    "taiga"="lab-mgmt1"; "snipeit"="lab-mgmt1"; "glpi"="lab-mgmt1"
    "traefik"="lab-proxy1"; "zabbix"="lab-comm1"; "graylog"="lab-proxy1"
}

# ── Create issues ──────────────────────────────────────────────────────────────
$totalOk = 0; $totalFail = 0

foreach ($m in $modules) {
    $displayName = $displayNames[$m.mod]
    $server      = $productionServers[$m.mod]
    $msNum       = Get-MilestoneNumber -repoName $m.repo -phaseName $m.phaseName

    Write-Host ""
    Write-Host "==> $($m.repo) (milestone #$msNum)" -ForegroundColor Cyan

    foreach ($lab in $labs) {
        $title = $lab.titleTpl -f $m.num, $displayName
        $body  = $lab.bodyTpl  -f $m.num, $displayName, $m.repo, $server

        $issueLabels = @("lab", "module-$($m.num)", "phase-$($m.phase)", $m.cat, $lab.priority, "status-todo")

        $payload = @{
            title     = $title
            body      = $body
            labels    = $issueLabels
        }
        if ($msNum) { $payload.milestone = $msNum }

        $json = $payload | ConvertTo-Json -Depth 5
        try {
            $r = Invoke-RestMethod "https://api.github.com/repos/$org/$($m.repo)/issues" `
                -Method POST -Headers $headers -Body $json -ErrorAction Stop
            Write-Host "  #$($r.number) $title" -ForegroundColor Green
            $totalOk++
        } catch {
            Write-Host "  [FAIL] $title - $_" -ForegroundColor Red
            $totalFail++
        }
    }
}

Write-Host ""
Write-Host "Issues created: OK=$totalOk  FAIL=$totalFail" -ForegroundColor Yellow
