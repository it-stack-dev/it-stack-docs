#!/usr/bin/env pwsh
# link-issues-to-projects.ps1 — Add all 120 lab issues to the appropriate GitHub Projects (v2)
# Projects: #6=Phase1, #7=Phase2, #8=Phase3, #9=Phase4, #10=MasterDashboard

$org   = "it-stack-dev"
$token = gh auth token
$gqlUrl = "https://api.github.com/graphql"
$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

# ── Helper: run a GraphQL query ────────────────────────────────────────────────
function Invoke-GQL {
    param([string]$Query, [hashtable]$Variables = @{})
    $body = @{ query = $Query; variables = $Variables } | ConvertTo-Json -Depth 10
    $r = Invoke-RestMethod $gqlUrl -Method POST -Headers $headers -Body $body
    if ($r.errors) { Write-Host "  GQL ERROR: $($r.errors[0].message)" -ForegroundColor Red }
    return $r.data
}

# ── Get project node IDs (projects #6-#10 in org) ─────────────────────────────
Write-Host "Fetching project node IDs..." -ForegroundColor Cyan
$projQuery = @"
query { organization(login: "$org") { projectsV2(first: 20) { nodes { number databaseId id title } } } }
"@
$projData = Invoke-GQL -Query $projQuery
$projects = $projData.organization.projectsV2.nodes
$projects | ForEach-Object { Write-Host "  Project #$($_.number): $($_.title) — $($_.id)" -ForegroundColor DarkGray }

# Map project numbers to node IDs (cast to int to ensure consistent lookup)
$projMap = @{}
foreach ($p in $projects) { $projMap[[int]$p.number] = $p.id }

# ── Module → project(s) mapping ────────────────────────────────────────────────
# Each module goes into its phase project + Master Dashboard (#10)
$moduleProjects = @{
    "it-stack-freeipa"       = @(6, 10)
    "it-stack-keycloak"      = @(6, 10)
    "it-stack-postgresql"    = @(6, 10)
    "it-stack-redis"         = @(6, 10)
    "it-stack-traefik"       = @(6, 10)
    "it-stack-nextcloud"     = @(7, 10)
    "it-stack-mattermost"    = @(7, 10)
    "it-stack-jitsi"         = @(7, 10)
    "it-stack-iredmail"      = @(7, 10)
    "it-stack-zammad"        = @(7, 10)
    "it-stack-freepbx"       = @(8, 10)
    "it-stack-suitecrm"      = @(8, 10)
    "it-stack-odoo"          = @(8, 10)
    "it-stack-openkm"        = @(8, 10)
    "it-stack-taiga"         = @(9, 10)
    "it-stack-snipeit"       = @(9, 10)
    "it-stack-glpi"          = @(9, 10)
    "it-stack-elasticsearch" = @(9, 10)
    "it-stack-zabbix"        = @(9, 10)
    "it-stack-graylog"       = @(9, 10)
}

# ── Add item mutation ──────────────────────────────────────────────────────────
$addMutation = @"
mutation AddItem(`$projectId: ID!, `$contentId: ID!) {
  addProjectV2ItemById(input: { projectId: `$projectId, contentId: `$contentId }) {
    item { id }
  }
}
"@

$totalOk = 0; $totalFail = 0

foreach ($repo in $moduleProjects.Keys | Sort-Object) {
    $projNums = $moduleProjects[$repo]
    Write-Host ""
    Write-Host "==> $repo → projects $($projNums -join ', ')" -ForegroundColor Cyan

    # Get all issues for this repo (up to 6)
    $issueQuery = @"
query { repository(owner: "$org", name: "$repo") { issues(first: 10, states: OPEN) { nodes { id number title } } } }
"@
    $issueData = Invoke-GQL -Query $issueQuery
    $issues = $issueData.repository.issues.nodes

    foreach ($issue in $issues) {
        foreach ($projNum in $projNums) {
            $projId = $projMap[$projNum]
            if (-not $projId) { Write-Host "  No project node ID for #$projNum" -ForegroundColor Yellow; continue }

            $vars = @{ projectId = $projId; contentId = $issue.id }
            $result = Invoke-GQL -Query $addMutation -Variables $vars
            if ($result.addProjectV2ItemById.item.id) {
                $totalOk++
            } else {
                Write-Host "  [FAIL] Issue #$($issue.number) -> project #$projNum" -ForegroundColor Red
                $totalFail++
            }
        }
        Write-Host "  #$($issue.number) added to projects $($projNums -join '+')" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Project items added: OK=$totalOk  FAIL=$totalFail" -ForegroundColor Yellow
