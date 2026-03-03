# ADR-007: Docker Compose for Labs, Ansible for Production

**Status:** Accepted  
**Date:** 2026-02-27  
**Deciders:** IT-Stack Architecture Team  

---

## Context

IT-Stack needs a consistent deployment model that:

- Works on a single laptop for Labs 01–03 (no VMs required)
- Works on 2–5 VMs for Labs 02–05 (LAN networking required)
- Deploys to 8 bare-metal servers for production (Lab 06)
- Is reproducible (same config produces same service state)
- Supports the educational/documentation mission (clear, readable configs)

### Tools Available

| Tool | Strengths | Weaknesses |
|------|-----------|-----------|
| Docker Compose | Fast; self-contained; reproducible; readable YAML | Not for bare-metal production services; no systemd integration |
| Ansible | Idempotent; bare-metal native; systemd aware; secrets via Vault | Requires SSH access; slower than `docker compose up` |
| Helm / Kubernetes | Production-grade scheduling; self-healing | Adds k8s complexity inappropriate for Tier 1/2 deployments |
| Terraform | VM provisioning; infrastructure as code | Not for application deployment within VMs |
| Shell scripts | Maximum flexibility | Not idempotent; hard to test |

---

## Decision

**Use Docker Compose for all lab environments (Labs 01–05). Use Ansible for production deployment (Lab 06 and all Tier 3 deployments).**

### Boundary

| Scenario | Tool | Config Location |
|----------|------|----------------|
| Lab 01: Standalone | `docker compose` | `docker/docker-compose.standalone.yml` |
| Lab 02: LAN integration | `docker compose` | `docker/docker-compose.lan.yml` |
| Lab 03: Advanced features | `docker compose` | `docker/docker-compose.advanced.yml` |
| Lab 04: SSO integration | `docker compose` | `docker/docker-compose.sso.yml` |
| Lab 05: Full integration | `docker compose` | `docker/docker-compose.integration.yml` |
| Lab 06: Production | `docker compose` + `ansible-playbook` | `docker/docker-compose.production.yml` + Ansible role |
| Tier 3 Production | `ansible-playbook site.yml` | `it-stack-ansible/` |
| VM provisioning | `terraform apply` | `it-stack-terraform/` |
| Kubernetes | `helm install` | `it-stack-helm/` |

### Docker Compose Conventions

All six compose files per module follow this pattern:

```yaml
# docker/docker-compose.standalone.yml
services:
  {module}:
    image: {vendor}/{module}:{version}
    container_name: it-stack-{module}
    restart: unless-stopped
    environment:
      - ENV_VAR=${ENV_VAR:-default}
    ports:
      - "{port}:{port}"
    volumes:
      - {module}_data:/var/lib/{module}
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{port}/health"]
      interval: 30s
      timeout: 10s
      retries: 5
    networks:
      - it-stack-net

volumes:
  {module}_data:
networks:
  it-stack-net:
    name: it-stack
```

### Ansible Role Conventions

Every service has an Ansible role in `it-stack-ansible/roles/{module}/`:

```
roles/{module}/
├── tasks/
│   ├── main.yml          # Install, configure, start
│   ├── install.yml
│   ├── configure.yml
│   └── service.yml
├── templates/            # Jinja2 config files
│   └── {module}.conf.j2
├── handlers/
│   └── main.yml          # restart {module}
├── defaults/
│   └── main.yml          # All variables with defaults
└── vars/
    └── main.yml          # Derived/computed variables
```

Variables flow: `group_vars/all.yml` → `host_vars/{server}.yml` → role `defaults/main.yml`

Secrets: all passwords and API keys in `vault/secrets.yml`, encrypted with `ansible-vault encrypt`.

### Makefile Integration

Each module's `Makefile` provides a unified interface regardless of underlying tool:

```make
make install  # docker compose up (lab) OR ansible-playbook (production)
make test     # run test-lab-XX-01.sh through test-lab-XX-06.sh
make build    # build custom Docker image (if applicable)
make deploy   # ansible-playbook deploy-{module}.yml
make clean    # docker compose down -v
```

---

## Consequences

### Positive
- **Single-command lab startup** — `docker compose -f docker/docker-compose.standalone.yml up -d` requires only Docker; no VM, no SSH, no configuration
- **Idempotent production** — `ansible-playbook site.yml` is safe to re-run; only changed resources are touched
- **Vault-secured production secrets** — no plaintext credentials in any Ansible playbook or variable file
- **Portable labs** — Docker Compose files run on macOS, Windows (Docker Desktop), and Linux identically
- **CI-friendly** — Lab 01 Docker Compose runs on any GitHub Actions runner with Docker installed
- **Clear upgrade path** — teams start with Docker Compose, graduate to Ansible as their environment grows

### Negative / Trade-offs
- **Two configuration systems** — Docker Compose and Ansible YAML for same service; must stay in sync
  - Mitigation: both use the same environment variable names from `group_vars/all.yml`; the Ansible role generates the same config that the Compose env vars represent
- **Docker not used in production** — Lab 06 (`docker-compose.production.yml`) is the bridge but real Tier 3 production uses Ansible bare-metal install; admins transitioning must understand this boundary
- **Compose file count** — 6 files × 20 modules = 120 Docker Compose files to maintain
  - Mitigation: `scripts/utilities/create-repo-template.ps1` scaffolds all 6 with correct stubs; only service-specific customization is needed

---

## Alternatives Considered

### Docker Compose everywhere (including production)
- Single tool; simpler mental model
- Docker Compose in production lacks systemd integration, Kerberos keytab management, UFW rules, and filesystem-level configuration that production services require
- **Rejected:** production bare-metal configuration goes beyond what Compose YAML can express

### Ansible everywhere (including labs)
- Single tool; truly idempotent even in labs
- Lab 01 standalone requires SSH access, an Ansible control node, and an inventory — this is too heavy for a developer running a quick locally
- **Rejected:** compose is dramatically faster to iterate for lab/development use

### Podman + systemd (Podman Quadlets)
- Rootless containers; more secure than Docker; native systemd integration via Quadlets
- Smaller ecosystem; Docker Compose compatibility layer has edge cases
- **Not yet rejected:** this is a strong candidate for Phase 6 production hardening; see future ADR

### Nix / NixOS
- Fully reproducible; Nix expressions for everything
- Steep learning curve; FreeIPA and many services lack Nix packages
- **Rejected for v1:** may revisit for v2

---

## References

- [Docker Compose v2 Documentation](https://docs.docker.com/compose/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
- [it-stack-ansible repo](https://github.com/it-stack-dev/it-stack-ansible)
- [it-stack-terraform repo](https://github.com/it-stack-dev/it-stack-terraform)
- [it-stack-helm repo](https://github.com/it-stack-dev/it-stack-helm)
- [ADR-004: 6-Lab Methodology](adr-004-lab-methodology.md)
