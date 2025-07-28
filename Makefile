# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Variables

SHELL = /bin/bash
SHELL_CMD = source
SHELL_PATH = scripts/shell
SHELL_FILE_CLI = ${SHELL_PATH}/cli.sh
SHELL_FILE_FORMAT = ${SHELL_PATH}/format.sh

# Define Targets

default: help

help:
	@awk 'BEGIN {printf "Task\n\tA collection of tasks used in the current project.\n\n"}'
	@awk 'BEGIN {printf "Usage\n\tmake $(shell tput -Txterm setaf 6)<task>$(shell tput -Txterm sgr0)\n\n"}' $(MAKEFILE_LIST)
	@awk '/^##/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print "$(shell tput -Txterm setaf 6)\t" substr($$1,1,index($$1,":")) "$(shell tput -Txterm sgr0)",c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
.PHONY: help

# Prompt for credentials and cache them for the current session
permission:
	@sudo -v
.PHONY: permission

## Initialize a software development workspace with requisites
bootstrap:
	@$(MAKE) -s permission
	cd $(@D)/scripts && chmod +x bootstrap.sh && ./bootstrap.sh
.PHONY: bootstrap

## Install and configure all dependencies essential for development
setup:
	@$(MAKE) -s permission
	cd $(@D)/scripts && chmod +x setup.sh && ./setup.sh
.PHONY: setup

## Remove development artifacts and restore the host to its pre-setup state
teardown:
	@$(MAKE) -s permission
	cd $(@D)/scripts && chmod +x teardown.sh && ./teardown.sh
.PHONY: teardown

## Perform install Role and Collection of Ansible Galaxy
ansible-galaxy-install:
	find . -name "requirements.yml" -exec ansible-galaxy install --force -r {} \;
.PHONY: ansible-galaxy-install

## Perform upgrade Role and Collection of Ansible Galaxy
ansible-galaxy-update: ansible-galaxy-install
.PHONY: ansible-galaxy-update

## Perform removel Role and Collection of Ansible Galaxy
ansible-galaxy-uninstall:
	rm -rf ~/.ansible/collections/ansible_collections/
.PHONY: ansible-galaxy-uninstall

## Perform the Static Analysis of Ansible configuration
ansible-lint:
	$(SHELL_CMD) $(SHELL_FILE_CLI) && $(SHELL_CMD) $(SHELL_FILE_FORMAT) && cli_ansible_lint | format_gitlab_ansible_lint
.PHONY: ansible-lint

## Deploy the Ansible configuration to the target environment
ansible-deploy:
	ansible-playbook -i inventory/$(ENV)/hosts.yml site.yml --ask-become-pass --skip-tags restart,stop,destroy --vault-password-file "./vault/$(ENV).vault_pass"
.PHONY: ansible-deploy

## Destroy the Ansible configuration on the target environment
ansible-destroy:
	ansible-playbook -i inventory/$(ENV)/hosts.yml site.yml --ask-become-pass --tags destroy --vault-password-file "./vault/$(ENV).vault_pass"
.PHONY: ansible-destroy

## Restart the Ansible configuration on the target environment
ansible-restart:
	ansible-playbook -i inventory/$(ENV)/hosts.yml site.yml --ask-become-pass --tags restart --vault-password-file "./vault/$(ENV).vault_pass"
.PHONY: ansible-restart

## Stop the Ansible configuration on the target environment
ansible-stop:
	ansible-playbook -i inventory/$(ENV)/hosts.yml site.yml --ask-become-pass --tags stop --vault-password-file "./vault/$(ENV).vault_pass"
.PHONY: ansible-stop

# Usage: make ansible-vault-encrypt <file>
#
## Create Ansible vault encrypted file
ansible-vault-encrypt:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make ansible-vault-encrypt <file>"; \
		exit 1; \
	fi
	ansible-vault encrypt --vault-password-file="./vault/$(ENV).vault_pass" "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: ansible-vault-encrypt

# Usage: make ansible-vault-decrypt <file>
#
## Decrypt Ansible vault encrypted file
ansible-vault-decrypt:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make ansible-vault-encrypt <file>"; \
		exit 1; \
	fi
	ansible-vault decrypt --vault-password-file="./vault/$(ENV).vault_pass" "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: ansible-vault-decrypt

# Usage: make ansible-vault-view <file>
#
## View Ansible vault encrypted file
ansible-vault-view:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make ansible-vault-view <file>"; \
		exit 1; \
	fi
	ansible-vault view --vault-password-file="./vault/$(ENV).vault_pass" "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: ansible-vault-view

## Open AWS EC2 Instance in the terminal
aws-terminal:
	ssh aws-$(ENV)
.PHONY: aws-terminal
