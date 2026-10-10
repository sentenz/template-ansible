# SPDX-License-Identifier: Apache-2.0
"""Optional native Traefik smoke test; Docker discovery and ACME are not exercised."""

import http.client
import os
import socket
import ssl
import subprocess
import time

import pytest
import yaml


def free_port():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


def request(port, path="/", context=None, headers=None):
    cls = http.client.HTTPSConnection if context else http.client.HTTPConnection
    options = {"context": context} if context else {}
    conn = cls("127.0.0.1", port, timeout=2, **options)
    try:
        conn.request("GET", path, headers=headers or {})
        response = conn.getresponse()
        response.read()
        return response.status, dict(response.getheaders())
    finally:
        conn.close()


def tls_context(version):
    # The debug-mode certificate is intentionally self-signed in this local test.
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    context.minimum_version = context.maximum_version = version
    return context


def test_health_redirect_tls_policy_and_atomic_reload(role_run, tmp_path):
    binary = os.environ.get("TRAEFIK_BINARY")
    if not binary:
        pytest.skip("Set TRAEFIK_BINARY to run the native runtime smoke test")
    role_run()
    service = role_run.compose()["services"]["traefik"]
    # Match an actual router so request-policy middleware is exercised.
    dynamic = role_run.project / "dynamic/dynamic.yml"
    config = yaml.safe_load(dynamic.read_text())
    config["http"] = {
        "routers": {
            "probe": {
                "rule": "PathPrefix(`/probe`)",
                "service": "ping@internal",
                "entryPoints": ["websecure"],
                "tls": {},
            }
        }
    }
    dynamic.write_text(yaml.safe_dump(config))
    web, secure, health = free_port(), free_port(), free_port()
    replacements = {
        "--entrypoints.web.address=": f"127.0.0.1:{web}",
        "--entrypoints.websecure.address=": f"127.0.0.1:{secure}",
        "--entrypoints.healthcheck.address=": f"127.0.0.1:{health}",
        "--providers.file.directory=": str(role_run.project / "dynamic"),
    }
    flags = []
    for flag in service["command"]:
        if flag.startswith("--providers.docker"):
            continue
        for prefix, value in replacements.items():
            if flag.startswith(prefix):
                flag = prefix + value
                break
        flags.append(flag)
    flags.append("--providers.docker=false")
    log_path = tmp_path / "traefik.log"
    with log_path.open("w") as log:
        process = subprocess.Popen(
            [binary, *flags], cwd=tmp_path, stdout=log, stderr=log
        )
        try:
            deadline = time.monotonic() + 15
            while True:
                assert process.poll() is None, log_path.read_text()
                try:
                    if request(health, "/ping")[0] == 200:
                        break
                except (OSError, http.client.HTTPException):
                    pass
                assert time.monotonic() < deadline, log_path.read_text()
                time.sleep(0.1)
            health_flags = [
                (
                    f"--entrypoints.healthcheck.address=127.0.0.1:{health}"
                    if flag.startswith("--entrypoints.healthcheck.address=")
                    else flag
                )
                for flag in service["healthcheck"]["test"][3:]
            ]
            subprocess.run(
                [binary, "healthcheck", *health_flags], check=True, capture_output=True
            )
            # Provider initialization is asynchronous after the ping endpoint starts.
            deadline = time.monotonic() + 10
            while True:
                status, headers = request(web, "/resource")
                if status in (301, 308):
                    break
                assert time.monotonic() < deadline, log_path.read_text()
                time.sleep(0.1)
            assert headers["Location"] == f"https://127.0.0.1:{secure}/resource"
            tls12 = tls_context(ssl.TLSVersion.TLSv1_2)
            tls13 = tls_context(ssl.TLSVersion.TLSv1_3)
            assert request(secure, "/api/version", tls12)[0] == 404
            assert request(secure, "/probe", tls12)[0] == 200
            assert request(secure, "/probe/a%2Fb", tls12)[0] == 400
            assert (
                request(secure, "/probe", tls12, headers={"X_Auth_User": "spoof"})[0]
                == 400
            )
            replacement = dynamic.with_suffix(".tmp")
            replacement.write_text(
                dynamic.read_text().replace("VersionTLS12", "VersionTLS13")
            )
            replacement.replace(dynamic)
            deadline = time.monotonic() + 10
            while True:
                try:
                    request(secure, context=tls12)
                except ssl.SSLError:
                    break
                assert time.monotonic() < deadline, "TLS policy was not hot-reloaded"
                time.sleep(0.1)
            assert request(secure, context=tls13)[0] == 404
            assert request(health, "/ping")[0] == 200
        finally:
            process.terminate()
            process.wait(timeout=10)
