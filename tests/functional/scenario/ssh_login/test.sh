#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    # SSH test target: default to localhost when SSH_TEST_HOST is not set
    ssh_host="${SSH_TEST_HOST:-localhost}"

    rlPhaseStartTest "sshd running"
        rlRun "systemctl is-active sshd" 0 "check sshd is running"
    rlPhaseEnd

    rlPhaseStartTest "root ssh login denied"
        perm_root="$(sshd -T 2>/dev/null | grep -i '^permitrootlogin ' | awk '{print $2}')"
        if [ -n "$perm_root" ]; then
            rlRun "echo \"$perm_root\" | grep -qiE 'no|prohibit-password'" 0 "sshd PermitRootLogin=${perm_root} (root login should be disabled)"
        else
            rlLogWarning "cannot get sshd PermitRootLogin config, skip config check"
        fi
        rlRun "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@${ssh_host} 'uname -a'" 255 "check root login is rejected"
    rlPhaseEnd

    rlPhaseStartTest "user login via ssh"
        if [ -n "${SSH_TEST_PASSWORD:-}" ] && command -v sshpass >/dev/null 2>&1; then
            rlRun "sshpass -p '${SSH_TEST_PASSWORD}' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${SSH_TEST_USER:-openruyi}@${ssh_host} 'uname -a'" 0 "log in with password and run uname -a"
        elif [ -n "${SSH_TEST_KEY:-}" ]; then
            rlRun "ssh -i '${SSH_TEST_KEY}' -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${SSH_TEST_USER:-openruyi}@${ssh_host} 'uname -a'" 0 "log in with key"
        else
            rlLogWarning "SSH_TEST_PASSWORD/SSH_TEST_KEY not set, skip user login test"
        fi
    rlPhaseEnd
rlJournalEnd
