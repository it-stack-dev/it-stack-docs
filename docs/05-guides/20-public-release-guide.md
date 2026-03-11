# IT-Stack Public Release Guide

> **Everything needed to announce IT-Stack to the open-source and homelab community.**  
> **Target date:** After local Docker tests confirm passing on all 4 phases.

---

## Table of Contents

1. [Pre-Release Checklist](#1-pre-release-checklist)
2. [GitHub Repository Polish](#2-github-repository-polish)
3. [Documentation Site (GitHub Pages)](#3-documentation-site-github-pages)
4. [Docker Images Publishing](#4-docker-images-publishing)
5. [Community Announcements](#5-community-announcements)
6. [Demo Video Script](#6-demo-video-script)
7. [Press Kit](#7-press-kit)
8. [Post-Release Monitoring](#8-post-release-monitoring)

---

## 1. Pre-Release Checklist

### Minimum Bar (Must-Have Before Any Announcement)

- [ ] All 120 lab tests passing (✅ Azure confirmed — local Docker fixes in progress)
- [ ] All 35 SSO integration tests passing (✅ Azure confirmed)
- [ ] GitHub Pages docs site live and accessible
- [ ] README.md accurate and presentable
- [ ] CHANGELOG.md up to date through v1.41.0
- [ ] LICENSE file present (Apache 2.0 ✅)
- [ ] CONTRIBUTING.md present ✅
- [ ] CODE_OF_CONDUCT.md present ✅
- [ ] SECURITY.md with responsible disclosure contact ✅
- [ ] No secrets / credentials in any repo (Trivy Gitleaks scan clean ✅)
- [ ] `it-stack-docs` README has working "Getting Started" that a new user can follow

### Nice-to-Have for Initial Release

- [ ] Docker Hub images for at least Phase 1 modules (FreeIPA patch image essential)
- [ ] YouTube demo video (5–10 minutes)
- [ ] Screenshots of each web UI in the docs
- [ ] One-command quick start: `curl -fsSL https://get.it-stack.dev | bash`
- [ ] GitHub Discussions enabled
- [ ] Issue templates configured (.github/ISSUE_TEMPLATE/)

---

## 2. GitHub Repository Polish

### 2.1 Repository Description + Topics

For each of the 26 repositories, set description and topics via GitHub CLI:

```bash
# it-stack-docs (main repo)
gh repo edit it-stack-dev/it-stack-docs \
  --description "IT-Stack — Complete enterprise IT infrastructure on open-source. 20 services, SSO, 120 labs. Zero licensing cost." \
  --homepage "https://it-stack-dev.github.io/it-stack-docs/"

# Add topics to all repos
$topics = "enterprise-it,open-source,self-hosted,sso,docker,ansible,freeipa,keycloak,nextcloud,mattermost"
foreach ($repo in @("it-stack-docs","it-stack-ansible","it-stack-installer","it-stack-freeipa","it-stack-keycloak","it-stack-postgresql","it-stack-redis","it-stack-traefik")) {
  gh repo edit "it-stack-dev/$repo" --add-topic $_ 
}
```

### 2.2 README Screenshot Section

Add a screenshots section to `README.md`:

```markdown
## Screenshots

| Service | URL | Screenshot |
|---------|-----|------------|
| FreeIPA | `https://id.it-stack.local` | ![FreeIPA](docs/assets/screenshots/freeipa-admin.png) |
| Keycloak SSO | `https://sso.it-stack.local` | ![Keycloak](docs/assets/screenshots/keycloak-realm.png) |
| Nextcloud | `https://cloud.it-stack.local` | ![Nextcloud](docs/assets/screenshots/nextcloud-files.png) |
| Mattermost | `https://chat.it-stack.local` | ![Mattermost](docs/assets/screenshots/mattermost-channels.png) |
| Odoo ERP | `https://erp.it-stack.local` | ![Odoo](docs/assets/screenshots/odoo-dashboard.png) |
| Zabbix | `https://monitor.it-stack.local` | ![Zabbix](docs/assets/screenshots/zabbix-dashboard.png) |
```

### 2.3 GitHub Issue Templates

Create `.github/ISSUE_TEMPLATE/bug_report.yml` in `it-stack-docs`:

```yaml
name: Bug Report
description: Report a broken lab test, failed deployment, or incorrect documentation
labels: ["bug"]
body:
  - type: dropdown
    id: module
    attributes:
      label: Module
      options: [FreeIPA, Keycloak, PostgreSQL, Redis, Elasticsearch, Nextcloud, Mattermost, Jitsi, iRedMail, FreePBX, Zammad, SuiteCRM, Odoo, OpenKM, Taiga, Snipe-IT, GLPI, Traefik, Zabbix, Graylog, Other]
    validations:
      required: true
  - type: dropdown
    id: lab
    attributes:
      label: Lab Number
      options: ["01 - Standalone", "02 - External Deps", "03 - Advanced", "04 - SSO", "05 - Integration", "06 - Production", "Ansible", "Docker Compose", "Other"]
  - type: textarea
    id: description
    attributes:
      label: What happened?
      placeholder: Describe the issue in detail
    validations:
      required: true
  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
      placeholder: |
        1. Run `lab-phase2.sh --only-zammad`
        2. Container shows unhealthy after 5 minutes
        3. ...
  - type: textarea
    id: environment
    attributes:
      label: Environment
      placeholder: |
        OS: Ubuntu 24.04
        Docker: 29.3.0
        Docker Compose: v5.1.0
        RAM: 16 GB
        Host: Azure Standard_D4s_v4 / local Docker Desktop / bare metal
```

Create `.github/ISSUE_TEMPLATE/feature_request.yml`:

```yaml
name: Feature Request
description: Suggest a new module, integration, or lab improvement
labels: ["enhancement"]
body:
  - type: input
    id: title
    attributes:
      label: Feature Summary
    validations:
      required: true
  - type: textarea
    id: motivation
    attributes:
      label: Why is this needed?
      placeholder: What problem does this solve for IT-Stack users?
  - type: textarea
    id: proposal
    attributes:
      label: Proposed Implementation
      placeholder: How should this work? Any specific services, APIs, or configs involved?
```

### 2.4 GitHub Discussions Setup

```bash
# Enable Discussions on the main repo
gh repo edit it-stack-dev/it-stack-docs --enable-discussions

# Create initial discussion categories via GitHub web UI:
# Announcements (pinned)
# Q&A (users asking questions)
# Show and Tell (community deployments)
# Ideas (feature requests)
# General
```

---

## 3. Documentation Site (GitHub Pages)

### 3.1 Verify GitHub Pages Status

```bash
# Check if docs.yml workflow is running
gh workflow list --repo it-stack-dev/it-stack-docs
gh run list --repo it-stack-dev/it-stack-docs --workflow docs.yml --limit 3
```

Expected output:
```
NAME    STATUS     CONCLUSION  WORKFLOW    BRANCH  EVENT  ID
Build   completed  success     Docs (MkDocs Material)  main  push  12345
```

### 3.2 MkDocs Configuration Polish

Ensure `mkdocs.yml` has the Material theme with all features:

```yaml
site_name: IT-Stack Documentation
site_description: Complete enterprise IT infrastructure on open-source
site_url: https://it-stack-dev.github.io/it-stack-docs/
repo_url: https://github.com/it-stack-dev/it-stack-docs
repo_name: it-stack-dev/it-stack-docs

theme:
  name: material
  palette:
    - scheme: default
      primary: indigo
      accent: blue
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - scheme: slate
      primary: indigo
      accent: blue
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - navigation.top
    - search.highlight
    - search.share
    - content.code.copy

plugins:
  - search
  - minify:
      minify_html: true

markdown_extensions:
  - admonition
  - pymdownx.details
  - pymdownx.superfences
  - pymdownx.highlight
  - pymdownx.inlinehilite
  - tables
  - toc:
      permalink: true
```

### 3.3 Docs Site Navigation

Ensure `mkdocs.yml` `nav:` section includes all new guides:

```yaml
nav:
  - Home: index.md
  - Architecture:
    - Overview: 07-architecture/README.md
    - Network Topology: 07-architecture/network-topology.md
    - Service Integration Map: 07-architecture/service-integration-map.md
    - ADRs: 07-architecture/adr-001-identity-stack.md
  - Deployment:
    - Hardware Deployment Guide: 05-guides/19-hardware-deployment-guide.md
    - Azure Lab Deployment: 05-guides/18-azure-lab-deployment.md
    - Lab Manual Part 1: 03-labs/07-lab-manual-part1.md
    - Lab Manual Part 2: 03-labs/08-lab-manual-part2.md
    - Lab Manual Part 3: 03-labs/09-lab-manual-part3.md
    - Lab Manual Part 4: 03-labs/10-lab-manual-part4.md
    - Lab Manual Part 5: 03-labs/11-lab-manual-part5.md
  - Guides:
    - Master Index: 05-guides/01-master-index.md
    - User Onboarding: 05-guides/16-user-onboarding.md
    - Admin Runbook: 05-guides/17-admin-runbook.md
    - On-Call Policy: 05-guides/18-on-call-policy.md
    - Public Release Guide: 05-guides/20-public-release-guide.md
  - Troubleshooting:
    - Production Guide: 05-guides/21-production-troubleshooting.md
    - Complete Issue History: 06-technical-reference/troubleshooting-complete.md
  - Reference:
    - Integration Guide: 02-implementation/12-integration-guide.md
    - Capacity Planning: 02-implementation/15-capacity-planning.md
    - Test Suite: 06-technical-reference/test-suite.md
  - Contributing:
    - How to Contribute: contributing/framework-template.md
    - TODO: IT-STACK-TODO.md
```

---

## 4. Docker Images Publishing

### 4.1 GHCR (GitHub Container Registry) — Recommended

Each module repo already has CI workflows. Add a publish step to the release workflow:

```yaml
# .github/workflows/release.yml (in each module repo)
- name: Build and push Docker image
  uses: docker/build-push-action@v5
  with:
    context: .
    push: true
    tags: |
      ghcr.io/it-stack-dev/it-stack-${{ env.MODULE }}:latest
      ghcr.io/it-stack-dev/it-stack-${{ env.MODULE }}:${{ github.ref_name }}
    labels: |
      org.opencontainers.image.source=${{ github.server_url }}/${{ github.repository }}
      org.opencontainers.image.description=IT-Stack ${{ env.MODULE }} module
      org.opencontainers.image.licenses=Apache-2.0
```

### 4.2 Critical Image: FreeIPA Patched

The custom FreeIPA image (with cgroupv2 and PrivateTmp patches) is essential. Publish it first:

```bash
# Build and push to GHCR
cd it-stack-dev/scripts/testing/freeipa-patch/
docker build -t ghcr.io/it-stack-dev/it-stack-freeipa:almalinux-9 .
docker push ghcr.io/it-stack-dev/it-stack-freeipa:almalinux-9
```

---

## 5. Community Announcements

### 5.1 r/selfhosted

**Title:**
```
[Project] IT-Stack: Complete open-source enterprise IT platform (20 services, SSO, zero licensing cost) — 120 lab tests passing
```

**Body:**
```markdown
I've been building IT-Stack for the past few months: a fully documented, 
production-tested, open-source replacement for the enterprise software stack 
most organizations pay millions for.

**What it replaces (100 users, annual savings estimate):**
- Microsoft 365 → Nextcloud + iRedMail (~$24K/yr)
- Slack/Teams → Mattermost (~$15K/yr)  
- Zoom → Jitsi (~$24K/yr)
- Salesforce → SuiteCRM (~$90K/yr)
- SAP/QuickBooks → Odoo (~$50K/yr)
- RingCentral → FreePBX (~$36K/yr)
- ServiceNow → GLPI + Zammad (~$120K/yr)
- Jira → Taiga (~$12K/yr)
- Active Directory → FreeIPA + Keycloak (~$10K/yr)
- Datadog/Splunk → Zabbix + Graylog (~$25K/yr)

**Total: ~$406K/yr at 100 users, ~$2M over 5 years**

**What's included:**
- 8-server Ubuntu 24.04 reference architecture (10.0.50.0/24)
- 20 modules, each with 6-lab testing progression (120 labs total)
- Ansible playbooks for automated deployment
- Full SSO via FreeIPA LDAP + Keycloak (all 9 user-facing services)
- 23 cross-service business integrations
- CI/CD, security scanning, backup, monitoring, alerting
- ~600 pages of documentation

**All 120 labs pass on Azure Standard_D4s_v4 (Ubuntu 24.04, Docker 29.x)**

GitHub: https://github.com/it-stack-dev/it-stack-docs
Docs: https://it-stack-dev.github.io/it-stack-docs/
```

### 5.2 r/homelab

**Title:**
```
I documented a complete enterprise IT stack replacement — 20 services, SSO, 120 lab tests, Apache 2.0
```

**Body:** (lighter tone, focus on homelab aspect)
```markdown
Been working on this for months: a complete, documented, tested enterprise 
IT platform that you can actually deploy at home or for a small/medium organization.

The goal was "what would it take to replace every commercial IT tool 
with open-source, and actually document it properly?"

**Result:** IT-Stack — 20 services across 8 servers, all connected with SSO 
(FreeIPA LDAP → Keycloak → all apps), 120 lab test scripts, Ansible playbooks 
for deployment, and every integration tested end-to-end.

Key features for homelabbers:
- Each service has a "Lab 01 Standalone" — just Docker Compose, no dependencies
- Scales from 1-server all-in-one to 8-server enterprise split
- Full Ansible automation — `ansible-playbook playbooks/deploy-nextcloud.yml` and you're done
- FreeIPA + Keycloak gives you proper Active Directory replacement with real SSO

GitHub org: https://github.com/it-stack-dev (26 repos)
Main docs: https://github.com/it-stack-dev/it-stack-docs
```

### 5.3 Hacker News (Show HN)

```
Show HN: IT-Stack – open-source enterprise IT platform (20 services, zero licensing)
https://github.com/it-stack-dev/it-stack-docs

Six months of work to document, automate, and test a complete enterprise IT 
platform using only open-source software. 20 services in 7 layers 
(Identity→DB→Collaboration→Comms→Business→IT Mgmt→Infrastructure), 
all connected with FreeIPA LDAP and Keycloak SSO.

120 automated lab tests pass on Ubuntu 24.04 / Docker 29.x. 
Full Ansible automation for all 20 services. 23 cross-service integrations 
(click-to-call, CRM-calendar sync, log-triggered alerts, etc.).

Targets 50–1,000 users on 8 servers. Apache 2.0.
```

### 5.4 Dev.to Article

**Title:** "Building a $0 Microsoft 365 + Salesforce + ServiceNow Replacement (Full Stack, 120 Tests)"

**Outline:**
1. The problem: enterprise software licensing is expensive
2. The architecture (diagram)
3. Phase 1: Identity foundation (FreeIPA + Keycloak)
4. The SSO connection (how all 20 services authenticate through one identity)
5. The testing methodology (6 labs per module, 120 total)
6. Key lessons: Docker healthchecks, Alpine vs curl, FreePBX module install times
7. What's next: Kubernetes/Helm migration

---

## 6. Demo Video Script

**Duration:** 8–10 minutes

### Scene 1: The Problem (0:00–1:00)
- Show a typical org's SaaS bill: $200K/year for 50 users
- "What if you could replace all of it with open-source for the cost of servers?"

### Scene 2: Architecture Overview (1:00–2:00)
- Screen share: 7-layer architecture diagram
- "8 servers, 20 services, all connected with SSO"

### Scene 3: SSO Demo (2:00–4:00)
- Log in to FreeIPA, create user "demo-user"
- Open Nextcloud → login with SSO → works
- Open Mattermost → login with SSO → same session
- Open Odoo → login with SSO → same session
- "One login, every app"

### Scene 4: Collaboration Demo (4:00–5:30)
- Create a file in Nextcloud
- Reference it in a Mattermost message
- Start a Jitsi video call from Mattermost
- "Like Microsoft 365, but yours"

### Scene 5: IT Management Demo (5:30–7:00)
- Create a Zammad ticket (helpdesk request)
- Ticket auto-escalates to GLPI ITSM
- Zabbix shows infrastructure monitoring
- Graylog shows live log streams

### Scene 6: Deployment Demo (7:00–9:00)
- `ansible-playbook -i inventory/production.yml playbooks/deploy-nextcloud.yml`
- Watch Nextcloud install in 3 minutes
- "20 services, all installable like this"

### Scene 7: Call to Action (9:00–10:00)
- Show GitHub organization (26 repos)
- Show documentation site
- "Apache 2.0 — fork it, deploy it, contribute back"

---

## 7. Press Kit

### Elevator Pitch (50 words)
> IT-Stack is a fully documented, production-tested, open-source replacement for every enterprise IT tool — file sharing, chat, video, email, VoIP, CRM, ERP, helpdesk, monitoring, and identity management. 20 services, 120 automated tests, Ansible deployment, full SSO. Zero licensing cost.

### One-Liner
> "Replaces Microsoft 365, Salesforce, Slack, Zoom, ServiceNow, and 5 others — for $0 in software licensing."

### Key Numbers
- **20** integrated open-source services
- **8** Ubuntu 24.04 servers
- **120** passing lab tests
- **35** passing SSO integration tests
- **23** cross-service business integrations
- **$2M** 5-year TCO savings at 100 users
- **0** licensing cost
- **Apache 2.0** license

### Technology Stack Summary
```
Identity:      FreeIPA + Keycloak
Database:      PostgreSQL + Redis + Elasticsearch
Collaboration: Nextcloud + Mattermost + Jitsi
Communications:iRedMail + FreePBX + Zammad
Business:      SuiteCRM + Odoo + OpenKM
IT Management: Taiga + Snipe-IT + GLPI
Infrastructure:Traefik + Zabbix + Graylog
Automation:    Ansible + Docker Compose + GitHub Actions
```

---

## 8. Post-Release Monitoring

### GitHub Stars / Issues Tracking

```bash
# Check stats
gh repo view it-stack-dev/it-stack-docs --json stargazerCount,forkCount,openIssues
```

### Engagement Checklist (First 72 Hours)

- [ ] Reply to all comments on r/selfhosted post within 24 hours
- [ ] Reply to all HN comments within 12 hours
- [ ] Respond to any GitHub issues opened
- [ ] Merge any quick documentation PRs
- [ ] Track if any forks are created (sign of real interest)

### Community Health Signals

| Signal | Low (OK for v1) | Good | Excellent |
|--------|----------------|------|-----------|
| GitHub Stars | 10+ | 100+ | 1,000+ |
| Forks | 1+ | 10+ | 50+ |
| Issues opened | 0 | 5–15 (mostly questions) | 20+ (community engaged) |
| r/selfhosted upvotes | 25+ | 200+ | 500+ |
| HN front page | – | 50 points | 200+ points |

---

*Document version: 1.0 — 2026-03-11 — IT-Stack Public Release Guide*
