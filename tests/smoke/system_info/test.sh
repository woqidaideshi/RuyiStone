#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

rlJournalStart
    rlPhaseStartSetup "检查前置命令"
        assertCmdExists uname
        assertCmdExists hostnamectl
        assertCmdExists lscpu
        assertCmdExists free
        assertCmdExists date
    rlPhaseEnd

    rlPhaseStartTest "内核版本与架构"
        rlRun "uname" 0 "uname 内核名"
        rlRun "uname -a" 0 "uname 输出"
        rlRun "uname -r" 0 "内核版本"
        rlRun "uname -m" 0 "机器架构"
        rlRun "uname -m | grep -E 'riscv64|aarch64|x86_64'" 0 "测试架构支持"
    rlPhaseEnd

    rlPhaseStartTest "发行版信息"
        rlRun "cat /etc/os-release" 0 "os-release 内容"
        rlRun "grep -qi openruyi /etc/os-release" 0 "测试发行版为 openruyi"
    rlPhaseEnd

    rlPhaseStartTest "CPU 架构与 ISA 特性"
        rlRun "lscpu" 0 "lscpu 输出"
        if [ "$(uname -m)" = "riscv64" ]; then
            rlRun "grep -qi '^isa' /proc/cpuinfo" 0 "测试 ISA 特性"
        fi
    rlPhaseEnd

    rlPhaseStartTest "内存信息"
        rlRun "free -h" 0 "free 输出"
    rlPhaseEnd

    rlPhaseStartTest "系统时间"
        rlRun "date" 0 "date 输出"
    rlPhaseEnd

    rlPhaseStartTest "主机名与系统信息"
        rlRun "hostnamectl" 0 "hostnamectl 输出"
    rlPhaseEnd
rlJournalEnd
