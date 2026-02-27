# Enterprise Open-Source IT Infrastructure Lab
# Complete Deployment Manual - Part 5: Back Office Suite
**Educational Lab Manual - Business Systems Integration**

---

## Part 5 Overview

This part extends your infrastructure from collaboration and communications to complete business operations. You'll deploy:
- **VoIP/PBX System** (FreePBX) - Professional phone system
- **CRM** (SuiteCRM) - Customer relationship management
- **ERP** (Odoo) - Complete business management
- **Document Management** (OpenKM) - Enterprise document repository
- **Project Management** (Taiga) - Agile project tracking
- **Asset Management** (Snipe-IT) - IT asset inventory
- **ITSM** (GLPI) - IT service management

**Prerequisites:** Parts 1-4 complete (Identity, Database, Collaboration, Communications)

---

## Table of Contents

1. [Back Office Architecture](#back-office-architecture)
2. [Exercise 15: FreePBX VoIP System](#exercise-15-freepbx-voip-system)
3. [Exercise 16: SuiteCRM Installation](#exercise-16-suitecrm-installation)
4. [Exercise 17: Odoo ERP Deployment](#exercise-17-odoo-erp-deployment)
5. [Exercise 18: OpenKM Document Management](#exercise-18-openkm-document-management)
6. [Exercise 19: Taiga Project Management](#exercise-19-taiga-project-management)
7. [Exercise 20: Snipe-IT Asset Management](#exercise-20-snipe-it-asset-management)
8. [Exercise 21: GLPI IT Service Management](#exercise-21-glpi-it-service-management)
9. [Exercise 22: Back Office Integration](#exercise-22-back-office-integration)
10. [Exercise 23: End-to-End Workflows](#exercise-23-end-to-end-workflows)
11. [Testing Back Office Systems](#testing-back-office-systems)
12. [Back Office Troubleshooting](#back-office-troubleshooting)

---

## Back Office Architecture

### Extended Infrastructure Overview

**Server Allocation:**

```
EXISTING (From Parts 1-4):
├── LAB-ID1 (10.0.50.11)    - Identity & SSO
├── LAB-DB1 (10.0.50.12)    - Database & Cache
├── LAB-APP1 (10.0.50.13)   - Collaboration Apps
├── LAB-COMM1 (10.0.50.14)  - Communications
└── LAB-PROXY1 (10.0.50.15) - Reverse Proxy

NEW (Part 5):
├── LAB-VOIP1 (10.0.50.16)  - VoIP/PBX System
├── LAB-BIZ1 (10.0.50.17)   - Business Apps (CRM, DMS)
├── LAB-ERP1 (10.0.50.18)   - ERP System
└── LAB-IT1 (10.0.50.19)    - IT Management

Total: 9 servers
```

### Business Value Chain

```
┌─────────────────────────────────────────────────────────────┐
│                  COMPLETE BUSINESS PLATFORM                  │
└─────────────────────────────────────────────────────────────┘

MARKETING & SALES (Lead to Customer):
  Web Form → SuiteCRM → Phone (FreePBX) → Quote (Odoo) → 
  Contract (OpenKM) → Order (Odoo) → Invoice (Odoo) → 
  Payment → Customer Record

SERVICE DELIVERY (Project to Completion):
  Project (Taiga) → Tasks → Time Tracking → Team Chat → 
  Video Meetings → Documents (Nextcloud/OpenKM) → 
  Deliverables → Client Invoice (Odoo) → Archive

CUSTOMER SUPPORT (Request to Resolution):
  Phone Call (FreePBX) → Ticket (Zammad/GLPI) → 
  Asset Lookup (Snipe-IT) → Knowledge Base → 
  Resolution → Customer Notification → Satisfaction Survey

INTERNAL OPERATIONS:
  HR (Odoo) → Procurement (Odoo) → Inventory (Odoo) → 
  Accounting (Odoo) → Reporting → Compliance

IT OPERATIONS:
  Asset Management (Snipe-IT) → Service Catalog (GLPI) → 
  Incident Management (GLPI) → Change Management (GLPI) → 
  Knowledge Base (GLPI)
```

### Integration Matrix

| System | Integrates With | Integration Method | Purpose |
|--------|----------------|-------------------|---------|
| **FreePBX** | SuiteCRM | AMI/AGI | Click-to-call, call logging |
| | Zammad | REST API | Phone ticket creation |
| | FreeIPA | LDAP | Extension provisioning |
| **SuiteCRM** | Odoo | REST API | Customer sync |
| | FreePBX | CTI | Call logging |
| | Nextcloud | CalDAV | Calendar sync |
| | iRedMail | IMAP | Email integration |
| | OpenKM | WebDAV | Document linking |
| **Odoo** | FreeIPA | LDAP | Employee sync |
| | SuiteCRM | API | Customer data |
| | Taiga | API | Time import |
| | Snipe-IT | API | Asset procurement |
| | OpenKM | WebDAV | Document storage |
| **OpenKM** | All systems | WebDAV/API | Central document repository |
| **Taiga** | Mattermost | Webhooks | Notifications |
| | Nextcloud | WebDAV | File storage |
| | Odoo | API | Time export |
| **Snipe-IT** | FreeIPA | LDAP | User sync |
| | GLPI | API | Asset sync |
| | Odoo | API | Procurement |
| **GLPI** | FreeIPA | LDAP | Authentication |
| | Zammad | API | Ticket sync |
| | Snipe-IT | API | Asset data |
| | Keycloak | SAML | SSO |

---

## Exercise 15: FreePBX VoIP System

### Understanding VoIP and PBX

**What is a PBX?**

PBX (Private Branch Exchange) is a private telephone network used within an organization. Instead of each phone having a direct line to the telephone company, a PBX routes calls internally and connects to the outside world through a limited number of lines.

**Traditional PBX vs VoIP PBX:**

```
Traditional PBX:
┌─────────────────┐
│  Physical PBX   │ (Large hardware box)
│  Hardware       │ $10,000-50,000+
└────────┬────────┘
         │
    Analog Lines
         │
┌────────▼────────┐
│  Phone Company  │ $50-100 per line/month
└─────────────────┘

VoIP PBX (FreePBX):
┌─────────────────┐
│  FreePBX        │ (Software on server)
│  (Free!)        │ $0
└────────┬────────┘
         │
    SIP Trunk (Internet)
         │
┌────────▼────────┐
│  VoIP Provider  │ $10-20 per user/month
│  (Twilio, etc)  │ 
└─────────────────┘

Savings: $30,000-80,000 initial + $30-80 per user/month
```

**What You'll Learn:**
- PBX fundamentals and telephony concepts
- SIP protocol and VoIP architecture
- Extension management
- Call routing and IVR (Interactive Voice Response)
- Voicemail system configuration
- Call recording for compliance
- Integration with CRM (click-to-call)
- Quality of Service (QoS) for VoIP

**Real-World Impact:**
- Professional phone system on par with Fortune 500 companies
- Work from anywhere (softphones)
- Call analytics and reporting
- Integration with business systems
- Scalable from 10 to 1,000+ users

**Time Required:** 3-4 hours

---

### Task 15.1: Prepare VoIP Server

**Hardware Requirements:**

VoIP has specific requirements because poor quality = dropped calls and angry customers.

**Why LAB-VOIP1?**

Dedicated server for VoIP because:
- **Quality of Service (QoS):** Voice traffic needs priority
- **Reliability:** Phone system can't go down
- **Call Recording:** Storage grows quickly
- **Isolation:** Keeps voice network separate (security/compliance)

**On LAB-VOIP1:**

---

#### Step 1: Install Ubuntu Server

**If using existing lab computer:**

You've already installed Ubuntu in Part 1. Just verify:

```bash
ssh labadmin@10.0.50.16
hostname -f
```

Should show: `lab-voip1.lab.local`

**If needed, set hostname:**

```bash
sudo hostnamectl set-hostname lab-voip1.lab.local
```

---

#### Step 2: Configure Network for VoIP

**VoIP traffic should ideally be on separate VLAN for QoS:**

**In production:**
- VLAN 30: VoIP traffic (10.0.30.0/24)
- QoS priority tags
- Dedicated bandwidth

**In lab (simplified):**
- Same network as other servers
- Still works fine for testing

**Update /etc/hosts:**

```bash
sudo nano /etc/hosts
```

Add:
```
10.0.50.16    lab-voip1.lab.local lab-voip1 voip pbx
```

---

#### Step 3: Install Prerequisites

```bash
sudo apt update
sudo apt upgrade -y

# Install basic tools
sudo apt install -y vim curl wget git htop net-tools

# Install required packages for FreePBX
sudo apt install -y apache2 mariadb-server mariadb-client \
    php8.3 php8.3-cli php8.3-common php8.3-curl php8.3-gd \
    php8.3-mbstring php8.3-mysql php8.3-xml php8.3-zip \
    php8.3-intl php8.3-bcmath sox mpg123 \
    lame ffmpeg sqlite3 git unixodbc uuid-dev
```

**Understanding packages:**
- **apache2** - Web server for FreePBX GUI
- **mariadb** - Database (FreePBX can use this or PostgreSQL)
- **php** - FreePBX is written in PHP
- **sox, mpg123, lame, ffmpeg** - Audio processing for voicemail, music on hold
- **uuid-dev** - Required for Asterisk compilation

---

#### Step 4: Install Asterisk

**What is Asterisk?**

Asterisk is the core PBX engine. FreePBX is the web GUI that manages Asterisk.

**Download and compile Asterisk:**

```bash
# Create directory for source
cd /usr/src

# Download Asterisk 21 (LTS version)
sudo wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-21-current.tar.gz

# Extract
sudo tar -xzf asterisk-21-current.tar.gz
cd asterisk-21.*/

# Install prerequisites
sudo contrib/scripts/install_prereq install

# Configure with all modules
sudo ./configure --with-jansson-bundled --with-pjproject-bundled

# Compile (this takes 15-30 minutes)
sudo make -j$(nproc)

# Install
sudo make install
sudo make samples
sudo make config
sudo ldconfig
```

**Understanding compile process:**
```
./configure     - Checks system and prepares build
make            - Compiles source code
make install    - Installs binaries
make samples    - Creates sample config files
make config     - Sets up systemd service
```

**Create Asterisk user:**

```bash
sudo groupadd asterisk
sudo useradd -r -d /var/lib/asterisk -g asterisk asterisk
sudo usermod -aG audio,dialout asterisk

# Set ownership
sudo chown -R asterisk:asterisk /etc/asterisk
sudo chown -R asterisk:asterisk /var/{lib,log,spool}/asterisk
sudo chown -R asterisk:asterisk /usr/lib/asterisk
```

**Configure Asterisk to run as asterisk user:**

```bash
sudo nano /etc/default/asterisk
```

Set:
```
AST_USER="asterisk"
AST_GROUP="asterisk"
```

**Start Asterisk:**

```bash
sudo systemctl start asterisk
sudo systemctl enable asterisk
sudo systemctl status asterisk
```

**Test Asterisk:**

```bash
sudo asterisk -rvvv
```

You should see Asterisk CLI:
```
Asterisk 21.x.x, Copyright (C) 1999-2024 Sangoma Technologies Corporation and others.
Created by Mark Spencer <markster@digium.com>
Asterisk comes with ABSOLUTELY NO WARRANTY; type 'core show warranty' for details.
This is free software, with components licensed under the GNU General Public
License version 2 and other licenses; you are welcome to redistribute it under
certain conditions. Type 'core show license' for details.
=========================================================================
Connected to Asterisk 21.x.x currently running on lab-voip1 (pid = 1234)
lab-voip1*CLI>
```

**Try commands:**
```
core show version
sip show peers
dialplan show
```

**Exit:**
```
exit
```

---

#### Step 5: Install FreePBX

**Download FreePBX:**

```bash
cd /usr/src
sudo wget https://github.com/freepbx/freepbx/releases/download/release/17.0/freepbx-17.0-latest.tgz
sudo tar -xzf freepbx-17.0-latest.tgz
cd freepbx
```

**Install FreePBX:**

```bash
sudo ./start_asterisk start
sudo ./install -n
```

**This installs FreePBX framework and creates the web GUI.**

**Set Apache to run as asterisk user:**

```bash
sudo nano /etc/apache2/envvars
```

Change:
```
export APACHE_RUN_USER=asterisk
export APACHE_RUN_GROUP=asterisk
```

**Enable Apache modules:**

```bash
sudo a2enmod rewrite
sudo systemctl restart apache2
```

**Set permissions:**

```bash
sudo chown -R asterisk:asterisk /var/www/html
```

---

#### Step 6: Access FreePBX Web Interface

**From your laptop browser:**

```
http://10.0.50.16
```

**Or using hostname:**

```
http://voip.lab.local
```

**You should see FreePBX initial setup wizard.**

---

### Task 15.2: Initial FreePBX Configuration

#### Step 1: Complete Setup Wizard

**Screen 1: Language**
- Select: English (or your language)
- Click: Submit

**Screen 2: Create Admin Account**
```
Username: admin
Password: VoipAdmin2024!
Email: admin@lab.local
```
- Click: Submit

**Screen 3: Activation (Optional)**
- FreePBX offers commercial modules
- You can skip activation for community edition
- Click: Skip Activation

**Screen 4: System Information**
- Review detected system info
- Asterisk version should show 21.x
- Click: Finish

**You're now in the FreePBX dashboard!**

---

#### Step 2: Configure Basic Settings

**Navigate: Admin → System Admin → Network Settings**

**Configure:**
```
Hostname: lab-voip1.lab.local
Domain: lab.local
Primary IP: 10.0.50.16
Timezone: America/Toronto (or your timezone)
```

**Click: Submit & Apply Changes**

---

#### Step 3: Configure Asterisk SIP Settings

**Navigate: Settings → Asterisk SIP Settings**

**Understanding SIP:**

SIP (Session Initiation Protocol) is how VoIP calls are set up. Think of it like the "dialing" part of a phone call.

**Configuration:**

**General Settings:**
```
Bind Address: 10.0.50.16
External IP: [Your public IP if accessing from outside]
Local Networks: 10.0.50.0/24

Enable: Yes
```

**NAT Settings:** (if behind router)
```
NAT: Yes
External IP: [Your public IP]
Local Network: 10.0.50.0/24
```

**Codec Settings:**
```
Preferred Codecs:
  ✓ ulaw (G.711u) - Uncompressed, best quality
  ✓ alaw (G.711a) - Uncompressed, international standard
  ✓ g722 - HD Voice
  
Optional:
  ✓ opus - Modern codec, great quality
```

**Understanding codecs:**
- **ulaw/alaw:** 64 kbps, best quality, uses more bandwidth
- **g722:** HD voice, better than ulaw
- **opus:** Variable bitrate, excellent quality at low bandwidth

**Click: Submit & Reload**

---

### Task 15.3: Create Extensions

**What is an extension?**

An extension is like a phone number within your organization. Instead of calling a full phone number, you dial just 3-4 digits.

**Extension Plan:**

```
100-199: Executives and Management
200-299: Sales Department
300-399: Support/Customer Service
400-499: IT and Technical Staff
500-599: Operations and General Staff
```

---

#### Step 1: Create First Extension

**Navigate: Applications → Extensions**

**Click: Add Extension → Add SIP [chan_pjsip] Extension**

**User Extension:**
```
Extension Number: 101
Display Name: Guard One
```

**Click: Submit**

**Secret (Password) will be auto-generated. Note it down!**

**Advanced Settings:**

**Under "Device Options":**
```
Secret: [Auto-generated] (e.g., xK9mP2nQ5vR8)
```

**This is the password the phone/softphone will use to register.**

---

#### Step 2: Configure Voicemail

**Scroll down to "Voicemail" section:**

```
Status: Enabled
Voicemail Password: 1234 (user can change)
Email Address: guard1@lab.local
Email Attachment: Yes
Play CID: Yes
Play Envelope: Yes
Delete Voicemail After Email: No
```

**Understanding voicemail settings:**
- **Email Attachment:** Sends voicemail as .wav file to email
- **Play CID:** Announces who called
- **Play Envelope:** Announces date/time of message
- **Delete After Email:** If yes, doesn't store on server

**Click: Submit**

**Click: Apply Config** (red bar at top)

---

#### Step 3: Create More Extensions

**Repeat for each user:**

```
Extension 102:
  Display Name: Guard Two
  Email: guard2@lab.local

Extension 201:
  Display Name: Manager One
  Email: manager1@lab.local

Extension 301:
  Display Name: Office Staff
  Email: office1@lab.local

Extension 401:
  Display Name: IT Admin
  Email: itadmin1@lab.local
```

**Quick Bulk Method:**

**Navigate: Applications → Extension → Bulk Extensions**

```
Starting Extension: 200
Number of Extensions: 10
Display Name Prefix: Sales-
Voicemail: Enabled
Email Suffix: @lab.local
```

**This creates extensions 200-209 all at once.**

**Click: Submit & Apply Config**

---

### Task 15.4: Configure Ring Groups

**What are Ring Groups?**

Ring groups allow multiple phones to ring when someone dials a single number.

**Example:**
```
Dial 600 (Sales) → Rings extensions 201, 202, 203 simultaneously
First person to answer gets the call
```

---

#### Step 1: Create Sales Ring Group

**Navigate: Applications → Ring Groups**

**Click: Add Ring Group**

**Configuration:**
```
Ring Group Number: 600
Group Description: Sales Team
Ring Strategy: ringall

Extension List:
  201
  202
  203
  204
  205

Announcement: None (or upload greeting)
Destination if No Answer: Voicemail (600)
```

**Ring Strategy options:**
- **ringall:** All phones ring at once (recommended for support)
- **hunt:** Try each phone in order
- **memoryhunt:** Remembers where last call was answered, starts there
- **random:** Picks random extension

**Click: Submit & Apply Config**

---

#### Step 2: Create More Ring Groups

```
Ring Group 601:
  Description: Customer Support
  Extensions: 301, 302, 303, 304
  Strategy: ringall

Ring Group 602:
  Description: IT Support
  Extensions: 401, 402, 403
  Strategy: hunt (try in order)
```

---

### Task 15.5: Create IVR (Auto-Attendant)

**What is IVR?**

IVR (Interactive Voice Response) is the menu callers hear: "Press 1 for Sales, Press 2 for Support..."

---

#### Step 1: Record/Upload Greeting

**Navigate: Admin → System Recordings**

**Option A: Upload Recording**
- Record greeting on your computer
- Upload .wav file (8000 Hz, 16-bit, mono)

**Option B: Text-to-Speech**
- FreePBX can generate speech from text
- Navigate: Admin → Sound Languages → Text to Speech

**Sample greeting:**
```
"Thank you for calling. 
Press 1 for Sales
Press 2 for Customer Support  
Press 3 for IT Support
Press 9 for the directory
Or stay on the line for the operator."
```

**Save as:** "main-greeting"

---

#### Step 2: Create IVR

**Navigate: Applications → IVR**

**Click: Add IVR**

**Configuration:**
```
IVR Name: Main Menu
IVR Description: Main incoming call menu
Announcement: main-greeting (recording from Step 1)
Timeout: 10 seconds
Invalid Retry Recording: Please enter a valid option
Invalid Destination: Operator (ext 101)
Timeout Destination: Operator (ext 101)

IVR Entries:
  1 → Ring Group 600 (Sales)
  2 → Ring Group 601 (Support)
  3 → Ring Group 602 (IT)
  9 → Directory
  # → Return
  * → Return
```

**Click: Submit & Apply Config**

---

### Task 15.6: Configure Inbound Routes

**What are Inbound Routes?**

These determine what happens when someone calls your main number.

---

#### Step 1: Create Main Inbound Route

**Navigate: Connectivity → Inbound Routes**

**Click: Add Inbound Route**

**Configuration:**
```
Description: Main Incoming Line
DID Number: [Leave blank for "any"]
  (or enter your phone number if you have SIP trunk)

Set Destination:
  IVR: Main Menu
```

**This means:** Any call coming in goes to IVR menu

**Click: Submit & Apply Config**

---

### Task 15.7: Test with Softphone

**Install Softphone on Your Computer**

**Options:**
- **Zoiper** (Windows/Mac/Linux) - https://www.zoiper.com
- **Linphone** (Open source) - https://www.linphone.org
- **MicroSIP** (Windows only) - https://www.microsip.org

**We'll use Zoiper (Free version):**

---

#### Step 1: Install Zoiper

**Download** from https://www.zoiper.com/downloads

**Run installer.**

---

#### Step 2: Configure Extension 101

**In Zoiper:**

1. **Click:** Settings → Accounts → Add Account

2. **Account Configuration:**
   ```
   Account Type: SIP
   
   Account Name: Guard One (101)
   
   Domain: 10.0.50.16
   Username: 101
   Password: [Secret from extension config in FreePBX]
   
   Authentication user: 101
   Caller ID: Guard One <101>
   
   Register: Yes
   
   Domain/Realm/Proxy: 10.0.50.16
   Port: 5060
   Transport: UDP
   ```

3. **Click:** Create Account

**You should see:** Green checkmark - Registered

**If red X:**
- Check IP address
- Verify password
- Check firewall (port 5060 must be open)

---

#### Step 3: Make Test Call

**Install second softphone on another computer or phone:**
- Configure as extension 102

**From extension 101:**
- Dial: 102
- Should ring on other softphone
- Answer and talk!

**You've made your first VoIP call!**

---

### Task 15.8: Test Voicemail

**From extension 101:**

1. **Dial:** 102
2. **Let it ring** (don't answer on 102)
3. **After timeout:** Should go to voicemail
4. **Record message:** "This is a test voicemail"
5. **Hang up**

**Check voicemail on extension 102:**

1. **Dial:** *97 (voicemail access code)
2. **Enter:** Password (1234 by default)
3. **Listen** to new message

**Check email:**
- Email should arrive at guard2@lab.local
- Contains .wav attachment with voicemail

---

### Task 15.9: Configure Conference Bridge

**What is conference bridge?**

Allows multiple people to join a single call - like a meeting room.

---

#### Step 1: Create Conference

**Navigate: Applications → Conferences**

**Click: Add Conference**

**Configuration:**
```
Conference Number: 9000
Conference Name: Main Conference Room
User PIN: 2468 (optional)
Admin PIN: 1357 (allows admin control)
Max Users: 10

Options:
  ✓ Quiet Mode (no beep when joining)
  ✓ Wait for Leader (waits for admin PIN before starting)
  ✓ Music on Hold when alone
  ✓ Record Conference
```

**Click: Submit & Apply Config**

---

#### Step 2: Test Conference

**From any extension:**

1. **Dial:** 9000
2. **Enter PIN:** 2468
3. **Join conference**

**From another extension:**
1. **Dial:** 9000
2. **Enter PIN:** 2468
3. **Now both in conference - can talk!**

**As admin (with admin PIN 1357):**
- Can mute all participants
- Can kick users
- Can lock conference

---

### Task 15.10: Call Recording

**Enable call recording for compliance or training.**

---

#### Step 1: Enable Recording for Extension

**Navigate: Applications → Extensions → 201 (Sales)**

**Scroll to "Other" section:**

```
Recording Options:
  Recording Incoming: Always
  Recording Outgoing: Always
  On Demand Recording: Yes
```

**Click: Submit & Apply Config**

**Now all calls to/from extension 201 are recorded.**

---

#### Step 2: Access Recordings

**Navigate: Admin → Call Event Logging**

**Or:** Reports → Call Recordings

**You can:**
- Play recordings
- Download recordings
- Delete old recordings
- Search by date/extension

**Recordings stored at:** `/var/spool/asterisk/monitor/`

---

### Task 15.11: Configure SIP Trunk (Optional)

**Skip this if you don't need external calling.**

**If you want to call real phone numbers:**

You need a SIP trunk provider:
- **Twilio** (https://twilio.com)
- **Voip.ms** (https://voip.ms)
- **Bandwidth.com** (https://bandwidth.com)

**Example with Twilio:**

---

#### Step 1: Sign Up for Twilio

1. Go to https://www.twilio.com/try-twilio
2. Sign up for account
3. Get: SIP Domain, Username, Password
4. Purchase phone number

---

#### Step 2: Configure Trunk in FreePBX

**Navigate: Connectivity → Trunks**

**Click: Add Trunk → Add SIP (chan_pjsip) Trunk**

**Configuration:**
```
Trunk Name: Twilio

Outbound CallerID: +1XXXXXXXXXX (your Twilio number)

PEER Details:
  type=peer
  host=yourdomain.pstn.twilio.com
  username=your_username
  secret=your_auth_token
  insecure=port,invite
  context=from-trunk
  
Maximum Channels: 10
```

**Click: Submit & Apply Config**

---

#### Step 3: Create Outbound Route

**Navigate: Connectivity → Outbound Routes**

**Click: Add Outbound Route**

**Configuration:**
```
Route Name: Twilio Outbound
Route Password: (blank)

Dial Patterns:
  NXXNXXXXXX (10-digit US numbers)
  1NXXNXXXXXX (11-digit with 1)
  011ZZZXXXXXXX (international)

Trunk Sequence:
  Twilio
```

**Click: Submit & Apply Config**

**Now you can dial external numbers!**

**Test:**
- Dial: 1234567890 (replace with real number)
- Should dial out through Twilio

---

### Task 15.12: Mobile Softphone

**Use your PBX extension on your mobile phone.**

---

#### Step 1: Install Zoiper on Phone

**iOS:** App Store → Search "Zoiper"  
**Android:** Play Store → Search "Zoiper"

**Install the free version.**

---

#### Step 2: Configure Extension

**Open Zoiper on phone:**

1. **Create Account**
2. **Enter:**
   ```
   Domain: voip.lab.local (or 10.0.50.16)
   Username: 101
   Password: [extension secret]
   ```
3. **Connect**

**Note:** Phone must be on same network as lab, or you need VPN/port forwarding.

---

**✅ FreePBX Installation Complete!**

**What you've accomplished:**
- ✅ Installed Asterisk and FreePBX
- ✅ Created extensions (internal phone numbers)
- ✅ Configured ring groups (departments)
- ✅ Built IVR menu (auto-attendant)
- ✅ Set up voicemail with email
- ✅ Created conference bridge
- ✅ Enabled call recording
- ✅ Tested with softphones
- ✅ Optional: Connected to outside world (SIP trunk)

**Your organization now has:**
- Professional phone system
- Internal extensions
- Auto-attendant
- Voicemail-to-email
- Conference rooms
- Call recording
- Mobile access

**Cost:** $0 (vs $20,000+ for commercial PBX!)

---

## Exercise 16: SuiteCRM Installation

### Understanding CRM Systems

**What is CRM?**

CRM (Customer Relationship Management) tracks all interactions with customers and potential customers.

**Without CRM:**
```
Customer calls → Agent writes notes on paper
Later → Can't find notes
Customer calls again → "Who are you?"
Result: Poor customer experience, lost sales
```

**With CRM:**
```
Customer calls → Screen pop shows:
  - Customer name
  - Purchase history  
  - Previous conversations
  - Open issues
  - Opportunities
Agent: "Hi John, how's the new product working?"
Result: Professional, personalized service
```

**What You'll Learn:**
- Contact and account management
- Lead tracking and conversion
- Sales pipeline management
- Email integration
- Calendar and task management
- Reporting and dashboards
- Mobile CRM access
- Phone integration (click-to-call)

**Time Required:** 2-3 hours

---

### Task 16.1: Prepare CRM Server

**On LAB-BIZ1:**

---

#### Step 1: Install Prerequisites

```bash
ssh labadmin@10.0.50.17

sudo apt update
sudo apt upgrade -y

# Install web server and PHP
sudo apt install -y nginx php8.3-fpm php8.3-cli \
    php8.3-common php8.3-curl php8.3-gd \
    php8.3-mbstring php8.3-pgsql php8.3-xml \
    php8.3-zip php8.3-intl php8.3-imap \
    php8.3-ldap php8.3-soap php8.3-bcmath \
    unzip curl
```

---

#### Step 2: Create Database

**SSH to LAB-DB1:**

```bash
ssh labadmin@10.0.50.12

sudo -u postgres psql
```

```sql
CREATE DATABASE suitecrm;
CREATE USER suitecrm WITH ENCRYPTED PASSWORD 'CrmPass2024!';
GRANT ALL PRIVILEGES ON DATABASE suitecrm TO suitecrm;
GRANT ALL ON SCHEMA public TO suitecrm;
\q
```

---

#### Step 3: Download SuiteCRM

**Back on LAB-BIZ1:**

```bash
cd /tmp
wget https://github.com/salesagility/SuiteCRM/archive/refs/tags/v8.6.1.zip
unzip v8.6.1.zip
sudo mv SuiteCRM-8.6.1 /var/www/suitecrm
sudo chown -R www-data:www-data /var/www/suitecrm
sudo chmod -R 755 /var/www/suitecrm
```

---

#### Step 4: Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/crm.lab.local
```

**Content:**

```nginx
server {
    listen 80;
    server_name crm.lab.local;
    
    root /var/www/suitecrm/public;
    index index.php index.html;

    client_max_body_size 20M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

**Enable site:**

```bash
sudo ln -s /etc/nginx/sites-available/crm.lab.local /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

#### Step 5: Configure PHP

```bash
sudo nano /etc/php/8.3/fpm/php.ini
```

**Update:**
```
memory_limit = 256M
upload_max_filesize = 20M
post_max_size = 20M
max_execution_time = 300
```

**Restart PHP-FPM:**

```bash
sudo systemctl restart php8.3-fpm
```

---

### Task 16.2: Install SuiteCRM

#### Step 1: Web Installation

**Navigate to:** `http://crm.lab.local`

**Welcome Screen:**
- Click: **Next**

**License Agreement:**
- Read and accept
- Click: **Next**

**System Check:**
- Review green checkmarks
- All should pass
- Click: **Next**

**Database Configuration:**
```
Database Type: PostgreSQL
Host Name: 10.0.50.12
Database Name: suitecrm
Database User: suitecrm
Database Password: CrmPass2024!
```
- Click: **Next**

**Site Configuration:**
```
Site URL: http://crm.lab.local
Admin Username: admin
Admin Password: CrmAdmin2024!
First Name: CRM
Last Name: Administrator
Email: admin@lab.local
```
- Click: **Next**

**Locale Settings:**
```
Date Format: Y-m-d
Time Format: H:i
Timezone: America/Toronto
Currency: USD
```
- Click: **Next**

**SMTP Configuration:**
```
SMTP Server: 10.0.50.14
SMTP Port: 587
Username: crm@lab.local
Password: [mail password]
Use TLS: Yes
```
- Click: **Next**

**Installation runs - takes 2-5 minutes**

**Click: Log In to SuiteCRM**

---

### Task 16.3: Initial CRM Configuration

**You're now in SuiteCRM!**

---

#### Step 1: Configure LDAP Authentication

**Navigate: Admin → Password Management → LDAP Authentication**

**Enable LDAP:**

```
Server: 10.0.50.11
Port: 389
Enable Start TLS: Yes

Base DN: cn=users,cn=accounts,dc=lab,dc=local
Bind DN: uid=admin,cn=users,cn=accounts,dc=lab,dc=local
Bind Password: [FreeIPA admin password]

Login Attribute: uid
Auto Create Users: Yes

User DN: cn=users,cn=accounts,dc=lab,dc=local
```

**Save**

**Test:** Try logging in with FreeIPA user (guard1 / password)

---

#### Step 2: Configure Email Settings

**Navigate: Admin → Email Settings**

**Outbound Email:**
```
SMTP Server: 10.0.50.14
Port: 587
Use TLS: Yes
Username: crm@lab.local
Password: [password]
From Name: Company Name CRM
From Address: crm@lab.local
```

**Click: Send Test Email → Enter your email → Send**

**Should receive test email**

---

#### Step 3: Create Sales Team

**Navigate: Admin → Users**

**For each FreeIPA user, create:**

1. **Click: Create**
2. **User Details:**
   ```
   Username: guard1 (from LDAP)
   First Name: Guard
   Last Name: One
   Email: guard1@lab.local
   Status: Active
   Department: Sales
   Title: Sales Representative
   ```
3. **Save**

**Repeat for: guard2, manager1, office1**

---

#### Step 4: Customize Sales Pipeline

**Navigate: Admin → Studio → Opportunities → Fields**

**Default Sales Stages:**
- Prospecting
- Qualification
- Needs Analysis
- Value Proposition
- Id. Decision Makers
- Perception Analysis
- Proposal/Price Quote
- Negotiation/Review
- Closed Won
- Closed Lost

**Add custom stage:**

**Click: Add Field**
```
Data Type: Dropdown
Field Name: sales_stage
Display Label: Sales Stage

Options:
  Lead
  Qualified
  Demo Scheduled
  Proposal Sent
  Negotiation
  Closed Won
  Closed Lost
```

**Save & Deploy**

---

### Task 16.4: Add Sample Data

**Let's add realistic test data.**

---

#### Step 1: Create Accounts (Companies)

**Navigate: Sales → Accounts**

**Click: Create**

**Account 1:**
```
Account Name: Acme Security Services
Phone: (555) 123-4567
Website: www.acmesecurity.com
Billing Address:
  Street: 123 Main St
  City: Ottawa
  State: ON
  Postal Code: K1A 0B1
Industry: Security
Annual Revenue: $5,000,000
Employees: 50
```

**Save**

**Repeat for 2-3 more companies**

---

#### Step 2: Create Contacts

**Navigate: Sales → Contacts**

**Click: Create**

**Contact 1:**
```
First Name: John
Last Name: Smith
Account: Acme Security Services
Title: Director of Operations
Email: john.smith@acmesecurity.com
Phone (Office): (555) 123-4567 ext 101
Phone (Mobile): (555) 987-6543

Address: [Same as account]
```

**Save**

**Create 3-4 contacts per account**

---

#### Step 3: Create Opportunity (Deal)

**Navigate: Sales → Opportunities**

**Click: Create**

**Opportunity 1:**
```
Opportunity Name: Acme - New Security System
Account: Acme Security Services
Amount: $50,000
Date Closed: [30 days from now]
Sales Stage: Qualified
Probability: 50%
Lead Source: Cold Call
Assigned To: guard1 (Sales Rep)

Description:
Potential deal for 24/7 monitoring system across
all Acme facilities. 3-year contract.
```

**Save**

---

#### Step 4: Log Activities

**While viewing opportunity:**

**Click: Log Call**
```
Subject: Discovery Call
Date: [Today]
Duration: 30 minutes
Notes: Discussed current security pain points.
       They need 24/7 monitoring. Budget approved.
       Next step: Schedule site visit.
```

**Save**

**Create calendar event:**

**Click: Schedule Meeting**
```
Subject: Site Visit - Acme Security
Start Date: [Tomorrow, 10:00 AM]
Duration: 2 hours
Invitees: John Smith (contact)
Location: Acme Office
Related To: Acme - New Security System (opportunity)
```

**Save**

---

### Task 16.5: Configure Dashboards

**Navigate: Home (Dashboard)**

**Click: Create Dashboard**

**Add Dashlets:**

1. **My Opportunities**
   - Shows your open deals
   - Drag to position

2. **Sales Pipeline by Month**
   - Shows revenue forecast
   
3. **My Calls Today**
   - Shows scheduled calls

4. **My Meetings**
   - Shows calendar events

**Save Dashboard**

**Now you have visual overview of sales activity**

---

### Task 16.6: Email Integration

**Connect SuiteCRM to iRedMail for email tracking**

---

#### Step 1: Configure Group Email Account

**Navigate: Admin → Inbound Email**

**Click: Create**

**Configuration:**
```
Name: CRM Shared Mailbox
Email Address: crm@lab.local

Server Type: IMAP
Server: 10.0.50.14
Port: 993
Use SSL: Yes

Username: crm@lab.local
Password: [password]

Monitored Folders: INBOX

Options:
  ✓ Create Case from Email
  ✓ Auto-import
  ✓ Link emails to records
```

**Save**

**Test:** Click "Test Settings" → Should connect successfully

**Now emails to crm@lab.local appear in SuiteCRM!**

---

#### Step 2: Configure Personal Email

**As a user (guard1):**

**Navigate: Email → Settings**

**Configure:**
```
Email Address: guard1@lab.local

Outbound:
  SMTP Server: 10.0.50.14
  Port: 587
  Use TLS: Yes
  Auth Required: Yes
  Username: guard1@lab.local
  Password: [password]

Inbound:
  Server: 10.0.50.14
  Protocol: IMAP
  Port: 993
  SSL: Yes
  Username: guard1@lab.local
  Password: [password]
```

**Save & Test**

**Now you can:**
- Send emails from CRM
- Emails automatically linked to contacts
- Track email history per customer

---

### Task 16.7: FreePBX Integration (Click-to-Call)

**Integrate CRM with phone system**

---

#### Step 1: Install Asterisk Connector

**SuiteCRM has built-in Asterisk integration:**

**Navigate: Admin → Module Loader**

**Search: Asterisk**

**If not installed:**

1. Download Asterisk Integration module
2. Upload via Module Loader
3. Install

---

#### Step 2: Configure Asterisk Connection

**Navigate: Admin → Asterisk Settings**

**Configuration:**
```
Asterisk Server: 10.0.50.16
AMI Port: 5038
AMI Username: admin
AMI Password: [Create in FreePBX]
```

**In FreePBX (to create AMI user):**

```bash
ssh labadmin@10.0.50.16
sudo nano /etc/asterisk/manager.conf
```

**Add:**
```
[admin]
secret = CrmAmi2024!
deny = 0.0.0.0/0.0.0.0
permit = 10.0.50.0/255.255.255.0
read = system,call,log,verbose,command,agent,user
write = system,call,log,verbose,command,agent,user
```

**Reload Asterisk:**
```bash
sudo asterisk -rx "manager reload"
```

**Back in SuiteCRM:**

**Test Connection** → Should show "Connected"

---

#### Step 3: Assign Extensions to Users

**Navigate: Admin → Users**

**For each user:**

```
guard1:
  Extension: 101
  
guard2:
  Extension: 102
```

**Save**

---

#### Step 4: Test Click-to-Call

**Open a Contact record (John Smith)**

**Click phone number:** `(555) 123-4567`

**Pop-up appears:** "Calling (555) 123-4567 from extension 101"

**Your phone (extension 101) rings**

**When you answer:**
- System dials external number
- Call is logged in CRM automatically!

**Call ends:**
- Duration recorded
- Notes can be added
- Call linked to contact

**This is HUGE for sales productivity!**

---

**✅ SuiteCRM Installation Complete!**

**What you've accomplished:**
- ✅ Installed SuiteCRM 8.6
- ✅ Configured PostgreSQL database
- ✅ Integrated with FreeIPA (LDAP)
- ✅ Set up email integration
- ✅ Created accounts, contacts, opportunities
- ✅ Built sales dashboard
- ✅ Integrated with FreePBX (click-to-call)
- ✅ Configured mobile access

**Your sales team now has:**
- Complete customer database
- Sales pipeline tracking
- Email integration
- Phone integration
- Calendar and tasks
- Mobile CRM access
- Automated workflows

---

[Document continues with Exercise 17: Odoo ERP Deployment, Exercise 18: OpenKM Document Management, Exercise 19: Taiga Project Management, Exercise 20: Snipe-IT Asset Management, Exercise 21: GLPI IT Service Management, Exercise 22: Back Office Integration, and Exercise 23: End-to-End Workflows]

**[Continuing to next file due to length...]**
