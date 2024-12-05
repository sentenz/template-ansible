#!/usr/bin/python
#
# SPDX-License-Identifier: Apache-2.0

"""
Ansible Collection module that provides a function for the OpenAPI definition to upload SBOM to the
Dependency-Track API server.
"""

from __future__ import absolute_import, division, print_function
from ansible.module_utils.basic import AnsibleModule
import requests

__metaclass__ = type

DOCUMENTATION = r"""
---
module: bom_create
short_description: Manage create BOM with REST API
description:
  - Create BOM using OpenAPI defination for OWASP Dependency-Track API server.
options:
  base_url:
    description: The base URL of the API.
    required: true
    type: str
  api_key:
    description: The API key for authentication.
    required: true
    type: str
  project:
    description: The project identifier.
    required: false
    type: str
  autoCreate:
    description: Whether to automatically create the project.
    required: false
    type: bool
    default: false
  projectName:
    description: The name of the project.
    required: false
    type: str
  projectVersion:
    description: The version of the project.
    required: false
    type: str
  parentName:
    description: The name of the parent project.
    required: false
    type: str
  parentVersion:
    description: The version of the parent project.
    required: false
    type: str
  parentUUID:
    description: The UUID of the parent project.
    required: false
    type: str
"""

EXAMPLES = r"""
---
- hosts: localhost
  gather_facts: false

  tasks:
    - name: Create BOM
      sentenz.dependency_track.bom_create:
        base_url: "{{ base_url }}"
        api_key: "{{ api_key }}"
        sbom_file_path: "{{ sbom_file_path }}"
        project_name: "{{ project_name }}"
        project_version: "{{ project_version }}"
        auto_create: true
      register: result

    - name: Debug output
      debug:
        var: result.message
"""

RETURN = r"""
message:
  description: The response from the API.
  type: dict
  returned: always
"""


def create_bom(data):
    """
    Send a POST request to upload a Bill of Materials (BOM).

    :param base_url: The API base URL.
    :param api_key: The API key for authentication.
    :param project_id: The unique identifier for the project.
    :param file_path: The file path of the BOM to upload.
    """

    base_url = data["base_url"]
    api_key = data["api_key"]
    sbom_file_path = data["sbom_file_path"]
    project = data.get("project")
    auto_create = data.get("auto_create", False)
    project_name = data.get("project_name")
    project_version = data.get("project_version")
    parent_name = data.get("parent_name")
    parent_version = data.get("parent_version")
    parent_uuid = data.get("parent_uuid")

    payload = {
        "project": (None, project),
        "autoCreate": (None, str(auto_create)),
        "projectName": (None, project_name),
        "projectVersion": (None, project_version),
        "parentName": (None, parent_name),
        "parentVersion": (None, parent_version),
        "parentUUID": (None, parent_uuid),
    }

    headers = {"X-Api-Key": api_key, "Content-Type": "multipart/form-data"}

    files = {"bom": open(sbom_file_path, "rb")}

    response = requests.post(
        f"{base_url}:8081/api/v1/bom",
        headers=headers,
        data=payload,
        files=files,
        timeout=10,
    )

    if response.status_code == 200:
        return {
            "changed": True,
            "message": "SBOM uploaded successfully.",
            "response": response.json(),
        }
    else:
        return {
            "changed": False,
            "message": f"Failed to upload SBOM. Server responded status: {response.status_code}.",
        }


def run_module():
    argument_spec = dict(
        base_url=dict(required=True, type="str"),
        api_key=dict(required=True, type="str", no_log=True),
        sbom_file_path=dict(required=True, type="str"),
        project=dict(required=False, type="str"),
        auto_create=dict(required=False, type="bool", default=False),
        project_name=dict(required=False, type="str"),
        project_version=dict(required=False, type="str"),
        parent_name=dict(required=False, type="str"),
        parent_version=dict(required=False, type="str"),
        parent_uuid=dict(required=False, type="str"),
    )

    module = AnsibleModule(argument_spec=argument_spec, supports_check_mode=True)

    result = create_bom(module.params)

    module.exit_json(**result)


def main():
    run_module()


if __name__ == "__main__":
    main()
