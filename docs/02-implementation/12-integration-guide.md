---
doc: 12
title: "Integration Guide — Cross-Service Procedures"
category: implementation
date: 2026-02-27
source: architecture/integrations.md
---
# Complete Enterprise IT Stack - Integration Guide
## Cross-System Integration and Workflows

---

## Document Purpose

This guide provides complete integration instructions for connecting all systems in your enterprise IT stack into a unified platform. Each integration is documented with:
- **Purpose** - Why this integration matters
- **Prerequisites** - What must be in place first
- **Step-by-step procedures** - Exact commands and configurations
- **Testing** - How to verify it works
- **Troubleshooting** - Common issues and solutions

---

## Table of Contents

1. [Integration Overview](#integration-overview)
2. [SSO Integration Matrix](#sso-integration-matrix)
3. [FreePBX Integrations](#freepbx-integrations)
4. [CRM Integrations](#crm-integrations)
5. [ERP Integrations](#erp-integrations)
6. [Document Management Integrations](#document-management-integrations)
7. [Workflow Automation](#workflow-automation)
8. [API Integration Examples](#api-integration-examples)
9. [Complete Workflow Scenarios](#complete-workflow-scenarios)

---

## Integration Overview

### Complete Integration Map

```
┌─────────────────────────────────────────────────────────────────┐
│                   ENTERPRISE INTEGRATION MAP                     │
└─────────────────────────────────────────────────────────────────┘

IDENTITY LAYER (Foundation):
┌──────────┐         ┌──────────┐
│ FreeIPA  │────────▶│ Keycloak │
│  (LDAP)  │  Users  │  (SSO)   │
└────┬─────┘         └────┬─────┘
     │                    │
     │ LDAP Auth          │ SSO (SAML/OAuth)
     ▼                    ▼
┌────────────────────────────────────────┐
│        ALL APPLICATION SERVICES         │
│  Nextcloud, Mattermost, Jitsi,         │
│  Mail, Zammad, FreePBX, SuiteCRM,      │
│  Odoo, OpenKM, Taiga, Snipe-IT, GLPI   │
└────────────────────────────────────────┘

DATA LAYER:
┌──────────┐    ┌──────────┐    ┌──────────┐
│PostgreSQL│    │  Redis   │    │Elasticsearch│
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     ├───────────────┴───────────────┤
     │ Database Connections          │
     ▼                               ▼
┌────────────────────┐    ┌────────────────────┐
│  Application Data  │    │   Search Indexes   │
│  (All Services)    │    │   (Zammad, GLPI)   │
└────────────────────┘    └────────────────────┘

COMMUNICATION LAYER:
┌──────────┐    ┌──────────┐    ┌──────────┐
│iRedMail  │    │ FreePBX  │    │Mattermost│
│  (SMTP)  │    │  (SIP)   │    │ (WebRTC) │
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     └───────────────┴───────────────┘
     │ Notifications & Communications │
     ▼                               ▼
┌────────────────────────────────────────┐
│         USER NOTIFICATIONS             │
│  Email, SMS, Push, In-App              │
└────────────────────────────────────────┘

BUSINESS PROCESS LAYER:
┌──────────┐    ┌──────────┐    ┌──────────┐
│ SuiteCRM │◀──▶│   Odoo   │◀──▶│ OpenKM   │
│ (Sales)  │    │  (ERP)   │    │  (Docs)  │
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     ├───────────────┴───────────────┤
     │ Business Data Synchronization │
     ▼                               ▼
┌────────────────────┐    ┌────────────────────┐
│  Customer Data     │    │   Financial Data   │
│  (360° view)       │    │   (Single truth)   │
└────────────────────┘    └────────────────────┘

PROJECT & IT LAYER:
┌──────────┐    ┌──────────┐    ┌──────────┐
│  Taiga   │◀──▶│Snipe-IT  │◀──▶│   GLPI   │
│(Projects)│    │ (Assets) │    │  (ITSM)  │
└────┬─────┘    └────┬─────┘    └────┬─────┘
     │               │               │
     └───────────────┴───────────────┘
     │  IT Operations & Project Mgmt  │
     ▼                               ▼
┌────────────────────┐    ┌────────────────────┐
│  Project Tracking  │    │   Asset Lifecycle  │
│  (Time, Budget)    │    │   (ITAM/ITSM)      │
└────────────────────┘    └────────────────────┘
```

### Integration Complexity Levels

**Level 1: Basic (LDAP/SSO)**
- Simple configuration
- Works out-of-box
- Minimal customization
- Examples: Most apps authenticate via Keycloak

**Level 2: Moderate (API/WebDAV)**
- Requires API keys
- Some scripting
- Configuration files
- Examples: File sharing, calendar sync

**Level 3: Advanced (Custom Development)**
- Custom code/scripts
- Webhooks/event handlers
- Database queries
- Examples: Real-time sync, complex workflows

---

## SSO Integration Matrix

### Keycloak Client Configuration

**For each application, create Keycloak client:**

#### Template Configuration

```
Client ID: [application-name]
Name: [Human Readable Name]
Client Protocol: openid-connect (or saml for SAML apps)
Access Type: confidential
Valid Redirect URIs: 
  https://[app].domain.com/*
  http://[app].lab.local/*
Web Origins: *
```

#### Application-Specific Configurations

**Nextcloud (OIDC):**
```
Client ID: nextcloud
Redirect URIs: 
  https://cloud.domain.com/*
  https://cloud.domain.com/apps/user_oidc/code
Client Scopes:
  - email (default)
  - profile (default)
  - groups (add mapper)
```

**Mattermost (OAuth 2.0):**
```
Client ID: mattermost
Redirect URIs:
  https://chat.domain.com/signup/oauth/complete
  https://chat.domain.com/login/oauth/complete
Mappers:
  - email → email
  - preferred_username → username
  - given_name → first_name
  - family_name → last_name
```

**SuiteCRM (SAML):**
```
Client ID: suitecrm
Client Protocol: saml
Client SAML Endpoint: https://crm.domain.com/index.php?module=Users&action=Authenticate
Name ID Format: username
Sign Assertions: On
Sign Documents: On
Include AuthnStatement: On
Mappers:
  - email → email
  - username → uid
  - firstName → givenName
  - lastName → sn
```

**Odoo (OAuth 2.0):**
```
Client ID: odoo
Redirect URIs:
  https://erp.domain.com/auth_oauth/signin
Mappers:
  - email → email
  - preferred_username → login
  - name → name
```

**Taiga (OIDC):**
```
Client ID: taiga
Redirect URIs:
  https://projects.domain.com/login
Access Type: public (Taiga is SPA)
Web Origins: https://projects.domain.com
```

**GLPI (SAML):**
```
Client ID: glpi
Client Protocol: saml
Assertion Consumer URL: https://itsm.domain.com/front/login.php
Name ID: email
Sign Assertions: On
```

---

## FreePBX Integrations

### Integration 1: FreePBX ↔ SuiteCRM (Click-to-Call)

**Purpose:** Click phone numbers in CRM to automatically dial from your desk phone

**Architecture:**
```
User clicks phone number in SuiteCRM web browser
         ↓
SuiteCRM sends AMI command to FreePBX
         ↓
FreePBX initiates call:
  1. Rings user's extension
  2. User answers
  3. FreePBX dials external number
  4. Call connects
         ↓
Call details logged back to SuiteCRM
  - Duration
  - Outcome
  - Recording link
```

**Prerequisites:**
- ✅ FreePBX installed with AMI enabled
- ✅ SuiteCRM installed
- ✅ Network connectivity between servers

**Step 1: Enable AMI in FreePBX**

**SSH to FreePBX server:**

```bash
ssh labadmin@10.0.50.16
sudo nano /etc/asterisk/manager.conf
```

**Add AMI user:**

```ini
[general]
enabled = yes
port = 5038
bindaddr = 10.0.50.16

[suitecrm]
secret = CrmAmi2024!
deny = 0.0.0.0/0.0.0.0
permit = 10.0.50.17/255.255.255.0
read = system,call,log,verbose,command,agent,user,originate
write = system,call,log,verbose,command,agent,user,originate
writetimeout = 5000
```

**Reload Asterisk:**

```bash
sudo asterisk -rx "manager reload"
```

**Test AMI connection:**

```bash
telnet 10.0.50.16 5038
```

Should see:
```
Asterisk Call Manager/2.10.0
```

Type:
```
Action: Login
Username: suitecrm
Secret: CrmAmi2024!

Action: Logoff
```

**Step 2: Configure SuiteCRM**

**In SuiteCRM web interface:**

**Navigate:** Admin → Asterisk Integration

**If module not installed:**

```bash
# On CRM server
cd /var/www/suitecrm
sudo -u www-data composer require salesagility/asterisk-integration
sudo -u www-data php bin/console extension:install asterisk
```

**Configure integration:**

```
Asterisk Server: 10.0.50.16
AMI Port: 5038
AMI Username: suitecrm
AMI Password: CrmAmi2024!

Dial Context: from-internal
Dial Prefix: (leave blank)

Call Popup: Enable
Call Recording: Enable (if FreePBX has recording on)
```

**Save & Test Connection**

**Step 3: Map Users to Extensions**

**Navigate:** Admin → Users

**For each user:**

```
Username: guard1
Extension: 101

Username: guard2
Extension: 102
```

**Save**

**Step 4: Test Click-to-Call**

1. Open contact with phone number: (555) 123-4567
2. Click the phone number
3. Pop-up: "Calling (555) 123-4567 from extension 101"
4. Your desk phone (ext 101) rings
5. Answer it
6. System dials (555) 123-4567
7. Call connects!
8. Call is logged in contact's activity history

**Troubleshooting:**

```
Issue: "Connection failed"
Solution: 
  - Check firewall allows port 5038
  - Verify AMI credentials
  - Test: telnet 10.0.50.16 5038

Issue: "Extension not found"
Solution:
  - Verify extension exists in FreePBX
  - Check user mapping in SuiteCRM

Issue: Phone doesn't ring
Solution:
  - Verify extension is registered
  - Check FreePBX CLI: asterisk -rvvv
  - Watch for originate command
```

---

### Integration 2: FreePBX ↔ Zammad (Phone Tickets)

**Purpose:** Automatically create support tickets from phone calls

**Architecture:**
```
Customer calls support number
         ↓
FreePBX answers, plays IVR
         ↓
Customer enters ticket option
         ↓
Call routed to support queue
         ↓
FreePBX sends webhook to Zammad
         ↓
Zammad creates ticket with:
  - Caller ID
  - Call recording
  - Call duration
         ↓
Agent receives ticket notification
```

**Prerequisites:**
- ✅ FreePBX installed
- ✅ Zammad installed
- ✅ Both servers can communicate

**Step 1: Install FreePBX Webhook Module**

```bash
ssh labadmin@10.0.50.16
cd /tmp
wget https://github.com/lgaetz/webhook/archive/master.zip
unzip master.zip
sudo cp -r webhook-master/* /var/lib/asterisk/agi-bin/
sudo chown -R asterisk:asterisk /var/lib/asterisk/agi-bin/
sudo chmod +x /var/lib/asterisk/agi-bin/webhook.php
```

**Step 2: Create Webhook in Zammad**

**In Zammad:**

**Navigate:** Admin → Webhooks

**Create Webhook:**
```
Name: FreePBX Integration
Endpoint: Internal (Zammad receives)
Trigger: None (we'll call it from FreePBX)
```

**Note the webhook URL:** 
`https://desk.domain.com/api/v1/integration/webhook/[token]`

**Step 3: Configure FreePBX Dialplan**

```bash
sudo nano /etc/asterisk/extensions_custom.conf
```

**Add:**

```
[from-internal-custom]
; When call comes in, create Zammad ticket
exten => _X.,1,NoOp(Call from ${CALLERID(num)} to ${EXTEN})
same => n,AGI(webhook.php,https://desk.domain.com/api/v1/integration/webhook/TOKEN,POST,"caller=${CALLERID(num)}&extension=${EXTEN}&uniqueid=${UNIQUEID}")
same => n,Return()
```

**Reload dialplan:**

```bash
sudo asterisk -rx "dialplan reload"
```

**Step 4: Configure Zammad to Process Webhook**

**Create Trigger in Zammad:**

**Navigate:** Admin → Trigger

**Create:**
```
Name: Create Ticket from Call
Conditions:
  - Webhook received
  - caller_id exists
Actions:
  - Create ticket
  - Title: "Phone call from {caller_id}"
  - Group: Support
  - Priority: Normal
  - State: New
```

**Step 5: Test**

1. Make test call to support extension
2. Zammad should create ticket
3. Ticket includes caller ID and call details

---

### Integration 3: FreePBX ↔ FreeIPA (Extension Provisioning)

**Purpose:** Automatically create phone extensions when user added to FreeIPA

**Architecture:**
```
New user added to FreeIPA
         ↓
FreeIPA hook script triggered
         ↓
Script calls FreePBX API
         ↓
FreePBX creates extension:
  - Extension number = last 3 digits of employee ID
  - Password = auto-generated
  - Voicemail = user's email
         ↓
User receives welcome email with extension details
```

**Step 1: Install FreePBX API Module**

**In FreePBX GUI:**

**Navigate:** Admin → Module Admin

**Install:** "User Control Panel" (includes API)

**Or via CLI:**

```bash
ssh labadmin@10.0.50.16
fwconsole ma downloadinstall userman
fwconsole reload
```

**Step 2: Create API Token**

**Navigate:** Admin → API

**Create Token:**
```
Application: FreeIPA Integration
Token: [auto-generated, save this!]
Permissions:
  - Extensions: Read, Write
  - Voicemail: Read, Write
```

**Save token:** `fbx_api_token_abc123def456`

**Step 3: Create FreeIPA Hook Script**

**On FreeIPA server:**

```bash
ssh labadmin@10.0.50.11
sudo nano /usr/local/bin/freepbx-provision.sh
```

**Script content:**

```bash
#!/bin/bash
# FreeIPA hook to provision FreePBX extension

# Get user details from FreeIPA
USERNAME=$1
EMAIL=$(ipa user-show $USERNAME --all | grep "Mail address:" | awk '{print $3}')
FIRSTNAME=$(ipa user-show $USERNAME --all | grep "First name:" | awk '{print $3}')
LASTNAME=$(ipa user-show $USERNAME --all | grep "Last name:" | awk '{print $3}')

# Generate extension (simple: user ID number)
EXTENSION=$(ipa user-show $USERNAME --all | grep "User ID:" | awk '{print $3}' | tail -c 4)

# Generate random password
PASSWORD=$(openssl rand -base64 12)

# Call FreePBX API to create extension
curl -X POST "http://10.0.50.16/admin/api/api/extensions" \
  -H "Authorization: Bearer fbx_api_token_abc123def456" \
  -H "Content-Type: application/json" \
  -d "{
    \"extension\": \"$EXTENSION\",
    \"name\": \"$FIRSTNAME $LASTNAME\",
    \"secret\": \"$PASSWORD\",
    \"voicemail\": \"enabled\",
    \"email\": \"$EMAIL\",
    \"vm_password\": \"1234\"
  }"

# Send welcome email
mail -s "Your Phone Extension" $EMAIL << EOF
Hello $FIRSTNAME,

Your phone extension has been created:

Extension: $EXTENSION
Password: $PASSWORD
Voicemail: Dial *97

You can configure a softphone or desk phone with these credentials.

Server: voip.lab.local
Port: 5060

Thanks,
IT Department
EOF

echo "Extension $EXTENSION created for $USERNAME"
```

**Make executable:**

```bash
sudo chmod +x /usr/local/bin/freepbx-provision.sh
```

**Step 4: Configure IPA Hook**

```bash
sudo nano /etc/ipa/ipa-hooks.d/user-add.sh
```

**Content:**

```bash
#!/bin/bash
/usr/local/bin/freepbx-provision.sh "$1"
```

**Make executable:**

```bash
sudo chmod +x /etc/ipa/ipa-hooks.d/user-add.sh
```

**Step 5: Test**

```bash
ipa user-add testuser5 --first=Test --last=User5 --email=test5@lab.local --password
```

**Check:**
1. Email sent to test5@lab.local
2. Extension created in FreePBX
3. Can register softphone with credentials

---

## CRM Integrations

### Integration 4: SuiteCRM ↔ Odoo (Customer Sync)

**Purpose:** Sync customers between CRM (sales) and ERP (billing/operations)

**Flow:**
```
Sales wins deal in CRM
         ↓
Customer account synced to Odoo
         ↓
Sales order created in Odoo
         ↓
Invoice generated
         ↓
Payment recorded
         ↓
Status updated in CRM
```

**Step 1: Install Odoo Connector in SuiteCRM**

**Option A: Manual Integration (API-based)**

**Create integration script:**

```bash
# On CRM server
sudo nano /var/www/suitecrm/custom/odoo-sync.php
```

```php
<?php
// SuiteCRM to Odoo customer sync

require_once('include/entryPoint.php');

// Odoo credentials
$odoo_url = "http://10.0.50.18:8069";
$odoo_db = "odoo";
$odoo_user = "admin@lab.local";
$odoo_password = "OdooAdmin2024!";

// Authenticate with Odoo
$auth = xmlrpc_encode_request('authenticate', array(
    $odoo_db, $odoo_user, $odoo_password, array()
));

$context = stream_context_create(array('http' => array(
    'method' => "POST",
    'header' => "Content-Type: text/xml",
    'content' => $auth
)));

$auth_file = file_get_contents($odoo_url."/xmlrpc/2/common", false, $context);
$uid = xmlrpc_decode($auth_file);

// Get customers from SuiteCRM that need sync
$bean = BeanFactory::getBean('Accounts');
$accounts = $bean->get_full_list('', "accounts.odoo_id IS NULL");

foreach ($accounts as $account) {
    // Create customer in Odoo
    $partner_data = array(
        'name' => $account->name,
        'email' => $account->email1,
        'phone' => $account->phone_office,
        'street' => $account->billing_address_street,
        'city' => $account->billing_address_city,
        'zip' => $account->billing_address_postalcode,
        'country_id' => 1, // Adjust based on country
        'customer_rank' => 1,
        'is_company' => true
    );
    
    $create = xmlrpc_encode_request('execute_kw', array(
        $odoo_db, $uid, $odoo_password,
        'res.partner', 'create',
        array($partner_data)
    ));
    
    $create_context = stream_context_create(array('http' => array(
        'method' => "POST",
        'header' => "Content-Type: text/xml",
        'content' => $create
    )));
    
    $partner_id = xmlrpc_decode(file_get_contents($odoo_url."/xmlrpc/2/object", false, $create_context));
    
    // Update SuiteCRM with Odoo ID
    $account->odoo_id_c = $partner_id;
    $account->save();
    
    echo "Synced: {$account->name} -> Odoo ID: {$partner_id}\n";
}
?>
```

**Make executable:**

```bash
sudo chown www-data:www-data /var/www/suitecrm/custom/odoo-sync.php
sudo chmod +x /var/www/suitecrm/custom/odoo-sync.php
```

**Step 2: Create Cron Job**

```bash
sudo crontab -e
```

**Add:**

```
# Sync CRM to Odoo every hour
0 * * * * cd /var/www/suitecrm && php custom/odoo-sync.php >> /var/log/crm-odoo-sync.log 2>&1
```

**Step 3: Test Sync**

```bash
sudo -u www-data php /var/www/suitecrm/custom/odoo-sync.php
```

**Check Odoo:**

**Navigate:** Contacts

**Should see customers from CRM!**

---

### Integration 5: SuiteCRM ↔ Nextcloud (Calendar Sync)

**Purpose:** Sync CRM meetings to Nextcloud calendar

**Architecture:**
```
Sales rep schedules meeting in CRM
         ↓
Meeting saved to SuiteCRM database
         ↓
CalDAV sync pushes to Nextcloud
         ↓
Calendar appears in Nextcloud Calendar
         ↓
Mobile devices sync via CalDAV
```

**Step 1: Enable CalDAV in Nextcloud**

**Already enabled by default in Nextcloud!**

**Get CalDAV URL:**

**Navigate:** Nextcloud → Calendar → Settings

**Calendar URL:** 
`https://cloud.domain.com/remote.php/dav/calendars/guard1/personal/`

**Step 2: Configure SuiteCRM CalDAV**

**In SuiteCRM:**

**Navigate:** User Profile → Calendar Settings

**Configure:**
```
CalDAV Server: https://cloud.domain.com/remote.php/dav
Username: guard1
Password: [user password]
Calendar: personal

Sync Direction: Two-way
Sync Frequency: Every 15 minutes
```

**Save**

**Step 3: Test Sync**

1. Create meeting in SuiteCRM
2. Wait 15 minutes (or trigger manual sync)
3. Check Nextcloud Calendar
4. Meeting should appear!

---

## ERP Integrations

### Integration 6: Odoo ↔ FreeIPA (Employee Sync)

**Purpose:** Automatically sync employees from Odoo HR to FreeIPA

**Flow:**
```
HR creates employee in Odoo
         ↓
Employee data synced to FreeIPA
         ↓
LDAP account created
         ↓
Email provisioned
         ↓
VoIP extension created
         ↓
Access to all systems (SSO)
```

**Step 1: Install Odoo LDAP Module**

**In Odoo:**

**Navigate:** Apps → Remove "Apps" filter → Search "LDAP"

**Install:** "LDAP Authentication"

**Step 2: Configure LDAP Connection**

**Navigate:** Settings → Users & Companies → LDAP Authentication

**Create:**
```
LDAP Server: 10.0.50.11
Port: 389
Use TLS: Yes

User DN: cn=users,cn=accounts,dc=lab,dc=local
Bind DN: uid=admin,cn=users,cn=accounts,dc=lab,dc=local
Password: [FreeIPA admin password]

User Filter: (objectClass=person)
```

**Step 3: Create Sync Script**

```bash
# On Odoo server
sudo nano /usr/local/bin/odoo-ipa-sync.py
```

```python
#!/usr/bin/env python3
import xmlrpc.client
import subprocess
import sys

# Odoo connection
odoo_url = "http://localhost:8069"
odoo_db = "odoo"
odoo_user = "admin@lab.local"
odoo_password = "OdooAdmin2024!"

# Connect to Odoo
common = xmlrpc.client.ServerProxy('{}/xmlrpc/2/common'.format(odoo_url))
uid = common.authenticate(odoo_db, odoo_user, odoo_password, {})
models = xmlrpc.client.ServerProxy('{}/xmlrpc/2/object'.format(odoo_url))

# Get employees from Odoo
employees = models.execute_kw(odoo_db, uid, odoo_password,
    'hr.employee', 'search_read',
    [[['active', '=', True]]],
    {'fields': ['name', 'work_email', 'job_id', 'department_id']})

for emp in employees:
    # Generate username from email
    username = emp['work_email'].split('@')[0] if emp['work_email'] else emp['name'].lower().replace(' ', '.')
    
    # Check if user exists in FreeIPA
    result = subprocess.run(['ipa', 'user-show', username], 
                          capture_output=True, text=True)
    
    if result.returncode != 0:
        # User doesn't exist, create
        first_name = emp['name'].split()[0]
        last_name = ' '.join(emp['name'].split()[1:])
        
        subprocess.run([
            'ipa', 'user-add', username,
            '--first=' + first_name,
            '--last=' + last_name,
            '--email=' + emp['work_email'],
            '--title=' + (emp['job_id'][1] if emp['job_id'] else ''),
            '--password'  # Will prompt for temp password
        ])
        
        print(f"Created user: {username}")
    else:
        print(f"User exists: {username}")
```

**Make executable:**

```bash
sudo chmod +x /usr/local/bin/odoo-ipa-sync.py
```

**Step 4: Schedule Sync**

```bash
sudo crontab -e
```

**Add:**

```
# Sync Odoo employees to FreeIPA daily at 2 AM
0 2 * * * /usr/local/bin/odoo-ipa-sync.py >> /var/log/odoo-ipa-sync.log 2>&1
```

---

[Document continues with remaining integrations...]

## Quick Reference: All Integration Points

### Master Integration Table

| Source | Target | Method | Purpose | Complexity |
|--------|--------|--------|---------|------------|
| FreeIPA | Keycloak | LDAP | User federation | ⭐ Basic |
| Keycloak | All Apps | SAML/OAuth | Single Sign-On | ⭐ Basic |
| FreePBX | SuiteCRM | AMI | Click-to-call | ⭐⭐ Moderate |
| FreePBX | Zammad | Webhook | Phone tickets | ⭐⭐ Moderate |
| FreePBX | FreeIPA | API | Extension provisioning | ⭐⭐⭐ Advanced |
| SuiteCRM | Odoo | XML-RPC | Customer sync | ⭐⭐⭐ Advanced |
| SuiteCRM | Nextcloud | CalDAV | Calendar sync | ⭐⭐ Moderate |
| SuiteCRM | FreePBX | AMI | Call logging | ⭐⭐ Moderate |
| SuiteCRM | OpenKM | WebDAV | Document linking | ⭐⭐ Moderate |
| Odoo | FreeIPA | LDAP | Employee sync | ⭐⭐⭐ Advanced |
| Odoo | SuiteCRM | API | Customer data | ⭐⭐⭐ Advanced |
| Odoo | Taiga | REST API | Time import | ⭐⭐⭐ Advanced |
| Odoo | Snipe-IT | API | Asset procurement | ⭐⭐⭐ Advanced |
| Odoo | OpenKM | WebDAV | Document storage | ⭐⭐ Moderate |
| OpenKM | All Apps | WebDAV/API | Central docs | ⭐⭐ Moderate |
| Taiga | Mattermost | Webhooks | Notifications | ⭐⭐ Moderate |
| Taiga | Nextcloud | WebDAV | File storage | ⭐⭐ Moderate |
| Taiga | Odoo | API | Time export | ⭐⭐⭐ Advanced |
| Snipe-IT | FreeIPA | LDAP | User sync | ⭐ Basic |
| Snipe-IT | GLPI | API | Asset sync | ⭐⭐⭐ Advanced |
| Snipe-IT | Odoo | API | Procurement | ⭐⭐⭐ Advanced |
| GLPI | FreeIPA | LDAP | Authentication | ⭐ Basic |
| GLPI | Zammad | API | Ticket sync | ⭐⭐⭐ Advanced |
| GLPI | Snipe-IT | API | Asset data | ⭐⭐⭐ Advanced |
| GLPI | Keycloak | SAML | SSO | ⭐⭐ Moderate |
| All Apps | PostgreSQL | Native | Database | ⭐ Basic |
| All Apps | Redis | Native | Cache | ⭐ Basic |
| All Apps | Traefik | HTTP | Reverse proxy | ⭐ Basic |
| All Apps | Zabbix | Agent | Monitoring | ⭐ Basic |
| All Apps | Graylog | Syslog | Logging | ⭐ Basic |

**Total Integrations:** 30+  
**Complexity:**
- ⭐ Basic: Configuration only, no code
- ⭐⭐ Moderate: Some scripting required
- ⭐⭐⭐ Advanced: Custom development needed

---

## Testing Checklist

### Complete Integration Testing

**SSO Testing:**
- [ ] Login to Keycloak
- [ ] Access Nextcloud (auto-login)
- [ ] Access Mattermost (auto-login)
- [ ] Access SuiteCRM (auto-login)
- [ ] Access Odoo (auto-login)
- [ ] Access all systems with one password

**VoIP Integration:**
- [ ] Click-to-call from CRM works
- [ ] Call logged in CRM
- [ ] Voicemail sent to email
- [ ] Phone ticket created in Zammad
- [ ] Conference bridge works

**Business Process:**
- [ ] Lead in CRM converts to customer
- [ ] Customer synced to Odoo
- [ ] Invoice generated in Odoo
- [ ] Document stored in OpenKM
- [ ] Email sent via iRedMail
- [ ] Support ticket in Zammad

**Project Workflow:**
- [ ] Project created in Taiga
- [ ] Time tracked in Taiga
- [ ] Time synced to Odoo
- [ ] Invoice generated from time
- [ ] Documents in Nextcloud

**IT Operations:**
- [ ] New employee in Odoo
- [ ] Account in FreeIPA
- [ ] Email created
- [ ] Extension provisioned
- [ ] Asset assigned in Snipe-IT
- [ ] GLPI ticket for onboarding

---

**Total Integration Value:**

All systems work as **one unified platform** instead of disconnected silos.

**User Experience:** One login, one interface, one source of truth.

**Business Value:** Complete visibility across entire organization.

**Cost Savings:** $100,000+ per year vs commercial alternatives.
