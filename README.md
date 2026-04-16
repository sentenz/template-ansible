# Ansible

- [1. Details](#1-details)
- [2. Usage](#2-usage)
  - [2.1. Authentication](#21-authentication)
    - [2.1.1. SSH Key Pair](#211-ssh-key-pair)
  - [2.2. Cryptographic](#22-cryptographic)
    - [2.2.1. TLS Certificates and Private Keys](#221-tls-certificates-and-private-keys)
    - [2.2.2. CA-Signed Certificates from CSRs](#222-ca-signed-certificates-from-csrs)
- [3. Contribute](#3-contribute)
  - [3.1. Secrets Manager](#31-secrets-manager)
    - [3.1.1. Ansible Vault](#311-ansible-vault)
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

[CONTRIBUTING.md](CONTRIBUTING.md) provides guidens and instructions for contributing to the project.

- [AI Agents](CONTRIBUTING.md#1-ai-agents)
  > Automated tools that assist in various development tasks such as code generation, testing, and documentation.

- [Skills Manager](CONTRIBUTING.md#2-skills-manager)
  > CLI tool for managing AI agent skills in development projects.

- [Task Runner](CONTRIBUTING.md#3-task-runner)
  > Make automation tool that defines and manages tasks to streamline development workflows.

- [Bootstrap](CONTRIBUTING.md#4-bootstrap)
  > Scripts to bootstrap, setup, and teardown a software development workspace with requisites.

- [Release Manager](CONTRIBUTING.md#6-release-manager)
  > Semantic-Release automates the release process by analyzing commit messages.

- [Update Manager](CONTRIBUTING.md#7-update-manager)
  > Renovate and Dependabot automate dependency updates by creating pull requests.

- [Container Manager](CONTRIBUTING.md#9-container-manager)
  > Docker containerization tool to run applications in isolated container environments.

- [Policy Manager](CONTRIBUTING.md#10-policy-manager)
  > Conftest for policy-as-code enforcement.

- [Supply Chain Manager](CONTRIBUTING.md#11-supply-chain-manager)
  > Trivy for security scanning of vulnerabilities, misconfigurations, and compliance issues.

### 3.1. Secrets Manager

#### 3.1.1. Ansible Vault

[Ansible Vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html) is a built-in feature of Ansible to encrypt sensitive data and secrets within Ansible playbooks and roles.

1. Insights and Details

    - `ansible-vault`
      > Command-line tool to create, edit, encrypt, decrypt, and view vaulted files.

    - [ansible.cfg](ansible.cfg)
      > Configure a vault password file for automation (ensure file is protected).

        ```ini
        [defaults]
        inventory = ./inventory
        vault_password_file = ./vault/.vault_pass
        ```

2. Usage and Instructions

    - Create Vaulted Files

      - Tasks
        > Create a new encrypted file interactively.

        ```bash
        ansible-vault create secrets.yml
        ```

    - Edit Vaulted Files
      > Edit an existing vaulted file interactively.

        ```bash
        ansible-vault edit secrets.yml
        ```

    - Encrypt/Decrypt Vaulted Files
      > Encrypt or decrypt existing files interactively.

        ```bash
        ansible-vault encrypt group_vars/all/vault.yml
        ansible-vault decrypt group_vars/all/vault.yml
        ```

      - Tasks
        > View the content of a vaulted file without decrypting it.

        ```bash
        make ansible-vault-view <file>
        ```

        ```bash
        ansible-vault view group_vars/all/vault.yml
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

## 4. Troubleshoot

### 4.1. TODO

TODO

## 5. References

- Sentenz [Template DX](https://github.com/sentenz/template-dx) repository.
- Sentenz [Actions](https://github.com/sentenz/actions) repository.
- Sentenz [Manager Tools](https://github.com/sentenz/convention/issues/392) article.
