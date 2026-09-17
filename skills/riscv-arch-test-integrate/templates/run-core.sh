#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Template runner for Silver-style tb/. riscv-arch-test invokes:
#   run-<name>.sh {debug:--trace file.fst} --elf <elf>
# Engineering decision: flock so parallel riscv-arch-test workers share one build.
set -euo pipefail

ROOT="${CORE_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SIM_DIR="${ROOT}/sim"
OBJ_DIR="${SIM_DIR}/obj_dir"
SIM="${OBJ_DIR}/Vtb_core"
TB_DIR="${ROOT}/tb"
RTL_DIR="${ROOT}/rtl"
LOCK_FILE="${SIM_DIR}/.build.lock"

elf=""
trace=""
rest=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --elf)
      if [[ $# -ge 2 && "$2" != --* ]]; then elf="$2"; shift 2; else shift; fi ;;
    --elf=*)
      elf="${1#--elf=}"; shift ;;
    --trace)
      if [[ $# -ge 2 && "$2" != --* ]]; then trace="$2"; shift 2; else shift; fi ;;
    --trace=*)
      trace="${1#--trace=}"; shift ;;
    --help|-h)
      echo "usage: $(basename "$0") [--trace file.fst] --elf <path>"
      exit 0 ;;
    *)
      rest+=("$1"); shift ;;
  esac
done

if [[ -z "${elf}" && ${#rest[@]} -gt 0 ]]; then
  elf="${rest[-1]}"
  unset 'rest[-1]'
fi

if [[ -z "${elf}" ]]; then
  echo "usage: $(basename "$0") [--trace file.fst] --elf <path>" >&2
  exit 2
fi

mkdir -p "${SIM_DIR}"

needs_build() {
  if [[ ! -x "${SIM}" ]]; then
    return 0
  fi
  local newest_src
  newest_src="$(find "${RTL_DIR}" "${TB_DIR}" \
                  \( -name '*.sv' -o -name '*.cpp' -o -name 'Makefile' \) \
                  -newer "${SIM}" -print -quit)"
  [[ -n "${newest_src}" ]]
}

(
  flock -x 200
  if needs_build; then
    echo "$(basename "$0"): RTL/TB changed (or no build found) — rebuilding..." >&2
    make -C "${TB_DIR}" sim
  fi
) 200>"${LOCK_FILE}"

if [[ -n "${trace}" ]]; then
  exec "${SIM}" --elf "${elf}" --trace "${trace}" ${rest[@]+"${rest[@]}"}
else
  exec "${SIM}" --elf "${elf}" ${rest[@]+"${rest[@]}"}
fi
