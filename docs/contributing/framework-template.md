# IT-Stack Project Framework
## Enterprise Open-Source IT Infrastructure — Implementation Blueprint

> **Project:** `it-stack` | **GitHub Org:** [`it-stack-dev`](https://github.com/it-stack-dev) | **Last Updated:** February 27, 2026
>
> **Purpose:** This document captures every structural pattern, convention, automation, and methodology for the IT-Stack project — a complete open-source enterprise IT infrastructure stack replacing Microsoft 365, Salesforce, SAP, RingCentral, and ServiceNow at zero software licensing cost.
>
> **Stack:** FreeIPA · Keycloak · PostgreSQL · Nextcloud · Mattermost · Jitsi · iRedMail · FreePBX · Zammad · SuiteCRM · Odoo · OpenKM · Taiga · Snipe-IT · GLPI · Traefik · Zabbix · Graylog

---

## Table of Contents

1. [Framework Overview](#1-framework-overview)
2. [GitHub Organization Structure](#2-github-organization-structure)
3. [Repository Naming & Template](#3-repository-naming--template)
4. [Module Manifest (project.yml)](#4-module-manifest-projectyml)
5. [Documentation Architecture](#5-documentation-architecture)
6. [Lab Testing Framework (6-Lab Progression)](#6-lab-testing-framework-6-lab-progression)
7. [Local Development Environment](#7-local-development-environment)
8. [Deployment Tiers & Environments](#8-deployment-tiers--environments)
9. [Configuration Management](#9-configuration-management)
10. [Automation Scripts](#10-automation-scripts)
11. [GitHub Projects & Phased Roadmap](#11-github-projects--phased-roadmap)
12. [AI Assistant Instructions (claude.md)](#12-ai-assistant-instructions-claudemd)
13. [CI/CD & Workflows](#13-cicd--workflows)
14. [Development Workflows & Conventions](#14-development-workflows--conventions)
15. [Code Review Checklist](#15-code-review-checklist)
16. [Shell Aliases & Developer Experience](#16-shell-aliases--developer-experience)
17. [Quick Start: Setting Up a New Project](#17-quick-start-setting-up-a-new-project)
18. [Appendix: Complete File Templates](#18-appendix-complete-file-templates)

---

## 1. Framework Overview

### Philosophy

This framework is built on these principles:

- **Modular by default** — Every component is an independent module with its own repository
- **Test small, build confidence, integrate, repeat** — Progressive lab testing from standalone to production
- **One module = one repo = one manifest = 6 labs** — Uniform structure everywhere
- **Categorize everything** — Modules grouped into thematic categories
- **Automate everything** — Scripts for repo creation, issue management, directory setup, deployment
- **Document everything** — Numbered documents, lab databases, architecture references
- **AI-assisted development** — A `claude.md` (or equivalent) file gives AI assistants full project context

### Scale Pattern

| Element | D-Central Example | Your Project |
|---------|------------------|--------------|
| Modules | 126 | **20** |
| Categories | 17 | **7** |
| Labs per module | 6 | 6 (universal) |
| Total labs | 756 | **120** |
| GitHub repos | 132 (6 meta + 126 component) | **26 (6 meta + 20 component)** |
| Documentation docs | 30+ numbered documents | Scale as needed |
| Deployment tiers | 4 (home → school → neighborhood → district) | Define your own tiers |

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Module** | A self-contained component with its own repo, tests, docs, and deployment configs |
| **Category** | A thematic grouping of related modules (e.g., "Identity", "Storage") |
| **Lab** | A hands-on test exercise that validates a module at a specific complexity level |
| **Lab Progression** | The 6-step journey from standalone (Lab 01) to production HA (Lab 06) |
| **Tier** | A deployment scale level (e.g., 1-5 nodes, 5-10 nodes, 10-50 nodes, 50+) |
| **Phase** | A time-boxed implementation milestone containing a set of modules to build |
| **Manifest** | A YAML file (`it-stack.yml`) declaring module metadata, dependencies, deployment, and testing |

---

## 2. GitHub Organization Structure

### Organization-Level Setup

```
github.com/it-stack-dev/
│
├── .github/                         # Organization-level defaults
│   ├── profile/
│   │   └── README.md                # Organization profile (shown on org page)
│   ├── CONTRIBUTING.md              # Default contributing guidelines
│   ├── CODE_OF_CONDUCT.md           # Code of conduct
│   ├── SECURITY.md                  # Security policy
│   └── workflows/                   # Reusable GitHub Actions workflows
│       ├── ci.yml                   # Standard CI workflow
│       ├── release.yml              # Release workflow
│       ├── security-scan.yml        # Security scanning
│       └── docker-build.yml         # Docker image build
│
├── it-stack-installer               # Meta: Automated installer / bootstrap scripts
├── it-stack-docs                    # Meta: Full documentation set (this repo)
├── it-stack-testing                 # Meta: Integration & e2e testing suite
├── it-stack-ansible                 # Meta: Ansible playbooks for all services
├── it-stack-terraform               # Meta: Terraform modules collection
├── it-stack-helm                    # Meta: Helm charts collection
│
│   ── Category 01: Identity & Authentication ──
├── it-stack-freeipa                 # 01 · Identity Provider (LDAP/Kerberos/DNS)
├── it-stack-keycloak                # 02 · SSO / OAuth2 / OIDC / SAML Broker
│
│   ── Category 02: Database & Cache ──
├── it-stack-postgresql              # 03 · Relational Database (10+ service DBs)
├── it-stack-redis                   # 04 · In-Memory Cache & Session Store
├── it-stack-elasticsearch           # 05 · Search Engine & Log Index
│
│   ── Category 03: Collaboration ──
├── it-stack-nextcloud               # 06 · File Share, Office, Calendar (→ M365)
├── it-stack-mattermost              # 07 · Team Chat & DevOps Notifications (→ Slack)
├── it-stack-jitsi                   # 08 · Video Conferencing (→ Zoom)
│
│   ── Category 04: Communications ──
├── it-stack-iredmail                # 09 · Email Server MTA/MDA (→ Exchange)
├── it-stack-freepbx                 # 10 · VoIP PBX / IVR / Call Queues (→ RingCentral)
├── it-stack-zammad                  # 11 · Help Desk & Ticketing (→ Zendesk)
│
│   ── Category 05: Business Systems ──
├── it-stack-suitecrm                # 12 · CRM & Sales Pipeline (→ Salesforce)
├── it-stack-odoo                    # 13 · ERP (HR/Finance/Inventory) (→ SAP)
├── it-stack-openkm                  # 14 · Document Management System (→ SharePoint)
│
│   ── Category 06: IT & Project Management ──
├── it-stack-taiga                   # 15 · Agile Project Management (→ Jira)
├── it-stack-snipeit                 # 16 · IT Asset Management & Lifecycle
├── it-stack-glpi                    # 17 · IT Service Management / CMDB
│
│   ── Category 07: Infrastructure ──
├── it-stack-traefik                 # 18 · Reverse Proxy, TLS Termination, Routing
├── it-stack-zabbix                  # 19 · Infrastructure Monitoring & Alerting
└── it-stack-graylog                 # 20 · Centralized Log Management
```

### Naming Convention

**Pattern:** `it-stack-{component-name}` (kebab-case)

**Rules:**
- Always prefix with project name: `it-stack-`
- Use kebab-case for component names
- Keep names descriptive but concise
- Use the same name in the repo, Docker image, Helm chart, and Kubernetes namespace

**IT-Stack Examples:**
- `it-stack-freeipa`
- `it-stack-keycloak`
- `it-stack-nextcloud`
- `it-stack-postgresql`
- `it-stack-freepbx`
- `it-stack-suitecrm`

### Repository Types

| Type | Count | Purpose | Naming |
|------|-------|---------|--------|
| Meta | 6 | Cross-cutting infrastructure (installer, docs, testing, IaC) | `it-stack-{purpose}` |
| Component | 20 | One per module, contains all code/config/tests/docs for that module | `it-stack-{module-name}` |

### Category Organization

Define your categories and assign modules. Each category gets:
- A directory in the local workspace: `repos/{category-name}/`
- A documentation spec: `docs/01-core/{NN}-{category-name}.md`
- A lab database section
- A GitHub Project or label

**IT-Stack Category Definitions:**

```yaml
categories:
  01-identity:
    name: "Identity & Authentication"
    description: "Central authentication, SSO, directory, and authorization"
    modules:
      - it-stack-freeipa      # 01 · LDAP/Kerberos/DNS
      - it-stack-keycloak     # 02 · SSO Broker

  02-database:
    name: "Database & Cache"
    description: "Persistent storage, caching, and search indexing"
    modules:
      - it-stack-postgresql   # 03 · Relational DB
      - it-stack-redis        # 04 · Cache / Session Store
      - it-stack-elasticsearch # 05 · Search & Log Index

  03-collaboration:
    name: "Collaboration"
    description: "File sharing, team chat, and video conferencing"
    modules:
      - it-stack-nextcloud    # 06 · Files/Office/Calendar
      - it-stack-mattermost   # 07 · Team Chat
      - it-stack-jitsi        # 08 · Video Conferencing

  04-communications:
    name: "Communications"
    description: "Email, VoIP/PBX, and help desk ticketing"
    modules:
      - it-stack-iredmail     # 09 · Email Server
      - it-stack-freepbx      # 10 · VoIP / PBX
      - it-stack-zammad       # 11 · Help Desk

  05-business:
    name: "Business Systems"
    description: "CRM, ERP, and Document Management"
    modules:
      - it-stack-suitecrm     # 12 · CRM / Sales
      - it-stack-odoo         # 13 · ERP (HR/Finance)
      - it-stack-openkm       # 14 · Document Management

  06-it-management:
    name: "IT & Project Management"
    description: "Project tracking, asset management, ITSM"
    modules:
      - it-stack-taiga        # 15 · Agile Project Mgmt
      - it-stack-snipeit      # 16 · Asset Management
      - it-stack-glpi         # 17 · IT Service Management

  07-infrastructure:
    name: "Infrastructure"
    description: "Reverse proxy, monitoring, and log management"
    modules:
      - it-stack-traefik      # 18 · Reverse Proxy / TLS
      - it-stack-zabbix       # 19 · Infrastructure Monitoring
      - it-stack-graylog      # 20 · Log Management
```

### GitHub Topics (Tags)

Apply consistent topics to every repository for discoverability:

```
it-stack               # Always present
{category-name}        # e.g. identity, database, collaboration, communications,
                       #      business, it-management, infrastructure
module-{NN}            # e.g. module-01 through module-20
phase-{N}              # e.g. phase-1 through phase-4
open-source
self-hosted
v1.0
```

---

## 3. Repository Naming & Template

### Standard Repository Structure

Every module repository follows this exact structure:

```
{project-name}-{module}/
│
├── src/                             # Source code
│   ├── main application code
│   └── (language-specific structure)
│
├── tests/                           # All tests
│   ├── unit/                        # Unit tests
│   ├── integration/                 # Integration tests
│   ├── e2e/                         # End-to-end tests
│   └── labs/                        # Lab test scripts
│       ├── test-lab-01.sh           # Standalone test
│       ├── test-lab-02.sh           # External dependencies test
│       ├── test-lab-03.sh           # Advanced features test
│       ├── test-lab-04.sh           # SSO integration test
│       ├── test-lab-05.sh           # Advanced integration test
│       └── test-lab-06.sh           # Production deployment test
│
├── docker/                          # Docker configurations
│   ├── docker-compose.standalone.yml    # Lab 01
│   ├── docker-compose.lan.yml           # Lab 02
│   ├── docker-compose.advanced.yml      # Lab 03
│   ├── docker-compose.sso.yml           # Lab 04
│   ├── docker-compose.did.yml           # Lab 05
│   └── docker-compose.production.yml    # Lab 06
│
├── kubernetes/                      # Kubernetes manifests
│   ├── base/                        # Base manifests (Kustomize)
│   └── overlays/
│       ├── dev/
│       ├── staging/
│       └── production/
│
├── helm/                            # Helm chart
│   └── templates/
│
├── ansible/                         # Ansible automation
│   ├── roles/
│   └── playbooks/
│
├── docs/                            # Module documentation
│   ├── ARCHITECTURE.md              # Architecture overview
│   ├── API.md                       # API documentation
│   ├── DEPLOYMENT.md                # Deployment guide
│   ├── TROUBLESHOOTING.md           # Troubleshooting guide
│   └── labs/                        # Lab guides
│       ├── 01-standalone.md
│       ├── 02-external-deps.md
│       ├── 03-advanced.md
│       ├── 04-sso-integration.md
│       ├── 05-advanced-integration.md
│       └── 06-production.md
│
├── .github/                         # GitHub-specific
│   └── workflows/
│       ├── ci.yml                   # CI pipeline
│       └── release.yml              # Release pipeline
│
├── {project-name}.yml               # Module manifest (see Section 4)
├── Makefile                         # Build automation
├── Dockerfile                       # Container image
├── .gitignore                       # Git ignore rules
├── CONTRIBUTING.md                  # Contributing guidelines
├── LICENSE                          # License file
└── README.md                        # Module README
```

### README.md Template

```markdown
# {project-name}-{module-name}

{Brief description of what this module does}

## Overview

This module is part of the {Project Name} ecosystem.

**Category:** {Category Name}
**Status:** Development
**Version:** 0.1.0

## Quick Start

\`\`\`bash
git clone https://github.com/{org-name}/{project-name}-{module-name}.git
cd {project-name}-{module-name}
./tests/labs/test-lab-01.sh
\`\`\`

## Lab Tests

| Lab | Name | Duration | Hardware |
|-----|------|----------|----------|
| 01 | Standalone Deployment | 30-60 min | 1 machine |
| 02 | External Dependencies | 45-90 min | 2-3 machines |
| 03 | Advanced Features | 60-120 min | 2-3 machines |
| 04 | SSO Integration | 90-120 min | 3-4 machines |
| 05 | Advanced Integration | 90-150 min | 4-5 machines |
| 06 | Production Deployment | 120-180 min | 5+ machines |

## Development

\`\`\`bash
make install     # Install dependencies
make test        # Run all tests
make build       # Build Docker image
make deploy      # Deploy locally
\`\`\`

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [API Documentation](docs/API.md)
- [Lab Guides](docs/labs/)

## License

Apache 2.0
```

### Makefile Template

```makefile
.PHONY: help install test build deploy clean

MODULE_NAME = {module-name}
IMAGE_NAME = {project-name}-$(MODULE_NAME)

help:
	@echo "Available targets:"
	@echo "  install       - Install dependencies"
	@echo "  test          - Run all tests"
	@echo "  test-unit     - Run unit tests"
	@echo "  test-lab-NN   - Run specific lab test (01-06)"
	@echo "  build         - Build Docker image"
	@echo "  deploy        - Deploy locally"
	@echo "  clean         - Clean build artifacts"

install:
	@echo "Installing dependencies..."

test: test-unit test-integration

test-unit:
	@echo "Running unit tests..."

test-integration:
	@echo "Running integration tests..."

test-lab-%:
	@echo "Running lab $* test..."
	./tests/labs/test-lab-$*.sh

build:
	docker build -t $(IMAGE_NAME):latest .

deploy:
	docker-compose -f docker/docker-compose.standalone.yml up -d

clean:
	docker-compose -f docker/docker-compose.standalone.yml down
```

---

## 4. Module Manifest (`it-stack.yml`)

Every module has a manifest file at the repository root. This provides machine-readable metadata about the module.

### Complete Manifest Template

```yaml
module:
  name: {module-name}
  version: "0.1.0"
  description: "{Brief description}"
  category: {category-name}
  tier: development    # development | testing | staging | production
  
  authors:
    - name: "{Team Name}"
      email: "{email}"
  
  license: "Apache-2.0"
  
  repository:
    type: git
    url: "https://github.com/{org-name}/{project-name}-{module-name}"

# --- Dependencies ---
dependencies:
  required:
    - name: "{dependency-module}"
      version: ">=1.0.0"
      description: "Why this dependency is required"
  optional:
    - name: "{optional-module}"
      version: ">=0.5.0"
      description: "What this enables"

# --- Deployment ---
deployment:
  docker:
    image: "ghcr.io/{org-name}/{project-name}-{module-name}"
    tags:
      - latest
      - "0.1.0"
  
  kubernetes:
    chart: "helm/{project-name}-{module-name}"
    namespace: "{project-name}-{category}"
  
  ports:
    - name: http
      port: 8080
      protocol: TCP
    - name: metrics
      port: 9090
      protocol: TCP
  
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"
    limits:
      cpu: "2000m"
      memory: "2Gi"

# --- Configuration ---
configuration:
  environment:
    - name: LOG_LEVEL
      default: "info"
      description: "Logging verbosity"
    - name: PORT
      default: "8080"
      description: "Service port"

# --- Testing ---
testing:
  unit: "make test-unit"
  integration: "make test-integration"
  
  labs:
    - number: "01"
      name: "Standalone Deployment"
      duration: "30-60m"
    - number: "02"
      name: "External Dependencies"
      duration: "45-90m"
    - number: "03"
      name: "Advanced Features"
      duration: "60-120m"
    - number: "04"
      name: "SSO Integration"
      duration: "90-120m"
    - number: "05"
      name: "Advanced Integration"
      duration: "90-150m"
    - number: "06"
      name: "Production Deployment"
      duration: "120-180m"

# --- Monitoring ---
monitoring:
  metrics:
    endpoint: "/metrics"
    port: 9090
  healthcheck:
    endpoint: "/health"
    interval: 10s
    timeout: 5s

# --- Integration ---
integration:
  provides:
    - type: "api"
      description: "REST API for {purpose}"
      port: 8080
  requires:
    - type: "database"
      description: "PostgreSQL database"
      module: "{project-name}-postgresql"
```

---

## 5. Documentation Architecture

### Numbered Document System

All project documentation uses numbered documents organized in categorized folders. This provides:
- Clear referencing (e.g., "See Document 28")
- Priority ordering
- Complete coverage tracking

### Documentation Directory Structure

```
docs/
├── 01-core/                         # Category specification documents
│   ├── 01-{category-1-name}.md      # One doc per category
│   ├── 02-{category-2-name}.md      # Detailed architecture, components,
│   ├── 03-{category-3-name}.md      # integration points, configuration
│   └── ...                          # for each category
│
├── 02-implementation/               # Implementation guides
│   ├── {N}-practical-implementation-roadmap.md
│   ├── {N}-tier-1-deployment-guide.md
│   ├── {N}-tier-2-deployment-guide.md
│   └── {N}-integration-guide.md
│
├── 03-labs/                         # Lab testing documentation
│   ├── {N}-modular-lab-testing-framework.md    # Framework definition
│   ├── {N}-complete-lab-database.md             # All labs catalog
│   ├── {N}-lab-database-part1.md                # Split for large DBs
│   ├── {N}-lab-database-part2.md
│   ├── {N}-category-XX-{name}-all-labs.md       # Per-category lab details
│   └── {N}-MASTER-LAB-INDEX.md                  # Master index
│
├── 04-github/                       # GitHub organization docs
│   ├── {N}-github-organization-structure.md     # Repo architecture
│   ├── {N}-github-setup-automation.md           # Setup scripts
│   ├── projects/                                # GitHub Projects guides
│   │   ├── projects-setup.md
│   │   ├── projects-views-guide.md
│   │   └── projects-troubleshooting.md
│   └── setup/                                   # Setup guides
│       └── repo-creation-guide.md
│
├── 05-guides/                       # Organization guides
│   ├── {N}-master-organization-guide.md         # PRIMARY REFERENCE
│   ├── {N}-ai-assistant-instructions.md         # Source for claude.md
│   └── status-reports/
│
├── 06-technical-reference/          # Deep technical docs
│   ├── authentication/
│   ├── infrastructure/
│   └── systems/
│
└── 07-architecture/                 # Architecture diagrams & decisions
    ├── adr/                         # Architecture Decision Records
    └── diagrams/
```

### Document Numbering Convention

- **Docs 01-{N}:** Category specification documents (one per category)
- **Docs {N+1}-{M}:** Implementation & deployment guides
- **Docs {M+1}-{P}:** Lab testing framework & databases
- **Docs {P+1}-{Q}:** GitHub organization & automation
- **Docs {Q+1}-{R}:** Master guides & AI instructions

### Priority Reading Order

When onboarding or orienting:
1. **Master Organization Guide** — Overall structure, how everything fits together
2. **Category Specification Documents** — Detailed module architecture per category
3. **Lab Database** — Testing procedures and validation
4. **GitHub Structure** — Repository organization
5. **Architecture Documents** — Deep technical details

---

## 6. Lab Testing Framework (6-Lab Progression)

### Core Concept

Every module in the project has **exactly 6 labs** that progress from simple to complex. This is the universal testing methodology.

### The 6 Labs

| Lab | Name | Duration | Hardware | Purpose |
|-----|------|----------|----------|---------|
| **XX-01** | Standalone | 30-60 min | 1 machine | Basic functionality in complete isolation. No external dependencies. |
| **XX-02** | External Dependencies | 45-90 min | 2-3 machines | Network integration — external database, storage, services on other machines. |
| **XX-03** | Advanced Features | 60-120 min | 2-3 machines | Production features enabled — performance, scaling, advanced configuration. |
| **XX-04** | SSO Integration | 90-120 min | 3-4 machines | Central authentication — SSO, OIDC/OAuth2, identity provider integration. |
| **XX-05** | Advanced Integration | 90-150 min | 4-5 machines | Deep ecosystem integration — multi-module composition, advanced auth. |
| **XX-06** | Production Deployment | 120-180 min | 5+ machines | High availability cluster — HA, monitoring, disaster recovery, load testing. |

### Lab Numbering

**Format:** `XX-YY`
- `XX` = Module number (01, 02, ... N)
- `YY` = Lab number (01-06)

**Examples:**
- `01-01` = Module 1, Standalone
- `01-06` = Module 1, Production
- `25-04` = Module 25, SSO Integration

### Lab Progression Logic

```
Lab 01: Can it run at all? (standalone, single machine)
    ↓
Lab 02: Can it talk to external services? (network, multi-machine)
    ↓
Lab 03: Can it handle production features? (performance, advanced config)
    ↓
Lab 04: Can it authenticate via central SSO? (identity integration)
    ↓
Lab 05: Can it integrate deeply with the ecosystem? (multi-module)
    ↓
Lab 06: Can it run in production? (HA, monitoring, DR)
```

### Lab Test Script Template

Every lab has a test script at `tests/labs/test-lab-XX.sh`:

```bash
#!/bin/bash
# Lab {MODULE_NUMBER}-{LAB_NUMBER}: {Lab Name} - {Module Name}
# Duration: {duration}
# Hardware: {hardware requirements}

set -e

MODULE="{module-name}"
LAB="{lab-number}"
COMPOSE_FILE="docker/docker-compose.{lab-type}.yml"

echo "================================================================"
echo "  Lab $LAB: {Lab Name}"
echo "  Module: $MODULE"
echo "================================================================"

# --- PHASE 1: Setup ---
echo "[1/4] Setting up environment..."
docker-compose -f $COMPOSE_FILE up -d
sleep 10

# --- PHASE 2: Health Check ---
echo "[2/4] Verifying deployment..."
# Check that containers are running
docker-compose -f $COMPOSE_FILE ps
# Check health endpoint
curl -sf http://localhost:8080/health || { echo "✗ Health check failed"; exit 1; }
echo "✓ Health check passed"

# --- PHASE 3: Functional Tests ---
echo "[3/4] Running functional tests..."
# Add module-specific test commands here
echo "✓ Functional tests passed"

# --- PHASE 4: Cleanup ---
echo "[4/4] Cleaning up..."
docker-compose -f $COMPOSE_FILE down -v

echo ""
echo "================================================================"
echo "  ✓ Lab $LAB PASSED"
echo "================================================================"
```

### Lab Guide Document Template

Every lab has a guide at `docs/labs/{NN}-{lab-name}.md`:

```markdown
# Lab {XX-YY}: {Lab Name}

## Overview
- **Module:** {Module Number} - {Module Name}
- **Duration:** {duration}
- **Hardware:** {hardware}
- **Prerequisites:** {list previous labs or dependencies}

## Objectives
- [ ] Deploy {module} in {lab-type} configuration
- [ ] Verify core functionality
- [ ] Test integration points
- [ ] Validate security controls
- [ ] Document results

## Prerequisites
- Completed Lab {XX-(YY-1)}
- {Software prerequisites}
- {Hardware prerequisites}

## Step-by-Step Instructions

### Step 1: Prepare Environment
{detailed steps}

### Step 2: Deploy
{detailed steps}

### Step 3: Verify
{detailed steps}

### Step 4: Test
{detailed steps}

### Step 5: Document Results
{detailed steps}

## Success Criteria
- All deployment steps complete without errors
- Functional tests pass
- {Module-specific criteria}

## Troubleshooting
- **Issue:** {common issue}
  **Fix:** {solution}

## Results
| Test | Status | Notes |
|------|--------|-------|
| Deployment | ✓/✗ | |
| Health check | ✓/✗ | |
| Functional test | ✓/✗ | |
```

### Testing Tiers (Lab-to-Tier Mapping)

Map your deployment tiers to lab numbers:

```yaml
testing_tiers:
  tier-1-small:           # 1-5 nodes
    capacity: "1-5 nodes"
    labs_assigned:
      - "All XX-01 labs (standalone)"
      - "All XX-02 labs (external deps)"
      - "Selected XX-03 labs"
  
  tier-1-medium:          # 5-10 nodes
    capacity: "5-10 nodes"  
    labs_assigned:
      - "All XX-02 labs"
      - "All XX-03 labs (advanced)"
      - "All XX-04 labs (SSO)"
  
  tier-2-large:           # 10-50 nodes
    capacity: "10-50 nodes"
    labs_assigned:
      - "All XX-04 labs"
      - "All XX-05 labs (deep integration)"
      - "Selected XX-06 labs"
  
  tier-3-production:      # 50+ nodes
    capacity: "50+ nodes"
    labs_assigned:
      - "All XX-06 labs (production)"
      - "Integration testing"
      - "Performance benchmarking"
```

### Test Result Symbols

```
✓ = Test passed
✗ = Test failed
⏭ = Test skipped
ℹ = Information
```

---

## 7. Local Development Environment

### Directory Structure

```
~/{project-name}-dev/
│
├── repos/                           # All module repositories (by category)
│   ├── meta/                        # Meta repositories
│   │   ├── {project-name}-installer/
│   │   ├── {project-name}-docs/
│   │   └── {project-name}-testing/
│   ├── {category-1}/               # Category directories
│   │   ├── {project-name}-{module-1}/
│   │   ├── {project-name}-{module-2}/
│   │   └── ...
│   ├── {category-2}/
│   │   └── ...
│   └── ... (one dir per category)
│
├── workspaces/                      # Active development areas
│   ├── current-sprint/              # Current sprint work
│   │   ├── feature-branch-1/
│   │   └── bugfix-branch-1/
│   ├── labs-testing/                # Lab testing workspace
│   │   ├── lab-01-standalone/
│   │   ├── lab-02-external-deps/
│   │   ├── lab-03-advanced/
│   │   ├── lab-04-sso/
│   │   ├── lab-05-integration/
│   │   └── lab-06-production/
│   └── integration/                 # Integration testing
│       ├── {stack-1}/
│       └── full-stack/
│
├── deployments/                     # Deployment configurations
│   ├── local/                       # Local cluster (k3d / minikube)
│   │   ├── k3d-config.yaml
│   │   ├── manifests/
│   │   ├── helm-values/
│   │   └── scripts/
│   ├── dev/                         # Development environment
│   │   ├── inventory.ini
│   │   ├── group_vars/
│   │   ├── host_vars/
│   │   ├── playbooks/
│   │   └── terraform/
│   ├── staging/                     # Staging environment
│   │   └── (same structure as dev)
│   └── production/                  # Production environment
│       ├── (same structure as dev)
│       ├── disaster-recovery/
│       └── monitoring/
│
├── lab-environments/                # Physical lab testing
│   ├── tier-1-small/                # Smallest deployment tier
│   │   ├── inventory/
│   │   │   ├── node-01.yaml
│   │   │   └── network.yaml
│   │   ├── configs/
│   │   ├── labs/
│   │   │   ├── module-01-{name}/
│   │   │   │   ├── lab-01-standalone/
│   │   │   │   │   ├── test-results.md
│   │   │   │   │   ├── screenshots/
│   │   │   │   │   └── logs/
│   │   │   │   ├── lab-02-external-deps/
│   │   │   │   └── ... (lab-03 through lab-06)
│   │   │   └── module-02-{name}/
│   │   ├── logs/
│   │   └── backups/
│   ├── tier-1-medium/
│   ├── tier-2-large/
│   └── tier-3-production/
│
├── configs/                         # Configuration management
│   ├── global/                      # Global configs
│   │   ├── {project-name}.yaml      # Main project config
│   │   ├── network.yaml
│   │   └── storage.yaml
│   ├── modules/                     # Per-module configs
│   │   ├── {module-1}.yaml
│   │   └── {module-2}.yaml
│   ├── environments/                # Environment-specific overrides
│   │   ├── local.yaml
│   │   ├── dev.yaml
│   │   ├── staging.yaml
│   │   └── production.yaml
│   └── secrets/                     # Secrets (git-ignored!)
│       ├── .gitignore
│       ├── vault-keys/
│       ├── ssl-certs/
│       └── api-tokens/
│
├── scripts/                         # Automation scripts
│   ├── setup/                       # One-time setup scripts
│   ├── github/                      # GitHub automation
│   ├── operations/                  # Day-to-day operations
│   ├── testing/                     # Test runners
│   ├── deployment/                  # Deployment automation
│   └── utilities/                   # Miscellaneous utilities
│
├── docs/                            # Local documentation mirror
│   ├── 01-core/
│   ├── 02-implementation/
│   ├── 03-labs/
│   ├── 04-github/
│   ├── 05-guides/
│   ├── 06-technical-reference/
│   └── 07-architecture/
│
├── tools/                           # Development tools
│   ├── ide-configs/                 # IDE settings (VSCode, etc.)
│   ├── linters/                     # Code linter configs
│   ├── formatters/                  # Code formatter configs
│   └── templates/                   # Code templates by language
│
├── logs/                            # Centralized logs
│   ├── application/
│   ├── infrastructure/
│   └── testing/
│
├── claude.md                        # AI assistant instructions
├── README.md                        # Development environment README
└── GETTING-STARTED.md               # Quick start guide
```

### Setup Script Template (PowerShell)

```powershell
# setup-directory-structure.ps1
# Creates the complete local development directory structure

param(
    [string]$BaseDir = "C:\{project-name}-dev"
)

Write-Host "Setting up {Project Name} development directory structure..." -ForegroundColor Cyan

$directories = @(
    # Repositories by category
    "repos\meta",
    "repos\{category-1}",
    "repos\{category-2}",
    # ... add all category directories
    
    # Workspaces
    "workspaces\current-sprint",
    "workspaces\labs-testing",
    "workspaces\integration",
    
    # Deployments
    "deployments\local\configs",
    "deployments\local\scripts",
    "deployments\dev\configs",
    "deployments\staging\configs",
    "deployments\production\configs",
    
    # Lab environments (one per tier)
    "lab-environments\tier-1-small\labs",
    "lab-environments\tier-1-small\configs",
    "lab-environments\tier-1-small\results",
    "lab-environments\tier-1-medium\labs",
    "lab-environments\tier-2-large\labs",
    "lab-environments\tier-3-production\labs",
    
    # Configuration
    "configs\modules",
    "configs\environments",
    "configs\secrets",
    "configs\templates",
    
    # Scripts
    "scripts\setup",
    "scripts\github",
    "scripts\operations",
    "scripts\testing",
    "scripts\deployment",
    "scripts\utilities",
    
    # Documentation
    "docs\01-core",
    "docs\02-implementation",
    "docs\03-labs",
    "docs\04-github",
    "docs\05-guides",
    "docs\06-technical-reference",
    "docs\07-architecture",
    
    # Tools
    "tools\ide-configs",
    "tools\linters",
    "tools\templates",
    
    # Logs
    "logs\application",
    "logs\infrastructure",
    "logs\testing"
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $BaseDir $dir
    if (!(Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "✓ Created: $dir" -ForegroundColor Green
    }
}

Write-Host "`nDirectory structure created at: $BaseDir" -ForegroundColor Green
```

---

## 8. Deployment Tiers & Environments

### Tier Model

Define tiers based on your deployment scale:

| Tier | Name | Nodes | Purpose | Labs Covered |
|------|------|-------|---------|--------------|
| Tier 1A | Small/Home | 1-5 | Basic functionality, standalone | Labs 01, 02, some 03 |
| Tier 1B | Medium/School | 5-10 | LAN integration, multi-node | Labs 02, 03, 04 |
| Tier 2 | Large/Cluster | 10-50 | Full integration, HA testing | Labs 04, 05, some 06 |
| Tier 3 | Production | 50+ | Production deployment, performance | Labs 06, integration |

### Environment Hierarchy

```
Environments (deployment stages):

local/          → Developer's machine (k3d, minikube, docker-compose)
    ↓
dev/            → Shared development environment
    ↓
staging/        → Pre-production (mirrors production)
    ↓
production/     → Live deployment
```

### Per-Environment Structure

```
deployments/{environment}/
├── inventory.ini           # Ansible inventory
├── ansible.cfg             # Ansible configuration
├── group_vars/
│   ├── all.yaml            # Global variables
│   └── {category}.yaml     # Category-specific vars
├── host_vars/
│   └── node-{N}.yaml       # Per-node variables
├── playbooks/
│   ├── deploy-{category}.yaml
│   └── deploy-full-stack.yaml
├── roles/
│   └── {category}/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── modules/
└── scripts/
    ├── deploy-stack.sh
    └── rollback-stack.sh
```

---

## 9. Configuration Management

### Configuration Hierarchy (Precedence)

```
Highest priority → Lowest priority:

1. Environment variables
2. Command-line arguments
3. Environment-specific config   (configs/environments/production.yaml)
4. Module-specific config        (configs/modules/{module}.yaml)
5. Global config                 (configs/global/{project-name}.yaml)
6. Default values                (in code / manifest)
```

### Global Configuration Template

```yaml
# configs/global/{project-name}.yaml
project:
  name: "{project-name}"
  version: "1.0.0"
  domain: "{project-name}.local"

networks:
  tier-1-small:
    cidr: "192.168.100.0/24"
    gateway: "192.168.100.1"
  tier-1-medium:
    cidr: "10.0.0.0/16"
    gateway: "10.0.0.1"

services:
  auth:
    provider: "keycloak"
    port: 8080
    realm: "{project-name}"
  storage:
    provider: "minio"
    port: 9000
  monitoring:
    metrics_port: 9090
    dashboard_port: 3000
```

### Secrets Management

```
configs/secrets/
├── .gitignore               # ← CRITICAL: Never commit secrets!
├── README.md                # How to manage secrets
├── vault/
│   ├── unseal-keys.txt.gpg  # Encrypted with GPG
│   └── root-token.txt.gpg
├── ssl/
│   ├── ca.crt
│   └── ca.key.gpg
└── api-tokens/
    └── github-token.txt.gpg
```

**`.gitignore` for secrets:**
```
# NEVER commit secrets
*
!.gitignore
!README.md
```

---

## 10. Automation Scripts

### Script Categories

```
scripts/
├── setup/                   # One-time setup (run once)
│   ├── install-tools.ps1         # Install all required tools
│   ├── setup-directory-structure.ps1  # Create workspace dirs
│   └── setup-github.ps1         # Configure GitHub CLI
│
├── github/                  # GitHub repo & issue management
│   ├── create-phase{N}-modules.ps1    # Create repos per phase
│   ├── add-phase{N}-issues.ps1        # Add lab issues to projects
│   ├── create-github-projects.ps1     # Create GitHub Projects
│   ├── create-milestones.ps1          # Create milestones
│   ├── verify-all-projects.ps1        # Verify project completeness
│   └── add-master-dashboard-issues.ps1
│
├── operations/              # Day-to-day operations
│   ├── clone-repos.ps1           # Clone all repos locally
│   ├── update-all-repos.ps1      # Pull latest for all repos
│   └── batch-operations.ps1      # Run command across all repos
│
├── testing/                 # Test automation
│   ├── run-all-labs.sh           # Run all lab tests
│   └── run-integration-tests.sh
│
├── deployment/              # Deployment automation
│   ├── deploy-stack.sh
│   └── rollback-stack.sh
│
└── utilities/               # Misc utilities
    └── create-repo-template.ps1  # Scaffold a new module repo
```

### Module Creation Script Template (PowerShell)

This is the most critical automation script — it scaffolds a new module repository with the entire standard structure:

```powershell
# create-repo-template.ps1
# Creates standard directory structure for new modules

param(
    [Parameter(Mandatory=$true)]
    [string]$ModuleName,
    
    [Parameter(Mandatory=$true)]
    [string]$Category,
    
    [string]$Description = "",
    [string]$OutputPath = ""
)

if ($OutputPath -eq "") {
    $OutputPath = "C:\{project-name}-dev\repos\$Category\{project-name}-$ModuleName"
}

# Create directory structure
$directories = @(
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

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path (Join-Path $OutputPath $dir) -Force | Out-Null
}

# Create README.md, {project-name}.yml, Makefile, Dockerfile, .gitignore
# Create 6 docker-compose files (standalone, lan, advanced, sso, integration, production)
# Create lab test script stubs
# Create lab guide document stubs

Write-Host "Repository template created at: $OutputPath"
Write-Host "Next: git init, git add ., git commit, create GitHub repo, push"
```

### Phase Module Creation Script Template

This script creates multiple repos and their lab issues for a phase:

```powershell
# create-phase{N}-modules.ps1
# Creates GitHub repos and lab issues for a deployment phase

param(
    [string]$OrgName = "{org-name}",
    [switch]$CreateRepos = $false,
    [switch]$CreateIssues = $false,
    [switch]$DryRun = $true
)

# Module definitions for this phase
$modules = @(
    @{
        Number = "01"
        Name = "Module One"
        RepoName = "{project-name}-module-one"
        Description = "Description of module one"
        Category = "category-name"
        Topics = @("topic1", "topic2", "{project-name}")
    },
    # ... more modules
)

# Universal lab definitions (same for EVERY module)
$labTests = @(
    @{ Number = "01"; Name = "Standalone"; Duration = "30-60 min"; Hardware = "1 machine" }
    @{ Number = "02"; Name = "External Dependencies"; Duration = "45-90 min"; Hardware = "2-3 machines" }
    @{ Number = "03"; Name = "Advanced Features"; Duration = "60-120 min"; Hardware = "2-3 machines" }
    @{ Number = "04"; Name = "SSO Integration"; Duration = "90-120 min"; Hardware = "3-4 machines" }
    @{ Number = "05"; Name = "Advanced Integration"; Duration = "90-150 min"; Hardware = "4-5 machines" }
    @{ Number = "06"; Name = "Production Deployment"; Duration = "120-180 min"; Hardware = "5+ machines" }
)

if ($CreateRepos) {
    foreach ($module in $modules) {
        $fullRepoName = "$OrgName/$($module.RepoName)"
        gh repo create $fullRepoName --public --description $module.Description
        # Add topics
        gh api -X PUT "repos/$fullRepoName/topics" -f names="$($module.Topics -join ',')"
    }
}

if ($CreateIssues) {
    foreach ($module in $modules) {
        foreach ($lab in $labTests) {
            $labNumber = "$($module.Number)-$($lab.Number)"
            $title = "Lab $labNumber`: $($lab.Name) - $($module.Name)"
            $body = "## Lab $labNumber`: $($lab.Name)
**Module:** $($module.Number) - $($module.Name)
**Duration:** $($lab.Duration)
**Hardware:** $($lab.Hardware)

### Objectives
- [ ] Deploy in $($lab.Name.ToLower()) configuration
- [ ] Verify core functionality
- [ ] Document results"
            
            gh issue create --repo "$OrgName/$($module.RepoName)" --title $title --body $body `
                --label "lab,module-$($module.Number),phase-{N}"
        }
    }
}
```

### Add Issues to GitHub Project Script Template

```powershell
# add-phase{N}-issues.ps1
# Adds all phase issues to a GitHub Project

param(
    [int]$ProjectNumber = 5
)

$phaseRepos = @(
    "{project-name}-module-1",
    "{project-name}-module-2",
    # ... all repos in this phase
)

foreach ($repo in $phaseRepos) {
    $issues = gh issue list -R "{org-name}/$repo" --state open --limit 10 --json url | ConvertFrom-Json
    foreach ($issue in $issues) {
        gh project item-add $ProjectNumber --owner {org-name} --url $issue.url
    }
}
```

---

## 11. GitHub Projects & Phased Roadmap

### IT-Stack Phased Implementation

```yaml
phases:
  phase-1:
    name: "Foundation"
    timeline: "Weeks 1-4"
    description: "Core infrastructure all other services depend on"
    modules:
      - it-stack-freeipa       # 01
      - it-stack-keycloak      # 02
      - it-stack-postgresql    # 03
      - it-stack-redis         # 04
      - it-stack-traefik       # 18
    github_project: "Project #1 – Phase 1: Foundation"
    deliverable: "SSO + DB + Reverse Proxy working end-to-end"

  phase-2:
    name: "Collaboration & Communications"
    timeline: "Weeks 5-8"
    description: "User-facing collaboration and communication platform"
    modules:
      - it-stack-nextcloud     # 06
      - it-stack-mattermost    # 07
      - it-stack-jitsi         # 08
      - it-stack-iredmail      # 09
      - it-stack-zammad        # 11
    github_project: "Project #2 – Phase 2: Collaboration"
    deliverable: "Full collaboration suite with SSO for 50+ users"

  phase-3:
    name: "Back Office"
    timeline: "Weeks 9-14"
    description: "Business systems replacing commercial SaaS"
    modules:
      - it-stack-freepbx       # 10
      - it-stack-suitecrm      # 12
      - it-stack-odoo          # 13
      - it-stack-openkm        # 14
    github_project: "Project #3 – Phase 3: Back Office"
    deliverable: "VoIP + CRM + ERP + DMS integrated with SSO"

  phase-4:
    name: "IT Management & Observability"
    timeline: "Weeks 15-20"
    description: "IT operations, monitoring, and log management"
    modules:
      - it-stack-taiga         # 15
      - it-stack-snipeit       # 16
      - it-stack-glpi          # 17
      - it-stack-elasticsearch # 05
      - it-stack-zabbix        # 19
      - it-stack-graylog       # 20
    github_project: "Project #4 – Phase 4: IT Management"
    deliverable: "Full observability and IT management stack"
```

### IT-Stack GitHub Projects Structure

| Project | Name | Modules | Issues |
|---------|------|---------|--------|
| #1 | Phase 1: Foundation | freeipa, keycloak, postgresql, redis, traefik | 30 |
| #2 | Phase 2: Collaboration | nextcloud, mattermost, jitsi, iredmail, zammad | 30 |
| #3 | Phase 3: Back Office | freepbx, suitecrm, odoo, openkm | 24 |
| #4 | Phase 4: IT Management | taiga, snipeit, glpi, elasticsearch, zabbix, graylog | 36 |
| #5 | Master Dashboard | All 20 modules | 120 |

### Project Views

Each GitHub Project should have these views:

1. **Board View** — Kanban columns: Todo → In Progress → Done
2. **Table View** — Sortable by module, lab number, status
3. **Roadmap View** — Timeline-based view of phases

### Issue Template for Labs

Every lab becomes a GitHub Issue:

```markdown
## Lab {XX-YY}: {Lab Name}

**Module:** {XX} - {Module Name}
**Category:** {Category}
**Duration:** {duration}
**Hardware:** {hardware}

### Objectives
- [ ] Deploy {module} in {lab-type} configuration
- [ ] Verify core functionality
- [ ] Test integration points
- [ ] Validate security controls
- [ ] Document results

### Success Criteria
- All deployment steps complete without errors
- Functional tests pass
- Documentation updated

---
**Phase:** {N}
**Lab:** {XX-YY}
**Type:** {Lab Name}
```

### Labels

Apply these labels consistently:

```
lab                    # All lab issues
module-{NN}            # Module number
phase-{N}              # Phase number
{category-name}        # Category
priority-{high|med|low}
status-{todo|in-progress|done|blocked}
```

---

## 12. AI Assistant Instructions (claude.md)

### Purpose

Place a `claude.md` file at the project root. This file gives AI assistants (Claude, Copilot, etc.) complete context about your project so they can assist effectively without re-discovering the project structure every time.

### claude.md Template

```markdown
# IT-Stack Project Instructions for AI Assistant

> **Purpose:** This document provides AI assistants with essential context
> for assisting with the IT-Stack project.

---

## Quick Reference

**Project:** IT-Stack — Open-source enterprise IT infrastructure replacing Microsoft 365, Salesforce, SAP, RingCentral, and ServiceNow
**Scale:** 20 modules, 7 categories, 120 lab tests
**GitHub Org:** `it-stack-dev` (26 repositories)
**Dev Path:** `C:\it-stack-dev\`

---

## Core Context

### What is {Project Name}?

{2-3 paragraph description of what the project is, its goals,
 key technologies, and architecture principles}

**Key Technologies:**
- {Technology 1}
- {Technology 2}
- ...

**Architecture Principles:**
1. {Principle 1}
2. {Principle 2}
3. ...

---

## Documentation Structure

**Priority Order:**
1. Master Organization Guide - Overall structure
2. Category Documents - Detailed implementation
3. Lab Database - Testing procedures
4. GitHub Structure - Repository organization
5. Architecture Documents - Deep technical details

---

## GitHub Organization Structure

{List all categories with their repository names}

### Naming Convention: `{project-name}-{component-name}` (kebab-case)

---

## Repository Structure

{Standard repo structure tree}

---

## Lab Testing Framework

### 6-Lab Progression (Every Module Has Exactly 6 Labs)

**Lab XX-01: Standalone (30-60 min)**
- Purpose: Basic functionality in isolation
- Hardware: 1 machine

**Lab XX-02: External Dependencies (45-90 min)**
- Purpose: Network integration
- Hardware: 2-3 machines

**Lab XX-03: Advanced Features (60-120 min)**
- Purpose: Production features enabled
- Hardware: 2-3 machines

**Lab XX-04: SSO Integration (90-120 min)**
- Purpose: Central authentication
- Hardware: 3-4 machines

**Lab XX-05: Advanced Integration (90-150 min)**
- Purpose: Deep ecosystem integration
- Hardware: 4-5 machines

**Lab XX-06: Production Deployment (120-180 min)**
- Purpose: High availability cluster
- Hardware: 5+ machines

---

## Module Quick Reference

{Complete list of all modules by category with numbers}

---

## Common Commands

{List of frequently used commands}

---

## Common Tasks & How to Help

### Setup Assistance
{How to help with setup}

### Development Assistance
{How to help with coding}

### Lab Testing Assistance
{How to help with labs}

### Debugging
{How to help debug issues}

---

## Code Review Checklist

**Structure:** Tests included, docs updated, manifest correct
**Security:** No secrets in code, input validation, encryption
**Operations:** Error handling, logging, metrics exposed

---

## Best Practices

1. Search project knowledge first
2. Provide complete, working examples
3. Follow repository conventions exactly
4. Be specific — reference exact file paths
5. Think systematically — check prerequisites and dependencies
```

---

## 13. CI/CD & Workflows

### GitHub Actions — Reusable Workflows

Place reusable workflows at the organization level in `.github/workflows/`:

#### CI Workflow Template

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run unit tests
        run: make test-unit
      - name: Run integration tests
        run: make test-integration
  
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: make build
  
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
```

#### Release Workflow Template

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags: ['v*']

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and push Docker image
        run: |
          docker build -t ghcr.io/{org-name}/{project-name}-${{ github.event.repository.name }}:${{ github.ref_name }} .
          docker push ghcr.io/{org-name}/{project-name}-${{ github.event.repository.name }}:${{ github.ref_name }}
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
```

### Branch Strategy

```
main        ← production-ready code
develop     ← integration branch
feature/*   ← feature branches (from develop)
bugfix/*    ← bug fix branches
release/*   ← release preparation
hotfix/*    ← production hotfixes (from main)
```

---

## 14. Development Workflows & Conventions

### Daily Development Workflow

```bash
# Morning routine
cd ~/{project-name}-dev
./scripts/operations/update-all-repos.sh    # Pull all repos

# Work on a module
cd repos/{category}/{project-name}-{module}
git checkout develop
git pull origin develop
git checkout -b feature/my-feature

# Make changes, test locally
make test
make deploy                                  # Local docker-compose

# Run lab test
./tests/labs/test-lab-01.sh

# Commit and push
git add .
git commit -m "Implement feature X"
git push origin feature/my-feature

# Create pull request
gh pr create --title "Feature X" --body "Description"
```

### Lab Testing Workflow

```bash
# Navigate to module
cd repos/{category}/{project-name}-{module}

# Run specific lab
make test-lab-01

# Record results
cd ~/{project-name}-dev/lab-environments/tier-1-small/labs/module-01-{name}/lab-01-standalone/
cat > test-results.md << EOF
# Lab 01-01 Test Results
Date: $(date)
Status: PASS
Duration: 28 minutes
Notes: All tests passed
EOF
```

### Module Creation Workflow

```bash
# 1. Create repo template locally
./scripts/utilities/create-repo-template.ps1 -ModuleName "my-module" -Category "my-category"

# 2. Initialize git
cd repos/{category}/{project-name}-my-module
git init
git add .
git commit -m "Initial commit"

# 3. Create GitHub repo
gh repo create {org-name}/{project-name}-my-module --public --source=.

# 4. Push
git push -u origin main
git checkout -b develop
git push -u origin develop
```

---

## 15. Code Review Checklist

### Structure & Testing
- [ ] Follows standard repository structure
- [ ] Unit tests included
- [ ] Integration tests included
- [ ] Lab test scripts updated
- [ ] Documentation updated (README, API docs)
- [ ] Module manifest (`{project-name}.yml`) is correct
- [ ] Docker configuration works
- [ ] Lab tests pass

### Security
- [ ] No secrets or credentials in code
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF tokens where applicable
- [ ] Rate limiting configured
- [ ] Authentication required on protected endpoints
- [ ] Encryption at rest and in transit

### Operations
- [ ] No hardcoded credentials or configuration
- [ ] Proper error handling (no silent failures)
- [ ] Logging implemented (structured logs)
- [ ] Metrics exposed (Prometheus format at `/metrics`)
- [ ] Health check endpoint (`/health`)
- [ ] Graceful shutdown handling
- [ ] Resource limits defined in manifest

---

## 16. Shell Aliases & Developer Experience

### Recommended Aliases

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, or PowerShell profile):

```bash
# Navigation
alias {p}-dev='cd ~/{project-name}-dev'
alias {p}-repos='cd ~/{project-name}-dev/repos'
alias {p}-labs='cd ~/{project-name}-dev/lab-environments'
alias {p}-deploy='cd ~/{project-name}-dev/deployments'
alias {p}-docs='cd ~/{project-name}-dev/docs'

# Operations
alias {p}-update='~/{project-name}-dev/scripts/operations/update-all-repos.sh'
alias {p}-status='~/{project-name}-dev/scripts/operations/batch-operations.sh status'
alias {p}-test='~/{project-name}-dev/scripts/testing/run-all-labs.sh'

# Quick category navigation
alias {p}-{cat1}='cd ~/{project-name}-dev/repos/{category-1}'
alias {p}-{cat2}='cd ~/{project-name}-dev/repos/{category-2}'

# Lab environments
alias {p}-lab-small='cd ~/{project-name}-dev/lab-environments/tier-1-small'
alias {p}-lab-prod='cd ~/{project-name}-dev/lab-environments/tier-3-production'

# Deployments
alias {p}-local='cd ~/{project-name}-dev/deployments/local'
alias {p}-staging='cd ~/{project-name}-dev/deployments/staging'
alias {p}-prod='cd ~/{project-name}-dev/deployments/production'
```

### IDE Configuration

Include VS Code workspace settings in `tools/ide-configs/vscode/`:

```json
{
    "editor.formatOnSave": true,
    "files.exclude": {
        "**/node_modules": true,
        "**/__pycache__": true
    },
    "search.exclude": {
        "**/logs": true,
        "**/builds": true
    }
}
```

---

## 17. Quick Start: Setting Up a New Project

### IT-Stack Quick Start Checklist

> Status: GitHub org `it-stack-dev` is freshly created and empty. Start here.

#### Step 0: Planning ✅ COMPLETE

- [x] **Project name:** `it-stack`
- [x] **GitHub org:** `it-stack-dev`
- [x] **Categories defined:** 7 (identity, database, collaboration, communications, business, it-management, infrastructure)
- [x] **Modules listed:** 20 modules numbered 01–20
- [x] **Phases defined:** 4 phases over 20 weeks
- [x] **Deployment tiers defined:** 4 tiers (lab → school → department → enterprise)
- [x] **Documentation:** 14 source documents in `C:\IT-Stack\docs\`

#### Step 1: GitHub Organization Bootstrap (2–4 hours)

- [ ] Create `.github` repo at `github.com/it-stack-dev/.github`
  - [ ] Add `profile/README.md` (org homepage)
  - [ ] Add `CONTRIBUTING.md`
  - [ ] Add `CODE_OF_CONDUCT.md`
  - [ ] Add `SECURITY.md`
  - [ ] Add reusable workflows: `ci.yml`, `release.yml`, `security-scan.yml`, `docker-build.yml`
- [ ] Create 6 meta repositories:
  - [ ] `it-stack-docs` — push existing `C:\IT-Stack\docs\` content
  - [ ] `it-stack-installer` — bootstrap & automation scripts
  - [ ] `it-stack-testing` — integration tests
  - [ ] `it-stack-ansible` — Ansible playbooks
  - [ ] `it-stack-terraform` — Terraform modules
  - [ ] `it-stack-helm` — Helm charts
- [ ] Create 5 GitHub Projects (#1 through #5)
- [ ] Apply org-level labels: `lab`, `module-NN`, `phase-N`, category tags, priority/status labels

#### Step 2: Local Environment Setup (30 min)

- [ ] Run `scripts/setup/setup-directory-structure.ps1` (create `C:\it-stack-dev\`)
- [ ] Clone meta repos into `C:\it-stack-dev\repos\meta\`
- [ ] Create `claude.md` at `C:\it-stack-dev\` (see Section 12 template)
- [ ] Configure PowerShell aliases (see Section 16)

#### Step 3: Phase 1 Module Scaffolding (per-phase)

Repeat for each phase:
- [ ] Run `create-phase1-modules.ps1 -CreateRepos` — creates 5 GitHub repos
- [ ] Run `create-repo-template.ps1` for each module — scaffolds local dirs
- [ ] Run `create-phase1-modules.ps1 -CreateIssues` — 30 lab issues
- [ ] Add issues to GitHub Project #1: `add-phase1-issues.ps1`
- [ ] Repeat for Phase 2, 3, 4

#### Step 4: Populate `it-stack-docs` Repository

- [ ] Initialize git in `C:\IT-Stack\`
- [ ] Push all docs to `github.com/it-stack-dev/it-stack-docs`
- [ ] Create numbered folder structure (`docs/01-core/` … `docs/07-architecture/`)
- [ ] Import existing documentation into correct folders

#### Step 5: Development & Testing (ongoing)

- [ ] Develop modules following standard repo structure
- [ ] Run lab tests progressively (01 → 02 → 03 → 04 → 05 → 06)
- [ ] Record results in `C:\it-stack-dev\lab-environments\`
- [ ] Track progress in GitHub Projects

---

## 18. Appendix: Complete File Templates

### A. Organization Profile README (`it-stack-dev`)

```markdown
# IT-Stack

**Complete open-source enterprise IT infrastructure — $0 in software licensing.**

## Mission
IT-Stack provides a complete, production-ready enterprise IT platform using 100% open-source software.
It replaces Microsoft 365, Salesforce, SAP, RingCentral, Zendesk, ServiceNow and more — at zero licensing cost.
Supports 50–1,000+ users across 8–9 servers.

## Stack (7 Categories · 20 Services)

- **Identity:** FreeIPA · Keycloak (SSO)
- **Database:** PostgreSQL · Redis · Elasticsearch
- **Collaboration:** Nextcloud · Mattermost · Jitsi
- **Communications:** iRedMail · FreePBX · Zammad
- **Business Systems:** SuiteCRM · Odoo · OpenKM
- **IT Management:** Taiga · Snipe-IT · GLPI
- **Infrastructure:** Traefik · Zabbix · Graylog

## Documentation
- [Complete Documentation](https://github.com/it-stack-dev/it-stack-docs)
- [Installer / Bootstrap](https://github.com/it-stack-dev/it-stack-installer)
- [Ansible Playbooks](https://github.com/it-stack-dev/it-stack-ansible)
- [Helm Charts](https://github.com/it-stack-dev/it-stack-helm)

## Quick Start
\`\`\`bash
git clone https://github.com/it-stack-dev/it-stack-installer.git
cd it-stack-installer
./install.sh
\`\`\`

## Contributing
See our [Contributing Guide](https://github.com/it-stack-dev/.github/blob/main/CONTRIBUTING.md).

## License
Apache 2.0
```

### B. Complete dcentral.yml Manifest (see Section 4)

### C. Lab Test Script (see Section 6)

### D. Docker Compose File per Lab

```yaml
# docker/docker-compose.standalone.yml (Lab 01)
version: '3.8'

services:
  {project-name}-{module}:
    build: ..
    image: {project-name}-{module}:latest
    container_name: {project-name}-{module}-standalone
    ports:
      - "8080:8080"
      - "9090:9090"
    environment:
      - LOG_LEVEL=info
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
```

### E. GitHub Issue Body for Lab

```markdown
## Lab {XX-YY}: {Lab Name}

**Module:** {XX} - {Module Name}
**Category:** {Category}
**Duration:** {duration}
**Hardware:** {hardware}

### Overview
{Lab description}

### Objectives
- [ ] Deploy {module} in {lab-type} configuration
- [ ] Verify core functionality
- [ ] Test integration points
- [ ] Validate security controls
- [ ] Document configuration and results

### Success Criteria
- All deployment steps complete without errors
- Functional tests pass
- Security validation complete
- Documentation updated

---
**Phase:** {N}
**Lab:** {XX-YY}
**Type:** {Lab Name}
```

### F. Tools Required

| Tool | Purpose | Installation |
|------|---------|-------------|
| Git | Version control | `apt install git` / `winget install git` |
| GitHub CLI (`gh`) | GitHub management | `apt install gh` / `winget install GitHub.cli` |
| Docker | Containerization | docker.com |
| Docker Compose | Multi-container orchestration | Included with Docker Desktop |
| kubectl | Kubernetes management | kubernetes.io |
| Helm | Kubernetes package management | helm.sh |
| k3d | Local K8s clusters | k3d.io |
| Ansible | Configuration management | ansible.com |
| Terraform | Infrastructure as Code | terraform.io |
| Python 3.x | Scripting | python.org |
| Node.js | JavaScript runtime | nodejs.org |
| Make | Build automation | Build tools |

---

## Summary: What Makes This Framework Work

| Element | Purpose | Universal Rule |
|---------|---------|----------------|
| **One module = one repo** | Isolation, independent deployment | Always |
| **Standard repo structure** | Predictability, automation-friendly | Every repo, identical layout |
| **Module manifest (YAML)** | Machine-readable metadata | Every repo root |
| **6-lab progression** | Systematic validation from simple to production | Every module, exactly 6 labs |
| **Numbered documentation** | Clear referencing, complete coverage | All docs numbered |
| **Category organization** | Thematic grouping for navigation | All modules categorized |
| **Phase-based roadmap** | Time-boxed implementation milestones | All work planned in phases |
| **GitHub Projects** | Visual progress tracking | One project per phase |
| **Automation scripts** | Eliminate manual repo/issue creation | Scripts for every repetitive task |
| **AI instructions (claude.md)** | AI assistants have full context | Updated as project evolves |
| **Deployment tiers** | Scale-appropriate testing | Labs mapped to tiers |
| **Config hierarchy** | Consistent, overridable configuration | Global → Module → Environment → Runtime |

---

**This document is the IT-Stack project blueprint. GitHub org: `it-stack-dev`. All placeholder values have been resolved for this project.**

---

## IT-Stack Module Reference Table

| # | Module Repo | Category | Replaces |
|---|-------------|----------|----------|
| 01 | `it-stack-freeipa` | Identity | Active Directory / LDAP |
| 02 | `it-stack-keycloak` | Identity | Azure AD / Okta |
| 03 | `it-stack-postgresql` | Database | MS SQL / RDS |
| 04 | `it-stack-redis` | Database | ElastiCache |
| 05 | `it-stack-elasticsearch` | Database | Splunk / CloudSearch |
| 06 | `it-stack-nextcloud` | Collaboration | Microsoft 365 / SharePoint |
| 07 | `it-stack-mattermost` | Collaboration | Slack / Teams |
| 08 | `it-stack-jitsi` | Collaboration | Zoom / Meet |
| 09 | `it-stack-iredmail` | Communications | Exchange / Gmail |
| 10 | `it-stack-freepbx` | Communications | RingCentral / Teams Phone |
| 11 | `it-stack-zammad` | Communications | Zendesk / Freshdesk |
| 12 | `it-stack-suitecrm` | Business | Salesforce |
| 13 | `it-stack-odoo` | Business | SAP / QuickBooks |
| 14 | `it-stack-openkm` | Business | SharePoint DMS |
| 15 | `it-stack-taiga` | IT Management | Jira / Linear |
| 16 | `it-stack-snipeit` | IT Management | ServiceNow Assets |
| 17 | `it-stack-glpi` | IT Management | ServiceNow ITSM |
| 18 | `it-stack-traefik` | Infrastructure | nginx / HAProxy |
| 19 | `it-stack-zabbix` | Infrastructure | Datadog / Nagios |
| 20 | `it-stack-graylog` | Infrastructure | Splunk / ELK Stack |
