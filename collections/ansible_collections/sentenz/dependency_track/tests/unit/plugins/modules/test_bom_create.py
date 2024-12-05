# SPDX-License-Identifier: Apache-2.0

"""Ansible Collection unit tests for the `sentenz.dependency_track` using `pytest` for testing."""

from __future__ import absolute_import, division, print_function

__metaclass__ = type

from unittest.mock import patch, MagicMock
from ansible_collections.sentenz.dependency_track.plugins.modules.bom_create import (
    create_bom,
)


@patch("requests.post")
def test_create_bom(mock_post):
    # Arrange
    data = {
        "base_url": "https://your-api-server.com",
        "api_key": "your_api_key",
        "sbom_file_path": "examples/plugins/sbom.cdx.json",
        "project": "your_project",
        "auto_create": True,
        "project_name": "your_project_name",
        "project_version": "1.0.0",
    }

    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"message": "Success"}
    mock_post.return_value = mock_response

    # Act
    result = create_bom(data)

    # Assert
    mock_post.assert_called_once()
    assert result["changed"] is True
    assert result["message"] == "SBOM uploaded successfully."
    assert result["response"] == {"message": "Success"}
