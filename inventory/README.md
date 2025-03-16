# Inventory

- [1. inventory/](#1-inventory)
  - [1.1. hosts](#11-hosts)
  - [1.2. group\_vars/](#12-group_vars)
  - [1.3. host\_vars/](#13-host_vars)

## 1. inventory/

Contains the inventory files that define the hosts and groups of hosts that Ansible will manage.

> [!NOTE]
> Ansible applies variable precedence in `inventory/` in the order of `host_vars/` > `group_vars/` > `inventory file (hosts)` > `role defaults`.

- `inventory/`
  > Directory structure for inventory files.

  ```plaintext
  inventory/
  ├── hosts
  ├── group_vars/
  │   ├── all.yml
  │   └── observability.yml
  └── host_vars/
      ├── prometheus01.example.com.yml
      └── grafana01.example.com.yml
  ```

### 1.1. hosts

The primary inventory file that Ansible uses to determine which hosts to manage. It defines hostnames or IP addresses and groups.

### 1.2. group_vars/

Stores variables that apply to specific groups of hosts defined in the inventory. This allows for common configuration settings to be applied uniformly across all hosts within a particular group, simplifying management and ensuring consistency.

> [!NOTE]
> Files within the `group_vars/` directory must match the group name specified in the inventory `hosts` file. The special `all` group applies variables to every host.

1. Examples and Explanations

    - `hosts`
      > Groups in inventory file that variables will apply to.

      ```yml
      observability:
        hosts:
          prometheus01.example.com:
          grafana01.example.com:
      ```

    - `group_vars/`
      > The corresponding files under `group_vars/` would match the group names.

      ```plaintext
      group_vars/
      ├── all.yml
      └── observability.yml
      ```

### 1.3. host_vars/

Defines unique settings for individual hosts without cluttering group-wide configurations. Enables flexible handling of exceptions or customizations per host without affecting broader group-level configurations.

> [!NOTE]
> Files within the `host_vars/` directory must exactly match the hostname or FQDN (fully qualified domain name) specified in the inventory `hosts` file.

1. Examples and Explanations

    - `hosts`
      > Hosts in inventory file that variables will apply to.

      ```yml
      observability:
        hosts:
          prometheus01.example.com:
          grafana01.example.com:
      ```

    - `host_vars/`
      > The corresponding files under `host_vars/` would precisely match the hostnames.

      > [!NOTE]
      > Ansible looks up variables by matching the filename directly to the hostname. Minor deviations such as uppercase letters, trailing spaces, or different extensions will cause the file not to be recognized.

      ```plaintext
      host_vars/
      ├── prometheus01.example.com.yml
      └── grafana01.example.com.yml
      ```
