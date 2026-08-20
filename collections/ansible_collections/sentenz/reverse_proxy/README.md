# Ansible Collection for Reverse Proxy

The `sentenz.reverse_proxy` collection deploys reverse-proxy services. Its
Traefik role manages a Docker Compose project with conservative defaults,
explicit lifecycle control, and support for ACME or operator-supplied TLS
certificates.

## Requirements

- Ansible Core 2.16 or newer
- Docker Engine with the Docker Compose plugin 2.18 or newer on the managed host
- `community.docker` 4.8.8 (declared in `requirements.yml`)
- Privilege escalation when the project is installed under `/etc`

Install the dependency from the collection directory:

```bash
ansible-galaxy collection install -r requirements.yml
```

## Traefik role

The fully qualified role name is `sentenz.reverse_proxy.traefik`.

### Basic Docker provider

The default `none` certificate mode exposes only the plaintext HTTP entry point.
Docker services remain private unless they have `traefik.enable=true`.

```yaml
---
- name: Deploy Traefik
  hosts: reverse_proxies
  become: true
  pre_tasks:
    - name: Create the shared proxy network
      community.docker.docker_network:
        name: proxy
        state: present
  roles:
    - role: sentenz.reverse_proxy.traefik
      vars:
        traefik_networks:
          - proxy
        traefik_docker_network: proxy
```

A backend attached to the same network can opt in with labels:

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.application.rule=Host(`application.example.com`)
  - traefik.http.routers.application.entrypoints=web
```

### ACME HTTP-01

Port 80 must be reachable by the certificate authority. The persistent ACME
directory is mounted read-write so Traefik can update its storage atomically.
The `acme.json` file is created only when absent; subsequent role runs preserve
its certificate data.

```yaml
roles:
  - role: sentenz.reverse_proxy.traefik
    vars:
      traefik_challenge: http
      traefik_acme_email: operations@example.com
      traefik_certificates_resolver: letsencrypt
      traefik_networks:
        - proxy
      traefik_docker_network: proxy
```

TLS routers must select the configured resolver:

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.application.rule=Host(`application.example.com`)
  - traefik.http.routers.application.entrypoints=websecure
  - traefik.http.routers.application.tls=true
  - traefik.http.routers.application.tls.certresolver=letsencrypt
```

### ACME DNS-01

DNS provider values use the environment names expected by
[Lego's DNS providers](https://go-acme.github.io/lego/dns/). Store credentials
with Ansible Vault rather than in plaintext inventory.

```yaml
roles:
  - role: sentenz.reverse_proxy.traefik
    vars:
      traefik_challenge: dns
      traefik_acme_email: operations@example.com
      traefik_challenge_dns_provider: cloudflare
      traefik_challenge_dns_provider_variables:
        - "CF_DNS_API_TOKEN={{ vault_cloudflare_dns_api_token }}"
```

### File certificates

The role copies certificate sources from the Ansible controller. Private keys
may be Vault-encrypted because `ansible.builtin.copy` decrypts them before
installing the managed-host copy.

```yaml
roles:
  - role: sentenz.reverse_proxy.traefik
    vars:
      traefik_challenge: file
      traefik_tls_public_cert: files/tls/application.crt
      traefik_tls_private_key: files/tls/application.key.vault
```

The legacy `intranet` and `debug` challenge values remain aliases for `file`.
The collection does not distribute a private key or a domain-specific example
certificate.

### Lifecycle

`traefik_state` is the sole lifecycle selector. A normal role run no longer
executes destructive and stop operations after deployment.

```yaml
traefik_state: present    # create or update; default
traefik_state: restarted  # explicitly restart
traefik_state: stopped    # retain containers and configuration
traefik_state: absent     # remove the Compose project containers and network
```

Setting `absent` leaves managed configuration and certificate storage on the
host. This permits a later deployment to retain ACME state.

### Principal variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `traefik_image` | `traefik:v3.7.11` | Pinned Traefik image tag |
| `traefik_path` | See defaults | Compose project directory |
| `traefik_state` | `present` | Compose project lifecycle state |
| `traefik_challenge` | `none` | `none`, `http`, `dns`, `tls`, or `file` |
| `traefik_networks` | `[]` | Existing external Docker networks |
| `traefik_docker_network` | `""` | Default network for discovered backends |
| `traefik_ports` | `[]` | Additional published port mappings |
| `traefik_publish_default_ports` | `true` | Publish challenge ports |
| `traefik_dashboard_enabled` | `false` | Enable the dashboard API |
| `traefik_access_log_enabled` | `false` | Enable access logging to stdout |
| `traefik_labels` | `[]` | Labels attached to the Traefik service |
| `traefik_environment` | `[]` | Additional container environment entries |
| `traefik_extra_arguments` | `[]` | Additional Traefik CLI arguments |

The complete public interface and type constraints are defined in
`roles/traefik/meta/argument_specs.yml`.

## Security notes

- The dashboard is disabled by default and `api.insecure` is fixed to `false`.
- Docker services are not exposed by default.
- Generated configuration uses mode `0600`; this protects DNS API credentials
  embedded in the Compose environment.
- Mounting the Docker socket grants substantial control over the Docker host,
  even when the mount is marked read-only. Set `traefik_docker_socket: ""` and
  point `traefik_docker_endpoint` at a restricted socket proxy when required.
- Extra CLI arguments can override role-managed settings and should be reviewed
  as privileged configuration.

See the current [Traefik Docker provider documentation](https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/)
and [ACME reference](https://doc.traefik.io/traefik/reference/install-configuration/tls/certificate-resolvers/acme/)
for provider-specific requirements.
