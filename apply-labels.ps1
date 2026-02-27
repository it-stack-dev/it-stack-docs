#!/usr/bin/env pwsh
# apply-labels.ps1 — Apply standard IT-Stack labels to all meta repos

$labelDefs = @(
    @{ Name = "lab";                Color = "0075ca"; Desc = "Lab test issue" }
    @{ Name = "module-01";          Color = "e4e669"; Desc = "FreeIPA" }
    @{ Name = "module-02";          Color = "e4e669"; Desc = "Keycloak" }
    @{ Name = "module-03";          Color = "e4e669"; Desc = "PostgreSQL" }
    @{ Name = "module-04";          Color = "e4e669"; Desc = "Redis" }
    @{ Name = "module-05";          Color = "e4e669"; Desc = "Elasticsearch" }
    @{ Name = "module-06";          Color = "e4e669"; Desc = "Nextcloud" }
    @{ Name = "module-07";          Color = "e4e669"; Desc = "Mattermost" }
    @{ Name = "module-08";          Color = "e4e669"; Desc = "Jitsi" }
    @{ Name = "module-09";          Color = "e4e669"; Desc = "iRedMail" }
    @{ Name = "module-10";          Color = "e4e669"; Desc = "FreePBX" }
    @{ Name = "module-11";          Color = "e4e669"; Desc = "Zammad" }
    @{ Name = "module-12";          Color = "e4e669"; Desc = "SuiteCRM" }
    @{ Name = "module-13";          Color = "e4e669"; Desc = "Odoo" }
    @{ Name = "module-14";          Color = "e4e669"; Desc = "OpenKM" }
    @{ Name = "module-15";          Color = "e4e669"; Desc = "Taiga" }
    @{ Name = "module-16";          Color = "e4e669"; Desc = "Snipe-IT" }
    @{ Name = "module-17";          Color = "e4e669"; Desc = "GLPI" }
    @{ Name = "module-18";          Color = "e4e669"; Desc = "Traefik" }
    @{ Name = "module-19";          Color = "e4e669"; Desc = "Zabbix" }
    @{ Name = "module-20";          Color = "e4e669"; Desc = "Graylog" }
    @{ Name = "phase-1";            Color = "006b75"; Desc = "Phase 1: Foundation" }
    @{ Name = "phase-2";            Color = "006b75"; Desc = "Phase 2: Collaboration" }
    @{ Name = "phase-3";            Color = "006b75"; Desc = "Phase 3: Back Office" }
    @{ Name = "phase-4";            Color = "006b75"; Desc = "Phase 4: IT Management" }
    @{ Name = "identity";           Color = "d93f0b"; Desc = "Category: Identity" }
    @{ Name = "database";           Color = "0e8a16"; Desc = "Category: Database" }
    @{ Name = "collaboration";      Color = "1d76db"; Desc = "Category: Collaboration" }
    @{ Name = "communications";     Color = "5319e7"; Desc = "Category: Communications" }
    @{ Name = "business";           Color = "e99695"; Desc = "Category: Business" }
    @{ Name = "it-management";      Color = "f9d0c4"; Desc = "Category: IT Management" }
    @{ Name = "infrastructure";     Color = "bfd4f2"; Desc = "Category: Infrastructure" }
    @{ Name = "priority-high";      Color = "d73a4a"; Desc = "High priority" }
    @{ Name = "priority-med";       Color = "fbca04"; Desc = "Medium priority" }
    @{ Name = "priority-low";       Color = "c2e0c6"; Desc = "Low priority" }
    @{ Name = "status-todo";        Color = "eeeeee"; Desc = "Not started" }
    @{ Name = "status-in-progress"; Color = "0052cc"; Desc = "In progress" }
    @{ Name = "status-done";        Color = "0e8a16"; Desc = "Completed" }
    @{ Name = "status-blocked";     Color = "b60205"; Desc = "Blocked" }
)

$repos = @(
    "it-stack-docs"
    "it-stack-installer"
    "it-stack-testing"
    "it-stack-ansible"
    "it-stack-terraform"
    "it-stack-helm"
)

$ok = 0
$fail = 0

foreach ($repo in $repos) {
    Write-Host "Applying labels to $repo ..." -ForegroundColor Cyan
    foreach ($label in $labelDefs) {
        $output = gh label create $label.Name `
            --repo "it-stack-dev/$repo" `
            --color $label.Color `
            --description $label.Desc `
            --force 2>&1
        if ($LASTEXITCODE -eq 0) {
            $ok++
        } else {
            $fail++
            Write-Host "  FAIL [$repo] $($label.Name): $output" -ForegroundColor Red
        }
    }
    Write-Host "  $($labelDefs.Count) labels applied" -ForegroundColor Green
}

Write-Host ""
Write-Host "Finished. OK=$ok  FAIL=$fail" -ForegroundColor Yellow
