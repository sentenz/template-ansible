# SPDX-License-Identifier: Apache-2.0

ifneq (,$(wildcard .env))
	include .env
	export
endif

# Define Variables

SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.ONESHELL:

SHELL_CMD = source
SHELL_PATH = scripts/shell
SHELL_FILE_CLI = ${SHELL_PATH}/cli.sh
SHELL_FILE_FORMAT = ${SHELL_PATH}/format.sh

# Define Targets

default: help

help:
	@awk 'BEGIN {printf "Tasks\n\tA collection of tasks used in the current project.\n\n"}'
	@awk 'BEGIN {printf "Usage\n\tmake $(shell tput -Txterm setaf 6)<task>$(shell tput -Txterm sgr0)\n\n"}' $(MAKEFILE_LIST)
	@awk '/^##/{c=substr($$0,3);next}c&&/^[[:alpha:]][[:alnum:]_-]+:/{print "$(shell tput -Txterm setaf 6)\t" substr($$1,1,index($$1,":")) "$(shell tput -Txterm sgr0)",c}1{c=0}' $(MAKEFILE_LIST) | column -s: -t
.PHONY: help

# ── Setup & Teardown ─────────────────────────────────────────────────────────────────────────────

## Initialize a software development workspace with requisites
bootstrap:
	cd $(@D)/scripts && ./bootstrap.sh
.PHONY: bootstrap

## Install and configure all dependencies essential for development
setup:
	cd $(@D)/scripts && ./setup.sh
.PHONY: setup

## Remove development artifacts and restore the host to its pre-setup state
teardown:
	cd $(@D)/scripts && ./teardown.sh
.PHONY: teardown

# ── Configuration Manager ────────────────────────────────────────────────────────────────────────

# Interactive user confirmation before proceeding with Ansible Deploy & Destroy
ansible-confirm:
	@echo ""
	@read -r -p "Confirm: Proceed with 'Ansible' in '$(ENV)'$(if $(LIMIT), targeting '$(LIMIT)',)? [yes $(ENV)/no] " confirm; \
		if [[ "$$confirm" != "yes $(ENV)" ]]; then \
			echo "Aborted."; \
			exit 1; \
		fi
.PHONY: ansible-confirm

# Usage: $(MAKE) ansible-deploy LIMIT=<hosts>
#
## Deploying Ansible configuration with optional LIMIT for a specific hosts
ansible-deploy:
	@$(MAKE) -s ansible-ssh-agent
	@$(MAKE) -s ansible-confirm
	@if [ -z "$(ANSIBLE_VAULT_PASSWORD_FILE)" ]; then \
		echo "Error: ANSIBLE_VAULT_PASSWORD_FILE is not set."; \
		exit 2; \
	fi
	ansible-playbook -i inventory/$(ENV)/hosts.yml site.yml --ask-become-pass --skip-tags restart,stop,destroy $(if $(strip $(LIMIT)),--limit $(LIMIT),)
.PHONY: ansible-deploy

## Deploy the Ansible configuration for Component Analysis
ansible-deploy-component-analysis:
	@$(MAKE) -s ansible-deploy LIMIT=component_analysis
.PHONY: ansible-deploy-component-analysis

## Deploy the Ansible configuration for Observability
ansible-deploy-observability:
	@$(MAKE) -s ansible-deploy LIMIT=observability
.PHONY: ansible-deploy-observability

# Usage: $(MAKE) ansible-destroy LIMIT=<hosts>
#
## Destroying Ansible configuration with optional LIMIT for a specific hosts
ansible-destroy:
	@$(MAKE) -s ansible-ssh-agent
	@$(MAKE) -s ansible-confirm
	@if [ -z "$(ANSIBLE_VAULT_PASSWORD_FILE)" ]; then \
		echo "Error: ANSIBLE_VAULT_PASSWORD_FILE is not set."; \
		exit 2; \
	fi
	ansible-playbook -i inventory/$(ENV)/hosts.yml site.yml --ask-become-pass --tags destroy $(if $(strip $(LIMIT)),--limit $(LIMIT),)
.PHONY: ansible-destroy

## Destroy the Ansible configuration for Component Analysis
ansible-destroy-component-analysis:
	@$(MAKE) -s ansible-destroy LIMIT=component_analysis
.PHONY: ansible-destroy-component-analysis

## Destroy the Ansible configuration for Observability
ansible-destroy-observability:
	@$(MAKE) -s ansible-destroy LIMIT=observability
.PHONY: ansible-destroy-observability

# Usage: $(MAKE) ansible-restart LIMIT=<hosts>
#
## Restarting Ansible configuration with optional LIMIT for a specific hosts
ansible-restart:
	@$(MAKE) -s ansible-ssh-agent
	@if [ -z "$(ANSIBLE_VAULT_PASSWORD_FILE)" ]; then \
		echo "Error: ANSIBLE_VAULT_PASSWORD_FILE is not set."; \
		exit 2; \
	fi
	ansible-playbook -i inventory/$(ENV)/hosts.yml site.yml --ask-become-pass --tags restart $(if $(strip $(LIMIT)),--limit $(LIMIT),)
.PHONY: ansible-restart

## Restart the Ansible configuration for Component Analysis
ansible-restart-component-analysis:
	@$(MAKE) -s ansible-restart LIMIT=component_analysis
.PHONY: ansible-restart-component-analysis

## Restart the Ansible configuration for Observability
ansible-restart-observability:
	@$(MAKE) -s ansible-restart LIMIT=observability
.PHONY: ansible-restart-observability

# Usage: $(MAKE) ansible-stop LIMIT=<hosts>
#
## Stopping Ansible configuration with optional LIMIT for a specific hosts
ansible-stop:
	@$(MAKE) -s ansible-ssh-agent
	@if [ -z "$(ANSIBLE_VAULT_PASSWORD_FILE)" ]; then \
		echo "Error: ANSIBLE_VAULT_PASSWORD_FILE is not set."; \
		exit 2; \
	fi
	ansible-playbook -i inventory/$(ENV)/hosts.yml site.yml --ask-become-pass --tags stop $(if $(strip $(LIMIT)),--limit $(LIMIT),)
.PHONY: ansible-stop

## Stop the Ansible configuration for Component Analysis
ansible-stop-component-analysis:
	@$(MAKE) -s ansible-stop LIMIT=component_analysis
.PHONY: ansible-stop-component-analysis

## Stop the Ansible configuration for Observability
ansible-stop-observability:
	@$(MAKE) -s ansible-stop LIMIT=observability
.PHONY: ansible-stop-observability

# ── Software Analysis ────────────────────────────────────────────────────────────────────────────

## Perform the Static Analysis of Ansible configuration
ansible-lint:
	$(SHELL_CMD) $(SHELL_FILE_CLI) && $(SHELL_CMD) $(SHELL_FILE_FORMAT) && cli_ansible_lint | format_gitlab_ansible_lint
.PHONY: ansible-lint

# ── Dependency Manager ───────────────────────────────────────────────────────────────────────────

## Perform install Role and Collection of Ansible Galaxy
ansible-collections-install:
	find . -name "requirements.yml" -exec ansible-galaxy install --force -r {} \;
.PHONY: ansible-collections-install

## Perform upgrade Role and Collection of Ansible Galaxy
ansible-collections-update: ansible-collections-install
.PHONY: ansible-collections-update

## Perform removel Role and Collection of Ansible Galaxy
ansible-collections-uninstall:
	rm -rf ~/.ansible/collections/ansible_collections/
.PHONY: ansible-collections-uninstall

# ── Secrets Manager ──────────────────────────────────────────────────────────────────────────────

# Usage: make ansible-vault-encrypt <file>
#
## Encrypt a file using Ansible Vault
ansible-vault-encrypt:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make ansible-vault-encrypt <file>"; \
		exit 1; \
	fi
	@if [ -z "$(ANSIBLE_VAULT_PASSWORD_FILE)" ]; then \
		echo "Error: ANSIBLE_VAULT_PASSWORD_FILE is not set."; \
		exit 2; \
	fi
	ansible-vault encrypt "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: ansible-vault-encrypt

# Usage: make ansible-vault-decrypt <file>
#
## Decrypt a file using Ansible Vault
ansible-vault-decrypt:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make ansible-vault-encrypt <file>"; \
		exit 1; \
	fi
	@if [ -z "$(ANSIBLE_VAULT_PASSWORD_FILE)" ]; then \
		echo "Error: ANSIBLE_VAULT_PASSWORD_FILE is not set."; \
		exit 2; \
	fi
	ansible-vault decrypt "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: ansible-vault-decrypt

# Usage: make ansible-vault-view <file>
#
## View a file encrypted with Ansible Vault
ansible-vault-view:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make ansible-vault-view <file>"; \
		exit 1; \
	fi
	@if [ -z "$(ANSIBLE_VAULT_PASSWORD_FILE)" ]; then \
		echo "Error: ANSIBLE_VAULT_PASSWORD_FILE is not set."; \
		exit 2; \
	fi
	ansible-vault view "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: ansible-vault-view

# ── Ansible Miscellaneous ────────────────────────────────────────────────────────────────────────

# Check if an SSH key is passphrase-protected and launch ssh-agent accordingly
ansible-ssh-agent:
	@if [ -z "$(SSH_PRIVATE_KEY_FILE)" ]; then \
		echo "Environment variable SSH_PRIVATE_KEY_FILE is not set"; \
		exit 1; \
	fi; \
	if [ ! -f "$(SSH_PRIVATE_KEY_FILE)" ]; then \
		echo "File $(SSH_PRIVATE_KEY_FILE) does not exist."; \
		exit 2; \
	fi; \
	if ssh-keygen -y -f "$(SSH_PRIVATE_KEY_FILE)" >/dev/null 2>&1; then \
		exit 0; \
	fi; \
	eval "$$(ssh-agent -s)" && ssh-add "$(SSH_PRIVATE_KEY_FILE)"
.PHONY: ansible-ssh-agent

# Usage: $(MAKE) template-aws-connect-ssh-<instance>
#
#	NOTE Optoins to connect to an AWS EC2 instance, see https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect.html
#
# Template for connecting to an AWS EC2 instance over Secure Shell (SSH)
template-aws-connect-ssh-%:
	ssh aws-$*-$(ENV) -F files/.ssh/config.vault
.PHONY: template-aws-connect-ssh-%

## Connect to an AWS EC2 instance for Component Analysis over SSH
aws-connect-ssh-component-analysis:
	@$(MAKE) template-aws-connect-ssh-component-analysis
.PHONY: aws-connect-ssh-component-analysis

# ── Policy Manager ───────────────────────────────────────────────────────────────────────────────

POLICY_IMAGE_CONFTEST ?= openpolicyagent/conftest:v0.65.0@sha256:afa510df6d4562ebe24fb3e457da6f6d6924124140a13b51b950cc6cb1d25525

# Usage: make policy-analysis-conftest <filepath>
#
## Analyze configuration files using Conftest for policy violations and generate a report
policy-analysis-conftest:
	@mkdir -p logs/policy

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make policy-analysis-conftest <filepath>"; \
		exit 1; \
	fi

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(POLICY_IMAGE_CONFTEST)" test "$(filter-out $@,$(MAKECMDGOALS))" > logs/policy/conftest.json 2>&1
.PHONY: policy-analysis-conftest

POLICY_IMAGE_REGAL ?= ghcr.io/openpolicyagent/regal:0.37.0@sha256:a09884658f3c8c9cc30de136b664b3afdb7927712927184ba891a155a9676050

# Usage: make policy-lint-regal <filepath>
#
## Lint Rego policies using Regal and generate a report
policy-lint-regal:
	@mkdir -p logs/analysis

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make policy-lint-regal"; \
		exit 1; \
	fi

	docker pull "$(POLICY_IMAGE_REGAL)"
	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(POLICY_IMAGE_REGAL)" regal lint "$(filter-out $@,$(MAKECMDGOALS))" --format json > logs/analysis/regal.json 2>&1
.PHONY: policy-lint-regal

# ── SAST Manager ─────────────────────────────────────────────────────────────────────────────────

SAST_IMAGE_TRIVY ?= aquasec/trivy:0.68.2@sha256:05d0126976bdedcd0782a0336f77832dbea1c81b9cc5e4b3a5ea5d2ec863aca7
SAST_IMAGE_COSIGN ?= cgr.dev/chainguard/cosign:3.0.0@sha256:b6bc266358e9368be1b3d01fca889b78d5ad5a47832986e14640c34a237ef638

## Scan Infrastructure-as-Code (IaC) files for misconfigurations using Trivy and generate a report
sast-trivy-misconfig:
	@mkdir -p logs/sast

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" config --output logs/sast/trivy-misconfig.json /workspace 2>&1
.PHONY: sast-trivy-misconfig

## Scan local filesystem for vulnerabilities and misconfigurations using Trivy
sast-trivy-fs:
	@mkdir -p logs/sast

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" filesystem --output logs/sast/trivy-filesystem.json /workspace 2>&1
.PHONY: sast-trivy-fs

# Usage: make sast-trivy-image <image_name>
#
## Scan a container image for vulnerabilities using Trivy
sast-trivy-image:
	@mkdir -p logs/sast

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-image <image_name>"; \
		exit 1; \
	fi

	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" image --output logs/sast/trivy-image.json "$(filter-out $@,$(MAKECMDGOALS))" 2>&1
.PHONY: sast-trivy-image

# Usage: make sast-trivy-image-license <image_name>
#
## Scan a container image for license compliance using Trivy
sast-trivy-image-license:
	@mkdir -p logs/sast

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-image-license <image_name>"; \
		exit 1; \
	fi

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" image --scanners license --format table --output logs/sast/trivy-image-license.txt "$(filter-out $@,$(MAKECMDGOALS))" 2>&1
.PHONY: sast-trivy-image-license

# Usage: make sast-trivy-repository <repo_url>
#
## Scan a remote repository for vulnerabilities using Trivy
sast-trivy-repository:
	@mkdir -p logs/sast

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-repository <repo_url>"; \
		exit 1; \
	fi

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" repository --output logs/sast/trivy-repository.json "$(filter-out $@,$(MAKECMDGOALS))" 2>&1
.PHONY: sast-trivy-repository

# Usage: make sast-trivy-rootfs <path>
#
## Scan a rootfs e.g. `/` for vulnerabilities using Trivy
sast-trivy-rootfs:
	@mkdir -p logs/sast

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-rootfs <path>"; \
		exit 1; \
	fi

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" rootfs --output logs/sast/trivy-rootfs.json "$(filter-out $@,$(MAKECMDGOALS))" 2>&1
.PHONY: sast-trivy-rootfs

# Usage: make sast-trivy-sbom-scan <sbom_path>
#
## Scan SBOM for vulnerabilities using Trivy
sast-trivy-sbom-scan:
	@mkdir -p logs/sast

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-sbom-scan <sbom_path>"; \
		exit 1; \
	fi

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" sbom --output logs/sast/trivy-sbom.json "$(filter-out $@,$(MAKECMDGOALS))" 2>&1
.PHONY: sast-trivy-sbom-scan

# Usage: make sast-trivy-sbom-cyclonedx-image <image_name>
#
## Generate SBOM in CycloneDX format for a container image using Trivy
sast-trivy-sbom-cyclonedx-image:
	@mkdir -p logs/sbom

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-sbom-cyclonedx-image <image_name>"; \
		exit 1; \
	fi

	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" image --format cyclonedx --output logs/sbom/sbom-image.cdx.json "$(filter-out $@,$(MAKECMDGOALS))" 2>&1
.PHONY: sast-trivy-sbom-cyclonedx-image

# Usage: make sast-trivy-sbom-cyclonedx-fs <path>
#
## Generate SBOM in CycloneDX format for a file system using Trivy
sast-trivy-sbom-cyclonedx-fs:
	@mkdir -p logs/sbom

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-sbom-cyclonedx-fs <path>"; \
		exit 1; \
	fi

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" filesystem --format cyclonedx --output logs/sbom/sbom-fs.cdx.json "$(filter-out $@,$(MAKECMDGOALS))" 2>&1
.PHONY: sast-trivy-sbom-cyclonedx-fs

# Usage: make sast-trivy-sbom-license <sbom_path>
#
## Scan SBOM for license compliance using Trivy
sast-trivy-sbom-license:
	@mkdir -p logs/sast

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-sbom-license <sbom_path>"; \
		exit 1; \
	fi

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" sbom --scanners license --format table --output logs/sast/trivy-sbom-license.txt "$(filter-out $@,$(MAKECMDGOALS))" 2>&1
.PHONY: sast-trivy-sbom-license

# Usage: make sast-trivy-sbom-attestation <intoto_sbom_path>
#
## Scan the verified SBOM attestation using Trivy
sast-trivy-sbom-attestation:
	@mkdir -p logs/sast

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-sbom-attestation <intoto_sbom_path>"; \
		exit 1; \
	fi

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" sbom "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: sast-trivy-sbom-attestation

# Usage: make sast-trivy-vm <vm_image_path>
#
## [EXPERIMENTAL] Scan a virtual machine image using Trivy
sast-trivy-vm:
	@mkdir -p logs/sast

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-trivy-vm <vm_image_path>"; \
		exit 1; \
	fi

	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" vm --output logs/sast/trivy-vm.json "$(filter-out $@,$(MAKECMDGOALS))" 2>&1
.PHONY: sast-trivy-vm

# Usage: make sast-trivy-kubernetes [target]
#
## [EXPERIMENTAL] Scan kubernetes cluster using Trivy (default `cluster`)
sast-trivy-kubernetes:
	@mkdir -p logs/sast

	@echo "Note: This requires KUBECONFIG to be mounted or available to the container. Assuming ~/.kube/config is mounted to /root/.kube/config"

	docker run --rm -v "${HOME}/.kube/config:/root/.kube/config" -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_TRIVY)" kubernetes --output logs/sast/trivy-kubernetes.json $(if $(filter-out $@,$(MAKECMDGOALS)),$(filter-out $@,$(MAKECMDGOALS)),cluster) 2>&1
.PHONY: sast-trivy-kubernetes

## Generate Cosign key pair
sast-cosign-generate-key-pair:
	docker run --rm -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_COSIGN)" generate-key-pair
.PHONY: sast-cosign-generate-key-pair

# Usage: make sast-cosign-attest <image_name>
#
## Attest an image with the generated SBOM using Cosign
sast-cosign-attest:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-cosign-attest <image_name>"; \
		exit 1; \
	fi
	@if [ ! -f cosign.key ]; then \
		echo "Error: cosign.key not found. Run 'make sast-cosign-generate-key-pair' first."; \
		exit 1; \
	fi
	@if [ ! -f logs/sbom/sbom.cdx.json ]; then \
		echo "Error: logs/sbom/sbom.cdx.json not found. Run 'make sast-trivy-sbom-cyclonedx <image_name>' first."; \
		exit 1; \
	fi

	docker run --rm -v "${HOME}/.docker/config.json:/root/.docker/config.json" -v "${PWD}:/workspace" -w /workspace -e COSIGN_PASSWORD "$(SAST_IMAGE_COSIGN)" attest --key cosign.key --type cyclonedx --predicate logs/sbom/sbom.cdx.json "$(filter-out $@,$(MAKECMDGOALS))"
.PHONY: sast-cosign-attest

# Usage: make sast-cosign-verify <image_name>
#
## Verify SBOM attestation for an image using Cosign
sast-cosign-verify:
	@mkdir -p logs/sast

	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "usage: make sast-cosign-verify <image_name>"; \
		exit 1; \
	fi
	@if [ ! -f cosign.pub ]; then \
		echo "Error: cosign.pub not found. Run 'make sast-cosign-generate-key-pair' first."; \
		exit 1; \
	fi

	docker run --rm -v "${HOME}/.docker/config.json:/root/.docker/config.json" -v "${PWD}:/workspace" -w /workspace "$(SAST_IMAGE_COSIGN)" verify-attestation --key cosign.pub --type cyclonedx "$(filter-out $@,$(MAKECMDGOALS))" > logs/sbom/sbom.cdx.intoto.jsonl 2> logs/sast/cosign-verify.log
.PHONY: sast-cosign-verify
