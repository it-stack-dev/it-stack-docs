#!/usr/bin/env pwsh
# apply-milestones-components.ps1 — Apply 4 phase milestones to all 20 component repos

$org = "it-stack-dev"

$repos = @(
    "it-stack-freeipa","it-stack-keycloak",
    "it-stack-postgresql","it-stack-redis","it-stack-elasticsearch",
    "it-stack-nextcloud","it-stack-mattermost","it-stack-jitsi",
    "it-stack-iredmail","it-stack-freepbx","it-stack-zammad",
    "it-stack-suitecrm","it-stack-odoo","it-stack-openkm",
    "it-stack-taiga","it-stack-snipeit","it-stack-glpi",
    "it-stack-traefik","it-stack-zabbix","it-stack-graylog"
)

$milestones = @(
    @{ title = "Phase 1: Foundation";    description = "FreeIPA, Keycloak, PostgreSQL, Redis, Traefik" }
    @{ title = "Phase 2: Collaboration"; description = "Nextcloud, Mattermost, Jitsi, iRedMail, Zammad" }
    @{ title = "Phase 3: Back Office";   description = "FreePBX, SuiteCRM, Odoo, OpenKM" }
    @{ title = "Phase 4: IT Management"; description = "Taiga, Snipe-IT, GLPI, Elasticsearch, Zabbix, Graylog" }
)

$token   = gh auth token
$headers = @{ Authorization = "Bearer $token"; Accept = "application/vnd.github.v3+json"; "Content-Type" = "application/json" }

$ok = 0; $fail = 0

foreach ($repo in $repos) {
    Write-Host "$repo" -ForegroundColor Cyan

    # Delete existing milestones first (clean slate)
    $existing = Invoke-RestMethod "https://api.github.com/repos/$org/$repo/milestones?state=all&per_page=20" -Headers $headers
    foreach ($e in $existing) {
        Invoke-RestMethod "https://api.github.com/repos/$org/$repo/milestones/$($e.number)" `
            -Method DELETE -Headers $headers | Out-Null
    }

    foreach ($ms in $milestones) {
        $body = $ms | ConvertTo-Json
        try {
            $r = Invoke-RestMethod "https://api.github.com/repos/$org/$repo/milestones" `
                -Method POST -Headers $headers -Body $body -ErrorAction Stop
            Write-Host "  [$($r.number)] $($r.title)" -ForegroundColor Green
            $ok++
        } catch {
            Write-Host "  [FAIL] $($ms.title): $_" -ForegroundColor Red
            $fail++
        }
    }
}

Write-Host ""
Write-Host "Milestones: OK=$ok  FAIL=$fail" -ForegroundColor Yellow
