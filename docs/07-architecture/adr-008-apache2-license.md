# ADR-008: Apache 2.0 License for All IT-Stack Repositories

**Status:** Accepted  
**Date:** 2026-02-27  
**Deciders:** IT-Stack Architecture Team  

---

## Context

IT-Stack is an open-source project with 26 repositories. Every repository needs a license. The license choice determines:

- Who can use the software (individuals, companies, governments)
- Whether the code can be incorporated into commercial products
- What obligations adopters have (attribution, share-alike, patent notices)
- Community adoption velocity (permissive licenses attract more contributors)

The project's core mission is to make enterprise IT infrastructure accessible to organizations that cannot afford commercial software. The license must not impede adoption.

### Key Constraints

1. **All dependencies must be compatible** — the license must be compatible with the licenses of FreeIPA (GPLv3), Keycloak (Apache 2.0), PostgreSQL (PostgreSQL License), etc.
2. **Config and scripts, not application code** — IT-Stack repositories contain Ansible playbooks, Docker Compose files, and automation scripts, not forks of the underlying applications. The underlying apps retain their own licenses.
3. **Enterprise adoption** — companies must be able to deploy IT-Stack internally without being required to open-source their internal configurations.

---

## Decision

**License all 26 IT-Stack repositories under [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).**

### What IT-Stack Distributes

IT-Stack does **not** redistribute the source code of FreeIPA, Keycloak, PostgreSQL, or any other service. It distributes:

- Ansible roles and playbooks (configuration code)
- Docker Compose files (infrastructure definitions)
- Shell and PowerShell automation scripts
- Documentation (Markdown)
- Helm charts (Kubernetes deployment templates)
- CI/CD workflow files (GitHub Actions YAML)

These are original works by the IT-Stack contributors and are properly licensed under Apache 2.0.

### Why Apache 2.0

| Property | Apache 2.0 | MIT | GPLv3 |
|----------|-----------|-----|-------|
| Commercial use | ✅ | ✅ | ✅ |
| Modification allowed | ✅ | ✅ | ✅ (share-alike) |
| Distribution allowed | ✅ | ✅ | ✅ (with source) |
| Patent grant | ✅ explicit | ❌ | ✅ |
| Copyleft (must open-source modifications) | ❌ | ❌ | ✅ |
| Attribution required | ✅ (NOTICE file) | ✅ | ✅ |
| Compatible with Keycloak (Apache 2.0) | ✅ | ✅ | ❌ |
| Compatible with PostgreSQL License | ✅ | ✅ | ✅ |
| Compatible with GPLv3 (FreeIPA) | ✅ (combined works) | ✅ | ✅ |

Apache 2.0 provides:
- **Explicit patent grant** — contributors grant a royalty-free patent license; MIT does not do this
- **Permissive** — organizations can fork, modify, and use internally without releasing modifications
- **Copyleft-free** — unlike GPLv3, forks do not need to be open-sourced
- **Industry standard** — used by Kubernetes, Ansible, Terraform, Keycloak, Helm, and most CNCF projects

### License Header

All original files include (or reference) the SPDX identifier:

```
# SPDX-License-Identifier: Apache-2.0
```

Full license text is in the `LICENSE` file at each repository root.

---

## Consequences

### Positive
- **Maximum adoption** — companies can build internal products on IT-Stack without open-sourcing their configs
- **Patent protection** — contributors and users are protected by the explicit Apache 2.0 patent grant
- **Ecosystem alignment** — same license as Keycloak, Ansible, Terraform, and Helm; no compatibility issues
- **Clear separation** — underlying service licenses (FreeIPA GPLv3, etc.) are unaffected; IT-Stack config code is cleanly Apache 2.0

### Negative / Trade-offs
- **Copyleft-free** — IT-Stack does not require forks to return improvements to the community
  - Accepted trade-off: permissive licensing maximizes adoption; community norms and GitHub social incentives are used instead of legal compulsion

---

## Alternatives Considered

### MIT License
- Even simpler; no NOTICE file requirement
- No explicit patent grant — riskier for enterprise adopters in litigious environments
- **Rejected:** Apache 2.0's patent grant is a meaningful protection worth the minor additional complexity

### GPLv3
- Strong copyleft; ensures all modifications are open-sourced
- Incompatible with some commercial environments; would prevent adoption for key target organizations
- **Rejected:** conflicts with the project's mission of maximum accessibility

### Creative Commons (for docs only)
- CC BY-SA 4.0 is appropriate for documentation
- Would require different licenses for code vs. docs, adding confusion
- **Rejected:** Apache 2.0 is compatible with documentation; using one license for all files is simpler

---

## References

- [Apache License 2.0 Full Text](https://www.apache.org/licenses/LICENSE-2.0)
- [SPDX License List](https://spdx.org/licenses/Apache-2.0.html)
- [Apache 2.0 vs GPL compatibility](https://www.apache.org/licenses/GPL-compatibility.html)
- [CNCF Project Licenses](https://www.cncf.io/legal/licenses/)
