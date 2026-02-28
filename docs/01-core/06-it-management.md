---
doc: "01-core-06"
title: "IT & Project Management — Taiga + Snipe-IT + GLPI"
category: it-management
phase: 4
servers: [lab-mgmt1]
date: 2026-02-27
---

# IT & Project Management

> **Category:** IT & Project Management — Layer 6  
> **Phase:** 4 (IT Management)  
> **Servers:** `lab-mgmt1` (10.0.50.18, 16 GB RAM)  
> **Modules:** Taiga (15) · Snipe-IT (16) · GLPI (17)

---

## Module 15: Taiga

**Repo:** [it-stack-taiga](https://github.com/it-stack-dev/it-stack-taiga)  
**Port:** 443 (via Traefik) · **Subdomain:** `pm.example.com`  
**Replaces:** Jira, Linear, Trello

### Project Boards in Use

| Project | Board Type | Team |
|---------|------------|------|
| IT-Stack Build | Kanban / Scrum | IT Infrastructure |
| IT Operations | Kanban | IT Operations |
| HR Onboarding | Kanban | HR |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| Mattermost | Webhook | Story/task updates → `#dev-updates` |
| Odoo | Export | Sprint timesheets → Odoo HR timesheet |
| Keycloak | OIDC | SSO login |

---

## Module 16: Snipe-IT

**Repo:** [it-stack-snipeit](https://github.com/it-stack-dev/it-stack-snipeit)  
**Port:** 443 (via Traefik) · **Subdomain:** `assets.example.com`  
**Replaces:** Lansweeper, ManageEngine AssetExplorer

### Asset Categories

| Category | Examples |
|----------|---------|
| Computers | Desktops, laptops, servers |
| Network | Switches, routers, access points |
| Phones | VoIP handsets, mobile phones |
| Software | Licensed software (by seat) |
| Peripherals | Monitors, keyboards, mice |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| GLPI | REST API | Sync hardware assets → GLPI CMDB |
| Odoo | REST API | Asset purchase → Odoo inventory |
| FreeIPA LDAP | LDAP | Assign assets to directory users |
| Keycloak | SAML | SSO login |

---

## Module 17: GLPI

**Repo:** [it-stack-glpi](https://github.com/it-stack-dev/it-stack-glpi)  
**Port:** 443 (via Traefik) · **Subdomain:** `itsm.example.com`  
**Replaces:** ServiceNow, BMC Remedy, Cherwell

### GLPI Modules Used

| Module | Purpose |
|--------|---------|
| Helpdesk | IT incident and request tickets |
| CMDB | Configuration item database |
| Asset Management | Supplement to Snipe-IT (CMDB view) |
| Change Management | RFC process, CAB approvals |
| Problem Management | Root cause analysis tracking |
| SLA Management | Response/resolution time targets |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| Snipe-IT | REST API | Hardware assets → CMDB CIs |
| Zammad | REST API | Escalate IT incidents, sync updates |
| FreeIPA LDAP | LDAP | User authentication |
| Mattermost | Webhook | Critical ticket alerts |
| Keycloak | SAML | SSO login |
