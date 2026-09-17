#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Source this file so riscv-arch-test can find run-*.sh on PATH.
#   source /path/to/dir/sourceme.sh
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="${DIR}:${PATH}"
if [[ -z "${CORE_ROOT:-}" && -d "${DIR}/../rtl" ]]; then
  export CORE_ROOT="$(cd "${DIR}/.." && pwd)"
fi
