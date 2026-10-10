# SPDX-License-Identifier: Apache-2.0
"""Test double recording orchestration, not a Docker engine simulation."""

import hashlib
import json
from pathlib import Path

from ansible.module_utils.basic import AnsibleModule


def main():
    module = AnsibleModule(
        argument_spec={
            "project_src": {"type": "path", "required": True},
            "files": {"type": "list", "elements": "str"},
            "docker_cli": {"type": "path"},
            "state": {"type": "str"},
            "recreate": {"type": "str", "default": "auto"},
            "pull": {"type": "str"},
            "wait": {"type": "bool"},
            "wait_timeout": {"type": "int"},
            "remove_volumes": {"type": "bool"},
        },
        supports_check_mode=True,
    )
    project = Path(module.params["project_src"])
    state = module.params["state"]
    marker = project.parent / "last-compose-hash"
    digest = ""
    if state == "present":
        digest = hashlib.sha256(
            (project / "docker-compose.yml").read_bytes()
        ).hexdigest()
    changed = (
        state != "present"
        or module.params["recreate"] == "always"
        or not marker.exists()
        or marker.read_text() != digest
    )
    if not module.check_mode:
        with (project.parent / "compose-calls.jsonl").open("a") as stream:
            stream.write(json.dumps(module.params) + "\n")
        marker.write_text(digest)
    module.exit_json(changed=changed)


if __name__ == "__main__":
    main()
