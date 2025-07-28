# Ansible Collection for Component Analysis

- [1. Roles](#1-roles)
  - [1.1. Dependency-Track](#11-dependency-track)
    - [1.1.1. API Server](#111-api-server)
      - [1.1.1.1. Details](#1111-details)
      - [1.1.1.2. Role](#1112-role)
    - [1.1.2. Front End](#112-front-end)
      - [1.1.2.1. Details](#1121-details)
      - [1.1.2.2. Role](#1122-role)
- [2. Plugins](#2-plugins)
  - [2.1. Module](#21-module)
  - [2.2. Install and Uninstall](#22-install-and-uninstall)
  - [2.3. Examples and Explanations](#23-examples-and-explanations)

## 1. Roles

### 1.1. Dependency-Track

OWASP Dependency-Track is an intelligent Component Analysis platform for organizations to identify and reduce risk in the software supply chain.

#### 1.1.1. API Server

##### 1.1.1.1. Details

1. Compoments and Features

    - [Dependency-Track API Server](https://github.com/DependencyTrack/dependency-track)
      > Dependency-Track monitors component usage across all versions of every application in its portfolio in order to proactively identify risk across an organization.

      > [!NOTE]
      > Available as [Ansible Role](roles/dependency_track/apiserver/tasks/main.yml) in the Collection.

    - [Dependency-Track API Server](https://hub.docker.com/r/dependencytrack/apiserver) Docker Hub
      > The official docker container.

##### 1.1.1.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Component Analysis
        hosts: component_analysis
        become: true
        roles:
          - role: component_analysis.dependency_track.apiserver
      ```

#### 1.1.2. Front End

##### 1.1.2.1. Details

1. Compoments and Features

    - [Dependency-Track Front End (UI)](https://github.com/grafana/grafana)
      > The Front-End is a Single Page Application (SPA) used in Dependency-Track.

      > [!NOTE]
      > Available as [Ansible Role](roles/dependency_track/frontend/tasks/main.yml) in the Collection.

    - [Dependency-Track Front End (UI)](https://hub.docker.com/r/dependencytrack/frontend) Docker Hub
      > The official docker container.

##### 1.1.2.2. Role

1. Examples and Explantions

    - Playbook
      > Add a Role using Fully Qualified Domain Name (FQDN).

      ```yaml
      ---
      - name: Component Analysis
        hosts: component_analysis
        become: true
        roles:
          - role: component_analysis.dependency_track.frontend
      ```

## 2. Plugins

### 2.1. Module

### 2.2. Install and Uninstall

> NOTE The collection is tested and supported with `ansible >=2.12.0`.

1. Install
    > Install a collection from a private repository by running `ansible-galaxy collection install <repository>` command in a terminal.

    ```bash
    ansible-galaxy collection install git@<git-repo>/sentenz.component_analysis.git
    ```

2. Update
    > Upgrade a collection from a private repository by running `ansible-galaxy collection install <repository> --upgrade` command in a terminal.

    ```bash
    ansible-galaxy collection install git@<git-repo>/sentenz.component_analysis.git --upgrade
    ```

3. Uninstall
    > Remove a collection from the filesystem by running `rm -rf <path>/<namespace>/<collection>` command in a terminal.

    ```bash
    rm -rf ~/.ansible/collections/ansible_collections/sentenz/dependency_track
    rm -rf ./venv/lib/python3.9/site-packages/ansible_collections/sentenz/dependency_track
    ```

### 2.3. Examples and Explanations

1. Plugins
    > Call the modules by the Fully Qualified Collection Name (FQCN) `<namespace>.<collection>.<module>` or using the `collections` keyword.

    ```yml
    ---
    - name: Uploud SBOM to Dependency-Track
      hosts: localhost
      gather_facts: false

      tasks:
        - name: Create SBOM
          sentenz.component_analysis.sbom_create:
            base_url: "{{ base_url }}"
            api_key: "{{ api_key }}"
            sbom_file_path: "{{ sbom_file_path }}"
            project_name: "{{ project_name }}"
            project_version: "{{ project_version }}"
    ```

    ```bash
    ansible-playbook -i inventory.ini site.yml -e "base_url=$URL api_key=$API_KEY sbom_file_path=$BOM_FILE project_name=$PROJECT_NAME project_version=$PROJECT_VERSION"
    ```
