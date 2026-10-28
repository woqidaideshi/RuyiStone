#!/bin/bash
# ============================================================
# openRuyi 共享测试库
#
# 收敛原来每个 suite 一份、内容高度重复的 lib.sh 为单一实现。
# 依赖安装交给 tmt 的 require / prepare 处理，本库只提供断言与
# 环境相关的辅助函数。
#
# 用法（从 tests/<用例>/test.sh 引入，按目录深度加 ../）：
#   . "$(dirname "$0")/../lib/common.sh"      # tests/<用例>/test.sh
#   . "$(dirname "$0")/../../lib/common.sh"   # tests/base_pkgs/<包>/test.sh
# ============================================================

# 断言命令可用
assertCmdExists() {
    local cmd="$1"
    rlRun "command -v $cmd" 0 "命令 '$cmd' 可用"
}

# 当前 RVA 变体（rva20 / rva23），默认 rva23
rvaVariant() {
    echo "${OPENRUYI_RVA_VARIANT:-rva23}"
}

# 根据 RVA 变体返回软件源 baseurl
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

# 安装软件包并检查安装输出中的警告/报错
# 用法：assertDnfInstall <包名...>（多个包作为一个 dnf install 事务）
# 安装日志写入 ${TMT_TEST_DATA:-/tmp}/dnf-install.log，不删除；
# tmt 会把 TMT_TEST_DATA 目录内容作为测试产物（artifacts）收集保存。
# 安装失败 → 报错并打印完整日志；日志含 error/failed/conflict/problem → 报错；
# 日志含 warning → 提醒（不失败）。
assertDnfInstall() {
    local log_dir="${TMT_TEST_DATA:-${TMPDIR:-/tmp}}"
    mkdir -p "$log_dir"
    local log="$log_dir/dnf-install.log"
    local pkgs=("$@")
    local rc=0

    rlPhaseStartTest "dnf 安装 ${pkgs[*]}"
        rlRun "dnf install -y ${pkgs[*]} >'$log' 2>&1" 0 "dnf install ${pkgs[*]}"
        rc=$?
    rlPhaseEnd

    if [ "$rc" -ne 0 ]; then
        rlLogError "dnf 安装失败，完整日志见 $log"
        while IFS= read -r line; do rlLogError "  $line"; done <"$log"
        return 1
    fi

    rlPhaseStartTest "检查安装日志中的 warning/error"
        if grep -niE 'error|failed|conflict|problem' "$log" >"$log.err"; then
            rlLogError "${pkgs[*]} 安装过程出现报错信息（完整日志见 $log）："
            while IFS= read -r line; do rlLogError "  $line"; done <"$log.err"
            rlFail "${pkgs[*]} 安装日志包含 error/failed 信息"
        fi
        if grep -niE 'warning' "$log" >"$log.warn"; then
            rlLogWarning "${pkgs[*]} 安装过程出现警告信息（完整日志见 $log）："
            while IFS= read -r line; do rlLogWarning "  $line"; done <"$log.warn"
        fi
        if [ ! -s "$log.err" ] && [ ! -s "$log.warn" ]; then
            rlPass "安装日志无 warning/error 信息"
        fi
    rlPhaseEnd

    return 0
}
