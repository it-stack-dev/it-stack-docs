# Enterprise Open-Source IT Stack Deployment Guide
## Professional Security Guard Services Company

**Document Version:** 1.0  
**Last Updated:** February 2026  
**Classification:** Internal Technical Documentation  
**Author:** Enterprise IT Infrastructure Team

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Infrastructure Requirements](#infrastructure-requirements)
4. [Component Stack](#component-stack)
5. [Network Architecture](#network-architecture)
6. [Server Deployment Specifications](#server-deployment-specifications)
7. [Installation Procedures](#installation-procedures)
8. [Integration Configuration](#integration-configuration)
9. [Security Hardening](#security-hardening)
10. [Backup and Disaster Recovery](#backup-and-disaster-recovery)
11. [Monitoring and Logging](#monitoring-and-logging)
12. [User Management and Access Control](#user-management-and-access-control)
13. [Mobile and Remote Access](#mobile-and-remote-access)
14. [Maintenance Procedures](#maintenance-procedures)
15. [Troubleshooting Guide](#troubleshooting-guide)
16. [Appendices](#appendices)

---

## Executive Summary

### Purpose
This document provides comprehensive technical specifications and deployment procedures for a complete enterprise-grade, open-source IT infrastructure stack designed for a professional security guard services company with distributed operations across back office and remote sites.

### Scope
The infrastructure encompasses:
- Email services with enterprise features
- Calendar and scheduling systems
- Real-time chat and messaging
- Video conferencing capabilities
- File storage and collaboration platform
- Shared workspaces and project management
- Internal and external help desk system
- Comprehensive backup and disaster recovery

### Key Design Principles
- **100% Open Source**: No proprietary vendor lock-in
- **Enterprise-Grade**: Production-ready, scalable, and reliable
- **Integrated Ecosystem**: Seamless interoperability between all components
- **Security-First**: Multi-layered security with zero-trust architecture
- **High Availability**: Minimal downtime with redundancy
- **Mobile-Ready**: Full functionality for field personnel
- **Compliance-Ready**: Audit trails and data sovereignty

---

## Architecture Overview

### Logical Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet/WAN                             │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                 Edge Firewall Layer (pfSense)                    │
│  • IDS/IPS (Suricata)  • VPN (WireGuard/OpenVPN)                │
│  • Traffic Shaping     • DDoS Protection                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│         Reverse Proxy & Load Balancer (HAProxy/Traefik)         │
│  • SSL/TLS Termination  • Load Distribution                     │
│  • Web Application Firewall  • Certificate Management           │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
┌───────▼──────┐  ┌─────▼─────┐  ┌──────▼──────┐
│ DMZ Services │  │  App Tier  │  │  Data Tier  │
└──────────────┘  └────────────┘  └─────────────┘
```

### Three-Tier Architecture

#### **Tier 1: DMZ Services (Public-Facing)**
- Reverse Proxy (Traefik/HAProxy)
- Web Application Firewall (ModSecurity)
- VPN Gateway (WireGuard)

#### **Tier 2: Application Services (Internal)**
- Nextcloud Hub (Collaboration Platform)
- Mattermost (Team Communication)
- Jitsi Meet (Video Conferencing)
- Zammad (Help Desk System)
- Mail Server (iRedMail)
- Keycloak (Identity & Access Management)

#### **Tier 3: Data & Directory Services (Backend)**
- FreeIPA/Samba AD (Directory Services)
- PostgreSQL Cluster (Primary Database)
- MariaDB Cluster (Secondary Database)
- Redis Cache Layer
- Backup Infrastructure (Borg/PBS)

---

## Infrastructure Requirements

### Sizing Model

#### Small Deployment (50-100 Users)
- **Total vCPU**: 48 cores
- **Total RAM**: 96 GB
- **Total Storage**: 5 TB (hot) + 10 TB (backup)
- **Network**: 1 Gbps symmetrical
- **Servers**: 4-6 physical hosts or VM cluster

#### Medium Deployment (100-500 Users)
- **Total vCPU**: 128 cores
- **Total RAM**: 256 GB
- **Total Storage**: 15 TB (hot) + 30 TB (backup)
- **Network**: 10 Gbps backbone
- **Servers**: 8-12 physical hosts or VM cluster

#### Large Deployment (500-2000 Users)
- **Total vCPU**: 256 cores
- **Total RAM**: 512 GB
- **Total Storage**: 50 TB (hot) + 100 TB (backup)
- **Network**: 10 Gbps+ backbone with redundancy
- **Servers**: 15-20 physical hosts or VM cluster

### Hardware Requirements

#### Enterprise Server Specifications (Per Physical Host)

**Compute Nodes (Application Servers)**
```
CPU: 2x Intel Xeon Gold 6338 (32 cores / 64 threads each) or AMD EPYC 7543
RAM: 256 GB DDR4-3200 ECC (expandable to 512 GB)
Storage: 
  - 2x 960GB NVMe SSD (RAID 1) - OS/System
  - 4x 3.84TB NVMe SSD (RAID 10) - Application Data
Network: 
  - 4x 10GbE ports (bonded/redundant)
  - 2x 1GbE IPMI/Management
RAID: Hardware RAID controller with 2GB cache, BBU
Power: Dual redundant PSU (Platinum efficiency)
```

**Storage Nodes (File & Backup)**
```
CPU: 1x Intel Xeon Silver 4314 or AMD EPYC 7313P
RAM: 128 GB DDR4-3200 ECC
Storage:
  - 2x 480GB SSD (RAID 1) - OS
  - 12x 8TB HDD (RAIDZ2) - Data pool
  - 2x 1.92TB NVMe - Cache/Log
Network: 4x 10GbE ports
HBA: LSI 9305-16i or equivalent
Power: Dual redundant PSU
```

**Database Nodes**
```
CPU: 2x Intel Xeon Gold 6338 or AMD EPYC 7543
RAM: 512 GB DDR4-3200 ECC
Storage:
  - 2x 960GB NVMe (RAID 1) - OS
  - 6x 3.84TB NVMe (RAID 10) - Database
Network: 4x 10GbE + 2x 25GbE (cluster interconnect)
RAID: Hardware RAID with 4GB cache, BBU
Power: Dual redundant PSU
```

### Network Infrastructure

#### Core Network Equipment

**Edge Firewall/Router**
```
Platform: Netgate 6100 or build custom pfSense appliance
CPU: 8-core Intel Atom C3000 or better
RAM: 16 GB
Storage: 128 GB M.2 SSD
Ports: 8x 10GbE SFP+, 4x 1GbE RJ45
Throughput: 10+ Gbps with IDS/IPS enabled
```

**Core Switch (L3)**
```
Type: Enterprise managed 10GbE switch
Ports: 48x 10GbE SFP+ + 6x 40GbE QSFP+
Features: L3 routing, LACP, VLAN, QoS, redundant PSU
Backplane: 1.28 Tbps
Example: Arista 7050SX or equivalent
```

**Access Switches (L2)**
```
Type: Managed 1GbE/2.5GbE switch
Ports: 48x 1GbE/2.5GbE + 4x 10GbE SFP+ uplink
Features: VLAN, PoE+ (for WiFi APs), LACP
Example: Ubiquiti UniFi Switch Pro or equivalent
```

### VLAN Segmentation

```
VLAN 10: Management (172.16.10.0/24)
VLAN 20: Server Infrastructure (172.16.20.0/24)
VLAN 30: Database Backend (172.16.30.0/24)
VLAN 40: Storage Network (172.16.40.0/24)
VLAN 50: Office Staff (172.16.50.0/23)
VLAN 60: VoIP/Video (172.16.60.0/24)
VLAN 70: Guest/Contractor (172.16.70.0/24)
VLAN 80: IoT/Devices (172.16.80.0/24)
VLAN 99: DMZ (192.168.99.0/24)
```

---

## Component Stack

### 1. Identity and Access Management (IAM)

#### **Keycloak** - Enterprise Identity Provider
- **Version**: 24.x LTS
- **Purpose**: Centralized authentication and Single Sign-On (SSO)
- **Features**:
  - SAML 2.0, OAuth 2.0, OpenID Connect support
  - Multi-factor authentication (TOTP, WebAuthn, SMS)
  - User federation with LDAP/Active Directory
  - Fine-grained authorization
  - User self-service account management
  - Identity brokering (Google, Microsoft, etc.)
  - Customizable login themes
  - Session management and logout

#### **FreeIPA** - Identity Management & Directory Services
- **Version**: 4.11.x
- **Purpose**: Central user/group management and policy enforcement
- **Features**:
  - Integrated LDAP (389 Directory Server)
  - Kerberos authentication
  - DNS management
  - Certificate Authority (CA)
  - Sudo rules management
  - Host-based access control (HBAC)
  - SELinux user mapping
  - Replication for high availability

**Alternative**: Samba AD DC for Windows-centric environments

### 2. Email Services

#### **iRedMail** - Complete Mail Server Solution
- **Version**: 1.6.x
- **Components**:
  - **Postfix**: SMTP server
  - **Dovecot**: IMAP/POP3 server
  - **SOGo**: Webmail, calendar, contacts
  - **Roundcube**: Alternative webmail
  - **SpamAssassin**: Spam filtering
  - **ClamAV**: Antivirus scanning
  - **Amavisd**: Content filtering
  - **OpenDKIM**: Email authentication
  - **Fail2ban**: Intrusion prevention

- **Features**:
  - Full email server stack
  - Webmail interface
  - Calendar (CalDAV) and contacts (CardDAV)
  - Unlimited domains and aliases
  - Quarantine management
  - DKIM, SPF, DMARC support
  - TLS encryption
  - Sieve filtering

**Storage Estimate**: 1-2 GB per user (average)

### 3. Collaboration Platform

#### **Nextcloud Hub** - Central Collaboration System
- **Version**: 28.x (Hub 7)
- **Core Apps**:
  - **Files**: Cloud storage with versioning
  - **Talk**: Chat and video calls
  - **Calendar**: Scheduling and resource booking
  - **Contacts**: Address book management
  - **Deck**: Kanban boards
  - **Mail**: Email client
  - **Office**: Document collaboration (Collabora/OnlyOffice)
  - **Forms**: Survey and data collection
  - **Tasks**: To-do management

- **Enterprise Features**:
  - Group folders with ACL
  - File access control
  - Workflow automation
  - File retention policies
  - Full-text search (Elasticsearch)
  - E2E encryption
  - External storage integration
  - SAML/OAuth SSO

- **Deployment Mode**: Docker or native (PHP-FPM + Nginx)
- **Database**: PostgreSQL (recommended) or MariaDB
- **Cache**: Redis + APCu

**Storage Estimate**: 10-50 GB per user (depending on usage)

### 4. Team Communication

#### **Mattermost Team Edition** - Enterprise Chat Platform
- **Version**: 9.x
- **Features**:
  - Unlimited channels and teams
  - Direct and group messaging
  - File sharing and search
  - Markdown formatting
  - Custom emoji and reactions
  - Thread conversations
  - Channel webhooks and integrations
  - Mobile push notifications
  - SAML/OAuth SSO
  - Multi-language support

- **Enterprise Add-ons** (if needed):
  - Advanced compliance
  - Guest accounts
  - Custom user groups
  - Data retention policies

- **Deployment**: Docker or binary
- **Database**: PostgreSQL
- **Storage**: S3-compatible (MinIO) or local

**Storage Estimate**: 5-10 GB per user

### 5. Video Conferencing

#### **Jitsi Meet** - Open Source Video Platform
- **Version**: Stable (latest)
- **Components**:
  - **Jitsi Videobridge (JVB)**: Media routing
  - **Jicofo**: Conference focus
  - **Prosody**: XMPP signaling
  - **Jigasi**: SIP gateway (optional)
  - **Jibri**: Recording service (optional)

- **Features**:
  - HD video and audio
  - Screen sharing
  - Virtual backgrounds
  - Live streaming (YouTube, etc.)
  - Recording capabilities
  - Chat and reactions
  - Password protection
  - Guest access (no account needed)
  - Mobile apps

- **Scalability**: Horizontally scale JVB instances
- **Integration**: Embeds in Nextcloud Talk

**Bandwidth Requirements**: 1-2 Mbps per participant

### 6. Help Desk System

#### **Zammad** - Modern Ticketing Platform
- **Version**: 6.x
- **Features**:
  - Multi-channel support (email, phone, chat, social)
  - Customer portal
  - Internal knowledge base
  - Ticket templates and triggers
  - SLA management
  - Time accounting
  - Report builder
  - Text modules (canned responses)
  - Tag management
  - Ticket merge/split
  - LDAP/SSO integration

- **Use Cases**:
  - **Internal**: IT support, HR requests, facilities
  - **External**: Client service requests, incident reports

- **Deployment**: Docker or package install
- **Database**: PostgreSQL
- **Search**: Elasticsearch

**Storage Estimate**: 1-5 GB per year

### 7. Backup and Recovery

#### **Borg Backup** - Deduplicating Backup Program
- **Version**: 1.4.x
- **Features**:
  - Space-efficient deduplication
  - Compression (lz4, zstd, lzma)
  - Encryption (AES-256)
  - Data integrity verification
  - Mount capability for file recovery
  - Append-only mode (ransomware protection)

#### **Proxmox Backup Server (PBS)** - VM/Container Backup
- **Version**: 3.x
- **Features** (if using Proxmox VE):
  - Incremental backups
  - Block-level deduplication
  - Encryption at rest
  - Backup verification
  - Web-based management
  - Retention policies
  - Tape backup integration

**Alternative**: Bareos (Enterprise-grade backup solution)

### 8. Monitoring and Logging

#### **Zabbix** - Infrastructure Monitoring
- **Version**: 7.x LTS
- **Monitoring**:
  - Server health (CPU, RAM, disk, network)
  - Service availability
  - Application metrics
  - Network devices (SNMP)
  - Log file analysis
  - Custom metrics via API

- **Features**:
  - Auto-discovery
  - Templating
  - Alerting (email, SMS, webhooks)
  - Web dashboards
  - Historical data analysis
  - Map visualization

#### **Graylog** - Log Management
- **Version**: 5.x
- **Features**:
  - Centralized logging
  - Full-text search
  - Stream processing
  - Alerting and notifications
  - Dashboard creation
  - Role-based access control

**Alternative**: ELK Stack (Elasticsearch, Logstash, Kibana)

#### **Prometheus + Grafana** - Metrics and Visualization
- **Prometheus**: Time-series database for metrics
- **Grafana**: Visualization and dashboards
- **Node Exporter**: System metrics
- **Application Exporters**: PostgreSQL, Redis, Nginx, etc.

### 9. Reverse Proxy and Load Balancing

#### **Traefik** - Modern Reverse Proxy (Recommended)
- **Version**: 2.x/3.x
- **Features**:
  - Automatic service discovery
  - Let's Encrypt integration
  - Load balancing
  - Middleware (auth, rate limiting, etc.)
  - Metrics export
  - WebSocket support

**Alternative**: HAProxy + Nginx (traditional setup)

### 10. Database Layer

#### **PostgreSQL** - Primary Relational Database
- **Version**: 16.x
- **Used by**: Nextcloud, Mattermost, Zammad, Keycloak, Gitea
- **High Availability**: 
  - Patroni cluster (leader election)
  - Streaming replication
  - Automatic failover

#### **MariaDB** - Secondary Database
- **Version**: 11.x LTS
- **Used by**: Legacy apps, iRedMail (optional)
- **High Availability**: Galera cluster

#### **Redis** - In-Memory Cache
- **Version**: 7.x
- **Used by**: Nextcloud, Mattermost (optional), session storage
- **High Availability**: Redis Sentinel or Cluster mode

---

## Network Architecture

### Production Network Topology

```
                          Internet (Public IPs)
                                  │
                   ┌──────────────┴──────────────┐
                   │   Edge Firewall/Router      │
                   │  (pfSense/OPNsense)         │
                   │  • NAT                      │
                   │  • IDS/IPS (Suricata)       │
                   │  • VPN Server (WireGuard)   │
                   └──────────────┬──────────────┘
                                  │
                   ┌──────────────┴──────────────┐
                   │  Core L3 Switch             │
                   │  Inter-VLAN Routing         │
                   └──────────────┬──────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
    ┌────▼────┐            ┌──────▼──────┐         ┌──────▼──────┐
    │ VLAN 99 │            │  VLAN 20    │         │  VLAN 50    │
    │   DMZ   │            │  Servers    │         │   Clients   │
    └─────────┘            └─────────────┘         └─────────────┘
         │                        │
    ┌────▼────────┐        ┌──────▼──────────┐
    │ Traefik     │        │ Application     │
    │ HAProxy     │        │ Servers         │
    │ WAF         │        │ - Nextcloud     │
    └─────────────┘        │ - Mattermost    │
                           │ - Keycloak      │
                           │ - Jitsi         │
                           │ - Zammad        │
                           └─────────────────┘
```

### Firewall Rules Summary

#### Internet → DMZ (VLAN 99)
```
ALLOW tcp/443 (HTTPS) → Reverse Proxy
ALLOW tcp/80 (HTTP - redirect to 443) → Reverse Proxy
ALLOW udp/10000 (Jitsi video) → JVB
ALLOW tcp/5349 (TURNS) → Jitsi
ALLOW tcp/443 (VPN) → WireGuard/OpenVPN
DENY all other
```

#### DMZ → Server VLAN (VLAN 20)
```
ALLOW tcp/443,80 → Application servers (Nextcloud, Mattermost, etc.)
ALLOW tcp/8443 → Keycloak
ALLOW tcp/5222,5280 → Prosody (Jitsi signaling)
DENY all other
```

#### Server VLAN → Database VLAN (VLAN 30)
```
ALLOW tcp/5432 → PostgreSQL
ALLOW tcp/3306 → MariaDB
ALLOW tcp/6379 → Redis
DENY all other
```

#### Client VLAN → Server VLAN
```
ALLOW tcp/443 → All web services
ALLOW tcp/587,993 → Mail (SMTP submission, IMAP)
ALLOW tcp/5222 → XMPP (Jitsi)
ALLOW established/related
DENY all other
```

### DNS Configuration

#### Internal DNS (FreeIPA/Bind)
```
Domain: company.internal
NS Records: ipa1.company.internal, ipa2.company.internal

# Service Records
mail.company.internal       → 172.16.20.10 (iRedMail)
cloud.company.internal      → 172.16.20.20 (Nextcloud)
chat.company.internal       → 172.16.20.30 (Mattermost)
meet.company.internal       → 172.16.20.40 (Jitsi)
desk.company.internal       → 172.16.20.50 (Zammad)
sso.company.internal        → 172.16.20.60 (Keycloak)
```

#### External DNS (Public)
```
Domain: company.com

# Public A Records
mail.company.com           → <Public IP 1>
cloud.company.com          → <Public IP 1>
chat.company.com           → <Public IP 1>
meet.company.com           → <Public IP 1>
desk.company.com           → <Public IP 1>
vpn.company.com            → <Public IP 1>

# MX Records
company.com   MX 10 mail.company.com

# SPF Record
company.com   TXT "v=spf1 mx ip4:<Public IP 1> -all"

# DMARC Record
_dmarc.company.com  TXT "v=DMARC1; p=quarantine; rua=mailto:postmaster@company.com"

# DKIM Record
default._domainkey.company.com  TXT "v=DKIM1; k=rsa; p=<public-key>"

# SRV Records (Jitsi)
_turns._tcp.company.com  SRV 5 0 5349 meet.company.com
```

### SSL/TLS Certificate Management

#### Certificate Strategy
- **Public Services**: Let's Encrypt (automated renewal via Traefik/Certbot)
- **Internal Services**: FreeIPA CA or private CA
- **Wildcard Cert**: *.company.com (for all external services)

#### Certificate Locations
```
/etc/ssl/certs/company.com/          # Primary cert directory
├── fullchain.pem                    # Full certificate chain
├── privkey.pem                      # Private key
├── cert.pem                         # Server certificate
└── chain.pem                        # Intermediate chain
```

---

## Server Deployment Specifications

### Virtualization Platform

#### **Proxmox VE** (Recommended)
- **Version**: 8.x
- **Features**: 
  - KVM/LXC virtualization
  - Web-based management
  - High availability clustering
  - Live migration
  - Backup integration (PBS)
  - Software-defined networking
  - Ceph integration (optional)

**Alternative**: oVirt, XCP-ng, or bare-metal deployments

### Virtual Machine Allocation

#### VM Configuration Standards

**Small VM** (Support services)
```yaml
vCPU: 2
RAM: 4 GB
Disk: 50 GB
OS: Ubuntu 24.04 LTS / Rocky Linux 9
Examples: Monitoring agents, log collectors
```

**Medium VM** (Application servers)
```yaml
vCPU: 4-8
RAM: 8-16 GB
Disk: 100-200 GB
OS: Ubuntu 24.04 LTS / Rocky Linux 9
Examples: Nextcloud, Mattermost, Keycloak, Jitsi
```

**Large VM** (Database, heavy workloads)
```yaml
vCPU: 8-16
RAM: 32-64 GB
Disk: 500 GB - 1 TB (SSD/NVMe)
OS: Ubuntu 24.04 LTS / Rocky Linux 9
Examples: PostgreSQL, MariaDB, Elasticsearch
```

### Server Inventory (100-User Deployment Example)

| Hostname | Role | vCPU | RAM | Disk | IP | VLAN |
|----------|------|------|-----|------|-----|------|
| ipa1.company.internal | FreeIPA Primary | 4 | 8 GB | 100 GB | 172.16.20.5 | 20 |
| ipa2.company.internal | FreeIPA Replica | 4 | 8 GB | 100 GB | 172.16.20.6 | 20 |
| sso1.company.internal | Keycloak Node 1 | 4 | 8 GB | 100 GB | 172.16.20.60 | 20 |
| sso2.company.internal | Keycloak Node 2 | 4 | 8 GB | 100 GB | 172.16.20.61 | 20 |
| mail1.company.internal | Mail Server | 8 | 16 GB | 500 GB | 172.16.20.10 | 20 |
| cloud1.company.internal | Nextcloud | 8 | 16 GB | 200 GB | 172.16.20.20 | 20 |
| chat1.company.internal | Mattermost | 4 | 8 GB | 100 GB | 172.16.20.30 | 20 |
| meet1.company.internal | Jitsi Videobridge | 8 | 16 GB | 100 GB | 172.16.20.40 | 20 |
| desk1.company.internal | Zammad | 4 | 8 GB | 100 GB | 172.16.20.50 | 20 |
| db1.company.internal | PostgreSQL Primary | 8 | 32 GB | 500 GB | 172.16.30.10 | 30 |
| db2.company.internal | PostgreSQL Standby | 8 | 32 GB | 500 GB | 172.16.30.11 | 30 |
| cache1.company.internal | Redis Primary | 4 | 8 GB | 100 GB | 172.16.30.20 | 30 |
| storage1.company.internal | File Storage (NFS/Ceph) | 8 | 32 GB | 10 TB | 172.16.40.10 | 40 |
| backup1.company.internal | Backup Server | 8 | 16 GB | 20 TB | 172.16.40.20 | 40 |
| proxy1.company.internal | Traefik/HAProxy | 4 | 8 GB | 50 GB | 192.168.99.10 | 99 |
| monitor1.company.internal | Zabbix | 4 | 8 GB | 200 GB | 172.16.20.70 | 20 |
| log1.company.internal | Graylog/ELK | 8 | 16 GB | 500 GB | 172.16.20.71 | 20 |

**Total Resources**: 98 vCPU, 238 GB RAM, ~32 TB Storage

---

## Installation Procedures

### Phase 1: Foundation Layer (Week 1-2)

#### 1.1 Base OS Installation

**Operating System Choice**:
- **Primary**: Ubuntu 24.04 LTS (Long-term support until 2029)
- **Alternative**: Rocky Linux 9 (RHEL-compatible, for enterprise preference)

**Standard Installation Process**:

1. **Download and Verify ISO**
```bash
# Ubuntu
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
wget https://releases.ubuntu.com/24.04/SHA256SUMS
sha256sum -c SHA256SUMS 2>&1 | grep OK
```

2. **Create Base Template** (Proxmox)
```bash
# On Proxmox host
qm create 9000 --name ubuntu-24.04-template --memory 4096 --cores 2 --net0 virtio,bridge=vmbr0
qm set 9000 --scsi0 local-lvm:32
qm set 9000 --ide2 local:iso/ubuntu-24.04-live-server-amd64.iso,media=cdrom
qm set 9000 --boot order=scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Start VM and install via console
qm start 9000
qm terminal 9000
```

3. **Post-Install Configuration** (on template)
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y vim curl wget git htop tmux \
  net-tools dnsutils tcpdump nmap qemu-guest-agent \
  chrony ntp fail2ban ufw

# Configure time sync
sudo systemctl enable --now chrony

# Set timezone
sudo timedatectl set-timezone America/Toronto  # Adjust for your location

# Configure automatic updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Disable swap (for production VMs)
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Cloud-init cleanup (for template)
sudo cloud-init clean
sudo rm -rf /var/lib/cloud/instances
sudo truncate -s 0 /etc/machine-id
sudo rm /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# Shutdown template
sudo shutdown -h now
```

4. **Convert to Template**
```bash
# On Proxmox host
qm template 9000
```

#### 1.2 Network Configuration

**Standard Network Setup** (on each VM):

```bash
# Edit /etc/netplan/50-cloud-init.yaml
sudo nano /etc/netplan/50-cloud-init.yaml
```

```yaml
network:
  version: 2
  ethernets:
    ens18:
      dhcp4: no
      addresses:
        - 172.16.20.XX/24  # Adjust per server
      gateway4: 172.16.20.1
      nameservers:
        addresses:
          - 172.16.20.5   # FreeIPA server
          - 172.16.20.6   # FreeIPA replica
          - 1.1.1.1       # Fallback
        search:
          - company.internal
```

```bash
# Apply configuration
sudo netplan apply

# Verify
ip addr show
ping -c 3 google.com
```

#### 1.3 FreeIPA Deployment

**Server 1 (Primary)**:

```bash
# Set hostname
sudo hostnamectl set-hostname ipa1.company.internal

# Update /etc/hosts
sudo nano /etc/hosts
```

```
127.0.0.1 localhost
172.16.20.5 ipa1.company.internal ipa1

# FreeIPA servers
172.16.20.5 ipa1.company.internal ipa1
172.16.20.6 ipa2.company.internal ipa2
```

```bash
# Install FreeIPA server
sudo apt install -y freeipa-server freeipa-server-dns

# Run installation wizard
sudo ipa-server-install \
  --domain=company.internal \
  --realm=COMPANY.INTERNAL \
  --ds-password='<Directory Manager Password>' \
  --admin-password='<Admin Password>' \
  --hostname=ipa1.company.internal \
  --ip-address=172.16.20.5 \
  --setup-dns \
  --forwarder=1.1.1.1 \
  --forwarder=8.8.8.8 \
  --reverse-zone=20.16.172.in-addr.arpa. \
  --no-ntp \
  --unattended

# Firewall configuration
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 389/tcp
sudo ufw allow 636/tcp
sudo ufw allow 88/tcp
sudo ufw allow 88/udp
sudo ufw allow 464/tcp
sudo ufw allow 464/udp
sudo ufw allow 123/udp
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw enable

# Obtain Kerberos ticket
kinit admin
klist
```

**Server 2 (Replica)**:

```bash
# Set hostname
sudo hostnamectl set-hostname ipa2.company.internal

# Update /etc/hosts (same as Server 1)

# Install FreeIPA client first
sudo apt install -y freeipa-client

# Join domain
sudo ipa-client-install \
  --domain=company.internal \
  --realm=COMPANY.INTERNAL \
  --server=ipa1.company.internal \
  --principal=admin \
  --password='<Admin Password>' \
  --mkhomedir \
  --unattended

# Install replica packages
sudo apt install -y freeipa-server freeipa-server-dns

# Set up replica
sudo ipa-replica-install \
  --setup-dns \
  --forwarder=1.1.1.1 \
  --forwarder=8.8.8.8 \
  --no-ntp \
  --unattended

# Configure firewall (same as Server 1)
```

**Create Service Accounts**:

```bash
# Authenticate
kinit admin

# Create service accounts for applications
ipa user-add keycloak --first=Keycloak --last="Service Account" --email=keycloak@company.internal
ipa user-add nextcloud --first=Nextcloud --last="Service Account" --email=nextcloud@company.internal
ipa user-add mattermost --first=Mattermost --last="Service Account" --email=mattermost@company.internal

# Create groups
ipa group-add --desc="Back Office Staff" office-staff
ipa group-add --desc="Security Guards" guards
ipa group-add --desc="IT Administrators" it-admins
ipa group-add --desc="Managers" managers

# Set group policies (HBAC)
ipa hbacrule-add allow_all_services
ipa hbacrule-add-service allow_all_services --hbacsvcs=sshd
ipa hbacrule-add-user allow_all_services --groups=it-admins
```

#### 1.4 Keycloak Deployment

**Database Preparation** (on PostgreSQL server):

```bash
# Install PostgreSQL
sudo apt install -y postgresql-16 postgresql-contrib

# Configure PostgreSQL
sudo -u postgres psql

CREATE DATABASE keycloak;
CREATE USER keycloak WITH ENCRYPTED PASSWORD '<keycloak-db-password>';
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
\q

# Allow remote connections
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

Add:
```
host    keycloak    keycloak    172.16.20.0/24    scram-sha-256
```

```bash
# Restart PostgreSQL
sudo systemctl restart postgresql
```

**Keycloak Installation** (on sso1.company.internal):

```bash
# Install Java 17
sudo apt install -y openjdk-17-jdk

# Download Keycloak
cd /opt
sudo wget https://github.com/keycloak/keycloak/releases/download/24.0.0/keycloak-24.0.0.tar.gz
sudo tar -xzf keycloak-24.0.0.tar.gz
sudo mv keycloak-24.0.0 keycloak
sudo chown -R root:root /opt/keycloak

# Create Keycloak user
sudo useradd -r -s /bin/false keycloak
sudo chown -R keycloak:keycloak /opt/keycloak

# Configure database
sudo nano /opt/keycloak/conf/keycloak.conf
```

```properties
# Database configuration
db=postgres
db-url=jdbc:postgresql://172.16.30.10:5432/keycloak
db-username=keycloak
db-password=<keycloak-db-password>

# HTTP/HTTPS configuration
hostname=sso.company.com
http-enabled=true
http-port=8080
https-port=8443
proxy=edge

# Clustering (for HA)
cache=ispn
cache-stack=tcp
```

```bash
# Build Keycloak
cd /opt/keycloak
sudo -u keycloak ./bin/kc.sh build

# Create systemd service
sudo nano /etc/systemd/system/keycloak.service
```

```ini
[Unit]
Description=Keycloak Application Server
After=network.target postgresql.service

[Service]
Type=idle
User=keycloak
Group=keycloak
ExecStart=/opt/keycloak/bin/kc.sh start
ExecStop=/opt/keycloak/bin/kc.sh stop
Restart=on-failure
RestartSec=10s
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable keycloak
sudo systemctl start keycloak

# Check status
sudo systemctl status keycloak
sudo journalctl -u keycloak -f

# Create admin user
cd /opt/keycloak
sudo -u keycloak ./bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password <admin-password>
```

**Configure LDAP Integration**:

Access Keycloak admin console: `https://sso.company.com/admin`

1. Create realm: `company`
2. User Federation → Add provider → LDAP
   - **Edit Mode**: WRITABLE
   - **Vendor**: Red Hat Directory Server
   - **Connection URL**: ldap://ipa1.company.internal ldap://ipa2.company.internal
   - **Bind DN**: uid=keycloak,cn=users,cn=accounts,dc=company,dc=internal
   - **Bind Credential**: <keycloak service account password>
   - **Users DN**: cn=users,cn=accounts,dc=company,dc=internal
   - **UUID LDAP Attribute**: ipaUniqueID
   - **RDN LDAP Attribute**: uid
   - **Username LDAP Attribute**: uid
   - Save and Test Connection

3. Mappers:
   - email: mail
   - first name: givenName
   - last name: sn
   - groups: memberOf (for group membership)

#### 1.5 Reverse Proxy Setup (Traefik)

**Installation on proxy1.company.internal**:

```bash
# Install Docker
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker

# Create Traefik directory structure
sudo mkdir -p /opt/traefik/{config,certs,logs}
cd /opt/traefik
```

**Create docker-compose.yml**:

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.11
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
    ports:
      - "80:80"
      - "443:443"
    environment:
      - CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}  # For Cloudflare DNS challenge (if used)
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik.yml:/traefik.yml:ro
      - ./config:/config:ro
      - ./certs:/certs
      - ./logs:/logs
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.entrypoints=https"
      - "traefik.http.routers.traefik.rule=Host(`traefik.company.com`)"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.middlewares=auth"
      - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$..."  # htpasswd hash

networks:
  proxy:
    external: true
```

**Create traefik.yml**:

```yaml
api:
  dashboard: true
  insecure: false

entryPoints:
  http:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: https
          scheme: https
  https:
    address: ":443"
    http:
      tls:
        certResolver: letsencrypt

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@company.com
      storage: /certs/acme.json
      httpChallenge:
        entryPoint: http
      # For wildcard certs, use DNS challenge:
      # dnsChallenge:
      #   provider: cloudflare
      #   resolvers:
      #     - "1.1.1.1:53"
      #     - "8.8.8.8:53"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: proxy
  file:
    directory: /config
    watch: true

log:
  level: INFO
  filePath: /logs/traefik.log
  format: json

accessLog:
  filePath: /logs/access.log
  format: json
  filters:
    statusCodes:
      - "400-499"
      - "500-599"
```

**Create backend service configurations**:

```bash
sudo nano /opt/traefik/config/backends.yml
```

```yaml
http:
  routers:
    nextcloud:
      rule: "Host(`cloud.company.com`)"
      entryPoints:
        - https
      service: nextcloud
      tls:
        certResolver: letsencrypt
      middlewares:
        - security-headers
        - rate-limit

    mattermost:
      rule: "Host(`chat.company.com`)"
      entryPoints:
        - https
      service: mattermost
      tls:
        certResolver: letsencrypt
      middlewares:
        - security-headers

    jitsi:
      rule: "Host(`meet.company.com`)"
      entryPoints:
        - https
      service: jitsi
      tls:
        certResolver: letsencrypt
      middlewares:
        - security-headers

    keycloak:
      rule: "Host(`sso.company.com`)"
      entryPoints:
        - https
      service: keycloak
      tls:
        certResolver: letsencrypt
      middlewares:
        - security-headers

    zammad:
      rule: "Host(`desk.company.com`)"
      entryPoints:
        - https
      service: zammad
      tls:
        certResolver: letsencrypt
      middlewares:
        - security-headers

  services:
    nextcloud:
      loadBalancer:
        servers:
          - url: "http://172.16.20.20:80"
        healthCheck:
          path: /status.php
          interval: "10s"
          timeout: "3s"

    mattermost:
      loadBalancer:
        servers:
          - url: "http://172.16.20.30:8065"
        healthCheck:
          path: /api/v4/system/ping
          interval: "10s"

    jitsi:
      loadBalancer:
        servers:
          - url: "http://172.16.20.40:80"

    keycloak:
      loadBalancer:
        servers:
          - url: "http://172.16.20.60:8080"
          - url: "http://172.16.20.61:8080"
        healthCheck:
          path: /health
          interval: "10s"

    zammad:
      loadBalancer:
        servers:
          - url: "http://172.16.20.50:3000"

  middlewares:
    security-headers:
      headers:
        customResponseHeaders:
          X-Robots-Tag: "noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex"
          server: ""
        sslRedirect: true
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
        forceSTSHeader: true
        frameDeny: true
        contentTypeNosniff: true
        browserXssFilter: true
        referrerPolicy: "same-origin"
        customFrameOptionsValue: "SAMEORIGIN"

    rate-limit:
      rateLimit:
        average: 100
        burst: 50
        period: 1m
```

```bash
# Create Docker network
sudo docker network create proxy

# Set permissions
sudo chmod 600 /opt/traefik/certs
sudo touch /opt/traefik/certs/acme.json
sudo chmod 600 /opt/traefik/certs/acme.json

# Start Traefik
sudo docker-compose up -d

# Check logs
sudo docker-compose logs -f
```

---

### Phase 2: Core Services (Week 3-4)

#### 2.1 PostgreSQL High Availability Cluster

**Install PostgreSQL on db1 and db2**:

```bash
# Install PostgreSQL 16
sudo apt install -y postgresql-16 postgresql-contrib
sudo systemctl enable postgresql

# Install Patroni for HA
sudo apt install -y python3-pip python3-psycopg2
sudo pip3 install patroni[etcd] python-etcd

# Install etcd (distributed configuration store)
sudo apt install -y etcd
```

**Configure etcd** (on db1, db2, and one more server for quorum):

```bash
# /etc/default/etcd
ETCD_NAME="db1"  # Change per node
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_LISTEN_CLIENT_URLS="http://172.16.30.10:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://172.16.30.10:2379"
ETCD_LISTEN_PEER_URLS="http://172.16.30.10:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.16.30.10:2380"
ETCD_INITIAL_CLUSTER="db1=http://172.16.30.10:2380,db2=http://172.16.30.11:2380,db3=http://172.16.30.12:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="postgres-cluster"

sudo systemctl restart etcd
```

**Configure Patroni** (on db1):

```yaml
# /etc/patroni/patroni.yml
scope: postgres-cluster
namespace: /db/
name: db1

restapi:
  listen: 172.16.30.10:8008
  connect_address: 172.16.30.10:8008

etcd:
  hosts: 172.16.30.10:2379,172.16.30.11:2379,172.16.30.12:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      parameters:
        max_connections: 500
        shared_buffers: 8GB
        effective_cache_size: 24GB
        maintenance_work_mem: 2GB
        checkpoint_completion_target: 0.9
        wal_buffers: 16MB
        default_statistics_target: 100
        random_page_cost: 1.1
        effective_io_concurrency: 200
        work_mem: 10MB
        min_wal_size: 1GB
        max_wal_size: 4GB
        max_worker_processes: 8
        max_parallel_workers_per_gather: 4
        max_parallel_workers: 8
        max_parallel_maintenance_workers: 4

  initdb:
    - encoding: UTF8
    - locale: en_US.UTF-8
    - data-checksums

  pg_hba:
    - host replication replicator 172.16.30.0/24 scram-sha-256
    - host all all 172.16.20.0/24 scram-sha-256
    - host all all 172.16.30.0/24 scram-sha-256
    - host all all 127.0.0.1/32 scram-sha-256

  users:
    admin:
      password: <admin-password>
      options:
        - createrole
        - createdb
    replicator:
      password: <replicator-password>
      options:
        - replication

postgresql:
  listen: 172.16.30.10:5432
  connect_address: 172.16.30.10:5432
  data_dir: /var/lib/postgresql/16/main
  bin_dir: /usr/lib/postgresql/16/bin
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: <replicator-password>
    superuser:
      username: postgres
      password: <postgres-password>
  parameters:
    unix_socket_directories: '/var/run/postgresql'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false
```

```bash
# Create systemd service
sudo nano /etc/systemd/system/patroni.service
```

```ini
[Unit]
Description=Patroni PostgreSQL Cluster Manager
After=syslog.target network.target etcd.service

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni/patroni.yml
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=process
TimeoutSec=30
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
# Stop PostgreSQL (managed by Patroni now)
sudo systemctl stop postgresql
sudo systemctl disable postgresql

# Start Patroni
sudo systemctl daemon-reload
sudo systemctl enable patroni
sudo systemctl start patroni

# Check cluster status
patronictl -c /etc/patroni/patroni.yml list
```

**Repeat for db2** (adjust name, IPs in patroni.yml)

**Setup HAProxy for PostgreSQL** (on separate VM or proxy server):

```bash
sudo apt install -y haproxy

sudo nano /etc/haproxy/haproxy.cfg
```

```
global
    maxconn 4096
    log /dev/log local0

defaults
    log global
    mode tcp
    option tcplog
    option dontlognull
    retries 3
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

listen postgres_cluster
    bind *:5000
    mode tcp
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server db1 172.16.30.10:5432 maxconn 100 check port 8008
    server db2 172.16.30.11:5432 maxconn 100 check port 8008

listen postgres_replica
    bind *:5001
    mode tcp
    balance roundrobin
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server db1 172.16.30.10:5432 maxconn 100 check port 8008
    server db2 172.16.30.11:5432 maxconn 100 check port 8008

listen stats
    bind *:7000
    mode http
    stats enable
    stats uri /
    stats refresh 30s
```

```bash
sudo systemctl restart haproxy
```

**Applications now connect to**:
- Write: `172.16.30.15:5000` (HAProxy VIP, primary only)
- Read: `172.16.30.15:5001` (HAProxy VIP, load balanced)

#### 2.2 Nextcloud Hub Deployment

**Database Setup**:

```bash
# On PostgreSQL
sudo -u postgres psql

CREATE DATABASE nextcloud;
CREATE USER nextcloud WITH ENCRYPTED PASSWORD '<nextcloud-db-password>';
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
\q
```

**Install Dependencies** (on cloud1.company.internal):

```bash
# Install web server and PHP
sudo apt install -y nginx php8.3-fpm php8.3-cli php8.3-common \
  php8.3-mysql php8.3-pgsql php8.3-zip php8.3-gd php8.3-mbstring \
  php8.3-curl php8.3-xml php8.3-bcmath php8.3-intl php8.3-imagick \
  php8.3-apcu php8.3-redis php8.3-gmp php8.3-bz2 \
  redis-server unzip

# Install recommended packages
sudo apt install -y ffmpeg libreoffice
```

**Download Nextcloud**:

```bash
cd /tmp
wget https://download.nextcloud.com/server/releases/nextcloud-28.0.0.tar.bz2
wget https://download.nextcloud.com/server/releases/nextcloud-28.0.0.tar.bz2.sha256

# Verify checksum
sha256sum -c nextcloud-28.0.0.tar.bz2.sha256 < nextcloud-28.0.0.tar.bz2

# Extract
sudo tar -xjf nextcloud-28.0.0.tar.bz2 -C /var/www/
sudo chown -R www-data:www-data /var/www/nextcloud
```

**Configure PHP**:

```bash
sudo nano /etc/php/8.3/fpm/php.ini
```

```ini
memory_limit = 512M
upload_max_filesize = 10G
post_max_size = 10G
max_execution_time = 3600
max_input_time = 3600
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=60
opcache.save_comments=1
```

```bash
sudo nano /etc/php/8.3/fpm/pool.d/www.conf
```

```ini
pm = dynamic
pm.max_children = 120
pm.start_servers = 12
pm.min_spare_servers = 6
pm.max_spare_servers = 18
```

```bash
sudo systemctl restart php8.3-fpm
```

**Configure Nginx**:

```bash
sudo nano /etc/nginx/sites-available/nextcloud
```

```nginx
upstream php-handler {
    server unix:/run/php/php8.3-fpm.sock;
}

server {
    listen 80;
    listen [::]:80;
    server_name cloud.company.com cloud.company.internal;

    # Add headers to serve security related headers
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload;" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Download-Options "noopen" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Permitted-Cross-Domain-Policies "none" always;
    add_header X-Robots-Tag "noindex, nofollow" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Path to the root of your installation
    root /var/www/nextcloud;

    # Specify how to handle directories
    location = / {
        if ( $http_user_agent ~ ^DavClnt ) {
            return 302 /remote.php/webdav/$is_args$args;
        }
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    # Make a regex exception for `/.well-known` so that clients can still
    # access it despite the existence of the regex rule
    location ^~ /.well-known {
        location = /.well-known/carddav { return 301 /remote.php/dav/; }
        location = /.well-known/caldav  { return 301 /remote.php/dav/; }

        location /.well-known/acme-challenge    { try_files $uri $uri/ =404; }
        location /.well-known/pki-validation    { try_files $uri $uri/ =404; }

        return 301 /index.php$request_uri;
    }

    # Rules borrowed from `.htaccess` to hide certain paths from clients
    location ~ ^/(?:build|tests|config|lib|3rdparty|templates|data)(?:$|/)  { return 404; }
    location ~ ^/(?:\.|autotest|occ|issue|indie|db_|console)                { return 404; }

    # Ensure this block, which passes PHP files to the PHP process, is above the blocks
    # which handle static assets (as seen below).
    location ~ \.php(?:$|/) {
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;
        set $path_info $fastcgi_path_info;

        try_files $fastcgi_script_name =404;

        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $path_info;

        fastcgi_param modHeadersAvailable true;
        fastcgi_param front_controller_active true;
        fastcgi_pass php-handler;

        fastcgi_intercept_errors on;
        fastcgi_request_buffering off;

        fastcgi_read_timeout 3600;
        fastcgi_send_timeout 3600;
        fastcgi_connect_timeout 3600;
    }

    location ~ \.(?:css|js|svg|gif|png|jpg|ico|wasm|tflite|map)$ {
        try_files $uri /index.php$request_uri;
        add_header Cache-Control "public, max-age=15778463, immutable";
        access_log off;
    }

    location ~ \.woff2?$ {
        try_files $uri /index.php$request_uri;
        expires 7d;
        access_log off;
    }

    # Rule borrowed from `.htaccess`
    location /remote {
        return 301 /remote.php$request_uri;
    }

    location / {
        try_files $uri $uri/ /index.php$request_uri;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**Install Nextcloud via CLI**:

```bash
cd /var/www/nextcloud
sudo -u www-data php occ maintenance:install \
  --database="pgsql" \
  --database-name="nextcloud" \
  --database-host="172.16.30.15:5000" \
  --database-user="nextcloud" \
  --database-pass="<nextcloud-db-password>" \
  --admin-user="admin" \
  --admin-pass="<admin-password>" \
  --data-dir="/var/www/nextcloud/data"

# Configure trusted domains
sudo -u www-data php occ config:system:set trusted_domains 0 --value=cloud.company.com
sudo -u www-data php occ config:system:set trusted_domains 1 --value=cloud.company.internal
sudo -u www-data php occ config:system:set trusted_domains 2 --value=172.16.20.20

# Configure Redis caching
sudo -u www-data php occ config:system:set redis host --value=172.16.30.20
sudo -u www-data php occ config:system:set redis port --value=6379
sudo -u www-data php occ config:system:set memcache.local --value='\\OC\\Memcache\\APCu'
sudo -u www-data php occ config:system:set memcache.distributed --value='\\OC\\Memcache\\Redis'
sudo -u www-data php occ config:system:set memcache.locking --value='\\OC\\Memcache\\Redis'

# Configure background jobs
sudo -u www-data php occ background:cron

# Add cron job
echo "*/5  *  *  *  * www-data php -f /var/www/nextcloud/cron.php" | sudo tee -a /etc/crontab

# Configure default phone region (adjust as needed)
sudo -u www-data php occ config:system:set default_phone_region --value="CA"
```

**Install Nextcloud Office** (Collabora Online):

```bash
# Using Docker for Collabora
sudo docker run -d \
  --name collabora \
  --restart unless-stopped \
  -p 9980:9980 \
  -e "domain=cloud\\.company\\.com" \
  -e "username=admin" \
  -e "password=<collabora-admin-password>" \
  -e "extra_params=--o:ssl.enable=false --o:ssl.termination=true" \
  collabora/code

# Install Nextcloud Office app
sudo -u www-data php occ app:install richdocuments
sudo -u www-data php occ config:app:set richdocuments wopi_url --value="http://172.16.20.20:9980"
```

**Configure LDAP/SSO Integration**:

```bash
# Install LDAP app
sudo -u www-data php occ app:install user_ldap

# Configure via web UI or CLI
sudo -u www-data php occ ldap:create-empty-config
sudo -u www-data php occ ldap:set-config s01 ldapHost "ldap://ipa1.company.internal ldap://ipa2.company.internal"
sudo -u www-data php occ ldap:set-config s01 ldapPort 389
sudo -u www-data php occ ldap:set-config s01 ldapAgentName "uid=nextcloud,cn=users,cn=accounts,dc=company,dc=internal"
sudo -u www-data php occ ldap:set-config s01 ldapAgentPassword "<nextcloud-service-account-password>"
sudo -u www-data php occ ldap:set-config s01 ldapBase "cn=accounts,dc=company,dc=internal"
sudo -u www-data php occ ldap:set-config s01 ldapUserFilter "(&(objectClass=person)(uid=*))"
sudo -u www-data php occ ldap:set-config s01 ldapGroupFilter "(&(objectClass=groupOfNames)(cn=*))"
sudo -u www-data php occ ldap:set-config s01 ldapLoginFilter "(&(objectClass=person)(uid=%uid))"
sudo -u www-data php occ ldap:set-config s01 ldapEmailAttribute "mail"
sudo -u www-data php occ ldap:set-config s01 ldapUserDisplayName "displayName"
sudo -u www-data php occ ldap:set-config s01 ldapConfigurationActive 1

# Test LDAP connection
sudo -u www-data php occ ldap:test-config s01
```

**Install Essential Apps**:

```bash
# Productivity
sudo -u www-data php occ app:install calendar
sudo -u www-data php occ app:install contacts
sudo -u www-data php occ app:install tasks
sudo -u www-data php occ app:install deck
sudo -u www-data php occ app:install forms

# Communication
sudo -u www-data php occ app:install spreed  # Talk

# Files
sudo -u www-data php occ app:install files_pdfviewer
sudo -u www-data php occ app:install files_texteditor
sudo -u www-data php occ app:install files_markdown

# Security
sudo -u www-data php occ app:install twofactor_totp
sudo -u www-data php occ app:install end_to_end_encryption

# Admin tools
sudo -u www-data php occ app:install admin_audit
sudo -u www-data php occ app:install files_retention
```

#### 2.3 iRedMail Email Server

**Pre-installation Preparation** (mail1.company.internal):

```bash
# Set hostname
sudo hostnamectl set-hostname mail.company.com

# Update /etc/hosts
echo "172.16.20.10 mail.company.com mail" | sudo tee -a /etc/hosts

# Disable AppArmor (can interfere)
sudo systemctl stop apparmor
sudo systemctl disable apparmor
```

**Download and Install iRedMail**:

```bash
cd /tmp
wget https://github.com/iredmail/iRedMail/archive/1.6.8.tar.gz
tar -xzf 1.6.8.tar.gz
cd iRedMail-1.6.8

# Run installer
sudo bash iRedMail.sh
```

**Installation Wizard Selections**:
1. Welcome: Continue
2. Mail storage path: `/var/vmail` (default)
3. Backend: **MariaDB** or **PostgreSQL** (recommend PostgreSQL)
4. First domain: `company.com`
5. Postmaster password: Set strong password
6. Optional components:
   - [x] Roundcubemail (webmail)
   - [x] SOGo Groupware (calendar/contacts)
   - [x] netdata (monitoring)
   - [x] iRedAdmin (web admin panel)
   - [x] Fail2ban

**Post-Installation Configuration**:

```bash
# Get configuration summary
cat /root/iRedMail-1.6.8/iRedMail.tips
```

**Configure DKIM**:

```bash
# Get DKIM public key
sudo amavisd-new showkeys

# Add to DNS (see DNS Configuration section)
```

**Firewall Rules**:

```bash
sudo ufw allow 25/tcp    # SMTP
sudo ufw allow 587/tcp   # SMTP Submission
sudo ufw allow 465/tcp   # SMTPS
sudo ufw allow 993/tcp   # IMAPS
sudo ufw allow 995/tcp   # POP3S
sudo ufw allow 80/tcp    # HTTP (redirect)
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
```

**Create Mailboxes**:

Access iRedAdmin: `https://mail.company.com/iredadmin`

Or use CLI:
```bash
# Add user
sudo bash /var/vmail/bin/create_mail_user_SQL.sh user1@company.com 'password'

# Add mail alias
sudo bash /var/vmail/bin/create_mail_alias_SQL.sh alias@company.com user1@company.com
```

**Configure LDAP Authentication** (optional, for SSO):

```bash
sudo nano /etc/postfix/ldap/catchall_maps.cf
```

```
server_host = ipa1.company.internal ipa2.company.internal
server_port = 389
version = 3
bind = yes
start_tls = yes
bind_dn = uid=postfix,cn=sysaccounts,cn=etc,dc=company,dc=internal
bind_pw = <postfix-service-password>
search_base = cn=users,cn=accounts,dc=company,dc=internal
scope = sub
query_filter = (&(objectClass=person)(mail=%s))
result_attribute = mail
```

**Test Email**:

```bash
# Send test email
echo "Test email" | mail -s "Test Subject" user@external.com

# Check mail logs
sudo tail -f /var/log/mail.log
```

---

### Phase 3: Communication Services (Week 5-6)

#### 3.1 Mattermost Deployment

**Database Preparation**:

```bash
# On PostgreSQL
sudo -u postgres psql

CREATE DATABASE mattermost;
CREATE USER mattermost WITH ENCRYPTED PASSWORD '<mattermost-db-password>';
GRANT ALL PRIVILEGES ON DATABASE mattermost TO mattermost;
\q
```

**Install Mattermost** (on chat1.company.internal):

```bash
# Download latest version
cd /tmp
wget https://releases.mattermost.com/9.3.0/mattermost-9.3.0-linux-amd64.tar.gz
tar -xzf mattermost-9.3.0-linux-amd64.tar.gz

# Move to /opt
sudo mv mattermost /opt/
sudo mkdir /opt/mattermost/data

# Create system user
sudo useradd --system --user-group mattermost
sudo chown -R mattermost:mattermost /opt/mattermost
sudo chmod -R g+w /opt/mattermost
```

**Configure Mattermost**:

```bash
sudo nano /opt/mattermost/config/config.json
```

Key settings:
```json
{
  "ServiceSettings": {
    "SiteURL": "https://chat.company.com",
    "ListenAddress": ":8065",
    "EnableDeveloper": false,
    "EnableInsecureOutgoingConnections": false
  },
  "TeamSettings": {
    "SiteName": "Company Chat",
    "MaxUsersPerTeam": 500,
    "EnableTeamCreation": true,
    "EnableUserCreation": true
  },
  "SqlSettings": {
    "DriverName": "postgres",
    "DataSource": "postgres://mattermost:<password>@172.16.30.15:5000/mattermost?sslmode=disable&connect_timeout=10"
  },
  "FileSettings": {
    "Directory": "/opt/mattermost/data",
    "MaxFileSize": 104857600
  },
  "EmailSettings": {
    "EnableSignUpWithEmail": true,
    "EnableSignInWithEmail": true,
    "EnableSignInWithUsername": true,
    "SMTPServer": "mail.company.com",
    "SMTPPort": "587",
    "SMTPUsername": "noreply@company.com",
    "SMTPPassword": "<smtp-password>",
    "FeedbackEmail": "noreply@company.com",
    "ReplyToAddress": "noreply@company.com"
  },
  "LdapSettings": {
    "Enable": true,
    "LdapServer": "ipa1.company.internal",
    "LdapPort": 389,
    "BaseDN": "cn=users,cn=accounts,dc=company,dc=internal",
    "BindUsername": "uid=mattermost,cn=users,cn=accounts,dc=company,dc=internal",
    "BindPassword": "<mattermost-service-account-password>",
    "UserFilter": "(objectClass=person)",
    "EmailAttribute": "mail",
    "UsernameAttribute": "uid",
    "IdAttribute": "ipaUniqueID",
    "FirstNameAttribute": "givenName",
    "LastNameAttribute": "sn"
  },
  "SamlSettings": {
    "Enable": false
  }
}
```

**Create systemd Service**:

```bash
sudo nano /etc/systemd/system/mattermost.service
```

```ini
[Unit]
Description=Mattermost
After=network.target postgresql.service

[Service]
Type=notify
ExecStart=/opt/mattermost/bin/mattermost
TimeoutStartSec=3600
KillMode=mixed
Restart=always
RestartSec=10
WorkingDirectory=/opt/mattermost
User=mattermost
Group=mattermost
LimitNOFILE=49152

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable mattermost
sudo systemctl start mattermost
sudo systemctl status mattermost
```

**Configure Nginx Reverse Proxy** (local):

```bash
sudo nano /etc/nginx/sites-available/mattermost
```

```nginx
upstream mattermost_backend {
    server 127.0.0.1:8065;
    keepalive 32;
}

server {
    listen 80;
    server_name chat.company.com chat.company.internal;

    location ~ /api/v[0-9]+/(users/)?websocket$ {
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        client_max_body_size 50M;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_buffers 256 16k;
        proxy_buffer_size 16k;
        client_body_timeout 60;
        send_timeout 300;
        lingering_timeout 5;
        proxy_connect_timeout 90;
        proxy_send_timeout 300;
        proxy_read_timeout 90s;
        proxy_http_version 1.1;
        proxy_pass http://mattermost_backend;
    }

    location / {
        client_max_body_size 50M;
        proxy_set_header Connection "";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_buffers 256 16k;
        proxy_buffer_size 16k;
        proxy_read_timeout 600s;
        proxy_http_version 1.1;
        proxy_pass http://mattermost_backend;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/mattermost /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**Initial Setup**:

1. Access `https://chat.company.com`
2. Create system admin account
3. Configure team settings
4. Invite users or enable LDAP login

#### 3.2 Jitsi Meet Deployment

**Installation** (on meet1.company.internal):

```bash
# Add Jitsi repository
curl -sL https://download.jitsi.org/jitsi-key.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/jitsi-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list

# Update and install
sudo apt update
sudo apt install -y jitsi-meet

# During installation:
# Hostname: meet.company.com
# SSL: Generate self-signed (we'll use Traefik for SSL termination)
```

**Configure Jitsi**:

```bash
# Main configuration
sudo nano /etc/jitsi/meet/meet.company.com-config.js
```

```javascript
var config = {
    hosts: {
        domain: 'meet.company.com',
        muc: 'conference.meet.company.com'
    },
    bosh: '//meet.company.com/http-bind',
    websocket: 'wss://meet.company.com/xmpp-websocket',

    // Branding
    brandingDataUrl: '',
    defaultLogoUrl: 'images/logo.svg',

    // Feature flags
    enableWelcomePage: true,
    enableClosePage: false,
    disableThirdPartyRequests: true,

    // Authentication
    enableUserRolesBasedOnToken: false,

    // Recording
    fileRecordingsEnabled: true,
    liveStreamingEnabled: false,

    // P2P (disable for larger deployments)
    p2p: {
        enabled: false
    },

    // Resolution and quality
    resolution: 720,
    constraints: {
        video: {
            height: {
                ideal: 720,
                max: 1080,
                min: 240
            }
        }
    },

    // Other settings
    defaultLanguage: 'en',
    disableAudioLevels: false,
    enableNoisyMicDetection: true,
    startAudioOnly: false,
    startWithAudioMuted: false,
    startWithVideoMuted: false
};
```

**Configure Videobridge**:

```bash
sudo nano /etc/jitsi/videobridge/sip-communicator.properties
```

```properties
org.ice4j.ice.harvest.NAT_HARVESTER_LOCAL_ADDRESS=172.16.20.40
org.ice4j.ice.harvest.NAT_HARVESTER_PUBLIC_ADDRESS=<Public-IP>
org.jitsi.videobridge.ENABLE_STATISTICS=true
org.jitsi.videobridge.STATISTICS_TRANSPORT=muc
org.jitsi.videobridge.xmpp.user.shard.HOSTNAME=localhost
org.jitsi.videobridge.xmpp.user.shard.DOMAIN=auth.meet.company.com
org.jitsi.videobridge.xmpp.user.shard.USERNAME=jvb
org.jitsi.videobridge.xmpp.user.shard.PASSWORD=<jvb-password>
org.jitsi.videobridge.xmpp.user.shard.MUC_JIDS=JvbBrewery@internal.auth.meet.company.com
org.jitsi.videobridge.xmpp.user.shard.MUC_NICKNAME=<unique-nickname>
```

**Configure Jicofo**:

```bash
sudo nano /etc/jitsi/jicofo/sip-communicator.properties
```

```properties
org.jitsi.jicofo.BRIDGE_MUC=JvbBrewery@internal.auth.meet.company.com
```

**Firewall Rules**:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10000/udp  # Video/audio
sudo ufw allow 5347/tcp   # XMPP component
sudo ufw enable
```

**Restart Services**:

```bash
sudo systemctl restart prosody
sudo systemctl restart jicofo
sudo systemctl restart jitsi-videobridge2
```

**Enable Authentication** (optional, recommended):

```bash
# Configure Prosody for internal authentication
sudo nano /etc/prosody/conf.avail/meet.company.com.cfg.lua
```

Change:
```lua
VirtualHost "meet.company.com"
    authentication = "internal_hashed"  # Change from 'anonymous'
```

Add:
```lua
VirtualHost "guest.meet.company.com"
    authentication = "anonymous"
    c2s_require_encryption = false
```

Update:
```lua
Component "conference.meet.company.com" "muc"
    restrict_room_creation = true
    storage = "memory"
    modules_enabled = {
        "muc_meeting_id";
        "muc_domain_mapper";
        "polls";
    }
    admins = { "focus@auth.meet.company.com" }
    muc_room_locking = false
    muc_room_default_public_jids = true
```

```bash
# Restart Prosody
sudo systemctl restart prosody

# Create users
sudo prosodyctl register <username> meet.company.com <password>
```

#### 3.3 Jitsi-Nextcloud Integration

```bash
# On Nextcloud server
sudo -u www-data php occ app:install integration_jitsi

# Configure
sudo -u www-data php occ config:app:set integration_jitsi jitsi_url --value="https://meet.company.com"
sudo -u www-data php occ config:app:set integration_jitsi room_name_format --value="{user}-{timestamp}"
```

Users can now start Jitsi meetings from Nextcloud Talk.

---

### Phase 4: Support & Administration (Week 7-8)

#### 4.1 Zammad Help Desk

**Database Setup**:

```bash
# On PostgreSQL
sudo -u postgres psql

CREATE DATABASE zammad_production;
CREATE USER zammad WITH ENCRYPTED PASSWORD '<zammad-db-password>';
GRANT ALL PRIVILEGES ON DATABASE zammad_production TO zammad;
\q
```

**Install Elasticsearch** (on log1 or separate server):

```bash
# Import GPG key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Install
sudo apt update
sudo apt install -y elasticsearch

# Configure
sudo nano /etc/elasticsearch/elasticsearch.yml
```

```yaml
cluster.name: zammad
node.name: es1
network.host: 172.16.20.71
http.port: 9200
discovery.type: single-node
xpack.security.enabled: false
```

```bash
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# Test
curl http://172.16.20.71:9200
```

**Install Zammad** (on desk1.company.internal):

```bash
# Add Zammad repository
curl -fsSL https://dl.packager.io/srv/zammad/zammad/key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/pkgr-zammad.gpg> /dev/null
echo "deb [signed-by=/etc/apt/trusted.gpg.d/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/ubuntu 24.04 main"| sudo tee /etc/apt/sources.list.d/zammad.list > /dev/null

# Update and install
sudo apt update
sudo apt install -y zammad

# Configure database connection
sudo zammad config:set DATABASE_URL="postgresql://zammad:<password>@172.16.30.15:5000/zammad_production"

# Configure Elasticsearch
sudo zammad config:set ELASTICSEARCH_URL="http://172.16.20.71:9200"

# Run database migration
sudo zammad run rails db:migrate

# Build search index
sudo zammad run rake searchindex:rebuild

# Restart services
sudo systemctl restart zammad
sudo systemctl restart zammad-web
sudo systemctl restart zammad-worker
```

**Configure Nginx**:

```bash
# Nginx configuration should be created automatically
sudo nginx -t
sudo systemctl reload nginx
```

**Initial Setup**:

1. Access `https://desk.company.com`
2. Set up admin account
3. Configure organization details
4. Set up email integration (IMAP/SMTP from mail server)

**Email Integration**:

- IMAP:
  - Host: `mail.company.com`
  - Port: 993 (SSL)
  - User: `support@company.com`
  - Password: (mailbox password)

- SMTP:
  - Host: `mail.company.com`
  - Port: 587 (STARTTLS)
  - User: `support@company.com`
  - Password: (mailbox password)

**LDAP/SSO Integration**:

Settings → Security → Third-party Applications → LDAP

```yaml
Name: FreeIPA
Host: ipa1.company.internal
Port: 389
SSL: STARTTLS
Bind DN: uid=zammad,cn=users,cn=accounts,dc=company,dc=internal
Bind Password: <zammad-service-account-password>
Base DN: cn=users,cn=accounts,dc=company,dc=internal
User Filter: (objectClass=person)
UID Attribute: uid
```

---

## Integration Configuration

### Single Sign-On (SSO) Flow

**Architecture**:
```
User → Traefik → Application → Keycloak → FreeIPA
```

All applications authenticate through Keycloak, which federates to FreeIPA LDAP.

**Keycloak Client Configuration** (for each app):

1. **Nextcloud**:
   - Client ID: `nextcloud`
   - Client Protocol: `openid-connect`
   - Access Type: `confidential`
   - Valid Redirect URIs: `https://cloud.company.com/*`
   - Base URL: `https://cloud.company.com`

   Install OIDC plugin in Nextcloud:
   ```bash
   sudo -u www-data php occ app:install user_oidc
   sudo -u www-data php occ user_oidc:provider Keycloak \
     --clientid=nextcloud \
     --clientsecret=<client-secret> \
     --discoveryuri=https://sso.company.com/realms/company/.well-known/openid-configuration
   ```

2. **Mattermost**:
   In Mattermost config.json:
   ```json
   "GitLabSettings": {
     "Enable": true,
     "Id": "mattermost",
     "Secret": "<client-secret>",
     "Scope": "openid profile email",
     "AuthEndpoint": "https://sso.company.com/realms/company/protocol/openid-connect/auth",
     "TokenEndpoint": "https://sso.company.com/realms/company/protocol/openid-connect/token",
     "UserApiEndpoint": "https://sso.company.com/realms/company/protocol/openid-connect/userinfo"
   }
   ```

3. **Zammad**:
   Configure via web UI → Settings → Security → Third Party → OAuth2

### Cross-Application Features

**Nextcloud Files in Mattermost**:

Mattermost → Integrations → Marketplace → Install "Nextcloud"

Configuration:
```
Nextcloud URL: https://cloud.company.com
Username: Integration account
Password/Token: (create app password in Nextcloud)
```

**Jitsi in Nextcloud Talk**:

Already configured in section 3.3

**Calendar Sync Across Platforms**:

All platforms support CalDAV:
- URL: `https://cloud.company.com/remote.php/dav/`
- Username: User's email
- Password: User's password (or app-specific password)

### Automation and Webhooks

**Example: New User Provisioning**

Create script `/usr/local/bin/provision-user.sh`:

```bash
#!/bin/bash
# Provisions new user across all platforms

USERNAME=$1
EMAIL=$2
FIRST_NAME=$3
LAST_NAME=$4
PASSWORD=$5
GROUPS=$6

# FreeIPA
ipa user-add $USERNAME \
  --first="$FIRST_NAME" \
  --last="$LAST_NAME" \
  --email="$EMAIL" \
  --password <<< "$PASSWORD"

# Add to groups
for group in $GROUPS; do
  ipa group-add-member $group --users=$USERNAME
done

# Create email account (iRedMail)
bash /var/vmail/bin/create_mail_user_SQL.sh "$EMAIL" "$PASSWORD"

# Nextcloud (auto-provisioned via LDAP)

# Mattermost (auto-provisioned via LDAP on first login)

# Send welcome email
mail -s "Welcome to Company IT" "$EMAIL" <<EOF
Hello $FIRST_NAME,

Your account has been created:

Email: $EMAIL
Chat: https://chat.company.com
Files: https://cloud.company.com
Help Desk: https://desk.company.com

Please log in and change your password.

Regards,
IT Team
EOF

echo "User $USERNAME provisioned successfully"
```

```bash
sudo chmod +x /usr/local/bin/provision-user.sh
```

---

## Security Hardening

### System-Level Security

#### 1. SSH Hardening

**On all servers**:

```bash
sudo nano /etc/ssh/sshd_config
```

```
# Disable root login
PermitRootLogin no

# Disable password authentication (use keys only)
PasswordAuthentication no
PubkeyAuthentication yes

# Only allow specific users/groups
AllowUsers admin
AllowGroups ssh-users

# Strong ciphers only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# Other settings
X11Forwarding no
MaxAuthTries 3
MaxSessions 2
ClientAliveInterval 300
ClientAliveCountMax 2
```

```bash
sudo systemctl restart sshd
```

#### 2. Firewall Configuration (UFW)

**Default deny policy**:

```bash
# Set defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH from management VLAN only
sudo ufw allow from 172.16.10.0/24 to any port 22

# Allow specific services (example for web server)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable logging
sudo ufw logging on

# Enable firewall
sudo ufw enable
```

#### 3. Fail2ban

**Install and configure**:

```bash
sudo apt install -y fail2ban

sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = security@company.com
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log

[nginx-badbots]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log

[postfix]
enabled = true
port = smtp,ssmtp,submission
logpath = /var/log/mail.log

[dovecot]
enabled = true
port = pop3,pop3s,imap,imaps,submission
logpath = /var/log/mail.log
```

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

#### 4. Automatic Security Updates

```bash
sudo apt install -y unattended-upgrades apt-listchanges

sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
```

```
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";

Unattended-Upgrade::Mail "sysadmin@company.com";
Unattended-Upgrade::MailReport "on-change";
```

```bash
sudo dpkg-reconfigure -plow unattended-upgrades
```

#### 5. Auditd (System Auditing)

```bash
sudo apt install -y auditd audispd-plugins

sudo nano /etc/audit/rules.d/audit.rules
```

```
# Delete all existing rules
-D

# Buffer size
-b 8192

# Failure mode (1 = print failure message, 2 = panic)
-f 1

# Monitor file changes
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k actions
-w /etc/ssh/sshd_config -p wa -k sshd

# Monitor authentication
-w /var/log/auth.log -p wa -k auth
-w /var/log/faillog -p wa -k auth

# Monitor network changes
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network_modifications
-w /etc/hosts -p wa -k network_modifications
-w /etc/network/ -p wa -k network_modifications

# Monitor user/group changes
-w /usr/sbin/useradd -p x -k user_modification
-w /usr/sbin/userdel -p x -k user_modification
-w /usr/sbin/usermod -p x -k user_modification
-w /usr/sbin/groupadd -p x -k group_modification
-w /usr/sbin/groupdel -p x -k group_modification

# Monitor privilege escalation
-a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -k priv_esc
-w /usr/bin/sudo -p x -k priv_esc
```

```bash
sudo systemctl restart auditd
```

### Application Security

#### SSL/TLS Best Practices

**Nginx SSL Configuration**:

```nginx
# Strong SSL configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;

# HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# Other security headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;
```

#### Database Security

**PostgreSQL Hardening**:

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

```
# TYPE  DATABASE    USER        ADDRESS           METHOD
local   all         postgres                      peer
local   all         all                           peer
host    all         all         127.0.0.1/32      scram-sha-256
host    all         all         ::1/128           scram-sha-256
host    replication replicator  172.16.30.0/24    scram-sha-256
host    all         all         172.16.20.0/24    scram-sha-256  # App servers only
```

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

```
listen_addresses = '172.16.30.10'  # Specific IP only
ssl = on
ssl_cert_file = '/etc/ssl/certs/pg-server.crt'
ssl_key_file = '/etc/ssl/private/pg-server.key'

# Logging
log_connections = on
log_disconnections = on
log_duration = on
log_line_prefix = '%t [%p]: user=%u,db=%d,app=%a,client=%h '
log_statement = 'ddl'  # Log all DDL statements

# Security
password_encryption = scram-sha-256
```

#### Rate Limiting

**Traefik Rate Limiting** (already configured in backends.yml):

```yaml
http:
  middlewares:
    rate-limit:
      rateLimit:
        average: 100  # requests per period
        burst: 50     # max burst
        period: 1m    # time window
```

**Nginx Rate Limiting**:

```nginx
# Define rate limit zone
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

# Apply to locations
location / {
    limit_req zone=general burst=20 nodelay;
}

location /login {
    limit_req zone=login burst=5 nodelay;
}
```

### Network Security

#### VPN Access for Remote Sites

**WireGuard VPN Setup** (on edge firewall):

```bash
# Install WireGuard
sudo apt install -y wireguard

# Generate server keys
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey

# Create configuration
sudo nano /etc/wireguard/wg0.conf
```

```ini
[Interface]
PrivateKey = <server-private-key>
Address = 10.10.10.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Remote site 1
[Peer]
PublicKey = <site1-public-key>
AllowedIPs = 10.10.10.2/32, 172.16.100.0/24
PersistentKeepalive = 25

# Remote site 2
[Peer]
PublicKey = <site2-public-key>
AllowedIPs = 10.10.10.3/32, 172.16.101.0/24
PersistentKeepalive = 25

# Mobile guard 1
[Peer]
PublicKey = <guard1-public-key>
AllowedIPs = 10.10.10.10/32
```

```bash
# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Start WireGuard
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Check status
sudo wg show
```

**Client Configuration** (guards/remote sites):

```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.10.10.10/32
DNS = 172.16.20.5

[Peer]
PublicKey = <server-public-key>
Endpoint = vpn.company.com:51820
AllowedIPs = 172.16.0.0/16, 10.10.10.0/24
PersistentKeepalive = 25
```

#### IDS/IPS (Suricata)

**Install on edge firewall**:

```bash
sudo apt install -y suricata

sudo nano /etc/suricata/suricata.yaml
```

```yaml
vars:
  address-groups:
    HOME_NET: "[172.16.0.0/16,10.10.10.0/24]"
    EXTERNAL_NET: "!$HOME_NET"

af-packet:
  - interface: eth0
    threads: auto
    cluster-id: 99
    cluster-type: cluster_flow
    defrag: yes

outputs:
  - fast:
      enabled: yes
      filename: fast.log
  - eve-log:
      enabled: yes
      filetype: regular
      filename: eve.json
      types:
        - alert
        - http
        - dns
        - tls
        - files
        - smtp

rule-files:
  - suricata.rules
  - /var/lib/suricata/rules/emerging-threats.rules
```

```bash
# Update rules
sudo suricata-update

# Enable and start
sudo systemctl enable suricata
sudo systemctl start suricata
```

---

## Backup and Disaster Recovery

### Backup Strategy

#### 3-2-1 Rule
- **3** copies of data
- **2** different media types
- **1** offsite backup

### Backup Schedule

| Data Type | Frequency | Retention | Method |
|-----------|-----------|-----------|--------|
| Databases | Every 6 hours | 30 days | Borg + PostgreSQL dumps |
| Files (Nextcloud) | Daily | 90 days | Borg |
| Email | Daily | 365 days | Borg |
| VMs | Weekly (full), Daily (incremental) | 4 weekly, 3 monthly | Proxmox Backup Server |
| Configuration | On change | Indefinite | Git repository |
| Logs | Daily | 180 days | Graylog archive |

### Borg Backup Implementation

**Install Borg on all application servers**:

```bash
sudo apt install -y borgbackup
```

**Configure Backup Server** (backup1.company.internal):

```bash
# Create backup user
sudo useradd -r -m -d /backup -s /bin/bash backup

# Create SSH key for each server
sudo -u backup ssh-keygen -t ed25519 -f /backup/.ssh/id_ed25519_cloud1 -N ""
# Repeat for each server

# Install public keys on source servers
# On cloud1:
sudo mkdir -p /root/.ssh
echo "<public-key>" | sudo tee -a /root/.ssh/authorized_keys
```

**Create Backup Script** (on cloud1.company.internal):

```bash
sudo nano /usr/local/bin/backup-nextcloud.sh
```

```bash
#!/bin/bash
set -e

# Configuration
BACKUP_USER="backup"
BACKUP_HOST="backup1.company.internal"
BACKUP_REPO="ssh://${BACKUP_USER}@${BACKUP_HOST}/backup/repos/cloud1"
BACKUP_NAME="nextcloud"
DATE=$(date +%Y-%m-%d-%H%M)

# Borg passphrase
export BORG_PASSPHRASE='<strong-passphrase>'

# Paths to backup
NEXTCLOUD_DATA="/var/www/nextcloud"
NEXTCLOUD_CONFIG="/var/www/nextcloud/config"

# Pre-backup: Enable maintenance mode
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on

# Database dump
sudo -u postgres pg_dump nextcloud | gzip > /tmp/nextcloud_db_${DATE}.sql.gz

# Create backup
borg create \
  --verbose --stats \
  --compression lz4 \
  --exclude-caches \
  ${BACKUP_REPO}::${BACKUP_NAME}-${DATE} \
  ${NEXTCLOUD_DATA} \
  ${NEXTCLOUD_CONFIG} \
  /tmp/nextcloud_db_${DATE}.sql.gz

# Disable maintenance mode
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off

# Cleanup temp files
rm /tmp/nextcloud_db_${DATE}.sql.gz

# Prune old backups (keep last 30 daily, 12 monthly)
borg prune \
  --verbose --stats \
  --keep-daily=30 \
  --keep-monthly=12 \
  ${BACKUP_REPO}

# Compact repo
borg compact ${BACKUP_REPO}

# Send notification
echo "Nextcloud backup completed successfully at $(date)" | \
  mail -s "Backup Success: Nextcloud" sysadmin@company.com

unset BORG_PASSPHRASE
```

```bash
sudo chmod +x /usr/local/bin/backup-nextcloud.sh
```

**Create Cron Job**:

```bash
sudo crontab -e
```

```
# Nextcloud backup - every 6 hours
0 */6 * * * /usr/local/bin/backup-nextcloud.sh >> /var/log/backup-nextcloud.log 2>&1
```

**Similar scripts for**:
- Mattermost
- PostgreSQL databases
- Mail server
- Keycloak
- Zammad

### Disaster Recovery Procedures

#### Full System Restoration

**Scenario: Complete infrastructure loss**

**Phase 1: Infrastructure Rebuild (Day 1)**

1. **Restore Hypervisor**:
   - Reinstall Proxmox VE on hardware
   - Configure network
   - Restore VM configurations from PBS

2. **Restore Core Services**:
   - FreeIPA (from Borg backup)
   - PostgreSQL (from dumps + Borg)
   - DNS services

**Phase 2: Application Restoration (Day 2-3)**

3. **Restore Applications** (order matters):
   ```bash
   # Example: Restore Nextcloud
   borg extract backup@backup1:/backup/repos/cloud1::nextcloud-latest
   
   # Restore database
   gunzip -c nextcloud_db_*.sql.gz | sudo -u postgres psql nextcloud
   
   # Fix permissions
   sudo chown -R www-data:www-data /var/www/nextcloud
   
   # Disable maintenance mode
   sudo -u www-data php occ maintenance:mode --off
   ```

4. Verify services one by one
5. Test SSO and integrations
6. Resume normal operations

**Recovery Time Objective (RTO)**: 24-72 hours  
**Recovery Point Objective (RPO)**: 6 hours (databases), 24 hours (files)

#### Database Point-in-Time Recovery

**PostgreSQL PITR**:

```bash
# Restore base backup
borg extract backup@backup1:/backup/repos/db1::postgres-latest

# Restore WAL archives
borg extract backup@backup1:/backup/repos/db1::wal-archive-latest

# Configure recovery
cat > /var/lib/postgresql/16/main/recovery.signal <<EOF
restore_command = 'cp /backup/wal_archive/%f %p'
recovery_target_time = '2026-02-04 14:30:00'
EOF

# Start PostgreSQL (will replay WAL logs)
sudo systemctl start postgresql
```

---

## Monitoring and Logging

### Zabbix Configuration

**Server Installation** (monitor1.company.internal):

```bash
# Install Zabbix repository
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_7.0-1+ubuntu24.04_all.deb
sudo apt update

# Install Zabbix server, frontend, agent
sudo apt install -y zabbix-server-pgsql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent

# Create database
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix

# Import schema
zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix

# Configure Zabbix server
sudo nano /etc/zabbix/zabbix_server.conf
```

```
DBHost=172.16.30.15
DBName=zabbix
DBUser=zabbix
DBPassword=<zabbix-db-password>
DBPort=5000
```

```bash
# Configure PHP for Zabbix
sudo nano /etc/zabbix/nginx.conf
```

```nginx
listen 80;
server_name monitor.company.com;
```

```bash
# Start services
sudo systemctl restart zabbix-server zabbix-agent nginx php8.3-fpm
sudo systemctl enable zabbix-server zabbix-agent nginx php8.3-fpm
```

**Web Interface Setup**:
1. Navigate to `http://monitor.company.com`
2. Complete wizard
3. Login: Admin / zabbix

**Install Agents on All Servers**:

```bash
sudo apt install -y zabbix-agent

sudo nano /etc/zabbix/zabbix_agentd.conf
```

```
Server=172.16.20.70
ServerActive=172.16.20.70
Hostname=<server-hostname>
```

```bash
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent
```

**Key Monitoring Templates**:
- Template OS Linux
- Template App PostgreSQL
- Template App Nginx
- Template App Redis
- Custom templates for Nextcloud, Mattermost, etc.

**Critical Alerts** (configure in Zabbix):
- CPU > 80% for 5 minutes
- Memory > 90%
- Disk space < 10%
- Service down
- Database connection failures
- SSL certificate expiry < 30 days
- Backup failures

### Centralized Logging with Graylog

**Installation** (log1.company.internal):

```bash
# Install Java
sudo apt install -y openjdk-17-jre

# Install MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod

# Install Elasticsearch (already installed for Zammad, can share)

# Install Graylog
wget https://packages.graylog2.org/repo/packages/graylog-5.2-repository_latest.deb
sudo dpkg -i graylog-5.2-repository_latest.deb
sudo apt update
sudo apt install -y graylog-server

# Generate password secret
echo -n "Enter Password: " && head -1 </dev/stdin | tr -d '\n' | sha256sum | cut -d" " -f1

# Configure Graylog
sudo nano /etc/graylog/server/server.conf
```

```
password_secret = <generated-secret>
root_password_sha2 = <sha256-of-admin-password>
root_timezone = America/Toronto

http_bind_address = 172.16.20.71:9000
elasticsearch_hosts = http://127.0.0.1:9200
mongodb_uri = mongodb://localhost/graylog
```

```bash
sudo systemctl enable --now graylog-server
```

**Configure Rsyslog on Servers to Forward Logs**:

```bash
sudo nano /etc/rsyslog.d/90-graylog.conf
```

```
*.* @@172.16.20.71:1514;RSYSLOG_SyslogProtocol23Format
```

```bash
sudo systemctl restart rsyslog
```

**Graylog Input Configuration**:
1. Navigate to `http://log1.company.internal:9000`
2. System → Inputs → Select "Syslog TCP" → Launch
3. Port: 1514
4. Bind address: 0.0.0.0

**Create Dashboards** for:
- Failed login attempts
- HTTP status codes
- Database errors
- Application errors
- Security events

---

## User Management and Access Control

### Role-Based Access Control (RBAC)

**FreeIPA Groups**:

```bash
kinit admin

# Create organizational groups
ipa group-add --desc="C-Level Executives" executives
ipa group-add --desc="Department Managers" managers
ipa group-add --desc="Back Office Staff" office-staff
ipa group-add --desc="Field Guards" guards
ipa group-add --desc="IT Department" it-dept
ipa group-add --desc="HR Department" hr-dept

# Create privilege groups
ipa group-add --desc="System Administrators" sysadmins
ipa group-add --desc="Nextcloud Admins" nextcloud-admins
ipa group-add --desc="Mail Admins" mail-admins
ipa group-add --desc="Help Desk Agents" helpdesk-agents

# Nested groups
ipa group-add-member sysadmins --groups=it-dept
ipa group-add-member nextcloud-admins --groups=it-dept
```

**Application-Level Permissions**:

**Nextcloud**:
- Admins: Full access
- Managers: Can create groups, assign permissions
- Users: Own files + shared folders

**Mattermost**:
- System Admin: Full control
- Team Admin: Manage team channels
- Users: Join channels, DM

**Zammad**:
- Admin: Full access
- Agent: Manage tickets in assigned groups
- Customer: Submit and view own tickets

### User Onboarding Workflow

**Automated Process**:

1. HR submits request via Zammad
2. IT creates user in FreeIPA (runs provision script)
3. User receives welcome email with credentials
4. User logs into SSO (Keycloak)
5. Access to all integrated apps automatically
6. Assign to appropriate groups/teams

**Provision Script** (enhanced version from integration section):

```bash
#!/bin/bash
# /usr/local/bin/provision-user.sh

set -e

# Input validation
if [ $# -lt 5 ]; then
    echo "Usage: $0 <username> <email> <first_name> <last_name> <password> [groups]"
    exit 1
fi

USERNAME=$1
EMAIL=$2
FIRST_NAME=$3
LAST_NAME=$4
PASSWORD=$5
GROUPS=${6:-"office-staff"}  # Default group

# Kerberos auth
kinit admin

# Create FreeIPA user
echo "Creating FreeIPA user..."
ipa user-add $USERNAME \
    --first="$FIRST_NAME" \
    --last="$LAST_NAME" \
    --email="$EMAIL" \
    --password <<< "$PASSWORD"

# Add to groups
echo "Adding to groups: $GROUPS"
for group in $GROUPS; do
    ipa group-add-member $group --users=$USERNAME
done

# Create email account
echo "Creating email account..."
ssh mail1 "bash /var/vmail/bin/create_mail_user_SQL.sh '$EMAIL' '$PASSWORD'"

# Create initial Nextcloud folder structure
echo "Preparing Nextcloud workspace..."
# (Will be created on first login via LDAP)

# Send welcome email
echo "Sending welcome email..."
cat <<EOF | mail -s "Welcome to Company Security Services" "$EMAIL"
Hello $FIRST_NAME,

Your account has been successfully created. Here are your login details:

Username: $USERNAME
Email: $EMAIL
Temporary Password: $PASSWORD

**IMPORTANT: Please change your password immediately after first login.**

Access our services:
- Email: https://mail.company.com
- Webmail: https://mail.company.com/mail
- Files & Collaboration: https://cloud.company.com
- Team Chat: https://chat.company.com
- Video Meetings: https://meet.company.com
- Help Desk: https://desk.company.com

Single Sign-On: Use your email and password to access all services.

If you need assistance, contact IT support at helpdesk@company.com or submit a ticket at https://desk.company.com

Best regards,
IT Department
Company Security Services
EOF

# Log action
logger -t user-provision "User $USERNAME ($EMAIL) created and added to groups: $GROUPS"

echo "✓ User $USERNAME provisioned successfully!"
echo "  Email: $EMAIL"
echo "  Groups: $GROUPS"
```

```bash
sudo chmod +x /usr/local/bin/provision-user.sh

# Usage example
sudo /usr/local/bin/provision-user.sh jdoe john.doe@company.com John Doe 'TempPass123!' "guards"
```

### User Offboarding Workflow

```bash
#!/bin/bash
# /usr/local/bin/deprovision-user.sh

set -e

USERNAME=$1

if [ -z "$USERNAME" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

kinit admin

# Disable FreeIPA user
echo "Disabling FreeIPA user..."
ipa user-disable $USERNAME

# Get user email
EMAIL=$(ipa user-show $USERNAME --all --raw | grep "mail:" | awk '{print $2}')

# Disable email account
echo "Disabling email account..."
ssh mail1 "mysql -e \"UPDATE mailbox SET active=0 WHERE username='$EMAIL';\" vmail"

# Archive Nextcloud data
echo "Archiving Nextcloud data..."
ssh cloud1 "sudo -u www-data php occ user:disable $USERNAME"

# Remove from Mattermost active users
echo "Deactivating Mattermost account..."
ssh chat1 "cd /opt/mattermost && sudo -u mattermost ./bin/mattermost user deactivate $EMAIL"

# Log action
logger -t user-deprovision "User $USERNAME ($EMAIL) deprovisioned"

echo "✓ User $USERNAME deprovisioned successfully!"
echo "  FreeIPA: Disabled"
echo "  Email: Disabled"
echo "  Nextcloud: Disabled"
echo "  Mattermost: Deactivated"
echo ""
echo "To permanently delete user data, run: /usr/local/bin/purge-user.sh $USERNAME"
```

---

## Mobile and Remote Access

### Mobile Device Management (MDM)

While not open-source, consider integrating with:
- **MicroMDM** (basic iOS MDM)
- **Device policies via FreeIPA**

For BYOD, ensure:
- VPN access (WireGuard)
- Mobile app availability
- Remote wipe capability (Nextcloud)

### Mobile Apps

| Service | iOS App | Android App | Features |
|---------|---------|-------------|----------|
| Email | Native Mail app | Native Gmail/Outlook | IMAP/SMTP sync |
| Files | Nextcloud | Nextcloud | Auto-upload, offline files |
| Calendar | Native Calendar | Nextcloud/DAVx⁵ | CalDAV sync |
| Chat | Mattermost | Mattermost | Push notifications |
| Video | Jitsi Meet | Jitsi Meet | Join meetings |

### Field Guard Configuration

**Optimized Settings for Mobile Users**:

**Nextcloud**:
- Enable instant upload for incident photos
- Create "Daily Reports" folder template
- Offline sync for schedules and documents

**Mattermost**:
- Create channels per site/shift
- Enable push notifications for @mentions
- Pin important announcements

**Calendar**:
- Color-code shifts by site
- Set reminders 30 minutes before shift
- Allow mobile schedule changes (approval workflow)

### Remote Site Connectivity

**Site-to-Site VPN** (WireGuard):

**Central Office** (already configured in security section)

**Remote Site Configuration**:

```ini
# /etc/wireguard/wg0.conf on remote site router
[Interface]
PrivateKey = <site-private-key>
Address = 10.10.10.2/24, 172.16.100.1/24  # VPN IP + Local subnet
ListenPort = 51820

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <central-office-public-key>
Endpoint = vpn.company.com:51820
AllowedIPs = 172.16.0.0/16, 10.10.10.0/24
PersistentKeepalive = 25
```

**Routing**:
Remote site devices (172.16.100.0/24) can access all central services seamlessly.

---

## Maintenance Procedures

### Regular Maintenance Tasks

#### Daily
- Check backup logs
- Review Zabbix alerts
- Monitor disk space
- Check service availability

#### Weekly
- Review system logs (Graylog)
- Update system packages (test environment first)
- Verify backup integrity (random restore test)
- Review user access logs

#### Monthly
- Full system updates (production)
- Review and rotate logs
- Capacity planning review
- Security patch assessment
- Test disaster recovery procedures
- Update documentation

#### Quarterly
- Penetration testing
- Vulnerability scanning (OpenVAS/Nessus)
- Compliance audit
- Performance tuning
- Review and update firewall rules
- Update SSL certificates (if not automated)

### Update Procedures

**System Updates** (Ubuntu):

```bash
# Test environment first
sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y
sudo apt autoremove -y
sudo reboot  # If kernel updated

# After testing, apply to production
```

**Application Updates**:

**Nextcloud**:
```bash
# Enable maintenance mode
sudo -u www-data php occ maintenance:mode --on

# Backup
sudo -u www-data php occ maintenance:repair

# Update via updater
sudo -u www-data php updater/updater.phar

# Or manual update
cd /var/www
sudo -u www-data php nextcloud/occ upgrade

# Disable maintenance mode
sudo -u www-data php occ maintenance:mode --off
```

**Mattermost**:
```bash
sudo systemctl stop mattermost
cd /opt
sudo wget https://releases.mattermost.com/<version>/mattermost-<version>-linux-amd64.tar.gz
sudo tar -xzf mattermost-<version>-linux-amd64.tar.gz --strip-components=1 -C mattermost/
sudo chown -R mattermost:mattermost /opt/mattermost
sudo systemctl start mattermost
```

**PostgreSQL Minor Updates**:
```bash
sudo apt update
sudo apt upgrade postgresql-16
sudo systemctl restart postgresql
```

**PostgreSQL Major Upgrades**:
Use `pg_upgrade` or logical replication (detailed procedure in PostgreSQL docs)

### Maintenance Windows

**Scheduled Maintenance**: 
- **Primary Window**: Sunday 02:00-06:00 AM
- **Emergency Window**: Any time (with notifications)

**Pre-Maintenance Checklist**:
1. ✅ Notify users 48 hours in advance
2. ✅ Take full backup
3. ✅ Test rollback procedure
4. ✅ Document changes
5. ✅ Prepare rollback plan
6. ✅ Alert on-call staff

**Post-Maintenance Checklist**:
1. ✅ Verify all services running
2. ✅ Test SSO flow
3. ✅ Check monitoring dashboards
4. ✅ Review logs for errors
5. ✅ Notify users of completion
6. ✅ Update documentation

---

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. "Cannot Connect to Service"

**Symptoms**: Users unable to access web applications

**Diagnosis**:
```bash
# Check service status
sudo systemctl status <service>

# Check listening ports
sudo netstat -tlnp | grep <port>

# Check firewall
sudo ufw status

# Check reverse proxy logs
sudo docker logs traefik
# or
sudo tail -f /var/log/nginx/error.log

# Test from application server
curl -I http://localhost:<port>
```

**Solutions**:
- Restart service: `sudo systemctl restart <service>`
- Check SSL certificate: `sudo certbot certificates`
- Verify DNS: `nslookup <domain>`
- Check Traefik routing: Review `/opt/traefik/config/backends.yml`

#### 2. "Login Failed" / SSO Issues

**Symptoms**: Users cannot authenticate

**Diagnosis**:
```bash
# Check Keycloak
sudo systemctl status keycloak
sudo journalctl -u keycloak -f

# Check FreeIPA
sudo systemctl status ipa
kinit admin
ipa user-show <username>

# Check LDAP connection
ldapsearch -x -H ldap://ipa1.company.internal \
  -D "uid=<service-account>,cn=users,cn=accounts,dc=company,dc=internal" \
  -W -b "cn=users,cn=accounts,dc=company,dc=internal" "(uid=<username>)"

# Application-specific
# Nextcloud:
sudo -u www-data php occ ldap:test-config s01
# Mattermost:
Check System Console → Authentication → LDAP
```

**Solutions**:
- Verify user exists in FreeIPA
- Check service account credentials
- Verify LDAP connection settings
- Check firewall between app and LDAP server
- Clear browser cache / try incognito mode

#### 3. "Out of Disk Space"

**Symptoms**: Services failing, slow performance

**Diagnosis**:
```bash
df -h
du -sh /var/www/nextcloud/data/*
du -sh /var/log/*
du -sh /opt/mattermost/data/*

# Find large files
find / -type f -size +1G -exec ls -lh {} \;

# Check Docker volumes
sudo docker system df
```

**Solutions**:
- Clean up old logs: `sudo journalctl --vacuum-time=30d`
- Remove old backups
- Expand storage volume
- Enable Nextcloud file versioning limits
- Clean Docker: `sudo docker system prune -a`

#### 4. Database Connection Errors

**Symptoms**: Applications showing database errors

**Diagnosis**:
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check Patroni cluster
patronictl -c /etc/patroni/patroni.yml list

# Check connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Check for locks
sudo -u postgres psql -c "SELECT * FROM pg_locks WHERE NOT granted;"

# Check logs
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

**Solutions**:
- Check max_connections setting
- Kill idle connections
- Restart application connection pool
- Failover to standby (if primary failed)
- Check network connectivity

#### 5. Email Not Sending/Receiving

**Symptoms**: Emails stuck in queue or bouncing

**Diagnosis**:
```bash
# Check mail queue
sudo mailq

# Check logs
sudo tail -f /var/log/mail.log

# Test SMTP
telnet mail.company.com 25

# Check DNS records
dig company.com MX
dig company.com TXT  # SPF
dig default._domainkey.company.com TXT  # DKIM

# Check Postfix status
sudo systemctl status postfix

# Check if port is blocked
sudo nc -zv mail.company.com 25
sudo nc -zv mail.company.com 587
```

**Solutions**:
- Flush mail queue: `sudo postfix flush`
- Check firewall rules
- Verify DNS records
- Check SPF/DKIM/DMARC configuration
- Review spam filters (SpamAssassin)
- Check if IP is blacklisted: `https://mxtoolbox.com/blacklists.aspx`

#### 6. Slow Performance

**Symptoms**: Pages loading slowly

**Diagnosis**:
```bash
# Check system resources
top
htop
iotop  # Disk I/O

# Check database performance
sudo -u postgres psql nextcloud -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"

# Check Redis
redis-cli INFO

# Check web server
# Nginx:
curl -s http://localhost/nginx_status

# Application-specific
# Nextcloud:
sudo -u www-data php occ config:list system
sudo -u www-data php occ db:add-missing-indices
```

**Solutions**:
- Add RAM if memory is maxed
- Optimize database queries
- Enable/check caching (Redis, APCu)
- Increase PHP-FPM workers
- Add Elasticsearch for file searching
- Check for DDOS (review firewall logs)

#### 7. Certificate Errors

**Symptoms**: Browser warning about invalid certificate

**Diagnosis**:
```bash
# Check certificate
sudo certbot certificates

# Check expiry
echo | openssl s_client -connect cloud.company.com:443 2>/dev/null | openssl x509 -noout -dates

# Check Traefik certificate storage
sudo cat /opt/traefik/certs/acme.json | jq

# Check certificate chain
openssl s_client -connect cloud.company.com:443 -showcerts
```

**Solutions**:
- Renew certificate: `sudo certbot renew`
- Check Traefik Let's Encrypt rate limits
- Verify DNS points to correct IP
- Clear browser cache
- Check certificate permissions

#### 8. Backup Failures

**Symptoms**: Backup alerts from Zabbix

**Diagnosis**:
```bash
# Check backup logs
sudo tail -f /var/log/backup-*.log

# Test Borg repo
borg list backup@backup1:/backup/repos/cloud1

# Check disk space on backup server
ssh backup1 "df -h"

# Test Borg manually
sudo borg create --dry-run --stats <repo>::test-backup /tmp
```

**Solutions**:
- Free up space on backup server
- Check SSH connectivity
- Verify Borg passphrase
- Re-run failed backup manually
- Check if repo is locked: `borg break-lock <repo>`

### Emergency Procedures

#### Service Completely Down

1. **Assess Impact**: 
   - Check Zabbix dashboard
   - Identify affected services
   
2. **Immediate Actions**:
   - Check if hardware/network issue
   - Attempt service restart
   - Check logs for root cause

3. **Escalation**:
   - If restart fails, prepare for restoration from backup
   - Notify stakeholders
   - Activate incident response team

4. **Communication Template**:
   ```
   Subject: [OUTAGE] <Service> Unavailable
   
   We are currently experiencing an outage affecting <service>.
   
   Impact: [list affected functions]
   Estimated Resolution: [time]
   Workarounds: [if any]
   
   Updates will be provided every [interval].
   
   IT Support Team
   ```

#### Ransomware/Security Breach

1. **Isolate Affected Systems**:
   ```bash
   # Disconnect from network
   sudo ip link set <interface> down
   
   # Enable iptables block-all
   sudo iptables -P INPUT DROP
   sudo iptables -P OUTPUT DROP
   sudo iptables -P FORWARD DROP
   ```

2. **Activate Incident Response**:
   - Notify security team
   - Preserve evidence
   - Contact authorities if needed

3. **Assessment**:
   - Identify scope of compromise
   - Check logs for indicators of compromise
   - Review user access logs

4. **Containment**:
   - Disable compromised accounts
   - Reset all passwords
   - Restore from clean backups

5. **Recovery**:
   - Rebuild affected systems
   - Verify integrity before reconnection
   - Enhanced monitoring

---

## Appendices

### Appendix A: Network Diagram

```
                            Internet
                                │
                    ┌───────────┴───────────┐
                    │ pfSense Firewall      │
                    │ 203.0.113.10 (WAN)    │
                    │ 192.168.99.1 (DMZ)    │
                    │ 172.16.20.1 (LAN)     │
                    └───────────┬───────────┘
                                │
                    ┌───────────┴───────────┐
                    │ Core Switch (L3)      │
                    │ Inter-VLAN Routing    │
                    └───────────┬───────────┘
                                │
         ┌──────────────────────┼──────────────────────┐
         │                      │                      │
    ┌────▼────┐           ┌─────▼─────┐        ┌──────▼──────┐
    │ VLAN 99 │           │ VLAN 20   │        │ VLAN 30     │
    │ DMZ     │           │ Servers   │        │ Database    │
    │ .99.0/24│           │ .20.0/24  │        │ .30.0/24    │
    └────┬────┘           └─────┬─────┘        └──────┬──────┘
         │                      │                     │
    ┌────▼────┐           ┌─────▼─────┐        ┌──────▼──────┐
    │ Traefik │           │Nextcloud  │        │PostgreSQL   │
    │HAProxy  │           │Mattermost │        │Patroni      │
    │ .99.10  │           │Keycloak   │        │ .30.10-11   │
    │         │           │Jitsi      │        │             │
    │         │           │Zammad     │        │MariaDB      │
    │         │           │Mail Server│        │Redis        │
    │         │           │ .20.10-70 │        │ .30.20      │
    └─────────┘           └───────────┘        └─────────────┘

    ┌─────────────┐       ┌─────────────┐      ┌─────────────┐
    │ VLAN 40     │       │ VLAN 50     │      │ VLAN 60     │
    │ Storage     │       │ Clients     │      │ VoIP        │
    │ .40.0/24    │       │ .50.0/23    │      │ .60.0/24    │
    └──────┬──────┘       └──────┬──────┘      └──────┬──────┘
           │                     │                    │
    ┌──────▼──────┐       ┌──────▼──────┐      ┌──────▼──────┐
    │NFS/Ceph     │       │Workstations │      │Jitsi SFU    │
    │Backup Server│       │Guard Devices│      │VoIP Phones  │
    │ .40.10-20   │       │ DHCP Range  │      │ .60.10-50   │
    └─────────────┘       └─────────────┘      └─────────────┘
```

### Appendix B: Port Reference

| Service | Protocol | Port | Description |
|---------|----------|------|-------------|
| HTTP | TCP | 80 | Web (redirect to HTTPS) |
| HTTPS | TCP | 443 | Encrypted web traffic |
| SSH | TCP | 22 | Secure shell |
| SMTP | TCP | 25 | Mail transfer |
| SMTP Submission | TCP | 587 | Mail submission (STARTTLS) |
| SMTPS | TCP | 465 | Mail submission (SSL) |
| IMAP | TCP | 143 | Mail retrieval |
| IMAPS | TCP | 993 | Mail retrieval (SSL) |
| POP3 | TCP | 110 | Mail retrieval |
| POP3S | TCP | 995 | Mail retrieval (SSL) |
| PostgreSQL | TCP | 5432 | Database |
| MariaDB | TCP | 3306 | Database |
| Redis | TCP | 6379 | Cache |
| LDAP | TCP | 389 | Directory |
| LDAPS | TCP | 636 | Directory (SSL) |
| Kerberos | TCP/UDP | 88 | Authentication |
| Kerberos Admin | TCP/UDP | 464 | Password changes |
| DNS | TCP/UDP | 53 | Name resolution |
| NTP | UDP | 123 | Time sync |
| Elasticsearch | TCP | 9200 | Search engine |
| Zabbix Server | TCP | 10051 | Monitoring |
| Zabbix Agent | TCP | 10050 | Monitoring |
| Jitsi Video | UDP | 10000 | Video/audio RTP |
| Jitsi TURNS | TCP | 5349 | TURN/STUN |
| WireGuard | UDP | 51820 | VPN |

### Appendix C: Default Credentials Reference

⚠️ **SECURITY WARNING**: Change all default credentials immediately after installation!

| Service | Username | Default Password | Change Method |
|---------|----------|------------------|---------------|
| Proxmox | root | (set during install) | Web UI or `passwd` |
| FreeIPA | admin | (set during install) | `ipa passwd admin` |
| Keycloak | admin | (set during install) | Web UI |
| Nextcloud | admin | (set during install) | Web UI |
| Mattermost | (created during setup) | N/A | Web UI |
| Jitsi | (none - open by default) | N/A | Configure auth |
| Zammad | (created during setup) | N/A | Web UI |
| Zabbix | Admin | zabbix | Web UI → Profile |
| Graylog | admin | (set during install) | Web UI |
| PostgreSQL | postgres | (set during install) | `ALTER USER postgres PASSWORD` |
| Mail (postmaster) | postmaster@company.com | (set during install) | iRedAdmin |

### Appendix D: Useful Commands Cheat Sheet

**FreeIPA**:
```bash
# Get Kerberos ticket
kinit admin

# List users
ipa user-find

# Add user
ipa user-add jdoe --first=John --last=Doe --email=jdoe@company.com

# Reset password
ipa passwd jdoe

# Disable user
ipa user-disable jdoe

# List groups
ipa group-find

# Add user to group
ipa group-add-member <group> --users=<username>
```

**PostgreSQL**:
```bash
# Connect to database
sudo -u postgres psql <database>

# List databases
\l

# List tables
\dt

# Show table structure
\d <table>

# Backup database
pg_dump <database> > backup.sql

# Restore database
psql <database> < backup.sql

# Check replication status
SELECT * FROM pg_stat_replication;
```

**Nextcloud**:
```bash
# Run OCC command
sudo -u www-data php occ <command>

# List apps
sudo -u www-data php occ app:list

# Enable app
sudo -u www-data php occ app:enable <app>

# Scan files
sudo -u www-data php occ files:scan --all

# Maintenance mode
sudo -u www-data php occ maintenance:mode --on/--off

# User management
sudo -u www-data php occ user:list
sudo -u www-data php occ user:disable <username>
```

**Docker**:
```bash
# List containers
sudo docker ps -a

# View logs
sudo docker logs -f <container>

# Restart container
sudo docker restart <container>

# Execute command in container
sudo docker exec -it <container> <command>

# Clean up
sudo docker system prune -a
```

**Systemd**:
```bash
# Check status
sudo systemctl status <service>

# Start/stop/restart
sudo systemctl start|stop|restart <service>

# Enable/disable autostart
sudo systemctl enable|disable <service>

# View logs
sudo journalctl -u <service> -f

# List all services
sudo systemctl list-units --type=service
```

**Borg Backup**:
```bash
# List backups
borg list <repo>

# Create backup
borg create <repo>::<name> /path

# Extract backup
borg extract <repo>::<name>

# Mount backup
borg mount <repo>::<name> /mnt

# Prune old backups
borg prune --keep-daily=7 --keep-weekly=4 <repo>

# Check integrity
borg check <repo>
```

### Appendix E: Vendor Documentation Links

- **Proxmox VE**: https://pve.proxmox.com/wiki/Main_Page
- **FreeIPA**: https://www.freeipa.org/page/Documentation
- **Keycloak**: https://www.keycloak.org/documentation
- **Nextcloud**: https://docs.nextcloud.com/
- **Mattermost**: https://docs.mattermost.com/
- **Jitsi**: https://jitsi.github.io/handbook/
- **Zammad**: https://docs.zammad.org/
- **iRedMail**: https://docs.iredmail.org/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Borg Backup**: https://borgbackup.readthedocs.io/
- **Zabbix**: https://www.zabbix.com/documentation
- **Graylog**: https://docs.graylog.org/
- **Traefik**: https://doc.traefik.io/traefik/
- **WireGuard**: https://www.wireguard.com/quickstart/

### Appendix F: Support Contacts

**Internal**:
- IT Help Desk: helpdesk@company.com / https://desk.company.com
- Emergency IT Support: +1-XXX-XXX-XXXX
- System Administrator: sysadmin@company.com

**External / Vendors**:
- ISP Support: [ISP Contact]
- Hardware Vendor: [Vendor Contact]
- Managed Services (if applicable): [MSP Contact]

**Community**:
- Nextcloud Forums: https://help.nextcloud.com/
- Mattermost Community: https://community.mattermost.com/
- r/selfhosted: https://reddit.com/r/selfhosted
- r/sysadmin: https://reddit.com/r/sysadmin

### Appendix G: Compliance and Audit

**Data Privacy Considerations**:
- GDPR compliance (if handling EU data)
- Personal information encryption (E2E in Nextcloud)
- Data retention policies (configurable in Nextcloud, Zammad)
- Right to deletion (user data purge scripts)
- Audit trails (enabled in all applications)

**Security Compliance**:
- Regular vulnerability scanning
- Penetration testing (annual)
- Security awareness training
- Incident response plan
- Disaster recovery testing

**Logging and Audit Trails**:
All applications configured to log:
- User authentication (success/failure)
- Administrative actions
- File access/modifications
- Email sent/received
- Ticket creation/resolution
- Configuration changes

Logs centralized in Graylog, retained for 180 days minimum.

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-04 | IT Infrastructure Team | Initial release |

---

## Glossary

- **AD**: Active Directory
- **API**: Application Programming Interface
- **BBU**: Battery Backup Unit
- **CA**: Certificate Authority
- **CalDAV**: Calendar Distributed Authoring and Versioning
- **CardDAV**: Contact Distributed Authoring and Versioning
- **DKIM**: DomainKeys Identified Mail
- **DMARC**: Domain-based Message Authentication, Reporting, and Conformance
- **DMZ**: Demilitarized Zone
- **E2E**: End-to-End (encryption)
- **ECC**: Error-Correcting Code (memory)
- **HBAC**: Host-Based Access Control
- **IDS**: Intrusion Detection System
- **IMAP**: Internet Message Access Protocol
- **IPS**: Intrusion Prevention System
- **LDAP**: Lightweight Directory Access Protocol
- **MFA**: Multi-Factor Authentication
- **MUC**: Multi-User Chat
- **NVMe**: Non-Volatile Memory Express
- **OAuth**: Open Authorization
- **OIDC**: OpenID Connect
- **PITR**: Point-In-Time Recovery
- **RAID**: Redundant Array of Independent Disks
- **RBAC**: Role-Based Access Control
- **RPO**: Recovery Point Objective
- **RTO**: Recovery Time Objective
- **SAML**: Security Assertion Markup Language
- **SFP+**: Small Form-factor Pluggable (enhanced)
- **SLA**: Service Level Agreement
- **SMTP**: Simple Mail Transfer Protocol
- **SPF**: Sender Policy Framework
- **SSD**: Solid-State Drive
- **SSO**: Single Sign-On
- **TOTP**: Time-based One-Time Password
- **VLAN**: Virtual Local Area Network
- **VPN**: Virtual Private Network
- **WAF**: Web Application Firewall
- **XMPP**: Extensible Messaging and Presence Protocol

---

**END OF DOCUMENT**

This comprehensive deployment guide provides a complete enterprise-grade IT infrastructure solution using 100% open-source technologies. All components are production-ready, scalable, and integrated through a single sign-on system.

For questions or clarifications, contact the IT Infrastructure Team at sysadmin@company.com.
