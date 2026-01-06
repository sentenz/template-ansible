#!/bin/bash
#
# Remove development artifacts and restore the host to its pre-setup state.

# -x: print a trace (debug)
# -u: treat unset variables
# -o pipefail: return value of a pipeline
set -uo pipefail

# Include Scripts

source ./../scripts/shell/pkg.sh

# Constant Variables

readonly -A NPM_PACKAGES=(
  ["prettier"]="3.5.3"
)

readonly -A PIP_PACKAGES=(
  ["ansible-core"]=""
  ["ansible-lint"]=""
)

readonly -A APT_PACKAGES=(
  ["make"]=""
  ["git"]=""
  ["jq"]=""
  ["bash"]=""
  ["ca-certificates"]=""
  ["snapd"]=""
  ["pip"]=""
)

# Control Flow Logic

function teardown() {
  # NOTE Use reversed order of `bootstrap.sh` and `setup.sh` scripts for tearing down the environment

  local -i retval=0

  pkg_npm_uninstall_list NPM_PACKAGES
  ((retval |= $?))

  pkg_npm_clean
  ((retval |= $?))

  pkg_pip_uninstall_list PIP_PACKAGES
  ((retval |= $?))

  pkg_pip_clean
  ((retval |= $?))

  pkg_apt_uninstall_list APT_PACKAGES
  ((retval |= $?))

  pkg_apt_clean
  ((retval |= $?))

  return "${retval}"
}

teardown
exit "${?}"
