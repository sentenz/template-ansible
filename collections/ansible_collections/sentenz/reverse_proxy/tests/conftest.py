# SPDX-License-Identifier: Apache-2.0
"""Run real Ansible file tasks and Compose validation, replacing only deployment."""

import grp
import json
import os
from pathlib import Path
import pwd
import shutil
import subprocess
import sys

import pytest

COLLECTION = Path(__file__).resolve().parents[1]


@pytest.fixture
def role_run(tmp_path):
    collection_path = tmp_path / "collections" / "ansible_collections"
    collection_path.mkdir(parents=True)
    (collection_path / "sentenz").symlink_to(
        COLLECTION.parent, target_is_directory=True
    )
    mock = collection_path / "community/docker/plugins/modules"
    mock.mkdir(parents=True)
    shutil.copyfile(
        COLLECTION / "tests/fixtures/compose_module.py", mock / "docker_compose_v2.py"
    )
    compose = os.environ.get("COMPOSE_BINARY")
    docker = shutil.which("docker")
    if compose:
        docker = str(tmp_path / "docker")
        Path(docker).write_text(
            f"#!{sys.executable}\nimport os, sys\n"
            "assert sys.argv[1] == 'compose'\n"
            f"os.execv({compose!r}, [{compose!r}, *sys.argv[2:]])\n"
        )
        Path(docker).chmod(0o755)
    if not docker:
        pytest.fail(
            "Install Docker Compose or set COMPOSE_BINARY to its standalone binary"
        )

    config = tmp_path / "ansible.cfg"
    config.write_text("[defaults]\nretry_files_enabled = False\n")
    temporary = tmp_path / "tmp"
    temporary.mkdir()
    env = dict(os.environ)
    env.update(
        TMPDIR=str(temporary),
        ANSIBLE_CONFIG=str(config),
        ANSIBLE_COLLECTIONS_PATH=str(collection_path.parent),
        ANSIBLE_HOME=str(tmp_path / "ansible-home"),
        ANSIBLE_LOCAL_TEMP=str(tmp_path / "ansible-local"),
        ANSIBLE_REMOTE_TEMP=str(tmp_path / "ansible-remote"),
        ANSIBLE_NOCOLOR="1",
    )
    variables = {
        "traefik_path": str(tmp_path / "project"),
        "traefik_docker_cli": docker,
        "traefik_ownership_owner": pwd.getpwuid(os.getuid()).pw_name,
        "traefik_ownership_group": grp.getgrgid(os.getgid()).gr_name,
        "ansible_python_interpreter": sys.executable,
    }

    def run(overrides=None, args=(), success=True):
        variables.update(overrides or {})
        varfile = tmp_path / "vars.json"
        varfile.write_text(json.dumps(variables))
        varfile.chmod(0o600)
        result = subprocess.run(
            [
                "ansible-playbook",
                "-i",
                "localhost,",
                str(COLLECTION / "tests/playbook.yml"),
                "-e",
                f"@{varfile}",
                *args,
            ],
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=90,
            check=False,
        )
        if success:
            assert result.returncode == 0, result.stdout
        else:
            assert result.returncode != 0, result.stdout
        return result.stdout

    run.variables = variables
    run.project = tmp_path / "project"
    run.calls = lambda: (
        [
            json.loads(line)
            for line in (tmp_path / "compose-calls.jsonl").read_text().splitlines()
        ]
        if (tmp_path / "compose-calls.jsonl").exists()
        else []
    )
    run.compose = lambda: json.loads(
        subprocess.check_output(
            [
                docker,
                "compose",
                "-f",
                str(run.project / "docker-compose.yml"),
                "config",
                "--format",
                "json",
            ],
            text=True,
        )
    )
    return run
