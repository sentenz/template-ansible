# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

SHELL = /bin/bash
SHELL_CMD = source
SHELL_PATH = scripts/shell
SHELL_FILE_CLI = ${SHELL_PATH}/cli.sh
SHELL_FILE_FORMAT = ${SHELL_PATH}/format.sh

# Define Targets

default: help

help:
	@awk 'BEGIN {printf "TASK\n\tA collection of task runner used in this project.\n\n"}'
	@awk 'BEGIN {printf "USAGE\n\tmake $(shell tput -Txterm setaf 6)[target]$(shell tput -Txterm sgr0)\n\n"}' $(MAKEFILE_LIST)
	@awk '/^##/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print "$(shell tput -Txterm setaf 6)\t" substr($$1,1,index($$1,":")) "$(shell tput -Txterm sgr0)",c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
.PHONY: help

## Bootstrap the Software Development environment
bootstrap:
	cd $(@D)/scripts && chmod +x bootstrap.sh && ./bootstrap.sh
.PHONY: bootstrap

## Setup the Software Development environment
setup:
	cd $(@D)/scripts && chmod +x setup.sh && ./setup.sh
.PHONY: setup

## Teardown the Software Development environment
teardown:
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
## Create vault encrypted file
ansible-vault-encrypt:
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" != "" ]; then \
		ansible-vault encrypt --vault-password-file="./vault/$(ENV).vault_pass" "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		echo "Usage: make ansible-vault-encrypt <file>"; \
		exit 1; \
	fi
.PHONY: ansible-vault-encrypt

# Usage: make ansible-vault-decrypt <file>
#
## Decrypt Ansible vault encrypted file
ansible-vault-decrypt:
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" != "" ]; then \
		ansible-vault decrypt --vault-password-file="./vault/$(ENV).vault_pass" "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		echo "Usage: make ansible-vault-encrypt <file>"; \
		exit 1; \
	fi
.PHONY: ansible-vault-decrypt

# Usage: make ansible-vault-view <file>
#
## View the Ansible Vault
ansible-vault-view:
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" != "" ]; then \
		ansible-vault view --vault-password-file="./vault/$(ENV).vault_pass" "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		echo "Usage: make ansible-vault-view <file>"; \
		exit 1; \
	fi
.PHONY: ansible-vault-view

## Open AWS EC2 Instance in the terminal
aws-terminal:
	ssh aws
.PHONY: aws-terminal
