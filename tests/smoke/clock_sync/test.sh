#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

rlJournalStart
    rlPhaseStartSetup "检查前置命令"
        assertCmdExists timedatectl
    rlPhaseEnd

    rlPhaseStartTest "时钟同步服务与系统时间"
        rlRun "timedatectl" 0 "timedatectl 输出"
        rlRun "timedatectl show -p NTPSynchronized" 0 "NTP 同步状态"
        rlRun "timedatectl show -p NTPSynchronized | grep -q yes" 0 "测试 NTP 同步开启"
    rlPhaseEnd

    rlPhaseStartTest "系统时间与时区"
        rlRun "date" 0 "date 输出"
        rlRun "timedatectl show -p Timezone" 0 "时区信息"
    rlPhaseEnd
rlJournalEnd
