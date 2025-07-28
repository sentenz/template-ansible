# Ansible

> [!NOTE]
> In Ansible, variables are the foundation for customizing and controlling the behavior of automation tasks. Understanding the `scopes`, `levels`, and `precedence` of variables is crucial for writing effective playbooks and roles.

> [!IMPORTANT]
> Create unique **task/handler names** within their scope (e.g., role or playbook) to prevent unexpected behavior in Ansible. Duplicate names in the same scope will silently overwrite earlier definitions, which can lead to unintended consequences, especially with handlers (e.g., service restarts).

- [1. Usage](#1-usage)
  - [1.1. Identity and Access](#11-identity-and-access)
    - [1.1.1. SSH Authentication](#111-ssh-authentication)
    - [1.1.2. CA Signed Certificate from CSR Certificate](#112-ca-signed-certificate-from-csr-certificate)
  - [1.2. Task Runner](#12-task-runner)

## 1. Usage

### 1.1. Identity and Access

#### 1.1.1. SSH Authentication

SSH is used to securely connect to AWS EC2 instances for provisioning and management via Ansible. Proper configuration ensures secure and streamlined automation.

> [!NOTE]
> 

1. SSH Key Pair

    Generate an SSH Key Pair.

    ```bash
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws
    ```

    Create dedicated SSH Key Pairs for dev and prod to enforce isolation.

    ```bash
    # For Development
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-dev

    # For Production
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-prod
    ```

    - Private Key
      > SSH keys are used to securely connect to EC2 instances. Private Key must be kept secret and secure on the local machine.

      > [!NOTE]
      > Set strict permissions for Private Key security utilizing `chmod 600 ~/.ssh/aws-prod`.

    - Public Key
      > An SSH public key is part of a key pair. Share the public key with the server to be connected.

2. Ansible Integration

    Reference the SSH private key in Ansible `ansible.cfg` configuration file for Ansible provisioning.

    - `ansible.cfg`
      > Add the private key path to `ansible.cfg` to automate authentication

      ```ini
      [defaults]
      inventory = ./inventory
      private_key_file = ~/.ssh/aws
      ```

    For multi-environment organize inventory to separate dev/prod hosts.

    - `inventory/dev/group_vars/all.yml`

      ```yaml
      ansible_ssh_private_key_file: ~/.ssh/aws-dev
      ```

    - `inventory/prod/group_vars/all.yml`

      ```yaml
      ansible_ssh_private_key_file: ~/.ssh/aws-prod
      ```

#### 1.1.2. CA Signed Certificate from CSR Certificate

TODO

### 1.2. Task Runner

- [Makefile](Makefile)
  > Refer to the Makefile as the Task Runner file.

  > [!NOTE]
  > Run the `make help` command in the terminal to list the tasks used for the project.

  ```plaintext
  $ make help

  Task Runner
          A collection of tasks used in the current project.

  Usage
          make <task>

          bootstrap                   Initialize a software development workspace with requisites
          setup                       Install and configure all dependencies essential for development
          teardown                    Remove development artifacts and restore the host to its pre-setup state
          ansible-deploy              Deploy the Ansible configuration to the target environment
          ansible-destroy             Destroy the Ansible configuration on the target environment
          ansible-restart             Restart the Ansible configuration on the target environment
          ansible-stop                Stop the Ansible configuration on the target environment
  ```
