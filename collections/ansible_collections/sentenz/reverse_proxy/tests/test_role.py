# SPDX-License-Identifier: Apache-2.0
"""Regression tests for file safety and task selection; no Docker daemon needed."""

import json
import re
import stat

import pytest
import yaml


def unchanged(output):
    assert re.search(r"changed=0\s", output), output


@pytest.mark.parametrize("challenge", ["debug", "intranet", "http", "dns", "tls"])
def test_modes_check_mode_idempotency_and_secure_compose(role_run, tmp_path, challenge):
    variables = {
        "traefik_challenge": challenge,
        "traefik_acme_email": "operator@example.org",
    }
    if challenge == "intranet":
        # File-task fixtures; actual TLS parsing is exercised by the runtime test.
        cert, key = tmp_path / "public.pem", tmp_path / "private.pem"
        cert.write_text("certificate fixture\n")
        key.write_text("private key fixture\n")
        variables.update(
            traefik_tls_public_cert=str(cert), traefik_tls_private_key=str(key)
        )
    if challenge == "dns":
        variables.update(
            traefik_acme_storage="/letsencrypt/custom.json",
            traefik_challenge_dns_provider_variables=[
                'CF_DNS_API_TOKEN=literal$token:"quoted"'
            ],
            traefik_networks=["edge"],
        )
    dry = role_run(variables, args=("--check", "--diff"))
    assert not role_run.project.exists()
    assert not role_run.calls()
    assert "literal$token" not in dry

    first = role_run(args=("--diff",))
    assert "literal$token" not in first
    assert [call["state"] for call in role_run.calls()] == ["present"]
    service = role_run.compose()["services"]["traefik"]
    assert "--api=false" in service["command"]
    assert "--api.insecure=true" not in service["command"]
    assert (
        "--entrypoints.web.http.redirections.entrypoint.scheme=https"
        in service["command"]
    )
    assert service["read_only"] is True
    assert service["cap_drop"] == ["ALL"]
    assert "--ping" in service["healthcheck"]["test"]
    assert {str(port["target"]) for port in service["ports"]} == {"80", "443"}
    assert (
        stat.S_IMODE((role_run.project / "docker-compose.yml").stat().st_mode) == 0o600
    )
    dynamic = yaml.safe_load((role_run.project / "dynamic/dynamic.yml").read_text())
    assert dynamic["tls"]["options"]["default"]["minVersion"] == "VersionTLS12"
    if challenge == "dns":
        # `compose config` re-escapes dollars when serializing its resolved model.
        assert (
            service["environment"]["CF_DNS_API_TOKEN"].replace("$$", "$")
            == 'literal$token:"quoted"'
        )

    unchanged(role_run())
    if challenge in {"http", "dns", "tls"}:
        filename = "custom.json" if challenge == "dns" else "acme.json"
        state = role_run.project / "certs" / filename
        sentinel = json.dumps({"account": "existing-certificate-state"})
        state.write_text(sentinel)
        state.chmod(0o644)
        repair_output = role_run()
        assert state.read_text() == sentinel
        assert stat.S_IMODE(state.stat().st_mode) == 0o600, repair_output
        unchanged(role_run())
        assert state.read_text() == sentinel


def test_lifecycle_tags_are_explicit_and_exclusive(role_run):
    role_run()
    unchanged(role_run(args=("--tags", "traefik_test")))
    before = len(role_run.calls())
    role_run(args=("--tags", "never"))
    assert len(role_run.calls()) == before
    role_run(args=("--tags", "stop,restart"), success=False)
    assert len(role_run.calls()) == before
    for tag, state in [
        ("stop", "stopped"),
        ("restart", "present"),
        ("destroy", "absent"),
    ]:
        role_run(args=("--tags", tag))
        assert len(role_run.calls()) == before + 1
        assert role_run.calls()[-1]["state"] == state
        before += 1


@pytest.mark.parametrize(
    "variables",
    [
        {"traefik_challenge": "unknown"},
        {"traefik_challenge": {"default": "debug"}},
        {"traefik_challenge": "intranet"},
        {
            "traefik_challenge": "dns",
            "traefik_acme_email": "operator@example.org",
            "traefik_challenge_dns_provider_variables": "CF_DNS_API_TOKEN=secret-marker",
        },
        {"traefik_challenge": "http"},
        {"traefik_permission_file": "0644"},
        {"traefik_networks": "edge"},
    ],
)
def test_invalid_inputs_fail_before_writes(role_run, variables):
    output = role_run(variables, success=False)
    assert not role_run.project.exists()
    assert not role_run.calls()
    assert "secret-marker" not in output


def test_socket_proxy_omits_host_socket_and_port_overrides_work(role_run):
    role_run(
        {
            "traefik_docker_endpoint": "tcp://socket-proxy:2375",
            "traefik_published_ports": ["127.0.0.1:8443:443"],
            "traefik_forwarded_headers_trusted_ips": ["192.0.2.0/24"],
        }
    )
    service = role_run.compose()["services"]["traefik"]
    assert all("docker.sock" not in volume["source"] for volume in service["volumes"])
    assert service["ports"][0]["host_ip"] == "127.0.0.1"
    assert (
        "--entrypoints.websecure.forwardedheaders.trustedips=192.0.2.0/24"
        in service["command"]
    )


def test_invalid_compose_does_not_replace_working_file(role_run):
    role_run()
    original = (role_run.project / "docker-compose.yml").read_bytes()
    count = len(role_run.calls())
    role_run({"traefik_published_ports": ["invalid-port"]}, success=False)
    assert (role_run.project / "docker-compose.yml").read_bytes() == original
    assert len(role_run.calls()) == count


def test_certificate_rotation_triggers_one_recreation(role_run, tmp_path):
    cert, key = tmp_path / "public.pem", tmp_path / "private.pem"
    cert.write_text("certificate fixture\n")
    key.write_text("private key fixture\n")
    role_run(
        {"traefik_tls_public_cert": str(cert), "traefik_tls_private_key": str(key)}
    )
    assert len(role_run.calls()) == 1
    key.write_text("rotated private key fixture\n")
    role_run()
    assert [call["recreate"] for call in role_run.calls()] == ["always", "always"]
    unchanged(role_run())
