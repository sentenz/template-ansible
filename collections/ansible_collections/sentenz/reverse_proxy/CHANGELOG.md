# Changelog

## Unreleased

- Upgrade Traefik to security patch v3.7.14 with verified image-index digest,
  including the dev, stage, and prod inventory overrides.
- Make destructive lifecycle actions opt-in and mutually exclusive; avoid duplicate restarts.
- Preserve ACME account/certificate data across runs and enforce restrictive permissions.
- Disable unauthenticated API access, protect rendered credentials and diffs, retain
  literal credentials through Compose interpolation, and pin the role image default.
- Add HTTPS redirection, explicit TLS/trusted-proxy defaults, container hardening,
  bounded logging, loopback health checks, and health-checked deployments.
- Mount watched configuration/certificate directories and validate Compose before replacement.
- Correct the Ansible compatibility floor to 2.17 and declare collection dependencies.
- Validate role inputs, support safe first-run check mode, and document migrations.
- Add regression tests and optional native Traefik smoke coverage.
