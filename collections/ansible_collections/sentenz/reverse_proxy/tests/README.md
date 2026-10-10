# Reverse proxy tests

Run from the repository root in a Python 3.12 virtual environment:

```sh
python -m pip install 'ansible-core>=2.19,<2.20' ansible-lint pytest PyYAML
ansible-galaxy collection install -r collections/ansible_collections/sentenz/reverse_proxy/requirements.yml
export ANSIBLE_COLLECTIONS_PATH="$PWD/collections:$HOME/.ansible/collections"
ansible-lint --offline collections/ansible_collections/sentenz/reverse_proxy
ansible-playbook -i localhost, collections/ansible_collections/sentenz/reverse_proxy/tests/playbook.yml --syntax-check
pytest -q collections/ansible_collections/sentenz/reverse_proxy/tests
```

Docker Compose must be available as `docker compose`, or set `COMPOSE_BINARY` to an
absolute path to the standalone Compose binary. No Docker daemon, production
inventory, Vault password, external DNS credential, or elevated privilege is needed.

The tests execute actual Ansible input checks and file modules in temporary directories,
plus real `docker compose config` validation. A test-only `docker_compose_v2` module
records lifecycle calls and recognizes Compose-content changes. This establishes
orchestration and filesystem idempotency; it does not establish real-container
idempotency, Docker discovery, health-wait behavior, capability enforcement, or ACME issuance.

Tests cover all five challenge modes, first-run check mode, secret-safe diffs,
ACME content preservation and permission repair, empty/external networks, literal
credential quoting, invalid-input rejection, atomic Compose validation, lifecycle
selection (including inherited role tags), and single-recreation certificate rotation.

Set `TRAEFIK_BINARY` to a checksum-verified Traefik v3.7.14 executable to enable the
native smoke test. It uses temporary loopback ports and the rendered CLI configuration,
with Docker discovery disabled and the file-provider path adapted to the host. It
checks the real healthcheck command, HTTP redirect, disabled API route, TLS 1.2/1.3,
and atomic dynamic TLS-policy reload. It does not contact a certificate authority.

The CI workflow runs the role tests on Ansible 2.17 and 2.19 and separately lints with
Ansible 2.19. A real Docker-host staging run remains necessary before production:
converge twice, verify the second run is unchanged, exercise a real routed backend,
rotate a supplied certificate, confirm ACME renewal with a staging CA, and test
stop/restart/destroy while confirming ACME state survives.
