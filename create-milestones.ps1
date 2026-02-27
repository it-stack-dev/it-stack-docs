#!/usr/bin/env pwsh
# create-milestones.ps1 — Create standard phase milestones in repos

param(
    [string[]]$Repos = @(
        "it-stack-docs",
        "it-stack-installer",
        "it-stack-testing",
        "it-stack-ansible",
        "it-stack-terraform",
        "it-stack-helm"
    )
)

$milestones = @(
    @{ Title = "Phase 1: Foundation";    Due = "2026-03-27"; Desc = "FreeIPA, Keycloak, PostgreSQL, Redis, Traefik — Weeks 1-4" }
    @{ Title = "Phase 2: Collaboration"; Due = "2026-04-24"; Desc = "Nextcloud, Mattermost, Jitsi, iRedMail, Zammad — Weeks 5-8" }
    @{ Title = "Phase 3: Back Office";   Due = "2026-06-05"; Desc = "FreePBX, SuiteCRM, Odoo, OpenKM — Weeks 9-14" }
    @{ Title = "Phase 4: IT Management"; Due = "2026-07-17"; Desc = "Taiga, Snipe-IT, GLPI, Elasticsearch, Zabbix, Graylog — Weeks 15-20" }
)

$ok = 0
$fail = 0

foreach ($repo in $Repos) {
    Write-Host "Creating milestones in $repo ..." -ForegroundColor Cyan
    foreach ($ms in $milestones) {
        $result = gh api -X POST "repos/it-stack-dev/$repo/milestones" `
            -f title=$ms.Title `
            -f due_on="$($ms.Due)T00:00:00Z" `
            -f description=$ms.Desc 2>&1
        if ($LASTEXITCODE -eq 0) {
            $ok++
            Write-Host "  OK: $($ms.Title)" -ForegroundColor Green
        } else {
            $fail++
            Write-Host "  FAIL: $($ms.Title) — $result" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Finished. OK=$ok  FAIL=$fail" -ForegroundColor Yellow
