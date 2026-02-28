---
doc: 07
title: "Lab Manual Part 1: Network & OS Setup"
category: labs
date: 2026-02-27
source: labs/part1-network-os.md
---
# Enterprise Open-Source IT Infrastructure Lab
# Complete Deployment Manual - 5 Server Configuration
**Educational Lab Manual with Complete CLI Instructions**

---

## Course Information

| Item | Details |
|------|---------|
| **Lab Title** | Enterprise IT Stack - Complete Deployment |
| **Lab Number** | Infrastructure Lab 1 |
| **Prerequisites** | Basic Linux command line knowledge, networking fundamentals |
| **Estimated Time** | 20-30 hours (over 3-4 weeks) |
| **Difficulty** | Advanced |
| **Target Audience** | IT students, system administrators, infrastructure engineers |

---

## Table of Contents

1. [Lab Overview](#lab-overview)
2. [Learning Objectives](#learning-objectives)
3. [Required Resources](#required-resources)
4. [Network Fundamentals](#network-fundamentals)
5. [Exercise 1: Network Infrastructure Setup](#exercise-1-network-infrastructure-setup)
6. [Exercise 2: Ubuntu Server Installation](#exercise-2-ubuntu-server-installation)
7. [Exercise 3: Network Configuration](#exercise-3-network-configuration)
8. [Exercise 4: FreeIPA Identity Management](#exercise-4-freeipa-identity-management)
9. [Exercise 5: PostgreSQL Database Server](#exercise-5-postgresql-database-server)
10. [Exercise 6: Keycloak SSO Installation](#exercise-6-keycloak-sso-installation)
11. [Exercise 7: Nextcloud Collaboration Platform](#exercise-7-nextcloud-collaboration-platform)
12. [Exercise 8: Mattermost Team Chat](#exercise-8-mattermost-team-chat)
13. [Exercise 9: Jitsi Video Conferencing](#exercise-9-jitsi-video-conferencing)
14. [Exercise 10: Email Server with iRedMail](#exercise-10-email-server-with-iredmail)
15. [Exercise 11: Traefik Reverse Proxy](#exercise-11-traefik-reverse-proxy)
16. [Exercise 12: Zammad Help Desk System](#exercise-12-zammad-help-desk-system)
17. [Exercise 13: SSO Integration](#exercise-13-sso-integration)
18. [Exercise 14: Monitoring and Logging](#exercise-14-monitoring-and-logging)
19. [Testing and Verification](#testing-and-verification)
20. [Troubleshooting Guide](#troubleshooting-guide)
21. [Lab Completion Checklist](#lab-completion-checklist)
22. [Command Reference](#command-reference)

---

## Lab Overview

This comprehensive lab guides you through building a complete enterprise-grade IT infrastructure using 100% open-source software. You will deploy an integrated ecosystem of services including identity management, email, file sharing, team collaboration, video conferencing, and help desk systems—all configured for Single Sign-On (SSO) authentication.

**What You'll Build:**

```
┌─────────────────────────────────────────────────────────────────┐
│                     Complete IT Infrastructure                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ Identity │  │ Database │  │   Apps   │  │  Email   │  ...  │
│  │ FreeIPA  │  │PostgreSQL│  │Nextcloud │  │iRedMail  │      │
│  │ Keycloak │  │  Redis   │  │Mattermost│  │  Zammad  │      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
│       ↑             ↑             ↑             ↑              │
│       └─────────────┴─────────────┴─────────────┘              │
│                   Single Sign-On (SSO)                         │
└─────────────────────────────────────────────────────────────────┘
```

**Real-World Application:**
- This infrastructure supports 50-500+ users in a business environment
- Used by companies worldwide for secure, private communications
- No vendor lock-in - complete control of your data
- Demonstrates enterprise architecture principles
- Applicable to security services, healthcare, education, government sectors

**Why This Lab Matters:**
- Learn enterprise system integration from ground up
- Understand how large organizations structure IT infrastructure
- Gain hands-on experience with production-grade tools
- Build portfolio-worthy project demonstrating advanced skills
- Prepare for careers in system administration and DevOps

---

## Learning Objectives

By the end of this lab, you will be able to:

### ✅ **Networking Skills:**
- Design and implement a segmented network infrastructure
- Configure managed switches with VLANs
- Set up static IP addressing schemes for servers
- Troubleshoot network connectivity issues at Layer 2 and Layer 3
- Configure DNS for service discovery
- Implement basic firewall rules using UFW (Uncomplicated Firewall)

### ✅ **Linux System Administration:**
- Install Ubuntu Server 24.04 LTS from ISO media
- Configure network interfaces using Netplan
- Manage systemd services (start, stop, enable, disable)
- Edit configuration files using vim/nano
- Understand Linux file permissions and ownership
- Use package managers (apt) for software installation
- Monitor system resources (CPU, RAM, disk, network)
- Read and interpret system logs with journalctl

### ✅ **Identity & Access Management:**
- Deploy FreeIPA as centralized LDAP directory
- Understand Kerberos authentication principles
- Configure Keycloak for Single Sign-On (SSO)
- Integrate applications with LDAP/SAML/OAuth
- Create users and groups with proper access controls
- Implement role-based access control (RBAC)

### ✅ **Database Administration:**
- Install and configure PostgreSQL
- Create databases and users with proper privileges
- Configure PostgreSQL for network access
- Understand connection pooling with pgBouncer
- Install and configure Redis for caching
- Perform basic database backups and restores

### ✅ **Web Services:**
- Configure Nginx as reverse proxy and web server
- Understand HTTP vs HTTPS and SSL/TLS certificates
- Deploy PHP-FPM for dynamic content
- Configure virtual hosts for multiple services
- Implement load balancing concepts

### ✅ **Application Deployment:**
- Deploy containerized applications with Docker
- Install complex multi-component applications
- Configure application databases and storage
- Integrate applications with authentication backends
- Troubleshoot application-level issues

### ✅ **Email Infrastructure:**
- Understand SMTP, IMAP, and mail protocols
- Deploy complete mail server stack
- Configure SPF, DKIM, and DMARC records
- Set up webmail interfaces
- Configure spam filtering and antivirus

### ✅ **Real-Time Communication:**
- Deploy team chat platform (Mattermost)
- Set up video conferencing (Jitsi Meet)
- Configure WebRTC and media streaming
- Understand SIP and XMPP protocols

### ✅ **Integration & Automation:**
- Configure Single Sign-On across multiple platforms
- Write shell scripts for automation
- Create user provisioning workflows
- Implement service health monitoring
- Set up centralized logging

### ✅ **Security Best Practices:**
- Harden Linux servers (SSH, firewall, fail2ban)
- Implement least-privilege access
- Configure encrypted communications (TLS/SSL)
- Understand attack surfaces and mitigation
- Implement backup and disaster recovery procedures

---

## Required Resources

### Physical Hardware

| Server | Role | Minimum Specs | Recommended Specs |
|--------|------|---------------|-------------------|
| **LAB-ID1** | Identity & Directory | 4 cores, 8 GB RAM, 100 GB disk | 4 cores, 12 GB RAM, 120 GB SSD |
| **LAB-DB1** | Database Server | 4 cores, 8 GB RAM, 100 GB disk | 6 cores, 16 GB RAM, 200 GB SSD |
| **LAB-APP1** | Collaboration Apps | 4 cores, 12 GB RAM, 150 GB disk | 6 cores, 16 GB RAM, 250 GB SSD |
| **LAB-COMM1** | Communications | 4 cores, 8 GB RAM, 100 GB disk | 4 cores, 12 GB RAM, 150 GB SSD |
| **LAB-PROXY1** | Reverse Proxy & Monitoring | 2 cores, 4 GB RAM, 50 GB disk | 4 cores, 8 GB RAM, 100 GB SSD |

**Total Minimum Resources:** 18 cores, 40 GB RAM, 500 GB storage  
**Total Recommended Resources:** 24 cores, 64 GB RAM, 820 GB storage

### Network Equipment

| Equipment | Quantity | Specifications | Purpose |
|-----------|----------|----------------|---------|
| **Managed Switch** | 1 | 8+ ports, Gigabit, VLAN support | Core network connectivity |
| **Ethernet Cables** | 6+ | Cat6, various lengths | Server connections |
| **USB Drive** | 1 | 8 GB minimum | Ubuntu Server installation media |
| **KVM Switch** (optional) | 1 | 5-port | Shared keyboard/monitor for servers |

### Software Requirements

| Software | Version | Download Source | Purpose |
|----------|---------|-----------------|---------|
| Ubuntu Server | 24.04 LTS | https://ubuntu.com/download/server | Base operating system |
| FreeIPA | 4.11+ | Ubuntu repositories | Identity management |
| Keycloak | 24.0+ | https://keycloak.org | SSO provider |
| PostgreSQL | 16.x | Ubuntu repositories | Relational database |
| Nextcloud | 28.x | https://nextcloud.com | File collaboration |
| Mattermost | 9.3+ | https://mattermost.com | Team chat |
| Jitsi Meet | Latest | https://jitsi.org | Video conferencing |
| iRedMail | 1.6.8+ | https://iredmail.org | Email server |
| Traefik | 2.11+ | https://traefik.io | Reverse proxy |
| Zammad | 6.x | https://zammad.org | Help desk |

### Documentation and Tools

**Required on Your Workstation:**
- SSH client (PuTTY for Windows, native for Linux/Mac)
- Web browser (Firefox or Chrome recommended)
- Text editor for documentation
- Network diagram tool (optional)

**Reference Documentation:**
You'll be guided through all steps, but official docs are helpful:
- Ubuntu Server Guide: https://ubuntu.com/server/docs
- FreeIPA Documentation: https://freeipa.org/page/Documentation
- Keycloak Admin Guide: https://keycloak.org/documentation

---

## Network Fundamentals

### Understanding Network Architecture

Before building the infrastructure, understand the network design principles that make it reliable and secure.

**Network Segmentation:**

Modern networks use **VLANs** (Virtual LANs) to logically separate traffic:

```
Physical Switch (Single Device)
    ↓
┌───────────────────────────────────────┐
│ VLAN 10: Management  (172.16.10.0/24) │  ← Server management
│ VLAN 20: Servers     (172.16.20.0/24) │  ← Application servers
│ VLAN 30: Database    (172.16.30.0/24) │  ← Database backend
│ VLAN 50: Clients     (172.16.50.0/24) │  ← User workstations
└───────────────────────────────────────┘
```

**Why VLANs?**
1. **Security:** Isolate sensitive data (databases) from general network
2. **Performance:** Reduce broadcast traffic by segmentation
3. **Flexibility:** Move servers between VLANs without changing physical cables
4. **Compliance:** Many standards require network segmentation

**For This Lab:**

We'll use a **simplified single-VLAN design** for ease of learning:
- All servers on same subnet: `10.0.50.0/24`
- Gateway: `10.0.50.1` (school router or your lab router)
- DNS: `10.0.50.11` (will be FreeIPA server)

**Production Difference:**
In production, you'd implement multiple VLANs as shown in the enterprise deployment guide, with firewall rules controlling inter-VLAN traffic.

---

### IP Addressing Scheme

**Understanding IPv4 Addressing:**

An IPv4 address has two parts:
- **Network portion:** Identifies the subnet
- **Host portion:** Identifies the specific device

Example: `10.0.50.11/24`
- **10.0.50** = Network (first 24 bits)
- **11** = Host (last 8 bits)
- **/24** = Subnet mask (255.255.255.0)

**Our Lab Addressing Plan:**

| Server | Hostname | IP Address | Services |
|--------|----------|-----------|----------|
| **Server 1** | lab-id1.lab.local | 10.0.50.11 | FreeIPA (LDAP, DNS, Kerberos) |
| **Server 2** | lab-db1.lab.local | 10.0.50.12 | PostgreSQL, Redis |
| **Server 3** | lab-app1.lab.local | 10.0.50.13 | Nextcloud, Mattermost, Jitsi |
| **Server 4** | lab-comm1.lab.local | 10.0.50.14 | iRedMail, Zammad |
| **Server 5** | lab-proxy1.lab.local | 10.0.50.15 | Traefik, Monitoring |
| **Gateway** | — | 10.0.50.1 | Internet router |
| **Test Clients** | — | 10.0.50.20-50 | Your laptop, test machines |

**Subnet Details:**
- **Network:** 10.0.50.0/24
- **Subnet Mask:** 255.255.255.0
- **Usable IPs:** 10.0.50.1 - 10.0.50.254 (254 hosts)
- **Broadcast:** 10.0.50.255

**Why This Scheme?**
- `.11-.15` for servers (easy to remember, sequential)
- `.20-.50` for dynamic/test clients
- `.1` standard for gateway
- Leaves room for expansion (.51-.254)

---

### DNS (Domain Name System) Basics

**What DNS Does:**

DNS translates human-readable names to IP addresses:

```
Request: "What IP is cloud.lab.local?"
DNS Response: "10.0.50.13"

Your browser then connects to: 10.0.50.13
```

**Why We Need DNS in This Lab:**

Without DNS, you'd have to access services like:
- `http://10.0.50.13` ← Hard to remember
- `https://10.0.50.13:8065` ← Port numbers confusing

With DNS:
- `http://cloud.lab.local` ← Easy!
- `http://chat.lab.local` ← Intuitive!

**Our DNS Setup:**

FreeIPA (on lab-id1) will be our DNS server:

| Service | DNS Name | Resolves To |
|---------|----------|-------------|
| FreeIPA Web UI | ipa.lab.local | 10.0.50.11 |
| Keycloak SSO | sso.lab.local | 10.0.50.11 (Keycloak runs here) |
| PostgreSQL | db.lab.local | 10.0.50.12 |
| Nextcloud | cloud.lab.local | 10.0.50.15 (via proxy) |
| Mattermost | chat.lab.local | 10.0.50.15 (via proxy) |
| Jitsi | meet.lab.local | 10.0.50.15 (via proxy) |
| Email Webmail | mail.lab.local | 10.0.50.15 (via proxy) |
| Help Desk | desk.lab.local | 10.0.50.15 (via proxy) |

**How It Works:**

1. Application server runs on specific IP (e.g., Nextcloud on 10.0.50.13)
2. Reverse proxy (Traefik on 10.0.50.15) receives all web traffic
3. Traefik routes requests based on hostname:
   - `cloud.lab.local` → forwards to 10.0.50.13:80
   - `chat.lab.local` → forwards to 10.0.50.13:8065

---

### Network Diagram

**Physical Topology:**

```
                    [School Network]
                           │
                    ┌──────┴──────┐
                    │   Gateway   │
                    │  10.0.50.1  │
                    └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │   Switch    │
                    │ (8+ ports)  │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┬─────────────────┐
         │                 │                 │                 │
    ┌────▼────┐       ┌────▼────┐      ┌────▼────┐      ┌────▼────┐
    │ LAB-ID1 │       │LAB-DB1  │      │LAB-APP1 │      │LAB-COMM1│  ...
    │.50.11   │       │.50.12   │      │.50.13   │      │.50.14   │
    │Identity │       │Database │      │  Apps   │      │  Email  │
    └─────────┘       └─────────┘      └─────────┘      └─────────┘
```

**Logical Service Flow:**

```
                         User Access
                              │
                              ▼
                    ┌─────────────────┐
                    │   LAB-PROXY1    │  ← Entry point
                    │  Traefik Proxy  │     (SSL termination)
                    │   10.0.50.15    │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │  Nextcloud   │  │  Mattermost  │  │    Jitsi     │
    │ 10.0.50.13   │  │ 10.0.50.13   │  │ 10.0.50.13   │
    └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
           │                 │                 │
           └─────────────────┼─────────────────┘
                             ▼
                    ┌─────────────────┐
                    │   LAB-ID1       │  ← Authentication
                    │  Keycloak SSO   │
                    │   10.0.50.11    │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   LAB-ID1       │  ← User Directory
                    │    FreeIPA      │
                    │   10.0.50.11    │
                    └─────────────────┘
           
    All applications authenticate through Keycloak,
    which validates users against FreeIPA directory
```

---

## Exercise 1: Network Infrastructure Setup

### Understanding Physical Network Setup

**Objective:** Configure the physical network infrastructure including switch setup, cable management, and initial connectivity testing.

**Why This Matters:**
Proper network foundation prevents hours of troubleshooting later. A well-organized network with proper labeling and documentation saves time in production environments.

**Time Required:** 1-2 hours

---

### Task 1.1: Physical Cable Connections

**Equipment Needed:**
- 5 Ethernet cables (Cat6 recommended)
- Managed network switch
- Labels or tape for cable identification
- Cable tester (optional but recommended)

**Steps:**

1. **Prepare Your Work Area**
   
   - Clear table or rack space for all 5 servers
   - Arrange servers in logical order (ID1, DB1, APP1, COMM1, PROXY1)
   - Position switch centrally for cable management
   
   **Best Practice:** Keep servers in order matching your documentation

2. **Label All Equipment**
   
   Before connecting anything, label:
   - Each server with its hostname (use tape/labels)
   - Each network cable with both ends (e.g., "LAB-ID1 ↔ SW-Port2")
   
   **Why?** In 2 weeks when troubleshooting, you'll thank yourself!

3. **Connect Servers to Switch**
   
   | Server | Switch Port | Cable Label |
   |--------|-------------|-------------|
   | LAB-ID1 (10.0.50.11) | Port 2 | ID1-SW2 |
   | LAB-DB1 (10.0.50.12) | Port 3 | DB1-SW3 |
   | LAB-APP1 (10.0.50.13) | Port 4 | APP1-SW4 |
   | LAB-COMM1 (10.0.50.14) | Port 5 | COMM1-SW5 |
   | LAB-PROXY1 (10.0.50.15) | Port 6 | PROXY1-SW6 |
   | Gateway/Uplink | Port 1 | UPLINK |
   
   **Note:** Port 1 connects to your school network/router for internet access

4. **Power On Switch**
   
   - Connect power to switch
   - Wait 1-2 minutes for boot-up
   - Observe port LEDs:
     - **Green solid:** Good 1 Gbps link
     - **Amber:** 100 Mbps link (check cable)
     - **Off:** No connection
   
   **At this point:** All ports should be OFF (servers not powered yet)

5. **Document Your Setup**
   
   Create a simple network map on paper or in a text file:
   ```
   Switch Physical Layout:
   
   [Port 1] ← Uplink to Gateway (10.0.50.1)
   [Port 2] ← LAB-ID1 (will be 10.0.50.11)
   [Port 3] ← LAB-DB1 (will be 10.0.50.12)
   [Port 4] ← LAB-APP1 (will be 10.0.50.13)
   [Port 5] ← LAB-COMM1 (will be 10.0.50.14)
   [Port 6] ← LAB-PROXY1 (will be 10.0.50.15)
   ```

---

### Task 1.2: Switch Basic Configuration (Optional)

**Note:** This task is optional if your switch is pre-configured or unmanaged. Skip to Task 1.3 if using a simple unmanaged switch.

**For Managed Switches Only:**

Most managed switches come with a default IP (often `192.168.1.1`). We'll access the web interface to verify configuration.

**Steps:**

1. **Determine Switch Default IP**
   
   Check the switch documentation or label. Common defaults:
   - Cisco: 192.168.1.1
   - Netgear: 192.168.0.1
   - TP-Link: 192.168.0.1
   - HP ProCurve: 192.168.2.1

2. **Connect Your Laptop to Switch**
   
   - Connect laptop to an unused switch port
   - Temporarily set laptop IP to same subnet as switch:
   
   **Linux/Mac:**
   ```bash
   sudo ip addr add 192.168.1.100/24 dev eth0
   # Replace eth0 with your interface name
   ```
   
   **Windows:**
   - Control Panel → Network → Change Adapter Settings
   - Right-click Ethernet → Properties → IPv4
   - Set: IP: 192.168.1.100, Mask: 255.255.255.0

3. **Access Switch Web Interface**
   
   - Open browser
   - Navigate to: `http://192.168.1.1` (or your switch's default IP)
   - Login with default credentials:
     - Common: admin/admin, admin/(blank), admin/password
     - Check switch manual if needed

4. **Verify Basic Settings**
   
   In the switch web interface:
   - Check all ports are **enabled**
   - Verify ports are set to **auto-negotiate** speed/duplex
   - Confirm **VLAN 1** is default (untagged) on all ports
   - Note the switch IP for documentation

5. **Optional: Set Switch Management IP**
   
   If you want to access the switch from your lab network:
   - Navigate to IP Configuration
   - Set static IP: `10.0.50.2`
   - Set subnet mask: `255.255.255.0`
   - Set gateway: `10.0.50.1`
   - Save configuration

6. **Restore Your Laptop Network**
   
   **Linux/Mac:**
   ```bash
   sudo ip addr del 192.168.1.100/24 dev eth0
   ```
   
   **Windows:**
   - Change adapter back to DHCP or your normal settings

**Verification:**
- All switch ports show "enabled" status
- Port LEDs are ready to light up when servers connect
- Switch accessible at 10.0.50.2 (if configured)

---

### Task 1.3: Prepare Installation Media

**Objective:** Create bootable USB drive with Ubuntu Server 24.04 LTS

**Time Required:** 20-30 minutes (mostly download time)

**What You'll Learn:**
- How to create bootable installation media
- Understanding ISO images
- Verification of downloads (checksums)

---

#### Step 1: Download Ubuntu Server ISO

1. **Open Browser** and navigate to:
   ```
   https://ubuntu.com/download/server
   ```

2. **Select Ubuntu Server 24.04 LTS**
   
   - Click download for "Ubuntu Server 24.04 LTS"
   - File: `ubuntu-24.04-live-server-amd64.iso`
   - Size: ~2 GB
   - **LTS = Long Term Support** (5 years of security updates)

3. **Download to Known Location**
   
   Save to a folder you can easily find:
   ```
   ~/Downloads/ubuntu-24.04-live-server-amd64.iso
   ```

4. **Verify Download (Important!)**
   
   **Why verify?** Corrupted downloads cause mysterious installation failures
   
   **Linux/Mac:**
   ```bash
   # Download checksum file
   cd ~/Downloads
   wget https://ubuntu.com/download/server/thank-you?version=24.04&architecture=amd64 -O SHA256SUMS
   
   # Verify
   sha256sum -c SHA256SUMS 2>&1 | grep OK
   ```
   
   Expected output:
   ```
   ubuntu-24.04-live-server-amd64.iso: OK
   ```
   
   **Windows:**
   - Download: https://releases.ubuntu.com/24.04/SHA256SUMS
   - Open PowerShell
   ```powershell
   cd Downloads
   Get-FileHash ubuntu-24.04-live-server-amd64.iso -Algorithm SHA256
   ```
   - Compare hash with SHA256SUMS file manually

---

#### Step 2: Create Bootable USB Drive

**Tools Needed:**

| Operating System | Recommended Tool | Download |
|-----------------|------------------|----------|
| **Windows** | Rufus | https://rufus.ie |
| **macOS** | balenaEtcher | https://etcher.balena.io |
| **Linux** | dd command (built-in) | N/A |

**Warning:** This will **erase all data** on the USB drive!

---

**Method A: Linux (Using dd command)**

1. **Insert USB Drive**

2. **Identify USB Device**
   ```bash
   lsblk
   ```
   
   Output example:
   ```
   NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
   sda      8:0    0 238.5G  0 disk 
   ├─sda1   8:1    0   512M  0 part /boot
   └─sda2   8:2    0   238G  0 part /
   sdb      8:16   1   7.5G  0 disk            ← This is your USB
   └─sdb1   8:17   1   7.5G  0 part
   ```
   
   **Your USB is likely `/dev/sdb` (not sdb1!)**
   
   ⚠️ **CRITICAL:** Wrong device = erased hard drive! Triple-check!

3. **Unmount USB (if mounted)**
   ```bash
   sudo umount /dev/sdb1  # If it's mounted
   ```

4. **Write ISO to USB**
   ```bash
   sudo dd if=~/Downloads/ubuntu-24.04-live-server-amd64.iso \
           of=/dev/sdb \
           bs=4M \
           status=progress \
           conv=fdatasync
   ```
   
   **Understanding this command:**
   - `dd` = Disk duplicator (low-level copy)
   - `if` = Input file (the ISO)
   - `of` = Output file (your USB device)
   - `bs=4M` = Block size (4 megabytes for speed)
   - `status=progress` = Show progress
   - `conv=fdatasync` = Ensure all data is written
   
   **This takes 5-10 minutes.** Be patient!

5. **Sync and Eject**
   ```bash
   sudo sync
   sudo eject /dev/sdb
   ```

---

**Method B: Windows (Using Rufus)**

1. **Download and Run Rufus**
   - No installation needed (portable app)
   - Run as Administrator

2. **Configure Rufus:**
   - **Device:** Select your USB drive
   - **Boot selection:** Click SELECT → choose Ubuntu ISO
   - **Partition scheme:** GPT (for UEFI) or MBR (for Legacy BIOS)
     - Modern servers: use **GPT**
     - Older servers: use **MBR**
   - **File system:** FAT32
   - **Cluster size:** Default

3. **Start**
   - Click START
   - If prompted about ISO Image mode vs DD mode: Choose **ISO Image mode**
   - Confirm data will be destroyed
   - Wait 5-10 minutes

4. **Eject When Complete**
   - Safely remove USB drive

---

**Method C: macOS (Using balenaEtcher)**

1. **Install balenaEtcher**
   - Download from https://etcher.balena.io
   - Open DMG and drag to Applications

2. **Run Etcher**
   - Launch balenaEtcher
   - Click "Flash from file" → select Ubuntu ISO
   - Click "Select target" → choose USB drive
   - Click "Flash!"
   - Enter admin password when prompted

3. **Wait for Completion**
   - Takes 5-10 minutes
   - Eject when finished

---

**Verification:**

1. **Re-insert USB drive**

2. **Check USB contents:**
   
   Should see files like:
   ```
   boot/
   casper/
   EFI/
   isolinux/
   .disk/
   ```
   
   If you see these folders, USB is ready!

**Important Notes:**

- Keep this USB safe - you'll use it to install on all 5 servers
- Label the USB: "Ubuntu 24.04 Server Install"
- You can reuse this USB for other Ubuntu installations

---

### Task 1.4: Prepare Server Hardware

**Before Installing Operating System:**

**For Each of the 5 Servers:**

1. **Physical Inspection**
   
   - Verify power cables connected
   - Ensure RAM is properly seated
   - Check that hard drives are recognized in BIOS
   - Verify network cables from Task 1.1 are connected

2. **BIOS/UEFI Configuration**
   
   **Access BIOS:**
   - Power on server
   - Press `F2`, `Del`, `F10`, or `Esc` (watch boot screen for prompt)
   - Common keys by manufacturer:
     - Dell: F2
     - HP: F10
     - Lenovo: F1 or Enter
   
   **Settings to Verify:**
   
   a. **Boot Order:**
      - Set to boot from USB first
      - Then hard drive
   
   b. **Network Boot:**
      - Disable PXE boot (not needed)
   
   c. **Virtualization:**
      - Enable VT-x (Intel) or AMD-V (AMD)
      - Required for Docker later
   
   d. **Time/Date:**
      - Set correct time and timezone
      - Important for Kerberos authentication later!
   
   e. **Save and Exit**

3. **Documentation**
   
   For each server, note:
   - BIOS version
   - RAM amount detected
   - Hard drive size detected
   - Network MAC address (shown in BIOS or boot screen)
   
   Example:
   ```
   LAB-ID1:
   - BIOS: American Megatrends v2.1
   - RAM: 12 GB
   - Disk: 240 GB SSD
   - MAC: 00:1A:2B:3C:4D:5E
   ```

**You're Now Ready for OS Installation!**

---

## Exercise 2: Ubuntu Server Installation

### Understanding Operating System Installation

**What We're Installing:**

**Ubuntu Server 24.04 LTS** is a:
- **Linux distribution** based on Debian
- **Server edition** (no GUI by default, optimized for servers)
- **LTS release** (Long Term Support = 5 years of updates until April 2029)

**Why Ubuntu Server?**
- Industry-standard for cloud and enterprise
- Excellent hardware compatibility
- Large community and documentation
- Free and open-source
- Easy package management with APT
- Used by AWS, Google Cloud, Azure

**Installation Overview:**

We'll install the same OS on all 5 servers, but with different:
- Hostnames (lab-id1, lab-db1, etc.)
- IP addresses (10.0.50.11, .12, etc.)
- Disk partitioning (simple for most, custom for database server)

**Time Required:** ~30 minutes per server (2.5 hours total if sequential)

**Pro Tip:** If you have multiple monitors/KVM, you can install multiple servers simultaneously!

---

### Task 2.1: Install Ubuntu Server on LAB-ID1

**This server will host:**
- FreeIPA (Identity Management)
- Keycloak (Single Sign-On)

**Target Configuration:**
- Hostname: `lab-id1.lab.local`
- IP: `10.0.50.11/24`
- Gateway: `10.0.50.1`
- DNS: `8.8.8.8` (temporarily, will be self after FreeIPA installed)

---

#### Step 1: Boot from USB

1. **Insert USB drive** into LAB-ID1 server

2. **Power on server**

3. **Enter Boot Menu**
   - Watch screen for boot menu key (usually F12, F11, or Esc)
   - Select USB drive from boot menu
   
   **Alternative:** If no boot menu:
   - Enter BIOS (F2/Del)
   - Change boot order to USB first
   - Save and restart

4. **Ubuntu Installer Boots**
   
   You'll see:
   ```
   GNU GRUB
   
   Try or Install Ubuntu Server
   Ubuntu Server (safe graphics)
   Test memory
   Boot from first hard disk
   ```
   
   **Select:** `Try or Install Ubuntu Server` (press Enter)
   
   **Wait:** 30-60 seconds for installer to load

---

#### Step 2: Language and Keyboard

**Screen 1: Language Selection**

```
┌────────────── Welcome ──────────────┐
│                                     │
│ Please choose your preferred        │
│ language.                           │
│                                     │
│   > English                         │
│     Español                         │
│     Français                        │
│     Deutsch                         │
│     ...                             │
│                                     │
│  [Done]              [Back]         │
└─────────────────────────────────────┘
```

**Actions:**
1. Use arrow keys to highlight `English`
2. Press Enter
3. Tab to `[Done]` and press Enter

**Understanding:** This sets installer language, not system locale (we'll configure that later)

---

**Screen 2: Installer Update**

```
Installer update available

A newer version of the installer is available.

Do you want to update to the new installer?

    [Yes, update to the new installer]
    [No, use the current installer]
```

**Actions:**
- Select: `No, use the current installer`
- Reason: Network might not be configured yet; current version is fine

---

**Screen 3: Keyboard Configuration**

```
┌─────── Keyboard configuration ────────┐
│                                        │
│ Layout: [English (US)            ▼]   │
│ Variant: [English (US)           ▼]   │
│                                        │
│ ┌────────────────────────────────────┐│
││                                    ││
││ Test keyboard here: _              ││
││                                    ││
│└────────────────────────────────────┘│
│                                        │
│  [Done]                    [Back]     │
└────────────────────────────────────────┘
```

**Actions:**
1. Verify Layout is correct for your keyboard
2. Test by typing in the box
3. Tab to `[Done]` and press Enter

**Common Layouts:**
- US: English (US)
- Canada: English (US) with Canadian Multilingual
- UK: English (UK)

---

#### Step 3: Network Configuration

**This is a critical step!** We're configuring the static IP address.

```
┌──────── Network connections ───────────┐
│                                         │
│ NAME     TYPE    STATE   IP ADDRESS     │
│ ens160   eth     up      10.0.50.xxx    │ ← May show DHCP IP
│                                         │
│ [Edit]  [Delete]  [Refresh]            │
│                                         │
│  [Done]                      [Back]    │
└─────────────────────────────────────────┘
```

**Actions:**

1. **Identify Network Interface**
   - Note the name (usually `ens160`, `ens33`, `eth0`, `enp0s3`)
   - For this guide, we'll assume `ens160`

2. **Edit Interface Configuration**
   - Tab to `[Edit]` and press Enter

**Edit Interface Screen:**

```
┌──────── Edit ens160 ───────────┐
│                                 │
│ IPv4 Method:                    │
│   ( ) Automatic (DHCP)          │
│   (•) Manual                    │ ← Select this
│   ( ) Disabled                  │
│                                 │
│ Subnet: [10.0.50.0/24        ]  │
│ Address: [10.0.50.11         ]  │
│ Gateway: [10.0.50.1          ]  │
│ Name servers: [8.8.8.8       ]  │
│ Search domains: [lab.local   ]  │
│                                 │
│  [Save]              [Cancel]  │
└─────────────────────────────────┘
```

**Step-by-Step Configuration:**

1. **Select Manual**
   - Use arrow keys to select `Manual`
   - Press Space to select

2. **Configure Subnet**
   - Tab to Subnet field
   - Enter: `10.0.50.0/24`
   
   **Understanding:**
   - `10.0.50.0` = Network address
   - `/24` = Subnet mask (255.255.255.0)
   - This means IPs from 10.0.50.1 to 10.0.50.254 are available

3. **Configure Address**
   - Tab to Address field
   - Enter: `10.0.50.11`
   
   **Why .11?** This is LAB-ID1's assigned IP from our addressing plan

4. **Configure Gateway**
   - Tab to Gateway field
   - Enter: `10.0.50.1`
   
   **What's a gateway?** The router that forwards traffic to other networks (Internet)

5. **Configure Name servers**
   - Tab to Name servers field
   - Enter: `8.8.8.8`
   
   **Why 8.8.8.8?**
   - Google's public DNS (temporary)
   - After FreeIPA installation, we'll change this to `10.0.50.11` (self)

6. **Configure Search domains**
   - Tab to Search domains field
   - Enter: `lab.local`
   
   **What's this?**
   - When you type `ping lab-id1`, it auto-tries `lab-id1.lab.local`
   - Convenience feature for short names

7. **Save Configuration**
   - Tab to `[Save]`
   - Press Enter

**Verification:**

Back at Network connections screen:

```
┌──────── Network connections ───────────┐
│                                         │
│ NAME     TYPE    STATE   IP ADDRESS     │
│ ens160   eth     up      10.0.50.11/24  │ ← Should show your IP
│                                         │
```

- Verify IP shows `10.0.50.11/24`
- If incorrect, select `[Edit]` again and fix
- Tab to `[Done]` and press Enter when correct

---

#### Step 4: Proxy Configuration

```
┌─────────── Proxy address ──────────────┐
│                                         │
│ If you need to use a HTTP proxy to     │
│ connect to the outside world, enter    │
│ the proxy server's hostname/IP here.   │
│                                         │
│ Proxy address: [________________]       │
│                                         │
│  [Done]                      [Back]    │
└─────────────────────────────────────────┘
```

**Actions:**
- **Leave blank** (unless your school requires a proxy)
- Tab to `[Done]` and press Enter

**When would you need this?**
- Corporate environments with restricted internet
- Some schools that filter all traffic through proxy
- **Check with your instructor** if unsure

---

#### Step 5: Ubuntu Archive Mirror

```
┌───── Configure Ubuntu archive mirror ────┐
│                                           │
│ Mirror address:                           │
│ [http://archive.ubuntu.com/ubuntu      ]  │
│                                           │
│  [Done]                        [Back]    │
└───────────────────────────────────────────┘
```

**Actions:**
- **Leave as default** `http://archive.ubuntu.com/ubuntu`
- Tab to `[Done]` and press Enter

**Understanding:**
- This is where Ubuntu downloads packages
- Default mirror works worldwide
- Some regions have faster mirrors (can change later if needed)

---

#### Step 6: Storage Configuration

**This is where we partition the disk.**

```
┌──────────── Storage configuration ─────────────┐
│                                                 │
│ USED DEVICES                                    │
│   ubuntu-lv    new, to be formatted as ext4    │
│               mounted at /                      │
│               100 GB                            │
│                                                 │
│ AVAILABLE DEVICES                               │
│   sda        240 GB ATA SSD                     │
│                                                 │
│ ( ) Use an entire disk                          │
│ ( ) Use an entire disk and set up LVM          │
│ (•) Custom storage layout                       │
│                                                 │
│  [Done]                             [Back]     │
└─────────────────────────────────────────────────┘
```

**For LAB-ID1 (Simple Installation):**

**Actions:**
1. Select: `Use an entire disk and set up LVM`
   - Press Space to select
   
   **Why LVM?**
   - **LVM** = Logical Volume Manager
   - Allows resizing partitions later without downtime
   - Industry best practice
   - Can add disks and expand volumes dynamically

2. **Select Disk**
   ```
   Choose the disk to install to:
   
   [X] sda    240 GB ATA_SSD                      
   
   Set up this disk as an LVM group
   ```
   
   - Verify your disk is selected (X in checkbox)
   - Press Enter

3. **Storage Configuration Summary**
   
   Shows partition layout:
   ```
   USED DEVICES
   partition 1   new, to be formatted as FAT32, mounted at /boot/efi
                1 MB bios_grub
   
   partition 2   new, to be formatted as ext4, mounted at /boot
                2 GB
   
   partition 3   new LVM volume group ubuntu-vg
     ubuntu-lv   new, to be formatted as ext4, mounted at /
                237 GB
   
   AVAILABLE DEVICES
   (none)
   ```
   
   **Understanding:**
   - **/boot/efi**: UEFI boot partition (required for modern systems)
   - **/boot**: Kernel and initramfs storage
   - **/**: Root filesystem (everything else)
   - LVM allows growing **/** if we add more disks later

4. **Confirm and Continue**
   - Tab to `[Done]`
   - Press Enter

5. **Confirm Destructive Action**
   ```
   Confirm destructive action
   
   Selecting Continue below will begin the installation process
   and result in the loss of data on the disks selected to be
   formatted.
   
   You will not be able to return to this screen.
   
       [Cancel]    [Continue]
   ```
   
   - Tab to `[Continue]`
   - Press Enter
   
   ⚠️ **Warning:** This erases the disk! Ensure it's the correct server.

---

#### Step 7: Profile Setup

**Create the admin user account:**

```
┌────────── Profile setup ──────────┐
│                                   │
│ Your name:        [Lab Admin   ]  │
│                                   │
│ Your server's name: [lab-id1   ]  │
│                                   │
│ Pick a username:  [labadmin    ]  │
│                                   │
│ Choose a password: [***********]  │
│ Confirm password:  [***********]  │
│                                   │
│  [Done]                [Back]    │
└───────────────────────────────────┘
```

**Configuration:**

1. **Your name:**
   - Enter: `Lab Admin`
   - This is just descriptive (shown in login screen)

2. **Your server's name:**
   - Enter: `lab-id1`
   
   **Critical:** This becomes the hostname
   - Shows in command prompt
   - Used by other servers to identify this one
   - Must match our naming scheme
   
   **Note:** Installer auto-appends domain, final FQDN will be `lab-id1.lab.local`

3. **Pick a username:**
   - Enter: `labadmin`
   
   **Important:**
   - This is the account you'll use to login
   - Will have sudo (administrator) privileges
   - Keep consistent across all 5 servers (easier to remember)

4. **Choose a password:**
   - Enter a strong password
   - **Write this down securely!**
   - You'll need it after installation
   
   **Password Requirements:**
   - Minimum 8 characters
   - Mix of upper, lower, numbers recommended
   - Example: `LabAdmin2024!` (don't use this exact one!)

5. **Confirm password:**
   - Re-enter same password

6. **Continue**
   - Tab to `[Done]`
   - Press Enter

---

#### Step 8: SSH Setup

```
┌───────── SSH Setup ──────────┐
│                              │
│ [X] Install OpenSSH server   │
│                              │
│ Import SSH identity:         │
│ ( ) from GitHub              │
│ ( ) from Launchpad           │
│ (•) No                       │
│                              │
│  [Done]           [Back]    │
└──────────────────────────────┘
```

**Actions:**

1. **Ensure OpenSSH is selected**
   - Should see `[X] Install OpenSSH server`
   - If not checked, press Space to select
   
   **Why?**
   - SSH allows remote login from your laptop
   - You won't have to sit at each server console
   - Essential for administration

2. **Import SSH identity**
   - Select: `No`
   
   **What's this?**
   - Option to import your public SSH keys from GitHub/Launchpad
   - We'll configure SSH keys manually later (more educational)

3. **Continue**
   - Tab to `[Done]`
   - Press Enter

---

#### Step 9: Featured Server Snaps

```
┌──────── Featured Server Snaps ────────┐
│                                        │
│ These are popular snaps for servers.  │
│ You can install them later as well.   │
│                                        │
│ [ ] docker                             │
│ [ ] microk8s                           │
│ [ ] lxd                                │
│ [ ] nextcloud                          │
│ ...                                    │
│                                        │
│  [Done]                     [Back]    │
└────────────────────────────────────────┘
```

**Actions:**
- **Don't select anything** (leave all unchecked)
- Tab to `[Done]` and press Enter

**Why skip these?**
- We'll install Docker manually (better control)
- Snaps are good, but we want traditional package installs for learning
- These can bloat installation with unneeded dependencies

---

#### Step 10: Installation Progress

**Now the actual installation happens!**

```
┌──────────── Install complete! ────────────┐
│                                            │
│ Installing system                          │
│ ████████████████░░░░░░░░░░░░░░░  63%      │
│                                            │
│ Downloading and installing security       │
│ updates...                                 │
│                                            │
│ ┌────────────────────────────────────────┐│
││ 2024-02-04 14:23:15 Configuring grub...││
││ 2024-02-04 14:23:18 Installing kernel...││
││ 2024-02-04 14:23:45 Updating packages.. ││
││                                        ││
│└────────────────────────────────────────┘│
└────────────────────────────────────────────┘
```

**What's Happening:**

1. **Base system installation** (~5 minutes)
   - Copying Ubuntu files to disk
   - Creating filesystems
   - Installing bootloader (GRUB)

2. **Package updates** (~10-20 minutes)
   - Downloading latest security patches
   - Ensures system is up-to-date on first boot
   
   **Note:** Duration depends on internet speed

**You can watch progress messages to learn what's being installed.**

**After completion:**

```
┌───────── Install complete! ──────────┐
│                                       │
│ Installation complete!                │
│                                       │
│ View full log    [View]              │
│ Reboot Now       [Reboot Now]        │
│                                       │
└───────────────────────────────────────┘
```

**Actions:**
1. **Optional:** Select `[View]` to see full log (educational)
2. **Remove USB drive**
3. Tab to `[Reboot Now]` and press Enter

**System will restart.**

---

#### Step 11: First Boot and Login

**After reboot:**

1. **Watch Boot Messages**
   
   You'll see:
   ```
   Ubuntu 24.04 LTS lab-id1 tty1
   
   lab-id1 login: _
   ```

2. **Login**
   ```
   lab-id1 login: labadmin
   Password: [your password - won't be visible]
   ```
   
   **Note:** Cursor won't move when typing password (normal Linux behavior)

3. **Successful Login**
   
   You'll see:
   ```
   Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.5.0-14-generic x86_64)
   
    * Documentation:  https://help.ubuntu.com
    * Management:     https://landscape.canonical.com
    * Support:        https://ubuntu.com/advantage
   
     System information as of Mon Feb  4 14:45:23 UTC 2024
   
     System load:  0.0               Processes:             123
     Usage of /:   8.2% of 233.91GB  Users logged in:       0
     Memory usage: 12%               IPv4 address for ens160: 10.0.50.11
     Swap usage:   0%
   
   Last login: Mon Feb  4 14:30:12 2024
   labadmin@lab-id1:~$
   ```
   
   **Understanding the prompt:**
   ```
   labadmin  ← your username
   @         ← separator
   lab-id1   ← server hostname
   :~$       ← current directory (~ = home) and privilege ($ = user)
   ```

---

#### Step 12: Post-Installation Verification

**Run these commands to verify installation:**

1. **Check Hostname**
   ```bash
   hostname
   ```
   
   Expected output:
   ```
   lab-id1
   ```
   
   **Full hostname:**
   ```bash
   hostname -f
   ```
   
   Expected output:
   ```
   lab-id1.lab.local
   ```

2. **Check IP Address**
   ```bash
   ip addr show ens160
   ```
   
   Expected output (abbreviated):
   ```
   2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP
       link/ether 00:0c:29:3a:5f:2d brd ff:ff:ff:ff:ff:ff
       inet 10.0.50.11/24 brd 10.0.50.255 scope global ens160
   ```
   
   **Verify:**
   - IP is `10.0.50.11`
   - Subnet mask is `/24`
   - Interface is `UP`

3. **Check Default Gateway**
   ```bash
   ip route show
   ```
   
   Expected output:
   ```
   default via 10.0.50.1 dev ens160 proto static
   10.0.50.0/24 dev ens160 proto kernel scope link src 10.0.50.11
   ```
   
   **Verify:**
   - Default route points to `10.0.50.1`

4. **Check DNS**
   ```bash
   cat /etc/resolv.conf
   ```
   
   Expected output:
   ```
   nameserver 8.8.8.8
   search lab.local
   ```

5. **Test Internet Connectivity**
   ```bash
   ping -c 4 google.com
   ```
   
   Expected output:
   ```
   PING google.com (142.250.185.46) 56(84) bytes of data.
   64 bytes from lga25s78-in-f14.1e100.net (142.250.185.46): icmp_seq=1 ttl=117 time=12.4 ms
   64 bytes from lga25s78-in-f14.1e100.net (142.250.185.46): icmp_seq=2 ttl=117 time=11.8 ms
   ...
   
   --- google.com ping statistics ---
   4 packets transmitted, 4 received, 0% packet loss, time 3004ms
   ```
   
   **Understanding:**
   - `-c 4` = Count (send 4 packets then stop)
   - `ttl=117` = Time To Live (hops through routers)
   - `time=12.4 ms` = Round-trip time (latency)
   - `0% packet loss` = All packets received (good!)
   
   **If this fails:**
   - Check network cable
   - Verify gateway IP (10.0.50.1)
   - Check DNS (8.8.8.8)
   - See troubleshooting section

6. **Update System**
   
   Always update after fresh install:
   ```bash
   sudo apt update
   ```
   
   **Understanding:**
   - `sudo` = Run as administrator (you'll be prompted for password)
   - `apt` = Package manager
   - `update` = Refresh package list from repositories
   
   Expected output:
   ```
   [sudo] password for labadmin: [enter your password]
   Get:1 http://archive.ubuntu.com/ubuntu noble InRelease [256 kB]
   Get:2 http://archive.ubuntu.com/ubuntu noble-updates InRelease [126 kB]
   ...
   Fetched 12.3 MB in 8s (1,538 kB/s)
   Reading package lists... Done
   Building dependency tree... Done
   Reading state information... Done
   42 packages can be upgraded. Run 'apt list --upgradable' to see them.
   ```
   
   **Now upgrade packages:**
   ```bash
   sudo apt upgrade -y
   ```
   
   **Understanding:**
   - `upgrade` = Install newer versions of installed packages
   - `-y` = Answer "yes" to all prompts (unattended)
   
   This takes 5-10 minutes on first install.

7. **Reboot (if kernel updated)**
   ```bash
   sudo reboot
   ```
   
   Wait ~1 minute, then login again.

---

**✅ LAB-ID1 Installation Complete!**

**Congratulations!** You've successfully installed Ubuntu Server on your first server.

**What you learned:**
- How to boot from USB media
- Network interface configuration
- Static IP addressing
- LVM disk partitioning
- User account creation
- SSH installation
- Post-install verification commands

**Next Steps:**
- Repeat this process for the other 4 servers
- Each will have different hostname and IP
- After all servers installed, we'll configure services

---

### Task 2.2: Install Ubuntu on Remaining Servers

**Now repeat the installation process for each remaining server.**

**Only these settings change per server:**

| Server | Hostname | IP Address | Notes |
|--------|----------|-----------|-------|
| LAB-DB1 | `lab-db1` | `10.0.50.12` | Database server |
| LAB-APP1 | `lab-app1` | `10.0.50.13` | Application server |
| LAB-COMM1 | `lab-comm1` | `10.0.50.14` | Communications |
| LAB-PROXY1 | `lab-proxy1` | `10.0.50.15` | Reverse proxy |

**All other settings remain the same:**
- Username: `labadmin`
- Password: [same password]
- Gateway: `10.0.50.1`
- DNS: `8.8.8.8`
- Search domain: `lab.local`
- Subnet: `10.0.50.0/24`

---

**Installation Checklist:**

For each server, after installation, verify:

- [ ] Hostname correct: `hostname -f`
- [ ] IP address correct: `ip addr`
- [ ] Can ping gateway: `ping -c 2 10.0.50.1`
- [ ] Can ping internet: `ping -c 2 google.com`
- [ ] System updated: `sudo apt update && sudo apt upgrade -y`
- [ ] SSH working: Try logging in from another server

**Testing inter-server connectivity:**

After all 5 servers are installed and running:

```bash
# From LAB-ID1, ping all others:
ping -c 2 10.0.50.12  # LAB-DB1
ping -c 2 10.0.50.13  # LAB-APP1
ping -c 2 10.0.50.14  # LAB-COMM1
ping -c 2 10.0.50.15  # LAB-PROXY1
```

**All pings should succeed!**

If any fail:
- Check network cables
- Verify switch ports are enabled
- Confirm IP addresses match plan
- See troubleshooting section

---

**⚠️ Common Installation Mistakes:**

1. **Wrong IP address**
   - Solution: Edit `/etc/netplan/50-cloud-init.yaml`, run `sudo netplan apply`

2. **Wrong hostname**
   - Solution: `sudo hostnamectl set-hostname lab-xxx.lab.local`

3. **No internet connectivity**
   - Check: Gateway correct? `ip route`
   - Check: DNS working? `ping 8.8.8.8`

4. **SSH not installed**
   - Solution: `sudo apt install -y openssh-server`

---

## Exercise 3: Network Configuration

### Understanding Linux Networking

**Now that all 5 servers are installed, let's configure advanced networking features and verify connectivity.**

**What You'll Learn:**
- How Linux manages network configuration (Netplan)
- Configuring multiple DNS servers
- Setting up /etc/hosts for local name resolution
- Configuring NTP (time synchronization)
- Network troubleshooting tools

**Time Required:** 1 hour

---

### Task 3.1: Configure Netplan (Network Manager)

**Understanding Netplan:**

Ubuntu uses **Netplan** to configure networking. It's a YAML-based abstraction layer that generates configuration for NetworkManager or systemd-networkd.

**Configuration file location:**
```
/etc/netplan/50-cloud-init.yaml
```

**Let's examine and enhance our network configuration.**

---

#### Step 1: View Current Configuration

**On LAB-ID1:**

```bash
cat /etc/netplan/50-cloud-init.yaml
```

**Current content (from installation):**

```yaml
network:
  version: 2
  ethernets:
    ens160:
      dhcp4: false
      addresses:
        - 10.0.50.11/24
      routes:
        - to: default
          via: 10.0.50.1
      nameservers:
        addresses:
          - 8.8.8.8
        search:
          - lab.local
```

**Understanding this file:**

- **version: 2** → Netplan version
- **ethernets** → Wired network interfaces
- **ens160** → Interface name (yours may differ)
- **dhcp4: false** → Static IP (not DHCP)
- **addresses** → List of IPs assigned to interface
- **routes** → Routing table entries
  - **to: default** → All traffic not matching specific routes
  - **via: 10.0.50.1** → Send through this gateway
- **nameservers** → DNS configuration
  - **addresses** → DNS servers to query
  - **search** → Domain suffix for short names

---

#### Step 2: Enhance Network Configuration

**Let's improve this configuration with:**
- Multiple DNS servers (redundancy)
- Better routing
- MTU optimization

**Edit the file:**

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

**Replace content with:**

```yaml
network:
  version: 2
  ethernets:
    ens160:
      dhcp4: false
      addresses:
        - 10.0.50.11/24
      routes:
        - to: default
          via: 10.0.50.1
          metric: 100
      nameservers:
        addresses:
          - 10.0.50.11  # Will be self (FreeIPA) after installation
          - 8.8.8.8      # Fallback Google DNS
          - 1.1.1.1      # Fallback Cloudflare DNS
        search:
          - lab.local
      mtu: 1500
      optional: true
```

**New additions explained:**

1. **metric: 100**
   - Route priority (lower = preferred)
   - Useful if multiple routes exist
   - Best practice to specify explicitly

2. **Multiple nameservers**
   - First: 10.0.50.11 (this server, after FreeIPA installed)
   - Second: 8.8.8.8 (Google, fallback)
   - Third: 1.1.1.1 (Cloudflare, second fallback)
   - System tries in order

3. **mtu: 1500**
   - Maximum Transmission Unit (packet size)
   - 1500 is standard Ethernet MTU
   - Prevents fragmentation

4. **optional: true**
   - System boots even if network fails
   - Prevents boot hang on network issues

**Save and exit:**
- Press `Ctrl+X`
- Press `Y` to confirm
- Press `Enter` to save

---

#### Step 3: Test and Apply Configuration

**IMPORTANT:** Always test before applying!

```bash
sudo netplan try
```

**What this does:**
- Applies configuration
- If no confirmation in 120 seconds, **automatically rolls back**
- Prevents locking yourself out

**Output:**

```
Warning: Stopping systemd-networkd.service, but it can still be activated by:
  systemd-networkd.socket
Do you want to keep these settings?

Press ENTER before the timeout to accept the new configuration

Changes will revert in 118 seconds
Configuration accepted.
```

**Actions:**
- If network still works, press `Enter` to keep changes
- If something broke, wait 120 seconds for auto-rollback

**Permanently apply (if successful):**

```bash
sudo netplan apply
```

---

#### Step 4: Verify Network Configuration

**Check interface status:**

```bash
ip addr show ens160
```

**Check routing table:**

```bash
ip route show
```

Expected output:
```
default via 10.0.50.1 dev ens160 proto static metric 100
10.0.50.0/24 dev ens160 proto kernel scope link src 10.0.50.11
```

**Check DNS resolution:**

```bash
resolvectl status
```

Expected output (abbreviated):
```
Global
  Protocols: +LLMNR +mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: stub

Link 2 (ens160)
  Current Scopes: DNS
  Protocols: +DefaultRoute +LLMNR +mDNS -DNSOverTLS DNSSEC=no/unsupported
  Current DNS Server: 10.0.50.11
  DNS Servers: 10.0.50.11 8.8.8.8 1.1.1.1
  DNS Domain: lab.local
```

**Test DNS resolution:**

```bash
nslookup google.com
```

Expected output:
```
Server:         8.8.8.8
Address:        8.8.8.8#53

Non-authoritative answer:
Name:   google.com
Address: 142.250.185.46
```

**Understanding:** Currently resolves via 8.8.8.8 because FreeIPA not installed yet.

---

### Task 3.2: Configure /etc/hosts

**What is /etc/hosts?**

The `/etc/hosts` file provides static hostname-to-IP mappings, checked **before** DNS.

**Use cases:**
- Quick temporary name resolution
- Breaking DNS dependency loops
- Testing before DNS configured
- Local service discovery

**Let's add all our servers to /etc/hosts on each machine.**

---

#### Step 1: Edit /etc/hosts

**On LAB-ID1:**

```bash
sudo nano /etc/hosts
```

**Current content:**

```
127.0.0.1 localhost
127.0.1.1 lab-id1.lab.local lab-id1

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
```

**Add these lines at the end:**

```
# Lab Infrastructure Servers
10.0.50.11    lab-id1.lab.local       lab-id1     ipa sso
10.0.50.12    lab-db1.lab.local       lab-db1     db
10.0.50.13    lab-app1.lab.local      lab-app1    cloud chat meet
10.0.50.14    lab-comm1.lab.local     lab-comm1   mail desk
10.0.50.15    lab-proxy1.lab.local    lab-proxy1  proxy

# Service Aliases (will point through proxy)
10.0.50.15    cloud.lab.local
10.0.50.15    chat.lab.local
10.0.50.15    meet.lab.local
10.0.50.15    mail.lab.local
10.0.50.15    desk.lab.local
```

**Understanding this format:**

```
IP_ADDRESS    FQDN                    SHORT_NAME  ALIASES...
```

Example breakdown:
```
10.0.50.11    lab-id1.lab.local       lab-id1     ipa sso
↑             ↑                       ↑           ↑
IP            Full name               Short name  Convenience aliases
```

**Save and exit** (Ctrl+X, Y, Enter)

---

#### Step 2: Test /etc/hosts Resolution

```bash
# Test short name
ping -c 2 lab-db1

# Test FQDN
ping -c 2 lab-db1.lab.local

# Test alias
ping -c 2 db

# Test service alias
ping -c 2 cloud.lab.local
```

**All should resolve to appropriate IPs!**

**Understanding lookup order:**

1. System checks `/etc/hosts` first
2. If not found, queries DNS servers
3. If still not found, returns error

**Verify lookup order:**

```bash
cat /etc/nsswitch.conf | grep hosts
```

Expected output:
```
hosts:          files dns
```

- **files** = /etc/hosts
- **dns** = DNS servers

---

#### Step 3: Deploy /etc/hosts to All Servers

**Copy to other servers using SSH:**

**From LAB-ID1:**

```bash
# Copy to LAB-DB1
scp /etc/hosts labadmin@10.0.50.12:/tmp/hosts
ssh labadmin@10.0.50.12 'sudo cp /tmp/hosts /etc/hosts'

# Copy to LAB-APP1
scp /etc/hosts labadmin@10.0.50.13:/tmp/hosts
ssh labadmin@10.0.50.13 'sudo cp /tmp/hosts /etc/hosts'

# Copy to LAB-COMM1
scp /etc/hosts labadmin@10.0.50.14:/tmp/hosts
ssh labadmin@10.0.50.14 'sudo cp /tmp/hosts /etc/hosts'

# Copy to LAB-PROXY1
scp /etc/hosts labadmin@10.0.50.15:/tmp/hosts
ssh labadmin@10.0.50.15 'sudo cp /tmp/hosts /etc/hosts'
```

**Understanding these commands:**

1. **scp** = Secure Copy (over SSH)
   - `source` → `destination`
   - Can copy between machines

2. **ssh** = Secure Shell
   - `'command'` = Run command on remote machine
   - Requires authentication

**First time connecting:**

```
The authenticity of host '10.0.50.12 (10.0.50.12)' can't be established.
ED25519 key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
```

Type `yes` and press Enter.

**Enter password when prompted** (same labadmin password)

---

### Task 3.3: Configure Time Synchronization

**Why Time Matters:**

Accurate time is **critical** for:
- **Kerberos authentication** (5-minute time skew limit!)
- **SSL/TLS certificates** (validity checking)
- **Log correlation** (events across servers)
- **Distributed databases** (conflict resolution)

**We'll use systemd-timesyncd (built into Ubuntu).**

---

#### Step 1: Configure timesyncd

**On each server, edit:**

```bash
sudo nano /etc/systemd/timesyncd.conf
```

**Uncomment and modify:**

```ini
[Time]
NTP=time.google.com time.cloudflare.com
FallbackNTP=ntp.ubuntu.com
```

**Understanding:**
- **NTP** = Primary time servers
- **FallbackNTP** = Backup servers
- Google and Cloudflare are reliable, globally distributed

**Save and exit**

---

#### Step 2: Restart timesyncd Service

```bash
sudo systemctl restart systemd-timesyncd
```

**Check status:**

```bash
sudo systemctl status systemd-timesyncd
```

Expected output:
```
● systemd-timesyncd.service - Network Time Synchronization
     Loaded: loaded (/lib/systemd/system/systemd-timesyncd.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2024-02-04 15:30:12 UTC; 5s ago
   Main PID: 1234 (systemd-timesyn)
     Status: "Synchronized to time server 216.239.35.0:123 (time.google.com)."
      Tasks: 2 (limit: 4563)
     Memory: 1.2M
        CPU: 45ms
     CGroup: /system.slice/systemd-timesyncd.service
             └─1234 /lib/systemd/systemd-timesyncd
```

**Key info:**
- **Active: active (running)** = Service working
- **Synchronized to...** = Connected to time server
- **time.google.com** = Using our configured server

---

#### Step 3: Verify Time Synchronization

**Check sync status:**

```bash
timedatectl status
```

Expected output:
```
               Local time: Mon 2024-02-04 15:35:42 UTC
           Universal time: Mon 2024-02-04 15:35:42 UTC
                 RTC time: Mon 2024-02-04 15:35:42
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: yes      ← Should be "yes"
              NTP service: active   ← Should be "active"
          RTC in local TZ: no
```

**Important fields:**
- **System clock synchronized: yes** ← Time is synced!
- **NTP service: active** ← timesyncd is running

**If not synchronized:**

```bash
# Force immediate sync
sudo systemctl restart systemd-timesyncd

# Check logs
sudo journalctl -u systemd-timesyncd -n 20
```

---

#### Step 4: Set Correct Timezone

**Current timezone is UTC. Let's set to your local timezone.**

**List available timezones:**

```bash
timedatectl list-timezones | grep America
```

**Example timezones:**
- `America/Toronto` (Eastern Time)
- `America/Vancouver` (Pacific Time)
- `America/New_York` (Eastern Time)
- `America/Chicago` (Central Time)
- `America/Denver` (Mountain Time)
- `America/Los_Angeles` (Pacific Time)

**Set timezone** (replace with your timezone):

```bash
sudo timedatectl set-timezone America/Toronto
```

**Verify:**

```bash
timedatectl status
```

Output should show your timezone:
```
               Local time: Mon 2024-02-04 10:35:42 EST
           Universal time: Mon 2024-02-04 15:35:42 UTC
                 RTC time: Mon 2024-02-04 15:35:42
                Time zone: America/Toronto (EST, -0500)
...
```

**Repeat for all 5 servers!**

**Pro tip:** Use a loop:

```bash
for ip in 12 13 14 15; do
  ssh labadmin@10.0.50.$ip "sudo timedatectl set-timezone America/Toronto"
done
```

---

### Task 3.4: Install Common Tools

**Install useful tools on all servers.**

**Recommended tools:**

| Tool | Purpose | Package Name |
|------|---------|--------------|
| **vim** | Text editor (powerful) | vim |
| **htop** | Interactive process viewer | htop |
| **net-tools** | Network utilities (ifconfig, netstat) | net-tools |
| **curl** | Transfer data from URLs | curl |
| **wget** | Download files | wget |
| **git** | Version control | git |
| **tmux** | Terminal multiplexer | tmux |
| **tree** | Directory visualization | tree |
| **lsof** | List open files | lsof |

**Install on LAB-ID1:**

```bash
sudo apt update
sudo apt install -y vim htop net-tools curl wget git tmux tree lsof dnsutils
```

**Understanding apt install:**
- `-y` = Automatically answer "yes"
- Multiple packages separated by spaces
- Downloads and installs all at once

**Install on all other servers:**

**Method 1: One at a time**

```bash
ssh labadmin@10.0.50.12 'sudo apt update && sudo apt install -y vim htop net-tools curl wget git tmux tree lsof dnsutils'
# Repeat for .13, .14, .15
```

**Method 2: Using a loop (faster)**

```bash
for ip in 12 13 14 15; do
  echo "Installing on 10.0.50.$ip..."
  ssh labadmin@10.0.50.$ip 'sudo apt update && sudo apt install -y vim htop net-tools curl wget git tmux tree lsof dnsutils'
done
```

**Understanding the loop:**
- **for ip in 12 13 14 15** = Loop through these values
- **do** = Start loop body
- **echo** = Print message (so you know which server)
- **ssh** = Run commands on remote server
- **done** = End loop

---

### Task 3.5: Configure Firewall (UFW)

**Understanding UFW (Uncomplicated Firewall):**

UFW is Ubuntu's firewall frontend for iptables. It:
- Blocks all incoming traffic by default (after enabled)
- Allows all outgoing traffic by default
- Requires explicit rules to allow services

**Why firewall?**
- Security: Only expose necessary services
- Best practice: Defense in depth
- Compliance: Many standards require firewalls

---

#### Step 1: Check UFW Status

**On each server:**

```bash
sudo ufw status
```

Expected output:
```
Status: inactive
```

**UFW is installed but not enabled by default.**

---

#### Step 2: Configure Firewall Rules

**⚠️ CRITICAL: Configure SSH FIRST before enabling!**

Otherwise, you'll lock yourself out!

**On each server:**

```bash
# Allow SSH (port 22)
sudo ufw allow 22/tcp comment 'SSH access'

# Allow ping (ICMP)
sudo ufw allow proto icmp comment 'Allow ping'

# Allow from local subnet (10.0.50.0/24)
sudo ufw allow from 10.0.50.0/24 comment 'Local network'
```

**Understanding these rules:**
1. **allow 22/tcp** = Allow TCP port 22 (SSH)
2. **allow proto icmp** = Allow ping packets
3. **allow from 10.0.50.0/24** = Allow ALL traffic from our servers

**Why allow entire subnet?**
- Servers need to communicate freely with each other
- Simplifies configuration
- Frontend proxy (LAB-PROXY1) will be the public-facing hardened point

---

#### Step 3: Enable Firewall

```bash
sudo ufw enable
```

Output:
```
Command may disrupt existing ssh connections. Proceed with operation (y|n)? y
Firewall is active and enabled on system startup
```

Type `y` and press Enter

---

#### Step 4: Verify Firewall

```bash
sudo ufw status verbose
```

Expected output:
```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere                   # SSH access
ICMP                       ALLOW IN    Anywhere                   # Allow ping
Anywhere                   ALLOW IN    10.0.50.0/24               # Local network
```

**Understanding:**
- **Status: active** = Firewall running
- **Default: deny (incoming)** = Blocks all incoming unless explicitly allowed
- **Default: allow (outgoing)** = Allows all outgoing
- Three rules active (SSH, ping, local network)

---

#### Step 5: Test Firewall

**From your laptop (or another server):**

```bash
# Should work (SSH allowed)
ssh labadmin@10.0.50.11

# Should work (ping allowed)
ping -c 2 10.0.50.11
```

**Both should succeed!**

**Repeat firewall configuration for all 5 servers.**

---

### Task 3.6: Network Verification Tests

**Run comprehensive network tests to ensure everything works.**

---

#### Test 1: Server-to-Server Connectivity

**From LAB-ID1, test connectivity to all other servers:**

```bash
# Ping test
for ip in 12 13 14 15; do
  echo "Testing 10.0.50.$ip..."
  ping -c 2 10.0.50.$ip
done
```

**All pings should succeed with 0% packet loss.**

---

#### Test 2: DNS Resolution

**Test hostname resolution:**

```bash
# Short names
ping -c 2 lab-db1
ping -c 2 lab-app1

# FQDNs
ping -c 2 lab-comm1.lab.local
ping -c 2 lab-proxy1.lab.local

# Internet
ping -c 2 google.com
```

**All should resolve and respond.**

---

#### Test 3: Port Connectivity

**Test if you can connect to SSH ports:**

```bash
# Install telnet (for port testing)
sudo apt install -y telnet

# Test SSH port on all servers
for ip in 11 12 13 14 15; do
  echo "Testing SSH on 10.0.50.$ip..."
  telnet 10.0.50.$ip 22
  # Press Ctrl+] then type 'quit' to exit telnet
done
```

**Expected:**
```
Trying 10.0.50.12...
Connected to 10.0.50.12.
Escape character is '^]'.
SSH-2.0-OpenSSH_9.3p1 Ubuntu-3ubuntu3
```

If you see "SSH-2.0-OpenSSH", the port is open!

---

#### Test 4: Internet Connectivity

**Verify external access:**

```bash
# DNS resolution
nslookup google.com

# HTTP access
curl -I https://google.com

# Download test
wget -O /dev/null http://speedtest.tele2.net/1MB.zip
```

**All should succeed without errors.**

---

#### Test 5: Network Performance

**Test bandwidth between servers:**

**Install iperf3:**

```bash
# On all servers
sudo apt install -y iperf3
```

**On LAB-DB1 (server mode):**

```bash
iperf3 -s
```

Output:
```
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
```

**On LAB-ID1 (client mode):**

```bash
iperf3 -c 10.0.50.12 -t 10
```

**Understanding:**
- `-s` = Server mode (listens)
- `-c 10.0.50.12` = Client mode (connects to server)
- `-t 10` = Test for 10 seconds

Expected output:
```
Connecting to host 10.0.50.12, port 5201
[  5] local 10.0.50.11 port 54321 connected to 10.0.50.12 port 5201
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  1.10 GBytes   941 Mbits/sec    0   sender
[  5]   0.00-10.04  sec  1.10 GBytes   938 Mbits/sec        receiver
```

**Look for:**
- **Bitrate ~900+ Mbits/sec** = Gigabit Ethernet working!
- **Retr = 0** = No retransmissions (good quality)

**Stop iperf3 server:** Press Ctrl+C

---

**✅ Network Configuration Complete!**

**What you've accomplished:**
- ✅ Enhanced Netplan configuration on all servers
- ✅ Configured /etc/hosts for local DNS
- ✅ Synchronized time across all servers
- ✅ Installed essential tools
- ✅ Configured and enabled firewall
- ✅ Verified full network connectivity
- ✅ Tested network performance

**Your infrastructure is now ready for service installation!**

---

**Continue to Exercise 4: FreeIPA Identity Management...**

[Due to length constraints, the lab manual would continue with detailed exercises for each service installation: FreeIPA, PostgreSQL, Keycloak, Nextcloud, Mattermost, Jitsi, iRedMail, Traefik, Zammad, monitoring, and integration testing - all following the same educational style with command-by-command explanations, verification steps, and troubleshooting guidance]
