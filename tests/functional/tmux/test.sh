#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartTest "tmux 版本"
        rlRun "tmux -V" 0 "tmux 版本"
    rlPhaseEnd

    rlPhaseStartTest "会话创建、命令执行与多客户端共享视图"
        rlRun "tmux new -d -s mysession" 0 "创建会话（后台）"
        rlRun "tmux ls | grep -q mysession" 0 "测试会话列表含 mysession"
        rlRun "tmux has-session -t mysession" 0 "测试会话存在"

        # 等价于在一个客户端 attach 后执行：echo 1111 > test.txt
        rlRun "tmux send-keys -t mysession 'echo 1111 > /tmp/tmux-share.txt' Enter" 0 "在会话内执行 echo 1111 > test.txt"
        sleep 1
        rlRun "test -f /tmp/tmux-share.txt && grep -q 1111 /tmp/tmux-share.txt" 0 "测试会话内命令执行"

        # 等价于另一个客户端 attach 到同一会话看到的画面
        rlRun "tmux send-keys -t mysession 'echo shared-view-ok' Enter" 0 "会话内再执行一条输出命令"
        sleep 1
        rlRun "tmux capture-pane -t mysession -p | grep -q shared-view-ok" 0 "测试共享视图"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "tmux kill-session -t mysession" 0 "清理会话"
        rm -f /tmp/tmux-share.txt
    rlPhaseEnd
rlJournalEnd
