#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    # SSH 测试目标：未配置 SSH_TEST_HOST 时默认本机 localhost
    ssh_host="${SSH_TEST_HOST:-localhost}"

    rlPhaseStartTest "sshd 服务运行"
        rlRun "systemctl is-active sshd" 0 "测试 sshd 运行"
    rlPhaseEnd

    rlPhaseStartTest "root 不支持 ssh 登录"
        perm_root="$(sshd -T 2>/dev/null | grep -i '^permitrootlogin ' | awk '{print $2}')"
        if [ -n "$perm_root" ]; then
            rlRun "echo \"$perm_root\" | grep -qiE 'no|prohibit-password'" 0 "sshd PermitRootLogin=${perm_root}（应禁止 root 登录）"
        else
            rlLogWarning "无法获取 sshd PermitRootLogin 配置，跳过配置检查"
        fi
        rlRun "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@${ssh_host} 'uname -a'" 255 "测试 root 登录被拒绝"
    rlPhaseEnd

    rlPhaseStartTest "配置用户可 ssh 登录"
        if [ -n "${SSH_TEST_PASSWORD:-}" ] && command -v sshpass >/dev/null 2>&1; then
            rlRun "sshpass -p '${SSH_TEST_PASSWORD}' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${SSH_TEST_USER:-openruyi}@${ssh_host} 'uname -a'" 0 "密码远程登录并执行 uname -a"
        elif [ -n "${SSH_TEST_KEY:-}" ]; then
            rlRun "ssh -i '${SSH_TEST_KEY}' -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${SSH_TEST_USER:-openruyi}@${ssh_host} 'uname -a'" 0 "密钥远程登录"
        else
            rlLogWarning "未配置 SSH_TEST_PASSWORD/SSH_TEST_KEY，跳过用户登录实测"
        fi
    rlPhaseEnd
rlJournalEnd
