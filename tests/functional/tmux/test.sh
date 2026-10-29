#!/bin/bash
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartTest "tmux version"
        rlRun "tmux -V" 0 "tmux version"
    rlPhaseEnd

    rlPhaseStartTest "session create and share"
        rlRun "tmux new -d -s mysession" 0 "create session (detached)"
        rlRun "tmux ls | grep -q mysession" 0 "check session list contains mysession"
        rlRun "tmux has-session -t mysession" 0 "check session exists"

        # Equivalent to running 'echo 1111 > test.txt' in an attached client
        rlRun "tmux send-keys -t mysession 'echo 1111 > /tmp/tmux-share.txt' Enter" 0 "run echo 1111 > test.txt in session"
        sleep 1
        rlRun "test -f /tmp/tmux-share.txt && grep -q 1111 /tmp/tmux-share.txt" 0 "check command ran in session"

        # Equivalent to the view another client sees when attached to the same session
        rlRun "tmux send-keys -t mysession 'echo shared-view-ok' Enter" 0 "run another output command in session"
        sleep 1
        rlRun "tmux capture-pane -t mysession -p | grep -q shared-view-ok" 0 "check shared view"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "tmux kill-session -t mysession" 0 "clean up session"
        rm -f /tmp/tmux-share.txt
    rlPhaseEnd
rlJournalEnd
