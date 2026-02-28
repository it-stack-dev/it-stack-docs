---
doc: "01-core-05"
title: "Business Systems — SuiteCRM + Odoo + OpenKM"
category: business
phase: 3
servers: [lab-biz1]
date: 2026-02-27
---

# Business Systems

> **Category:** Business Systems — Layer 5  
> **Phase:** 3 (Back Office)  
> **Servers:** `lab-biz1` (10.0.50.17, 24 GB RAM)  
> **Modules:** SuiteCRM (12) · Odoo (13) · OpenKM (14)

---

## Module 12: SuiteCRM

**Repo:** [it-stack-suitecrm](https://github.com/it-stack-dev/it-stack-suitecrm)  
**Port:** 443 (via Traefik) · **Subdomain:** `crm.example.com`  
**Replaces:** Salesforce, HubSpot

### Core Modules Used

| CRM Module | Purpose |
|------------|---------|
| Accounts & Contacts | Customer and prospect database |
| Opportunities | Sales pipeline management |
| Cases | Customer support case tracking |
| Activities | Calls, meetings, tasks linked to records |
| Reports & Dashboards | Sales analytics |
| Email integration | Via iRedMail IMAP sync |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| FreePBX CTI | AMI / REST | Click-to-call, auto-log inbound calls |
| Odoo | REST API | Sync converted opportunity → Odoo customer |
| Nextcloud | CalDAV | Sync activities to shared calendar |
| OpenKM | REST API | Link documents to CRM records |
| Keycloak | SAML 2.0 | SSO login |

---

## Module 13: Odoo

**Repo:** [it-stack-odoo](https://github.com/it-stack-dev/it-stack-odoo)  
**Ports:** 8069 (web), 8072 (longpoll) · **Subdomain:** `erp.example.com`  
**Replaces:** SAP, QuickBooks, NetSuite

### Installed Modules

| Odoo Module | Purpose |
|-------------|---------|
| Accounting | Double-entry bookkeeping, invoicing, expenses |
| Inventory | Stock management, warehouse operations |
| Purchase | PO management, vendor tracking |
| HR & Payroll | Employee records, leave, payroll |
| Project | Task management (lightweight — Taiga is primary PM) |
| Manufacturing | BOM, work orders (if applicable) |

### Key Integrations

| Integration | Method | Detail |
|-------------|--------|--------|
| FreeIPA LDAP | LDAP auth | Employee directory sync |
| SuiteCRM | REST API | Customer ↔ partner sync |
| Snipe-IT | REST API | Asset procurement → inventory |
| Taiga | Export | Timesheets → Odoo HR |
| Keycloak | OIDC | SSO login |

---

## Module 14: OpenKM

**Repo:** [it-stack-openkm](https://github.com/it-stack-dev/it-stack-openkm)  
**Port:** 8080 (via Traefik) · **Subdomain:** `docs.example.com`  
**Replaces:** SharePoint, Confluence, Google Drive (enterprise DMS use case)

### Document Repository Structure

```
/okm:root/
├── HR/               → Contracts, policies, onboarding docs
├── Finance/          → Invoices, receipts, financial reports
├── IT/               → Runbooks, network diagrams, SLAs
├── Sales/            → Proposals, contracts, case studies
├── Legal/            → NDAs, compliance documents
└── Shared/           → Company-wide reference documents
```

### Key Integrations

| Integration | Detail |
|-------------|--------|
| SuiteCRM | Attach documents to CRM records via REST |
| Odoo | Invoice/PO document storage |
| Nextcloud | Optional: Nextcloud as external storage backend |
| FreeIPA LDAP | User authentication and group-based ACLs |
