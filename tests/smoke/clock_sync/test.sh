#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

rlJournalStart
    rlPhaseStartSetup "check prereqs"
        assertCmdExists timedatectl
    rlPhaseEnd

    rlPhaseStartTest "ntp sync status"
        rlRun "timedatectl" 0 "timedatectl output"
        rlRun "timedatectl show -p NTPSynchronized" 0 "NTP sync status"
        rlRun "timedatectl show -p NTPSynchronized | grep -q yes" 0 "check NTP sync is enabled"
    rlPhaseEnd

    rlPhaseStartTest "timezone info"
        rlRun "date" 0 "date output"
        rlRun "timedatectl show -p Timezone" 0 "timezone info"
    rlPhaseEnd
rlJournalEnd
