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

## Install and configure all dependencies essential for development
setup:
	cd $(@D)/scripts && ./setup.sh
.PHONY: setup

## Setup the Software Analysis environment
setup-analysis:
	cd $(@D)/scripts && ./setup_analysis.sh
.PHONY: setup-analysis

## Setup the Software Testing environment
setup-testing:
	cd $(@D)/scripts && ./setup_testing.sh
.PHONY: setup-testing

## Perform the Static Analysis of Ansible configuration
lint-ansible:
	ansible-lint .
	ansible-later **/*.yml
.PHONY: lint-ansible

## Perform the Static Analysis of Python scripts
lint-python:
	pylint --recursive=y $(@D)
	black $(@D)
.PHONY: lint-python

## Perform the Sanity Tests against Ansible Collection
test-sanity:
	ansible-test sanity --docker default --python 3.8
	# ansible-test sanity --docker default --test pep8 --python 3.10
.PHONY: test-sanity

## Perform the Unit Tests against Ansible Collection
test-unit:
	ansible-test units --docker default --python 3.10
.PHONY: test-unit

## Perform the Integration Tests against Ansible Collection
test-integration:
	ansible-test integration --docker default --python 3.10
.PHONY: test-integration

## Perform the Code Coverage of Ansible Collection
test-coverage:
	ansible-test units --coverage --docker default --python 3.10
	ansible-test coverage html
	ansible-test coverage report
.PHONY: test-coverage

## Perform install Role and Collection of Ansible Galaxy
galaxy-install:
	ansible-galaxy collection install git@<git-repo>/sentenz.component_analysis.git --upgrade
.PHONY: galaxy-install

## Perform upgrade Role and Collection of Ansible Galaxy
galaxy-update: galaxy-install
.PHONY: galaxy-update

## Perform removel Role and Collection of Ansible Galaxy
galaxy-uninstall:
	rm -rf ~/.ansible/collections/ansible_collections/sentenz/dependency_track
.PHONY: galaxy-uninstall

## Workflow of the Software Analysis process
workflow-analysis:
	$(MAKE) setup-analysis
	$(MAKE) lint-ansible
	$(MAKE) lint-python
.PHONY: workflow-analysis

## Workflow of the Software Testing process
workflow-testing:
	$(MAKE) setup-testing
	$(MAKE) test-sanity
	$(MAKE) test-unit
	$(MAKE) test-integration
	$(MAKE) test-coverage
.PHONY: workflow-testing

## OpenAPI defination to upload SBOM to Dependency-Track API server
api-upload-sbom:
	curl -X POST \
    '$(DTRACK_BASE_URL)/api/v1/bom' \
    -H 'X-Api-Key: $(DTRACK_API_KEY)' \
    -H 'Content-Type: multipart/form-data' \
    -F 'autoCreate=true' \
    -F 'projectName=Test' \
    -F 'projectVersion=1.0.0' \
    -F 'bom=@examples/plugins/sbom.cdx.json'
    # -F 'project=$(DTRACK_API_PROJECT)'
.PHONY: api-upload-sbom

## OpenAPI defination to upload SBOM to Dependency-Track API server
api-get-sbom:
	curl -X GET \
  '$(DTRACK_BASE_URL)/v1/bom/cyclonedx/project/$(DTRACK_API_PROJECT)' \
  -H 'X-Api-Key: $(DTRACK_API_KEY)' \
  -H 'Accept: application/vnd.cyclonedx+json'
.PHONY: api-get-sbom

## OpenAPI defination to upload SBOM to Dependency-Track API server
api-delete-project:
	curl -X DELETE \
  '$(DTRACK_BASE_URL)/v1/project/$(DTRACK_API_PROJECT)' \
  -H 'X-Api-Key: $(DTRACK_API_KEY)'
.PHONY: api-delete-project

## Open AWS EC2 Instance in the terminal
aws-terminal:
	ssh aws_ec2
.PHONY: aws-terminal
