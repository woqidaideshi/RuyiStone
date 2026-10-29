#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartTest "linux lts boot entries"
        # The linux-lts metapackage VERSION-RELEASE lacks the "-lts" marker that appears in
        # the kernel version (e.g. rpm: 6.18.54-1.0_1288.1.or vs kernel: 6.18.54-lts-1.0_1288.1.or).
        # Derive the real kernel version from files owned by linux-lts-core, then check
        # kernel-install and the BLS boot entry against it.
        rlAssertRpm linux-lts
        lts_ver="$(rpm -ql linux-lts-core 2>/dev/null | grep -oE '/(usr/)?lib/modules/[^/]+' | head -n1 | sed 's|^/\(usr/\)\?lib/modules/||')"
        rlLogInfo "linux-lts kernel version: $lts_ver"
        if [ -n "$lts_ver" ]; then
            rlPass "check lts kernel version derived from rpm"
            rlRun "kernel-install list | grep -Fq \"${lts_ver}\"" 0 "check lts kernel exists in kernel-install"
            rlRun "ls /boot/efi/loader/entries/*${lts_ver}.conf" 0 "check lts kernel boot entry exists"
        else
            rlFail "cannot determine linux-lts kernel version from rpm"
        fi
    rlPhaseEnd

    rlPhaseStartCleanup
        rlLogInfo "note: rebooting and selecting the linux-lts kernel must be done manually"
    rlPhaseEnd
rlJournalEnd
