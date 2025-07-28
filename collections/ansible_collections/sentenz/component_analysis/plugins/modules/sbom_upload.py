#!/usr/bin/python
#
# SPDX-License-Identifier: Apache-2.0

"""
Ansible module to upload an SBOM to the Dependency-Track API server using the OpenAPI endpoint.
"""

from __future__ import absolute_import, division, print_function
from ansible.module_utils.basic import AnsibleModule
import requests

DOCUMENTATION = r"""
---
module: sbom_upload
short_description: Upload an SBOM file to Dependency-Track
description:
  - Sends a Software Bill of Materials (SBOM) file to the Dependency-Track API server using multipart/form-data.
  - Supports all shema types properties such as auto-creation of a project, hierarchical (parent) project associations, and marking the uploaded SBOM as the latest.
options:
  api_url:
    description:
      - Base URL of the Dependency-Track API server (e.g., https://api.example.com).
    required: true
    type: str
  api_key:
    description:
      - API key or token for authentication (sent in `X-Api-Key` header).
    required: true
    type: str
    no_log: true
  project_uuid:
    description:
      - UUID of an existing project to which the SBOM will be attached.
      - If omitted and `auto_create` is true, a new project will be created using `project_name` and `project_version`.
    required: false
    type: str
  project_name:
    description:
      - Human-readable name of the project.
      - Required if `auto_create` is true and `project_uuid` is not provided.
    required: false
    type: str
  project_version:
    description:
      - Version string of the project (e.g., "1.0.0"”").
      - Required if `auto_create` is true and `project_uuid` is not provided.
    required: false
    type: str
  project_tags:
    description:
      - Comma-separated tags to associate with the project (optional).
    required: false
    type: str
  parent_name:
    description:
      - Name of a parent project in a hierarchical project structure (optional).
    required: false
    type: str
  parent_version:
    description:
      - Version of the parent project (optional).
    required: false
    type: str
  parent_uuid:
    description:
      - UUID of an existing parent project (optional).
    required: false
    type: str
  auto_create:
    description:
      - Whether to automatically create a new project if none exists.
      - When true, `project_name` and `project_version` must be provided.
    required: false
    type: bool
    default: false
  is_latest:
    description:
      - Whether to mark this SBOM upload as the latest for the specified project.
    required: false
    type: bool
    default: false
  verify_certs:
    description:
      - Whether to verify the server TLS certificate. Set to false if using self-signed certificates.
    required: false
    type: bool
    default: true
  bom_file:
    description:
      - Path to the SBOM JSON file to upload.
    required: true
    type: path
"""

RETURN = r"""
status_code:
  description: HTTP status code returned by Dependency-Track API.
  type: int
  returned: always
upload_token:
  description: Token returned by the API to reference the uploaded SBOM (if provided).
  type: str
  returned: when present
msg:
  description: Detailed error message when `failed` is true.
  type: str
  returned: when an error occurred
"""

EXAMPLES = r"""
---
- hosts: localhost
  connection: local
  gather_facts: false

  vars:
    sbom_api_url: "https://api.component-analysis.localhost"
    sbom_api_key: "$API_KEY"
    sbom_auto_create: true
    sbom_parent_name: "Test Project"
    sbom_project_name: "Test Project"
    sbom_project_version: "4.13.13"
    sbom_is_latest: true
    sbom_file: "{{ playbook_dir }}/../test/sbom/sbom.cdx.dependencytrack-application-v4.13.2.json"
    sbom_verify_certs: false

  tasks:
    - name: SBOM - Upload SBOM to Dependency-Track
      sentenz.sbom.sbom_upload:
        api_url: "{{ sbom_api_url }}"
        api_key: "{{ sbom_api_key }}"
        parent_name: "{{ sbom_parent_name }}"
        project_name: "{{ sbom_project_name }}"
        project_version: "{{ sbom_project_version }}"
        auto_create: "{{ sbom_auto_create }}"
        is_latest: "{{ sbom_is_latest }}"
        bom_file: "{{ sbom_file }}"
        verify_certs: "{{ sbom_verify_certs }}"
      register: upload_result

    - name: SBOM - Display upload response
      debug:
        msg:
          - "HTTP Status Code: {{ upload_result.status_code }}"
          - "Upload Token: {{ upload_result.upload_token | default('N/A') }}"
"""


def sbom_upload(params):
    """
    Uploads an SBOM file to Dependency-Track API using OpenAPI (/api/v1/bom) properties via
    multipart/form-data.

    Args:
      - api_url         (str): Base URL of Dependency-Track API server (https://api.example.com).
      - api_key         (str): API key for Dependency-Track (X-Api-Key header).
      - project_uuid    (str): UUID of an existing project (optional if autoCreate).
      - project_name    (str): Name of the project (required if autoCreate is True).
      - project_version (str): Version string of the project (required if autoCreate is True).
      - project_tags    (str): Tags for the project (optional).
      - parent_name     (str): Parent project name (optional).
      - parent_version  (str): Parent project version (optional).
      - parent_uuid     (str): Parent project UUID (optional).
      - is_latest       (bool): Mark this upload as the latest BOM (default: False).
      - auto_create     (bool): Auto-create project if it doesnt exist (default: False).
      - bom_file        (path): Path on local filesystem to the SBOM file to upload.
      - verify_ssl      (bool): Determine whether to verify SSL certificates (default: True).

    Returns:
      A dict with keys:
        - changed      (bool)
        - status_code  (int)
        - upload_token (str, if returned by the API)
        - failed       (bool, only if an exception occurred)
        - msg          (str, only if failed)
    """

    endpoint = f"{params['api_url'].rstrip('/')}/api/v1/bom"

    # NOTE Requests will set Content-Type automatically for multipart
    headers = {
        "X-Api-Key": params["api_key"],
    }

    # Build form-data fields
    fields = {
        "project": params.get("project_uuid"),
        "autoCreate": str(params.get("auto_create", False)).lower(),
        "projectName": params.get("project_name"),
        "projectVersion": params.get("project_version"),
        "projectTags": params.get("project_tags"),
        "parentName": params.get("parent_name"),
        "parentVersion": params.get("parent_version"),
        "parentUUID": params.get("parent_uuid"),
        "isLatest": str(params.get("is_latest", False)).lower(),
    }
    # Drop None or empty‐string values
    data = {k: v for k, v in fields.items() if v not in (None, "")}

    # Open the SBOM file in binary mode for multipart upload
    try:
        bom_handle = open(params["bom_file"], "rb")
    except OSError as e:
        return {
            "failed": True,
            "msg": f"Failed to open SBOM file '{params['bom_file']}': {e}",
        }
    files = {"bom": (params["bom_file"], bom_handle)}

    # SSL/TLS verification
    # XXX Only set to `True` in the `dev` environment
    verify_ssl = params.get("verify_certs", True)

    try:
        response = requests.post(
            endpoint,
            headers=headers,
            data=data,
            files=files,
            timeout=30,
            verify=verify_ssl,
        )

        bom_handle.close()
        response.raise_for_status()
    except requests.exceptions.HTTPError as errh:
        return {
            "failed": True,
            "msg": f"HTTP error: {errh}",
            "status_code": getattr(errh.response, "status_code", "unknown"),
        }
    except requests.exceptions.RequestException as err:
        return {"failed": True, "msg": f"Request error: {err}"}

    # Capture the API upload token returned in the JSON body
    try:
        body = response.json()
    except ValueError:
        body = {}

    return {
        "changed": True,
        "status_code": response.status_code,
        "upload_token": body.get("token"),
    }


def main():
    """Ansible module plugin for uploading SBOM."""

    argument_spec = dict(
        api_url=dict(type="str", required=True),
        api_key=dict(type="str", required=True, no_log=True),
        project_uuid=dict(type="str", required=False),
        project_name=dict(type="str", required=False),
        project_version=dict(type="str", required=False),
        project_tags=dict(type="str", required=False),
        parent_name=dict(type="str", required=False),
        parent_version=dict(type="str", required=False),
        parent_uuid=dict(type="str", required=False),
        is_latest=dict(type="bool", default=False),
        auto_create=dict(type="bool", default=False),
        bom_file=dict(type="path", required=True),
        verify_certs=dict(type="bool", default=True),
    )
    module = AnsibleModule(argument_spec=argument_spec, supports_check_mode=False)

    result = sbom_upload(module.params)
    if result.get("failed"):
        module.fail_json(**result)
    else:
        module.exit_json(**result)


if __name__ == "__main__":
    main()
