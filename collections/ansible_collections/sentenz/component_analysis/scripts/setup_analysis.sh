#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#
# Setup the Software Analysis environment.

# -x: print a trace (debug)
# -u: treat unset variables
# -o pipefail: return value of a pipeline
set -uo pipefail

# Include Scripts

source ./../scripts/shell/pkg.sh

# Constant Variables

readonly -A APT_PACKAGES=(
  ["python3"]=""
  ["python3-pip"]=""
)

readonly -A PIP_PACKAGES=(
  ["pylint"]="3.1.0"
  ["black"]="24.3.0"
  ["ansible-lint"]="24.12.2"
)

# Control Flow Logic

function setup_analysis() {
  local -i retval=0

  pkg_apt_install_list APT_PACKAGES
  ((retval |= $?))

  pkg_apt_clean
  ((retval |= $?))

  pkg_pip_install_list PIP_PACKAGES
  ((retval |= $?))

  pkg_pip_clean
  ((retval |= $?))

  return "${retval}"
}

setup_analysis
exit "${?}"
