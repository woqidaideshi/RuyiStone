#!/bin/bash
# ============================================================
# openRuyi shared test library
#
# Consolidates the previously duplicated per-suite lib.sh files into
# a single implementation. Dependency installation is handled by tmt's
# require / prepare; this library only provides assertion helpers and
# environment-related utilities.
#
# Usage (source from tests/<case>/test.sh, add ../ according to depth):
#   . "$(dirname "$0")/../lib/common.sh"      # tests/<case>/test.sh
#   . "$(dirname "$0")/../../lib/common.sh"   # tests/base_pkgs/<pkg>/test.sh
# ============================================================

# Assert that a command is available
assertCmdExists() {
    local cmd="$1"
    rlRun "command -v $cmd" 0 "command '$cmd' is available"
}

# Current RVA variant (rva20 / rva23), defaults to rva23
rvaVariant() {
    echo "${OPENRUYI_RVA_VARIANT:-rva23}"
}

# Return the repository baseurl for the current RVA variant
openruyiRepoBaseurl() {
    case "$(rvaVariant)" in
        rva20)
            echo "${OPENRUYI_REPO_BASEURL:-https://repo.build.openruyi.cn/openruyi/rva20/}"
            ;;
        *)
            echo "${OPENRUYI_REPO_BASEURL:-https://repo.build.openruyi.cn/openruyi/riscv64/}"
            ;;
    esac
}

# Install packages and check the install output for warnings/errors.
# Usage: assertDnfInstall <pkg...> (multiple packages as one dnf install transaction)
# The install log is written to ${TMT_TEST_DATA:-/tmp}/dnf-install.log and kept;
# tmt collects the TMT_TEST_DATA directory contents as test artifacts.
# Install failure -> fail and print the full log; error/failed/conflict/problem -> fail;
# warning -> warn only (does not fail).
assertDnfInstall() {
    local log_dir="${TMT_TEST_DATA:-${TMPDIR:-/tmp}}"
    mkdir -p "$log_dir"
    local log="$log_dir/dnf-install.log"
    local pkgs=("$@")
    local rc=0

    rlPhaseStartTest "install packages"
        rlRun "dnf install -y ${pkgs[*]} >'$log' 2>&1" 0 "dnf install ${pkgs[*]}"
        rc=$?
    rlPhaseEnd

    if [ "$rc" -ne 0 ]; then
        rlLogError "dnf install failed, full log: $log"
        while IFS= read -r line; do rlLogError "  $line"; done <"$log"
        return 1
    fi

    rlPhaseStartTest "check install log"
        if grep -niE 'error|failed|conflict|problem' "$log" >"$log.err"; then
            rlLogError "${pkgs[*]} install produced errors (full log: $log):"
            while IFS= read -r line; do rlLogError "  $line"; done <"$log.err"
            rlFail "${pkgs[*]} install log contains error/failed messages"
        fi
        if grep -niE 'warning' "$log" >"$log.warn"; then
            rlLogWarning "${pkgs[*]} install produced warnings (full log: $log):"
            while IFS= read -r line; do rlLogWarning "  $line"; done <"$log.warn"
        fi
        if [ ! -s "$log.err" ] && [ ! -s "$log.warn" ]; then
            rlPass "install log has no warning/error messages"
        fi
    rlPhaseEnd

    return 0
}
