#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

rlJournalStart
    rlPhaseStartSetup "check prereqs"
        assertCmdExists useradd
        assertCmdExists id
        assertCmdExists getent
        assertCmdExists groups
        assertCmdExists whoami
        rlRun "userdel -r test 2>/dev/null || true" 0 "remove leftover test user"
    rlPhaseEnd

    rlPhaseStartTest "add user to wheel"
        rlRun "useradd -G wheel test" 0 "useradd -G wheel test"
        rlRun "getent passwd test" 0 "check user exists in passwd"
        rlRun "id test | grep -q wheel" 0 "check user test is in wheel"
        rlRun "groups test | grep -q wheel" 0 "check groups contains wheel"
    rlPhaseEnd

    rlPhaseStartTest "user group info"
        rlRun "id" 0 "current user id"
        rlRun "whoami" 0 "current user name"
        rlRun "groups" 0 "current user groups"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "userdel -r test" 0 "remove test user"
    rlPhaseEnd
rlJournalEnd
