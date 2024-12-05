#!/usr/bin/python
#
# SPDX-License-Identifier: Apache-2.0

"""
Ansible Collection module that provides a function for the OpenAPI definition to delete SBOM to the
Dependency-Track API server.
"""

from __future__ import absolute_import, division, print_function
from ansible.module_utils.basic import AnsibleModule
import requests

__metaclass__ = type

DOCUMENTATION = r"""
---
module: bom_delete
short_description: Manage delete BOM with REST API
description:
  - Delete BOM using OpenAPI defination for OWASP Dependency-Track API server.
options:
  base_url:
    description: The base URL of the API.
    required: true
    type: str
  api_key:
    description: The API key for authentication.
    required: true
    type: str
  uuid:
    description: The UUID of the BOM.
    required: true
    type: str
"""

EXAMPLES = r"""
- name: Delete a BOM
  sentenz.dependency_track.bom_delete:
    base_url: http://myapi.com
    api_key: myapikey
    uuid: myuuid
"""

RETURN = r"""
message:
  description: The response from the API.
  type: str
  returned: always
"""


class Repository:
    def __init__(self, base_url, api_key):
        self.base_url = base_url
        self.headers = {"X-Api-Key": api_key}

    def delete_bom(self, uuid):
        response = requests.delete(
            f"{self.base_url}:8081/v1/project/{uuid}", headers=self.headers, timeout=10
        )
        return response.status_code


def run_module():
    module_args = dict(
        base_url=dict(type="str", required=True),
        api_key=dict(type="str", required=True),
        uuid=dict(type="str", required=True),
    )

    result = dict(changed=False, original_message="", message="")

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    if module.check_mode:
        return result

    repo = Repository(module.params["base_url"], module.params["api_key"])
    status_code = repo.delete_bom(module.params["uuid"])

    result["original_message"] = module.params
    result["message"] = (
        "BOM deleted successfully" if status_code == 200 else "Failed to delete BOM"
    )

    module.exit_json(**result)


def main():
    run_module()


if __name__ == "__main__":
    main()
