#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

# wget 命令由 wget2-wget 提供（wget2 是另一个包），因此校验用 wget2-wget
BASE_PKGS="git openssh-clients vim rpm-build dnf5-plugins gcc make cmake clang wget2-wget tar pciutils procps-ng psmisc iputils gcc-c++ tmux podman linux-lts"

rlJournalStart
    # 一条事务整体安装全部基础软件包，并检查安装日志中的 warning/error。
    # "already installed" 本身不会导致失败；dnf 只会在存在更优候选版本
    # 且升级冲突（如 linux-lts best 候选 6.18.54 与已装 6.18.34 冲突）时
    # 才返回非 0 —— 这是真实问题，测试应如实报错，而非误报。
    assertDnfInstall $BASE_PKGS

    rlPhaseStartTest "逐个校验基础软件包已安装"
        for pkg in $BASE_PKGS; do
            rlAssertRpm "$pkg"
        done
    rlPhaseEnd
rlJournalEnd
