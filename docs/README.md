# IT-Stack Documentation

This folder contains all IT-Stack project documentation in two parallel structures:

| Structure | Purpose | How to use |
|-----------|---------|------------|
| **Numbered (`01-core/` … `07-architecture/`)** | Reference browsing directly on GitHub | Click folders below |
| **MkDocs (`architecture/`, `labs/`, etc.)** | Online documentation site | [it-stack-dev.github.io/it-stack-docs](https://it-stack-dev.github.io/it-stack-docs/) |

Both structures contain the same content. MkDocs files are the canonical source;
numbered files are copies with YAML front-matter added for catalogue indexing.

---

## Numbered Reference Structure

### [01-core/](01-core/) — Category Architecture Specifications

7 documents covering the purpose, configuration, and integration of each service category.

| # | File | Category | Services |
|---|------|----------|---------|
| – | [01-identity.md](01-core/01-identity.md) | Identity & Security | FreeIPA, Keycloak |
| – | [02-database.md](01-core/02-database.md) | Database & Cache | PostgreSQL, Redis, Elasticsearch |
| – | [03-collaboration.md](01-core/03-collaboration.md) | Collaboration | Nextcloud, Mattermost, Jitsi |
| – | [04-communications.md](01-core/04-communications.md) | Communications | iRedMail, FreePBX, Zammad |
| – | [05-business.md](01-core/05-business.md) | Business Systems | SuiteCRM, Odoo, OpenKM |
| – | [06-it-management.md](01-core/06-it-management.md) | IT & Project Mgmt | Taiga, Snipe-IT, GLPI |
| – | [07-infrastructure.md](01-core/07-infrastructure.md) | Infrastructure | Traefik, Zabbix, Graylog |

### [02-implementation/](02-implementation/) — Deployment & Integration Guides

| # | File | Source Document |
|---|------|----------------|
| 03 | [03-lab-deployment-plan.md](02-implementation/03-lab-deployment-plan.md) | Lab deployment strategy (3–5 servers) |
| 04 | [04-lab-deployment-plan-v2.md](02-implementation/04-lab-deployment-plan-v2.md) | Lab deployment plan (updated) |
| 06 | [06-stack-complete-v2.md](02-implementation/06-stack-complete-v2.md) | 8-server architecture overview |
| 12 | [12-integration-guide.md](02-implementation/12-integration-guide.md) | Cross-system integration procedures |

### [03-labs/](03-labs/) — Lab Manuals Parts 1–5

| # | File | Content |
|---|------|---------|
| 07 | [07-lab-manual-part1.md](03-labs/07-lab-manual-part1.md) | Part 1: Network & OS setup |
| 08 | [08-lab-manual-part2.md](03-labs/08-lab-manual-part2.md) | Part 2: Identity, Database, SSO |
| 09 | [09-lab-manual-part3.md](03-labs/09-lab-manual-part3.md) | Part 3: Collaboration suite |
| 10 | [10-lab-manual-part4.md](03-labs/10-lab-manual-part4.md) | Part 4: Communications |
| 11 | [11-lab-manual-part5.md](03-labs/11-lab-manual-part5.md) | Part 5: Back Office & IT Management |

### [04-github/](04-github/) — GitHub Organization Setup

| # | File | Content |
|---|------|---------|
| 13 | [13-github-guide.md](04-github/13-github-guide.md) | Complete GitHub org setup with scripts |

### [05-guides/](05-guides/) — Reference Guides & Templates

| # | File | Content |
|---|------|---------|
| 01 | [01-master-index.md](05-guides/01-master-index.md) | Master index and reading guide |
| 02 | [02-lab-manual-structure.md](05-guides/02-lab-manual-structure.md) | 6-lab methodology overview |
| 14 | [14-project-framework.md](05-guides/14-project-framework.md) | Project framework blueprint (canonical) |

### [06-technical-reference/](06-technical-reference/) — Full Technical Reference

| # | File | Content |
|---|------|---------|
| 05 | [05-stack-deployment.md](06-technical-reference/05-stack-deployment.md) | Original full technical reference (112 KB) |

### [07-architecture/](07-architecture/) — Architecture Decision Records

| File | Content |
|------|---------|
| [README.md](07-architecture/README.md) | ADR index and links |

---

## MkDocs Site Structure

These folders feed the live documentation website. Do not move or rename them.

```
architecture/    → System architecture and integrations
contributing/    → Project framework and contribution guidelines  
deployment/      → Deployment guides (lab and enterprise)
labs/            → Lab manuals (all 5 parts) and methodology overview
project/         → Master index, GitHub guide, todo tracker
index.md         → Site home page
```

**Live site:** https://it-stack-dev.github.io/it-stack-docs/

---

## Document Numbering Key

Original source documents are numbered 01–14 for catalogue purposes:

| # | Title | Category |
|---|-------|---------|
| 01 | Master Index | project |
| 02 | Lab Manual Structure | labs |
| 03 | Lab Deployment Plan | deployment |
| 04 | Lab Deployment Plan v2 | deployment |
| 05 | Enterprise Stack Deployment | technical-reference |
| 06 | Enterprise Stack Complete v2 | architecture |
| 07 | Lab Manual Part 1 — Network & OS | labs |
| 08 | Lab Manual Part 2 — Identity/DB/SSO | labs |
| 09 | Lab Manual Part 3 — Collaboration | labs |
| 10 | Lab Manual Part 4 — Communications | labs |
| 11 | Lab Manual Part 5 — Back Office | labs |
| 12 | Integration Guide | deployment |
| 13 | GitHub Organization Guide | github |
| 14 | Project Framework Template | contributing |
