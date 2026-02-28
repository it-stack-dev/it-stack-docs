#!/usr/bin/env pwsh
# build-standard-docs.ps1
# Creates the standard numbered docs/* folder structure alongside the MkDocs structure.
# Copies files from their MkDocs locations into numbered paths with YAML front-matter.

$root = "C:\IT-Stack"
$docs = "$root\docs"

# ── 1. Create all directories ──────────────────────────────────────────────────
$dirs = @(
    "01-core",
    "02-implementation",
    "03-labs",
    "04-github",
    "05-guides",
    "06-technical-reference",
    "07-architecture"
)
foreach ($d in $dirs) {
    $null = New-Item -ItemType Directory -Path "$docs\$d" -Force
    Write-Host "  mkdir docs/$d" -ForegroundColor DarkGray
}

# ── 2. Helper: copy file and prepend front-matter ──────────────────────────────
function Copy-WithFrontMatter {
    param (
        [string]$Source,       # relative to $docs, e.g. "project/master-index.md"
        [string]$Dest,         # relative to $docs, e.g. "05-guides/01-master-index.md"
        [int]   $DocNumber,
        [string]$Category,
        [string]$Title
    )
    $srcPath  = "$docs\$($Source.Replace('/','\'))"
    $destPath = "$docs\$($Dest.Replace('/','\'))"
    if (-not (Test-Path $srcPath)) {
        Write-Host "  [SKIP] Source not found: $srcPath" -ForegroundColor Yellow
        return
    }
    $original = Get-Content $srcPath -Raw -Encoding UTF8
    $frontmatter = @"
---
doc: $('{0:D2}' -f $DocNumber)
title: "$Title"
category: $Category
date: 2026-02-27
source: $Source
---

"@
    # Don't double-add front-matter if it already has one
    if ($original -notmatch '^---') {
        $content = $frontmatter + $original
    } else {
        $content = $original
    }
    Set-Content -Path $destPath -Value $content -Encoding UTF8 -NoNewline
    Write-Host "  [OK] docs/$Dest" -ForegroundColor Green
}

# ── 3. Copy & number all existing documents ────────────────────────────────────
Write-Host "`n==> Copying and numbering documents" -ForegroundColor Cyan

Copy-WithFrontMatter `
    -Source "project/master-index.md" `
    -Dest   "05-guides/01-master-index.md" `
    -DocNumber 1 -Category "guides" `
    -Title "Master Index & Reading Guide"

Copy-WithFrontMatter `
    -Source "labs/overview.md" `
    -Dest   "05-guides/02-lab-manual-structure.md" `
    -DocNumber 2 -Category "guides" `
    -Title "Lab Manual Structure & Methodology"

Copy-WithFrontMatter `
    -Source "deployment/lab-deployment.md" `
    -Dest   "02-implementation/03-lab-deployment-plan.md" `
    -DocNumber 3 -Category "implementation" `
    -Title "Lab Deployment Plan"

# Doc 04 was a duplicate (lab-deployment-plan(1).md) — removed; placeholder retained
$placeholder04 = @"
---
doc: 04
title: "Lab Deployment Plan v2 (merged)"
category: implementation
date: 2026-02-27
note: "Duplicate of doc 03 — content merged into 02-implementation/03-lab-deployment-plan.md"
---

> **Note:** This document slot was previously occupied by a duplicate deployment plan.
> The canonical document is [03-lab-deployment-plan.md](03-lab-deployment-plan.md).
"@
Set-Content "$docs\02-implementation\04-lab-deployment-plan-v2.md" $placeholder04 -Encoding UTF8
Write-Host "  [OK] docs/02-implementation/04-lab-deployment-plan-v2.md (placeholder)" -ForegroundColor DarkYellow

Copy-WithFrontMatter `
    -Source "deployment/enterprise-reference.md" `
    -Dest   "06-technical-reference/05-stack-deployment.md" `
    -DocNumber 5 -Category "technical-reference" `
    -Title "Enterprise IT Stack Deployment Reference"

Copy-WithFrontMatter `
    -Source "architecture/overview.md" `
    -Dest   "02-implementation/06-stack-complete-v2.md" `
    -DocNumber 6 -Category "implementation" `
    -Title "Enterprise Stack Complete v2 — 8-Server Architecture"

Copy-WithFrontMatter `
    -Source "labs/part1-network-os.md" `
    -Dest   "03-labs/07-lab-manual-part1.md" `
    -DocNumber 7 -Category "labs" `
    -Title "Lab Manual Part 1: Network & OS Setup"

Copy-WithFrontMatter `
    -Source "labs/part2-identity-database.md" `
    -Dest   "03-labs/08-lab-manual-part2.md" `
    -DocNumber 8 -Category "labs" `
    -Title "Lab Manual Part 2: Identity, Database & SSO"

Copy-WithFrontMatter `
    -Source "labs/part3-collaboration.md" `
    -Dest   "03-labs/09-lab-manual-part3.md" `
    -DocNumber 9 -Category "labs" `
    -Title "Lab Manual Part 3: Collaboration"

Copy-WithFrontMatter `
    -Source "labs/part4-communications.md" `
    -Dest   "03-labs/10-lab-manual-part4.md" `
    -DocNumber 10 -Category "labs" `
    -Title "Lab Manual Part 4: Communications"

Copy-WithFrontMatter `
    -Source "labs/part5-business-management.md" `
    -Dest   "03-labs/11-lab-manual-part5.md" `
    -DocNumber 11 -Category "labs" `
    -Title "Lab Manual Part 5: Business & IT Management"

Copy-WithFrontMatter `
    -Source "architecture/integrations.md" `
    -Dest   "02-implementation/12-integration-guide.md" `
    -DocNumber 12 -Category "implementation" `
    -Title "Integration Guide — Cross-Service Procedures"

Copy-WithFrontMatter `
    -Source "project/github-guide.md" `
    -Dest   "04-github/13-github-guide.md" `
    -DocNumber 13 -Category "github" `
    -Title "IT-Stack GitHub Organization Setup Guide"

Copy-WithFrontMatter `
    -Source "contributing/framework-template.md" `
    -Dest   "05-guides/14-project-framework.md" `
    -DocNumber 14 -Category "guides" `
    -Title "Project Framework Template"

# ── 4. Create 07-architecture README ──────────────────────────────────────────
Write-Host "`n==> Creating docs/07-architecture/" -ForegroundColor Cyan
$archReadme = @"
# Architecture Reference

> **Category:** Architecture Decision Records (ADRs) and Technical Diagrams  
> **Doc Range:** 15+

This directory contains architecture decision records (ADRs) and technical diagrams for IT-Stack.

## ADR Index

| # | Title | Status | Date |
|---|-------|--------|------|
| ADR-001 | [Use FreeIPA + Keycloak for identity](adr-001-identity-stack.md) | Accepted | 2026-02-27 |
| ADR-002 | [PostgreSQL as primary database for all services](adr-002-postgresql-primary.md) | Accepted | 2026-02-27 |
| ADR-003 | [Traefik as reverse proxy with Let's Encrypt](adr-003-traefik-proxy.md) | Accepted | 2026-02-27 |
| ADR-004 | [6-lab progressive testing methodology](adr-004-lab-methodology.md) | Accepted | 2026-02-27 |

## Diagrams

- Network topology: see [deployment/03-lab-deployment-plan.md](../02-implementation/03-lab-deployment-plan.md)
- Service integration map: see [implementation/12-integration-guide.md](../02-implementation/12-integration-guide.md)
- 7-layer architecture: see [architecture/overview.md](../architecture/overview.md)
"@
Set-Content "$docs\07-architecture\README.md" $archReadme -Encoding UTF8
Write-Host "  [OK] docs/07-architecture/README.md" -ForegroundColor Green

Write-Host "`nDone. Run phase-3-create-spec-docs.ps1 next for the 01-core/ category spec docs." -ForegroundColor Yellow
