#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartTest "检查 linux-lts 内核启动项"
        # linux-lts 已安装（内核版本号本身不含 lts，如 6.18.34-1272.1.or）
        rlAssertRpm linux-lts
        lts_ver="$(rpm -q --qf '%{VERSION}-%{RELEASE}' linux-lts)"
        rlLogInfo "linux-lts 内核版本：$lts_ver"
        # kernel-install 确认该内核存在（HAS KERNEL ✓）
        rlRun "kernel-install list | grep -Fq \"${lts_ver}\"" 0 "测试 lts 内核存在"
        # BLS 启动项存在（可被 bootloader 选择，挂在 /boot/efi）
        rlRun "ls /boot/efi/loader/entries/*${lts_ver}.conf" 0 "测试 lts 内核启动项存在"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlLogInfo "注意：重启并选择 linux-lts 内核需人工执行"
    rlPhaseEnd
rlJournalEnd
