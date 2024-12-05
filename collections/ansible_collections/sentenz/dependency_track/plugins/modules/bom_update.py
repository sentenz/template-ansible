#!/usr/bin/python
#
# SPDX-License-Identifier: Apache-2.0

"""
Ansible Collection module that provides a function for the OpenAPI definition to update SBOM to the
Dependency-Track API server.
"""

from __future__ import absolute_import, division, print_function
from ansible.module_utils.basic import AnsibleModule
import requests

__metaclass__ = type

DOCUMENTATION = r"""
---
module: bom_update
short_description: Manage update BOM with REST API
description:
  - Update BOM using OpenAPI defination for OWASP Dependency-Track API server.
options:
  base_url:
    description: The base URL of the API.
    required: true
    type: str
  api_key:
    description: The API key for authentication.
    required: true
    type: str
  body:
    description: The body of the request.
    required: true
    type: dict
"""

EXAMPLES = r"""
---
- hosts: localhost
  gather_facts: no
  vars:
    json_file: "sbom-v1.0.1.cdx.json"
  tasks:
    - name: Load JSON file
      set_fact:
        bom_data: "{{ lookup('file', json_file) | from_json }}"

    - name: Update BOM
      sentenz.dependency_track.bom_read:
        base_url: 'http://myapi.com'
        api_key: 'myapikey'
        body: "{{ bom_data }}"
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


class Repository:
    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.headers = {"X-Api-Key": api_key}

    def update_bom(self, body=None):
        response = requests.put(
            f"{self.base_url}:8081/api/v1/bom",
            headers=self.headers,
            json=body,
            timeout=10,
        )
        return response.json()


def run_module():
    module_args = dict(
        base_url=dict(type="str", required=True),
        api_key=dict(type="str", required=True),
        body=dict(type="dict", required=True),
    )

    result = dict(changed=False, original_message="", message="")

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    if module.check_mode:
        return result

    repo = Repository(module.params["base_url"], module.params["api_key"])
    bom = repo.update_bom(module.params["body"])

    result["original_message"] = module.params
    result["message"] = bom

    module.exit_json(**result)


def main():
    run_module()


if __name__ == "__main__":
    main()
