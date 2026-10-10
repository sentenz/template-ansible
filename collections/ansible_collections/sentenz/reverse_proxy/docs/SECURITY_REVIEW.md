# Reverse proxy review

Reviewed against repository baseline `095fa882ed5fa1e5b97149f57ff52c155520a5f0`
on 2026-10-10. Severity below is a qualitative assessment of this deployment,
not a CVSS assignment. No production host or private inventory was deployed.

## Verified findings and remediation

| Severity | Evidence in the baseline | Remediation |
| --- | --- | --- |
| High — availability | `roles/traefik/tasks/main.yml` ran `state: absent`, `restarted`, and `stopped` on ordinary runs; ordinary tags do not make tasks opt-in. | Explicit, mutually exclusive lifecycle tags with `never` and selection guards; one reconciliation on normal runs. |
| High — certificate loss | The same file-copy task reapplied the empty `files/acme.json` over persistent ACME state. | Check existence, initialize with `force: false` only when absent, then enforce permissions independently. |
| High — unauthenticated management | `templates/docker-compose.yml.j2` enabled `--api.insecure=true`; access was possible from attached container networks even without a published 8080 port. | Disable API by default and publish no management port. |
| High — secret exposure | DNS credentials appeared in Compose while `vars/main.yml` set file mode `0644`; templating/copy tasks did not suppress diffs. | Root ownership by default, `0600` secret/config files, restrictive directories, `no_log` and disabled diffs for sensitive tasks. |
| High, feature-dependent — dependency security | Inventories pinned v3.7.13; the role used `latest`. The v3.7.14 release fixes eight advisories, whose exploitability depends on enabled features/backends. | Advance only the patch release and pin the role plus dev/stage/prod overrides to the verified v3.7.14 OCI image-index digest. |
| Medium — unsafe or misleading configuration | The challenge default was a dictionary; DNS variables defaulted to a string; empty network sections rendered null; the unused static sample allowed encoded characters and had an incorrectly nested provider option. | Scalar/list defaults, preflight assertions, valid empty-network behavior, removal of the unused sample, and one static configuration source. |
| Medium — request interpretation | No explicit policy restricted aliased header names or encoded reserved characters for normalizing backends. | Sanitization retained; strict request validation by default, with a documented compatibility override. This is preventive hardening, not evidence of an application exploit. |
| Medium — reload reliability | Single-file configuration mounts could retain the old inode after Ansible's atomic replacement; no health check or pre-install Compose validation existed. | Directory mounts, watched dynamic configuration, validated atomic Compose installation, ping health, bounded health waits, and coalesced certificate recreation. |
| Medium — dependency metadata | `meta/runtime.yml` advertised Ansible 2.16 but the pinned `community.docker 5.3.0` requires 2.17; `galaxy.yml` omitted that dependency. | Correct the compatibility floor and declare the collection dependency. |

Module names were already fully qualified; the changes retain that convention and
use Ansible modules for filesystem and lifecycle management. No shell-based install
or unverified binary download is introduced into the production role. The CLI
validator is invoked by `ansible.builtin.template.validate`, without a shell.

## Version and artifact verification

The upstream [v3.7.14 release](https://github.com/traefik/traefik/releases/tag/v3.7.14)
was published on 2026-10-06. Its release notes enumerate the security advisories.
The [migration guide](https://doc.traefik.io/traefik/v3.7/migrate/v3/#v3714)
was reviewed; its Kubernetes naming/precedence and optional OpenTelemetry histogram
changes do not apply to this role's default Docker/file-provider configuration.

The public Docker Registry v2 manifest for `library/traefik:v3.7.14` returned the
OCI image-index digest below; the SHA-256 of the response body was independently
checked against the `Docker-Content-Digest` header:

```text
sha256:575fa15b135078fe5e50aa847987d96dbddd7b093c172429618404df73f3fa7c
```

Native test executables were checked against the SHA-256 digests reported by their
official GitHub release assets before execution:

| Test artifact | SHA-256 |
| --- | --- |
| Traefik v3.7.14 Linux amd64 archive | `d08641f5de2dd3788097bddab1ce4b29c10a0b788566970db707fa5c94c71f15` |
| Docker Compose v2.39.4 Linux x86_64 binary | `7af95166a730b87e172d4fc9aefea8725d3c6c7327d59149267b452114ddb7d4` |

Digest verification establishes content integrity against those upstream references;
it is not a separate signature or provenance attestation.

## Validation and remaining limits

Reproduction commands and test boundaries are in [tests/README.md](../tests/README.md).
The pull request records the exact checks and outcomes. Regression tests use real
Ansible file operations and real Compose parsing, with a recording test double only
for container lifecycle calls. Native loopback tests exercise actual Traefik startup,
healthcheck, redirects, TLS policy, request validation, and dynamic reloads.

No Docker daemon is available in the review environment. Real container capability
enforcement, Docker discovery, health-wait behavior, live backend routing, ACME
issuance/renewal, and full-engine idempotency remain staging validation requirements.
The health endpoint checks process liveness, not those end-to-end properties.

Direct Docker socket access remains a high-impact trust boundary even with a read-only
mount. A configurable restricted socket-proxy endpoint is provided, but provisioning
and auditing such a proxy is deployment-specific. The default container runs as UID 0
with reduced capabilities; non-root operation requires matching host ownership and
appropriate Docker API access.

Arbitrary CLI overrides can weaken security. Application-specific authorization,
security headers, rate limits, private backend CAs, host firewall rules, and backup
policies cannot be inferred from this collection and must be configured per deployment.
Dynamic-file updates are not a transaction with Compose updates, and a single-instance
recreation can briefly interrupt service. Compatibility changes are listed in the README.

Repository-level `ansible.cfg` disables SSH host-key checking. That broader policy
was not changed in this collection-focused patch; production controllers should
verify managed-host identities using a maintained known-hosts policy. Repository-wide
credential provenance and rotation were not audited.

## Authoritative guidance

- [Ansible tags: always and never](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_tags.html#special-tags-always-and-never)
- [Ansible copy: force, permissions, and check mode](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/copy_module.html)
- [Ansible template: validation and atomic operations](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/template_module.html)
- [community.docker Compose v2: requirements, wait, state, check mode](https://docs.ansible.com/projects/ansible/latest/collections/community/docker/docker_compose_v2_module.html)
- [Traefik configuration sources](https://doc.traefik.io/traefik/v3.7/getting-started/configuration-overview/)
- [Traefik API and dashboard security](https://doc.traefik.io/traefik/v3.7/reference/install-configuration/api-dashboard/)
- [Traefik Docker API security](https://doc.traefik.io/traefik/v3.7/reference/install-configuration/providers/docker/#docker-api-access)
- [Traefik entrypoints, trusted headers, and request interpretation](https://doc.traefik.io/traefik/v3.7/reference/install-configuration/entrypoints/)
- [Traefik TLS options](https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/tls/tls-options/)
- [Traefik health checks](https://doc.traefik.io/traefik/v3.7/reference/install-configuration/observability/healthcheck/)
- [Docker Compose literal-dollar escaping](https://docs.docker.com/reference/compose-file/interpolation/)
