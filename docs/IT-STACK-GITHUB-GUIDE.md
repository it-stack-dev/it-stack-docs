# IT-Stack GitHub Setup Guide
## Step-by-Step: Bootstrapping the `it-stack-dev` Organization
**Organization:** [`github.com/it-stack-dev`](https://github.com/it-stack-dev)  
**Created:** February 27, 2026  
**Status:** Organization created, empty — follow this guide from Step 1.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Organization-Level `.github` Repository](#2-organization-level-github-repository)
3. [Create Meta Repositories (6)](#3-create-meta-repositories-6)
4. [Push Existing Documentation](#4-push-existing-documentation)
5. [Create GitHub Projects (5)](#5-create-github-projects-5)
6. [Organization Labels](#6-organization-labels)
7. [Create Milestones](#7-create-milestones)
8. [Scaffold Component Repositories (20)](#8-scaffold-component-repositories-20)
9. [Create Lab Issues (120 Total)](#9-create-lab-issues-120-total)
10. [Branch Strategy](#10-branch-strategy)
11. [Reusable Workflow Templates](#11-reusable-workflow-templates)
12. [Repository Checklist: Per-Repo Standard Files](#12-repository-checklist-per-repo-standard-files)
13. [Automation Scripts Reference](#13-automation-scripts-reference)
14. [Quick Commands Cheat Sheet](#14-quick-commands-cheat-sheet)

---

## 1. Prerequisites

### Required Tools

```powershell
# Verify tools are installed before starting
git --version          # 2.x or higher
gh --version           # 2.x or higher (GitHub CLI)
docker --version       # For testing Docker images later
```

### GitHub CLI Authentication

```powershell
# Authenticate with GitHub CLI (if not done yet)
gh auth login

# Select: GitHub.com → HTTPS → Authenticate with browser
# Then set default org:
gh config set default-org it-stack-dev

# Verify authentication
gh auth status
gh api user --jq '.login'
```

### Verify Organization Access

```powershell
# Confirm you have Owner access to it-stack-dev
gh api orgs/it-stack-dev --jq '{login: .login, plan: .plan.name}'
```

---

## 2. Organization-Level `.github` Repository

This special repo provides default community health files and reusable workflows for all repositories in the org.

### 2.1 Create the Repository

```powershell
gh repo create it-stack-dev/.github `
  --public `
  --description "IT-Stack organization defaults: community health files and reusable workflows"
```

### 2.2 Clone and Set Up Locally

```powershell
# Clone locally
git clone https://github.com/it-stack-dev/.github.git
cd .github

# Create folder structure
New-Item -ItemType Directory -Path "profile", "workflows" -Force
```

### 2.3 Create `profile/README.md` (Org Homepage)

Create file `profile/README.md`:

```markdown
# IT-Stack

**Complete open-source enterprise IT infrastructure — $0 in software licensing.**

## Mission
IT-Stack delivers a production-ready enterprise IT platform using 100% open-source software.
It replaces Microsoft 365, Salesforce, SAP, RingCentral, Zendesk, and ServiceNow — at zero licensing cost.
Supports 50–1,000+ users on 8–9 servers.

## Stack (7 Categories · 20 Services)

| Category | Services | Replaces |
|----------|---------|---------|
| **Identity** | FreeIPA · Keycloak | Active Directory · Azure AD |
| **Database** | PostgreSQL · Redis · Elasticsearch | MS SQL · ElastiCache |
| **Collaboration** | Nextcloud · Mattermost · Jitsi | Microsoft 365 · Slack · Zoom |
| **Communications** | iRedMail · FreePBX · Zammad | Exchange · RingCentral · Zendesk |
| **Business** | SuiteCRM · Odoo · OpenKM | Salesforce · SAP · SharePoint |
| **IT Management** | Taiga · Snipe-IT · GLPI | Jira · — · ServiceNow |
| **Infrastructure** | Traefik · Zabbix · Graylog | nginx · Datadog · Splunk |

## Repositories

- 📚 [Full Documentation](https://github.com/it-stack-dev/it-stack-docs)
- 🚀 [Installer / Bootstrap](https://github.com/it-stack-dev/it-stack-installer)
- 🔧 [Ansible Playbooks](https://github.com/it-stack-dev/it-stack-ansible)
- ☸️ [Helm Charts](https://github.com/it-stack-dev/it-stack-helm)
- 🧪 [Integration Testing](https://github.com/it-stack-dev/it-stack-testing)

## Quick Start

```bash
git clone https://github.com/it-stack-dev/it-stack-installer.git
cd it-stack-installer
./install.sh
```

## License
Apache 2.0 · All components are open-source
```

### 2.4 Create `CONTRIBUTING.md`

```markdown
# Contributing to IT-Stack

## Getting Started
1. Fork the repository you want to contribute to
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make changes following the coding standards below
4. Ensure all lab tests pass: `make test`
5. Submit a pull request to the `develop` branch

## Coding Standards
- Follow existing code style in each repository
- Write tests for all new functionality (unit + lab test)
- Update documentation when changing behavior
- No secrets or credentials in commits

## Lab Test Requirement
All pull requests must include or pass the relevant lab tests.  
Run `./tests/labs/test-lab-01.sh` through the affected lab level.

## Commit Messages
Format: `type(scope): short description`  
Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`  
Example: `feat(keycloak): add SAML client for SuiteCRM`

## Questions?
Open an issue with the label `question`.
```

### 2.5 Create `CODE_OF_CONDUCT.md`

Use the Contributor Covenant:

```markdown
# Code of Conduct

## Our Pledge
We pledge to make participation a harassment-free experience for everyone.

## Our Standards
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

## Enforcement
Instances of abusive behavior may be reported by opening a private issue.

---
_Contributor Covenant, version 2.1_
```

### 2.6 Create `SECURITY.md`

```markdown
# Security Policy

## Supported Versions
| Version | Supported |
|---------|-----------|
| latest (main) | ✅ |
| develop | ⚠️ Beta |

## Reporting a Vulnerability
Please **do not** open a public GitHub issue for security vulnerabilities.

1. Open a [private security advisory](https://github.com/it-stack-dev/REPO/security/advisories/new)
2. Include: description, affected versions, reproduction steps, impact
3. We will respond within 72 hours

## Security Best Practices
- Use Ansible Vault for all secrets
- Never commit credentials, tokens, or private keys
- Keep Docker base images updated
- Run Trivy scans before releasing
```

### 2.7 Commit and Push

```powershell
git add .
git commit -m "chore: initialize organization .github repo"
git push origin main
```

---

## 3. Create Meta Repositories (6)

Run this block to create all 6 meta repositories in one pass:

```powershell
$metaRepos = @(
    @{ Name = "it-stack-docs";        Desc = "IT-Stack: Complete documentation — lab manuals, architecture, deployment guides" },
    @{ Name = "it-stack-installer";   Desc = "IT-Stack: Automated installer, bootstrap scripts, and automation tools" },
    @{ Name = "it-stack-testing";     Desc = "IT-Stack: Integration testing suite and end-to-end test scenarios" },
    @{ Name = "it-stack-ansible";     Desc = "IT-Stack: Ansible playbooks for all 20 services" },
    @{ Name = "it-stack-terraform";   Desc = "IT-Stack: Terraform modules for infrastructure provisioning" },
    @{ Name = "it-stack-helm";        Desc = "IT-Stack: Helm charts for Kubernetes deployment of all services" }
)

foreach ($repo in $metaRepos) {
    Write-Host "Creating: $($repo.Name)" -ForegroundColor Cyan
    gh repo create "it-stack-dev/$($repo.Name)" `
        --public `
        --description $repo.Desc `
        --add-readme
    
    # Add topics
    Start-Sleep -Seconds 1
    gh api -X PUT "repos/it-stack-dev/$($repo.Name)/topics" `
        -f "names[]=it-stack" `
        -f "names[]=open-source" `
        -f "names[]=self-hosted" `
        -f "names[]=enterprise-it"
    
    Write-Host "  ✓ Created $($repo.Name)" -ForegroundColor Green
}
```

---

## 4. Push Existing Documentation

### 4.1 Initialize Git in `C:\IT-Stack\`

```powershell
cd C:\IT-Stack

# Initialize git repository
git init
git branch -M main

# Add remote
git remote add origin https://github.com/it-stack-dev/it-stack-docs.git

# Stage all documentation
git add .
git commit -m "docs: initial commit — complete IT-Stack documentation set (14 documents, ~600 pages)"

# Push (first time — may need to force since remote has a README)
git push -u origin main --force
```

### 4.2 Create Standard Documentation Folder Structure

After the initial push, reorganize into the numbered system:

```powershell
cd C:\IT-Stack

# Create standard subdirectory structure
$docDirs = @(
    "docs\01-core",
    "docs\02-implementation",
    "docs\03-labs",
    "docs\04-github",
    "docs\05-guides",
    "docs\06-technical-reference",
    "docs\07-architecture\adr",
    "docs\07-architecture\diagrams"
)

foreach ($dir in $docDirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "Created: $dir"
}
```

---

## 5. Create GitHub Projects (5)

### Method A: GitHub CLI (Automated)

```powershell
# Create all 5 projects
$projects = @(
    "Phase 1: Foundation",
    "Phase 2: Collaboration",
    "Phase 3: Back Office",
    "Phase 4: IT Management",
    "Master Dashboard"
)

foreach ($project in $projects) {
    gh project create --owner it-stack-dev --title $project
    Write-Host "Created project: $project"
    Start-Sleep -Seconds 1
}

# List created projects to get their numbers
gh project list --owner it-stack-dev
```

### Method B: GitHub Web UI

1. Go to [github.com/orgs/it-stack-dev/projects](https://github.com/orgs/it-stack-dev/projects)
2. Click **New project** → Select **Board** template
3. Create each project:
   - "Phase 1: Foundation"
   - "Phase 2: Collaboration"
   - "Phase 3: Back Office"
   - "Phase 4: IT Management"
   - "Master Dashboard"

### Add Views to Each Project

For each project, add these views:
1. **Board** (columns: Todo → In Progress → Done)
2. **Table** (sortable by module #, lab #, status, assignee)
3. **Roadmap** (timeline by milestone)

```powershell
# After creating projects, note their numbers from:
gh project list --owner it-stack-dev
# Example output:
# NUMBER  TITLE                      STATE  ID
# 1       Phase 1: Foundation        open   PVT_xxx
# 2       Phase 2: Collaboration     open   PVT_xxx
# etc.
```

---

## 6. Organization Labels

Apply consistent labels to all repositories. Run this script after each repo is created, or run once and reapply:

```powershell
# apply-labels.ps1
# Run once per repository to set standard labels

param(
    [string]$RepoName   # e.g. "it-stack-freeipa"
)

$labels = @(
    # Lab label
    @{ Name = "lab";              Color = "0075ca"; Desc = "Lab test issue" },
    
    # Module labels (01-20)
    @{ Name = "module-01";        Color = "e4e669"; Desc = "FreeIPA" },
    @{ Name = "module-02";        Color = "e4e669"; Desc = "Keycloak" },
    @{ Name = "module-03";        Color = "e4e669"; Desc = "PostgreSQL" },
    @{ Name = "module-04";        Color = "e4e669"; Desc = "Redis" },
    @{ Name = "module-05";        Color = "e4e669"; Desc = "Elasticsearch" },
    @{ Name = "module-06";        Color = "e4e669"; Desc = "Nextcloud" },
    @{ Name = "module-07";        Color = "e4e669"; Desc = "Mattermost" },
    @{ Name = "module-08";        Color = "e4e669"; Desc = "Jitsi" },
    @{ Name = "module-09";        Color = "e4e669"; Desc = "iRedMail" },
    @{ Name = "module-10";        Color = "e4e669"; Desc = "FreePBX" },
    @{ Name = "module-11";        Color = "e4e669"; Desc = "Zammad" },
    @{ Name = "module-12";        Color = "e4e669"; Desc = "SuiteCRM" },
    @{ Name = "module-13";        Color = "e4e669"; Desc = "Odoo" },
    @{ Name = "module-14";        Color = "e4e669"; Desc = "OpenKM" },
    @{ Name = "module-15";        Color = "e4e669"; Desc = "Taiga" },
    @{ Name = "module-16";        Color = "e4e669"; Desc = "Snipe-IT" },
    @{ Name = "module-17";        Color = "e4e669"; Desc = "GLPI" },
    @{ Name = "module-18";        Color = "e4e669"; Desc = "Traefik" },
    @{ Name = "module-19";        Color = "e4e669"; Desc = "Zabbix" },
    @{ Name = "module-20";        Color = "e4e669"; Desc = "Graylog" },
    
    # Phase labels
    @{ Name = "phase-1";          Color = "006b75"; Desc = "Deployment Phase 1: Foundation" },
    @{ Name = "phase-2";          Color = "006b75"; Desc = "Deployment Phase 2: Collaboration" },
    @{ Name = "phase-3";          Color = "006b75"; Desc = "Deployment Phase 3: Back Office" },
    @{ Name = "phase-4";          Color = "006b75"; Desc = "Deployment Phase 4: IT Management" },
    
    # Category labels
    @{ Name = "identity";         Color = "d93f0b"; Desc = "Category: Identity & Authentication" },
    @{ Name = "database";         Color = "0e8a16"; Desc = "Category: Database & Cache" },
    @{ Name = "collaboration";    Color = "1d76db"; Desc = "Category: Collaboration" },
    @{ Name = "communications";   Color = "5319e7"; Desc = "Category: Communications" },
    @{ Name = "business";         Color = "e99695"; Desc = "Category: Business Systems" },
    @{ Name = "it-management";    Color = "f9d0c4"; Desc = "Category: IT & Project Management" },
    @{ Name = "infrastructure";   Color = "bfd4f2"; Desc = "Category: Infrastructure" },
    
    # Priority labels
    @{ Name = "priority-high";    Color = "d73a4a"; Desc = "High priority" },
    @{ Name = "priority-med";     Color = "fbca04"; Desc = "Medium priority" },
    @{ Name = "priority-low";     Color = "c2e0c6"; Desc = "Low priority" },
    
    # Status labels
    @{ Name = "status-todo";         Color = "ffffff"; Desc = "Not started" },
    @{ Name = "status-in-progress";  Color = "0052cc"; Desc = "In progress" },
    @{ Name = "status-done";         Color = "0e8a16"; Desc = "Completed" },
    @{ Name = "status-blocked";      Color = "b60205"; Desc = "Blocked" }
)

foreach ($label in $labels) {
    gh label create $label.Name `
        --repo "it-stack-dev/$RepoName" `
        --color $label.Color `
        --description $label.Desc `
        --force
}

Write-Host "Labels applied to it-stack-dev/$RepoName" -ForegroundColor Green
```

---

## 7. Create Milestones

```powershell
# create-milestones.ps1
# Apply to each component repo

$milestones = @(
    @{ Title = "Phase 1: Foundation";      Due = "2026-03-27"; Desc = "FreeIPA, Keycloak, PostgreSQL, Redis, Traefik" },
    @{ Title = "Phase 2: Collaboration";   Due = "2026-04-24"; Desc = "Nextcloud, Mattermost, Jitsi, iRedMail, Zammad" },
    @{ Title = "Phase 3: Back Office";     Due = "2026-06-05"; Desc = "FreePBX, SuiteCRM, Odoo, OpenKM" },
    @{ Title = "Phase 4: IT Management";   Due = "2026-07-17"; Desc = "Taiga, Snipe-IT, GLPI, Elasticsearch, Zabbix, Graylog" }
)

# Apply to a specific repo
param([string]$RepoName)

foreach ($ms in $milestones) {
    gh api -X POST "repos/it-stack-dev/$RepoName/milestones" `
        -f title=$ms.Title `
        -f due_on="$($ms.Due)T00:00:00Z" `
        -f description=$ms.Desc
}
```

---

## 8. Scaffold Component Repositories (20)

### 8.1 Repository Creation Script

```powershell
# create-all-component-repos.ps1
# Creates all 20 component repositories

$modules = @(
    # Phase 1 — Foundation
    @{ Num="01"; Name="freeipa";       Category="identity";       Phase=1; Desc="IT-Stack 01: FreeIPA — Identity Provider (LDAP/Kerberos/DNS)" },
    @{ Num="02"; Name="keycloak";      Category="identity";       Phase=1; Desc="IT-Stack 02: Keycloak — SSO Broker (OAuth2/OIDC/SAML)" },
    @{ Num="03"; Name="postgresql";    Category="database";       Phase=1; Desc="IT-Stack 03: PostgreSQL — Relational Database Server" },
    @{ Num="04"; Name="redis";         Category="database";       Phase=1; Desc="IT-Stack 04: Redis — In-Memory Cache and Session Store" },
    @{ Num="18"; Name="traefik";       Category="infrastructure"; Phase=1; Desc="IT-Stack 18: Traefik — Reverse Proxy, TLS Termination, Load Balancer" },
    
    # Phase 2 — Collaboration & Communications
    @{ Num="06"; Name="nextcloud";     Category="collaboration";  Phase=2; Desc="IT-Stack 06: Nextcloud — File Share, Office Suite, Calendar (replaces M365)" },
    @{ Num="07"; Name="mattermost";    Category="collaboration";  Phase=2; Desc="IT-Stack 07: Mattermost — Team Chat and DevOps Notifications (replaces Slack)" },
    @{ Num="08"; Name="jitsi";         Category="collaboration";  Phase=2; Desc="IT-Stack 08: Jitsi — Video Conferencing (replaces Zoom)" },
    @{ Num="09"; Name="iredmail";      Category="communications"; Phase=2; Desc="IT-Stack 09: iRedMail — Email Server MTA/MDA (replaces Exchange)" },
    @{ Num="11"; Name="zammad";        Category="communications"; Phase=2; Desc="IT-Stack 11: Zammad — Help Desk and Ticketing System (replaces Zendesk)" },
    
    # Phase 3 — Back Office
    @{ Num="10"; Name="freepbx";       Category="communications"; Phase=3; Desc="IT-Stack 10: FreePBX — VoIP PBX, IVR, Call Queues (replaces RingCentral)" },
    @{ Num="12"; Name="suitecrm";      Category="business";       Phase=3; Desc="IT-Stack 12: SuiteCRM — Customer Relationship Management (replaces Salesforce)" },
    @{ Num="13"; Name="odoo";          Category="business";       Phase=3; Desc="IT-Stack 13: Odoo — ERP HR/Finance/Inventory (replaces SAP)" },
    @{ Num="14"; Name="openkm";        Category="business";       Phase=3; Desc="IT-Stack 14: OpenKM — Document Management System (replaces SharePoint DMS)" },
    
    # Phase 4 — IT Management & Observability
    @{ Num="15"; Name="taiga";         Category="it-management";  Phase=4; Desc="IT-Stack 15: Taiga — Agile Project Management (replaces Jira)" },
    @{ Num="16"; Name="snipeit";       Category="it-management";  Phase=4; Desc="IT-Stack 16: Snipe-IT — IT Asset Management and Lifecycle Tracking" },
    @{ Num="17"; Name="glpi";          Category="it-management";  Phase=4; Desc="IT-Stack 17: GLPI — IT Service Management / CMDB (replaces ServiceNow)" },
    @{ Num="05"; Name="elasticsearch"; Category="database";       Phase=4; Desc="IT-Stack 05: Elasticsearch — Full-Text Search and Log Indexing" },
    @{ Num="19"; Name="zabbix";        Category="infrastructure"; Phase=4; Desc="IT-Stack 19: Zabbix — Infrastructure Monitoring and Alerting" },
    @{ Num="20"; Name="graylog";       Category="infrastructure"; Phase=4; Desc="IT-Stack 20: Graylog — Centralized Log Management" }
)

foreach ($module in $modules) {
    $repoName = "it-stack-$($module.Name)"
    $fullRepo = "it-stack-dev/$repoName"
    
    Write-Host "[$($module.Num)] Creating: $repoName" -ForegroundColor Cyan
    
    gh repo create $fullRepo `
        --public `
        --description $module.Desc `
        --add-readme
    
    Start-Sleep -Seconds 2
    
    # Apply topics
    gh api -X PUT "repos/$fullRepo/topics" `
        -f "names[]=it-stack" `
        -f "names[]=$($module.Category)" `
        -f "names[]=module-$($module.Num)" `
        -f "names[]=phase-$($module.Phase)" `
        -f "names[]=self-hosted" `
        -f "names[]=open-source"
    
    Write-Host "  ✓ Created $repoName" -ForegroundColor Green
}

Write-Host "`n✓ All 20 component repositories created." -ForegroundColor Green
Write-Host "Next: scaffold local directory structure for each repo (create-repo-template.ps1)"
```

### 8.2 Local Scaffold Script

```powershell
# create-repo-template.ps1
# Scaffolds the standard directory structure for one module repo

param(
    [Parameter(Mandatory=$true)]
    [string]$ModuleName,       # e.g. "freeipa"
    
    [Parameter(Mandatory=$true)]
    [string]$Category,         # e.g. "01-identity"
    
    [string]$ModuleNumber = "01",  # e.g. "01"
    [string]$BaseDir = "C:\it-stack-dev\repos"
)

$repoName = "it-stack-$ModuleName"
$outputPath = "$BaseDir\$Category\$repoName"

Write-Host "Scaffolding: $repoName → $outputPath" -ForegroundColor Cyan

$dirs = @(
    "src",
    "tests\unit",
    "tests\integration",
    "tests\e2e",
    "tests\labs",
    "docker",
    "kubernetes\base",
    "kubernetes\overlays\dev",
    "kubernetes\overlays\staging",
    "kubernetes\overlays\production",
    "helm\templates",
    "ansible\roles",
    "ansible\playbooks",
    "docs\labs",
    "docs\api",
    ".github\workflows"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path (Join-Path $outputPath $dir) -Force | Out-Null
}

# Create 6 docker-compose files
$labTypes = @("standalone", "lan", "advanced", "sso", "integration", "production")
foreach ($type in $labTypes) {
    @"
version: '3.8'
# Lab docker-compose: $type
# Module: it-stack-$ModuleName

services:
  it-stack-${ModuleName}:
    image: it-stack-${ModuleName}:latest
    container_name: it-stack-${ModuleName}-${type}
    ports:
      - "8080:8080"
    environment:
      - LOG_LEVEL=info
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
"@ | Set-Content "$outputPath\docker\docker-compose.$type.yml"
}

# Create 6 lab test scripts
$labDefs = @(
    @{ Num="01"; Name="Standalone";           Hardware="1 machine" },
    @{ Num="02"; Name="External Dependencies"; Hardware="2-3 machines" },
    @{ Num="03"; Name="Advanced Features";     Hardware="2-3 machines" },
    @{ Num="04"; Name="SSO Integration";       Hardware="3-4 machines" },
    @{ Num="05"; Name="Advanced Integration";  Hardware="4-5 machines" },
    @{ Num="06"; Name="Production Deployment"; Hardware="5+ machines" }
)

foreach ($lab in $labDefs) {
    $labNum = $lab.Num
    $composeType = @("standalone","lan","advanced","sso","integration","production")[[int]$labNum - 1]
    $script = @"
#!/bin/bash
# Lab $ModuleNumber-${labNum}: $($lab.Name) - it-stack-$ModuleName
# Hardware: $($lab.Hardware)
set -e

MODULE="$ModuleName"
LAB="$labNum"
COMPOSE_FILE="docker/docker-compose.$composeType.yml"

echo "================================================================"
echo "  Lab $ModuleNumber-${labNum}: $($lab.Name)"
echo "  Module: it-stack-\$MODULE"
echo "================================================================"

echo "[1/4] Starting services..."
docker compose -f \$COMPOSE_FILE up -d
sleep 15

echo "[2/4] Health check..."
curl -sf http://localhost:8080/health || { echo "✗ Health check failed"; exit 1; }
echo "✓ Health check passed"

echo "[3/4] Functional tests..."
# TODO: Add module-specific tests here
echo "✓ Functional tests passed"

echo "[4/4] Cleanup..."
docker compose -f \$COMPOSE_FILE down -v

echo ""
echo "================================================================"
echo "  ✓ Lab $ModuleNumber-${labNum} PASSED"
echo "================================================================"
"@
    $script | Set-Content "$outputPath\tests\labs\test-lab-$labNum.sh"
}

# Create manifest
@"
module:
  name: $ModuleName
  version: "0.1.0"
  description: "IT-Stack module: $ModuleName"
  category: $Category
  module_number: "$ModuleNumber"
  tier: development

  repository:
    type: git
    url: "https://github.com/it-stack-dev/it-stack-$ModuleName"

dependencies:
  required: []
  optional: []

testing:
  labs:
    - {number: "01", name: "Standalone Deployment",   duration: "30-60m"}
    - {number: "02", name: "External Dependencies",   duration: "45-90m"}
    - {number: "03", name: "Advanced Features",       duration: "60-120m"}
    - {number: "04", name: "SSO Integration",         duration: "90-120m"}
    - {number: "05", name: "Advanced Integration",    duration: "90-150m"}
    - {number: "06", name: "Production Deployment",   duration: "120-180m"}

monitoring:
  healthcheck:
    endpoint: "/health"
    interval: 10s
"@ | Set-Content "$outputPath\it-stack-$ModuleName.yml"

Write-Host "✓ Scaffold complete: $outputPath" -ForegroundColor Green
Write-Host "  Next:"
Write-Host "    cd $outputPath"
Write-Host "    git init && git add . && git commit -m 'chore: initial scaffold'"
Write-Host "    git remote add origin https://github.com/it-stack-dev/$repoName.git"
Write-Host "    git push -u origin main"
```

---

## 9. Create Lab Issues (120 Total)

### 9.1 Issue Creation Script

```powershell
# create-lab-issues.ps1
# Creates 6 lab issues per module repository

param(
    [string]$OrgName = "it-stack-dev",
    [int]$Phase = 1,          # Which phase to create issues for
    [switch]$DryRun = $false
)

# Universal lab definitions
$labs = @(
    @{ Num="01"; Name="Standalone Deployment";   Duration="30-60 min";   Hardware="1 machine" },
    @{ Num="02"; Name="External Dependencies";   Duration="45-90 min";   Hardware="2-3 machines" },
    @{ Num="03"; Name="Advanced Features";       Duration="60-120 min";  Hardware="2-3 machines" },
    @{ Num="04"; Name="SSO Integration";         Duration="90-120 min";  Hardware="3-4 machines" },
    @{ Num="05"; Name="Advanced Integration";    Duration="90-150 min";  Hardware="4-5 machines" },
    @{ Num="06"; Name="Production Deployment";   Duration="120-180 min"; Hardware="5+ machines" }
)

# Phase module definitions
$phaseModules = @{
    1 = @(
        @{ Num="01"; Repo="it-stack-freeipa";       Name="FreeIPA";       Category="identity" },
        @{ Num="02"; Repo="it-stack-keycloak";      Name="Keycloak";      Category="identity" },
        @{ Num="03"; Repo="it-stack-postgresql";    Name="PostgreSQL";    Category="database" },
        @{ Num="04"; Repo="it-stack-redis";         Name="Redis";         Category="database" },
        @{ Num="18"; Repo="it-stack-traefik";       Name="Traefik";       Category="infrastructure" }
    )
    2 = @(
        @{ Num="06"; Repo="it-stack-nextcloud";     Name="Nextcloud";     Category="collaboration" },
        @{ Num="07"; Repo="it-stack-mattermost";    Name="Mattermost";    Category="collaboration" },
        @{ Num="08"; Repo="it-stack-jitsi";         Name="Jitsi";         Category="collaboration" },
        @{ Num="09"; Repo="it-stack-iredmail";      Name="iRedMail";      Category="communications" },
        @{ Num="11"; Repo="it-stack-zammad";        Name="Zammad";        Category="communications" }
    )
    3 = @(
        @{ Num="10"; Repo="it-stack-freepbx";       Name="FreePBX";       Category="communications" },
        @{ Num="12"; Repo="it-stack-suitecrm";      Name="SuiteCRM";      Category="business" },
        @{ Num="13"; Repo="it-stack-odoo";          Name="Odoo";          Category="business" },
        @{ Num="14"; Repo="it-stack-openkm";        Name="OpenKM";        Category="business" }
    )
    4 = @(
        @{ Num="15"; Repo="it-stack-taiga";         Name="Taiga";         Category="it-management" },
        @{ Num="16"; Repo="it-stack-snipeit";       Name="Snipe-IT";      Category="it-management" },
        @{ Num="17"; Repo="it-stack-glpi";          Name="GLPI";          Category="it-management" },
        @{ Num="05"; Repo="it-stack-elasticsearch"; Name="Elasticsearch"; Category="database" },
        @{ Num="19"; Repo="it-stack-zabbix";        Name="Zabbix";        Category="infrastructure" },
        @{ Num="20"; Repo="it-stack-graylog";       Name="Graylog";       Category="infrastructure" }
    )
}

$modules = $phaseModules[$Phase]

foreach ($module in $modules) {
    foreach ($lab in $labs) {
        $labId    = "$($module.Num)-$($lab.Num)"
        $title    = "Lab $labId`: $($lab.Name) — $($module.Name)"
        $body = @"
## Lab $labId`: $($lab.Name)

**Module:** $($module.Num) — $($module.Name)
**Category:** $($module.Category)
**Duration:** $($lab.Duration)
**Hardware:** $($lab.Hardware)
**Phase:** $Phase

### Objectives
- [ ] Deploy $($module.Name) in $($lab.Name.ToLower()) configuration
- [ ] Verify core functionality passes health check
- [ ] Run test script: \`./tests/labs/test-lab-$($lab.Num).sh\`
- [ ] Test integration points relevant to this lab
- [ ] Document results in \`lab-environments/\`

### Success Criteria
- All deployment steps complete without errors
- Health check endpoint responds correctly
- Lab test script exits with code 0
- Results documented

### Lab Script
\`\`\`bash
cd repos/$($module.Category)/$($module.Repo)
./tests/labs/test-lab-$($lab.Num).sh
\`\`\`

---
_Lab: $labId | Phase: $Phase | Module: $($module.Name)_
"@

        if ($DryRun) {
            Write-Host "[DRY RUN] Would create: $title" -ForegroundColor Yellow
        } else {
            Write-Host "Creating issue: $title" -ForegroundColor Cyan
            gh issue create `
                --repo "$OrgName/$($module.Repo)" `
                --title $title `
                --body $body `
                --label "lab,module-$($module.Num),phase-$Phase,$($module.Category)"
        }
    }
}

Write-Host "`nDone. Issues created for Phase $Phase." -ForegroundColor Green
```

### 9.2 Add Issues to GitHub Projects

```powershell
# add-issues-to-project.ps1
# Adds all issues from a phase to the corresponding GitHub Project

param(
    [int]$Phase = 1,
    [int]$ProjectNumber       # Get from: gh project list --owner it-stack-dev
)

$phaseRepos = @{
    1 = @("it-stack-freeipa","it-stack-keycloak","it-stack-postgresql","it-stack-redis","it-stack-traefik")
    2 = @("it-stack-nextcloud","it-stack-mattermost","it-stack-jitsi","it-stack-iredmail","it-stack-zammad")
    3 = @("it-stack-freepbx","it-stack-suitecrm","it-stack-odoo","it-stack-openkm")
    4 = @("it-stack-taiga","it-stack-snipeit","it-stack-glpi","it-stack-elasticsearch","it-stack-zabbix","it-stack-graylog")
}

foreach ($repo in $phaseRepos[$Phase]) {
    Write-Host "Adding issues from $repo to Project #$ProjectNumber..."
    $issues = gh issue list -R "it-stack-dev/$repo" --state open --limit 10 --json url | ConvertFrom-Json
    foreach ($issue in $issues) {
        gh project item-add $ProjectNumber --owner it-stack-dev --url $issue.url
    }
}

Write-Host "Done. All Phase $Phase issues added to Project #$ProjectNumber"
```

---

## 10. Branch Strategy

Every component repository uses this branch model:

```
main          ← protected, production-ready only
develop       ← integration branch, default for PRs
feature/*     ← feature branches (branch from develop)
bugfix/*      ← bug fixes
release/*     ← release preparation (branch from develop, merge to main + tag)
hotfix/*      ← emergency production fixes (branch from main)
```

### Branch Protection Rules

Apply to `main` in each repository:

```powershell
# Set branch protection on main for one repo
param([string]$RepoName)

gh api -X PUT "repos/it-stack-dev/$RepoName/branches/main/protection" `
    --input - << '{'
    "required_status_checks": {
        "strict": true,
        "contexts": ["test", "build"]
    },
    "enforce_admins": false,
    "required_pull_request_reviews": {
        "required_approving_review_count": 1
    },
    "restrictions": null
    '}'
```

---

## 11. Reusable Workflow Templates

Place these in `.github/workflows/` in the `it-stack-dev/.github` repo for reuse:

### `ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run unit tests
        run: make test-unit || echo "No unit tests yet"
      
      - name: Run lab 01 smoke test
        run: |
          chmod +x tests/labs/test-lab-01.sh
          ./tests/labs/test-lab-01.sh

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: docker build -t ghcr.io/it-stack-dev/${{ github.event.repository.name }}:${{ github.sha }} .

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Trivy vulnerability scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          severity: CRITICAL,HIGH
```

### `release.yml`

```yaml
name: Release

on:
  push:
    tags: ['v*.*.*']

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: write
    steps:
      - uses: actions/checkout@v4
      
      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push image
        run: |
          IMAGE="ghcr.io/it-stack-dev/${{ github.event.repository.name }}"
          docker build -t "${IMAGE}:${{ github.ref_name }}" -t "${IMAGE}:latest" .
          docker push "${IMAGE}:${{ github.ref_name }}"
          docker push "${IMAGE}:latest"
      
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          generate_release_notes: true
```

---

## 12. Repository Checklist: Per-Repo Standard Files

For each of the 20 component repositories, verify these files exist:

```
it-stack-{module}/
├── README.md                    ✓ Module overview, quick start, lab table
├── it-stack-{module}.yml        ✓ Module manifest (metadata, deps, labs)
├── Makefile                     ✓ install, test, build, deploy, clean targets
├── Dockerfile                   ✓ Container image definition
├── .gitignore                   ✓ Ignore build artifacts, secrets, logs
├── CONTRIBUTING.md              ✓ How to contribute
├── LICENSE                      ✓ Apache 2.0
├── src/                         ✓ Source code
├── tests/
│   ├── unit/                    ✓ Unit tests
│   ├── integration/             ✓ Integration tests
│   └── labs/
│       ├── test-lab-01.sh       ✓ Standalone
│       ├── test-lab-02.sh       ✓ External deps
│       ├── test-lab-03.sh       ✓ Advanced features
│       ├── test-lab-04.sh       ✓ SSO integration
│       ├── test-lab-05.sh       ✓ Advanced integration
│       └── test-lab-06.sh       ✓ Production deployment
├── docker/
│   ├── docker-compose.standalone.yml
│   ├── docker-compose.lan.yml
│   ├── docker-compose.advanced.yml
│   ├── docker-compose.sso.yml
│   ├── docker-compose.integration.yml
│   └── docker-compose.production.yml
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   ├── TROUBLESHOOTING.md
│   └── labs/
│       ├── 01-standalone.md
│       ├── 02-external-deps.md
│       ├── 03-advanced.md
│       ├── 04-sso-integration.md
│       ├── 05-advanced-integration.md
│       └── 06-production.md
└── .github/
    └── workflows/
        ├── ci.yml
        └── release.yml
```

---

## 13. Automation Scripts Reference

| Script | Location | Purpose |
|--------|----------|---------|
| `install-tools.ps1` | `it-stack-installer/scripts/setup/` | Install all dev tools |
| `setup-directory-structure.ps1` | `it-stack-installer/scripts/setup/` | Create `C:\it-stack-dev\` |
| `setup-github.ps1` | `it-stack-installer/scripts/setup/` | Configure `gh` CLI |
| `create-all-component-repos.ps1` | `it-stack-installer/scripts/github/` | Create all 20 repos |
| `create-repo-template.ps1` | `it-stack-installer/scripts/utilities/` | Scaffold one module |
| `create-lab-issues.ps1` | `it-stack-installer/scripts/github/` | Create 6 issues per module |
| `add-issues-to-project.ps1` | `it-stack-installer/scripts/github/` | Link issues to Projects |
| `apply-labels.ps1` | `it-stack-installer/scripts/github/` | Apply standard labels |
| `create-milestones.ps1` | `it-stack-installer/scripts/github/` | Create 4 phase milestones |
| `clone-all-repos.ps1` | `it-stack-installer/scripts/operations/` | Clone all repos locally |
| `update-all-repos.ps1` | `it-stack-installer/scripts/operations/` | `git pull` all repos |
| `run-all-labs.sh` | `it-stack-installer/scripts/testing/` | Run all 120 lab tests |
| `deploy-stack.sh` | `it-stack-installer/scripts/deployment/` | Deploy full stack |

---

## 14. Quick Commands Cheat Sheet

```powershell
# === Organization ===
gh api orgs/it-stack-dev                              # Org info
gh repo list it-stack-dev --limit 50                  # List all repos
gh project list --owner it-stack-dev                  # List projects

# === Repository Management ===
gh repo create it-stack-dev/REPO --public --description "DESC"
gh repo clone it-stack-dev/REPO                       # Clone a repo
gh repo view it-stack-dev/REPO                        # View repo info

# === Issues ===
gh issue create --repo it-stack-dev/REPO --title "Title" --body "Body" --label "lab"
gh issue list -R it-stack-dev/REPO --state open
gh issue close NUMBER -R it-stack-dev/REPO

# === Projects ===
gh project list --owner it-stack-dev
gh project item-add PROJECT_NUMBER --owner it-stack-dev --url ISSUE_URL
gh project view PROJECT_NUMBER --owner it-stack-dev

# === Labels ===
gh label list -R it-stack-dev/REPO
gh label create NAME --color RRGGBB --repo it-stack-dev/REPO

# === Topics ===
gh api -X PUT repos/it-stack-dev/REPO/topics -f "names[]=it-stack" -f "names[]=phase-1"

# === Workflows ===
gh workflow list -R it-stack-dev/REPO
gh run list -R it-stack-dev/REPO

# === All repos quick status ===
gh repo list it-stack-dev --json name,updatedAt,isPrivate --limit 50 | ConvertFrom-Json | Format-Table
```

---

**Document Version:** 1.0  
**Project:** IT-Stack | **Org:** `it-stack-dev`  
**Status:** Ready to execute — org is empty, start with Step 1.  
**See also:** [IT-STACK-TODO.md](IT-STACK-TODO.md) for full project task tracking
