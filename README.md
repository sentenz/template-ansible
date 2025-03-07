# Ansible

> [!NOTE]
> In Ansible, variables are the foundation for customizing and controlling the behavior of automation tasks. Understanding the `scopes`, `levels`, and `precedence` of variables is crucial for writing effective playbooks and roles.

- [1. Usage](#1-usage)
  - [1.1. Task Runner](#11-task-runner)

## 1. Usage

### 1.1. Task Runner

- [Makefile](Makefile)
  > Refer to the Makefile as the Task Runner file.

  > [!NOTE]
  > Run the `make help` command in the terminal to list the tasks used for the project.

  ```plaintext
  $ make help

  TASK
          A collection of tasks used for the project.

  USAGE
          make [target]

  TARGET
          setup                  Setup the environment
          teardown               Clean up the environment
  ```
