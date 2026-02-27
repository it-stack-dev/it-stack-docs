# Contributing to IT-Stack

Thank you for your interest in contributing to IT-Stack! This project is a community effort to build a production-ready enterprise IT platform entirely from open-source software.

There are many ways to contribute: improving documentation, writing lab test scripts, creating Ansible playbooks, fixing bugs, or adding new integration guides.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Ways to Contribute](#ways-to-contribute)
- [Development Environment](#development-environment)
- [Branch Strategy](#branch-strategy)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Documentation Standards](#documentation-standards)
- [Lab Test Standards](#lab-test-standards)
- [Code Review Checklist](#code-review-checklist)
- [Labels and Issues](#labels-and-issues)

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this standard. Please report unacceptable behavior to the project maintainers.

---

## Getting Started

1. **Fork** the repository you want to contribute to
2. **Clone** your fork locally
3. **Read** the relevant documentation in [docs/MASTER-INDEX.md](docs/MASTER-INDEX.md)
4. **Check** [docs/IT-STACK-TODO.md](docs/IT-STACK-TODO.md) for current priorities
5. **Open an issue** before starting significant work — discuss the approach first

For the GitHub org structure and repo conventions, see [docs/IT-STACK-GITHUB-GUIDE.md](docs/IT-STACK-GITHUB-GUIDE.md).

---

## Ways to Contribute

### Documentation
- Fix typos, broken links, or unclear instructions in lab manuals
- Add missing troubleshooting sections
- Improve architecture diagrams
- Translate documentation

### Lab Scripts (`tests/labs/`)
- Write or improve `test-lab-XX.sh` scripts for any module
- All 120 labs need implementation — see the tracking grid in `IT-STACK-TODO.md`
- Scripts must be idempotent (re-runnable without manual cleanup)

### Docker Compose Files (`docker/`)
- Each module needs 6 compose files (standalone → production)
- Follow the existing pattern: `docker-compose.standalone.yml` through `docker-compose.production.yml`

### Ansible Playbooks
- Add or improve roles in `it-stack-ansible/roles/{module}/`
- Improve `group_vars` and `host_vars` for the 8-server layout
- All credentials must use Ansible Vault — never plaintext secrets

### CI/CD
- Improve GitHub Actions workflows in `.github/workflows/`
- Add tests, linting, or security scans

### Bug Reports
- Use the issue tracker in the relevant component repository
- Include: environment details, steps to reproduce, expected vs actual behavior, logs

---

## Development Environment

### Windows (Primary Dev Machine)

```powershell
# Required tools
winget install GitHub.cli          # GitHub CLI
winget install Git.Git             # Git
winget install Docker.DockerDesktop  # Docker Desktop
```

Verify:
```powershell
gh --version
git --version
docker --version
```

### Ubuntu Lab Servers

```bash
# Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Ansible (control node)
sudo apt install -y ansible

# GitHub CLI
sudo apt install -y gh
```

---

## Branch Strategy

```
main       ← production-ready, protected, requires PR + review
develop    ← integration branch, default branch for PRs
feature/*  ← new features (branch from develop)
bugfix/*   ← bug fixes (branch from develop)
release/*  ← release preparation (branch from develop)
hotfix/*   ← emergency fixes (branch from main)
```

**Always branch from `develop`** for normal work. Only `hotfix/*` branches from `main`.

```bash
# Example: adding a new feature
git checkout develop
git pull origin develop
git checkout -b feature/keycloak-saml-suitecrm
# ... make changes ...
git push origin feature/keycloak-saml-suitecrm
# Open PR targeting develop
```

---

## Commit Messages

Follow the **Conventional Commits** specification: `type(scope): short description`

| Type | Use For |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `test` | Adding or updating tests/labs |
| `refactor` | Code restructuring (no behavior change) |
| `chore` | Maintenance, tooling, CI |
| `perf` | Performance improvement |
| `security` | Security fix or improvement |

**Examples:**
```
feat(keycloak): add SAML client configuration for SuiteCRM
fix(postgresql): correct pg_hba.conf for remote connections
docs(labs): add lab 03 advanced features guide for Nextcloud
test(freeipa): add DNS resolution assertions to lab-02
chore(ci): add Trivy container security scanning to release workflow
security(traefik): enforce TLS 1.2 minimum in entrypoints config
```

**Rules:**
- Use the present tense ("add feature", not "added feature")
- Keep the subject line under 72 characters
- Reference issues: `feat(mattermost): add OIDC login (#42)`
- Breaking changes: add `!` after type/scope and include `BREAKING CHANGE:` in footer

---

## Pull Request Process

1. **Open an issue first** for non-trivial changes — get agreement on approach before coding
2. **Keep PRs focused** — one logical change per PR, easier to review and revert
3. **Update documentation** — README, architecture docs, lab guides if applicable
4. **Pass all checks** — CI must be green (tests, linting, security scan)
5. **Fill out the PR template** completely
6. **Request review** from at least one maintainer
7. **Squash commits** if asked before merge

**PR title format** follows commit message conventions: `type(scope): description`

---

## Documentation Standards

All documentation uses Markdown.

### Lab Manual Style

Labs follow this structure:
```markdown
## Lab XX-YY: {Lab Name}

**Duration:** 30–60 minutes
**Machines:** 1 (standalone) / 2–3 (with dependencies)

### Prerequisites
- Lab XX-01 completed
- Docker installed and running

### Objectives
1. Deploy {service} in standalone mode
2. Verify {specific functionality}

### Exercise 1: {Title}

#### Steps

1. **Step description**
   ```bash
   command to run
   ```
   Expected output:
   ```
   what you should see
   ```

#### Verification
```bash
verification command
```

#### Understanding
Brief explanation of what this step accomplished and why.

### Troubleshooting
| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
```

### Writing Requirements
- Every CLI command must have expected output shown
- Every configuration change must include a verification step
- Every lab must have a cleanup section (`docker compose down -v`)
- Avoid pronouns ("you should see" → "the output shows")

---

## Lab Test Standards

Lab test scripts (`tests/labs/test-lab-XX.sh`) must follow this structure:

```bash
#!/bin/bash
# Lab XX-YY: {Module} — {Lab Name}
# Tests: {brief description}
set -euo pipefail

PASS=0; FAIL=0; SKIP=0

pass() { echo "  [PASS] $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1"; ((FAIL++)); }
skip() { echo "  [SKIP] $1"; ((SKIP++)); }

echo "=== Lab XX-YY: {Module} — {Lab Name} ==="
echo ""

# --- SETUP ---
echo "[1/4] Setup"
docker compose -f docker/docker-compose.standalone.yml up -d
sleep 10

# --- HEALTH CHECK ---
echo "[2/4] Health checks"
curl -sf http://localhost:PORT/health && pass "service health endpoint" || fail "service health endpoint"

# --- FUNCTIONAL TESTS ---
echo "[3/4] Functional tests"
# ... module-specific assertions ...

# --- CLEANUP ---
echo "[4/4] Cleanup"
docker compose -f docker/docker-compose.standalone.yml down -v

# --- RESULTS ---
echo ""
echo "Results: ${PASS} passed, ${FAIL} failed, ${SKIP} skipped"
[[ $FAIL -eq 0 ]] && echo "LAB PASSED" && exit 0 || echo "LAB FAILED" && exit 1
```

**Requirements:**
- Idempotent — safe to run repeatedly without manual cleanup
- Exit code 0 = all tests pass, exit code 1 = any test fails
- Test output must be machine-parseable for CI
- No hardcoded IPs — use environment variables or service names

---

## Code Review Checklist

Reviewers check:

**Structure**
- [ ] Follows standard repository layout exactly
- [ ] Module manifest (`it-stack-{module}.yml`) is complete and accurate
- [ ] All 6 lab test scripts present and updated if applicable
- [ ] Documentation updated (README, ARCHITECTURE, lab guides)

**Security**
- [ ] No secrets, credentials, API tokens, or passwords in code
- [ ] Input validation on all user-facing inputs
- [ ] TLS configured where applicable
- [ ] Protected endpoints require authentication

**Operations**
- [ ] Health check endpoint at `/health`
- [ ] Metrics endpoint at `/metrics` (Prometheus format preferred)
- [ ] Structured/JSON logging implemented
- [ ] Graceful shutdown handling
- [ ] Resource limits defined in Docker Compose and manifest

---

## Labels and Issues

When opening issues, apply the relevant labels:

| Label Type | Options |
|------------|---------|
| Scope | `lab`, `module-01` … `module-20` |
| Phase | `phase-1` … `phase-4` |
| Category | `identity`, `database`, `collaboration`, `communications`, `business`, `it-management`, `infrastructure` |
| Priority | `priority-high`, `priority-med`, `priority-low` |
| Status | `status-todo`, `status-in-progress`, `status-done`, `status-blocked` |

---

## Questions?

- Open a discussion in the relevant repository
- Check [SUPPORT.md](SUPPORT.md) for additional help channels
- Review [docs/MASTER-INDEX.md](docs/MASTER-INDEX.md) for documentation guidance

Thank you for contributing to IT-Stack!
