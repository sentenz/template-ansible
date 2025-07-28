#!/bin/bash
#
# Install and configure all dependencies essential for development.

# -x: print a trace (debug)
# -u: treat unset variables
# -o pipefail: return value of a pipeline
set -uo pipefail

# Include Scripts

source ./../scripts/shell/pkg.sh

# Constant Variables

readonly -A PIP_PACKAGES=(
  ["ansible-core"]="2.18.4"
  ["ansible-lint"]="25.2.1"
)

readonly -A NPM_PACKAGES=(
  ["prettier"]="3.5.3"
)

# Control Flow Logic

function setup() {
  local -i retval=0

  pkg_pip_install_list PIP_PACKAGES
  ((retval |= $?))

  pkg_pip_clean
  ((retval |= $?))

  pkg_npm_install_list NPM_PACKAGES
  ((retval |= $?))

  pkg_npm_clean
  ((retval |= $?))

  return "${retval}"
}

setup
exit "${?}"
