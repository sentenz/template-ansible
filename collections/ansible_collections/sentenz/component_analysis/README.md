# Ansible Collection for Component Analysis

The Ansible Collection for Component Analysis contains modules and roles to assist in automating the management of resources in OWASP Dependency-Track with Ansible.

- [Ansible Collection for Component Analysis](#ansible-collection-for-component-analysis)
  - [1. Usage](#1-usage)
    - [1.1. Identity and Access](#11-identity-and-access)
    - [1.2. Install and Uninstall](#12-install-and-uninstall)
    - [1.3. Examples and Explanations](#13-examples-and-explanations)
    - [1.4. Commands and Operations](#14-commands-and-operations)
  - [2. Contributing](#2-contributing)

## 1. Usage

### 1.1. Identity and Access

1. SSH Authentication
    > Connecting to the Repository with Secure Shell (SSH) protocol provides a secure channel over an unsecured network.

    - Private Key
      > Private Key must be kept secret and secure on the local machine. The `~/.ssh/config` file is a user-specific configuration file for SSH (Secure Shell) clients. The `IdentityFile` keyword specifies the private key file to use for that specific connection. An SSH connection to a server can be made by issuing the command `ssh gitlab` which corresponds to a host entry in the `~/.ssh/config` file.

      ```plaintext
      Host gitlab
          User git
          HostName <public_ip/public_dns>
          IdentityFile ~/.ssh/gitlab
      ```

    - Public Key
      > An SSH public key is part of a key pair. Share the public key, e.g. `~/.ssh/gitlab.pub` within the GitLab account in `Preferences > SSH Keys` by configuring `Add new key`.

### 1.2. Install and Uninstall

> NOTE The collection is tested and supported with `ansible >=2.12.0`.

1. Install
    > Install a collection from a private repository by running `ansible-galaxy collection install <repository>` command in a terminal.

    ```bash
    ansible-galaxy collection install git@github/sentenz/sentenz.component_analysis.git
    ```

2. Update
    > Upgrade a collection from a private repository by running `ansible-galaxy collection install <repository> --upgrade` command in a terminal.

    ```bash
    ansible-galaxy collection install git@github/sentenz/sentenz.component_analysis.git --upgrade
    ```

3. Uninstall
    > Remove a collection from the filesystem by running `rm -rf <path>/<namespace>/<collection>` command in a terminal.

    ```bash
    rm -rf ~/.ansible/collections/ansible_collections/sentenz/dependency_track
    rm -rf ./venv/lib/python3.9/site-packages/ansible_collections/sentenz/dependency_track
    ```

### 1.3. Examples and Explanations

1. Roles
    > Call the roles by the Fully Qualified Collection Name (FQCN) `<namespace>.<collection>.<module>` or using the `collections` keyword.

    ```yml
    ---
    - name: Deploy Dependency-Track
      hosts: host
      become: true

      roles:
        - role: sentenz.component_analysis.dependency_track
    ```

    ```bash
    ansible-playbook -i inventory.ini site.yml
    ```

2. Plugins
    > Call the modules by the Fully Qualified Collection Name (FQCN) `<namespace>.<collection>.<module>` or using the `collections` keyword.

    ```yml
    ---
    - name: Uploud BOM to Dependency-Track
      hosts: localhost
      gather_facts: false

      tasks:
        - name: Create BOM
          sentenz.component_analysis.bom_create:
            base_url: "{{ base_url }}"
            api_key: "{{ api_key }}"
            sbom_file_path: "{{ sbom_file_path }}"
            project_name: "{{ project_name }}"
            project_version: "{{ project_version }}"
    ```

    ```bash
    ansible-playbook -i inventory.ini site.yml -e "base_url=$URL api_key=$API_KEY sbom_file_path=$BOM_FILE project_name=$PROJECT_NAME project_version=$PROJECT_VERSION"
    ```

### 1.4. Commands and Operations

1. Tasks

    - [Makefile](Makefile)
      > Refer to the Makefile as the central task file. Use the command line `make help` in the terminal to list the tasks used for the project.

      ```plaintext
      $ make help

      TASK
              A centralized collection of commands and operations used in this project.

      USAGE
              make [target]

              setup                        Setup the Software Development environment
      ```

## 2. Contributing

Clone the collection into the configured [COLLECTIONS_PATHS](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#collections-paths) based on the `collections/ansible_collections` keywords and the Fully Qualified Collection Name (FQCN) `<namespace>.<collection>` configured in [galaxy.yml](galaxy.yml).

```palintext
~/collections/ansible_collections/<namespace>/<collection>
```
