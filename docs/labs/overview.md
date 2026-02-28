# Enterprise IT Infrastructure Lab Manual - Complete Structure

## Document Organization

The complete lab manual is organized into multiple parts due to its comprehensive nature:

### Part 1: Foundation (COMPLETE - 2,624 lines, 73KB)
File: enterprise-it-lab-manual.md

**Coverage:**
- Exercise 1: Network Infrastructure Setup
  - Physical cabling and switch configuration
  - Bootable USB creation
  - Hardware preparation

- Exercise 2: Ubuntu Server Installation
  - Step-by-step installation for all 5 servers
  - Network configuration during install
  - Post-installation verification

- Exercise 3: Network Configuration
  - Netplan configuration
  - /etc/hosts setup
  - Time synchronization (NTP)
  - Firewall configuration (UFW/firewalld)
  - Network testing and verification

### Part 2: Identity & Database Services (READY)

**Exercise 4: FreeIPA Identity Management (DETAILED)**
- FreeIPA server installation on LAB-ID1
- DNS configuration for all infrastructure
- User and group creation
- Web UI access
- Client enrollment for all servers
- Kerberos authentication testing

**Exercise 5: PostgreSQL Database Server (DETAILED)**
- PostgreSQL 16 installation on LAB-DB1
- Database creation for all applications:
  - keycloak
  - nextcloud
  - mattermost
  - zammad
- User creation with proper permissions
- Redis cache installation
- Network access configuration
- Backup procedures
- Performance tuning

**Exercise 6: Keycloak SSO Installation (DETAILED)**  
- Keycloak 24.0.1 installation on LAB-ID1
- PostgreSQL backend configuration
- LDAP federation with FreeIPA
- Realm creation
- OIDC client configuration for:
  - Nextcloud
  - Mattermost
  - Jitsi
- Group mapping
- SSO testing

### Part 3: Application Services (NEXT)

**Exercise 7: Nextcloud Collaboration Platform**
- Installation on LAB-APP1
- Nginx web server configuration
- PHP-FPM setup
- PostgreSQL database integration
- Redis caching integration
- Keycloak SSO integration
- File storage configuration
- Mobile app configuration

**Exercise 8: Mattermost Team Chat**
- Installation on LAB-APP1
- PostgreSQL database connection
- Keycloak SSO integration
- Team and channel creation
- Mobile app setup
- File uploads configuration

**Exercise 9: Jitsi Video Conferencing**
- Jitsi Meet installation on LAB-APP1
- WebRTC configuration
- Keycloak authentication
- Recording setup
- Mobile compatibility

**Exercise 10: Email Server with iRedMail**
- iRedMail installation on LAB-COMM1
- Postfix MTA configuration
- Dovecot IMAP/POP3
- Webmail (Roundcube/SOGo)
- LDAP authentication
- SPF/DKIM/DMARC setup
- Spam filtering (SpamAssassin)

**Exercise 11: Traefik Reverse Proxy**
- Traefik installation on LAB-PROXY1
- Docker setup
- Dynamic configuration
- SSL/TLS certificates
- Service routing:
  - cloud.lab.local → Nextcloud
  - chat.lab.local → Mattermost
  - meet.lab.local → Jitsi
  - mail.lab.local → Webmail
  - desk.lab.local → Zammad

**Exercise 12: Zammad Help Desk System**
- Installation on LAB-COMM1
- PostgreSQL database
- Elasticsearch integration
- Email integration
- Keycloak SSO
- Ticket workflows

### Part 4: Integration & Operations (FINAL)

**Exercise 13: SSO Integration**
- Complete SSO testing across all applications
- User provisioning workflows
- Group-based access control
- Session management

**Exercise 14: Monitoring and Logging**
- Prometheus metrics collection
- Grafana dashboards
- Centralized logging
- Alert configuration

**Testing and Verification**
- Comprehensive test scenarios
- User acceptance testing
- Performance testing
- Security validation

**Troubleshooting Guide**
- Common issues and solutions
- Log file locations
- Diagnostic commands
- Recovery procedures

**Lab Completion Checklist**
- Installation verification
- Configuration validation
- Documentation review
- Backup procedures

**Command Reference**
- Quick reference for all major commands
- Service management
- User administration
- Network diagnostics

## Implementation Notes

**Total Content Scope:**
- ~10,000-12,000 lines of detailed instructions
- ~300-400 KB total size
- 40-60 hours of hands-on lab time
- Suitable for 4-6 week course

**Educational Features:**
- Step-by-step CLI commands
- Expected output examples
- "Understanding" sections explaining concepts
- "Why this matters" context
- Verification steps after each task
- Troubleshooting guidance
- Real-world applications
- Production vs lab differences

**Key Learning Outcomes:**
1. Enterprise Linux system administration
2. Network infrastructure design and implementation
3. Identity and access management
4. Database administration
5. Application deployment and integration
6. Security hardening
7. Monitoring and troubleshooting
8. Documentation and procedures

## Usage Recommendations

**For Instructors:**
- Can be split into multiple lab sessions
- Each exercise is self-contained
- Includes verification steps for grading
- Provides background for lecture material

**For Students:**
- Follow sequentially (dependencies exist)
- Document your own notes alongside
- Complete verification steps
- Review troubleshooting section when stuck
- Save configuration files for reference

**For Self-Learners:**
- Budget 4-6 weeks part-time
- Requires 5 physical machines or VMs
- Minimum 40GB RAM total recommended
- Keep lab environment for portfolio

## Files in This Lab Series

1. `enterprise-it-lab-manual.md` (Part 1) - ✅ COMPLETE
   - Foundation: Network, OS, Basic Configuration

2. `enterprise-it-lab-manual-part2.md` (Part 2) - 🔄 IN PROGRESS
   - Services: FreeIPA, PostgreSQL, Keycloak (detailed)
   - Continuation: Nextcloud, Mattermost, Jitsi, etc.

3. `lab-deployment-plan.md` - ✅ COMPLETE  
   - Quick reference guide
   - 3-server simplified deployment
   - Testing scenarios

4. `enterprise-it-stack-deployment.md` - ✅ COMPLETE
   - Production architecture reference
   - Full enterprise configuration
   - High availability setup

## Next Steps

To complete the full lab manual, create remaining sections following the same educational pattern:
- Detailed command-by-command instructions
- Explanation of each step
- Expected outputs
- Verification procedures
- Troubleshooting guidance
- Educational context

The foundation (Part 1) and core services (Part 2 FreeIPA/PostgreSQL/Keycloak) provide the template for remaining exercises.
