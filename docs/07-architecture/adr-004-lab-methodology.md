# ADR-004: 6-Lab Progressive Testing Methodology

**Status:** Accepted  
**Date:** 2026-02-27  
**Deciders:** IT-Stack Architecture Team  

---

## Context

IT-Stack delivers 20 services to organizations that span a wide range of deployment environments:

- A home lab with one server and no external services
- A school with 3 VMs and no SSO yet
- A mid-size company with 5 servers and partial integration
- An enterprise with 8+ servers, full HA, and existing Active Directory

A single deployment guide cannot serve all these environments. A single test suite that requires all 20 services to be running cannot validate individual services in isolation.

Additionally, each service must be validated across its full lifecycle:
1. Does it even work standalone?
2. Does it work with external databases?
3. Does it support production-grade configuration?
4. Does it integrate with SSO?
5. Does it integrate with the full ecosystem?
6. Does it survive a production deployment with HA and monitoring?

---

## Decision

**Every IT-Stack module implements exactly 6 labs. Labs are numbered `XX-YY` where `XX` is the zero-padded module number and `YY` is the lab number (01–06).**

### Lab Progression

| Lab | Name | Environment | Prerequisite | Duration |
|-----|------|-------------|-------------|---------|
| XX-01 | Standalone | Single machine, Docker only | None | 30–60 min |
| XX-02 | External Dependencies | 2–3 machines; LAN | Lab 01 passes | 45–90 min |
| XX-03 | Advanced Features | 2–3 machines | Lab 02 passes | 60–120 min |
| XX-04 | SSO Integration | 3–4 machines; Keycloak running | Labs 01–03 + Keycloak 04-01 passes | 90–120 min |
| XX-05 | Advanced Integration | 4–5 machines; multiple services up | Lab 04 passes | 90–150 min |
| XX-06 | Production Deployment | 5+ machines; HA configuration | Lab 05 passes | 120–180 min |

### Lab Deliverables per Module

Each lab corresponds to one Docker Compose file and one test script:

```
it-stack-{module}/
├── docker/
│   ├── docker-compose.standalone.yml    # Lab 01
│   ├── docker-compose.lan.yml           # Lab 02
│   ├── docker-compose.advanced.yml      # Lab 03
│   ├── docker-compose.sso.yml           # Lab 04
│   ├── docker-compose.integration.yml   # Lab 05
│   └── docker-compose.production.yml    # Lab 06
└── tests/labs/
    ├── test-lab-XX-01.sh
    ├── test-lab-XX-02.sh
    ├── test-lab-XX-03.sh
    ├── test-lab-XX-04.sh
    ├── test-lab-XX-05.sh
    └── test-lab-XX-06.sh
```

### Test Script Structure

Every `test-lab-XX-YY.sh` follows the same 4-phase structure:

```bash
# Phase 1: Setup
docker compose -f docker/docker-compose.{variant}.yml up -d

# Phase 2: Health check (with retries)
wait_for_service http://localhost:{PORT}/health 30 5

# Phase 3: Functional assertions
assert_http_200  "Service health"    http://localhost:{PORT}/
assert_contains  "Login page exists" http://localhost:{PORT}/login  "login"
# ... service-specific tests

# Phase 4: Cleanup
docker compose -f docker/docker-compose.{variant}.yml down -v
```

### Idempotency Requirement

All test scripts must be **idempotent** — running a test twice in succession must produce the same result as running it once. No manual cleanup required between runs.

### Makefile Integration

Each module's `Makefile` exposes:

```make
make test        # all 6 labs
make test LAB=1  # lab 01 only
make test LAB=4  # lab 04 only
```

### Global Runner

`it-stack-installer/scripts/testing/run-all-labs.sh` runs all 120 labs with filtering:

```bash
./run-all-labs.sh --phase 1          # 30 labs (5 modules × 6)
./run-all-labs.sh --module nextcloud # 6 labs
./run-all-labs.sh --lab 4           # SSO lab for all 20 modules (20 labs)
```

---

## Consequences

### Positive
- **Incremental confidence** — teams can adopt IT-Stack one lab at a time; they don't need the full stack to start
- **Isolation** — Lab 01 failures are always the service itself, never missing dependencies
- **Deployment tier mapping** — Labs 01–02 = home lab; 03–04 = school/dept; 05–06 = enterprise (see ADR-006)
- **CI integration** — Lab 01 runs in every pull request in ~5 minutes; Labs 04–06 run nightly
- **Documentation as code** — there is exactly one test script per lab doc; they stay in sync

### Negative / Trade-offs
- **6× the artifacts** — 6 docker-compose files + 6 test scripts per module = 240 files across 20 modules
- **Lab 06 is expensive** — requires 5+ machines and 2–3 hours; cannot run in CI without significant infrastructure
- **SSO dependency tree** — Lab 04 for every module requires Keycloak's own Lab 04 to pass first; this creates a sequential constraint in the test pipeline

---

## Alternatives Considered

### Single Docker Compose per module (all variants in one file)
- Simpler repository structure
- Cannot represent the progression from standalone to production clearly
- **Rejected:** the 6-file structure makes each deployment scenario self-contained and independently runnable

### Automated integration test suite only (no lab docs)
- More "DevOps-native"
- Misses the educational purpose — IT-Stack is also a learning platform for teams building their first enterprise stack
- **Rejected:** the lab guide format (with "Understanding" sections and exercises) is a core project value

### Fewer labs (3-tier: dev, staging, production)
- Less overhead; simpler to maintain
- Loses the granular SSO / ecosystem integration distinction that is IT-Stack's value proposition
- **Rejected:** the FreeIPA→Keycloak→service trust chain requires its own lab step (Lab 04)

---

## References

- [Lab Manual Structure](../03-labs/LAB_MANUAL_STRUCTURE.md)
- [Lab Deployment Plan](../02-implementation/03-lab-deployment-plan.md)
- [it-stack-testing repo](https://github.com/it-stack-dev/it-stack-testing)
- [Scripts: run-all-labs.sh](https://github.com/it-stack-dev/it-stack-installer/blob/main/scripts/testing/run-all-labs.sh)
