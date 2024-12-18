# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Targets

default: help

help:
	@awk 'BEGIN {printf "TASK\n\tA centralized collection of commands and operations used in this project.\n\n"}'
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
	apt update
	apt install --yes ansible-lint
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
	ansible-lint .
	# ansible-later **/*.yml
.PHONY: ansible-lint

## Provisioning of CaC to a specified environment
ansible-deploy:
	ansible-playbook -i inventory/$(ENV)/hosts site.yml --ask-become-pass --skip-tags stop,destroy
.PHONY: ansible-deploy

## Destroy of CaC to a specified environment
ansible-destroy:
	ansible-playbook -i inventory/$(ENV)/hosts site.yml --ask-become-pass --tags destroy
.PHONY: ansible-destroy

## Starting of CaC to a specified environment
ansible-start:
	# TODO
	# ansible-playbook -i inventory/$(ENV)/hosts site.yml --ask-become-pass --tags start
.PHONY: ansible-start

## Stopping of CaC to a specified environment
ansible-stop:
	ansible-playbook -i inventory/$(ENV)/hosts site.yml --ask-become-pass --tags stop
.PHONY: ansible-stop

## Open AWS EC2 Instance in the terminal
aws-terminal:
	ssh aws
.PHONY: aws-terminal
