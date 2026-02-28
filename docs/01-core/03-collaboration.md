---
doc: "01-core-03"
title: "Collaboration — Nextcloud + Mattermost + Jitsi"
category: collaboration
phase: 2
servers: [lab-app1]
date: 2026-02-27
---

# Collaboration

> **Category:** Collaboration — Layer 3  
> **Phase:** 2  
> **Servers:** `lab-app1` (10.0.50.13, 24 GB RAM)  
> **Modules:** Nextcloud (06) · Mattermost (07) · Jitsi (08)

---

## Overview

The collaboration layer replaces Microsoft 365, Slack/Teams, and Zoom in a single server.
All three services authenticate via Keycloak OIDC and store data in PostgreSQL on `lab-db1`.

---

## Module 06: Nextcloud

**Repo:** [it-stack-nextcloud](https://github.com/it-stack-dev/it-stack-nextcloud)  
**Port:** 443 (via Traefik) · **Subdomain:** `cloud.example.com`  
**Replaces:** Microsoft 365 (OneDrive, SharePoint, Calendar, Contacts, Office Online)

### Features Used in IT-Stack

| Feature | Detail |
|---------|--------|
| Files | Self-hosted file sync for all users |
| Calendar / Contacts | CalDAV/CardDAV shared with SuiteCRM |
| Collabora / ONLYOFFICE | In-browser office document editing |
| Talk | Internal video/audio calls (Jitsi handles large meetings) |
| OIDC login | Via Keycloak `nextcloud` client |
| External storage | Optional S3-compatible backend |

### Storage Layout

```
/var/www/nextcloud/data/
├── {username}/files/       # User files
├── appdata_{instanceid}/   # App data
└── __groupfolders/         # Shared department folders
```

---

## Module 07: Mattermost

**Repo:** [it-stack-mattermost](https://github.com/it-stack-dev/it-stack-mattermost)  
**Port:** 8065 (via Traefik) · **Subdomain:** `chat.example.com`  
**Replaces:** Slack, Microsoft Teams

### Default Channels

| Channel | Purpose |
|---------|---------|
| `#general` | Company-wide announcements |
| `#it-ops` | IT team coordination |
| `#ops-alerts` | Zabbix + Graylog automated alerts |
| `#deployments` | CI/CD deployment notifications |
| `#help-desk` | Zammad ticket escalations |

### Integrations

| Integration | Direction | Method |
|-------------|-----------|--------|
| Zabbix alerts | Zabbix → Mattermost | Webhook |
| Graylog alerts | Graylog → Mattermost | Webhook |
| Taiga updates | Taiga → Mattermost | Webhook |
| GLPI/Zammad tickets | GLPI → Mattermost | Webhook |

---

## Module 08: Jitsi

**Repo:** [it-stack-jitsi](https://github.com/it-stack-dev/it-stack-jitsi)  
**Ports:** 443 (HTTPS), 10000/UDP (media) · **Subdomain:** `meet.example.com`  
**Replaces:** Zoom, Google Meet

### Architecture

```
Browser → Jitsi Meet Web (443) → Jicofo (conference focus)
                                       → JVB (Video Bridge, 10000/UDP)
                                       → Prosody XMPP
```

### OIDC Authentication

When `TOKEN_AUTH_URL` is set to the Keycloak `jitsi` client, only authenticated users
can create rooms. Room names become JWT tokens tied to the Keycloak session.

---

## Lab Progression

| Lab | Module | Key Task |
|-----|--------|----------|
| 06-01 | Nextcloud | Standalone — file upload, app install |
| 06-02 | Nextcloud | PostgreSQL external DB, Redis cache |
| 06-04 | Nextcloud | Keycloak OIDC login |
| 06-05 | Nextcloud | SuiteCRM CalDAV sync, Mattermost notifications |
| 07-01 | Mattermost | Standalone — team, channels, users |
| 07-04 | Mattermost | Keycloak OIDC, invite-only |
| 08-01 | Jitsi | Standalone — test video call |
| 08-04 | Jitsi | Keycloak JWT authentication |
