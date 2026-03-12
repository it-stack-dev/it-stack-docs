# IT-Stack Service Integrations Guide

**Document:** 25  
**Location:** `docs/05-guides/25-integrations-guide.md`  
**Last Updated:** March 2026

This guide covers configuring cross-service integrations: Mattermost ↔ Taiga webhook notifications, Graylog → Zabbix log-based alerting, email synchronization across both Nextcloud Mail (web) and Thunderbird (desktop), and the FreePBX ↔ SuiteCRM CTI integration (on-premises only).

---

## Table of Contents

1. [Mattermost → Taiga Webhook](#1-mattermost--taiga-webhook-project-notifications)
2. [Graylog → Zabbix Log-Based Alerts](#2-graylog--zabbix-log-based-alert-triggers)
3. [Email Sync: Nextcloud + Thunderbird (IMAP)](#3-email-sync-nextcloud--thunderbird-imap)
4. [FreePBX ↔ SuiteCRM CTI](#4-freepbx--suitecrm-cti-on-premises-only)

---

## 1. Mattermost → Taiga Webhook (Project Notifications)

**Goal:** When Taiga project events occur (new issue, task assigned, sprint completed), a notification posts automatically to Mattermost's `#dev` channel.

**Flow:**  
```
Taiga event → Taiga outbound webhook → Mattermost incoming webhook → #dev channel
```

### 1.1 Create Mattermost Incoming Webhook

**In the Mattermost web UI** (http://4.154.17.25:8265):

1. Log in as admin
2. **Main Menu** (≡) → **Integrations** → **Incoming Webhooks** → **Add Incoming Webhook**
3. Fill in:
   | Field | Value |
   |-------|-------|
   | Title | Taiga Project Notifications |
   | Description | IT-Stack project events from Taiga |
   | Channel | `#dev` *(create this channel first if it doesn't exist)* |
   | Username | `taiga-bot` |
   | Profile picture | (optional — use Taiga logo) |
4. **Save** → copy the webhook URL

The URL looks like:
```
http://4.154.17.25:8265/hooks/xxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Create `#dev` channel first** (if it doesn't exist):

```bash
# Via Mattermost API (replace TOKEN and TEAM_ID)
MM_TOKEN="your-admin-token"
TEAM_ID="your-team-id"

curl -s -X POST "http://localhost:8265/api/v4/channels" \
  -H "Authorization: Bearer $MM_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"team_id\": \"$TEAM_ID\",
    \"name\": \"dev\",
    \"display_name\": \"Dev\",
    \"purpose\": \"Development and project notifications\",
    \"type\": \"O\"
  }"
```

### 1.2 Enable Incoming Webhooks in Mattermost

In **System Console** → **Integrations** → **Integration Management**:

| Setting | Value |
|---------|-------|
| Enable incoming webhooks | true |
| Enable webhook username override | true |
| Enable webhook icon override | true |

### 1.3 Configure Taiga Webhook

**In Taiga web UI** (http://4.154.17.25:9001):

1. Log in as admin → **Admin** → **Contrib plugins** (or **Settings** → **Webhooks**)
2. **Create webhook**:
   | Field | Value |
   |-------|-------|
   | Name | Mattermost #dev |
   | URL | `http://mm-demo:8065/hooks/xxxxxxxxxxxxxxxxxx` *(internal Docker URL)* |
   | Key | `taiga-mattermost` *(anything)* |
3. **Save**

> **Docker network note:** Use `http://mm-demo:8065` (internal name) instead of the public IP since both containers are on the `it-stack-demo` network. If Taiga runs on a different docker-compose stack, use the public IP `http://4.154.17.25:8265`.

**Or configure via Taiga API:**

```bash
TAIGA_URL="http://localhost:9001"

# Get auth token
TOKEN=$(curl -s -X POST "$TAIGA_URL/api/v1/auth" \
  -H "Content-Type: application/json" \
  -d '{"type":"normal","username":"admin","password":"123123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['auth_token'])")

# Get project list
curl -s "$TAIGA_URL/api/v1/projects?member=1" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -c "import sys,json; [print(p['id'], p['name']) for p in json.load(sys.stdin)]"

# Create webhook for project (replace PROJECT_ID and WEBHOOK_URL)
PROJECT_ID=1
WEBHOOK_URL="http://mm-demo:8065/hooks/your-webhook-id"

curl -s -X POST "$TAIGA_URL/api/v1/webhooks" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"project\": $PROJECT_ID,
    \"name\": \"Mattermost #dev\",
    \"url\": \"$WEBHOOK_URL\",
    \"key\": \"taiga-mattermost\"
  }" && echo "Webhook created"
```

### 1.4 Test the Integration

```bash
# Send a test message to Mattermost to verify webhook URL works
curl -s -X POST "http://4.154.17.25:8265/hooks/YOUR_WEBHOOK_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "taiga-bot",
    "icon_emoji": ":clipboard:",
    "text": "✅ **Taiga integration test** — webhook is working. Project notifications will appear here."
  }'
```

Expected: a message from `taiga-bot` appears in `#dev` channel.

### 1.5 Taiga → Mattermost Message Format

Taiga sends raw JSON. To format it nicely, you can deploy a small middleware (optional):

```bash
# Option: Use Taiga's built-in Mattermost plugin
# In Taiga admin panel → Contrib → mattermost (if available)
# OR deploy n8n/node-red as a lightweight formatter
# The raw JSON from Taiga is readable even without formatting
```

---

## 2. Graylog → Zabbix Log-Based Alert Triggers

**Goal:** When Graylog detects a log pattern (e.g., too many 500 errors, authentication failures in 5 minutes), it triggers a Zabbix external alert that shows up in the Zabbix dashboard and can page on-call staff.

**Flow:**
```
Service log → Docker logging driver / syslog → Graylog
    → Event Definition (matches pattern)
    → Alert Condition triggered
    → HTTP Notification → Zabbix External API
    → Zabbix Problem created → Zabbix alert/escalation
```

### 2.1 Create Graylog GELF Input (if not already done)

```bash
# Create GELF UDP input for Docker container log ingestion
curl -s -u admin:Admin01! -X POST "http://localhost:9002/api/system/inputs" \
  -H "Content-Type: application/json" \
  -H "X-Requested-By: api" \
  -d '{
    "title": "Docker GELF",
    "type": "org.graylog2.inputs.gelf.udp.GELFUDPInput",
    "global": true,
    "configuration": {
      "bind_address": "0.0.0.0",
      "port": 12201,
      "recv_buffer_size": 262144
    }
  }' | python3 -c "import sys,json; d=json.load(sys.stdin); print('Input ID:', d.get('id','ERROR'))"

# Create Syslog UDP input (for OS logs)
curl -s -u admin:Admin01! -X POST "http://localhost:9002/api/system/inputs" \
  -H "Content-Type: application/json" \
  -H "X-Requested-By: api" \
  -d '{
    "title": "Syslog UDP",
    "type": "org.graylog2.inputs.syslog.udp.SyslogUDPInput",
    "global": true,
    "configuration": {
      "bind_address": "0.0.0.0",
      "port": 1514,
      "recv_buffer_size": 262144
    }
  }' | python3 -c "import sys,json; d=json.load(sys.stdin); print('Input ID:', d.get('id','ERROR'))"
```

### 2.2 Configure Docker to Send Logs to Graylog

```bash
# Update Docker daemon to use GELF logging driver
sudo tee /etc/docker/daemon.json > /dev/null << 'EOF'
{
  "log-driver": "gelf",
  "log-opts": {
    "gelf-address": "udp://localhost:12201",
    "tag": "{{.Name}}"
  }
}
EOF

sudo systemctl restart docker

# IMPORTANT: Existing containers don't pick up the new log driver automatically.
# They need to be recreated. Do this service by service to avoid outage:
# docker stop nc-demo && docker rm nc-demo && docker compose up -d nc-demo
```

### 2.3 Create Graylog Event Definition

Create an alert that fires when more than 5 errors occur in 60 seconds:

**Via Graylog UI** (http://4.154.17.25:9002):

1. **Alerts** → **Event Definitions** → **Create Event Definition**
2. **Step 1 — Details:**
   - Title: `High Error Rate — Service Errors`
   - Priority: High
3. **Step 2 — Condition:**
   - Filter: `source:* AND level:<=3` *(syslog level 3 = error)*
   - OR for HTTP errors: `message:*500* AND message:*error*`
   - Time range: last 60 seconds
   - Execute every: 60 seconds
   - **Threshold:** Greater than, count = 5
4. **Step 3 — Fields:** (add custom fields to the event)
5. **Step 4 — Notifications:** → **Add Notification** → type: **HTTP Notification**
6. **Step 5 — Summary** → **Done**

**Or via API:**

```bash
# Create event definition
curl -s -u admin:Admin01! -X POST "http://localhost:9002/api/events/definitions" \
  -H "Content-Type: application/json" \
  -H "X-Requested-By: api" \
  -d '{
    "title": "High Error Rate",
    "description": "More than 5 errors in 60 seconds",
    "priority": 3,
    "alert": true,
    "config": {
      "type": "aggregation-v1",
      "query": "level:(<=3)",
      "query_parameters": [],
      "streams": [],
      "group_by": ["source"],
      "series": [{"id":"count()","function":"count","field":null}],
      "conditions": {"expression":{"expr":"greater-than","value":5.0,"ref":"count()"}},
      "search_within_ms": 60000,
      "execute_every_ms": 60000
    },
    "field_spec": {},
    "key_spec": ["source"],
    "notification_settings": {"grace_period_ms": 300000,"backlog_size": 5}
  }' | python3 -c "import sys,json; d=json.load(sys.stdin); print('Event def ID:', d.get('id','check response'))"
```

### 2.4 Create Zabbix HTTP Notification in Graylog

**Via Graylog UI:**

1. **Alerts** → **Notifications** → **Create Notification**
2. Type: **HTTP Notification**
3. URL: `http://zabbix-web-s01/api_jsonrpc.php` (internal Docker URL)
4. Method: POST
5. Body template:

```json
{
  "jsonrpc": "2.0",
  "method": "event.acknowledge",
  "params": {
    "eventids": ["1"],
    "message": "Graylog Alert: ${event.message}",
    "action": 6
  },
  "auth": "ZABBIX_API_TOKEN",
  "id": 1
}
```

**Better approach — use Zabbix external alert via HTTP agent:**

### 2.5 Create Zabbix HTTP Agent Item for Graylog Alerts

In Zabbix (**Configuration** → **Hosts** → `lab-single` → **Items** → **Create item**):

| Field | Value |
|-------|-------|
| Name | Graylog Alert Counter |
| Type | External check |
| Key | `graylog_alert_count[error,60]` |
| Type of information | Numeric (unsigned) |
| Update interval | 1m |

Alternatively, use a **Zabbix Trigger** on the Graylog API:

```bash
# Create a Zabbix API token first
ZBX_URL="http://localhost:8307"

# Login to Zabbix API (returns auth token)
ZBX_AUTH=$(curl -s -X POST "$ZBX_URL/api_jsonrpc.php" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc":"2.0","method":"user.login",
    "params":{"username":"Admin","password":"Lab01Password!"},
    "id":1
  }' | python3 -c "import sys,json; print(json.load(sys.stdin)['result'])")

echo "Zabbix auth: $ZBX_AUTH"

# Create API token for persistent use
ZBX_TOKEN=$(curl -s -X POST "$ZBX_URL/api_jsonrpc.php" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",\"method\":\"token.create\",
    \"params\":{
      \"name\":\"graylog-integration\",
      \"userid\":\"1\",
      \"description\":\"Token for Graylog alerts\"
    },
    \"auth\":\"$ZBX_AUTH\",\"id\":1
  }" | python3 -c "import sys,json; print(json.load(sys.stdin)['result']['token'])")

echo "Zabbix API token: $ZBX_TOKEN"
```

### 2.6 Graylog → Zabbix via Script Notification

The most reliable method uses a shell script that Graylog calls:

```bash
# Create the notification script
cat > /opt/graylog-to-zabbix.sh << 'SCRIPT'
#!/bin/bash
# Called by Graylog HTTP notification
# Usage: POST request body is passed via stdin
ZBX_URL="http://localhost:8307/api_jsonrpc.php"
ZBX_TOKEN="${ZBX_API_TOKEN}"  # Set as env var

# Parse Graylog alert
BODY=$(cat)
TITLE=$(echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('event',{}).get('message','Graylog Alert'))" 2>/dev/null)

# Send to Zabbix as external problem
curl -s -X POST "$ZBX_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"problem.acknowledge\",
    \"params\":{
      \"eventids\":[],
      \"message\":\"$TITLE\",
      \"action\":1
    },
    \"auth\":\"$ZBX_TOKEN\",
    \"id\":1
  }"
SCRIPT
chmod +x /opt/graylog-to-zabbix.sh
```

### 2.7 Test Graylog Alerting

```bash
# Send a test log message at error level
logger -n localhost -P 1514 -p local0.err "TEST: High error rate simulation from lab-single"

# Check Graylog received it (wait 30 seconds)
sleep 30
curl -s -u admin:Admin01! "http://localhost:9002/api/search/universal/relative?query=TEST&range=120&limit=5" \
  -H "Accept: application/json" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['total_results'], 'messages found')"
```

---

## 3. Email Sync: Nextcloud + Thunderbird (IMAP)

**Goal:** The same mailbox (`user@itstack.local`) is accessible from both Nextcloud's built-in Mail app (browser) and Thunderbird (desktop). **All actions sync automatically** — reading, deleting, archiving, or moving a message in one client is immediately reflected in the other because IMAP stores messages on the server, not locally.

### How IMAP Sync Works

```
docker-mailserver (IMAP server)
    ├── user@itstack.local (mailbox on server)
    │       ├── INBOX/
    │       ├── Sent/
    │       ├── Drafts/
    │       ├── Trash/
    │       └── Archive/
    │
    ├── Nextcloud Mail app ─────────────► reads/writes server
    │   (browser)                         directly via IMAP
    │
    └── Thunderbird ─────────────────────► reads/writes server
        (desktop)                          directly via IMAP
```

Because both clients connect to the same IMAP server and operate directly on server-side mailboxes, there is nothing to "sync" — both clients always show the same state.

**Read in Nextcloud → shows as read in Thunderbird immediately** ✅  
**Delete in Thunderbird → gone in Nextcloud on next refresh** ✅  
**Archive in either → shows in Archive/ folder in both** ✅

### 3.1 Add Mailbox to docker-mailserver

```bash
# If account doesn't exist yet
docker exec mail-demo setup email add user@itstack.local 'YourPassword'
docker exec mail-demo setup email list

# Verify mailbox exists
docker exec mail-demo setup email list | grep user@itstack.local
```

### 3.2 Configure Nextcloud Mail App

1. In Nextcloud (http://4.154.17.25:8280): top-right menu → **Mail** app
2. If not installed: **Apps** → search "Mail" → **Enable**
3. On first launch, fill in:
   | Field | Value |
   |-------|-------|
   | Name | Your Name |
   | Email address | `user@itstack.local` |
4. If auto-detect fails, use manual setup:
   | Field | Value |
   |-------|-------|
   | IMAP host | `mail-demo` *(internal Docker)* OR `4.154.17.25` *(external)* |
   | IMAP port | `143` |
   | IMAP security | STARTTLS |
   | IMAP username | `user@itstack.local` |
   | IMAP password | *(your mailbox password)* |
   | SMTP host | `mail-demo` OR `4.154.17.25` |
   | SMTP port | `587` |
   | SMTP security | STARTTLS |
   | SMTP username | `user@itstack.local` |
   | SMTP password | *(your mailbox password)* |

> **For Nextcloud running as Docker container:** Use internal hostname `mail-demo` (both containers are on `it-stack-demo` network). This avoids routing through the public IP.

### 3.3 Configure Thunderbird

1. Open Thunderbird → **File** → **New** → **Existing Email Account...**
2. Fill in name, email address (`user@itstack.local`), password
3. Click **Configure manually** (auto-detect won't work for non-standard ports):

| Protocol | Server | Port | SSL | Authentication |
|----------|--------|------|-----|----------------|
| IMAP (Incoming) | `4.154.17.25` | `143` | STARTTLS | Normal password |
| SMTP (Outgoing) | `4.154.17.25` | `587` | STARTTLS | Normal password |

4. Username: `user@itstack.local`
5. Click **Done**
6. Accept the self-signed certificate warning (click **Confirm Security Exception**)

### 3.4 Add CalDAV Calendar in Thunderbird

Thunderbird can also sync Nextcloud Calendar, so calendar events appear in the same client:

1. In Thunderbird: **File** → **New** → **Calendar**
2. **On the network** → **CalDAV**
3. Location: `http://4.154.17.25:8280/remote.php/dav/principals/users/admin/`
4. Thunderbird discovers all calendars automatically
5. Enter Nextcloud credentials (admin / Lab02Password!)

### 3.5 Add CardDAV Contacts in Thunderbird

1. In Thunderbird: **Address Book** → **New Address Book** → **CardDAV**
2. URL: `http://4.154.17.25:8280/remote.php/dav/`
3. Username: `admin`, Password: `Lab02Password!`

### 3.6 Configure Folder Subscriptions (for clean sync)

Thunderbird and Nextcloud Mail should subscribe to the same server-side folders for consistent inbox/archive behavior:

```bash
# Standard IMAP folders created by docker-mailserver:
# INBOX, Sent, Drafts, Trash, Junk, Archive

# In Thunderbird: right-click account → Subscribe → check all folders
# In Nextcloud Mail: automatic — shows all server folders
```

### 3.7 Verify Sync is Working

```bash
# Send a test email from the server itself
docker exec mail-demo bash -c "
  echo 'Subject: IMAP Sync Test
From: admin@itstack.local
To: user@itstack.local

This is a test message to verify IMAP sync.' | sendmail user@itstack.local"

# Wait a few seconds, then check mail was delivered
docker exec mail-demo bash -c "ls /var/mail/vhosts/itstack.local/user/new/"
```

Then verify the message appears in both Nextcloud Mail (browser) and Thunderbird (desktop).

---

## 4. FreePBX ↔ SuiteCRM CTI (On-Premises Only)

> ⚠️ **This integration requires a dedicated VoIP server** (`lab-pbx1` at 10.0.50.16) running FreePBX/Asterisk. It cannot be deployed on the single-VM cloud lab because FreePBX requires:
> - Dedicated network interface (SIP registrations)
> - UDP ports 5060-5061 (SIP) and 10000-20000 (RTP/audio)
> - Dedicated CPU resources for audio processing
>
> **See Phase 3 roadmap.** When lab-pbx1 is provisioned, complete this integration.

### Overview

CTI (Computer Telephony Integration) allows:
- Click-to-call from SuiteCRM contact/lead/account pages
- Incoming calls automatically open the caller's SuiteCRM record
- Calls logged automatically as SuiteCRM Activities
- Call recording linked to CRM history

**Architecture:**

```
SuiteCRM (CRM)
    │
    ├── Click-to-call (outbound)
    │   └── SuiteCRM sends dial request → Asterisk AMI/REST API
    │       └── FreePBX places outbound call to lead/contact
    │
    └── Screen pop (inbound)
        └── FreePBX detects incoming call →
            → looks up CallerID in SuiteCRM REST API →
            → opens contact record in agent's browser
```

### 4.1 FreePBX Prerequisites

```bash
# On lab-pbx1 (10.0.50.16)
fwconsole ma install sugarcrm
fwconsole reload

# Install vtiger/SuiteCRM module in FreePBX
# Admin → Module Admin → Upload → sugarcrm_module.zip
```

### 4.2 SuiteCRM VoIP Configuration

In SuiteCRM (**Admin** → **Telephony / VoIP**):

| Field | Value |
|-------|-------|
| VoIP Provider | FreePBX/Asterisk |
| AMI Host | `10.0.50.16` |
| AMI Port | `5038` |
| AMI Username | `suitecrm-ami` |
| AMI Password | *(set in `/etc/asterisk/manager.conf`)* |
| Call recording path | `/var/spool/asterisk/monitor/` |
| NFS mount point | `/mnt/asterisk-recordings/` |

### 4.3 Asterisk AMI Configuration

```bash
# On lab-pbx1 — /etc/asterisk/manager.conf
cat >> /etc/asterisk/manager.conf << 'EOF'
[suitecrm-ami]
secret=YourAMIPassword
deny=0.0.0.0/0.0.0.0
permit=10.0.50.17/255.255.255.0   ; lab-biz1 where SuiteCRM runs
read=call,originate
write=call,originate
EOF

asterisk -rx "manager reload"
```

### 4.4 Click-to-Call Flow

```
1. Agent views contact in SuiteCRM on lab-biz1
2. Clicks phone number → SuiteCRM sends AMI Originate request to FreePBX
3. FreePBX calls agent's extension first (e.g., ext 101)
4. When agent picks up, FreePBX dials the external number
5. Call bridges — customer and agent are connected
6. SuiteCRM logs call start time, records activity
7. On hangup, SuiteCRM logs call duration, outcome
```

### 4.5 Screen Pop (Inbound)

```bash
# In Asterisk dialplan (/etc/asterisk/extensions.conf)
# For inbound DID context, add lookup before ring:
[inbound-crm-lookup]
exten => _NXXNXXXXXX,1,Set(CALLERID_LOOKUP=${SHELL(curl -s 'http://10.0.50.17:8302/index.php?entryPoint=vcard&module=Contacts&phone=${CALLERID(num)}&return_type=json' | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('name','Unknown'))" 2>/dev/null)})
exten => _NXXNXXXXXX,n,Dial(PJSIP/ext/${EXTEN},30)
```

### 4.6 Recording Integration

```bash
# SuiteCRM fetches recordings from FreePBX NFS share
# Mount on lab-biz1:
echo "10.0.50.16:/var/spool/asterisk/monitor /mnt/asterisk-recordings nfs defaults,_netdev 0 0" >> /etc/fstab
mount -a

# SuiteCRM config: Admin → Telephony → Recording Path: /mnt/asterisk-recordings/
```

### 4.7 Testing CTI (Post-Provisioning)

```bash
# Test AMI connection
asterisk -rx "manager show connected" | grep suitecrm
# Expected: suitecrm-ami [read: call,originate] [write: call,originate]

# Test click-to-call via AMI
echo "Action: Originate
Channel: PJSIP/101
Exten: 5551234567
Context: from-internal
Priority: 1
Timeout: 30000
CallerID: SuiteCRM Test <0>
" | nc 10.0.50.16 5038
```

---

## Related Documentation

| Document | Purpose |
|----------|---------|
| [24-keycloak-oidc-config.md](24-keycloak-oidc-config.md) | SSO setup — authenticate users across all services |
| [23-thunderbird-integration.md](23-thunderbird-integration.md) | Thunderbird full setup (email, calendar, contacts) |
| [18-azure-lab-deployment.md](18-azure-lab-deployment.md) | Live environment reference |
| [17-admin-runbook.md](17-admin-runbook.md) | Day-to-day administration |

---

*IT-Stack Integrations Guide · Version 1.0 · March 2026*
