#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#
# Setup the Everything as Code (XaC) environment.

# -x: print a trace (debug)
# -u: treat unset variables
# -o pipefail: return value of a pipeline
set -uo pipefail

# Include Scripts

source ./../scripts/shell/pkg.sh

# Constant Variables

readonly -A APT_PACKAGES=(
  ["make"]=""
  ["ca-certificates"]=""
  ["python3"]=""
  ["python3-pip"]=""
  ["ansible-core"]=""
)

# Control Flow Logic

function setup_xac() {
  local -i retval=0

  pkg_apt_install_list APT_PACKAGES
  ((retval |= $?))

  pkg_apt_clean
  ((retval |= $?))

  return "${retval}"
}

setup_xac
exit "${?}"
