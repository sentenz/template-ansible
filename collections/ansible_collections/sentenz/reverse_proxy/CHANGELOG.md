# Changelog

All notable changes to `sentenz.reverse_proxy` are documented in this file.

## 1.1.0 - 2026-08-20

### Added

- Role argument validation and explicit Compose lifecycle state management.
- Safe defaults for the dashboard, Docker discovery, file permissions, and
  container health checks.
- A file certificate mode and a non-TLS development mode.

### Changed

- Pinned Traefik to 3.7.11 and updated `community.docker` to the compatible
  4.8.8 maintenance release.
- Reworked Compose rendering so empty networks and optional sections remain
  valid YAML.
- Replaced the challenge metadata dictionary with a validated string value.

### Fixed

- Prevented normal role runs from deploying, destroying, restarting, and
  stopping the same Compose project in sequence.
- Preserved existing ACME account and certificate data across role runs.
- Disabled Traefik's insecure API mode.

### Removed

- Domain-specific example certificates and the encrypted example private key.
- An unused Traefik static configuration template.

## 1.0.0 - 2025-07-28

- Initial collection release.
