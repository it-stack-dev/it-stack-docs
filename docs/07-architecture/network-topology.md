# IT-Stack Network Topology

> This document describes the network topology for IT-Stack in two deployment modes:  
> **Cloud (current live env)** and **On-Premises 8-Server (production reference)**.  
> For the architecture decision behind the 8-server layout see [ADR-006](adr-006-8server-layout.md).

---

## Cloud Single-VM Topology (Azure — Live, March 2026)

This is the **currently running lab environment** on a single Azure VM, established during the Phase 1 cloud lab session. All services are containers on a shared Docker bridge network.

### Azure Resources

| Property | Value |
|----------|-------|
| Resource Group | `rg-it-stack-phase1` |
| Region | West US 2 |
| VM Name | `lab-single` |
| VM Size | Standard_D4s_v4 (4 vCPU / 16 GB RAM) |
| OS | Ubuntu 24.04 LTS |
| OS Disk | 30 GB Premium SSD P4 |
| Public IP | `4.154.17.25` (static, Standard SKU) |
| SSH User | `itstack` |
| Docker bridge | `it-stack-demo` |
| DNS Zone | `lab.it-stack.local` (Azure Private DNS) |

### Container Layout

```
Internet
    │
    │  TLS (per-service, self-signed / no TLS in lab mode)
    ▼
4.154.17.25 — lab-single (Azure VM, West US 2)
    │
    ├── NSG: nsg-lab-single
    │   Inbound open: 8080, 8180, 8265, 8280, 8302, 8303, 8305,
    │                 8307, 8380, 8880, 9001, 9002, 9005, 25, 143, 587
    │
    └── Docker bridge: it-stack-demo (172.18.0.0/16)
        │
        ├── :8080  traefik-demo        (Traefik — dashboard)
        ├── :8180  keycloak-demo       (Keycloak SSO)
        │          keycloak-proxy      (Nginx reverse proxy for Keycloak)
        ├── :8265  mm-demo             (Mattermost)
        │          mm-db               (PostgreSQL for Mattermost)
        ├── :8280  nc-demo             (Nextcloud — 57 apps)
        │          nc-db               (PostgreSQL for Nextcloud)
        ├── :8302  crm-demo            (SuiteCRM)
        │          crm-db              (MariaDB for SuiteCRM)
        ├── :8303  odoo-demo           (Odoo ERP, DB: testdb)
        │          odoo-db             (PostgreSQL for Odoo)
        ├── :8305  snipe-demo          (Snipe-IT, 506 error fixed)
        │          snipe-db            (MySQL for Snipe-IT)
        ├── :8880  jitsi-web-lab01     (Jitsi Meet front end)
        │          jitsi-prosody       (XMPP signalling)
        │          jitsi-jicofo        (conference focus)
        │          jitsi-jvb           (video bridge — UDP :10000)
        ├── :9001  taiga-front-s01     (Taiga project management)
        │   :9000  taiga-back-s01      (Taiga Django API — internal)
        │          taiga-db-s01        (PostgreSQL for Taiga)
        ├── :8307  zabbix-web-s01      (Zabbix web UI)
        │          zabbix-srv-s01      (Zabbix server — :10051)
        │          zabbix-db-s01       (PostgreSQL for Zabbix)
        ├── :9002  graylog-s01         (Graylog — GELF UDP :12201, Syslog UDP :1514)
        │          graylog-es-s01      (Elasticsearch for Graylog)
        │          graylog-mongo-s01   (MongoDB for Graylog config)
        └── :587   mail-demo           (docker-mailserver — SMTP :25/:587, IMAP :143)
```

### Port Map (public-facing, via NSG)

| Port | Protocol | Service | Auth |
|------|----------|---------|------|
| 22 | TCP | SSH | Key-based |
| 8080 | TCP | Traefik dashboard | None |
| 8180 | TCP | Keycloak admin | admin/password |
| 8265 | TCP | Mattermost | Email/password |
| 8280 | TCP | Nextcloud | admin/password |
| 8302 | TCP | SuiteCRM | admin/password |
| 8303 | TCP | Odoo | admin/password |
| 8305 | TCP | Snipe-IT | admin/password |
| 8307 | TCP | Zabbix | Admin/password |
| 8880 | TCP | Jitsi Meet | None (guest) |
| 9001 | TCP | Taiga | admin/123123 |
| 9002 | TCP | Graylog | admin/password |
| 9005 | TCP | Email test UI | None |
| 25 | TCP | SMTP (inbound) | — |
| 143 | TCP | IMAP | credentials |
| 587 | TCP | SMTP submission | credentials |
| 10000 | UDP | Jitsi JVB | — |
| 12201 | UDP | Graylog GELF | — |
| 1514 | UDP | Graylog Syslog | — |

### Limitations vs. Production

| Aspect | Cloud Single-VM | On-Prem 8-Server |
|--------|----------------|-----------------|
| TLS | Self-signed / none | Let's Encrypt via Traefik |
| Identity | Keycloak standalone | Keycloak + FreeIPA LDAP |
| DB isolation | Per-service containers | Dedicated lab-db1 host |
| HA | Single point of failure | HA pairs per service |
| Network | Public IP, NSG | Private VLAN, Traefik ingress |
| DNS | Azure Private DNS (lab.it-stack.local) | FreeIPA DNS (it-stack.lab) |
| Monitoring | Basic Zabbix + Graylog | Full Zabbix + Graylog + alerting |
| Cost | ~$105/month (Azure) | Hardware / co-lo |

---

## On-Premises 8-Server Topology (Production Reference)

---

## Network Summary

| Property | Value |
|----------|-------|
| Subnet | `10.0.50.0/24` |
| Gateway | `10.0.50.1` |
| DNS Server | `10.0.50.11` (FreeIPA on lab-id1) |
| Domain | `it-stack.lab` |
| Reverse zone | `50.0.10.in-addr.arpa` |
| Inbound TLS | `10.0.50.15` (Traefik on lab-proxy1) |
| OS | Ubuntu 24.04 LTS (all nodes) |

---

## Server Layout

```
10.0.50.0/24  — IT-Stack LAN
│
├── 10.0.50.1   [Gateway / Router]
│
├── 10.0.50.11  lab-id1        Identity
│               ├── FreeIPA    (LDAP :389/:636, Kerberos :88, DNS :53)
│               └── Keycloak   (HTTPS :8443)
│
├── 10.0.50.12  lab-db1        Database
│               ├── PostgreSQL (TCP :5432)
│               └── Redis      (TCP :6379)
│
├── 10.0.50.13  lab-app1       Collaboration
│               ├── Nextcloud  (HTTP :80/:443)
│               ├── Mattermost (HTTP :8065)
│               └── Jitsi Meet (HTTPS :443, UDP :10000)
│
├── 10.0.50.14  lab-comm1      Communications
│               ├── iRedMail   (SMTP :25/:587, IMAP :143/:993)
│               ├── Zammad     (HTTP :3000)
│               └── Zabbix     (Server :10051, Web :3000)
│
├── 10.0.50.15  lab-proxy1     Infrastructure
│               ├── Traefik    (HTTP :80, HTTPS :443, Dashboard :8080)
│               └── Graylog    (Web :9000, Syslog :1514, GELF/UDP :12201)
│
├── 10.0.50.16  lab-pbx1       VoIP
│               └── FreePBX    (SIP :5060/:5061, RTP UDP :10000-20000)
│
├── 10.0.50.17  lab-biz1       Business
│               ├── SuiteCRM   (HTTP :80/:443)
│               ├── Odoo       (HTTP :8069, LiveChat :8072)
│               └── OpenKM     (HTTP :8080)
│
└── 10.0.50.18  lab-mgmt1      IT Management
                ├── Taiga      (HTTP :80/:443)
                ├── Snipe-IT   (HTTP :80/:443)
                └── GLPI       (HTTP :80/:443)
```

---

## Topology Diagram

```mermaid
graph TD
  GW["🌐 Gateway / Router\n10.0.50.1"]

  subgraph IDENTITY["Identity  —  lab-id1  10.0.50.11"]
    FIP["FreeIPA\nLDAP 389/636\nKerberos 88\nDNS 53\nPKI"]
    KC["Keycloak\nSSO :8443\nOIDC / SAML"]
  end

  subgraph DATABASE["Database  —  lab-db1  10.0.50.12"]
    PG["PostgreSQL 16\n:5432\n10 databases"]
    RD["Redis 7\n:6379\nsessions / cache"]
    ES["Elasticsearch 8\n:9200/:9300\n(Phase 4)"]
  end

  subgraph COLLAB["Collaboration  —  lab-app1  10.0.50.13"]
    NC["Nextcloud\n:80/:443"]
    MM["Mattermost\n:8065"]
    JT["Jitsi Meet\n:443 / UDP:10000"]
  end

  subgraph COMM["Communications  —  lab-comm1  10.0.50.14"]
    IM["iRedMail\nSMTP :25/:587\nIMAP :143/:993"]
    ZM["Zammad\n:3000"]
    ZB["Zabbix\n:10051 / :3000"]
  end

  subgraph INFRA["Infrastructure  —  lab-proxy1  10.0.50.15"]
    TR["Traefik\n:80/:443\nDashboard :8080"]
    GL["Graylog\n:9000\nSyslog :1514"]
  end

  subgraph VOIP["VoIP  —  lab-pbx1  10.0.50.16"]
    PBX["FreePBX / Asterisk\nSIP :5060/:5061\nRTP UDP :10000-20000"]
  end

  subgraph BIZ["Business  —  lab-biz1  10.0.50.17"]
    CRM["SuiteCRM\n:80/:443"]
    OD["Odoo ERP\n:8069"]
    KM["OpenKM\n:8080"]
  end

  subgraph MGMT["IT Management  —  lab-mgmt1  10.0.50.18"]
    TG["Taiga\n:80/:443"]
    SN["Snipe-IT\n:80/:443"]
    GP["GLPI\n:80/:443"]
  end

  GW --> TR
  TR -->|HTTPS routing| NC & MM & JT & IM & ZM & CRM & OD & KM & TG & SN & GP & KC
  FIP -->|LDAP federation| KC
  KC -->|OIDC/SAML tokens| NC & MM & JT & ZM & CRM & OD & TG & SN & GP
  PG -->|TCP 5432| NC & MM & ZM & CRM & OD & KM & TG & SN & GP & KC
  RD -->|TCP 6379| NC & MM & ZM & KC
  ES -->|TCP 9200| ZM & GL

  style IDENTITY fill:#dbeafe,stroke:#2563eb
  style DATABASE fill:#dcfce7,stroke:#16a34a
  style COLLAB  fill:#fef9c3,stroke:#ca8a04
  style COMM    fill:#ffe4e6,stroke:#e11d48
  style INFRA   fill:#f3e8ff,stroke:#9333ea
  style VOIP    fill:#ffedd5,stroke:#ea580c
  style BIZ     fill:#f0fdf4,stroke:#15803d
  style MGMT    fill:#e0f2fe,stroke:#0284c7
```

---

## DNS Records

FreeIPA (`lab-id1`) is the authoritative DNS server for the `it-stack.lab` zone.

### A Records

| Hostname | IP |
|----------|----|
| `lab-id1.it-stack.lab` | 10.0.50.11 |
| `lab-db1.it-stack.lab` | 10.0.50.12 |
| `lab-app1.it-stack.lab` | 10.0.50.13 |
| `lab-comm1.it-stack.lab` | 10.0.50.14 |
| `lab-proxy1.it-stack.lab` | 10.0.50.15 |
| `lab-pbx1.it-stack.lab` | 10.0.50.16 |
| `lab-biz1.it-stack.lab` | 10.0.50.17 |
| `lab-mgmt1.it-stack.lab` | 10.0.50.18 |

### CNAME Records (service subdomains → lab-proxy1)

| CNAME | Points To | Service |
|-------|-----------|---------|
| `sso.it-stack.lab` | `lab-id1.it-stack.lab` | Keycloak (direct; no proxy) |
| `ipa.it-stack.lab` | `lab-id1.it-stack.lab` | FreeIPA (direct; no proxy) |
| `cloud.it-stack.lab` | `lab-proxy1.it-stack.lab` | Nextcloud |
| `chat.it-stack.lab` | `lab-proxy1.it-stack.lab` | Mattermost |
| `meet.it-stack.lab` | `lab-proxy1.it-stack.lab` | Jitsi |
| `mail.it-stack.lab` | `lab-proxy1.it-stack.lab` | iRedMail webmail |
| `desk.it-stack.lab` | `lab-proxy1.it-stack.lab` | Zammad |
| `monitor.it-stack.lab` | `lab-proxy1.it-stack.lab` | Zabbix |
| `crm.it-stack.lab` | `lab-proxy1.it-stack.lab` | SuiteCRM |
| `erp.it-stack.lab` | `lab-proxy1.it-stack.lab` | Odoo |
| `dms.it-stack.lab` | `lab-proxy1.it-stack.lab` | OpenKM |
| `pm.it-stack.lab` | `lab-proxy1.it-stack.lab` | Taiga |
| `assets.it-stack.lab` | `lab-proxy1.it-stack.lab` | Snipe-IT |
| `itsm.it-stack.lab` | `lab-proxy1.it-stack.lab` | GLPI |
| `logs.it-stack.lab` | `lab-proxy1.it-stack.lab` | Graylog |
| `proxy.it-stack.lab` | `lab-proxy1.it-stack.lab` | Traefik dashboard |

---

## Firewall Rules Summary

### lab-id1 (Identity)

| Port | Protocol | From | Service |
|------|----------|------|---------|
| 53 | TCP/UDP | All LAN | DNS |
| 88 | TCP/UDP | All LAN | Kerberos |
| 389 | TCP | All LAN | LDAP |
| 443 | TCP | All LAN | FreeIPA HTTPS |
| 636 | TCP | All LAN | LDAPS |
| 8443 | TCP | All LAN | Keycloak |

### lab-db1 (Database)

| Port | Protocol | From | Service |
|------|----------|------|---------|
| 5432 | TCP | Application servers only | PostgreSQL |
| 6379 | TCP | Application servers only | Redis |
| 9200 | TCP | lab-proxy1, lab-comm1 | Elasticsearch |

### lab-proxy1 (Ingress)

| Port | Protocol | From | Service |
|------|----------|------|---------|
| 80 | TCP | All | HTTP (redirect to 443) |
| 443 | TCP | All | HTTPS (Traefik) |
| 9000 | TCP | LAN only | Graylog UI |
| 12201 | UDP | All LAN | GELF log input |
| 1514 | TCP/UDP | All LAN | Syslog input |

### lab-pbx1 (VoIP)

| Port | Protocol | From | Service |
|------|----------|------|---------|
| 5060 | UDP/TCP | All (SIP clients) | SIP |
| 5061 | TCP | All (SIP TLS) | SIP TLS |
| 10000–20000 | UDP | All (RTP clients) | RTP audio/video |

---

## Lab / Home Tier Topology (Tier 1A)

For 1–3 machine deployments, services are consolidated:

```
10.0.10.0/24 (example home lab subnet)

10.0.10.10  vm-01   FreeIPA + Keycloak + PostgreSQL + Redis + Traefik
10.0.10.11  vm-02   Nextcloud + Mattermost + Jitsi
10.0.10.12  vm-03   iRedMail + Zammad
```

See [ADR-006](adr-006-8server-layout.md) for tier descriptions and [Lab Deployment Plan](../02-implementation/03-lab-deployment-plan.md) for lab-specific configuration.
