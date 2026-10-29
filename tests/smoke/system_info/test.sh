#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

rlJournalStart
    rlPhaseStartSetup "check prereqs"
        assertCmdExists uname
        assertCmdExists hostnamectl
        assertCmdExists lscpu
        assertCmdExists free
        assertCmdExists date
    rlPhaseEnd

    rlPhaseStartTest "kernel architecture"
        rlRun "uname" 0 "uname kernel name"
        rlRun "uname -a" 0 "uname output"
        rlRun "uname -r" 0 "kernel version"
        rlRun "uname -m" 0 "machine architecture"
        rlRun "uname -m | grep -E 'riscv64|aarch64|x86_64'" 0 "check architecture support"
    rlPhaseEnd

    rlPhaseStartTest "distribution info"
        rlRun "cat /etc/os-release" 0 "os-release content"
        rlRun "grep -qi openruyi /etc/os-release" 0 "check distro is openruyi"
    rlPhaseEnd

    rlPhaseStartTest "cpu architecture and isa"
        rlRun "lscpu" 0 "lscpu output"
        if [ "$(uname -m)" = "riscv64" ]; then
            rlRun "grep -qi '^isa' /proc/cpuinfo" 0 "check ISA feature"
        fi
    rlPhaseEnd

    rlPhaseStartTest "memory info"
        rlRun "free -h" 0 "free output"
    rlPhaseEnd

    rlPhaseStartTest "system time"
        rlRun "date" 0 "date output"
    rlPhaseEnd

    rlPhaseStartTest "hostname info"
        rlRun "hostnamectl" 0 "hostnamectl output"
    rlPhaseEnd
rlJournalEnd
