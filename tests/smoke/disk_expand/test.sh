#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

rlJournalStart
    rlPhaseStartSetup "检查前置命令"
        assertCmdExists df
        assertCmdExists fdisk
        assertCmdExists lsblk
        assertCmdExists findmnt
    rlPhaseEnd

    rlPhaseStartTest "磁盘最后一个分区已扩容到磁盘末尾"
        rlRun "df -lh /" 0 "df 输出"
        rlRun "lsblk" 0 "lsblk 输出"

        # 从根分区推断整块磁盘（只读，不修改任何东西）
        root_dev="$(findmnt -n -o SOURCE /)"
        disk="/dev/$(lsblk -n -o PKNAME "$root_dev" 2>/dev/null | head -n1)"

        if [ ! -b "$disk" ]; then
            rlLogWarning "无法确定根分区所在磁盘（$root_dev），跳过扩容校验"
        else
            # 找到该磁盘上最后一个分区（START 最大者，可能是 root 或 home）
            last_part="$(lsblk -r -b -n -o NAME,TYPE,START "$disk" | awk '$2=="part" {print $1, $3}' | sort -k2 -n | tail -n1 | awk '{print $1}')"
            last_part_dev="/dev/${last_part}"
            part_num="$(echo "$last_part" | grep -oE '[0-9]+$')"

            if [ -n "$part_num" ]; then
                if command -v growpart >/dev/null 2>&1; then
                    # growpart -N 干跑：只报告、不实际改动；分区已到最大时输出 NOCHANGE
                    grow_out="$(growpart -N "$disk" "$part_num" 2>&1)"
                    rlRun "echo \"$grow_out\" | grep -qi '^NOCHANGE'" 0 "磁盘最后一个分区 $last_part_dev 扩容检查（growpart: $grow_out）"
                else
                    rlLogWarning "未安装 growpart（cloud-utils-growpart），跳过扩容精确校验"
                fi
            else
                rlLogWarning "未找到磁盘 $disk 上的分区，跳过扩容校验"
            fi
        fi
    rlPhaseEnd

    rlPhaseStartTest "磁盘分区信息"
        rlRun "fdisk -l" 0 "fdisk -l 输出"
    rlPhaseEnd
rlJournalEnd
