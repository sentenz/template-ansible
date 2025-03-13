# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Targets

default: help

help:
	@awk 'BEGIN {printf "TASK\n\tA collection of task runner used in this project.\n\n"}'
	@awk 'BEGIN {printf "USAGE\n\tmake $(shell tput -Txterm setaf 6)[target]$(shell tput -Txterm sgr0)\n\n"}' $(MAKEFILE_LIST)
	@awk '/^##/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print "$(shell tput -Txterm setaf 6)\t" substr($$1,1,index($$1,":")) "$(shell tput -Txterm sgr0)",c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
.PHONY: help

## Setup the Software Development environment
setup-ubuntu:
	apt update
	apt install software-properties-common
	add-apt-repository --yes --update ppa:ansible/ansible
	apt install -y ansible
.PHONY: setup-ubuntu

## Setup the Software Development environment
setup-alpine:
	apk add ansible
.PHONY: setup-alpine

## Setup the linting tools
setup-lint:
	pip3 install ansible-lint==24.12.2 --break-system-packages
.PHONY: setup-lint

## Perform install Role and Collection of Ansible Galaxy
galaxy-install:
	find . -name "requirements.yml" -exec ansible-galaxy install --force -r {} \;
.PHONY: galaxy-install

## Perform upgrade Role and Collection of Ansible Galaxy
galaxy-update: galaxy-install
.PHONY: galaxy-update

## Perform removel Role and Collection of Ansible Galaxy
galaxy-uninstall:
	rm -rf ~/.ansible/collections/ansible_collections/
.PHONY: galaxy-uninstall

## Perform the Static Analysis of Ansible configuration
ansible-lint:
	ansible-lint --fix ./
	ansible-lint --fix ./inventory/
	ansible-lint --fix ./playbooks/
	ansible-lint --fix ./collections/ansible_collections/sentenz/component_analysis/
	ansible-lint --fix ./collections/ansible_collections/sentenz/observability/
	ansible-lint --fix ./collections/ansible_collections/sentenz/reverse_proxy/

	# ansible-later **/*.yml
.PHONY: ansible-lint

## Deploy the Ansible configuration to the target environment
ansible-deploy:
	ansible-playbook -i inventory/$(ENV)/hosts site.yml --ask-become-pass --skip-tags restart,stop,destroy --vault-password-file "./vault_passwords/$(ENV).vault"
.PHONY: ansible-deploy

## Destroy the Ansible configuration on the target environment
ansible-destroy:
	ansible-playbook -i inventory/$(ENV)/hosts site.yml --ask-become-pass --tags destroy
.PHONY: ansible-destroy

## Restart the Ansible configuration on the target environment
ansible-restart:
	ansible-playbook -i inventory/$(ENV)/hosts site.yml --ask-become-pass --tags restart
.PHONY: ansible-restart

## Stop the Ansible configuration on the target environment
ansible-stop:
	ansible-playbook -i inventory/$(ENV)/hosts site.yml --ask-become-pass --tags stop
.PHONY: ansible-stop

# Usage: make ansible-vault-encrypt <file>
#
## Encrypt the Ansible Vault
ansible-vault-encrypt:
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" != "" ]; then \
		ansible-vault encrypt --vault-password-file="./vault_passwords/$(ENV).vault" "$(filter-out $@,$(MAKECMDGOALS))"; \
	else \
		echo "Usage: make ansible-vault-encrypt <file>"; \
		exit 1; \
	fi
.PHONY: ansible-vault-encrypt

# Usage: make ansible-vault-decrypt <file>
#
## Decrypt the Ansible Vault
ansible-vault-decrypt:
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" != "" ]; then \
		ansible-vault decrypt --vault-password-file="./vault_passwords/$(ENV).vault" "$(filter-out $@,$(MAKECMDGOALS))"; \
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
		ansible-vault view --vault-password-file="./vault_passwords/$(ENV).vault" "$(filter-out $@,$(MAKECMDGOALS))"; \
    else \
		echo "make ansible-vault-view <file>"; \
		exit 1; \
    fi
.PHONY: ansible-vault-view

## Open AWS EC2 Instance in the terminal
aws-terminal:
	ssh aws
.PHONY: aws-terminal
