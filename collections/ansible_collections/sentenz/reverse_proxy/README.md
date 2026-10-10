# Ansible Collection for Reverse Proxy

`sentenz.reverse_proxy.traefik` deploys one Traefik instance with Docker Compose.
Docker labels discover application routes; a watched file supplies TLS options and
optional certificates. CLI flags are the only static configuration source.

## Requirements

- A maintained Ansible controller; the compatibility floor is `ansible-core >=2.17`.
  This matches the existing `community.docker 5.3.0` dependency. Ansible 2.17 is a
  compatibility target, not a recommendation to retain an unsupported controller.
- Linux target with Docker Engine and Docker Compose plugin >=2.18.0 installed.
  Run with appropriate Docker and filesystem privileges, normally `become: true`.
- Traefik v3.7.14, pinned by OCI image-index digest in defaults and repository inventories.
  This patch fixes the advisories listed in its [release notes][release].
- External networks in `traefik_networks` must already exist. Application containers
  must share the selected network; use `traefik_docker_network` or a per-application
  `traefik.docker.network` label when multiple networks are attached.

From the repository root:

```sh
ansible-galaxy collection install -r collections/ansible_collections/sentenz/reverse_proxy/requirements.yml
export ANSIBLE_COLLECTIONS_PATH="$PWD/collections:$HOME/.ansible/collections"
```

The collection also declares `community.docker` in `galaxy.yml`, so collection
installation resolves that dependency. The requirements file pins the tested version.

## Configuration

All defaults are in [roles/traefik/defaults/main.yml](roles/traefik/defaults/main.yml).

| Variable | Default / purpose |
| --- | --- |
| `traefik_challenge` | `debug`; one of `http`, `dns`, `tls`, `intranet`, `debug` |
| `traefik_image` | Traefik v3.7.14 with immutable digest; update tag and digest together |
| `traefik_path` | `/etc/ansible_collections/reverse_proxy/traefik` on the target |
| `traefik_published_ports` | `['80:80', '443:443']`; replace to restrict host bindings |
| `traefik_ports` | Additional published ports, retained for compatibility |
| `traefik_networks` | Existing external Docker networks; empty uses Compose's default network |
| `traefik_docker_network` | Optional default network for backend discovery |
| `traefik_docker_endpoint` | `unix:///var/run/docker.sock`; supports a private TCP socket proxy |
| `traefik_docker_socket` | Host socket path, mounted only for a Unix endpoint |
| `traefik_container_user` | `0:0`; numeric UID:GID, align host ownership for non-root operation |
| `traefik_acme_email` | Required for ACME modes; no placeholder default |
| `traefik_certificates_resolver` | `myresolver`; reference this name in application labels |
| `traefik_acme_storage` | `/letsencrypt/acme.json` in the container |
| `traefik_acme_config` | Controller-side seed `acme.json`, used only if target storage is absent |
| `traefik_challenge_dns_provider` | `cloudflare`; credentials depend on the selected Lego provider |
| `traefik_challenge_dns_provider_variables` | List of `NAME=value` strings; source secrets from Vault |
| `traefik_tls_public_cert`, `traefik_tls_private_key` | Controller paths to a matching pair; required for `intranet` |
| `traefik_certs_path` | Target certificate/state directory, defaults to `{{ traefik_path }}/certs` |
| `traefik_dynamic_config`, `traefik_dynamic_config_path` | `dynamic.yml`, `/etc/traefik/dynamic` (container directory) |
| `traefik_forwarded_headers_trusted_ips` | Empty; list only actual upstream proxy CIDRs |
| `traefik_proxy_protocol_trusted_ips` | Empty; list only actual PROXY protocol sender CIDRs |
| `traefik_tls_min_version` | `VersionTLS12`; `VersionTLS13` also supported |
| `traefik_strict_request_validation` | `true`; reject aliasing header names and ambiguous encoded path characters |
| `traefik_log_level`, `traefik_access_log` | `INFO`, `true`; JSON logs to stdout, request headers omitted |
| `traefik_wait_timeout` | 120 seconds for container health during deployment/recreation |
| `traefik_ownership_owner`, `traefik_ownership_group` | Existing host accounts, default `root:root` |
| `traefik_permission_directory`, `traefik_permission_file` | `0750`, `0600`; only restrictive modes accepted |
| `traefik_challenge_options` | Additional CLI arguments; trusted operator overrides can weaken defaults |

`debug` without supplied certificates uses Traefik's generated, untrusted certificate.
It is intended for local development. `intranet` requires an explicitly supplied
certificate and private key. Bundled demonstration certificates are not deployed by default.

All modes redirect HTTP to HTTPS. HTTP-01 requires public port 80; TLS-ALPN-01
requires public port 443; DNS-01 requires provider credentials and DNS propagation.
The redirect is compatible with Traefik's HTTP-01 challenge handler.

### ACME example

```yaml
---
- name: Deploy reverse proxy
  hosts: reverse_proxy
  become: true
  roles:
    - role: sentenz.reverse_proxy.traefik
      vars:
        traefik_challenge: dns
        traefik_acme_email: operations@example.org
        traefik_networks: [edge]
        traefik_docker_network: edge
        traefik_challenge_dns_provider_variables:
          - "CF_DNS_API_TOKEN={{ vault_cloudflare_dns_api_token }}"
```

Use a narrowly scoped provider token with the permissions required by that provider.
The Compose file is `0600`, and credential-bearing tasks suppress output and diffs.
Literal dollar signs are escaped for Compose, so credentials are not interpolated.
Docker administrators can still inspect container environments; Vault protects secrets
at rest on the controller, not from administrators on the target.

Label the application service, not Traefik:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=edge"
  - "traefik.http.routers.app.rule=Host(`app.example.org`)"
  - "traefik.http.routers.app.entrypoints=websecure"
  - "traefik.http.routers.app.tls=true"
  - "traefik.http.routers.app.tls.certresolver=myresolver"
  - "traefik.http.services.app.loadbalancer.server.port=8080"
```

For a staging CA, retain the existing override interface:

```yaml
traefik_challenge_options:
  - "--certificatesresolvers.{{ traefik_certificates_resolver }}.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"
```

### Local or internal TLS

```yaml
traefik_challenge: intranet
traefik_tls_public_cert: /secure/controller/certs/service.crt
traefik_tls_private_key: /secure/controller/certs/service.key
traefik_published_ports: ["127.0.0.1:8080:80", "127.0.0.1:8443:443"]
# With nonstandard public HTTPS ports, set the redirect's destination explicitly.
traefik_challenge_options:
  - "--entrypoints.web.http.redirections.entrypoint.to=:8443"
```

For debug mode, an omitted pair uses an untrusted generated certificate. For real
internal services, install a certificate from an appropriate internal CA instead.

## Security boundaries

The API/dashboard is disabled, no management port is published, and container
self-health listens on loopback only. To enable a dashboard, configure `api@internal`
through an authenticated TLS router using the [official secure-mode guidance][api].
Never expose `api.insecure` for production.

Docker discovery exposes no applications by default. The container has a read-only
root filesystem, drops capabilities except `NET_BIND_SERVICE`, and uses
`no-new-privileges`. The ACME state mount remains writable; supplied certificates
and dynamic configuration are read-only mounts.

A read-only **socket mount does not restrict Docker API operations**. Direct socket
access remains host-equivalent authority if Traefik is compromised. Prefer an
independently managed, request-filtering socket proxy on an isolated network, then
set `traefik_docker_endpoint: tcp://socket-proxy:2375`; this omits the host socket
mount. Do not expose that unauthenticated endpoint to untrusted networks. Remote
Docker access requires authenticated, encrypted transport configured separately.
With a socket proxy, a non-root numeric `traefik_container_user` can be used when
host certificate and configuration ownership matches that UID. The role does not
create accounts or provision a socket proxy. See [Docker provider guidance][docker].

Forwarded headers and PROXY protocol are trusted only from configured CIDRs.
Backend TLS verification remains enabled. Private-CA backends require an appropriate
CA/ServersTransport configuration; disabling verification is not a substitute.
TLS policy retains Go/Traefik cipher defaults and requires TLS 1.2 or newer.
Request-path sanitization is enabled. Strict validation rejects aliasing header names
(such as `X_Auth_User`) and encoded slash, backslash, null, semicolon, percent,
question mark, and hash in paths to limit proxy/backend interpretation differences.
Queries are unaffected. Applications relying on those paths or header names require
compatibility testing; `traefik_strict_request_validation: false` restores Traefik's
permissive defaults only after assessing backend normalization and authentication.
Application-specific HSTS, CSP, authentication, and rate limits belong on application
routers: blanket policies can break subdomains or application behavior.

Access logs omit headers but still contain request paths and other request metadata;
apply suitable retention and avoid placing credentials in URLs. Docker log rotation
is limited to three 10 MB files per container.

## Persistence, validation, and lifecycle

ACME storage is initialized only when missing and remains `0600`. Repeated runs,
stop, restart, and destroy never overwrite or delete existing certificate state.
Back up the entire certificate directory securely. Do not share ACME storage between
multiple Traefik processes. Changing `traefik_acme_storage` or `traefik_certs_path`
requires an explicit state migration; otherwise a new account/store will be created.

Directories are mounted so atomic file replacement remains visible inside the
container. Dynamic TLS policy updates are watched. Supplied certificate changes
request one health-checked recreation during the normal Compose reconciliation.
Static CLI or Compose changes are reconciled by Compose. A single instance may have
a brief interruption during recreation; this is not a zero-downtime deployment.

`docker compose config --quiet` validates a temporary Compose file before atomic
replacement. Invalid Compose syntax leaves the previous Compose file intact. This
checks the Compose model, not every Traefik option, certificate, backend, or ACME
exchange. Dynamic files are written separately; the role is not a multi-file
transaction. Ping health confirms process liveness, not successful certificate
issuance or application routing. Check logs and perform application probes after upgrades.

```sh
ansible-playbook -i inventory.yml reverse-proxy.yml
ansible-playbook -i inventory.yml reverse-proxy.yml --check --diff
ansible-playbook -i inventory.yml reverse-proxy.yml --tags stop
ansible-playbook -i inventory.yml reverse-proxy.yml --tags restart
ansible-playbook -i inventory.yml reverse-proxy.yml --tags destroy
```

Only explicitly requested lifecycle tags execute; selecting multiple actions fails.
`restart` recreates the existing Compose service and waits for health. It does not
render changed inventory variables: use a normal run to apply those changes.
Check mode predicts filesystem changes and runs input validation. It deliberately
skips Compose validation/reconciliation and deferred restart handlers, including on
a fresh host. Explicit lifecycle actions use the module's check-mode behavior and
require an existing project. `--diff` never prints private key or Compose contents.

## Migration

- Ansible 2.17 is the minimum compatible with `community.docker 5.3.0`.
- Traefik v3.7.13 inventory pins and the floating role default move to v3.7.14.
  Its [migration notes][migration] affect Kubernetes naming/route precedence and
  optional OpenTelemetry histograms; those features are not enabled by this role.
- Replace the old dictionary-shaped `traefik_challenge` default with a mode string.
- The unauthenticated API is removed. Configure authenticated dashboard routing
  explicitly if needed. The unused sample `traefik.yml` is no longer rendered;
  old copies are inert and can be removed after inspection.
- Configuration is now owned by existing `root:root` accounts with restrictive
  modes. Custom ownership variables are defaults rather than high-precedence role
  vars. Existing custom accounts must be provisioned separately and ownership must
  match the container UID; obsolete service accounts are not deleted automatically.
- Debug no longer implicitly deploys bundled certificate material. Existing explicit
  certificate paths continue to work; intranet requires both paths.
- HTTPS redirection now applies to all modes, including HTTP/DNS/TLS ACME. TLS mode
  also publishes port 80 by default; override `traefik_published_ports` to keep only 443.
- Strict request validation changes responses for encoded paths and nonstandard
  header names. Test application URLs and clients before rollout; review the
  documented opt-out only when backend interpretation is known to be safe.
- The watched dynamic file now resides under `{{ traefik_path }}/dynamic/` and TLS
  policy applies to all modes. If renaming `traefik_dynamic_config`, remove the previous
  managed filename from that directory to avoid conflicting definitions.
- Broken, unused `traefik_challenge_*_router` example variables are removed; use the
  explicit application-label example above. Challenge-specific CLI lists and
  `traefik_challenge_options` remain supported.
- API, backend-TLS, trusted-header, and TLS policy overrides require deliberate review;
  arbitrary CLI customization remains privileged configuration.

## Verification

See [tests/README.md](tests/README.md) for reproducible commands and test boundaries,
and [docs/SECURITY_REVIEW.md](docs/SECURITY_REVIEW.md) for findings and remaining risks.

[release]: https://github.com/traefik/traefik/releases/tag/v3.7.14
[migration]: https://doc.traefik.io/traefik/v3.7/migrate/v3/#v3714
[api]: https://doc.traefik.io/traefik/v3.7/reference/install-configuration/api-dashboard/
[docker]: https://doc.traefik.io/traefik/v3.7/reference/install-configuration/providers/docker/#docker-api-access
