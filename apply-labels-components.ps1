#!/usr/bin/env pwsh
# apply-labels-components.ps1 — Apply standard labels to all 20 component repos

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

$labels = @(
    # Lab
    @{ name="lab";               color="0075ca"; desc="Lab test issue" }
    # Modules
    @{ name="module-01"; color="b60205"; desc="FreeIPA" }
    @{ name="module-02"; color="d93f0b"; desc="Keycloak" }
    @{ name="module-03"; color="e4e669"; desc="PostgreSQL" }
    @{ name="module-04"; color="0e8a16"; desc="Redis" }
    @{ name="module-05"; color="1d76db"; desc="Elasticsearch" }
    @{ name="module-06"; color="0052cc"; desc="Nextcloud" }
    @{ name="module-07"; color="5319e7"; desc="Mattermost" }
    @{ name="module-08"; color="e11d48"; desc="Jitsi" }
    @{ name="module-09"; color="f97316"; desc="iRedMail" }
    @{ name="module-10"; color="84cc16"; desc="FreePBX" }
    @{ name="module-11"; color="06b6d4"; desc="Zammad" }
    @{ name="module-12"; color="8b5cf6"; desc="SuiteCRM" }
    @{ name="module-13"; color="ec4899"; desc="Odoo" }
    @{ name="module-14"; color="14b8a6"; desc="OpenKM" }
    @{ name="module-15"; color="f59e0b"; desc="Taiga" }
    @{ name="module-16"; color="10b981"; desc="Snipe-IT" }
    @{ name="module-17"; color="3b82f6"; desc="GLPI" }
    @{ name="module-18"; color="6366f1"; desc="Traefik" }
    @{ name="module-19"; color="ef4444"; desc="Zabbix" }
    @{ name="module-20"; color="a855f7"; desc="Graylog" }
    # Phases
    @{ name="phase-1"; color="bfd4f2"; desc="Phase 1: Foundation" }
    @{ name="phase-2"; color="d4c5f9"; desc="Phase 2: Collaboration" }
    @{ name="phase-3"; color="c2e0c6"; desc="Phase 3: Back Office" }
    @{ name="phase-4"; color="fef2c0"; desc="Phase 4: IT Management" }
    # Categories
    @{ name="identity";       color="0075ca"; desc="Identity & Security" }
    @{ name="database";       color="e4e669"; desc="Database & Cache" }
    @{ name="collaboration";  color="0e8a16"; desc="Collaboration" }
    @{ name="communications"; color="d93f0b"; desc="Communications" }
    @{ name="business";       color="5319e7"; desc="Business Systems" }
    @{ name="it-management";  color="1d76db"; desc="IT Management" }
    @{ name="infrastructure"; color="b60205"; desc="Infrastructure" }
    # Priority
    @{ name="priority-high"; color="b60205"; desc="High priority" }
    @{ name="priority-med";  color="fbca04"; desc="Medium priority" }
    @{ name="priority-low";  color="0e8a16"; desc="Low priority" }
    # Status
    @{ name="status-todo";        color="ededed"; desc="Not started" }
    @{ name="status-in-progress"; color="0075ca"; desc="In progress" }
    @{ name="status-done";        color="0e8a16"; desc="Completed" }
    @{ name="status-blocked";     color="b60205"; desc="Blocked" }
)

$token   = gh auth token
$headers = @{ Authorization = "Bearer $token"; Accept = "application/vnd.github.v3+json"; "Content-Type" = "application/json" }

$ok = 0; $fail = 0

foreach ($repo in $repos) {
    Write-Host "$repo" -ForegroundColor Cyan
    foreach ($lbl in $labels) {
        $body = @{ name = $lbl.name; color = $lbl.color; description = $lbl.desc } | ConvertTo-Json
        try {
            # Try create first
            Invoke-RestMethod "https://api.github.com/repos/$org/$repo/labels" `
                -Method POST -Headers $headers -Body $body -ErrorAction Stop | Out-Null
            $ok++
        } catch {
            # If 422 (already exists), update it
            if ($_.Exception.Response.StatusCode.value__ -eq 422) {
                try {
                    Invoke-RestMethod "https://api.github.com/repos/$org/$repo/labels/$($lbl.name)" `
                        -Method PATCH -Headers $headers -Body $body -ErrorAction Stop | Out-Null
                    $ok++
                } catch { $fail++ }
            } else { $fail++ }
        }
    }
}

Write-Host ""
Write-Host "Labels: OK=$ok  FAIL=$fail" -ForegroundColor Yellow
