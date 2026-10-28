#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartTest "podman 基础信息"
        rlRun "podman version" 0 "podman version"
        rlRun "podman info" 0 "podman info"
        rlRun "podman ps" 0 "podman ps（空容器列表）"
    rlPhaseEnd

    rlPhaseStartTest "导入并运行 OCI 镜像"
        if [ -n "${OPENRUYI_OCI_IMAGE_URL:-}" ]; then
            rlRun "wget -O /tmp/openruyi-oci.tar '${OPENRUYI_OCI_IMAGE_URL}'" 0 "下载 OCI 镜像"
            image_id=$(podman import /tmp/openruyi-oci.tar)
            rlRun "podman run -it --rm '$image_id' /bin/bash -c 'echo openruyi-ok'" 0 "运行容器"
            rm -f /tmp/openruyi-oci.tar
        else
            rlLogWarning "未配置 OPENRUYI_OCI_IMAGE_URL，跳过镜像导入实测"
        fi
    rlPhaseEnd
rlJournalEnd
