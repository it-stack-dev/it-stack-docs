# ADR-005: Ubuntu 24.04 LTS as the Base Operating System

**Status:** Accepted  
**Date:** 2026-02-27  
**Deciders:** IT-Stack Architecture Team  

---

## Context

All 8 production servers and all lab VMs need a common operating system. The choice of OS determines:

- Package availability and freshness for all 20 services
- Systemd unit file compatibility (Ansible roles use `systemd` module)
- Security lifecycle (LTS support window)
- Container base image for Dockerfiles
- Compatibility with Ansible modules (e.g., `apt`, `ufw`, `unattended-upgrades`)
- FreeIPA client enrollment compatibility

### Requirements

| Requirement | Details |
|-------------|---------|
| LTS lifecycle | Minimum 5 years of security updates from deployment (2026) |
| Package availability | All 20 services available as apt packages or official Docker images |
| FreeIPA client support | `freeipa-client` package installable and supportable |
| Ansible compatibility | All target Ansible modules (`apt`, `ufw`, `service`, `user`) work without workarounds |
| Container base | Official Docker images for all services use this OS or are Alpine/scratch |
| ARM64 support | Lab environments may use Raspberry Pi 5 or Apple Silicon VMs |

---

## Decision

**Use Ubuntu Server 24.04 LTS (Noble Numbat) on all production servers and lab VMs.**

### Version Details

| Property | Value |
|----------|-------|
| Release | Ubuntu 24.04 LTS (Noble Numbat) |
| Release Date | April 2024 |
| Standard Support EOL | April 2029 |
| Extended Security Maintenance | April 2036 (with Ubuntu Pro) |
| Kernel | Linux 6.8 (HWE kernel available) |
| systemd | 255.x |
| Python | 3.12 (required for Ansible, Odoo, Taiga, scripts) |
| OpenSSL | 3.0.x |

### Per-Server Configuration Standard

All servers follow this baseline:

```
OS:       Ubuntu Server 24.04 LTS (minimal install)
Timezone: UTC (all log timestamps in UTC)
Hostname: lab-{role}{n}.it-stack.lab  (e.g., lab-db1.it-stack.lab)
SSH:      Key-only, root login disabled, port 22
UFW:      Enabled; only required ports open per server role
Updates:  unattended-upgrades for security patches; major upgrades manual
Python:   3.12 (pre-installed; used by Ansible control path)
```

### FreeIPA Enrollment

All servers enroll as FreeIPA clients after FreeIPA server is deployed:

```bash
ipa-client-install \
  --server=lab-id1.it-stack.lab \
  --domain=it-stack.lab \
  --realm=IT-STACK.LAB \
  --principal=admin \
  --mkhomedir
```

Post-enrollment: `/etc/krb5.conf`, SSH host keytabs, and `sssd` are configured automatically by FreeIPA.

---

## Consequences

### Positive
- **5-year LTS** — no OS upgrade required until 2029; extended to 2036 with Ubuntu Pro (free for up to 5 machines)
- **Python 3.12 pre-installed** — Ansible, Odoo, Taiga, and automation scripts work without version management
- **Largest package ecosystem** — every IT-Stack service has either an apt package or official Docker image tested on Ubuntu 24.04
- **Consistent Ansible target** — no conditional `when: ansible_os_family == ...` blocks needed
- **Docker CE support** — Docker's official Ubuntu 24.04 packages are available day one
- **ARM64 support** — Ubuntu 24.04 runs natively on Raspberry Pi 5, AWS Graviton, and Apple Silicon (Parallels/UTM)

### Negative / Trade-offs
- **Java services require manual install** — Keycloak and OpenKM use Java 17/21; Ubuntu 24.04 ships Java 21 in main, but Keycloak requires the UBI-based or official container image
- **FreeIPA server limitation** — while `freeipa-client` is in Ubuntu 24.04 main, `freeipa-server` from the Ubuntu repos may lag behind RHEL/Fedora releases; using the official FreeIPA apt repo is recommended
- **Snap packages** — Ubuntu 24.04 ships some tools as snaps; IT-Stack Ansible roles use `apt` only and explicitly avoid snap to prevent confinement issues

---

## Alternatives Considered

### Ubuntu 22.04 LTS (Jammy)
- Still supported (EOL April 2027)
- Ships Python 3.10 (Odoo 17 requires 3.10+; Taiga requires 3.12+)
- **Rejected:** Python version too low for newer Taiga; shorter remaining support window

### Debian 12 (Bookworm)
- Excellent stability; same apt ecosystem
- Python 3.11 (not 3.12); standard EOL June 2028
- Less pre-existing documentation for FreeIPA client on Debian in an enterprise context
- **Rejected:** Ubuntu 24.04 has broader community documentation for the specific services in IT-Stack

### Rocky Linux 9 / AlmaLinux 9
- RHEL-compatible; FreeIPA server is first-class (same codebase as RHEL IdM)
- `dnf` instead of `apt`; all Ansible roles would need `package:` abstraction or rewrites
- **Rejected:** Ubuntu is the primary expertise baseline for modern cloud-native teams; rewriting all roles for `dnf` and `firewalld` adds significant overhead

### Container-only (CoreOS / Flatcar)
- Immutable OS; all workloads in containers
- FreeIPA server is not available as a supported container image
- Ansible `apt` roles inapplicable
- **Rejected:** IT-Stack's Ansible role-based deployment model requires a traditional OS

---

## References

- [Ubuntu 24.04 LTS Release Notes](https://discourse.ubuntu.com/t/noble-numbat-release-notes/39890)
- [Ubuntu LTS Support Lifecycle](https://ubuntu.com/about/release-cycle)
- [FreeIPA on Ubuntu](https://wiki.debian.org/FreeIPA)
- [Docker CE for Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
