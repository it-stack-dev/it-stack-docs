# IT-Stack User Onboarding Guide

**Document:** 16  
**Location:** `docs/05-guides/16-user-onboarding.md`  
**Last Updated:** March 2026

---

## Welcome to IT-Stack

This guide helps you get started with the IT-Stack enterprise platform. IT-Stack provides all the tools your organization needs — email, chat, file storage, video conferencing, and more — through a unified login (Single Sign-On).

**Your single username and password gives you access to all services.** You only need to remember one set of credentials.

---

## Step 1: Get Your Account

Your IT administrator will create your account in FreeIPA (the central directory). You will receive:

1. **Username** — usually `firstname.lastname` (e.g., `jane.smith`)
2. **Temporary password** — you must change it on first login
3. **Email address** — automatically provisioned as `username@yourdomain.com`

**Change your temporary password:**
1. Go to: `https://ipa.yourdomain.com/ipa/ui/`
2. Log in with your temporary credentials
3. Click your username (top-right) → **Change Password**
4. Set a strong password (minimum 12 characters, mixed case, numbers, symbols)

---

## Step 2: Service Overview & URLs

| Service | URL | What it's for |
|---------|-----|--------------|
| **Files & Calendar** | `https://cloud.yourdomain.com` | File storage, sharing, calendar, contacts |
| **Chat** | `https://chat.yourdomain.com` | Team messaging, channels, direct messages |
| **Video** | `https://meet.yourdomain.com` | Video meetings, screen sharing |
| **Email (Webmail)** | `https://mail.yourdomain.com/SOGo` | Read and send email in a browser |
| **Help Desk** | `https://desk.yourdomain.com` | Submit and track IT support tickets |
| **Projects** | `https://projects.yourdomain.com` | Project management, tasks, sprints |
| **CRM** | `https://crm.yourdomain.com` | Customer relationship management (sales team) |
| **ERP** | `https://erp.yourdomain.com` | Finance, inventory, HR (management + finance team) |
| **Documents (DMS)** | `https://dms.yourdomain.com` | Document management, versioning, workflows |
| **Assets** | `https://assets.yourdomain.com` | IT asset tracking (IT team) |
| **Phone (Web)** | `https://pbx.yourdomain.com` | Web-based softphone, voicemail |

All services use your **IT-Stack SSO credentials** — no separate passwords.

---

## Step 3: Set Up Email

### Webmail (browser-based)
Go to `https://mail.yourdomain.com/SOGo` and log in with your SSO credentials.

### Email Client (Outlook, Thunderbird, Apple Mail)
Use these settings:

| Setting | Value |
|---------|-------|
| **Incoming (IMAP)** | `mail.yourdomain.com` · Port 993 · SSL/TLS |
| **Outgoing (SMTP)** | `mail.yourdomain.com` · Port 587 · STARTTLS |
| **Username** | Your full email address: `you@yourdomain.com` |
| **Password** | Your IT-Stack password |

**Mobile (iOS/Android):** Use the built-in mail app with the IMAP settings above, or install the **Nextcloud** app and enable the CalDAV/CardDAV sync for calendar and contacts.

---

## Step 4: Set Up File Storage (Nextcloud)

1. Go to `https://cloud.yourdomain.com`
2. Log in with your SSO credentials

### Install the Desktop Sync Client
- Download: `https://nextcloud.com/install/#install-clients`
- Server address: `https://cloud.yourdomain.com`
- Log in with your SSO credentials
- Choose which folders to sync

### Mobile App
- Search for **Nextcloud** in the App Store / Google Play
- Server: `https://cloud.yourdomain.com`

### Storage Quota
Each user starts with **5 GB** of cloud storage. Contact IT if you need more.

---

## Step 5: Set Up Chat (Mattermost)

1. Go to `https://chat.yourdomain.com`
2. Click **Sign in with GitLab SSO** (or the SSO button — exact label set by your admin)
3. You're automatically added to your team's default channels

### Desktop App
- Download: `https://mattermost.com/download/`
- Server URL: `https://chat.yourdomain.com`

### Mobile App
- Search for **Mattermost** in the App Store / Google Play
- Server URL: `https://chat.yourdomain.com`

### Key Channels to Join
| Channel | Purpose |
|---------|---------|
| `#general` | Company-wide announcements |
| `#ops-alerts` | Infrastructure alerts (IT team) |
| `#help` | Ask colleagues for help |
| `#random` | Off-topic conversations |

---

## Step 6: Video Meetings (Jitsi)

1. Go to `https://meet.yourdomain.com`
2. Log in with your SSO credentials (if required by your admin)
3. Enter a room name or click **New Meeting**
4. Share the link with participants

### Tips
- Rooms are password-protected by default — share both the link and password
- No software installation required (browser-based)
- For recurring meetings, create a permanent room with a memorable name
- Screen sharing: click the monitor icon in the toolbar

### Browser Compatibility
Best experience: **Chrome** or **Firefox**. Safari has limited screen-sharing support.

---

## Step 7: Phone & Voicemail (FreePBX)

Your IT administrator assigns you an **extension** (e.g., `1001`).

### Web Softphone
1. Go to `https://pbx.yourdomain.com/ucp`
2. Log in with your IT-Stack credentials
3. Use the browser-based phone — no hardware required

### Desk Phone
If you have a physical IP phone, your IT admin configures it automatically from the directory. Your username and extension are provisioned from FreeIPA.

### Voicemail
- Dial your voicemail box: dial `*97` from any phone
- Default PIN: provided by your IT admin
- **Change your PIN** immediately: press `0` in the voicemail menu

### Mobile Softphone (external)
Use a SIP client (Zoiper, Linphone, or Grandstream Wave):
- SIP Server: `pbx.yourdomain.com` (or internal IP `10.0.50.16`)
- Port: 5060 (UDP/TCP) or 5061 (TLS)
- Username/Auth: your extension number
- Password: provided by IT admin

---

## Step 8: Help Desk (Zammad)

Submit IT support tickets at `https://desk.yourdomain.com`.

### Ways to create a ticket
1. **Web portal** — `https://desk.yourdomain.com` → **New Ticket**
2. **Email** — Send to `support@yourdomain.com` (auto-creates a ticket)
3. **Chat** — `/ticket` command in Mattermost (if configured)

### What to include in a ticket
- Clear subject line describing the problem
- Which service/device is affected
- Steps to reproduce (if applicable)
- Urgency: Low / Normal / High / Critical
- Screenshots if relevant

---

## Password Policy

| Requirement | Policy |
|-------------|--------|
| Minimum length | 12 characters |
| Complexity | Must include: uppercase, lowercase, number, symbol |
| History | Cannot reuse last 10 passwords |
| Expiration | 180 days (you'll receive a reminder at 30, 14, and 7 days) |
| Lockout | 5 failed attempts = 30-minute lockout |

### Self-Service Password Reset
If you forget your password, contact your IT administrator. Password reset is performed via:
1. `https://ipa.yourdomain.com/ipa/ui/` → **Forgot Password** (if configured)
2. Or contact IT via email/phone with your employee ID for verification

---

## Security Best Practices

| Do | Don't |
|----|-------|
| Use a password manager | Reuse passwords across services |
| Lock your screen when away | Share your IT-Stack credentials |
| Log out of shared computers | Click links in unexpected emails |
| Report suspicious activity to IT | Use personal devices for sensitive work without MDM |
| Keep your softphone app updated | Ignore certificate warnings |

---

## Getting Help

| Issue | Contact |
|-------|---------|
| Can't log in | IT Help Desk: `support@yourdomain.com` or ext. 9000 |
| Storage full | IT Help Desk ticket |
| Phone not working | IT Help Desk — mark as **High** priority |
| Email not sending/receiving | IT Help Desk |
| Feature request | IT Help Desk ticket — label as "Enhancement" |

**Self-service check first:** Many issues are resolved by clearing browser cookies, or checking `https://zabbix.yourdomain.com` (if you have IT access) for any active service alerts.

---

*IT-Stack User Onboarding Guide · Version 1.0 · Generated March 2026*
