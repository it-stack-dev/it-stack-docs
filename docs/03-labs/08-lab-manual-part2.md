---
doc: 08
title: "Lab Manual Part 2: Identity, Database & SSO"
category: labs
date: 2026-02-27
source: labs/part2-identity-database.md
---
# Enterprise Open-Source IT Infrastructure Lab
# Complete Deployment Manual - Part 2: Service Installation
**Educational Lab Manual with Complete CLI Instructions**

---

**Part 2 Contents:**
- Exercise 4: FreeIPA Identity Management
- Exercise 5: PostgreSQL Database Server
- Exercise 6: Keycloak SSO Installation
- Exercise 7: Nextcloud Collaboration Platform
- Exercise 8: Mattermost Team Chat
- Exercise 9: Jitsi Video Conferencing
- Exercise 10: Email Server with iRedMail
- Exercise 11: Traefik Reverse Proxy
- Exercise 12: Zammad Help Desk System
- Exercise 13: SSO Integration & Testing
- Exercise 14: Monitoring and Logging
- Final Testing and Verification
- Troubleshooting Guide
- Command Quick Reference

---

## Exercise 4: FreeIPA Identity Management

### Understanding Identity Management

**What is Identity Management?**

Identity Management (IdM) is a centralized system for managing:
- **Users** (who can access systems)
- **Groups** (collections of users)
- **Authentication** (proving who you are)
- **Authorization** (what you're allowed to do)
- **Policies** (rules that govern access)

**What is FreeIPA?**

FreeIPA is an integrated security information management solution that combines:
- **LDAP** (Lightweight Directory Access Protocol) - Directory database
- **Kerberos** (MIT Kerberos 5) - Secure authentication
- **DNS** (BIND) - Name resolution
- **Certificate Authority** (Dogtag) - SSL/TLS certificates
- **NTP** (chrony) - Time synchronization

**Why FreeIPA?**

In enterprise environments:
- **Single source of truth** for all user accounts
- **Centralized authentication** - users login once, access all services
- **Strong security** with Kerberos (encrypted authentication tickets)
- **Built-in DNS** for service discovery
- **Self-service** password management
- **Role-based access control**

**FreeIPA vs Active Directory:**

| Feature | FreeIPA | Active Directory |
|---------|---------|------------------|
| Cost | Free, open-source | Windows Server licensing required |
| Platform | Linux/Unix | Windows (can integrate with Linux) |
| Protocol | LDAP, Kerberos | LDAP, Kerberos, AD-specific |
| GUI | Web-based | Windows-based tools |
| Integration | Linux-native | Windows-native |

**Real-World Use:**
- Red Hat Enterprise Linux's official IdM solution
- Used by universities, government agencies, tech companies
- Manages thousands of users in production environments
- Foundation for our entire infrastructure (all services authenticate here)

**Time Required:** 2-3 hours

---

### Task 4.1: Prepare FreeIPA Server

**Server:** LAB-ID1 (10.0.50.11)

**Why this server?**
- Identity services are critical infrastructure
- Should be first server configured
- Other services depend on it
- Dual-purpose: FreeIPA + Keycloak (SSO gateway)

---

#### Step 1: Pre-Installation Requirements Check

**Critical Requirements for FreeIPA:**

1. **Fully Qualified Domain Name (FQDN)**
2. **Static IP address**
3. **Correct hostname resolution**
4. **Time synchronization**
5. **Ports available**

**Let's verify each:**

**1. Check FQDN:**

```bash
hostname -f
```

Expected output:
```
lab-id1.lab.local
```

**Understanding:**
- `hostname -f` = Full hostname (FQDN)
- Must have domain portion (`.lab.local`)
- FreeIPA requires FQDN, not just hostname

**If incorrect:**

```bash
sudo hostnamectl set-hostname lab-id1.lab.local
```

---

**2. Verify Static IP:**

```bash
ip addr show ens160 | grep "inet "
```

Expected output:
```
    inet 10.0.50.11/24 brd 10.0.50.255 scope global ens160
```

**Understanding:**
- Must be static, not DHCP
- FreeIPA DNS requires predictable IP
- We configured this during installation ✓

---

**3. Check Hostname Resolution:**

```bash
# Forward lookup (name → IP)
ping -c 2 lab-id1.lab.local

# Check what IP it resolves to
getent hosts lab-id1.lab.local
```

Expected output:
```
10.0.50.11      lab-id1.lab.local lab-id1
```

**Understanding:**
- `getent hosts` = Query hostname resolution
- Should return 10.0.50.11
- Uses /etc/hosts (we configured this) ✓

---

**4. Verify Time Synchronization:**

```bash
timedatectl status
```

Expected output:
```
               Local time: Mon 2024-02-04 10:45:12 EST
           Universal time: Mon 2024-02-04 15:45:12 UTC
                 RTC time: Mon 2024-02-04 15:45:12
                Time zone: America/Toronto (EST, -0500)
System clock synchronized: yes    ← Must be "yes"
              NTP service: active  ← Must be "active"
          RTC in local TZ: no
```

**Critical:** Kerberos requires time sync within 5 minutes across all machines!

**If not synchronized:**

```bash
sudo systemctl restart systemd-timesyncd
sudo timedatectl set-ntp true
```

---

**5. Check Required Ports:**

```bash
# List listening ports
sudo ss -tulpn | grep LISTEN
```

**Ports FreeIPA will use:**
- **80** (HTTP)
- **443** (HTTPS)
- **389** (LDAP)
- **636** (LDAPS)
- **88** (Kerberos)
- **464** (Kerberos password change)
- **53** (DNS)
- **123** (NTP)

**These should NOT be in use yet** (FreeIPA will bind to them)

---

#### Step 2: Update System and Install Dependencies

**Update all packages first:**

```bash
sudo apt update
sudo apt upgrade -y
```

**Install required packages:**

```bash
sudo apt install -y \
  freeipa-server \
  freeipa-server-dns \
  python3-pip \
  bind9-dnsutils
```

**Understanding packages:**
- **freeipa-server** - Core FreeIPA components
- **freeipa-server-dns** - Integrated DNS server
- **python3-pip** - Python package manager (FreeIPA uses Python)
- **bind9-dnsutils** - DNS testing tools (dig, nslookup)

**This takes 5-10 minutes** (downloading ~300 MB)

---

#### Step 3: Configure Firewall for FreeIPA

**Open required ports:**

```bash
# HTTP/HTTPS (Web UI)
sudo ufw allow 80/tcp comment 'FreeIPA HTTP'
sudo ufw allow 443/tcp comment 'FreeIPA HTTPS'

# LDAP/LDAPS (Directory)
sudo ufw allow 389/tcp comment 'FreeIPA LDAP'
sudo ufw allow 636/tcp comment 'FreeIPA LDAPS'

# Kerberos
sudo ufw allow 88/tcp comment 'Kerberos KDC'
sudo ufw allow 88/udp comment 'Kerberos KDC'
sudo ufw allow 464/tcp comment 'Kerberos password change'
sudo ufw allow 464/udp comment 'Kerberos password change'

# DNS
sudo ufw allow 53/tcp comment 'FreeIPA DNS'
sudo ufw allow 53/udp comment 'FreeIPA DNS'

# NTP
sudo ufw allow 123/udp comment 'FreeIPA NTP'

# Reload firewall
sudo ufw reload
```

**Verify rules:**

```bash
sudo ufw status numbered
```

---

### Task 4.2: Install and Configure FreeIPA

**This is the main installation process.**

---

#### Step 1: Run FreeIPA Installer

**The FreeIPA installer is interactive. We'll use it in unattended mode for reproducibility.**

**Create installation command:**

```bash
sudo ipa-server-install \
  --domain=lab.local \
  --realm=LAB.LOCAL \
  --ds-password='LabDirectory2024!' \
  --admin-password='LabAdmin2024!' \
  --hostname=lab-id1.lab.local \
  --ip-address=10.0.50.11 \
  --setup-dns \
  --forwarder=8.8.8.8 \
  --forwarder=1.1.1.1 \
  --reverse-zone=50.0.10.in-addr.arpa \
  --no-ntp \
  --unattended
```

**⚠️ IMPORTANT: Understanding Each Parameter**

| Parameter | Value | Explanation |
|-----------|-------|-------------|
| `--domain` | lab.local | DNS domain name (lowercase) |
| `--realm` | LAB.LOCAL | Kerberos realm (UPPERCASE, convention) |
| `--ds-password` | LabDirectory2024! | Directory Manager password (LDAP admin) |
| `--admin-password` | LabAdmin2024! | FreeIPA admin user password |
| `--hostname` | lab-id1.lab.local | This server's FQDN |
| `--ip-address` | 10.0.50.11 | This server's IP |
| `--setup-dns` | (flag) | Install and configure DNS server |
| `--forwarder` | 8.8.8.8, 1.1.1.1 | External DNS for unknown domains |
| `--reverse-zone` | 50.0.10.in-addr.arpa | Reverse DNS zone (IP→hostname) |
| `--no-ntp` | (flag) | Don't configure NTP (we already did) |
| `--unattended` | (flag) | Don't ask questions, use defaults |

**Understanding Reverse Zone Name:**

For network `10.0.50.0/24`:
- Take network portion: `10.0.50`
- Reverse it: `50.0.10`
- Append `.in-addr.arpa`: `50.0.10.in-addr.arpa`

**Passwords Used:**

⚠️ **Write these down! You'll need them!**

| Account | Password | Purpose |
|---------|----------|---------|
| Directory Manager | LabDirectory2024! | LDAP database admin (recovery) |
| admin | LabAdmin2024! | FreeIPA admin user (daily use) |

**In production:** Use much stronger passwords! These are educational examples.

---

**Run the installer:**

```bash
sudo ipa-server-install \
  --domain=lab.local \
  --realm=LAB.LOCAL \
  --ds-password='LabDirectory2024!' \
  --admin-password='LabAdmin2024!' \
  --hostname=lab-id1.lab.local \
  --ip-address=10.0.50.11 \
  --setup-dns \
  --forwarder=8.8.8.8 \
  --forwarder=1.1.1.1 \
  --reverse-zone=50.0.10.in-addr.arpa \
  --no-ntp \
  --unattended
```

---

#### Step 2: Monitor Installation Progress

**Installation takes 20-30 minutes.** You'll see output like:

```
The log file for this installation can be found in /var/log/ipaserver-install.log
==============================================================================
This program will set up the FreeIPA Server.
Version 4.11.0

This includes:
  * Configure a stand-alone CA (dogtag) for certificate management
  * Configure the NTP client (chronyd)
  * Create and configure an instance of Directory Server
  * Create and configure a Kerberos Key Distribution Center (KDC)
  * Configure Apache (httpd)
  * Configure DNS (bind)
  * Configure SID generation
  * Configure the KDC to enable PKINIT

To accept the default shown in brackets, press the Enter key.

WARNING: conflicting time&date synchronization service 'chronyd' will be disabled
in favor of ntpd

==============================================================================
```

**Phases you'll see:**

1. **Preparing installation** (2 minutes)
   - Checking requirements
   - Configuring hostname
   - Setting up logging

2. **Configuring directory server** (5 minutes)
   - Creating LDAP database
   - Setting up replication infrastructure
   - Configuring directory structure

3. **Configuring certificate server** (8 minutes)
   - Installing Dogtag CA
   - Creating SSL certificates
   - Setting up certificate database

4. **Configuring Kerberos KDC** (3 minutes)
   - Creating Kerberos database
   - Generating keys
   - Creating admin principal

5. **Configuring Apache web server** (2 minutes)
   - Setting up web UI
   - Configuring SSL
   - Creating virtual hosts

6. **Configuring DNS server** (5 minutes)
   - Setting up BIND
   - Creating DNS zones
   - Configuring forwarders

7. **Finalizing installation** (5 minutes)
   - Starting services
   - Configuring DNS records
   - Running final checks

**Watch for errors:** Installation should complete without failures.

**Final output:**

```
==============================================================================
Setup complete

Next steps:
	1. You must make sure these network ports are open:
		TCP Ports:
		  * 80, 443: HTTP/HTTPS
		  * 389, 636: LDAP/LDAPS
		  * 88, 464: kerberos
		  * 53: bind
		UDP Ports:
		  * 88, 464: kerberos
		  * 53: bind
		  * 123: ntp

	2. You can now obtain a kerberos ticket using the command: 'kinit admin'
	   This ticket will allow you to use the IPA tools (e.g., ipa user-add)
	   and the web user interface.

Be sure to back up the CA certificates stored in /root/cacert.p12
These files are required to create replicas. The password for these
files is the Directory Manager password
The ipa-server-install command was successful
```

**✅ Success indicators:**
- "Setup complete" message
- "The ipa-server-install command was successful"
- No error messages in output

**If installation fails:**
- Check `/var/log/ipaserver-install.log`
- Verify hostname, DNS, and network settings
- Uninstall and retry: `sudo ipa-server-install --uninstall`

---

#### Step 3: Verify FreeIPA Installation

**1. Check services are running:**

```bash
ipactl status
```

Expected output:
```
Directory Service: RUNNING
krb5kdc Service: RUNNING
kadmin Service: RUNNING
httpd Service: RUNNING
ipa-custodia Service: RUNNING
pki-tomcatd Service: RUNNING
ipa-otpd Service: RUNNING
ipa-dnskeysyncd Service: RUNNING
named Service: RUNNING
ipa: FreeIPA server is running
```

**Understanding services:**

| Service | Purpose |
|---------|---------|
| Directory Service | LDAP database (389 Directory Server) |
| krb5kdc | Kerberos authentication server |
| kadmin | Kerberos admin interface |
| httpd | Apache web server (Web UI) |
| ipa-custodia | Secrets management |
| pki-tomcatd | Certificate Authority |
| ipa-otpd | One-Time Password daemon |
| ipa-dnskeysyncd | DNSSEC key synchronization |
| named | DNS server (BIND) |

**All should show "RUNNING"**

---

**2. Obtain Kerberos ticket:**

```bash
kinit admin
```

Prompt:
```
Password for admin@LAB.LOCAL: [enter LabAdmin2024!]
```

**Understanding:**
- `kinit` = Kerberos initialize (get authentication ticket)
- `admin` = Username
- `@LAB.LOCAL` = Kerberos realm (auto-appended)
- Ticket stored in `/tmp/krb5cc_[uid]`

**Verify ticket:**

```bash
klist
```

Expected output:
```
Ticket cache: KCM:1000
Default principal: admin@LAB.LOCAL

Valid starting       Expires              Service principal
02/04/2024 11:00:12  02/05/2024 11:00:12  krbtgt/LAB.LOCAL@LAB.LOCAL
```

**Understanding output:**
- **Default principal** = Your authenticated identity
- **Valid starting** = When ticket became valid
- **Expires** = When ticket expires (24 hours default)
- **Service principal** = Ticket Granting Ticket (TGT)

**Ticket allows you to run IPA commands without re-entering password!**

---

**3. Test IPA command-line tools:**

```bash
# Show server information
ipa config-show
```

Expected output (abbreviated):
```
  Maximum username length: 32
  Home directory base: /home
  Default shell: /bin/bash
  Default users group: ipausers
  Default e-mail domain: lab.local
  ...
```

**List users:**

```bash
ipa user-find
```

Expected output:
```
--------------
1 user matched
--------------
  User login: admin
  Last name: Administrator
  Home directory: /home/admin
  Login shell: /bin/bash
  Principal alias: admin@LAB.LOCAL
  UID: 1234000000
  GID: 1234000000
  Account disabled: False
----------------------------
Number of entries returned 1
----------------------------
```

**Only `admin` user exists initially** (created during install)

---

**4. Test DNS:**

**Check DNS zones:**

```bash
ipa dnszone-find
```

Expected output:
```
---------------
2 zones matched
---------------
  Zone name: lab.local.
  Authoritative nameserver: lab-id1.lab.local.
  Administrator e-mail address: hostmaster.lab.local.
  SOA serial: 1707053412
  SOA refresh: 3600
  SOA retry: 900
  SOA expire: 1209600
  SOA minimum: 3600
  Active zone: TRUE
  
  Zone name: 50.0.10.in-addr.arpa.
  Authoritative nameserver: lab-id1.lab.local.
  ... (reverse zone details)
----------------------------
Number of entries returned 2
----------------------------
```

**Understanding:**
- **lab.local.** = Forward zone (name → IP)
- **50.0.10.in-addr.arpa.** = Reverse zone (IP → name)
- Both zones are active ✓

---

**5. Test DNS resolution:**

**Query FreeIPA DNS server:**

```bash
# Using dig (DNS lookup tool)
dig @localhost lab-id1.lab.local
```

Expected output:
```
; <<>> DiG 9.18.18-0ubuntu0.22.04.1-Ubuntu <<>> @localhost lab-id1.lab.local
;; QUESTION SECTION:
;lab-id1.lab.local.		IN	A

;; ANSWER SECTION:
lab-id1.lab.local.	1200	IN	A	10.0.50.11

;; Query time: 2 msec
;; SERVER: 127.0.0.1#53(localhost) (UDP)
;; WHEN: Mon Feb 04 11:15:45 EST 2024
;; MSG SIZE  rcvd: 62
```

**Understanding output:**
- **QUESTION** = What we asked for
- **ANSWER** = Response (10.0.50.11) ✓
- **Query time** = How fast (should be <10ms)
- **SERVER** = Who answered (localhost = FreeIPA DNS)

**Test reverse lookup:**

```bash
dig @localhost -x 10.0.50.11
```

Expected output:
```
;; ANSWER SECTION:
11.50.0.10.in-addr.arpa. 1200	IN	PTR	lab-id1.lab.local.
```

**Understanding:**
- `-x` flag = Reverse lookup
- PTR record points 10.0.50.11 back to lab-id1.lab.local ✓

---

**6. Access Web UI:**

**From your laptop/workstation:**

1. **Add to your laptop's /etc/hosts:**
   
   **Linux/Mac:**
   ```bash
   sudo nano /etc/hosts
   ```
   
   Add:
   ```
   10.0.50.11  lab-id1.lab.local ipa.lab.local
   ```
   
   **Windows:**
   - Open Notepad as Administrator
   - File → Open → `C:\Windows\System32\drivers\etc\hosts`
   - Add same line
   - Save

2. **Open browser:**
   
   Navigate to: `https://ipa.lab.local`
   
   **You'll see SSL certificate warning** (expected - self-signed cert)
   
   **Firefox:** Click "Advanced" → "Accept the Risk and Continue"
   
   **Chrome:** Click "Advanced" → "Proceed to ipa.lab.local"

3. **Login screen appears:**
   
   ```
   FreeIPA Web UI
   
   Username: admin
   Password: [LabAdmin2024!]
   ```
   
   **Login!**

4. **You should see FreeIPA Dashboard:**
   
   - Identity tab (Users, Groups, Hosts)
   - Policy tab (HBAC, Sudo, SELinux)
   - Authentication tab (Certificates, OTP)
   - Network Services tab (DNS, Automount)

**Congratulations! FreeIPA Web UI is working!**

---

### Task 4.3: Configure DNS for Other Servers

**Now we'll add DNS records for all our servers.**

**Why?**
- Services will use FreeIPA as DNS server
- Enables discovery via hostname (not just IP)
- Required for Kerberos hostname verification

---

#### Step 1: Add DNS A Records (Name → IP)

**From LAB-ID1 terminal (with Kerberos ticket active):**

```bash
# Verify you have a ticket
klist

# If expired or not present:
kinit admin
```

**Add server DNS records:**

```bash
# LAB-ID1 (already exists, verify)
ipa dnsrecord-show lab.local lab-id1

# LAB-DB1
ipa dnsrecord-add lab.local lab-db1 \
  --a-rec=10.0.50.12 \
  --a-create-reverse

# LAB-APP1
ipa dnsrecord-add lab.local lab-app1 \
  --a-rec=10.0.50.13 \
  --a-create-reverse

# LAB-COMM1
ipa dnsrecord-add lab.local lab-comm1 \
  --a-rec=10.0.50.14 \
  --a-create-reverse

# LAB-PROXY1
ipa dnsrecord-add lab.local lab-proxy1 \
  --a-rec=10.0.50.15 \
  --a-create-reverse
```

**Understanding parameters:**
- **lab.local** = Zone name
- **lab-db1** = Record name (hostname)
- **--a-rec** = A record (Address record)
- **--a-create-reverse** = Also create PTR record automatically

**Expected output for each:**

```
  Record name: lab-db1
  A record: 10.0.50.12
```

---

#### Step 2: Add DNS CNAME Records (Aliases)

**Create service aliases that will point to proxy:**

```bash
# Nextcloud
ipa dnsrecord-add lab.local cloud \
  --cname-rec=lab-proxy1.lab.local.

# Mattermost
ipa dnsrecord-add lab.local chat \
  --cname-rec=lab-proxy1.lab.local.

# Jitsi
ipa dnsrecord-add lab.local meet \
  --cname-rec=lab-proxy1.lab.local.

# Webmail
ipa dnsrecord-add lab.local mail \
  --cname-rec=lab-proxy1.lab.local.

# Help Desk
ipa dnsrecord-add lab.local desk \
  --cname-rec=lab-proxy1.lab.local.

# SSO alias
ipa dnsrecord-add lab.local sso \
  --cname-rec=lab-id1.lab.local.
```

**Understanding CNAME:**
- **CNAME** = Canonical Name (alias)
- `cloud.lab.local` → points to → `lab-proxy1.lab.local`
- Allows moving services without changing DNS names
- Note the trailing dot (`.`) = absolute FQDN

---

#### Step 3: Verify DNS Records

**List all A records:**

```bash
ipa dnsrecord-find lab.local
```

**Test resolution:**

```bash
# Test from FreeIPA server
dig @localhost lab-db1.lab.local
dig @localhost lab-app1.lab.local
dig @localhost cloud.lab.local
```

**All should resolve correctly!**

---

### Task 4.4: Create User Accounts and Groups

**Let's create organizational structure with users and groups.**

**This demonstrates FreeIPA's user management capabilities.**

---

#### Step 1: Create Groups

**Create organizational groups:**

```bash
# Security Guards group
ipa group-add guards \
  --desc="Security Guard Personnel"

# Managers group
ipa group-add managers \
  --desc="Management Staff"

# Office Staff group
ipa group-add office-staff \
  --desc="Back Office Personnel"

# IT Administrators group
ipa group-add it-admins \
  --desc="IT Department"
```

**Expected output for each:**

```
-----------------------
Added group "guards"
-----------------------
  Group name: guards
  Description: Security Guard Personnel
  GID: 1234000001
```

**Verify groups:**

```bash
ipa group-find
```

---

#### Step 2: Create Test Users

**Create users for testing:**

```bash
# Guard users
ipa user-add guard1 \
  --first=John \
  --last=Smith \
  --email=guard1@lab.local \
  --password

# When prompted, enter initial password: TempPass123!
# User must change on first login

ipa user-add guard2 \
  --first=Jane \
  --last=Doe \
  --email=guard2@lab.local \
  --password

# Manager
ipa user-add manager1 \
  --first=Bob \
  --last=Johnson \
  --email=manager1@lab.local \
  --password

# Office staff
ipa user-add office1 \
  --first=Alice \
  --last=Williams \
  --email=office1@lab.local \
  --password

# IT admin
ipa user-add itadmin1 \
  --first=Tech \
  --last=Support \
  --email=itadmin@lab.local \
  --password
```

**Understanding user creation:**
- **--first/--last** = Name fields
- **--email** = Email address (important for services)
- **--password** = Sets initial password interactively
- User forced to change password on first login (security)

---

#### Step 3: Add Users to Groups

```bash
# Add guards to guards group
ipa group-add-member guards \
  --users=guard1,guard2

# Add manager to managers group
ipa group-add-member managers \
  --users=manager1

# Add office staff
ipa group-add-member office-staff \
  --users=office1

# Add IT admin to admin group
ipa group-add-member it-admins \
  --users=itadmin1
```

**Verify membership:**

```bash
# Show guards group members
ipa group-show guards

# Show what groups guard1 belongs to
ipa user-show guard1 --all | grep "Member of groups"
```

---

#### Step 4: Test User Authentication

**From LAB-ID1, test user login:**

```bash
# Get ticket for guard1
kinit guard1
```

Prompt:
```
Password for guard1@LAB.LOCAL: [enter TempPass123!]
Password expired. You must change it now.
Enter new password: [enter new password]
Enter it again: [confirm password]
```

**Understanding:**
- User must change password on first use (security policy)
- After changing, ticket is issued

**Verify ticket:**

```bash
klist
```

Should show:
```
Default principal: guard1@LAB.LOCAL
```

**Log out from guard1:**

```bash
kdestroy  # Destroy Kerberos ticket
```

**Log back in as admin:**

```bash
kinit admin
```

---

### Task 4.5: Configure Other Servers to Use FreeIPA DNS

**Update all servers to use FreeIPA as primary DNS.**

**Why?**
- Enables service discovery
- Required for Kerberos hostname resolution
- Automatic DNS updates when joining domain

---

#### Step 1: Update DNS Configuration on All Servers

**On each server (LAB-DB1, LAB-APP1, LAB-COMM1, LAB-PROXY1):**

**Edit Netplan:**

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

**Change nameservers section:**

```yaml
      nameservers:
        addresses:
          - 10.0.50.11   # FreeIPA DNS (primary)
          - 8.8.8.8      # Google (fallback)
        search:
          - lab.local
```

**Apply changes:**

```bash
sudo netplan apply
```

**Verify DNS resolution:**

```bash
# Should resolve via FreeIPA
dig lab-id1.lab.local

# Should use 10.0.50.11 as server
resolvectl status | grep "DNS Servers"
```

Expected:
```
DNS Servers: 10.0.50.11
             8.8.8.8
```

---

**Automated for all servers from LAB-ID1:**

```bash
# Create script
cat > /tmp/update-dns.sh << 'EOF'
#!/bin/bash
sudo sed -i 's/- 10.0.50.11/# - 10.0.50.11/' /etc/netplan/50-cloud-init.yaml
sudo sed -i '/nameservers:/a\        addresses:\n          - 10.0.50.11\n          - 8.8.8.8' /etc/netplan/50-cloud-init.yaml
sudo netplan apply
EOF

chmod +x /tmp/update-dns.sh

# Deploy to each server
for ip in 12 13 14 15; do
  echo "Updating DNS on 10.0.50.$ip..."
  scp /tmp/update-dns.sh labadmin@10.0.50.$ip:/tmp/
  ssh labadmin@10.0.50.$ip 'bash /tmp/update-dns.sh'
done
```

---

#### Step 2: Test DNS from Each Server

**From each server:**

```bash
# Test FreeIPA DNS works
nslookup lab-id1.lab.local

# Test service aliases
nslookup cloud.lab.local
nslookup chat.lab.local

# Test reverse DNS
nslookup 10.0.50.11
```

**All should resolve correctly!**

---

**✅ FreeIPA Installation Complete!**

**What you've accomplished:**
- ✅ Installed FreeIPA with integrated DNS
- ✅ Configured Kerberos authentication
- ✅ Created forward and reverse DNS zones
- ✅ Added DNS records for all servers
- ✅ Created organizational groups
- ✅ Created test user accounts
- ✅ Configured all servers to use FreeIPA DNS
- ✅ Verified authentication and DNS resolution

**Your infrastructure now has:**
- Centralized identity management (LDAP)
- Secure authentication (Kerberos)
- DNS service discovery
- User and group management
- Foundation for SSO

---

## Exercise 5: PostgreSQL Database Server

### Understanding PostgreSQL

**What is PostgreSQL?**

PostgreSQL (often called "Postgres") is an advanced, open-source relational database management system (RDBMS) known for:
- **ACID compliance** (Atomicity, Consistency, Isolation, Durability)
- **Advanced data types** (JSON, arrays, custom types)
- **Full-text search** capabilities
- **Geographic data** support (PostGIS extension)
- **Excellent performance** and scalability
- **Strong community** and extensive documentation

**Why PostgreSQL for This Stack?**

Most of our applications prefer PostgreSQL:
- **Nextcloud** - Recommended over MySQL
- **Mattermost** - Best performance with PostgreSQL
- **Keycloak** - Officially supports PostgreSQL
- **Zammad** - Optimized for PostgreSQL

**Alternative:** MariaDB/MySQL (also supported, but PostgreSQL is preferred)

**PostgreSQL vs MySQL:**

| Feature | PostgreSQL | MySQL/MariaDB |
|---------|-----------|---------------|
| ACID compliance | Full | Partial (InnoDB engine) |
| Advanced features | Many (JSON, arrays, window functions) | Limited |
| Concurrency | MVCC (excellent) | Lock-based (good) |
| Complex queries | Excellent optimizer | Good optimizer |
| Standards compliance | Very high | Moderate |
| Use case | Complex applications, analytics | Simple CRUD applications |

**Real-World Use:**
- Apple, Instagram, Reddit, Netflix use PostgreSQL
- Handles billions of rows in production
- Our stack will use it for 4+ applications

**Time Required:** 1-2 hours

---

### Task 5.1: Install PostgreSQL

**Server:** LAB-DB1 (10.0.50.12)

**Why dedicated database server?**
- **Performance isolation** - Database I/O doesn't impact apps
- **Resource allocation** - Can tune RAM/CPU for database workload
- **Security** - Database not exposed on same server as web apps
- **Scalability** - Easy to add read replicas or move to bigger server

---

#### Step 1: Install PostgreSQL 16

**SSH to LAB-DB1:**

```bash
ssh labadmin@10.0.50.12
```

**Update package list:**

```bash
sudo apt update
```

**Install PostgreSQL:**

```bash
sudo apt install -y postgresql-16 postgresql-contrib-16 postgresql-client-16
```

**Understanding packages:**
- **postgresql-16** - Database server
- **postgresql-contrib-16** - Additional extensions (pg_stat_statements, etc.)
- **postgresql-client-16** - Client tools (psql, pg_dump)

**Installation takes 2-3 minutes.**

**Verify installation:**

```bash
# Check version
psql --version
```

Expected output:
```
psql (PostgreSQL) 16.1 (Ubuntu 16.1-1.pgdg22.04+1)
```

**Check service status:**

```bash
sudo systemctl status postgresql
```

Expected output:
```
● postgresql.service - PostgreSQL RDBMS
     Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
     Active: active (exited) since Mon 2024-02-04 12:00:15 EST; 2min ago
```

**Understanding PostgreSQL service structure:**

PostgreSQL uses **cluster** concept:
- **Cluster** = Collection of databases managed by one server instance
- Default cluster: `main` running on port 5432
- Can run multiple clusters on different ports

**Check cluster status:**

```bash
pg_lsclusters
```

Expected output:
```
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

---

#### Step 2: Understand PostgreSQL Directory Structure

**Key directories:**

```bash
# Data directory (where databases are stored)
ls -la /var/lib/postgresql/16/main/

# Configuration files
ls -la /etc/postgresql/16/main/

# Log files
ls -la /var/log/postgresql/
```

**Important files:**

| File | Location | Purpose |
|------|----------|---------|
| postgresql.conf | /etc/postgresql/16/main/ | Main configuration |
| pg_hba.conf | /etc/postgresql/16/main/ | Client authentication |
| pg_ident.conf | /etc/postgresql/16/main/ | User name mapping |
| postgresql.log | /var/log/postgresql/ | Database logs |

---

#### Step 3: Secure PostgreSQL Installation

**By default, PostgreSQL:**
- Only accepts connections from localhost
- Uses peer authentication (Unix socket)
- No password required for local postgres user

**We need to:**
1. Set password for postgres superuser
2. Configure for network access
3. Enable password authentication

**Set postgres password:**

```bash
# Switch to postgres user
sudo -u postgres psql
```

**You're now in PostgreSQL prompt:**

```sql
-- Set password for postgres user
ALTER USER postgres WITH PASSWORD 'LabPostgres2024!';

-- Verify
\du
```

Expected output:
```
                             List of roles
 Role name |                         Attributes                         
-----------+------------------------------------------------------------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS
```

**Exit psql:**

```sql
\q
```

---

### Task 5.2: Configure PostgreSQL for Network Access

**By default, PostgreSQL only listens on localhost. We need it to accept connections from application servers.**

---

#### Step 1: Configure Listen Addresses

**Edit postgresql.conf:**

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

**Find the line (around line 64):**

```
#listen_addresses = 'localhost'
```

**Change to:**

```
listen_addresses = '10.0.50.12'
```

**Understanding:**
- `localhost` = Only accept connections from same machine
- `10.0.50.12` = Accept connections on this IP (our server IP)
- `'*'` = Accept on all IPs (less secure, don't use)

**Why specific IP?**
- Security: Only on our internal network interface
- If server has multiple NICs, we control which one
- Best practice for production

---

#### Step 2: Configure Client Authentication

**Edit pg_hba.conf:**

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

**Understanding pg_hba.conf:**

Format:
```
TYPE  DATABASE    USER        ADDRESS         METHOD
```

- **TYPE**: local (Unix socket), host (TCP/IP), hostssl (SSL only)
- **DATABASE**: Which database(s) this rule applies to
- **USER**: Which user(s) this rule applies to
- **ADDRESS**: Client IP address or network
- **METHOD**: Authentication method (peer, md5, scram-sha-256, trust)

**Add at the end of the file:**

```
# Allow connections from application servers
host    all             all             10.0.50.0/24            scram-sha-256
```

**Understanding this rule:**
- **host** = TCP/IP connection
- **all** (database) = Any database
- **all** (user) = Any user
- **10.0.50.0/24** = From our lab subnet
- **scram-sha-256** = Encrypted password authentication

**Why scram-sha-256?**
- **scram-sha-256** = Strongest password authentication (PostgreSQL 10+)
- **md5** = Weaker, deprecated
- **trust** = No password (dangerous!)
- **peer** = Unix user must match database user (local only)

**Save and exit** (Ctrl+X, Y, Enter)

---

#### Step 3: Optimize PostgreSQL Configuration

**Edit postgresql.conf for performance:**

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

**Find and modify these settings:**

```conf
# Memory Settings (for 16GB RAM server)
shared_buffers = 4GB                    # ~25% of RAM
effective_cache_size = 12GB             # ~75% of RAM
work_mem = 16MB                         # Per query operation
maintenance_work_mem = 512MB            # For VACUUM, CREATE INDEX

# Connection Settings
max_connections = 200                   # Concurrent connections

# WAL (Write-Ahead Logging) Settings
wal_buffers = 16MB
checkpoint_completion_target = 0.9

# Query Planner
random_page_cost = 1.1                  # For SSD (default 4.0 for HDD)
effective_io_concurrency = 200          # For SSD

# Logging (important for troubleshooting)
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_line_prefix = '%t [%p]: user=%u,db=%d,app=%a,client=%h '
log_min_duration_statement = 1000       # Log slow queries (>1 second)
log_connections = on
log_disconnections = on
```

**Understanding key settings:**

| Setting | Value | Explanation |
|---------|-------|-------------|
| shared_buffers | 4GB | PostgreSQL's internal cache |
| effective_cache_size | 12GB | OS + PostgreSQL total cache (for planner) |
| work_mem | 16MB | Memory per sort/hash operation |
| max_connections | 200 | Max concurrent clients |
| random_page_cost | 1.1 | SSD cost (lower = faster random access) |
| log_min_duration_statement | 1000ms | Log queries slower than 1 second |

**Save and exit**

---

#### Step 4: Restart PostgreSQL

```bash
sudo systemctl restart postgresql
```

**Check status:**

```bash
sudo systemctl status postgresql
```

Should show "active (exited)" - this is normal for PostgreSQL parent process.

**Check if listening on network:**

```bash
sudo ss -tlnp | grep 5432
```

Expected output:
```
LISTEN 0  200  10.0.50.12:5432  0.0.0.0:*  users:(("postgres",pid=12345,fd=5))
```

**Understanding:**
- Listening on `10.0.50.12:5432` ✓
- Not listening on `0.0.0.0` (all interfaces) ✓ - More secure

---

#### Step 5: Configure Firewall

```bash
sudo ufw allow from 10.0.50.0/24 to any port 5432 proto tcp comment 'PostgreSQL from app servers'
sudo ufw reload
```

**Verify:**

```bash
sudo ufw status
```

---

### Task 5.3: Create Application Databases

**We'll create separate databases for each application.**

**Why separate databases?**
- **Security**: Each app can't access other app's data
- **Resource isolation**: Can set quotas per database
- **Easier backup/restore**: Can backup individually
- **Clear ownership**: Each app has dedicated user

---

#### Step 1: Create Database Users

**Connect to PostgreSQL:**

```bash
sudo -u postgres psql
```

**Create users for each application:**

```sql
-- Nextcloud database user
CREATE USER nextcloud WITH ENCRYPTED PASSWORD 'NextcloudDB2024!';

-- Mattermost database user
CREATE USER mattermost WITH ENCRYPTED PASSWORD 'MattermostDB2024!';

-- Keycloak database user
CREATE USER keycloak WITH ENCRYPTED PASSWORD 'KeycloakDB2024!';

-- Zammad database user
CREATE USER zammad WITH ENCRYPTED PASSWORD 'ZammadDB2024!';

-- Verify users created
\du
```

Expected output:
```
                                   List of roles
 Role name  |                         Attributes                         
------------+------------------------------------------------------------
 keycloak   | 
 mattermost | 
 nextcloud  | 
 postgres   | Superuser, Create role, Create DB, Replication, Bypass RLS
 zammad     | 
```

---

#### Step 2: Create Databases

```sql
-- Create databases
CREATE DATABASE nextcloud OWNER nextcloud ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
CREATE DATABASE mattermost OWNER mattermost ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
CREATE DATABASE keycloak OWNER keycloak ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
CREATE DATABASE zammad_production OWNER zammad ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';

-- List databases
\l
```

**Understanding CREATE DATABASE:**
- **OWNER** = User who owns the database
- **ENCODING 'UTF8'** = Unicode support (international characters)
- **LC_COLLATE** = Sorting rules
- **LC_CTYPE** = Character classification

Expected output:
```
                                        List of databases
       Name        |   Owner    | Encoding |   Collate   |    Ctype    |   Access privileges   
-------------------+------------+----------+-------------+-------------+-----------------------
 keycloak          | keycloak   | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 mattermost        | mattermost | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 nextcloud         | nextcloud  | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres          | postgres   | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 zammad_production | zammad     | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
```

---

#### Step 3: Grant Privileges

```sql
-- Grant all privileges to database owners
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
GRANT ALL PRIVILEGES ON DATABASE mattermost TO mattermost;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
GRANT ALL PRIVILEGES ON DATABASE zammad_production TO zammad;

-- Exit psql
\q
```

---

#### Step 4: Test Remote Connection

**From LAB-ID1 (or any application server):**

**Install PostgreSQL client:**

```bash
sudo apt install -y postgresql-client
```

**Test connection:**

```bash
psql -h 10.0.50.12 -U nextcloud -d nextcloud
```

Prompt:
```
Password for user nextcloud: [enter NextcloudDB2024!]
```

**If successful:**

```
nextcloud=> 
```

**You're connected to the database!**

**Test queries:**

```sql
-- Check version
SELECT version();

-- Check current database
SELECT current_database();

-- Exit
\q
```

**Test from all application servers (LAB-ID1, LAB-APP1, LAB-COMM1):**

```bash
# Test connectivity
pg_isready -h 10.0.50.12 -p 5432
```

Expected output:
```
10.0.50.12:5432 - accepting connections
```

---

### Task 5.4: Install and Configure Redis

**Redis is an in-memory data store used for:**
- **Caching** - Speed up database queries
- **Session storage** - User login sessions
- **Message queuing** - Inter-process communication

**Used by:**
- Nextcloud (caching, transactional file locking)
- Mattermost (session storage, caching)

---

#### Step 1: Install Redis

**On LAB-DB1:**

```bash
sudo apt install -y redis-server
```

**Check status:**

```bash
sudo systemctl status redis-server
```

---

#### Step 2: Configure Redis for Network Access

**Edit Redis configuration:**

```bash
sudo nano /etc/redis/redis.conf
```

**Find and modify:**

```conf
# Bind to specific IP instead of localhost
bind 10.0.50.12 127.0.0.1

# Set password (IMPORTANT!)
requirepass LabRedis2024!

# Maximum memory and eviction policy
maxmemory 2gb
maxmemory-policy allkeys-lru

# Persistence (save to disk)
save 900 1
save 300 10
save 60 10000
```

**Understanding settings:**

| Setting | Value | Explanation |
|---------|-------|-------------|
| bind | 10.0.50.12 127.0.0.1 | Listen on DB server IP + localhost |
| requirepass | Password | Require authentication |
| maxmemory | 2gb | Max RAM Redis can use |
| maxmemory-policy | allkeys-lru | Evict least recently used keys when full |
| save | Intervals | Periodic disk snapshots |

**Save and exit**

---

#### Step 3: Restart Redis

```bash
sudo systemctl restart redis-server
```

**Verify listening:**

```bash
sudo ss -tlnp | grep 6379
```

Expected:
```
LISTEN 0  511  10.0.50.12:6379  0.0.0.0:*  users:(("redis-server",pid=23456))
LISTEN 0  511  127.0.0.1:6379   0.0.0.0:*  users:(("redis-server",pid=23456))
```

---

#### Step 4: Configure Firewall for Redis

```bash
sudo ufw allow from 10.0.50.0/24 to any port 6379 proto tcp comment 'Redis from app servers'
sudo ufw reload
```

---

#### Step 5: Test Redis Connection

**From LAB-APP1:**

```bash
# Install redis-tools
sudo apt install -y redis-tools

# Test connection
redis-cli -h 10.0.50.12 -a 'LabRedis2024!'
```

**If connected:**

```
10.0.50.12:6379>
```

**Test commands:**

```
# Set a key
SET test "Hello from LAB-APP1"

# Get a key
GET test

# Check server info
INFO server

# Exit
quit
```

---

**✅ PostgreSQL and Redis Installation Complete!**

**What you've accomplished:**
- ✅ Installed PostgreSQL 16
- ✅ Configured for network access
- ✅ Optimized performance settings
- ✅ Created 4 application databases
- ✅ Created database users with privileges
- ✅ Installed and configured Redis
- ✅ Secured both services with passwords
- ✅ Tested connectivity from application servers

**Your database infrastructure is ready!**

**Summary of Database Resources:**

| Database | User | Password | Used By |
|----------|------|----------|---------|
| nextcloud | nextcloud | NextcloudDB2024! | Nextcloud |
| mattermost | mattermost | MattermostDB2024! | Mattermost |
| keycloak | keycloak | KeycloakDB2024! | Keycloak |
| zammad_production | zammad | ZammadDB2024! | Zammad |
| Redis | — | LabRedis2024! | Multiple apps |

**Connection strings for applications:**

```
PostgreSQL: postgresql://user:password@10.0.50.12:5432/database
Redis: redis://:LabRedis2024!@10.0.50.12:6379
```

---

## Exercise 6: Keycloak SSO Installation

### Understanding Single Sign-On (SSO)

**What is Single Sign-On?**

SSO allows users to:
- **Log in once** → Access multiple applications
- **One set of credentials** → Works everywhere
- **Centralized management** → Admins control access in one place

**Example User Experience:**

Without SSO:
```
User logs into Nextcloud     → Enter username/password
User logs into Mattermost    → Enter username/password again
User logs into Email         → Enter username/password again
User logs into Help Desk     → Enter username/password again
```

With SSO:
```
User logs into SSO portal    → Enter username/password ONCE
User accesses Nextcloud      → Automatically logged in
User accesses Mattermost     → Automatically logged in
User accesses Email          → Automatically logged in
User accesses Help Desk      → Automatically logged in
```

---

**What is Keycloak?**

Keycloak is an open-source Identity and Access Management solution providing:
- **SSO** (Single Sign-On)
- **Identity Brokering** (social login, enterprise SSO)
- **User Federation** (LDAP, Active Directory integration)
- **Standard Protocols** (OAuth 2.0, OpenID Connect, SAML)
- **Multi-factor Authentication** (OTP, WebAuthn)
- **User Management** (self-service, admin console)

**Keycloak Architecture:**

```
┌─────────────────────────────────────────────────┐
│              User's Browser                     │
└───────────┬─────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────┐
│              Keycloak (SSO Gateway)             │
│  • Authenticates user                           │
│  • Issues tokens                                │
│  • Manages sessions                             │
└───────────┬────────────────┬────────────────────┘
            │                │
            ▼                ▼
    ┌───────────────┐  ┌───────────────┐
    │  Nextcloud    │  │  Mattermost   │  (Applications)
    │  (trusts      │  │  (trusts      │
    │   Keycloak)   │  │   Keycloak)   │
    └───────────────┘  └───────────────┘
            │
            ▼
    ┌───────────────┐
    │   FreeIPA     │  (User Directory)
    │  (LDAP + Kerb)│
    └───────────────┘
```

**How SSO Works (Simplified):**

1. User tries to access Nextcloud
2. Nextcloud redirects to Keycloak login page
3. User enters credentials
4. Keycloak verifies with FreeIPA LDAP
5. Keycloak issues **token** (proof of authentication)
6. Nextcloud receives token, trusts it, grants access
7. When user accesses Mattermost:
   - Mattermost sees existing Keycloak session
   - User automatically logged in (no re-authentication!)

**Time Required:** 2-3 hours

---

### Task 6.1: Install Keycloak Prerequisites

**Server:** LAB-ID1 (10.0.50.11)

**Why same server as FreeIPA?**
- Keycloak queries FreeIPA LDAP frequently (low latency)
- Both are identity services (logical grouping)
- In production, you might separate for scalability

---

#### Step 1: Install Java

**Keycloak requires Java 17+**

```bash
# SSH to LAB-ID1
ssh labadmin@10.0.50.11

# Install OpenJDK 17
sudo apt install -y openjdk-17-jdk openjdk-17-jre
```

**Verify installation:**

```bash
java -version
```

Expected output:
```
openjdk version "17.0.9" 2023-10-17
OpenJDK Runtime Environment (build 17.0.9+9-Ubuntu-122.04)
OpenJDK 64-Bit Server VM (build 17.0.9+9-Ubuntu-122.04, mixed mode, sharing)
```

---

#### Step 2: Create Keycloak Database

**On LAB-DB1:**

```bash
ssh labadmin@10.0.50.12
sudo -u postgres psql
```

**Create database (if not already created in Exercise 5):**

```sql
-- Create database
CREATE DATABASE keycloak OWNER keycloak ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';

-- Verify
\l keycloak

-- Exit
\q
```

**Test connection from LAB-ID1:**

```bash
psql -h 10.0.50.12 -U keycloak -d keycloak
# Enter password: KeycloakDB2024!
# Should connect successfully
\q
```

---

### Task 6.2: Install Keycloak

**Back on LAB-ID1:**

---

#### Step 1: Download Keycloak

```bash
cd /opt
sudo wget https://github.com/keycloak/keycloak/releases/download/24.0.0/keycloak-24.0.0.tar.gz
```

**Verify download:**

```bash
ls -lh keycloak-24.0.0.tar.gz
```

Expected: ~200 MB file

---

#### Step 2: Extract and Set Permissions

```bash
# Extract
sudo tar -xzf keycloak-24.0.0.tar.gz

# Rename for cleaner path
sudo mv keycloak-24.0.0 keycloak

# Create keycloak system user
sudo useradd -r -s /bin/false keycloak

# Set ownership
sudo chown -R keycloak:keycloak /opt/keycloak
```

**Understanding:**
- `-r` = System user (no login shell)
- `-s /bin/false` = Can't login interactively (security)
- Keycloak process runs as this user (not root)

---

#### Step 3: Configure Keycloak

**Create configuration file:**

```bash
sudo nano /opt/keycloak/conf/keycloak.conf
```

**Add this configuration:**

```properties
# Database configuration
db=postgres
db-url=jdbc:postgresql://10.0.50.12:5432/keycloak
db-username=keycloak
db-password=KeycloakDB2024!
db-pool-initial-size=20
db-pool-min-size=10
db-pool-max-size=100

# HTTP/HTTPS configuration
hostname=sso.lab.local
http-enabled=true
http-port=8080
https-port=8443
proxy=edge

# Clustering (single node for now)
cache=local

# Logging
log=console,file
log-level=info
```

**Understanding configuration:**

| Setting | Value | Explanation |
|---------|-------|-------------|
| db | postgres | Database type |
| db-url | jdbc:postgresql://... | Connection string to LAB-DB1 |
| hostname | sso.lab.local | Public hostname |
| http-enabled | true | Allow HTTP (Traefik will add HTTPS) |
| http-port | 8080 | Internal port |
| proxy | edge | Behind reverse proxy (Traefik) |
| cache | local | No distributed cache (single node) |

**Save and exit**

---

#### Step 4: Build Keycloak

**Keycloak requires a "build" step to optimize:**

```bash
cd /opt/keycloak
sudo -u keycloak ./bin/kc.sh build
```

**This takes 1-2 minutes.** Output:

```
Updating the configuration and installing your custom providers, if any. Please wait.
2024-02-04 13:00:12,345 INFO  [org.keycloak.quarkus.runtime.cli.command.Build] Updating the configuration and installing your custom providers, if any. Please wait.
...
2024-02-04 13:01:45,678 INFO  [org.keycloak.quarkus.runtime.cli.command.Build] Server configuration updated and persisted. Run the following command to review the configuration:

    kc.sh show-config

Next time you run the server, just run:

    kc.sh start --optimized

```

**Understanding:**
- **build** = Prepares configuration, optimizes for production
- **--optimized** = Skip build phase on future starts (faster)

---

### Task 6.3: Create Keycloak Service

**Create systemd service for automatic start:**

```bash
sudo nano /etc/systemd/system/keycloak.service
```

**Add:**

```ini
[Unit]
Description=Keycloak Application Server
After=network.target postgresql.service
Requires=network.target

[Service]
Type=idle
User=keycloak
Group=keycloak
ExecStart=/opt/keycloak/bin/kc.sh start --optimized
ExecStop=/opt/keycloak/bin/kc.sh stop
Restart=on-failure
RestartSec=10s
StandardOutput=journal
StandardError=journal
Environment="KEYCLOAK_ADMIN=admin"
Environment="KEYCLOAK_ADMIN_PASSWORD=LabAdmin2024!"

[Install]
WantedBy=multi-user.target
```

**Understanding systemd service:**

| Directive | Value | Explanation |
|-----------|-------|-------------|
| After | network.target | Start after network is ready |
| Type | idle | Wait for other services to start first |
| User/Group | keycloak | Run as keycloak user (not root) |
| ExecStart | /opt/keycloak/bin/kc.sh start | Start command |
| Restart | on-failure | Auto-restart if crashes |
| Environment | KEYCLOAK_ADMIN=admin | Initial admin username |
| Environment | KEYCLOAK_ADMIN_PASSWORD=... | Initial admin password |

**Save and exit**

---

#### Step 5: Start Keycloak

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable auto-start on boot
sudo systemctl enable keycloak

# Start service
sudo systemctl start keycloak
```

**Monitor startup (takes 1-2 minutes):**

```bash
sudo journalctl -u keycloak -f
```

**Watch for:**

```
...
INFO  [org.keycloak.quarkus.runtime.hostname.DefaultHostnameProvider] Hostname settings: Base URL: <unset>, Hostname: sso.lab.local, Strict HTTPS: false, Path: <request>, Strict BackChannel: false, Admin URL: <unset>, Admin: <request>, Port: -1, Proxied: true
...
INFO  [io.quarkus] Keycloak 24.0.0 on JVM (powered by Quarkus 3.2.9.Final) started in 45.678s. Listening on: http://0.0.0.0:8080
INFO  [io.quarkus] Profile prod activated.
INFO  [io.quarkus] Installed features: [agroal, cdi, hibernate-orm, jdbc-h2, jdbc-mariadb, jdbc-mssql, jdbc-mysql, jdbc-oracle, jdbc-postgresql, keycloak, narayana-jta, reactive-routes, resteasy, resteasy-jackson, smallrye-context-propagation, smallrye-health, vault, vertx]
```

**Key indicators:**
- "Keycloak 24.0.0... started in XX.XXXs" ✓
- "Listening on: http://0.0.0.0:8080" ✓
- No ERROR messages ✓

**Press Ctrl+C to exit log view**

---

#### Step 6: Verify Keycloak is Running

**Check service status:**

```bash
sudo systemctl status keycloak
```

Expected:
```
● keycloak.service - Keycloak Application Server
     Loaded: loaded (/etc/systemd/system/keycloak.service; enabled)
     Active: active (running) since Mon 2024-02-04 13:05:15 EST; 2min ago
```

**Check listening port:**

```bash
sudo ss -tlnp | grep 8080
```

Expected:
```
LISTEN 0  50  *:8080  *:*  users:(("java",pid=12345,fd=123))
```

---

#### Step 7: Configure Firewall

```bash
sudo ufw allow 8080/tcp comment 'Keycloak'
sudo ufw reload
```

---

#### Step 8: Test Keycloak Access

**From your laptop, add to /etc/hosts:**

```
10.0.50.11  sso.lab.local
```

**Open browser:**

Navigate to: `http://sso.lab.local:8080`

**You should see:**

```
Welcome to Keycloak

Administration Console
[Go to Administration Console]
```

**Click "Administration Console"**

**Login:**
- Username: `admin`
- Password: `LabAdmin2024!`

**You should see the Keycloak Admin Console!**

---

### Task 6.4: Configure Keycloak Realm

**Realms in Keycloak:**
- **Realm** = Isolated space for users, clients, roles
- Default realm: `master` (for admin access only)
- We'll create `lab` realm for our applications

---

#### Step 1: Create Lab Realm

**In Keycloak Admin Console:**

1. **Hover over "Master" (top-left dropdown)**
2. **Click "Create Realm"**
3. **Fill in:**
   - Realm name: `lab`
   - Enabled: `ON`
4. **Click "Create"**

**You're now in the "lab" realm!**

---

#### Step 2: Configure LDAP User Federation

**This connects Keycloak to FreeIPA's LDAP directory.**

**In Keycloak Admin Console:**

1. **Navigate:** Configure → User Federation
2. **Click "Add Ldap providers"** (or "ldap" from dropdown)
3. **Fill in the form:**

| Field | Value | Explanation |
|-------|-------|-------------|
| Edit Mode | READ_ONLY | Don't modify FreeIPA (read only) |
| Vendor | Red Hat Directory Server | FreeIPA uses 389-ds |
| Connection URL | ldap://10.0.50.11 | FreeIPA LDAP server |
| Bind Type | simple | Simple authentication |
| Bind DN | uid=admin,cn=users,cn=accounts,dc=lab,dc=local | FreeIPA admin user |
| Bind Credential | LabAdmin2024! | FreeIPA admin password |
| Users DN | cn=users,cn=accounts,dc=lab,dc=local | Where users are stored |
| Username LDAP attribute | uid | User ID field |
| RDN LDAP attribute | uid | Relative Distinguished Name |
| UUID LDAP attribute | ipaUniqueID | Unique ID field |
| User Object Classes | inetOrgPerson, organizationalPerson | LDAP object types |
| Custom User LDAP Filter | (leave empty) | No additional filter |

4. **Click "Test connection"** - Should show "Success"
5. **Click "Test authentication"** - Should show "Success"
6. **Click "Save"**

---

#### Step 3: Synchronize Users from LDAP

**After saving LDAP configuration:**

1. **Scroll to bottom of LDAP configuration page**
2. **Find "Synchronization Settings"**
3. **Click "Sync all users"**

**Output:**

```
Success! Sync of users finished successfully. 6 imported users, 0 updated users
```

**Understanding:**
- Keycloak imported all users from FreeIPA
- Users: admin, guard1, guard2, manager1, office1, itadmin1

---

#### Step 4: Verify Users

**In Keycloak:**

1. **Navigate:** Manage → Users
2. **Click "View all users"**

**You should see:**
- admin
- guard1
- guard2
- manager1
- office1
- itadmin1

**Click on "guard1" to see profile:**
- Username, Email, First Name, Last Name
- All from FreeIPA LDAP ✓

---

#### Step 5: Map LDAP Groups

**Map FreeIPA groups to Keycloak:**

1. **Navigate:** Configure → User Federation → ldap (click to edit)
2. **Tab:** Mappers
3. **Click "Add mapper"**
4. **Select:** group-ldap-mapper
5. **Fill in:**

| Field | Value |
|-------|-------|
| Name | groups |
| Mapper Type | group-ldap-mapper |
| LDAP Groups DN | cn=groups,cn=accounts,dc=lab,dc=local |
| Group Name LDAP Attribute | cn |
| Group Object Classes | groupOfNames |
| Membership LDAP Attribute | member |
| User Groups Retrieve Strategy | LOAD_GROUPS_BY_MEMBER_ATTRIBUTE |
| Mapped Group Attributes | (leave empty) |
| Drop non-existing groups | OFF |

6. **Click "Save"**
7. **Click "Sync LDAP Groups to Keycloak"**

**Success message:**

```
Success! Sync of groups finished successfully. 4 imported groups, 0 updated groups
```

**Verify groups:**

1. **Navigate:** Manage → Groups
2. **You should see:**
   - guards
   - managers
   - office-staff
   - it-admins

---

**✅ Keycloak Installation Complete!**

**What you've accomplished:**
- ✅ Installed Keycloak 24.0
- ✅ Configured PostgreSQL database connection
- ✅ Created systemd service
- ✅ Created 'lab' realm
- ✅ Integrated with FreeIPA LDAP
- ✅ Synchronized users and groups
- ✅ Tested admin console access

**Your SSO infrastructure is ready!**

**Next steps will configure applications to use Keycloak for authentication.**

---

## Exercise 7: Nextcloud Collaboration Platform

[Due to length constraints, I'll continue with a brief overview of remaining exercises. Would you like me to continue with full detail for Exercises 7-14?]

**Exercise 7 would cover:**
- Nextcloud installation on LAB-APP1
- PHP-FPM and Nginx configuration
- Database connection to PostgreSQL
- Redis caching setup
- LDAP integration with FreeIPA
- OAuth integration with Keycloak
- Installing essential apps (Calendar, Contacts, Talk, Office)

**Exercise 8 - Mattermost:**
- Binary installation
- Database configuration
- LDAP/SAML integration
- Nginx reverse proxy
- Testing team chat

**Exercise 9 - Jitsi Meet:**
- Repository setup
- Installation via apt
- Configuration for our domain
- Nginx integration
- Testing video calls

**Exercise 10 - iRedMail:**
- Complete mail server stack
- SMTP, IMAP configuration
- Webmail (SOGo/Roundcube)
- SPF/DKIM/DMARC DNS records
- User mailbox creation

**Exercise 11 - Traefik Reverse Proxy:**
- Docker installation
- Traefik configuration
- Backend routing for all services
- SSL/TLS with Let's Encrypt
- Dashboard access

**Exercise 12 - Zammad:**
- Help desk installation
- Elasticsearch integration
- Email ticket creation
- Web interface configuration
- Agent assignment

**Exercise 13 - SSO Integration:**
- Configuring each app with Keycloak
- Testing single sign-on flow
- User experience walkthrough

**Exercise 14 - Monitoring:**
- Basic Zabbix setup
- Service health checks
- Log aggregation basics

**Would you like me to continue with full detail for the remaining exercises, or is this overview sufficient?**

---

**Summary so far - Part 2:**
- ✅ Exercise 4: FreeIPA (Complete - 100+ commands)
- ✅ Exercise 5: PostgreSQL & Redis (Complete - 50+ commands)
- ✅ Exercise 6: Keycloak SSO (Complete - detailed GUI + CLI)
- 📝 Exercises 7-14: Ready to expand with same detail level

