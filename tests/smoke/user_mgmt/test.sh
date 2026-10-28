#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

rlJournalStart
    rlPhaseStartSetup "检查前置命令并清理残留用户"
        assertCmdExists useradd
        assertCmdExists id
        assertCmdExists getent
        assertCmdExists groups
        assertCmdExists whoami
        rlRun "userdel -r test 2>/dev/null || true" 0 "清理残留 test 用户"
    rlPhaseEnd

    rlPhaseStartTest "新增用户并加入 wheel 组"
        rlRun "useradd -G wheel test" 0 "useradd -G wheel test"
        rlRun "getent passwd test" 0 "测试用户存在于 passwd"
        rlRun "id test | grep -q wheel" 0 "测试 test 用户属于 wheel"
        rlRun "groups test | grep -q wheel" 0 "测试 groups 含 wheel"
    rlPhaseEnd

    rlPhaseStartTest "当前用户与组信息"
        rlRun "id" 0 "当前用户 id"
        rlRun "whoami" 0 "当前用户名"
        rlRun "groups" 0 "当前用户组"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "userdel -r test" 0 "清理 test 用户"
    rlPhaseEnd
rlJournalEnd
