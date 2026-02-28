---
doc: 03
title: "Lab Deployment Plan"
category: implementation
date: 2026-02-27
source: deployment/lab-deployment.md
---
# Lab Deployment Plan - Enterprise IT Stack
## School Testing Environment

**Document Version:** 1.0  
**Purpose:** Test and validate enterprise stack before production deployment  
**Environment:** School Lab Network  
**Timeline:** 2-4 weeks testing period

---

## Table of Contents

1. [Lab Environment Overview](#lab-environment-overview)
2. [Hardware Requirements](#hardware-requirements)
3. [Network Configuration](#network-configuration)
4. [Simplified Architecture](#simplified-architecture)
5. [Back Office Suite Integration](#back-office-suite-integration)
6. [Server Allocation](#server-allocation)
7. [Deployment Phases](#deployment-phases)
8. [Installation Quick Start](#installation-quick-start)
9. [Testing Scenarios](#testing-scenarios)
10. [Migration to Production](#migration-to-production)
11. [Lab Environment Cleanup](#lab-environment-cleanup)

---

## Lab Environment Overview

### Objectives

**Primary Goals:**
1. ✅ Validate all service integrations work together
2. ✅ Test SSO authentication flow (Keycloak + FreeIPA)
3. ✅ Verify backup and restore procedures
4. ✅ Practice installation and configuration
5. ✅ Identify potential issues before production
6. ✅ Train IT staff on administration
7. ✅ Document actual deployment time and complexity

**What We're Testing:**
- Single Sign-On (SSO) across all applications
- Email services (sending/receiving)
- File sharing and collaboration (Nextcloud)
- Team chat (Mattermost)
- Video conferencing (Jitsi)
- Help desk system (Zammad)
- Backup and recovery procedures
- User provisioning automation
- Mobile access

**What We're NOT Testing in Lab:**
- High availability / clustering (single instances only)
- Full-scale load testing (limited to 10-20 test users)
- Production-grade security hardening (basic security only)
- Geographic redundancy
- 24/7 operations

### Success Criteria

The lab deployment is successful when:
- [ ] All 10+ services are installed and running
- [ ] SSO works: One login accesses all services
- [ ] User can: Send email, share files, chat, video call, submit help desk ticket
- [ ] Backup script successfully backs up all services
- [ ] Restore procedure works for at least one service
- [ ] Mobile apps can connect to all services
- [ ] Documentation is accurate and tested

---

## Hardware Requirements

### Minimum Lab Setup (All-in-One)

**Option 1: Single Powerful Computer**
```
Minimum Specs:
- CPU: 8 cores / 16 threads (Intel i7/i9 or AMD Ryzen 7/9)
- RAM: 32 GB (64 GB recommended)
- Storage: 500 GB SSD
- Network: 1 Gbps Ethernet

This can run all services on one machine using Docker or VMs.
Good for: Quick proof-of-concept, limited users
```

**Option 2: Three-Server Setup (Recommended)**
```
Server 1 - "Infrastructure" (Identity + Database):
- CPU: 4 cores
- RAM: 16 GB
- Storage: 100 GB SSD
- Services: FreeIPA, Keycloak, PostgreSQL, Redis

Server 2 - "Applications":
- CPU: 6 cores
- RAM: 16 GB
- Storage: 200 GB SSD
- Services: Nextcloud, Mattermost, Jitsi, Zammad

Server 3 - "Communications":
- CPU: 4 cores
- RAM: 8 GB
- Storage: 100 GB SSD
- Services: iRedMail, Reverse Proxy, Monitoring

Total: 14 cores, 40 GB RAM, 400 GB storage
Good for: Realistic testing, proper separation of concerns
```

**Option 3: Five-Server Setup (Most Realistic)**
```
Server 1 - Identity & Auth:
- FreeIPA, Keycloak
- 4 cores, 8 GB RAM, 100 GB

Server 2 - Database:
- PostgreSQL, Redis
- 4 cores, 12 GB RAM, 100 GB

Server 3 - Collaboration:
- Nextcloud, Mattermost
- 4 cores, 12 GB RAM, 150 GB

Server 4 - Communications:
- Jitsi, iRedMail, Zammad
- 4 cores, 8 GB RAM, 100 GB

Server 5 - Infrastructure:
- Reverse Proxy, Monitoring, Backup
- 2 cores, 4 GB RAM, 200 GB

Total: 18 cores, 44 GB RAM, 650 GB storage
Good for: Production-like testing, full architecture validation
```

### Recommended: Use School Lab Computers

**Typical School Lab Computer Specs:**
- Dell OptiPlex / HP EliteDesk / Lenovo ThinkCentre
- 4-8 cores, 8-16 GB RAM, 256-512 GB SSD
- Windows 10/11 (will install Linux)

**Strategy**: Use 3-5 lab computers, install Ubuntu Server on each

---

## Network Configuration

### Lab Network Architecture

```
                    School Network
                          │
                   ┌──────┴──────┐
                   │ Lab Switch  │
                   └──────┬──────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
   ┌────▼────┐       ┌────▼────┐      ┌────▼────┐
   │ Lab-VM1 │       │ Lab-VM2 │      │ Lab-VM3 │
   │Identity │       │  Apps   │      │  Comm   │
   │10.0.X.11│       │10.0.X.12│      │10.0.X.13│
   └─────────┘       └─────────┘      └─────────┘
```

### IP Address Scheme (Lab)

**Option A: Use School's Existing Network**
- Ask network admin for a subnet or IP range
- Example: 10.10.50.10-20 (if school uses 10.10.x.x)
- Configure static IPs on each server
- Use school's DNS or configure local DNS

**Option B: Isolated Lab Network**
- Connect all lab computers to a separate switch
- Use private subnet: 192.168.100.0/24
- Configure one computer as router/gateway
- Full control, but isolated from school network

**Recommended Approach: Hybrid**
```
Use school network for connectivity, but isolated VLAN:
Lab Subnet: 10.0.50.0/24 (adjust to match school's scheme)

IP Assignments:
10.0.50.10 - Gateway (if needed)
10.0.50.11 - lab-id1 (FreeIPA, Keycloak)
10.0.50.12 - lab-db1 (PostgreSQL, Redis)
10.0.50.13 - lab-app1 (Nextcloud, Mattermost)
10.0.50.14 - lab-comm1 (Jitsi, Mail, Zammad)
10.0.50.15 - lab-infra1 (Proxy, Monitoring)
10.0.50.20-50 - DHCP range for test clients
```

### DNS Configuration

**Option 1: Edit /etc/hosts on Each Server**
```bash
# Add to /etc/hosts on all servers
10.0.50.11  id.lab.local ipa.lab.local sso.lab.local
10.0.50.12  db.lab.local
10.0.50.13  cloud.lab.local chat.lab.local
10.0.50.14  mail.lab.local meet.lab.local desk.lab.local
10.0.50.15  proxy.lab.local monitor.lab.local
```

**Option 2: Use FreeIPA's DNS (Better)**
- FreeIPA includes DNS server
- Automatically manages DNS records
- Set all servers to use FreeIPA as DNS

**Test Domain:** `lab.local` or `company.lab` (not a real domain)

### External Access

**For Testing Mobile Apps / Remote Access:**
1. **SSH Tunnel** (from your laptop):
   ```bash
   ssh -L 8443:cloud.lab.local:443 username@lab-gateway
   # Access: https://localhost:8443
   ```

2. **ngrok** (temporary public URL):
   ```bash
   # On proxy server
   ngrok http 443
   # Gives temporary URL like: https://abc123.ngrok.io
   ```

3. **Cloudflare Tunnel** (better for longer testing):
   ```bash
   cloudflared tunnel --url https://cloud.lab.local
   ```

---

## Simplified Architecture

### Lab Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      Test Clients                           │
│  (Your Laptop, Phone, Other Lab Computers)                  │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│              lab-infra1 (Proxy Server)                      │
│  Traefik Reverse Proxy - Routes all traffic                │
│  Ports: 80, 443                                             │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
┌───────▼──────┐  ┌──────▼──────┐  ┌─────▼──────┐
│  lab-id1     │  │  lab-app1   │  │ lab-comm1  │
│              │  │             │  │            │
│ FreeIPA      │  │ Nextcloud   │  │ Jitsi      │
│ Keycloak ────┼──┤ Mattermost  │  │ iRedMail   │
│              │  │             │  │ Zammad     │
└──────┬───────┘  └──────┬──────┘  └─────┬──────┘
       │                 │                │
       └─────────────────┼────────────────┘
                         │
                  ┌──────▼──────┐
                  │  lab-db1    │
                  │             │
                  │ PostgreSQL  │
                  │ Redis       │
                  └─────────────┘
```

### Simplified vs. Production Differences

| Component | Production | Lab |
|-----------|-----------|-----|
| FreeIPA | 2 servers (HA) | 1 server |
| Keycloak | 2 nodes (cluster) | 1 node |
| PostgreSQL | Patroni cluster (2-3 nodes) | Single instance |
| Redis | Sentinel/Cluster | Single instance |
| Nextcloud | Load balanced | Single instance |
| Mattermost | HA deployment | Single instance |
| Mail Server | Redundant MX | Single server |
| Reverse Proxy | HAProxy + backup | Single Traefik |
| Backup | Dedicated server + offsite | Local backups |
| Monitoring | Full Zabbix + Graylog | Basic monitoring |

**Key Point:** Same software, same integrations, just no redundancy

---

## Back Office Suite Integration

### Overview

A complete back office suite transforms your infrastructure from basic collaboration tools into a full enterprise management platform. This section covers essential business systems including VoIP calling, CRM, ERP, accounting, project management, and more.

### Back Office Components

#### 1. VoIP/PBX System (FreePBX/Asterisk)

**Purpose:** Complete business phone system with extensions, call routing, voicemail, IVR, and call recording

**Solution: FreePBX (Asterisk-based)**
```
Features:
├── Internal extensions (100-999)
├── Inbound/outbound calling via SIP trunk
├── Auto-attendant (IVR)
├── Call queues for departments
├── Voicemail to email
├── Call recording (compliance)
├── Conference bridges
├── Softphone support (desktop/mobile)
├── Integration with CRM for click-to-call
└── Real-time call monitoring

Hardware Requirements:
- CPU: 2-4 cores
- RAM: 4-8 GB
- Storage: 50-100 GB (call recordings can grow)
- Network: Dedicated VLAN recommended for QoS
```

**Deployment:**
```bash
# Server: lab-voip1 (10.0.50.15)
# Install FreePBX (includes Asterisk)
cd /opt
wget https://www.freepbx.org/downloads/freepbx-distro-latest.iso
# Boot from ISO or use Docker container

# Docker alternative:
docker run -d --name freepbx \
  --net=host \
  --cap-add=NET_ADMIN \
  -v /data/freepbx:/data \
  -e TIMEZONE=America/New_York \
  tiredofit/freepbx:latest
```

**Integration Points:**
- **SSO:** LDAP integration with FreeIPA for user authentication
- **CRM:** CTI (Computer Telephony Integration) with SuiteCRM/EspoCRM
- **Email:** Voicemail notifications via iRedMail
- **Chat:** Mattermost integration for click-to-call
- **Monitoring:** Asterisk stats in Zabbix

**SIP Trunk Providers (for external calling):**
- Twilio
- Voip.ms
- Flowroute
- Telnyx
- Bandwidth.com

**Configuration Example:**
```
Extensions:
100-199: Executive team
200-299: Sales department
300-399: Support department
400-499: IT department
500-599: Operations

Ring Groups:
600: Sales (rings 200-299)
601: Support (rings 300-399)
602: IT (rings 400-499)

IVR Menu:
"Press 1 for Sales"
"Press 2 for Support"
"Press 3 for IT"
"Press 9 for Directory"
```

#### 2. CRM System (SuiteCRM or EspoCRM)

**Purpose:** Customer Relationship Management - track leads, contacts, deals, and customer interactions

**Solution: SuiteCRM (open-source Salesforce alternative)**
```
Features:
├── Contact management
├── Lead tracking and conversion
├── Sales pipeline management
├── Email integration (track all communications)
├── Calendar and task management
├── Reporting and dashboards
├── Mobile app
├── VoIP integration (click-to-call)
├── Workflow automation
└── Custom modules

Hardware Requirements:
- CPU: 2-4 cores
- RAM: 4-8 GB
- Storage: 50 GB
```

**Deployment:**
```bash
# Server: lab-app2 (10.0.50.16)
# Create database
sudo -u postgres psql
CREATE DATABASE suitecrm;
CREATE USER suitecrm WITH ENCRYPTED PASSWORD 'CrmPass2024!';
GRANT ALL PRIVILEGES ON DATABASE suitecrm TO suitecrm;
\q

# Install SuiteCRM
cd /var/www
sudo wget https://suitecrm.com/download/latest
sudo unzip SuiteCRM-*.zip
sudo chown -R www-data:www-data suitecrm
sudo chmod -R 755 suitecrm

# Configure nginx
sudo nano /etc/nginx/sites-available/crm.lab.local
```

**Nginx config:**
```nginx
server {
    listen 80;
    server_name crm.lab.local;
    root /var/www/suitecrm;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }
}
```

**Integration Points:**
- **SSO:** SAML integration with Keycloak
- **Email:** Sync with iRedMail accounts
- **VoIP:** Asterisk CTI connector for call logging
- **Calendar:** CalDAV sync with Nextcloud
- **Documents:** Attach files from Nextcloud

**Alternative: EspoCRM (lighter weight option)**
```bash
docker run -d --name espocrm \
  -p 8090:80 \
  -e ESPOCRM_DATABASE_HOST=10.0.50.11 \
  -e ESPOCRM_DATABASE_NAME=espocrm \
  -e ESPOCRM_DATABASE_USER=espocrm \
  -e ESPOCRM_DATABASE_PASSWORD=EspoPass2024! \
  -e ESPOCRM_ADMIN_USERNAME=admin \
  -e ESPOCRM_ADMIN_PASSWORD=AdminPass2024! \
  -e ESPOCRM_SITE_URL=http://crm.lab.local \
  espocrm/espocrm:latest
```

#### 3. ERP System (Odoo or ERPNext)

**Purpose:** Enterprise Resource Planning - integrates accounting, inventory, HR, manufacturing, and more

**Solution: Odoo Community Edition**
```
Core Modules:
├── Accounting & Finance
│   ├── General ledger
│   ├── Invoicing
│   ├── Accounts receivable/payable
│   ├── Bank reconciliation
│   └── Multi-currency support
├── Sales Management
│   ├── Quotations and sales orders
│   ├── eCommerce integration
│   └── Customer portal
├── Purchase Management
│   ├── Purchase orders
│   ├── Vendor management
│   └── Procurement automation
├── Inventory & Warehouse
│   ├── Stock management
│   ├── Barcode scanning
│   ├── Multi-warehouse
│   └── Logistics
├── Manufacturing
│   ├── Bill of Materials (BoM)
│   ├── Work orders
│   └── Quality control
├── Human Resources
│   ├── Employee management
│   ├── Attendance tracking
│   ├── Leave management
│   ├── Recruitment
│   └── Performance reviews
├── Project Management
│   ├── Tasks and projects
│   ├── Timesheets
│   ├── Resource allocation
│   └── Gantt charts
└── Point of Sale (POS)
    ├── Retail management
    ├── Multi-store support
    └── Offline mode

Hardware Requirements:
- CPU: 4-8 cores
- RAM: 8-16 GB
- Storage: 100-200 GB
```

**Deployment:**
```bash
# Server: lab-erp1 (10.0.50.17)
# Install Odoo
sudo wget -O - https://nightly.odoo.com/odoo.key | sudo gpg --dearmor -o /usr/share/keyrings/odoo.gpg
echo 'deb [signed-by=/usr/share/keyrings/odoo.gpg] https://nightly.odoo.com/17.0/nightly/deb/ ./' | sudo tee /etc/apt/sources.list.d/odoo.list
sudo apt update
sudo apt install odoo -y

# Configure Odoo
sudo nano /etc/odoo/odoo.conf
```

**Odoo configuration:**
```ini
[options]
admin_passwd = OdooMaster2024!
db_host = 10.0.50.11
db_port = 5432
db_user = odoo
db_password = OdooDb2024!
xmlrpc_port = 8069
proxy_mode = True
```

**Create database:**
```bash
sudo -u postgres psql
CREATE DATABASE odoo;
CREATE USER odoo WITH ENCRYPTED PASSWORD 'OdooDb2024!';
GRANT ALL PRIVILEGES ON DATABASE odoo TO odoo;
\q

sudo systemctl restart odoo
```

**Integration Points:**
- **SSO:** OAuth2 with Keycloak
- **Email:** Send invoices/documents via iRedMail
- **Documents:** Integrate with Nextcloud for file storage
- **VoIP:** SIP connector for sales calls
- **HR:** Sync employees with FreeIPA
- **Time Tracking:** Import from Nextcloud Timetracker

**Alternative: ERPNext (Frappe Framework)**
```bash
# More modern UI, Python-based
docker run -d --name erpnext \
  -p 8080:8000 \
  -e MARIADB_HOST=10.0.50.11 \
  frappe/erpnext:latest
```

#### 4. Document Management (OpenKM or Alfresco)

**Purpose:** Advanced document management beyond basic file storage - version control, workflows, compliance

**Solution: OpenKM Community Edition**
```
Features:
├── Document versioning
├── Metadata tagging
├── Full-text search (OCR support)
├── Workflow automation
├── Records management (compliance)
├── Email archiving
├── Digital signatures
├── Audit trails
├── Document templates
└── Mobile access

Hardware Requirements:
- CPU: 2-4 cores
- RAM: 4-8 GB
- Storage: 100-500 GB
```

**Deployment:**
```bash
# Server: lab-app2 (10.0.50.16)
docker run -d --name openkm \
  -p 8090:8080 \
  -v /data/openkm:/opt/openkm \
  -e DB_HOST=10.0.50.11 \
  -e DB_NAME=openkm \
  -e DB_USER=openkm \
  -e DB_PASS=DmsPass2024! \
  openkm/openkm-ce:latest
```

**Integration Points:**
- **SSO:** LDAP with FreeIPA
- **Email:** Import emails from iRedMail
- **Odoo/CRM:** Attach DMS documents to invoices/contracts
- **Nextcloud:** Bidirectional sync for user documents

#### 5. Project Management (Taiga or OpenProject)

**Purpose:** Agile project management, issue tracking, and team collaboration

**Solution: Taiga (modern, agile-focused)**
```
Features:
├── Kanban boards
├── Scrum support (sprints, backlog)
├── Issue tracking
├── Wiki documentation
├── Time tracking
├── Gantt charts
├── Custom workflows
├── Multi-project support
└── Mobile apps

Hardware Requirements:
- CPU: 2 cores
- RAM: 4 GB
- Storage: 20 GB
```

**Deployment:**
```bash
# Server: lab-app3 (10.0.50.18)
git clone https://github.com/kaleidos-ventures/taiga-docker.git
cd taiga-docker
nano docker-compose.yml
# Update environment variables

docker-compose up -d
```

**Integration Points:**
- **SSO:** SAML with Keycloak
- **Chat:** Mattermost notifications for project updates
- **Git:** GitHub/GitLab integration
- **Time:** Export timesheets to Odoo

**Alternative: OpenProject**
```bash
# More traditional PM tool, Gantt-focused
docker run -d -p 8080:80 \
  -e SECRET_KEY_BASE=secret \
  -e DATABASE_URL=postgres://openproject:pass@10.0.50.11/openproject \
  openproject/community:latest
```

#### 6. Asset & Inventory Management (Snipe-IT)

**Purpose:** IT asset tracking, inventory management, license management

**Solution: Snipe-IT**
```
Features:
├── Asset tracking (hardware, software)
├── Check-in/check-out to employees
├── License management
├── Maintenance schedules
├── Depreciation tracking
├── QR code/barcode support
├── Custom fields
├── Audit reports
└── Email notifications

Hardware Requirements:
- CPU: 2 cores
- RAM: 2-4 GB
- Storage: 20 GB
```

**Deployment:**
```bash
# Server: lab-app3 (10.0.50.18)
docker run -d --name snipeit \
  -p 8085:80 \
  -e MYSQL_PORT_3306_TCP_ADDR=10.0.50.11 \
  -e MYSQL_PORT_3306_TCP_PORT=3306 \
  -e MYSQL_DATABASE=snipeit \
  -e MYSQL_USER=snipeit \
  -e MYSQL_PASSWORD=SnipePass2024! \
  -e APP_URL=http://assets.lab.local \
  -v /data/snipeit:/var/lib/snipeit \
  snipe/snipe-it:latest
```

**Integration Points:**
- **SSO:** LDAP with FreeIPA
- **HR:** Sync employees from Odoo
- **Procurement:** Link to Odoo purchase orders

#### 7. Help Desk Expansion (Zammad + GLPI)

**You already have Zammad, but add GLPI for IT service management:**

**GLPI (IT Service Management)**
```
Features:
├── IT asset inventory (auto-discovery)
├── Ticket system
├── Change management
├── Problem management
├── Service catalog
├── Knowledge base
├── SLA management
└── Software license tracking

Hardware Requirements:
- CPU: 2 cores
- RAM: 4 GB
- Storage: 30 GB
```

**Deployment:**
```bash
docker run -d --name glpi \
  -p 8084:80 \
  -e TIMEZONE=America/New_York \
  diouxx/glpi:latest
```

### Updated Architecture with Back Office Suite

```
┌──────────────────────────────────────────────────────────────────┐
│                       External World                             │
│  SIP Trunk Provider │ Email │ Web Clients │ Mobile Apps          │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
┌────────────────────────────────▼─────────────────────────────────┐
│              lab-infra1 (Reverse Proxy + Edge)                   │
│  Traefik - Routes: *.lab.local                                   │
│  Ports: 80, 443, 5060 (SIP)                                      │
└────────────────────────────────┬─────────────────────────────────┘
                                 │
        ┌────────────────────────┼────────────────────┐
        │                        │                    │
┌───────▼───────┐     ┌──────────▼────────┐   ┌──────▼──────────┐
│  IDENTITY     │     │   COLLABORATION   │   │  COMMUNICATIONS │
│  lab-id1      │     │   lab-app1        │   │  lab-comm1      │
│  10.0.50.11   │     │   10.0.50.12      │   │  10.0.50.13     │
│               │     │                   │   │                 │
│ • FreeIPA     │◄────┤ • Nextcloud       │   │ • iRedMail      │
│ • Keycloak    │     │ • Mattermost      │   │ • Zammad        │
│ • PostgreSQL  │     │ • Jitsi Meet      │   │ • Monitoring    │
│ • Redis       │     └───────────────────┘   └─────────────────┘
└───────┬───────┘              │                      │
        │                      │                      │
        └──────────────────────┼──────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
┌───────▼───────┐     ┌────────▼──────────┐   ┌──────▼──────────┐
│  VOIP/PBX     │     │   BUSINESS OPS    │   │  ERP/PROJECTS   │
│  lab-voip1    │     │   lab-app2        │   │  lab-erp1       │
│  10.0.50.15   │     │   10.0.50.16      │   │  10.0.50.17     │
│               │     │                   │   │                 │
│ • FreePBX     │◄────┤ • SuiteCRM        │   │ • Odoo ERP      │
│ • Asterisk    │     │ • OpenKM (DMS)    │   │ • Accounting    │
│ • SIP Trunk   │     │ • E-signing       │   │ • Inventory     │
└───────────────┘     └───────────────────┘   │ • HR/Payroll    │
                               │              │ • Manufacturing │
                      ┌────────▼──────────┐   └─────────────────┘
                      │  IT/PROJECT MGMT  │
                      │  lab-app3         │
                      │  10.0.50.18       │
                      │                   │
                      │ • Taiga (PM)      │
                      │ • Snipe-IT        │
                      │ • GLPI (ITSM)     │
                      └───────────────────┘
```

### Complete Service Roster

| Category | Service | URL | Server | Purpose |
|----------|---------|-----|--------|---------|
| **Identity** | FreeIPA | https://ipa.lab.local | lab-id1 | LDAP/DNS/Kerberos |
| | Keycloak | https://sso.lab.local | lab-id1 | SSO/OAuth Provider |
| **Collaboration** | Nextcloud | https://cloud.lab.local | lab-app1 | Files/Calendar/Docs |
| | Mattermost | https://chat.lab.local | lab-app1 | Team Chat |
| | Jitsi Meet | https://meet.lab.local | lab-app1 | Video Conferencing |
| **Communications** | iRedMail | https://mail.lab.local | lab-comm1 | Email Server |
| | Zammad | https://desk.lab.local | lab-comm1 | Help Desk |
| **VoIP** | FreePBX | https://voip.lab.local | lab-voip1 | PBX/Phone System |
| **Business** | SuiteCRM | https://crm.lab.local | lab-app2 | CRM |
| | OpenKM | https://docs.lab.local | lab-app2 | Document Management |
| **ERP** | Odoo | https://erp.lab.local | lab-erp1 | ERP/Accounting/HR |
| **IT/Projects** | Taiga | https://projects.lab.local | lab-app3 | Project Management |
| | Snipe-IT | https://assets.lab.local | lab-app3 | Asset Management |
| | GLPI | https://itsm.lab.local | lab-app3 | IT Service Mgmt |
| **Infrastructure** | Traefik | https://proxy.lab.local | lab-infra1 | Reverse Proxy |
| | Zabbix | https://monitor.lab.local | lab-comm1 | Monitoring |

### Integration Flow Examples

**Example 1: Customer Call to Sale**
1. Customer calls main number → FreePBX IVR
2. Selects "Sales" → Routes to sales queue
3. Sales rep answers (call logged in CRM automatically)
4. Rep creates lead in SuiteCRM during call
5. After call: Send quote from Odoo
6. Quote approved → Generate invoice in Odoo
7. Invoice emailed from iRedMail
8. Payment recorded → Accounting in Odoo
9. Inventory adjusted automatically

**Example 2: New Employee Onboarding**
1. HR creates employee in Odoo HR module
2. Employee synced to FreeIPA (LDAP)
3. Email account auto-created in iRedMail
4. VoIP extension auto-provisioned in FreePBX
5. User gets SSO access to all systems via Keycloak
6. IT creates asset assignment in Snipe-IT
7. Access to Nextcloud, Mattermost, CRM granted
8. Welcome email sent automatically

**Example 3: Project Execution**
1. Project created in Taiga with milestones
2. Tasks assigned to team members
3. Time tracked in Taiga
4. Documents stored in Nextcloud/OpenKM
5. Team communication in Mattermost
6. Client meetings via Jitsi
7. Client support tickets in Zammad
8. Time/expenses exported to Odoo for billing
9. Invoice generated and sent to client

### Resource Requirements (Extended Setup)

**New Servers Needed:**

#### Server 4: lab-voip1 (VoIP)
```
Hostname: lab-voip1.lab.local
IP: 10.0.50.15
OS: Ubuntu 24.04 or FreePBX Distro
CPU: 4 cores
RAM: 4-6 GB
Storage: 100 GB (call recordings)
Services: FreePBX, Asterisk
```

#### Server 5: lab-app2 (CRM/DMS)
```
Hostname: lab-app2.lab.local
IP: 10.0.50.16
OS: Ubuntu 24.04 Server
CPU: 4-6 cores
RAM: 8-12 GB
Storage: 150 GB
Services: SuiteCRM, OpenKM
```

#### Server 6: lab-erp1 (ERP)
```
Hostname: lab-erp1.lab.local
IP: 10.0.50.17
OS: Ubuntu 24.04 Server
CPU: 6-8 cores
RAM: 12-16 GB
Storage: 200 GB
Services: Odoo
```

#### Server 7: lab-app3 (IT/Projects)
```
Hostname: lab-app3.lab.local
IP: 10.0.50.18
OS: Ubuntu 24.04 Server
CPU: 4 cores
RAM: 8 GB
Storage: 100 GB
Services: Taiga, Snipe-IT, GLPI
```

**Total Extended Setup:**
- **Servers:** 7 (original 3 + 4 new)
- **Total CPU:** 36-42 cores
- **Total RAM:** 88-96 GB
- **Total Storage:** 1.1 TB
- **Concurrent Users:** 50-100

### Phased Rollout Strategy

**Phase 1: Core (Weeks 1-2)**
- Identity (FreeIPA, Keycloak)
- Database (PostgreSQL, Redis)
- Collaboration (Nextcloud, Mattermost, Jitsi)
- Communications (iRedMail, Zammad)

**Phase 2: VoIP (Week 3)**
- FreePBX/Asterisk installation
- Configure extensions and ring groups
- Set up IVR
- Test internal calling
- Configure SIP trunk (optional)
- CRM integration

**Phase 3: Business Systems (Week 4)**
- SuiteCRM deployment
- Odoo ERP deployment
- Initial configuration
- Data import (if migrating)
- SSO integration

**Phase 4: Extended Systems (Week 5)**
- Document Management (OpenKM)
- Project Management (Taiga)
- Asset Management (Snipe-IT)
- GLPI ITSM

**Phase 5: Integration & Testing (Week 6)**
- Cross-system integrations
- Workflow automation
- User acceptance testing
- Documentation
- Training materials

### Recommended Deployment Order

**Priority 1 (Critical):**
1. FreeIPA (identity foundation)
2. PostgreSQL/Redis (data layer)
3. Keycloak (SSO)
4. Nextcloud (collaboration)
5. iRedMail (email)
6. FreePBX (VoIP)

**Priority 2 (High Value):**
7. SuiteCRM (customer management)
8. Odoo (business operations)
9. Mattermost (internal communication)
10. Zammad (support tickets)

**Priority 3 (Enhancement):**
11. Jitsi (video calls)
12. Taiga/OpenProject (project management)
13. OpenKM (document management)
14. Snipe-IT (asset tracking)
15. GLPI (IT service management)

---

## Server Allocation

### Deployment Strategy: 3-Server Setup

Based on typical school lab availability, here's the recommended 3-server configuration:

#### Server 1: lab-id1 (Identity & Database)
```
Hostname: lab-id1.lab.local
IP: 10.0.50.11
OS: Ubuntu 24.04 Server

Services:
├── FreeIPA (LDAP/Kerberos/DNS)
│   └── Ports: 389, 636, 88, 464, 53
├── Keycloak (SSO)
│   └── Port: 8080
└── PostgreSQL (Shared database)
    └── Port: 5432
    └── Redis (Cache)
        └── Port: 6379

Resources: 8 GB RAM, 4 cores, 100 GB disk
```

#### Server 2: lab-app1 (Applications)
```
Hostname: lab-app1.lab.local
IP: 10.0.50.12
OS: Ubuntu 24.04 Server

Services:
├── Nextcloud (Files, Calendar, Collaboration)
│   └── Port: 80 (internal)
├── Mattermost (Chat)
│   └── Port: 8065
└── Jitsi Meet (Video)
    └── Ports: 80, 443, 10000/udp

Resources: 12 GB RAM, 6 cores, 200 GB disk
```

#### Server 3: lab-comm1 (Communications & Infrastructure)
```
Hostname: lab-comm1.lab.local
IP: 10.0.50.13
OS: Ubuntu 24.04 Server

Services:
├── Traefik (Reverse Proxy - Entry Point)
│   └── Ports: 80, 443
├── iRedMail (Email Server)
│   └── Ports: 25, 587, 993
├── Zammad (Help Desk)
│   └── Port: 3000
└── Zabbix (Monitoring)
    └── Port: 8080

Resources: 12 GB RAM, 4 cores, 150 GB disk
```

### Resource Summary
- **Total:** 32 GB RAM, 14 cores, 450 GB storage
- **Actual Usage:** ~24 GB RAM, 10 cores (services won't max out)
- **Headroom:** Sufficient for 10-20 concurrent test users

---

## Deployment Phases

### Phase 1: Foundation (Week 1, Days 1-3)

**Day 1: Lab Preparation**
- [ ] Secure access to 3 lab computers
- [ ] Document hardware specs (CPU, RAM, disk)
- [ ] Obtain network information from school IT
  - Available IP range
  - Gateway/DNS servers
  - Internet access confirmation
- [ ] Download Ubuntu 24.04 Server ISO
- [ ] Create bootable USB drives (3x)
- [ ] Backup any existing data on lab computers

**Day 2: OS Installation**
- [ ] Install Ubuntu Server on all 3 computers
  - Set hostnames: lab-id1, lab-app1, lab-comm1
  - Configure static IPs: 10.0.50.11, .12, .13
  - Set timezone to your location
  - Enable OpenSSH server
  - Create admin user: `labadmin`
- [ ] Verify network connectivity
  ```bash
  ping google.com
  ping 10.0.50.11  # From each server to others
  ssh labadmin@10.0.50.11  # Test SSH
  ```
- [ ] Update all systems
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```
- [ ] Install common tools on all servers
  ```bash
  sudo apt install -y vim curl wget git htop net-tools
  ```

**Day 3: FreeIPA + PostgreSQL Setup**
- [ ] Install FreeIPA on lab-id1
  ```bash
  sudo hostnamectl set-hostname lab-id1.lab.local
  sudo apt install -y freeipa-server freeipa-server-dns
  
  sudo ipa-server-install \
    --domain=lab.local \
    --realm=LAB.LOCAL \
    --ds-password='LabDS2024!' \
    --admin-password='LabAdmin2024!' \
    --hostname=lab-id1.lab.local \
    --ip-address=10.0.50.11 \
    --setup-dns \
    --forwarder=8.8.8.8 \
    --forwarder=1.1.1.1 \
    --no-ntp \
    --unattended
  ```
- [ ] Test FreeIPA
  ```bash
  kinit admin
  ipa user-find
  ```
- [ ] Install PostgreSQL on lab-id1
  ```bash
  sudo apt install -y postgresql-16 postgresql-contrib
  sudo systemctl enable postgresql
  
  # Configure to accept network connections
  sudo nano /etc/postgresql/16/main/postgresql.conf
  # Change: listen_addresses = '10.0.50.11'
  
  sudo nano /etc/postgresql/16/main/pg_hba.conf
  # Add: host all all 10.0.50.0/24 scram-sha-256
  
  sudo systemctl restart postgresql
  ```
- [ ] Install Redis on lab-id1
  ```bash
  sudo apt install -y redis-server
  sudo nano /etc/redis/redis.conf
  # Change: bind 10.0.50.11
  sudo systemctl restart redis-server
  ```

### Phase 2: Identity & SSO (Week 1, Days 4-5)

**Day 4: Keycloak Installation**
- [ ] Install Java on lab-id1
  ```bash
  sudo apt install -y openjdk-17-jdk
  ```
- [ ] Create Keycloak database
  ```bash
  sudo -u postgres psql
  CREATE DATABASE keycloak;
  CREATE USER keycloak WITH ENCRYPTED PASSWORD 'KeycloakLab2024!';
  GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
  \q
  ```
- [ ] Download and install Keycloak
  ```bash
  cd /opt
  sudo wget https://github.com/keycloak/keycloak/releases/download/24.0.0/keycloak-24.0.0.tar.gz
  sudo tar -xzf keycloak-24.0.0.tar.gz
  sudo mv keycloak-24.0.0 keycloak
  sudo useradd -r -s /bin/false keycloak
  sudo chown -R keycloak:keycloak /opt/keycloak
  ```
- [ ] Configure Keycloak
  ```bash
  sudo nano /opt/keycloak/conf/keycloak.conf
  ```
  Add:
  ```
  db=postgres
  db-url=jdbc:postgresql://10.0.50.11:5432/keycloak
  db-username=keycloak
  db-password=KeycloakLab2024!
  hostname=sso.lab.local
  http-enabled=true
  http-port=8080
  proxy=edge
  ```
- [ ] Build and start Keycloak
  ```bash
  cd /opt/keycloak
  sudo -u keycloak ./bin/kc.sh build
  
  # Create systemd service
  sudo nano /etc/systemd/system/keycloak.service
  ```
  Content:
  ```ini
  [Unit]
  Description=Keycloak
  After=network.target postgresql.service
  
  [Service]
  Type=idle
  User=keycloak
  Group=keycloak
  ExecStart=/opt/keycloak/bin/kc.sh start
  Restart=on-failure
  
  [Install]
  WantedBy=multi-user.target
  ```
  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable keycloak
  sudo systemctl start keycloak
  
  # Create admin user
  cd /opt/keycloak
  export KCADM=/opt/keycloak/bin/kcadm.sh
  sudo -u keycloak $KCADM config credentials \
    --server http://localhost:8080 \
    --realm master \
    --user admin \
    --password LabAdmin2024!
  ```

**Day 5: Keycloak LDAP Integration**
- [ ] Access Keycloak: http://10.0.50.11:8080 (from lab network)
- [ ] Login: admin / LabAdmin2024!
- [ ] Create realm: "lab"
- [ ] Configure LDAP User Federation
  - Go to: User Federation → Add provider → LDAP
  - Settings:
    ```
    Edit Mode: WRITABLE
    Vendor: Red Hat Directory Server
    Connection URL: ldap://10.0.50.11
    Bind DN: uid=admin,cn=users,cn=accounts,dc=lab,dc=local
    Bind Credential: LabAdmin2024!
    Users DN: cn=users,cn=accounts,dc=lab,dc=local
    Username LDAP Attribute: uid
    RDN LDAP Attribute: uid
    UUID LDAP Attribute: ipaUniqueID
    User Object Classes: person,inetOrgPerson
    ```
  - Click "Test Connection" → Should succeed
  - Click "Test Authentication" → Should succeed
  - Click "Synchronize all users"
- [ ] Test login with FreeIPA user
  ```bash
  # On lab-id1, create test user
  kinit admin
  ipa user-add testuser --first=Test --last=User --email=test@lab.local --password
  # Set password when prompted: TestUser123!
  ```
  - Try logging into Keycloak with: testuser / TestUser123!

### Phase 3: Core Applications (Week 2, Days 6-9)

**Day 6: Nextcloud Installation (on lab-app1)**
- [ ] Configure DNS to point to lab-app1
  ```bash
  # On lab-id1 (FreeIPA DNS)
  kinit admin
  ipa dnsrecord-add lab.local cloud --a-rec=10.0.50.12
  ```
- [ ] Install Nginx and PHP on lab-app1
  ```bash
  sudo apt install -y nginx php8.3-fpm php8.3-cli php8.3-common \
    php8.3-pgsql php8.3-zip php8.3-gd php8.3-mbstring php8.3-curl \
    php8.3-xml php8.3-bcmath php8.3-intl php8.3-imagick \
    php8.3-apcu php8.3-redis php8.3-gmp unzip
  ```
- [ ] Create Nextcloud database
  ```bash
  # SSH to lab-id1
  sudo -u postgres psql
  CREATE DATABASE nextcloud;
  CREATE USER nextcloud WITH ENCRYPTED PASSWORD 'NextcloudLab2024!';
  GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
  \q
  ```
- [ ] Download Nextcloud
  ```bash
  # On lab-app1
  cd /tmp
  wget https://download.nextcloud.com/server/releases/nextcloud-28.0.0.tar.bz2
  sudo tar -xjf nextcloud-28.0.0.tar.bz2 -C /var/www/
  sudo chown -R www-data:www-data /var/www/nextcloud
  ```
- [ ] Configure PHP-FPM
  ```bash
  sudo nano /etc/php/8.3/fpm/php.ini
  # Set: memory_limit = 512M
  # Set: upload_max_filesize = 2G
  # Set: post_max_size = 2G
  
  sudo systemctl restart php8.3-fpm
  ```
- [ ] Configure Nginx (basic, simplified version)
  ```bash
  sudo nano /etc/nginx/sites-available/nextcloud
  ```
  Content:
  ```nginx
  server {
      listen 80;
      server_name cloud.lab.local;
      root /var/www/nextcloud;
      
      location / {
          try_files $uri $uri/ /index.php$request_uri;
      }
      
      location ~ \.php(?:$|/) {
          fastcgi_split_path_info ^(.+?\.php)(/.*)$;
          fastcgi_pass unix:/run/php/php8.3-fpm.sock;
          fastcgi_index index.php;
          include fastcgi_params;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          fastcgi_param PATH_INFO $fastcgi_path_info;
      }
  }
  ```
  ```bash
  sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
  sudo nginx -t
  sudo systemctl restart nginx
  ```
- [ ] Install Nextcloud via command line
  ```bash
  cd /var/www/nextcloud
  sudo -u www-data php occ maintenance:install \
    --database="pgsql" \
    --database-name="nextcloud" \
    --database-host="10.0.50.11:5432" \
    --database-user="nextcloud" \
    --database-pass="NextcloudLab2024!" \
    --admin-user="admin" \
    --admin-pass="LabAdmin2024!" \
    --data-dir="/var/www/nextcloud/data"
  
  # Add trusted domains
  sudo -u www-data php occ config:system:set trusted_domains 0 --value=cloud.lab.local
  sudo -u www-data php occ config:system:set trusted_domains 1 --value=10.0.50.12
  
  # Configure Redis
  sudo -u www-data php occ config:system:set redis host --value=10.0.50.11
  sudo -u www-data php occ config:system:set redis port --value=6379
  sudo -u www-data php occ config:system:set memcache.local --value='\\OC\\Memcache\\APCu'
  sudo -u www-data php occ config:system:set memcache.distributed --value='\\OC\\Memcache\\Redis'
  ```
- [ ] Test Nextcloud: http://10.0.50.12 or http://cloud.lab.local

**Day 7: Mattermost Installation (on lab-app1)**
- [ ] Create database
  ```bash
  # SSH to lab-id1
  sudo -u postgres psql
  CREATE DATABASE mattermost;
  CREATE USER mattermost WITH ENCRYPTED PASSWORD 'MattermostLab2024!';
  GRANT ALL PRIVILEGES ON DATABASE mattermost TO mattermost;
  \q
  ```
- [ ] Download and install Mattermost
  ```bash
  # On lab-app1
  cd /tmp
  wget https://releases.mattermost.com/9.3.0/mattermost-9.3.0-linux-amd64.tar.gz
  tar -xzf mattermost-9.3.0-linux-amd64.tar.gz
  sudo mv mattermost /opt/
  sudo mkdir /opt/mattermost/data
  sudo useradd --system --user-group mattermost
  sudo chown -R mattermost:mattermost /opt/mattermost
  ```
- [ ] Configure Mattermost
  ```bash
  sudo nano /opt/mattermost/config/config.json
  ```
  Key changes:
  ```json
  {
    "ServiceSettings": {
      "SiteURL": "http://chat.lab.local",
      "ListenAddress": ":8065"
    },
    "SqlSettings": {
      "DriverName": "postgres",
      "DataSource": "postgres://mattermost:MattermostLab2024!@10.0.50.11:5432/mattermost?sslmode=disable"
    }
  }
  ```
- [ ] Create systemd service
  ```bash
  sudo nano /etc/systemd/system/mattermost.service
  ```
  Content:
  ```ini
  [Unit]
  Description=Mattermost
  After=network.target
  
  [Service]
  Type=notify
  ExecStart=/opt/mattermost/bin/mattermost
  TimeoutStartSec=3600
  Restart=always
  User=mattermost
  Group=mattermost
  WorkingDirectory=/opt/mattermost
  
  [Install]
  WantedBy=multi-user.target
  ```
  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable mattermost
  sudo systemctl start mattermost
  ```
- [ ] Test: http://10.0.50.12:8065

**Day 8: Jitsi Meet Installation (on lab-app1)**
- [ ] Add Jitsi repository
  ```bash
  curl -sL https://download.jitsi.org/jitsi-key.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/jitsi-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
  sudo apt update
  ```
- [ ] Install Jitsi
  ```bash
  sudo apt install -y jitsi-meet
  # During install: hostname = meet.lab.local
  # SSL: self-signed (we'll use proxy later)
  ```
- [ ] Basic configuration
  ```bash
  sudo nano /etc/jitsi/meet/meet.lab.local-config.js
  # Verify domain settings match
  ```
- [ ] Test: http://meet.lab.local (from lab network)

**Day 9: Email Server (on lab-comm1)**
- [ ] Set hostname
  ```bash
  sudo hostnamectl set-hostname lab-comm1.lab.local
  ```
- [ ] Download iRedMail
  ```bash
  cd /tmp
  wget https://github.com/iredmail/iRedMail/archive/1.6.8.tar.gz
  tar -xzf 1.6.8.tar.gz
  cd iRedMail-1.6.8
  ```
- [ ] Run installer
  ```bash
  sudo bash iRedMail.sh
  ```
  Selections:
  - Storage: /var/vmail
  - Backend: PostgreSQL (on 10.0.50.11)
  - Domain: lab.local
  - Postmaster password: LabMail2024!
  - Optional: Roundcube, SOGo
- [ ] After install, test webmail: https://mail.lab.local/mail

### Phase 4: Integration & Reverse Proxy (Week 2, Days 10-12)

**Day 10: Traefik Reverse Proxy (on lab-comm1)**
- [ ] Install Docker
  ```bash
  sudo apt install -y docker.io docker-compose
  sudo systemctl enable docker
  ```
- [ ] Create Traefik directory
  ```bash
  sudo mkdir -p /opt/traefik/{config,certs,logs}
  cd /opt/traefik
  ```
- [ ] Create docker-compose.yml
  ```bash
  sudo nano docker-compose.yml
  ```
  Content:
  ```yaml
  version: '3.8'
  
  services:
    traefik:
      image: traefik:v2.11
      container_name: traefik
      restart: unless-stopped
      ports:
        - "80:80"
        - "443:443"
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock:ro
        - ./traefik.yml:/traefik.yml:ro
        - ./config:/config:ro
        - ./certs:/certs
        - ./logs:/logs
      networks:
        - proxy
  
  networks:
    proxy:
      external: true
  ```
- [ ] Create traefik.yml
  ```bash
  sudo nano traefik.yml
  ```
  Content:
  ```yaml
  api:
    dashboard: true
    insecure: true
  
  entryPoints:
    http:
      address: ":80"
    https:
      address: ":443"
  
  providers:
    file:
      directory: /config
      watch: true
  
  log:
    level: INFO
    filePath: /logs/traefik.log
  
  accessLog:
    filePath: /logs/access.log
  ```
- [ ] Create backend config
  ```bash
  sudo nano config/backends.yml
  ```
  Content:
  ```yaml
  http:
    routers:
      nextcloud:
        rule: "Host(`cloud.lab.local`)"
        entryPoints:
          - http
        service: nextcloud
      
      mattermost:
        rule: "Host(`chat.lab.local`)"
        entryPoints:
          - http
        service: mattermost
      
      jitsi:
        rule: "Host(`meet.lab.local`)"
        entryPoints:
          - http
        service: jitsi
      
      keycloak:
        rule: "Host(`sso.lab.local`)"
        entryPoints:
          - http
        service: keycloak
    
    services:
      nextcloud:
        loadBalancer:
          servers:
            - url: "http://10.0.50.12:80"
      
      mattermost:
        loadBalancer:
          servers:
            - url: "http://10.0.50.12:8065"
      
      jitsi:
        loadBalancer:
          servers:
            - url: "http://10.0.50.12:80"
      
      keycloak:
        loadBalancer:
          servers:
            - url: "http://10.0.50.11:8080"
  ```
- [ ] Start Traefik
  ```bash
  sudo docker network create proxy
  sudo docker-compose up -d
  sudo docker-compose logs -f
  ```
- [ ] Update /etc/hosts on your laptop/workstation
  ```
  10.0.50.13   cloud.lab.local
  10.0.50.13   chat.lab.local
  10.0.50.13   meet.lab.local
  10.0.50.13   sso.lab.local
  10.0.50.13   mail.lab.local
  ```
- [ ] Test all services through proxy:
  - http://cloud.lab.local → Nextcloud
  - http://chat.lab.local → Mattermost
  - http://meet.lab.local → Jitsi
  - http://sso.lab.local → Keycloak

**Day 11: Zammad Help Desk (on lab-comm1)**
- [ ] Create database
  ```bash
  # On lab-id1
  sudo -u postgres psql
  CREATE DATABASE zammad_production;
  CREATE USER zammad WITH ENCRYPTED PASSWORD 'ZammadLab2024!';
  GRANT ALL PRIVILEGES ON DATABASE zammad_production TO zammad;
  \q
  ```
- [ ] Install Elasticsearch
  ```bash
  # On lab-comm1
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
  sudo apt update
  sudo apt install -y elasticsearch
  
  # Configure
  sudo nano /etc/elasticsearch/elasticsearch.yml
  # Add: network.host: 127.0.0.1
  # Add: xpack.security.enabled: false
  
  sudo systemctl enable elasticsearch
  sudo systemctl start elasticsearch
  ```
- [ ] Install Zammad
  ```bash
  curl -fsSL https://dl.packager.io/srv/zammad/zammad/key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/pkgr-zammad.gpg> /dev/null
  echo "deb [signed-by=/etc/apt/trusted.gpg.d/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/ubuntu 24.04 main"| sudo tee /etc/apt/sources.list.d/zammad.list > /dev/null
  sudo apt update
  sudo apt install -y zammad
  
  # Configure
  sudo zammad config:set DATABASE_URL="postgresql://zammad:ZammadLab2024!@10.0.50.11:5432/zammad_production"
  sudo zammad run rails db:migrate
  sudo zammad run rake searchindex:rebuild
  
  sudo systemctl restart zammad
  ```
- [ ] Add to Traefik
  ```bash
  # On lab-comm1, edit /opt/traefik/config/backends.yml
  # Add under routers:
  ```
  ```yaml
      zammad:
        rule: "Host(`desk.lab.local`)"
        entryPoints:
          - http
        service: zammad
  
  # Add under services:
      zammad:
        loadBalancer:
          servers:
            - url: "http://127.0.0.1:3000"
  ```
  ```bash
  # Traefik auto-reloads
  ```
- [ ] Test: http://desk.lab.local

**Day 12: SSO Integration Testing**
- [ ] Configure Nextcloud OIDC/SAML with Keycloak
  ```bash
  # On lab-app1
  sudo -u www-data php occ app:install user_oidc
  sudo -u www-data php occ user_oidc:provider add Keycloak \
    --clientid=nextcloud \
    --clientsecret=<get-from-keycloak> \
    --discoveryuri=http://sso.lab.local/realms/lab/.well-known/openid-configuration
  ```
- [ ] Create Keycloak clients for each app
  - Nextcloud: Client ID = nextcloud
  - Mattermost: Client ID = mattermost
  - Zammad: Client ID = zammad
- [ ] Test login flow:
  1. Go to http://cloud.lab.local
  2. Click SSO login
  3. Redirect to Keycloak
  4. Login with FreeIPA user
  5. Redirect back to Nextcloud - logged in!

### Phase 5: Testing & Documentation (Week 3-4)

**Days 13-15: Create Test Users and Scenarios**
- [ ] Create test users in FreeIPA
  ```bash
  # On lab-id1
  kinit admin
  ipa user-add guard1 --first=Guard --last=One --email=guard1@lab.local --password
  ipa user-add guard2 --first=Guard --last=Two --email=guard2@lab.local --password
  ipa user-add manager1 --first=Manager --last=One --email=manager1@lab.local --password
  ipa user-add office1 --first=Office --last=Staff --email=office1@lab.local --password
  
  # Create groups
  ipa group-add guards --desc="Security Guards"
  ipa group-add managers --desc="Managers"
  ipa group-add office-staff --desc="Office Staff"
  
  # Add users to groups
  ipa group-add-member guards --users=guard1,guard2
  ipa group-add-member managers --users=manager1
  ipa group-add-member office-staff --users=office1
  ```
- [ ] Create mailboxes
  ```bash
  # On lab-comm1
  sudo bash /var/vmail/bin/create_mail_user_SQL.sh guard1@lab.local 'Password123!'
  sudo bash /var/vmail/bin/create_mail_user_SQL.sh guard2@lab.local 'Password123!'
  sudo bash /var/vmail/bin/create_mail_user_SQL.sh manager1@lab.local 'Password123!'
  sudo bash /var/vmail/bin/create_mail_user_SQL.sh office1@lab.local 'Password123!'
  ```

**Days 16-20: Functional Testing (See Testing Scenarios section below)**

---

### Phase 6: VoIP/PBX System (Week 4)

**Day 1-2: FreePBX Installation**
- [ ] Set up server lab-voip1 (10.0.50.15)
  ```bash
  # Option 1: FreePBX Distro ISO (recommended)
  # Download from https://www.freepbx.org/downloads/
  # Boot and install, select all features
  
  # Option 2: Manual Asterisk + FreePBX
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y asterisk asterisk-modules
  
  # Or Option 3: Docker
  docker run -d --name freepbx \
    --net=host \
    --cap-add=NET_ADMIN \
    -v /data/freepbx:/data \
    -e TIMEZONE=America/New_York \
    tiredofit/freepbx:latest
  ```
- [ ] Access FreePBX GUI: http://10.0.50.15
- [ ] Complete initial setup wizard
- [ ] Set admin password
- [ ] Configure system timezone

**Day 3: Extensions and Basic Setup**
- [ ] Create SIP extensions
  ```
  Extensions → Add Extension → Chan SIP
  Extension: 101
  Display Name: Guard One
  Secret: strong_password
  
  Repeat for:
  102 - Guard Two
  103 - Manager One
  201 - Sales Dept
  301 - Support Dept
  401 - IT Dept
  ```
- [ ] Configure voicemail for each extension
  ```
  Enable: Yes
  Email: extension@lab.local
  Email Attachment: Yes
  Delete After Email: No
  ```
- [ ] Create ring groups
  ```
  Extensions → Ring Groups
  Group 600: Sales Team (rings 201, 202, 203)
  Group 601: Support Team (rings 301, 302, 303)
  Group 602: IT Team (rings 401, 402)
  
  Ring Strategy: ringall
  ```

**Day 4: IVR and Advanced Features**
- [ ] Create IVR (Auto Attendant)
  ```
  Applications → IVR
  Name: Main Menu
  Announcement: "Thank you for calling. Press 1 for Sales, 2 for Support, 3 for IT, 9 for directory"
  
  IVR Entries:
  1 → Ring Group 600 (Sales)
  2 → Ring Group 601 (Support)
  3 → Ring Group 602 (IT)
  9 → Directory
  ```
- [ ] Set up inbound route to IVR
  ```
  Connectivity → Inbound Routes
  DID: [leave blank for any]
  Destination: IVR → Main Menu
  ```
- [ ] Enable call recording
  ```
  Admin → System Recordings
  Upload announcements or use TTS
  
  For specific extensions:
  Extensions → [select extension] → Record Options
  ```
- [ ] Create conference bridge
  ```
  Applications → Conferences
  Conference Number: 9000
  PIN: [optional]
  Max users: 10
  ```

**Day 5: SIP Trunk and Integration**
- [ ] Configure SIP trunk (if using external calling)
  ```
  Connectivity → Trunks → Add Trunk → Chan SIP
  
  Example for Twilio:
  Trunk Name: Twilio
  Outbound CallerID: +1XXXXXXXXXX
  
  Peer Details:
  host=yourdomain.pstn.twilio.com
  username=your_username
  secret=your_auth_token
  type=peer
  insecure=port,invite
  context=from-trunk
  
  Outbound Routes:
  Route Pattern: NXXNXXXXXX (10-digit)
  Trunk: Twilio
  ```
- [ ] Integrate with FreeIPA for user authentication
  ```bash
  # In FreePBX User Management
  Settings → User Management → Directories
  Add LDAP Directory:
  Host: 10.0.50.11
  Base DN: cn=users,cn=accounts,dc=lab,dc=local
  User DN: uid=admin,cn=users,cn=accounts,dc=lab,dc=local
  Password: [FreeIPA admin password]
  ```
- [ ] Configure firewall rules
  ```bash
  sudo ufw allow 5060/udp  # SIP signaling
  sudo ufw allow 5061/tcp  # SIP TLS
  sudo ufw allow 10000:20000/udp  # RTP media
  sudo ufw allow 80/tcp    # HTTP
  sudo ufw allow 443/tcp   # HTTPS
  ```

**Day 6-7: Softphone Setup and Testing**
- [ ] Install softphone on desktop
  ```
  Options:
  - Zoiper (Windows/Mac/Linux/Mobile)
  - Linphone (Open source)
  - MicroSIP (Windows)
  - Bria (Commercial)
  
  Configuration:
  SIP Server: 10.0.50.15 or voip.lab.local
  Username: 101
  Password: [extension secret]
  ```
- [ ] Test internal calling
  ```
  ✓ Call from ext 101 to 102
  ✓ Test voicemail
  ✓ Call conference bridge (9000)
  ✓ Test IVR menu
  ✓ Check call recording
  ```
- [ ] Mobile softphone configuration
  - Install Zoiper or Linphone on mobile
  - Configure same as desktop
  - Test over WiFi and mobile data
  - Verify call quality

---

### Phase 7: Business Systems - CRM & ERP (Week 5)

**Day 1-2: SuiteCRM Installation**
- [ ] Prepare server lab-app2 (10.0.50.16)
- [ ] Create database
  ```bash
  sudo -u postgres psql
  CREATE DATABASE suitecrm;
  CREATE USER suitecrm WITH ENCRYPTED PASSWORD 'CrmPass2024!';
  GRANT ALL PRIVILEGES ON DATABASE suitecrm TO suitecrm;
  GRANT ALL ON SCHEMA public TO suitecrm;
  \q
  ```
- [ ] Install prerequisites
  ```bash
  sudo apt install -y nginx php8.1-fpm php8.1-mysql php8.1-pgsql \
    php8.1-curl php8.1-xml php8.1-mbstring php8.1-zip \
    php8.1-gd php8.1-imap php8.1-ldap
  ```
- [ ] Download and install SuiteCRM
  ```bash
  cd /var/www
  sudo wget https://github.com/salesagility/SuiteCRM/releases/download/v8.6.1/SuiteCRM-8.6.1.zip
  sudo unzip SuiteCRM-8.6.1.zip
  sudo mv SuiteCRM-8.6.1 suitecrm
  sudo chown -R www-data:www-data suitecrm
  sudo chmod -R 755 suitecrm
  ```
- [ ] Configure nginx
  ```nginx
  server {
      listen 80;
      server_name crm.lab.local;
      root /var/www/suitecrm/public;
      index index.php;

      location / {
          try_files $uri $uri/ /index.php?$query_string;
      }

      location ~ \.php$ {
          fastcgi_pass unix:/run/php/php8.1-fpm.sock;
          fastcgi_index index.php;
          include fastcgi_params;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      }
  }
  ```
- [ ] Complete web installation
  - Navigate to http://crm.lab.local
  - Accept license
  - Database: PostgreSQL, host: 10.0.50.11
  - Admin user: admin / CrmAdmin2024!
  - Create demo data option: YES for testing

**Day 3: SuiteCRM Configuration**
- [ ] Configure LDAP/FreeIPA authentication
  ```
  Admin → Password Management → LDAP Settings
  Server: 10.0.50.11
  Port: 389
  Base DN: cn=users,cn=accounts,dc=lab,dc=local
  Bind DN: uid=admin,cn=users,cn=accounts,dc=lab,dc=local
  Auto Create Users: Yes
  ```
- [ ] Configure email (iRedMail integration)
  ```
  Admin → Email Settings
  Outbound:
  SMTP Server: 10.0.50.13
  Port: 587
  Username: crm@lab.local
  Security: TLS
  
  Inbound:
  Server: 10.0.50.13
  Protocol: IMAP
  Port: 993
  ```
- [ ] Install VoIP integration module
  ```
  Download Asterisk connector for SuiteCRM
  Upload via Module Loader
  Configure: Asterisk host: 10.0.50.15
  AMI User/Password (create in FreePBX)
  Test click-to-call functionality
  ```
- [ ] Customize for your business
  - Set up sales stages
  - Configure product catalog
  - Create custom fields
  - Set up workflows

**Day 4-6: Odoo ERP Installation**
- [ ] Prepare server lab-erp1 (10.0.50.17)
- [ ] Install Odoo
  ```bash
  # Add Odoo repository
  sudo wget -O - https://nightly.odoo.com/odoo.key | sudo gpg --dearmor -o /usr/share/keyrings/odoo.gpg
  echo 'deb [signed-by=/usr/share/keyrings/odoo.gpg] https://nightly.odoo.com/17.0/nightly/deb/ ./' | sudo tee /etc/apt/sources.list.d/odoo.list
  
  sudo apt update
  sudo apt install -y odoo
  
  # Or use Docker:
  docker run -d --name odoo17 \
    -p 8069:8069 \
    -e HOST=10.0.50.11 \
    -e USER=odoo \
    -e PASSWORD=OdooDb2024! \
    -v /data/odoo:/var/lib/odoo \
    odoo:17.0
  ```
- [ ] Create database
  ```bash
  sudo -u postgres psql
  CREATE DATABASE odoo;
  CREATE USER odoo WITH ENCRYPTED PASSWORD 'OdooDb2024!';
  GRANT ALL PRIVILEGES ON DATABASE odoo TO odoo;
  \q
  ```
- [ ] Configure Odoo
  ```bash
  sudo nano /etc/odoo/odoo.conf
  ```
  ```ini
  [options]
  admin_passwd = OdooMaster2024!
  db_host = 10.0.50.11
  db_port = 5432
  db_user = odoo
  db_password = OdooDb2024!
  xmlrpc_port = 8069
  proxy_mode = True
  list_db = False
  ```
- [ ] Start Odoo and create database
  ```bash
  sudo systemctl restart odoo
  # Navigate to http://erp.lab.local or http://10.0.50.17:8069
  # Create database: production_lab
  # Master password: OdooMaster2024!
  # Admin email: admin@lab.local
  # Choose: Start with Apps
  ```

**Day 7: Odoo Module Installation**
- [ ] Install core modules
  ```
  Navigate to Apps (remove Apps filter)
  
  Install:
  ✓ Sales Management
  ✓ Invoicing / Accounting
  ✓ Purchase Management
  ✓ Inventory
  ✓ CRM
  ✓ Project
  ✓ Employees
  ✓ Time Off
  ✓ Timesheets
  ✓ Expenses
  ✓ Contacts
  ✓ Calendar
  
  Optional (if needed):
  - Manufacturing
  - Point of Sale
  - eCommerce
  - Email Marketing
  - Help Desk
  ```
- [ ] Configure company information
  ```
  Settings → General Settings → Companies
  Name: Your Company Name
  Address, Phone, Email, Website
  Currency: USD (or your currency)
  Fiscal Year: January-December
  ```
- [ ] Import chart of accounts
  - Accounting → Configuration → Chart of Accounts
  - Select country fiscal package
  - Install

---

### Phase 8: IT Management & Extended Systems (Week 6)

**Day 1-2: Document Management (OpenKM)**
- [ ] Deploy OpenKM on lab-app2
  ```bash
  # Create database
  sudo -u postgres psql
  CREATE DATABASE openkm;
  CREATE USER openkm WITH ENCRYPTED PASSWORD 'DmsPass2024!';
  GRANT ALL PRIVILEGES ON DATABASE openkm TO openkm;
  \q
  
  # Docker deployment
  docker run -d --name openkm \
    -p 8090:8080 \
    -v /data/openkm:/opt/openkm/repository \
    -e DB_HOST=10.0.50.11 \
    -e DB_NAME=openkm \
    -e DB_USER=openkm \
    -e DB_PASS=DmsPass2024! \
    openkm/openkm-ce:latest
  ```
- [ ] Configure LDAP authentication
- [ ] Set up folder structure
- [ ] Configure OCR for scanned documents
- [ ] Test document workflow

**Day 3: Project Management (Taiga)**
- [ ] Deploy on lab-app3 (10.0.50.18)
  ```bash
  git clone https://github.com/kaleidos-ventures/taiga-docker.git /opt/taiga
  cd /opt/taiga
  
  # Edit docker-compose.yml
  nano docker-compose.yml
  # Update:
  # - POSTGRES_HOST=10.0.50.11
  # - TAIGA_SECRET_KEY=[generate random]
  # - TAIGA_SITES_DOMAIN=projects.lab.local
  
  docker-compose up -d
  ```
- [ ] Create admin account
- [ ] Configure SAML SSO with Keycloak
- [ ] Create test project
- [ ] Invite team members

**Day 4: Asset Management (Snipe-IT)**
- [ ] Deploy Snipe-IT
  ```bash
  docker run -d --name snipeit \
    -p 8085:80 \
    -e MYSQL_PORT_3306_TCP_ADDR=10.0.50.11 \
    -e MYSQL_DATABASE=snipeit \
    -e MYSQL_USER=snipeit \
    -e MYSQL_PASSWORD=SnipePass2024! \
    -e APP_URL=http://assets.lab.local \
    -v /data/snipeit:/var/lib/snipeit \
    snipe/snipe-it:latest
  ```
- [ ] Initial configuration
  - Admin account setup
  - Company information
  - Currency, date format
- [ ] Create asset categories
- [ ] Add manufacturers and models
- [ ] Import test assets

**Day 5: IT Service Management (GLPI)**
- [ ] Deploy GLPI
  ```bash
  docker run -d --name glpi \
    -p 8084:80 \
    -e TIMEZONE=America/New_York \
    -v /data/glpi:/var/www/html/glpi \
    diouxx/glpi:latest
  ```
- [ ] Complete setup wizard
  - Database: Create automatically or use existing PostgreSQL
  - Admin: glpi / glpi (change after first login!)
- [ ] Install GLPI agent on test workstation
  ```bash
  # On Windows:
  Download from: https://github.com/glpi-project/glpi-agent/releases
  Install with server: http://10.0.50.18:8084/plugins/fusioninventory/
  
  # On Linux:
  sudo apt install glpi-agent
  sudo nano /etc/glpi-agent/agent.cfg
  # server = http://10.0.50.18:8084/plugins/fusioninventory/
  sudo systemctl restart glpi-agent
  ```
- [ ] Configure LDAP
- [ ] Set up ticket categories
- [ ] Define SLAs

**Day 6-7: Final Integration & Testing**
- [ ] Update reverse proxy (Traefik) routes
  ```yaml
  # Add to traefik dynamic config
  - "traefik.http.routers.crm.rule=Host(`crm.lab.local`)"
  - "traefik.http.routers.erp.rule=Host(`erp.lab.local`)"
  - "traefik.http.routers.voip.rule=Host(`voip.lab.local`)"
  - "traefik.http.routers.docs.rule=Host(`docs.lab.local`)"
  - "traefik.http.routers.projects.rule=Host(`projects.lab.local`)"
  - "traefik.http.routers.assets.rule=Host(`assets.lab.local`)"
  - "traefik.http.routers.itsm.rule=Host(`itsm.lab.local`)"
  ```
- [ ] Test SSO across all new systems
- [ ] Configure cross-system integrations:
  - FreePBX → SuiteCRM (call logging)
  - Odoo → FreeIPA (employee sync)
  - Taiga → Mattermost (notifications)
  - OpenKM → Odoo/CRM (document linking)
  - Snipe-IT → GLPI (asset sync)
- [ ] Run end-to-end workflow tests (Test 18.1-18.5)
- [ ] Document any issues or changes
- [ ] Update architecture diagram with actual IPs/configs

---

## Installation Quick Start

### Rapid Deployment Script (All-in-One)

For quickest testing, here's a script to automate most of the installation:

```bash
#!/bin/bash
# lab-deploy.sh - Automated lab deployment
# Run this on EACH server with appropriate SERVER_ROLE

set -e

# Configuration
SERVER_ROLE=$1  # id, app, or comm
BASE_IP="10.0.50"
LAB_DOMAIN="lab.local"
DB_PASSWORD="LabDB2024!"

if [ -z "$SERVER_ROLE" ]; then
    echo "Usage: $0 [id|app|comm]"
    exit 1
fi

# Common setup
echo "=== Common Setup ==="
sudo apt update
sudo apt upgrade -y
sudo apt install -y vim curl wget git htop net-tools

# Role-specific installation
case $SERVER_ROLE in
    id)
        echo "=== Installing Identity Server ==="
        sudo hostnamectl set-hostname lab-id1.lab.local
        
        # FreeIPA
        sudo apt install -y freeipa-server freeipa-server-dns
        sudo ipa-server-install \
            --domain=$LAB_DOMAIN \
            --realm=$(echo $LAB_DOMAIN | tr '[:lower:]' '[:upper:]') \
            --ds-password="$DB_PASSWORD" \
            --admin-password="$DB_PASSWORD" \
            --hostname=lab-id1.$LAB_DOMAIN \
            --ip-address=${BASE_IP}.11 \
            --setup-dns \
            --forwarder=8.8.8.8 \
            --no-ntp \
            --unattended
        
        # PostgreSQL
        sudo apt install -y postgresql-16 postgresql-contrib
        sudo systemctl enable postgresql
        # ... (configure for network access)
        
        # Redis
        sudo apt install -y redis-server
        
        echo "Identity server setup complete!"
        ;;
        
    app)
        echo "=== Installing Application Server ==="
        sudo hostnamectl set-hostname lab-app1.lab.local
        
        # Point DNS to FreeIPA
        echo "nameserver ${BASE_IP}.11" | sudo tee /etc/resolv.conf
        
        # Nextcloud dependencies
        sudo apt install -y nginx php8.3-fpm php8.3-pgsql \
            php8.3-gd php8.3-curl php8.3-zip php8.3-xml \
            php8.3-mbstring php8.3-intl
        
        # Download Nextcloud
        cd /tmp
        wget https://download.nextcloud.com/server/releases/nextcloud-28.0.0.tar.bz2
        sudo tar -xjf nextcloud-28.0.0.tar.bz2 -C /var/www/
        sudo chown -R www-data:www-data /var/www/nextcloud
        
        # Mattermost
        wget https://releases.mattermost.com/9.3.0/mattermost-9.3.0-linux-amd64.tar.gz
        tar -xzf mattermost-9.3.0-linux-amd64.tar.gz
        sudo mv mattermost /opt/
        
        # Jitsi
        curl -sL https://download.jitsi.org/jitsi-key.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/jitsi-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
        sudo apt update
        sudo apt install -y jitsi-meet
        
        echo "Application server setup complete!"
        echo "Manual configuration required for each service."
        ;;
        
    comm)
        echo "=== Installing Communications Server ==="
        sudo hostnamectl set-hostname lab-comm1.lab.local
        
        # Docker for Traefik
        sudo apt install -y docker.io docker-compose
        sudo systemctl enable docker
        
        # iRedMail
        cd /tmp
        wget https://github.com/iredmail/iRedMail/archive/1.6.8.tar.gz
        tar -xzf 1.6.8.tar.gz
        
        echo "Communications server prerequisites installed!"
        echo "Run iRedMail installer manually: cd /tmp/iRedMail-1.6.8 && sudo bash iRedMail.sh"
        ;;
        
    *)
        echo "Invalid role. Use: id, app, or comm"
        exit 1
        ;;
esac

echo "=== Setup complete for $SERVER_ROLE ==="
```

Usage:
```bash
# On lab-id1:
bash lab-deploy.sh id

# On lab-app1:
bash lab-deploy.sh app

# On lab-comm1:
bash lab-deploy.sh comm
```

---

## Testing Scenarios

### Test Plan Checklist

#### 1. Authentication & SSO
- [ ] **Test 1.1:** Login to Keycloak with FreeIPA user
  - Navigate to http://sso.lab.local
  - Login with: guard1 / Password123!
  - Verify successful login
- [ ] **Test 1.2:** SSO to Nextcloud
  - Navigate to http://cloud.lab.local
  - Click "Login with Keycloak" (or similar SSO option)
  - Should auto-login without re-entering credentials
- [ ] **Test 1.3:** SSO to Mattermost
  - Navigate to http://chat.lab.local
  - Choose SSO/OAuth login
  - Verify automatic login
- [ ] **Test 1.4:** Password change propagation
  - Change password in FreeIPA: `ipa passwd guard1`
  - Logout from all services
  - Login with new password
  - Verify works across all services

#### 2. Email Services
- [ ] **Test 2.1:** Send email between users
  - Login to webmail: http://mail.lab.local/mail
  - Send from guard1@lab.local to guard2@lab.local
  - Verify receipt
- [ ] **Test 2.2:** Email client configuration
  - Configure Thunderbird/Outlook with:
    - IMAP: mail.lab.local:993 (SSL)
    - SMTP: mail.lab.local:587 (STARTTLS)
  - Send and receive test emails
- [ ] **Test 2.3:** Spam filtering
  - Send email with spam keywords
  - Verify SpamAssassin marks it
- [ ] **Test 2.4:** Email forwarding
  - Set up forwarding rule
  - Verify emails forward correctly

#### 3. File Sharing & Collaboration
- [ ] **Test 3.1:** Upload and share file
  - Login to Nextcloud as guard1
  - Upload test file (document, image)
  - Share with guard2
  - Verify guard2 can access
- [ ] **Test 3.2:** Collaborative editing
  - Create document in Nextcloud
  - Share with manager1
  - Both users edit simultaneously
  - Verify changes merge correctly
- [ ] **Test 3.3:** Calendar sharing
  - Create event in Nextcloud Calendar
  - Share calendar with team
  - Verify others can see event
- [ ] **Test 3.4:** File versioning
  - Edit file multiple times
  - Check version history
  - Restore old version

#### 4. Team Communication
- [ ] **Test 4.1:** Create Mattermost team/channel
  - Login as manager1
  - Create team: "Security Operations"
  - Create channels: #general, #site-a, #incidents
  - Invite users to team
- [ ] **Test 4.2:** Direct messaging
  - Send DM from guard1 to guard2
  - Verify receipt and reply
- [ ] **Test 4.3:** File sharing in chat
  - Upload file in Mattermost
  - Verify other users can download
- [ ] **Test 4.4:** Mobile notifications
  - Install Mattermost on phone
  - Send message to user
  - Verify push notification received

#### 5. Video Conferencing
- [ ] **Test 5.1:** Create and join meeting
  - Navigate to http://meet.lab.local
  - Create meeting room
  - Join from 2+ devices
  - Verify video/audio works
- [ ] **Test 5.2:** Screen sharing
  - Share screen in Jitsi
  - Verify other participants see it
- [ ] **Test 5.3:** Jitsi from Nextcloud
  - In Nextcloud Talk, start video call
  - Verify Jitsi integration works
- [ ] **Test 5.4:** Recording (if enabled)
  - Start recording in meeting
  - Verify file is saved

#### 6. Help Desk
- [ ] **Test 6.1:** Submit ticket via email
  - Send email to support@lab.local
  - Verify ticket created in Zammad
- [ ] **Test 6.2:** Submit ticket via web
  - Navigate to http://desk.lab.local
  - Create new ticket
  - Assign to agent
- [ ] **Test 6.3:** Ticket workflow
  - Agent replies to ticket
  - User receives email notification
  - User responds
  - Agent closes ticket
- [ ] **Test 6.4:** Knowledge base
  - Create KB article
  - Search for article
  - Verify users can access

#### 7. Backup & Recovery
- [ ] **Test 7.1:** Manual backup
  - Run backup script for Nextcloud
  - Verify backup completes
  - Check backup size and location
- [ ] **Test 7.2:** Restore test
  - Delete test file from Nextcloud
  - Restore from backup
  - Verify file is recovered
- [ ] **Test 7.3:** Database backup
  - Backup PostgreSQL
  - Drop test database
  - Restore from backup
  - Verify data integrity

#### 8. Mobile Access
- [ ] **Test 8.1:** Nextcloud mobile app
  - Install Nextcloud app on phone
  - Connect to http://cloud.lab.local
  - Upload photo from phone
  - Verify syncs to server
- [ ] **Test 8.2:** Email on mobile
  - Configure native mail app
  - Send/receive emails
- [ ] **Test 8.3:** Mattermost mobile
  - Install app, login
  - Send messages
  - Verify notifications work
- [ ] **Test 8.4:** Calendar sync to phone
  - Add CalDAV account
  - Verify events sync

#### 9. User Management
- [ ] **Test 9.1:** Create new user
  - Run provision script
  - Verify user created in:
    - FreeIPA
    - Email server
    - Auto-provisioned in Nextcloud/Mattermost
- [ ] **Test 9.2:** Disable user
  - Disable user in FreeIPA
  - Verify cannot login to any service
- [ ] **Test 9.3:** Group permissions
  - Create group in FreeIPA
  - Add user to group
  - Verify group-based access in apps

#### 10. Performance & Stress
- [ ] **Test 10.1:** Concurrent users
  - Have 5-10 people login simultaneously
  - Perform various actions
  - Monitor resource usage
- [ ] **Test 10.2:** Large file upload
  - Upload 1-2 GB file to Nextcloud
  - Verify successful upload
  - Check disk space
- [ ] **Test 10.3:** Video conference with 5+ participants
  - Join meeting with multiple people
  - Check quality and lag
- [ ] **Test 10.4:** Email load test
  - Send 50-100 emails rapidly
  - Verify all delivered

#### 11. VoIP/PBX System
- [ ] **Test 11.1:** Internal extension calling
  - Configure 2+ SIP phones or softphones
  - Assign extensions (e.g., 101, 102)
  - Call from ext 101 to ext 102
  - Verify call connects and audio is clear
- [ ] **Test 11.2:** Voicemail system
  - Call extension, let it go to voicemail
  - Leave voicemail message
  - Check voicemail via phone (*97) or web interface
  - Verify voicemail-to-email delivery
- [ ] **Test 11.3:** IVR/Auto-attendant
  - Call main number
  - Navigate IVR menu (Press 1 for Sales, 2 for Support, etc.)
  - Verify routes to correct department/queue
- [ ] **Test 11.4:** Call queues
  - Set up sales queue with 2+ agents
  - Call sales number
  - Verify queue announcement plays
  - Verify call distributes to available agent
- [ ] **Test 11.5:** Call recording
  - Enable call recording for specific extension
  - Make test call
  - Verify recording saved
  - Play back recording from web interface
- [ ] **Test 11.6:** Conference bridge
  - Create conference room (e.g., extension 9000)
  - Have 3+ people dial in
  - Verify multi-party conference works
- [ ] **Test 11.7:** SIP trunk (if configured)
  - Place outbound call to external number
  - Verify call connects via SIP trunk
  - Receive inbound call from external number
  - Verify DID routing works
- [ ] **Test 11.8:** Mobile softphone
  - Configure softphone app (Zoiper, Linphone, etc.)
  - Register extension over WiFi/mobile data
  - Make/receive calls
  - Verify works from outside office network
- [ ] **Test 11.9:** CRM integration (CTI)
  - Make call from SuiteCRM (click-to-call)
  - Verify call logged automatically in CRM
  - Check call history shows in contact record
- [ ] **Test 11.10:** Call analytics
  - Check FreePBX call reports
  - Verify CDR (Call Detail Records) accurate
  - Review queue statistics
  - Export call logs

#### 12. CRM System (SuiteCRM)
- [ ] **Test 12.1:** Create and manage contacts
  - Login to https://crm.lab.local
  - Create new contact with SSO user
  - Add phone, email, address
  - Create account (company) for contact
  - Verify contact saved correctly
- [ ] **Test 12.2:** Lead management
  - Create new lead
  - Assign lead to sales rep
  - Convert lead to contact/opportunity
  - Verify conversion creates related records
- [ ] **Test 12.3:** Sales pipeline
  - Create opportunity (deal)
  - Set value, stage, close date
  - Move through sales stages
  - Mark as won/lost
  - Verify in pipeline dashboard
- [ ] **Test 12.4:** Email integration
  - Send email to customer from CRM
  - Verify email sent via iRedMail
  - Reply from customer
  - Verify email logged in CRM
- [ ] **Test 12.5:** Calendar/meetings
  - Schedule meeting in CRM
  - Invite contacts
  - Sync to Nextcloud calendar
  - Verify meeting appears in both systems
- [ ] **Test 12.6:** Reports and dashboards
  - Create sales report
  - Filter by date, rep, status
  - Export to PDF/Excel
  - Verify data accuracy
- [ ] **Test 12.7:** Mobile CRM access
  - Install SuiteCRM mobile app
  - Login with SSO
  - View contacts, create task
  - Verify syncs to web version
- [ ] **Test 12.8:** Document management integration
  - Attach document from OpenKM to contact
  - Upload file to CRM
  - Verify accessible from both systems
- [ ] **Test 12.9:** Workflow automation
  - Create workflow: Auto-assign leads from specific source
  - Test trigger conditions
  - Verify automation executes
- [ ] **Test 12.10:** SSO integration
  - Login via Keycloak SSO
  - Verify user attributes sync from FreeIPA
  - Test logout propagation

#### 13. ERP System (Odoo)
- [ ] **Test 13.1:** Employee management
  - Navigate to HR module
  - Create new employee record
  - Set department, position, manager
  - Verify employee syncs to FreeIPA
  - Check email account created
  - Verify VoIP extension provisioned
- [ ] **Test 13.2:** Purchase order workflow
  - Create vendor in Contacts
  - Create purchase requisition
  - Convert to purchase order
  - Send PO to vendor (email)
  - Receive products
  - Create vendor bill
  - Process payment
- [ ] **Test 13.3:** Sales order to invoice
  - Create customer in Contacts
  - Create quotation
  - Confirm quotation to sales order
  - Deliver products/services
  - Create invoice from sales order
  - Email invoice to customer
  - Record payment
- [ ] **Test 13.4:** Inventory management
  - Create product with stock tracking
  - Perform stock adjustment (add inventory)
  - Create sales order
  - Verify stock decreases automatically
  - Check stock valuation report
- [ ] **Test 13.5:** Manufacturing (if using)
  - Create Bill of Materials (BoM)
  - Create manufacturing order
  - Assign work orders
  - Report production
  - Verify finished goods in stock
- [ ] **Test 13.6:** Accounting
  - Review chart of accounts
  - Create journal entry
  - Reconcile bank statement
  - Generate financial reports:
    - Balance sheet
    - Profit & Loss
    - General ledger
  - Verify double-entry bookkeeping correct
- [ ] **Test 13.7:** Time tracking & expenses
  - Employee creates timesheet
  - Log hours on project
  - Submit expense report
  - Manager approves time/expenses
  - Export to payroll
- [ ] **Test 13.8:** Project accounting
  - Create project in Odoo
  - Link to Taiga project (if integrated)
  - Log time to project tasks
  - Create customer invoice from timesheet
  - Verify project profitability report
- [ ] **Test 13.9:** Multi-currency
  - Set up second currency
  - Create invoice in foreign currency
  - Process payment
  - Verify exchange rate handling
  - Check gain/loss accounts
- [ ] **Test 13.10:** Reporting & KPIs
  - Access custom dashboards
  - Create pivot table analysis
  - Export data to Excel
  - Schedule automated reports

#### 14. Document Management (OpenKM)
- [ ] **Test 14.1:** Document upload and metadata
  - Login to https://docs.lab.local
  - Upload document
  - Add metadata tags (category, author, date)
  - Add keywords for search
- [ ] **Test 14.2:** Version control
  - Upload document v1.0
  - Check out for editing
  - Upload v2.0
  - View version history
  - Restore to v1.0
  - Download specific version
- [ ] **Test 14.3:** Workflow automation
  - Create approval workflow
  - Submit document for review
  - Reviewer approves/rejects
  - Verify notification emails sent
  - Check audit trail
- [ ] **Test 14.4:** Full-text search with OCR
  - Upload scanned PDF (image-based)
  - Wait for OCR processing
  - Search for text within document
  - Verify results accurate
- [ ] **Test 14.5:** Document retention
  - Set retention policy (e.g., 7 years)
  - Mark document as record
  - Attempt to delete before retention expires
  - Verify deletion blocked
- [ ] **Test 14.6:** Email archiving
  - Configure email connector
  - Archive emails from iRedMail
  - Search archived emails
  - Export email with attachments
- [ ] **Test 14.7:** Integration with Odoo/CRM
  - Link document to Odoo invoice
  - Attach DMS document to CRM contact
  - Verify bidirectional access
- [ ] **Test 14.8:** Digital signatures
  - Upload contract
  - Add digital signature
  - Verify signature validity
  - Check certificate info
- [ ] **Test 14.9:** Folder permissions
  - Create folder structure by department
  - Set access control (HR can access HR folder only)
  - Test with different users
  - Verify permissions enforced
- [ ] **Test 14.10:** Mobile access
  - Access OpenKM from mobile browser
  - Search and download document
  - Upload photo from camera

#### 15. Project Management (Taiga)
- [ ] **Test 15.1:** Create project
  - Login to https://projects.lab.local
  - Create new project
  - Set up team members
  - Define roles (Product Owner, Scrum Master, Developer)
- [ ] **Test 15.2:** Backlog management
  - Create user stories
  - Add acceptance criteria
  - Estimate story points
  - Prioritize backlog
- [ ] **Test 15.3:** Sprint planning
  - Create sprint
  - Move stories from backlog to sprint
  - Assign tasks to team members
  - Set sprint duration
  - Start sprint
- [ ] **Test 15.4:** Kanban board
  - View tasks in Kanban view
  - Move task through workflow (To Do → In Progress → Done)
  - Add tasks directly from board
  - Filter by assignee, tag, etc.
- [ ] **Test 15.5:** Issue tracking
  - Create bug issue
  - Set severity, priority
  - Assign to developer
  - Track status changes
  - Close with resolution
- [ ] **Test 15.6:** Time tracking
  - Log time on task
  - View time reports by user
  - Export timesheet
  - Integrate with Odoo for billing
- [ ] **Test 15.7:** Wiki documentation
  - Create project wiki page
  - Add documentation, links
  - Attach files
  - Cross-link pages
- [ ] **Test 15.8:** Integration tests
  - Link commit to task (if using Git integration)
  - Mattermost notification on task update
  - Sync milestone to Nextcloud calendar
- [ ] **Test 15.9:** Burndown charts
  - View sprint burndown
  - Check velocity metrics
  - Verify calculations accurate
- [ ] **Test 15.10:** External stakeholder access
  - Invite client as external user
  - Grant read-only access
  - Verify limited permissions

#### 16. Asset Management (Snipe-IT)
- [ ] **Test 16.1:** Asset creation
  - Login to https://assets.lab.local
  - Create asset category (Laptops, Servers, etc.)
  - Add manufacturer (Dell, HP, etc.)
  - Create asset model
  - Add individual asset with serial number
- [ ] **Test 16.2:** Check-out/Check-in
  - Assign laptop to employee
  - Generate check-out email
  - Employee confirms receipt
  - Check asset back in when returned
  - View asset history
- [ ] **Test 16.3:** License management
  - Create software license (Microsoft Office, Adobe, etc.)
  - Set seat count
  - Assign seats to users
  - Track available vs used seats
  - Set expiration alerts
- [ ] **Test 16.4:** Maintenance tracking
  - Schedule maintenance for asset
  - Set maintenance frequency
  - Receive notification when due
  - Log maintenance completion
- [ ] **Test 16.5:** Asset depreciation
  - Set depreciation method
  - Configure useful life
  - Calculate current value
  - Generate depreciation report
- [ ] **Test 16.6:** Barcode/QR code
  - Generate QR code for asset
  - Print label
  - Scan with mobile app
  - Verify asset details load
- [ ] **Test 16.7:** Integration with HR
  - Sync employees from Odoo
  - Auto-create asset assignments for new hires
  - Generate IT equipment request from HR onboarding
- [ ] **Test 16.8:** Audit reports
  - Generate asset inventory report
  - Export to Excel
  - Filter by location, category, status
  - Verify accuracy
- [ ] **Test 16.9:** Procurement tracking
  - Create purchase order in Odoo
  - Link to asset record in Snipe-IT
  - Track from order to deployment
- [ ] **Test 16.10:** Custom fields
  - Add custom field (warranty expiration, MAC address, etc.)
  - Populate for assets
  - Filter/report on custom fields

#### 17. IT Service Management (GLPI)
- [ ] **Test 17.1:** Ticket creation
  - Login to https://itsm.lab.local
  - Create incident ticket
  - Set category, urgency, impact
  - Assign to technician
- [ ] **Test 17.2:** Asset auto-discovery
  - Install GLPI agent on workstation
  - Run inventory scan
  - Verify hardware/software detected
  - Check inventory updates automatically
- [ ] **Test 17.3:** Change management
  - Create change request
  - Define implementation plan
  - Submit for approval
  - Track change through workflow
  - Close with post-implementation review
- [ ] **Test 17.4:** Problem management
  - Create problem record
  - Link related incidents
  - Document root cause
  - Create solution/knowledge base article
- [ ] **Test 17.5:** Service catalog
  - Create service catalog items
  - User requests service (new software, access, etc.)
  - Request routed to appropriate team
  - Track fulfillment
- [ ] **Test 17.6:** SLA management
  - Define SLA (e.g., P1: 1hr response, 4hr resolution)
  - Create ticket
  - Monitor SLA countdown
  - Verify escalation if SLA breached
- [ ] **Test 17.7:** Knowledge base
  - Create KB article from solved problem
  - Categorize article
  - Search knowledge base
  - Link KB to ticket
- [ ] **Test 17.8:** Integration with Zammad
  - Create ticket in Zammad
  - Check if syncs to GLPI (if configured)
  - Update in one system
  - Verify reflects in other
- [ ] **Test 17.9:** Software license tracking
  - Import licenses
  - Link to deployed software (from inventory)
  - Track compliance
  - Alert on over-deployment
- [ ] **Test 17.10:** Reporting and dashboards
  - View ticket statistics
  - Check mean time to resolve (MTTR)
  - Asset inventory reports
  - License compliance status

#### 18. End-to-End Business Workflows
- [ ] **Test 18.1:** Complete customer lifecycle
  - Lead enters CRM from website form
  - Sales team calls (logged via FreePBX integration)
  - Quote sent from Odoo
  - Customer accepts → Sales order created
  - Service delivered → Invoice generated
  - Payment recorded
  - Support ticket created in Zammad
  - IT fulfills via GLPI
  - All interactions logged
- [ ] **Test 18.2:** Employee lifecycle
  - HR creates employee in Odoo
  - FreeIPA account auto-created
  - Email account provisioned
  - VoIP extension assigned
  - Asset check-out (laptop, phone) in Snipe-IT
  - Access to all systems via SSO
  - Employee creates project in Taiga
  - Employee terminates → deprovisioning workflow
  - Assets checked back in
- [ ] **Test 18.3:** Project delivery workflow
  - Client signs contract (document in OpenKM)
  - Project created in Taiga
  - Team assigned
  - Time tracked in Taiga
  - Regular meetings via Jitsi
  - Communication in Mattermost
  - Documents stored in Nextcloud/OpenKM
  - Time exported to Odoo
  - Invoice generated based on time/milestones
  - Payment received
  - Project closed
- [ ] **Test 18.4:** IT support workflow
  - User calls help desk (FreePBX routes to support queue)
  - Ticket auto-created in Zammad from call
  - Ticket also created in GLPI
  - Technician assigned
  - Checks asset info in Snipe-IT
  - References KB article in GLPI
  - Updates ticket → user gets email
  - Issue resolved → ticket closed
  - Satisfaction survey sent
- [ ] **Test 18.5:** Procurement workflow
  - Employee requests new software via GLPI service catalog
  - Manager approves in GLPI
  - IT checks license availability in Snipe-IT
  - Purchase requisition in Odoo
  - PO sent to vendor
  - License received → added to Snipe-IT
  - Deployed to employee
  - Asset/license linked in both systems

### Performance Metrics to Record

During testing, document:
- **Login time:** How long from entering credentials to dashboard
- **File upload speed:** MB/s for large files
- **Video quality:** Resolution, lag, dropped frames
- **Resource usage:** CPU, RAM, disk on each server during various tasks
- **Response time:** Page load times for each service

---

## Migration to Production

### Lessons Learned Documentation

After lab testing, document:

1. **What Worked Well:**
   - Services that were easy to install
   - Integrations that worked smoothly
   - Features users liked

2. **What Needs Improvement:**
   - Installation steps that were confusing
   - Configuration that needs better documentation
   - Performance bottlenecks

3. **Production Changes Needed:**
   - Hardware upgrades required
   - Additional redundancy needed
   - Security hardening steps
   - Network changes

### Migration Checklist

Before deploying to production:

- [ ] All test scenarios passed successfully
- [ ] Documentation updated with actual steps taken
- [ ] Team trained on administration
- [ ] Production hardware procured
- [ ] Network changes approved and scheduled
- [ ] Backup procedures tested and verified
- [ ] Disaster recovery plan documented
- [ ] Security audit completed
- [ ] Compliance requirements verified
- [ ] User training materials prepared

### Configuration Export

Export configurations from lab for reuse in production:

```bash
# FreeIPA
ipa-replica-prepare lab-id1.lab.local

# Keycloak
cd /opt/keycloak
./bin/kc.sh export --dir /tmp/keycloak-export --realm lab

# Nextcloud
sudo -u www-data php occ config:list system > /tmp/nextcloud-config.json

# Mattermost
cd /opt/mattermost
sudo -u mattermost ./bin/mattermost export bulk /tmp/mattermost-export.json

# Database schemas
pg_dump -s nextcloud > /tmp/nextcloud-schema.sql
pg_dump -s mattermost > /tmp/mattermost-schema.sql
```

### Scaling for Production

**Changes from Lab to Production:**

| Component | Lab | Production |
|-----------|-----|------------|
| Servers | 3 physical | 15-20 VMs on Proxmox cluster |
| FreeIPA | 1 server | 2 servers (HA) |
| Keycloak | 1 node | 2 nodes (clustered) |
| PostgreSQL | Single instance | Patroni cluster (3 nodes) |
| Nextcloud | 1 instance | Load balanced (2+) |
| Reverse Proxy | 1 Traefik | HAProxy pair (HA) |
| Backup | Local only | Local + offsite replication |
| Monitoring | Basic | Full Zabbix + Graylog |

---

## Lab Environment Cleanup

### Shutdown Procedure

When testing is complete:

1. **Backup configurations:**
   ```bash
   # Create archive of all configs
   tar -czf lab-configs-$(date +%Y%m%d).tar.gz \
     /etc/keycloak \
     /opt/keycloak/conf \
     /etc/nginx \
     /var/www/nextcloud/config \
     /opt/mattermost/config \
     /opt/traefik
   ```

2. **Export test data:**
   ```bash
   # Nextcloud files
   tar -czf nextcloud-data.tar.gz /var/www/nextcloud/data
   
   # Databases
   pg_dump -Fc nextcloud > nextcloud.dump
   pg_dump -Fc mattermost > mattermost.dump
   ```

3. **Document final state:**
   - Take screenshots of all dashboards
   - Export user list
   - Save monitoring graphs
   - Document any issues encountered

4. **Graceful shutdown:**
   ```bash
   # Stop services in order
   sudo systemctl stop mattermost
   sudo systemctl stop nginx
   sudo docker-compose -f /opt/traefik/docker-compose.yml down
   sudo systemctl stop keycloak
   sudo systemctl stop postgresql
   sudo systemctl stop ipa
   
   # Shutdown servers
   sudo shutdown -h now
   ```

### Restore Lab Equipment

If lab computers need to be returned to original state:

1. **Boot from USB** with original OS
2. **Reformat drives** to remove all data
3. **Reinstall original OS** (if needed)
4. **Document hours used** for lab access logs

### Keep Lab Environment Running

If you can keep the lab running:

1. **Access remotely** via SSH or VPN
2. **Continue testing** additional features
3. **Use for training** new IT staff
4. **Demonstrate to stakeholders** before production approval

---

## Appendix: Quick Reference

### Lab Server Credentials

**Default Passwords (Change These!):**
- FreeIPA admin: LabAdmin2024!
- PostgreSQL postgres: LabDB2024!
- Keycloak admin: LabAdmin2024!
- Nextcloud admin: LabAdmin2024!
- Mail postmaster: LabMail2024!

**Test User Accounts:**
- guard1@lab.local / Password123!
- guard2@lab.local / Password123!
- manager1@lab.local / Password123!
- office1@lab.local / Password123!

### Lab Service URLs

| Service | URL | IP | Port |
|---------|-----|-----|------|
| FreeIPA | https://ipa.lab.local | 10.0.50.11 | 443 |
| Keycloak | http://sso.lab.local | 10.0.50.11 | 8080 |
| Nextcloud | http://cloud.lab.local | 10.0.50.12 | 80 |
| Mattermost | http://chat.lab.local | 10.0.50.12 | 8065 |
| Jitsi | http://meet.lab.local | 10.0.50.12 | 80 |
| Webmail | https://mail.lab.local/mail | 10.0.50.13 | 443 |
| Zammad | http://desk.lab.local | 10.0.50.13 | 3000 |
| Traefik Dashboard | http://10.0.50.13:8080 | 10.0.50.13 | 8080 |

### Common Commands

**Check service status:**
```bash
# All servers
sudo systemctl status postgresql
sudo systemctl status keycloak
sudo systemctl status nginx
sudo systemctl status mattermost
sudo systemctl status ipa

# View logs
sudo journalctl -u <service> -f
```

**Database access:**
```bash
# From lab-id1
sudo -u postgres psql
\l  # List databases
\c <database>  # Connect to database
```

**Test connectivity:**
```bash
# From any server
ping 10.0.50.11  # Test network
curl http://10.0.50.12  # Test web service
telnet 10.0.50.11 5432  # Test PostgreSQL port
```

### Troubleshooting Lab Issues

**Problem: Cannot access services from laptop**
- Check /etc/hosts on laptop
- Verify servers are running: `ping 10.0.50.11`
- Check Traefik logs: `sudo docker logs traefik`

**Problem: FreeIPA not resolving DNS**
- Check if DNS service running: `sudo systemctl status named-pkcs11`
- Verify DNS records: `ipa dnsrecord-find lab.local`
- Set laptop DNS to 10.0.50.11

**Problem: Database connection errors**
- Check PostgreSQL is accepting connections: `sudo netstat -tlnp | grep 5432`
- Verify pg_hba.conf allows connections from app servers
- Check credentials in app config files

**Problem: Out of disk space**
- Check usage: `df -h`
- Clean up: `sudo apt autoremove && sudo apt clean`
- Remove old logs: `sudo journalctl --vacuum-time=3d`

---

## Estimated Timeline

### Conservative Estimate (First-Time Setup)
- **Week 1:** Foundation (OS install, FreeIPA, Keycloak, PostgreSQL)
- **Week 2:** Applications (Nextcloud, Mattermost, Jitsi, Mail)
- **Week 3:** Integration (Traefik, Zammad, SSO configuration)
- **Week 4:** Testing and documentation

**Total: 4 weeks part-time (2-3 hours/day)**

### Accelerated Timeline (With Experience)
- **Days 1-2:** Foundation layer
- **Days 3-5:** Core applications
- **Days 6-7:** Integration and testing

**Total: 1 week full-time**

---

## Success Metrics

Your lab deployment is successful when you can demonstrate:

1. ✅ **Single Sign-On:** Login once, access all services
2. ✅ **Email:** Send and receive emails between users
3. ✅ **Collaboration:** Share files, co-edit documents
4. ✅ **Communication:** Chat and video call between users
5. ✅ **Support:** Submit and manage help desk tickets
6. ✅ **Automation:** Provision new user across all systems
7. ✅ **Reliability:** Services stay up for 72+ hours
8. ✅ **Recovery:** Restore service from backup

---

**Good luck with your lab deployment! This hands-on experience will make your production deployment much smoother.**

For questions during lab setup, document them for the production team. Take lots of screenshots and notes!
