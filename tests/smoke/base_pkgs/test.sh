#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1
. "$(dirname "$0")/../../lib/common.sh"

# The wget command is provided by wget2-wget (wget2 is a separate package),
# so the check uses wget2-wget.
BASE_PKGS="git openssh-clients vim rpm-build dnf5-plugins gcc make cmake clang wget2-wget tar pciutils procps-ng psmisc iputils gcc-c++ tmux podman linux-lts"

rlJournalStart
    # Install all base packages in a single transaction and check the log for warnings/errors.
    # "already installed" does not cause failure by itself; dnf only returns
    # non-zero when a better candidate exists and upgrading would conflict
    # (e.g. linux-lts best candidate 6.18.54 conflicts with installed 6.18.34),
    # which is a real problem the test should report rather than mask.
    assertDnfInstall $BASE_PKGS

    rlPhaseStartTest "verify packages installed"
        for pkg in $BASE_PKGS; do
            rlAssertRpm "$pkg"
        done
    rlPhaseEnd
rlJournalEnd
