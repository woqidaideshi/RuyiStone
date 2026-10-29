#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartTest "linux lts boot entries"
        # linux-lts is installed (the kernel version itself does not contain lts, e.g. 6.18.34-1272.1.or)
        rlAssertRpm linux-lts
        lts_ver="$(rpm -q --qf '%{VERSION}-%{RELEASE}' linux-lts)"
        rlLogInfo "linux-lts kernel version: $lts_ver"
        # kernel-install confirms the kernel exists (HAS KERNEL)
        rlRun "kernel-install list | grep -Fq \"${lts_ver}\"" 0 "check lts kernel exists"
        # BLS boot entry exists (selectable by bootloader, mounted at /boot/efi)
        rlRun "ls /boot/efi/loader/entries/*${lts_ver}.conf" 0 "check lts kernel boot entry exists"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlLogInfo "note: rebooting and selecting the linux-lts kernel must be done manually"
    rlPhaseEnd
rlJournalEnd
