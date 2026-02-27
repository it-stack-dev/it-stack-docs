#!/usr/bin/env pwsh
# fix-milestones.ps1 — Delete and recreate all phase milestones correctly

$repos = @(
    "it-stack-docs"
    "it-stack-installer"
    "it-stack-testing"
    "it-stack-ansible"
    "it-stack-terraform"
    "it-stack-helm"
)

$milestones = @(
    @{ Title = "Phase 1: Foundation";    Due = "2026-03-27T00:00:00Z"; Desc = "FreeIPA, Keycloak, PostgreSQL, Redis, Traefik" }
    @{ Title = "Phase 2: Collaboration"; Due = "2026-04-24T00:00:00Z"; Desc = "Nextcloud, Mattermost, Jitsi, iRedMail, Zammad" }
    @{ Title = "Phase 3: Back Office";   Due = "2026-06-05T00:00:00Z"; Desc = "FreePBX, SuiteCRM, Odoo, OpenKM" }
    @{ Title = "Phase 4: IT Management"; Due = "2026-07-17T00:00:00Z"; Desc = "Taiga, Snipe-IT, GLPI, Elasticsearch, Zabbix, Graylog" }
)

foreach ($repo in $repos) {
    Write-Host "Fixing milestones in $repo ..." -ForegroundColor Cyan

    # Delete all existing milestones
    $existing = gh api "repos/it-stack-dev/$repo/milestones?state=all&per_page=20" | ConvertFrom-Json
    foreach ($ms in $existing) {
        gh api -X DELETE "repos/it-stack-dev/$repo/milestones/$($ms.number)" | Out-Null
        Write-Host "  Deleted: $($ms.title)"
    }

    # Create the correct milestones
    foreach ($ms in $milestones) {
        gh api -X POST "repos/it-stack-dev/$repo/milestones" `
            -f title=$ms.Title `
            -f due_on=$ms.Due `
            -f description=$ms.Desc | Out-Null
        Write-Host "  Created: $($ms.Title)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "All milestones fixed." -ForegroundColor Yellow
