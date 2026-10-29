#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

rlJournalStart
    rlPhaseStartSetup "check prereqs"
        assertCmdExists df
        assertCmdExists fdisk
        assertCmdExists lsblk
        assertCmdExists findmnt
    rlPhaseEnd

    rlPhaseStartTest "last partition expansion"
        rlRun "df -lh /" 0 "df output"
        rlRun "lsblk" 0 "lsblk output"

        # Infer the whole disk from the root partition (read-only, changes nothing)
        root_dev="$(findmnt -n -o SOURCE /)"
        disk="/dev/$(lsblk -n -o PKNAME "$root_dev" 2>/dev/null | head -n1)"

        if [ ! -b "$disk" ]; then
            rlLogWarning "cannot determine the disk for root partition ($root_dev), skip expansion check"
        else
            # Find the last partition on this disk (largest START, may be root or home)
            last_part="$(lsblk -r -b -n -o NAME,TYPE,START "$disk" | awk '$2=="part" {print $1, $3}' | sort -k2 -n | tail -n1 | awk '{print $1}')"
            last_part_dev="/dev/${last_part}"
            part_num="$(echo "$last_part" | grep -oE '[0-9]+$')"

            if [ -n "$part_num" ]; then
                if command -v growpart >/dev/null 2>&1; then
                    # growpart -N dry run: only reports, changes nothing; prints NOCHANGE when already at max
                    grow_out="$(growpart -N "$disk" "$part_num" 2>&1)"
                    rlRun "echo \"$grow_out\" | grep -qi '^NOCHANGE'" 0 "check last partition $last_part_dev expansion (growpart: $grow_out)"
                else
                    rlLogWarning "growpart (cloud-utils-growpart) not installed, skip exact expansion check"
                fi
            else
                rlLogWarning "no partition found on disk $disk, skip expansion check"
            fi
        fi
    rlPhaseEnd

    rlPhaseStartTest "partition info"
        rlRun "fdisk -l" 0 "fdisk -l output"
    rlPhaseEnd
rlJournalEnd
