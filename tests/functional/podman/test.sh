#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartTest "podman info"
        rlRun "podman version" 0 "podman version"
        rlRun "podman info" 0 "podman info"
        rlRun "podman ps" 0 "podman ps (empty container list)"
    rlPhaseEnd

    rlPhaseStartTest "import and run oci image"
        if [ -n "${OPENRUYI_OCI_IMAGE_URL:-}" ]; then
            rlRun "wget -O /tmp/openruyi-oci.tar '${OPENRUYI_OCI_IMAGE_URL}'" 0 "download OCI image"
            image_id=$(podman import /tmp/openruyi-oci.tar)
            rlRun "podman run -it --rm '$image_id' /bin/bash -c 'echo openruyi-ok'" 0 "run container"
            rm -f /tmp/openruyi-oci.tar
        else
            rlLogWarning "OPENRUYI_OCI_IMAGE_URL not set, skip image import test"
        fi
    rlPhaseEnd
rlJournalEnd
