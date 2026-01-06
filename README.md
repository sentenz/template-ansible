# Ansible

- [1. Details](#1-details)
- [2. Usage](#2-usage)
  - [2.1. Authentication](#21-authentication)
    - [2.1.1. SSH Key Pair](#211-ssh-key-pair)
  - [2.2. Cryptographic](#22-cryptographic)
    - [2.2.1. TLS Certificates and Private Keys](#221-tls-certificates-and-private-keys)
    - [2.2.2. CA-Signed Certificates from CSRs](#222-ca-signed-certificates-from-csrs)
- [3. Contribute](#3-contribute)
  - [3.1. Task Runner](#31-task-runner)
    - [3.1.1. Make](#311-make)
  - [3.2. Bootstrap](#32-bootstrap)
    - [3.2.1. Scripts](#321-scripts)
  - [3.3. Dev Containers](#33-dev-containers)
  - [3.4. Release Manager](#34-release-manager)
    - [3.4.1. Semantic-Release](#341-semantic-release)
  - [3.5. Update Manager](#35-update-manager)
    - [3.5.1. Renovate](#351-renovate)
    - [3.5.2. Dependabot](#352-dependabot)
  - [3.6. Secrets Manager](#36-secrets-manager)
    - [3.6.1. Ansible Vault](#361-ansible-vault)
  - [3.7. Container Manager](#37-container-manager)
    - [3.7.1. Docker](#371-docker)
  - [3.8. Policy Manager](#38-policy-manager)
    - [3.8.1. Conftest](#381-conftest)
  - [3.9. Supply Chain Manager](#39-supply-chain-manager)
    - [3.9.1. Trivy](#391-trivy)
- [4. Troubleshoot](#4-troubleshoot)
  - [4.1. TODO](#41-todo)
- [5. References](#5-references)

## 1. Details

> [!NOTE]
> In Ansible, variables are the foundation for customizing and controlling the behavior of automation tasks. Understanding the `scopes`, `levels`, and `precedence` of variables is crucial for writing effective playbooks and roles.

> [!TIP]
> Create unique **task/handler** names within their scope (e.g., role or playbook) to prevent unexpected behavior in Ansible. Duplicate names in the same scope will silently overwrite earlier definitions, which can lead to unintended consequences, especially with handlers (e.g., service restarts).

## 2. Usage

### 2.1. Authentication

#### 2.1.1. SSH Key Pair

Ansible uses SSH (Secure Shell) to connect to remote hosts for executing commands, copying files, or applying configurations. SSH key pairs (private key and public key) for non-interactive, secure, and auditable authentication.

> [!IMPORTANT]
> Store and retrieve the SSH Key Pair files from a Secrets Manager (Vaultwarden). Place the SSH Key Pair files in the `~/.ssh/` directory.

> [!TIP]
> File and directory permissions are critical. Set strict permissions for the `~/.ssh` directory to `700` and for files such as private keys and configuration files to `600`. Utilize Linux command `chmod 600 ~/.ssh/<private-key>`.

1. SSH Key Pair Generation

    - Generate an SSH Key Pair.

      ```bash
      ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws
      ```

    - Alternative, generate dedicated SSH Key Pairs for `stage` and `prod` to enforce isolation.

      ```bash
      # For Staging
      ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-stage

      # For Production
      ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-prod
      ```

2. SSH Key Pair Distribution

    - SSH Public Key
      > The SSH public key is shared with any remote machines (e.g. AWS EC2 instances) to connect to.

    - SSH Private Key
      > Ansible uses SSH private keys to securely proof the identity of the remote machines, such as AWS EC2 instances. The private key must be kept secret and secure, either locally or in a Secrets Manager.

3. SSH Client Configuration

    Configure `~/.ssh/config` to simplify SSH connections.

    > [!NOTE]
    > SSH connection for accessing AWS EC2 instances is not required if Ansible is used for automation. However, it can be useful for troubleshoot or maintenance purpose.

    - `files/.ssh/config`
      > The SSH client configuration file is typically located at `~/.ssh/config`. Specify an alternative location for an SSH configuration file using the `-F <path>` option with the ssh client, e.g. `ssh aws-dev -F files/.ssh/config`.

      ```plaintext
      Host aws-dev                       # Friendly name for the connection
        User         ec2-user            # Default user for Amazon Linux
        HostName     <PUBLIC_IP_OR_DNS>  # EC2 instance public IP/DNS after deployment
        IdentityFile ~/.ssh/aws-dev      # Path to private key
        Port         22                  # Optional: Specify the SSH port if not default (22)
        StrictHostKeyChecking no         # Optional: Disable host key prompts

      Host aws-prod                      # Friendly name for the connection
        User         ec2-user            # Default user for Amazon Linux
        HostName     <PUBLIC_IP_OR_DNS>  # EC2 instance public IP/DNS after deployment
        IdentityFile ~/.ssh/aws-prod     # Path to private key
        Port         22                  # Optional: Specify the SSH port if not default (22)
        StrictHostKeyChecking no         # Optional: Disable host key prompts
      ```

4. Ansible Integration

    - Reference the SSH private key in Ansible `ansible.cfg` configuration file for Ansible provisioning.

      - `ansible.cfg`
        > Add the private key path to `ansible.cfg` to automate authentication

        ```ini
        [defaults]
        inventory = ./inventory
        private_key_file = ~/.ssh/aws
        ```

    - For multi-environment organize inventory to separate `stage` and `prod` hosts.

      - `inventory/stage/host_vars/<host>.yml`

        ```yaml
        ansible_ssh_private_key_file: ~/.ssh/aws-stage
        ```

      - `inventory/prod/host_vars/<host>.yml`

        ```yaml
        ansible_ssh_private_key_file: ~/.ssh/aws-prod
        ```

### 2.2. Cryptographic

#### 2.2.1. TLS Certificates and Private Keys

TODO

#### 2.2.2. CA-Signed Certificates from CSRs

TODO

## 3. Contribute

Contribution guidelines and project management tools.

### 3.1. Task Runner

#### 3.1.1. Make

[Make](https://www.gnu.org/software/make/) is a automation tool that defines and manages tasks to streamline development workflows.

1. Insights and Details

    - [Makefile](Makefile)
      > Makefile defining tasks for building, testing, and managing the project.

2. Usage and Instructions

    - Tasks

      ```bash
      make help
      ```

      > [!NOTE]
      > - Each task description must begin with `##` to be included in the task list.

      ```plaintext
      $ make help

      Tasks
              A collection of tasks used in the current project.

      Usage
              make <task>

              bootstrap         Initialize a software development workspace with requisites
              setup             Install and configure all dependencies essential for development
              teardown          Remove development artifacts and restore the host to its pre-setup state
      ```

### 3.2. Bootstrap

#### 3.2.1. Scripts

[scripts/](scripts/README.md) provides scripts to bootstrap, setup, and teardown a software development workspace with requisites.

1. Insights and Details

    - [bootstrap.sh](scripts/bootstrap.sh)
      > Initializes a software development workspace with requisites.

    - [setup.sh](scripts/setup.sh)
      > Installs and configures all dependencies essential for development.

    - [teardown.sh](scripts/teardown.sh)
      > Removes development artifacts and restores the host to its pre-setup state.

2. Usage and Instructions

    - Tasks

      ```bash
      make bootstrap
      ```

      ```bash
      make setup
      ```

      ```bash
      make teardown
      ```

### 3.3. Dev Containers

[.devcontainer/](.devcontainer/README.md) provides Dev Containers as a consistent development environment using Docker containers.

1. Insights and Details

    - [ansilbe/](.devcontainer/ansilbe/)
      > Dev Container configuration for Ansible development environment.

      ```json
      // ...
      "postCreateCommand": "sudo make bootstrap && sudo make setup",
      // ...
      ```

      > [!NOTE]
      > The `devcontainer.json` runs the `bootstrap` and `setup` tasks to initialize and configure the development environment.

2. Usage and Instructions

    - Tasks

      ```bash
      # TODO
      # make devcontainer-ansilbe
      ```

### 3.4. Release Manager

#### 3.4.1. Semantic-Release

[Semantic-Release](https://github.com/semantic-release/semantic-release) automates the release process by analyzing commit messages to determine the next version number, generating changelog and release notes, and publishing the release.

1. Insights and Details

    - [.releaserc.json](.releaserc.json)
      > Configuration file for Semantic-Release specifying release rules and plugins.

2. Usage and Instructions

    - CI/CD

      ```yaml
      uses: sentenz/actions/semantic-release@latest
      ```

### 3.5. Update Manager

#### 3.5.1. Renovate

[Renovate](https://github.com/renovatebot/renovate) automates dependency updates by creating merge requests for outdated dependencies, libraries and packages.

1. Insights and Details

    - [renovate.json](renovate.json)
      > Configuration file for Renovate specifying update rules and schedules.

2. Usage and Instructions

    - CI/CD

      ```yaml
      uses: sentenz/actions/renovate@latest
      ```

#### 3.5.2. Dependabot

[Dependabot](https://github.com/dependabot/dependabot-core) automates dependency updates by creating pull requests for outdated dependencies, libraries and packages.

1. Insights and Details

    - [.github/dependabot.yml](.github/dependabot.yml)
      > Configuration file for Dependabot specifying update rules and schedules.

### 3.6. Secrets Manager

#### 3.6.1. Ansible Vault

Ansible Vault is the built-in Ansible tool for encrypting sensitive data such as passwords, API keys, and other secrets used in playbooks and roles.

1. Insights and Details

    - `ansible-vault`
      > Native Ansible utility to create, view, edit, encrypt, decrypt and rekey vaulted files.

2. Usage and Instructions

    - Create a vaulted file

      - Tasks
        > Create a new encrypted file interactively.

        ```bash
        ansible-vault create secrets.yml
        ```

    - Edit a vaulted file

        ```bash
        ansible-vault edit secrets.yml
        ```

    - Encrypt/decrypt existing files

        ```bash
        ansible-vault encrypt group_vars/all/vault.yml
        ansible-vault decrypt group_vars/all/vault.yml
        ```

    - View vaulted content

        ```bash
        ansible-vault view secrets.yml
        ```

    - Encrypt a single variable/string

        ```bash
        ansible-vault encrypt_string 'supersecret' --name 'my_secret'
        ```

    - Re-key a vault password

        ```bash
        ansible-vault rekey group_vars/all/vault.yml
        ```

3. Integration with Ansible

    - `ansible.cfg`
      > Configure a vault password file for automation (ensure file is protected).

        ```ini
        [defaults]
        inventory = ./inventory
        vault_password_file = ./vault/.vault_pass
        ```

    - CI / Automation
      > Avoid committing plaintext vault passwords. Provide `ANSIBLE_VAULT_PASSWORD_FILE` or use an encrypted provider in CI.

4. Best Practices

    - Keep vault password files out of source control and protected with strict filesystem permissions.
    - Prefer split vault files per environment: `group_vars/stage/vault.yml`, `group_vars/prod/vault.yml`.
    - Use `ansible-vault encrypt_string` to inline secrets in role defaults/vars when needed.
    - Rotate/rekey vault passwords periodically and audit access.

5. Make targets (examples)

    - Create or edit secrets

        ```bash
        make secrets-vault-create FILE=group_vars/all/vault.yml
        make secrets-vault-edit FILE=group_vars/all/vault.yml
        ```

    - Encrypt/decrypt via Make

        ```bash
        make secrets-vault-encrypt FILE=group_vars/all/vault.yml
        make secrets-vault-decrypt FILE=group_vars/all/vault.yml
        ```

### 3.7. Container Manager

#### 3.7.1. Docker

[Docker](https://github.com/docker) containerization tool to run applications in isolated container environments and execute container-based tasks.

1. Insights and Details

    - [Dockerfile](Dockerfile)
      > Dockerfile defining the container image for the project.

2. Usage and Instructions

    - CI/CD

      ```yaml
      # TODO
      ```

    - Tasks

      ```bash
      # TODO
      ```

### 3.8. Policy Manager

#### 3.8.1. Conftest

[Conftest](https://www.conftest.dev/) is a **Policy as Code (PaC)** tool to streamline policy management for improved development, security and audit capability.

1. Insights and Details

    - [conftest.toml](conftest.toml)
      > Configuration file for Conftest specifying policy paths and output formats.

    - [tests/policy](tests/policy/)
      > Directory contains Rego policies for Conftest to enforce best practices and compliance standards.

2. Usage and Instructions

    - CI/CD

      ```yaml
      uses: sentenz/actions/regal@latest
      ```

      ```yaml
      uses: sentenz/actions/conftest@latest
      ```

    - Tasks

      ```bash
      make policy-lint-regal <filepath>
      ```

      ```bash
      make policy-analysis-conftest <filepath>
      ```

### 3.9. Supply Chain Manager

#### 3.9.1. Trivy

[Trivy](https://github.com/aquasecurity/trivy) is a comprehensive security scanner for vulnerabilities, misconfigurations, and compliance issues in container images, filesystems, and source code.

1. Insights and Details

    - [trivy.yaml](trivy.yaml)
      > Configuration file for Trivy specifying scan settings and options.

    - [.trivyignore](.trivyignore)
      > File specifying vulnerabilities to ignore during Trivy scans.

2. Usage and Instructions

    - CI/CD

      ```yaml
      uses: sentenz/actions/trivy@latest
      ```

    - Tasks

      ```bash
      make sast-trivy-fs <path>
      ```

      ```bash
      make sast-trivy-sbom-cyclonedx-fs <path>
      ```

      ```bash
      make sast-trivy-sbom-scan <sbom_path>
      ```

      ```bash
      make sast-trivy-sbom-license <sbom_path>
      ```

## 4. Troubleshoot

### 4.1. TODO

TODO

## 5. References

- Sentenz [Template DX](https://github.com/sentenz/template-dx) repository.
- Sentenz [Actions](https://github.com/sentenz/actions) repository.
- Sentenz [Manager Tools](https://github.com/sentenz/convention/issues/392) article.
