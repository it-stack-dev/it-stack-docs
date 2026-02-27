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
5. [Server Allocation](#server-allocation)
6. [Deployment Phases](#deployment-phases)
7. [Installation Quick Start](#installation-quick-start)
8. [Testing Scenarios](#testing-scenarios)
9. [Migration to Production](#migration-to-production)
10. [Lab Environment Cleanup](#lab-environment-cleanup)

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
